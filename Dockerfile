# syntax=docker/dockerfile:1
# Docker Hardened Images (DHI) for ZEO Server

ARG PYTHON_VERSION=3.12
ARG DEBIAN_VERSION=debian13

# ============================================================================
# Builder Stage - Uses -dev variant with build tools
# ============================================================================
FROM dhi.io/python:${PYTHON_VERSION}-${DEBIAN_VERSION}-dev AS builder

COPY --from=dhi.io/uv:0 /uv /usr/local/bin/uv

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    UV_COMPILE_BYTECODE=1 \
    ZEO_HOME=/opt/zeo


# Setup virtual environment and copy requirements
RUN uv venv $ZEO_HOME
COPY requirements.txt $ZEO_HOME/

# Install ZEO
RUN uv pip install --python=$ZEO_HOME/bin/python -r $ZEO_HOME/requirements.txt

# Create necessary directories
RUN mkdir -p $ZEO_HOME/etc \
    $ZEO_HOME/var

# ============================================================================
# Runtime Stage - Minimal image for production
# ============================================================================
FROM dhi.io/python:${PYTHON_VERSION}-${DEBIAN_VERSION}-dev AS runtime

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    ZEO_HOME=/opt/zeo \
    ZEO_DATA_DIR=/data \
    ZEO_UID=1000 \
    ZEO_GID=1000 \
    PATH="/opt/zeo/bin:$PATH"

# Install only necessary runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    gosu \
    passwd \
    netcat-openbsd && \
    rm -rf /var/lib/apt/lists/*

# Create zeo user and data directory
RUN groupadd -g ${ZEO_GID} zeo && \
    useradd -g ${ZEO_GID} -u ${ZEO_UID} -m -s /bin/bash zeo && \
    mkdir -p ${ZEO_DATA_DIR} && \
    chown -R ${ZEO_UID}:${ZEO_GID} ${ZEO_DATA_DIR}

# Copy built environment and configurations
COPY --from=builder --chown=${ZEO_UID}:${ZEO_GID} $ZEO_HOME $ZEO_HOME
COPY src/docker-entrypoint.sh /

RUN chmod +x /docker-entrypoint.sh

WORKDIR $ZEO_HOME

# Expose ZEO port
EXPOSE 8100

HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=30s \
    CMD ["nc", "-z", "127.0.0.1", "8100"]

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["start"]

USER zeo
