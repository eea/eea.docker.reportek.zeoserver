FROM almalinux:8.10

ENV ZEO_HOME=/opt/zeoserver \
    ZEO_USERNAME=zope-www \
    ZEO_UID=500 \
    ZEO_GID=500 \
    PIP=20.3.4 \
    ZC_BUILDOUT=3.0.1 \
    SETUPTOOLS=44.1.1 \
    GOSU_VERSION=1.17

RUN groupadd -g $ZEO_GID $ZEO_USERNAME \
    && useradd -u $ZEO_UID -g $ZEO_GID -m -s /bin/bash $ZEO_USERNAME \
    && mkdir -p $ZEO_HOME /data/filestorage /data/blobstorage \
    && chown -R $ZEO_UID:$ZEO_GID $ZEO_HOME

COPY src/base.cfg  $ZEO_HOME/
COPY docker-manage-permissions.sh docker-entrypoint.sh docker-initialize.py /

RUN dnf -y update && dnf module install -y python27 && \
    dnf install -y gcc wget redhat-rpm-config bzip2-devel libffi-devel openssl-devel python2-devel && \
    alternatives --set python /usr/bin/python2 && \
    python -m ensurepip --upgrade && python -m pip install -U pip && \
    pip install pip==$PIP setuptools==$SETUPTOOLS zc.buildout==$ZC_BUILDOUT && \
    cd $ZEO_HOME && \
    buildout -c base.cfg && \
    chown -R $ZEO_UID:$ZEO_GID $ZEO_HOME && \
    rpmArch="$(rpm --query --queryformat='%{ARCH}' rpm)"; \
    case "$rpmArch" in \
    aarch64) dpkgArch='arm64' ;; \
    armv[67]*) dpkgArch='armhf' ;; \
    i[3456]86) dpkgArch='i386' ;; \
    ppc64le) dpkgArch='ppc64el' ;; \
    riscv64 | s390x) dpkgArch="$rpmArch" ;; \
    x86_64) dpkgArch='amd64' ;; \
    *) echo >&2 "error: unknown/unsupported architecture '$rpmArch'"; exit 1 ;; \
    esac; \
    wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
    wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
    \
    # verify the signature
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
    gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
    gpgconf --kill all; \
    rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
    \
    chmod +x /usr/local/bin/gosu; \
    # verify that the binary works
    gosu --version; \
    gosu nobody true; \
    dnf remove -y wget gcc redhat-rpm-config bzip2-devel libffi-devel openssl-devel python2-devel && \
    dnf clean all && \
    rm -rf /var/cache/dnf

WORKDIR $ZEO_HOME

VOLUME /data

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["start"]
