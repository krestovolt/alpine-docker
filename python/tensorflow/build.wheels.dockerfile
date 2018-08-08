FROM frolvlad/alpine-glibc:alpine-3.7

ENV NUMPY_VERSION=1.15.0 \
    OPENBLAS_VERSION=0.3.0 \
    ALPINE_VERSION=3.7 \
    JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk \
    LOCAL_RESOURCES=3048,.5,1.0 \    
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

RUN \
    echo "http://nl.alpinelinux.org/alpine/v${ALPINE_VERSION}/main" > /etc/apk/repositories \
    && echo "http://nl.alpinelinux.org/alpine/v${ALPINE_VERSION}/community" >> /etc/apk/repositories \
    && echo "@edge http://nl.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
    && echo "http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

COPY ./requirements.txt ./requirements.txt

# install deps for build numpy
RUN \
    apk add --no-cache --virtual build-deps \
        cmake \
        unzip \
        zip \
        curl \
        freetype-dev \
        g++ \
        gcc \
        libjpeg-turbo-dev \
        libpng-dev \
        linux-headers \
        make \
        musl-dev \
        openblas-dev \
        openjdk8 \
        patch \
        perl \
        rsync \
        sed \
        swig \
        postgresql-dev \
        mod_dav_svn \
        subversion \
        py-lxml \
        build-base \
        lcms2-dev \
        libwebp-dev \
        libffi-dev \
		zlib-dev \
		libxml2 \
		libxml2-dev \
		libxslt-dev \
        libexecinfo-dev \
        libunwind-dev \
        libunwind \
        libexecinfo \
        glib-dev \
        libc-dev \
        hdf5-dev

# install deps for utility
RUN \
    export NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
    && apk --update add \
        openssl \
        ca-certificates \
        bash \
        python-dev \
        python2 \
        python2-dev \
        py-setuptools \
        dumb-init \
        hdf5 \
    && update-ca-certificates \
    && if [[ ! -e /usr/bin/python ]];        then ln -sf /usr/bin/python2.7 /usr/bin/python; fi \
    && if [[ ! -e /usr/bin/python-config ]]; then ln -sf /usr/bin/python2.7-config /usr/bin/python-config; fi \
    && if [[ ! -e /usr/bin/easy_install ]]; then ln -sf /usr/bin/easy_install-2.7 /usr/bin/easy_install; fi \
    && easy_install pip \
    && pip install --upgrade pip \
    && if [[ ! -e /usr/bin/pip ]]; then ln -sf /usr/bin/pip2.7 /usr/bin/pip; fi

# install python package recuired for build
RUN \
    ln -s /usr/include/locale.h /usr/include/xlocale.h \
    && pip install --upgrade pip \
    && pip install \
        wheel \
        six \
        cython \
        setuptools \
        h5py

# build and install numpy
RUN \    
    cd /tmp \
    && cd /tmp \
    && wget https://github.com/numpy/numpy/releases/download/v$NUMPY_VERSION/numpy-$NUMPY_VERSION.tar.gz \
    && tar -xzf numpy-$NUMPY_VERSION.tar.gz \
    && rm numpy-$NUMPY_VERSION.tar.gz \
    && cd numpy-$NUMPY_VERSION/ \
    && cp site.cfg.example site.cfg \
    && echo -en "\n[openblas]\nlibraries = openblas\nlibrary_dirs = /usr/lib\ninclude_dirs = /usr/include\n" >> site.cfg \
    && python setup.py build -j$(($NPROC+0)) --fcompiler=gfortran install \
    && cd /tmp \
    && rm -r numpy-$NUMPY_VERSION

# make wheels
RUN \
    mkdir -p /wheels \    
    && pip install -r ./requirements.txt \
    && pip wheel --wheel-dir=/wheels numpy \
    && pip wheel --find-links=/wheels --wheel-dir=/wheels -r ./requirements.txt

# clean build deps
RUN \
    rm -rf \
        /var/cache/apk/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/man \
        /usr/share/doc \
    && apk --no-cache del --purge build-deps

CMD ["/bin/sh"]
