#!/bin/sh
echo -ne '\033c\033]0;Chore Engine 4\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Chore Engine 4.x86_64" "$@"
