--- @since 25.12.29

local hovered_dir = ya.sync(function()
	local h = cx.active.current.hovered
	if not h or not h.cha.is_dir then
		return
	end

	return {
		path = tostring(h.url.path),
		name = h.name,
	}
end)

local function trim(value)
	return value:match("^%s*(.-)%s*$")
end

local function fail(content)
	ya.notify {
		title = "Tmux session",
		content = content,
		level = "error",
		timeout = 5,
	}
end

local function tmux(args)
	local status, err = Command("tmux"):arg(args):status()
	return status and status.success, err
end

local function tmux_output(args)
	local output = Command("tmux"):arg(args):output()
	if not output or not output.status.success then
		return ""
	end

	return output.stdout
end

local function write_handoff(session)
	local path = os.getenv("YAZI_TMUX_SESSION_FILE")
	if not path or path == "" then
		return false
	end

	local file, err = io.open(path, "w")
	if not file then
		fail("Failed to write tmux handoff: " .. tostring(err))
		return false
	end

	file:write(session, "\n")
	file:close()
	return true
end

local function attach(session)
	if write_handoff(session) then
		ya.emit("quit", {})
	end
end

local function prompt_new_session(target)
	local session, event = ya.input {
		title = "Tmux session:",
		value = target.name,
		pos = { "top-center", y = 3, w = 50 },
	}
	if event ~= 1 then
		return
	end

	session = trim(session or "")
	if session == "" then
		return
	end

	if not tmux({ "has-session", "-t", "=" .. session }) then
		local ok, err = tmux({ "new-session", "-d", "-s", session, "-c", target.path })
		if not ok then
			return fail("Failed to create tmux session: " .. tostring(err or session))
		end
	end

	attach(session)
end

local function matching_sessions(name)
	if name == "" then
		return {}
	end

	local sessions = {}
	local stdout = tmux_output({ "list-sessions", "-F", "#S" })
	for session in stdout:gmatch("[^\r\n]+") do
		if session:find(name, 1, true) then
			sessions[#sessions + 1] = session
		end
	end

	table.sort(sessions)
	return sessions
end

local session_keys = {
	"1", "2", "3", "4", "5", "6", "7", "8", "9", "0",
	"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
	"o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
}

local function choose_session(sessions)
	local cands = {}
	local limit = math.min(#sessions, #session_keys)
	for i = 1, limit do
		cands[#cands + 1] = { on = session_keys[i], desc = sessions[i] }
	end

	cands[#cands + 1] = { on = "n", desc = "New session..." }

	if #sessions > limit then
		ya.notify {
			title = "Tmux session",
			content = string.format("Showing first %d of %d matching sessions", limit, #sessions),
			level = "warn",
			timeout = 5,
		}
	end

	return ya.which { cands = cands }, limit
end

return {
	entry = function()
		local target = hovered_dir()
		if not target then
			return
		end

		local sessions = matching_sessions(target.name)
		if #sessions == 0 then
			return prompt_new_session(target)
		end

		local choice, limit = choose_session(sessions)
		if not choice then
			return
		elseif choice <= limit then
			return attach(sessions[choice])
		end

		prompt_new_session(target)
	end,
}
