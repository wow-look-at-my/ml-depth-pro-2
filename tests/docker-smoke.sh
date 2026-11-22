#!/usr/bin/env bash
# Builds the image with CPU PyTorch and runs the example photo through docker-compose.yml.
set -euo pipefail
cd "$(dirname "$0")/.."

export COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml:tests/compose.cpu.yml}"
export PUID="${PUID:-$(id -u)}" PGID="${PGID:-$(id -g)}"
predict=(docker compose run --rm -T depth-pro-2 predict -i /in/example.jpg -o /out -m depthpro2-s)

cp assets/example.jpg in/
rm -f out/example-depth.png
docker compose build

"${predict[@]}"
if [[ ! -s out/example-depth.png ]]; then
	echo "FAIL: the run wrote no out/example-depth.png" >&2
	exit 1
fi

# This machine has no GPU, so a request for CUDA must stop the run.
if refusal="$(DEPTH_PRO_2_DEVICE=cuda "${predict[@]}" 2>&1)"; then
	echo "FAIL: --device cuda ran on a machine without CUDA" >&2
	exit 1
fi
if [[ "$refusal" != *"no usable cuda device"* ]]; then
	echo "FAIL: --device cuda stopped for another reason: $refusal" >&2
	exit 1
fi
echo "PASS"
