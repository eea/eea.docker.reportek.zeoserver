# Reportek ZEO Server Docker Image

Docker image for Reportek ZEO server. This image provides a minimal, hardened Python environment to run a ZEO server, built using `uv`.

### Base docker image

 - `dhi.io/python:3.12-debian13-dev`

### Source code

  - [github.com/eea/eea.docker.reportek.zeoserver](https://github.com/eea/eea.docker.reportek.zeoserver)

### Installation

1. Install [Docker](https://www.docker.com/).

## Usage

This image is built to be minimal and runs `runzeo` out of the box using a dynamically generated configuration.

### Run with basic configuration

    $ docker run -p 8100:8100 eeacms/reportek.zeoserver

The server will start listening on port `8100`. The default installation directory inside the container is `/opt/zeo`.

## Persistent data

For production use, to avoid data loss, you must keep your `Data.fs` and blobs within Docker volumes or host bind mounts. The entrypoint script will automatically ensure the mounted volumes have the correct ownership upon startup.

### Docker Compose example

A `docker-compose.yml` file for `zeoserver` using named volumes:

```yaml
services:
  zeoserver:
    image: eeacms/reportek.zeoserver
    ports:
      - "8100:8100"
    volumes:
      - zeo-data:/data

volumes:
  zeo-data:
```

## Supported commands

The entrypoint supports the following commands overriding the default start behavior:
  - `start` (or `fg`): Start ZEO (default)
  - `python`: Run the Python interpreter inside the ZEO virtual environment
  - `shell` (or `bash`): Start a bash shell as the internal user

Example of starting a shell for debugging:
    
    $ docker run -it --rm eeacms/reportek.zeoserver shell

## Supported environment variables

You can configure the container at runtime by passing the following environment variables:

| Variable | Description | Default |
| -------- | ----------- | ------- |
| `ZEO_HOME` | ZEO installation directory | `/opt/zeo` |
| `ZEO_DATA_DIR` | Directory where data and sockets are kept | `/data` |
| `ZEO_USER` | User to run ZEO as | `zeo` |
| `ZEO_UID` | UID for the ZEO user | `1000` |
| `ZEO_GID` | GID for the ZEO group | `1000` |
| `ZEO_PACK_KEEP_OLD` | Keep old ZODB pack files (`Data.fs.old`) | `true` |

When mounting external volumes (such as `/data`), the entrypoint will automatically adjust ownership to match the `ZEO_UID` and `ZEO_GID` provided.

## Copyright and license

The Initial Owner of the Original Code is European Environment Agency (EEA).
All Rights Reserved.

The Original Code is free software;
you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation;
either version 2 of the License, or (at your option) any later
version.

## Funding

[European Environment Agency (EU)](http://eea.europa.eu)
