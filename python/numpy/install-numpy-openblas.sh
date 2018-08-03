#!/bin/sh

# Source: https://hub.docker.com/r/o76923/alpine-numpy-stack/~/dockerfile/

# 1. Add repositories.
echo "using Alpine V${ALPINE_VERSION} | Numpy V${NUMPY_VERSION} | OpenBlas V${OPENBLAS_VERSION}"
echo "http://nl.alpinelinux.org/alpine/v${ALPINE_VERSION}/main" > /etc/apk/repositories
echo "http://nl.alpinelinux.org/alpine/v${ALPINE_VERSION}/community" >> /etc/apk/repositories
echo "@edge http://nl.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories

apk --no-cache --update upgrade
apk --no-cache --update add openblas-dev
# Add openssl for fetching from https-URLs.
apk --no-cache --update add openssl ca-certificates
update-ca-certificates

# 2. Install openblas.
export NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1)
apk --no-cache --update add --virtual build-deps \
    musl-dev \
    linux-headers \
    zlib-dev \
    jpeg-dev \
    g++ \
    gcc
cd /tmp 
ln -s /usr/include/locale.h /usr/include/xlocale.h
pip install cython
cd /tmp
wget https://github.com/numpy/numpy/releases/download/v$NUMPY_VERSION/numpy-$NUMPY_VERSION.tar.gz
tar -xzf numpy-$NUMPY_VERSION.tar.gz
rm numpy-$NUMPY_VERSION.tar.gz
cd numpy-$NUMPY_VERSION/
cp site.cfg.example site.cfg
echo -en "\n[openblas]\nlibraries = openblas\nlibrary_dirs = /usr/lib\ninclude_dirs = /usr/include\n" >> site.cfg
python setup.py build -j ${NPROC} --fcompiler=gfortran install
cd /tmp
rm -r numpy-$NUMPY_VERSION