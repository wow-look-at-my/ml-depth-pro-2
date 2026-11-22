# AGENTS.md

Depth Pro 2: metric depth for photos and videos, on Linux and Apple silicon Macs. The README has
the usage, what the outputs mean and which settings to use; read it first. This file adds what you
need to call, extend or export the code.

## Setup and check

```bash
uv sync
uv run depth-pro-2 predict -i assets/example.jpg -o out/ -m depthpro2-s
uv run depth-pro-2 predict -i assets/example.mp4 -o out/ -m depthpro2-s
```

`predict` prints the focal length it used and a depth range in meters.

`tests/docker-smoke.sh` builds the Docker image and checks that `predict` refuses to run on a machine with no GPU. CI runs it on every push.

## Code

- `src/depth_pro_2/model.py`: model presets, weight loading, `infer`, `infer_video`, `stream`.
- `src/depth_pro_2/streaming.py`: the video session behind `infer_video` and `stream`, both modes.
- `src/depth_pro_2/network/`: the encoder and its key-value cache for unbuffered mode, the
  decoder, and the field-of-view estimator.
- `src/depth_pro_2/utils.py`: `load_rgb` (a photo, upright, with its EXIF focal length),
  `upright` (a decoded video frame, upright), `default_device`.
- `src/depth_pro_2/cli.py`: the `predict` command.
- `Dockerfile`, `docker-compose.yml`: the container for Linux with an NVIDIA GPU. `in/` and `out/` are its default host folders.
- `demo/`: the Mac demo (`apple/`, Swift) and its Core ML exporter (`export/`, `uv sync --extra coreml`).

## Facts not in the README

- Weights: `checkpoints/<file>` under the current working directory is used instead of
  downloading, with the file names of `PRESETS` and `DepthPro2Config.fov_checkpoint_uri`
  (e.g. `depthpro2-s-bgcc6f8bg3.pt` and `depthpro2-fov-ew55zg4kq7.pt`).
- The network predicts inverse depth normalized by the focal length: depth in meters is
  `f_px / (width * inverse_depth)`.
- Export: `torch.export` works on `DepthPro2.forward` (normalized frames padded to a multiple of
  32 in, inverse depth out; one input size per export, and padding more than that changes the
  depth) and on `model.fov.focal_length_px`. For unbuffered mode, start from `CausalStep` in
  `demo/export/stream.py`, one frame per call with its cache kept as model state.
