#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || -z "${1:-}" ]]; then
	exit 0
fi

path=$1

if [[ ! -f "$path" ]]; then
	exit 0
fi

dir=$(dirname -- "$path")
base=$(basename -- "$path")
unchecked='[ ] - '
checked='[x] - '

if [[ "$base" == "$unchecked"* ]]; then
	target=$checked${base#"$unchecked"}
elif [[ "$base" == "$checked"* ]]; then
	target=$unchecked${base#"$checked"}
else
	exit 0
fi

target_path=$dir/$target

if [[ -e "$target_path" ]]; then
	printf 'Refusing to overwrite existing path: %s\n' "$target_path" >&2
	exit 1
fi

mv -- "$path" "$target_path"
