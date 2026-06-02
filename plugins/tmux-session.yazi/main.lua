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

return {
	entry = function()
		local target = hovered_dir()
		if not target then
			return
		end

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

		if write_handoff(session) then
			ya.emit("quit", {})
		end
	end,
}
