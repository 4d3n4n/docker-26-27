# syntax=docker/dockerfile:1.7
FROM python:3.12.12-slim-bookworm@sha256:593bd06efe90efa80dc4eee3948be7c0fde4134606dd40d8dd8dbcade98e669c AS builder
ARG TARGETARCH
ENV VIRTUAL_ENV=/opt/venv \
    PATH="/opt/venv/bin:${PATH}" \
    PIP_DISABLE_PIP_VERSION_CHECK=1
WORKDIR /app
RUN python -m venv /opt/venv
COPY requirements.txt ./
RUN --mount=type=secret,id=pipconf,target=/etc/pip.conf,required=true \
    --mount=type=cache,id=pip-${TARGETARCH},target=/root/.cache/pip,sharing=locked \
    pip install --no-input -r requirements.txt

FROM builder AS test
ARG TARGETARCH
COPY requirements-dev.txt ./
RUN --mount=type=secret,id=pipconf,target=/etc/pip.conf,required=true \
    --mount=type=cache,id=pip-${TARGETARCH},target=/root/.cache/pip,sharing=locked \
    pip install --no-input -r requirements-dev.txt
COPY worker/ ./worker/
COPY tests/ ./tests/
RUN python -m pytest -q && ruff check worker tests

FROM python:3.12.12-slim-bookworm@sha256:593bd06efe90efa80dc4eee3948be7c0fde4134606dd40d8dd8dbcade98e669c AS runtime
ARG APP_VERSION=1.0
ARG GIT_SHA=local
LABEL org.opencontainers.image.version="${APP_VERSION}" \
      org.opencontainers.image.revision="${GIT_SHA}" \
      org.opencontainers.image.source="https://github.com/4d3n4n/docker-26-27"
ENV VIRTUAL_ENV=/opt/venv \
    PATH="/opt/venv/bin:${PATH}" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
RUN groupadd --system worker && useradd --system --gid worker worker
WORKDIR /app
COPY --from=builder /opt/venv /opt/venv
COPY --from=test --chown=worker:worker /app/worker ./worker
USER worker
EXPOSE 9100
CMD ["python", "-m", "worker.main"]
