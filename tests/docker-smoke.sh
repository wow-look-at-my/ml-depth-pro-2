#!/usr/bin/env bash
# Builds the image, then checks that predict refuses to run on a machine with no GPU.
set -euo pipefail
cd "$(dirname "$0")/.."

export COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml:tests/compose.cpu.yml}"
export PUID="${PUID:-$(id -u)}" PGID="${PGID:-$(id -g)}"
predict=(docker compose run --rm -T depth-pro-2 predict -i assets/example.jpg -o out/ -m depthpro2-s)

rm -f out/example-depth.png
docker compose build

if refusal="$("${predict[@]}" 2>&1)"; then
	echo "FAIL: predict ran on a machine without CUDA" >&2
	exit 1
fi
if [[ "$refusal" != *"no usable cuda device"* ]]; then
	echo "FAIL: predict stopped for another reason: $refusal" >&2
	exit 1
fi
if [[ -e out/example-depth.png ]]; then
	echo "FAIL: predict wrote out/example-depth.png without CUDA" >&2
	exit 1
fi
echo "PASS"
