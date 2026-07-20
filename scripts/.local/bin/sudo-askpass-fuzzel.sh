#!/usr/bin/env bash
set -euo pipefail

exec fuzzel --dmenu --password --prompt="sudo: " --lines=0 --width=32
