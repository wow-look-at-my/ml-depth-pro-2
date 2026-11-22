# syntax=docker/dockerfile:1

FROM python:3.12-slim-trixie AS build
COPY --from=ghcr.io/astral-sh/uv:0.13.9 /uv /usr/local/bin/uv

# The CUDA build of PyTorch.
ARG TORCH_BACKEND=cu126
ENV UV_LINK_MODE=copy \
    UV_COMPILE_BYTECODE=1 \
    UV_PYTHON_DOWNLOADS=never \
    VIRTUAL_ENV=/opt/venv

WORKDIR /src
RUN uv venv /opt/venv
# The dependencies go in before the source. A source edit then keeps this layer.
COPY pyproject.toml ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --torch-backend "${TORCH_BACKEND}" -r pyproject.toml
COPY README.md ./
COPY src ./src
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --no-deps .


FROM python:3.12-slim-trixie
COPY --from=build /opt/venv /opt/venv

# /cache holds the downloaded weights. It accepts any user id, as /tmp does.
RUN mkdir /in /out && mkdir -m 1777 /cache

ENV PATH=/opt/venv/bin:$PATH \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HOME=/tmp \
    MPLCONFIGDIR=/tmp/matplotlib \
    XDG_CACHE_HOME=/cache

USER 1000:1000
ENTRYPOINT ["depth-pro-2"]
CMD ["--help"]
