#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 || -z "${1:-}" ]]; then
	exit 0
fi

dir=$1

if [[ ! -d "$dir" ]]; then
	printf 'Not a directory: %s\n' "$dir" >&2
	read -r -p 'Press enter to continue...' _
	exit 0
fi

if [[ $# -eq 2 ]]; then
	session=$2
else
	session=$(basename -- "$dir")
fi

if [[ -z "$session" ]]; then
	exit 0
fi

if ! tmux has-session -t "=$session" 2>/dev/null; then
	tmux new-session -d -s "$session" -c "$dir"
fi

ya emit quit >/dev/null 2>&1 || true

if [[ -n "${TMUX:-}" ]]; then
	tmux switch-client -t "=$session"
else
	exec tmux attach-session -t "=$session"
fi
