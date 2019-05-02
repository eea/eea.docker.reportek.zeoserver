FROM python:2.7-slim-stretch
MAINTAINER "EEA: IDM2 C-TEAM" <eea-edw-c-team-alerts@googlegroups.com>

ENV ZEO_HOME=/opt/zeoserver \
    ZEO_USERNAME=zope-www \
    ZEO_UID=500 \
    ZEO_GID=500 \
    PIP=9.0.3 \
    ZC_BUILDOUT=2.11.2 \
    SETUPTOOLS=38.7.0

RUN groupadd -g $ZEO_GID $ZEO_USERNAME \
    && useradd -u $ZEO_UID -g $ZEO_GID -m -s /bin/bash $ZEO_USERNAME \
    && mkdir -p $ZEO_HOME \
    && chown -R $ZEO_UID:$ZEO_GID $ZEO_HOME

COPY src/base.cfg  $ZEO_HOME/
COPY docker-manage-permissions.sh docker-entrypoint.sh docker-initialize.py /

RUN buildDeps="dpkg-dev gcc libbz2-dev libc6-dev libjpeg62-turbo-dev libopenjp2-7-dev libpcre3-dev libssl-dev libtiff5-dev libxml2-dev libxslt1-dev wget zlib1g-dev" \
 && runDeps="gosu libjpeg62 libopenjp2-7 libtiff5 libxml2 libxslt1.1 lynx netcat poppler-utils rsync wv" \
 && apt-get update \
 && apt-get install -y --no-install-recommends $buildDeps \
 && pip install pip==$PIP setuptools==$SETUPTOOLS zc.buildout==$ZC_BUILDOUT \
 && cd $ZEO_HOME \
 && buildout -c base.cfg \
 && apt-get purge -y --auto-remove $buildDeps \
 && apt-get install -y --no-install-recommends $runDeps \
 && rm -rf /var/lib/apt/lists/*

WORKDIR $ZEO_HOME

VOLUME $ZEO_HOME/var/

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["start"]
