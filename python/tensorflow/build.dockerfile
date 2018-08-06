FROM alpine:3.7

LABEL maintainer="kautsar ab <kautsar.ab@gmail.com>"

# This image based on Dockerfile from
# https://github.com/better/alpine-tensorflow/blob/master/Dockerfile
# in the previous attempts, i had some issues with
# ERROR: ... `undefined reference for backtrace` & undefined reference for `backtrace_symbols_fd`
# and i think the line below is the solution for the problem above
# - Disable TF_GENERATE_BACKTRACE and TF_GENERATE_STACKTRACE

# TODO: refactor and clean

ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
ENV LOCAL_RESOURCES 3048,1.0,1.0

# python
RUN apk add --update \
        dumb-init \
        build-base \
        python2 \        
        py2-pip \        
        python2-tkinter \
        py2-numpy \
        py2-numpy-f2py \
        freetype \
        libpng \
        libjpeg-turbo \
        imagemagick \
        graphviz \
        git \
        libc6-compat \
        libexecinfo \
        libunwind \
    && pip install -U pip \
    && pip install virtualenv

# build deps
RUN apk add --no-cache --virtual=build-deps \
        bash \
        cmake \
        curl \
        freetype-dev \
        g++ \
        libjpeg-turbo-dev \
        libpng-dev \
        linux-headers \
        make \
        musl-dev \
        openblas-dev \
        openjdk8 \
        patch \
        perl \
        # python deps for build
        python2-dev \
        py-numpy-dev \
        # utils for build
        rsync \
        sed \
        swig \
        zip \
        libexecinfo-dev \
        libunwind-dev \
    && pip install --no-cache-dir \
        wheel \
        cython
    # && $(cd /usr/bin && ln -s python2 python)

# Download Bazel
ENV BAZEL_VERSION 0.11.0
RUN curl -SLO https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip \
    && mkdir bazel-${BAZEL_VERSION} \
    && unzip -qd bazel-${BAZEL_VERSION} bazel-${BAZEL_VERSION}-dist.zip

# Install Bazel
RUN cd bazel-${BAZEL_VERSION} \
    && sed -i -e 's/-classpath/-J-Xmx8192m -J-Xms128m -classpath/g' scripts/bootstrap/compile.sh \
    && bash compile.sh \
    && cp -p output/bazel /usr/bin/

# move to top later #
RUN pip install --no-cache-dir \
    enum34 \
    pathlib \
    backports.inspect \
    backports.pbkdf2 \
    backports.datetime_timestamp \
    mock

# Download and install glibc
RUN apk del libc6-compat && \
    ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    ALPINE_GLIBC_PACKAGE_VERSION="2.27-r0" && \
    ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    apk add --no-cache --virtual=.build-dependencies wget ca-certificates && \
    wget \
        "https://raw.githubusercontent.com/sgerrand/alpine-pkg-glibc/master/sgerrand.rsa.pub" \
        -O "/etc/apk/keys/sgerrand.rsa.pub" && \
    wget \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    apk add --no-cache \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    \
    rm "/etc/apk/keys/sgerrand.rsa.pub" && \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true && \
    echo "export LANG=$LANG" > /etc/profile.d/locale.sh && \
    \
    apk del glibc-i18n && \
    \
    rm "/root/.wget-hsts" && \
    rm \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"

# Download Tensorflow
# i'm not sure why, but using version higher than 1.7.0
# and bazel ver above 0.11.0 always giving an error :\
ENV TENSORFLOW_VERSION 1.7.0
RUN cd /tmp \
    && curl -H \
        "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.133 Safari/537.36"\
        -SL https://github.com/tensorflow/tensorflow/archive/v${TENSORFLOW_VERSION}.tar.gz \
        | tar xzf -
    
# Build Tensorflow
RUN echo \
    && export NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
    && cd /tmp/tensorflow-${TENSORFLOW_VERSION} \
    && : musl-libc does not have "secure_getenv" function \
    && sed -i -e '/JEMALLOC_HAVE_SECURE_GETENV/d' third_party/jemalloc.BUILD \
    #################################################################
    # fix for: 
    # ERROR: ... `undefined reference for backtrace` & undefined reference for `backtrace_symbols_fd`
    && sed -i -e '/define TF_GENERATE_STACKTRACE/d' tensorflow/core/platform/stacktrace_handler.cc \
    && sed -i -e '/define TF_GENERATE_BACKTRACE/d' tensorflow/core/platform/default/stacktrace.h \
    #################################################################
    # && sed -i 's/2f7fbffac0d98d201ad0586f686034371a6d152ca67508ab611adc2386ad30de/beea5943641803343c0d037a12d86a019ff72b1a870310d2397a399eab69f708/g' tensorflow/workspace.bzl \
    && PYTHON_BIN_PATH=/usr/bin/python \
        PYTHON_LIB_PATH=/usr/lib/python2.7/site-packages \
        CC_OPT_FLAGS="-march=native" \
        TF_NEED_JEMALLOC=1 \
        TF_NEED_GCP=0 \
        TF_NEED_HDFS=0 \
        TF_NEED_S3=0 \
        TF_ENABLE_XLA=0 \
        TF_NEED_GDR=0 \
        TF_NEED_VERBS=0 \
        TF_NEED_OPENCL=0 \
        TF_NEED_CUDA=0 \
        TF_NEED_MPI=0 \
        bash configure

# Run Tensorflow Build
RUN cd /tmp/tensorflow-${TENSORFLOW_VERSION} \
    && bazel clean --expunge \
    && bazel build \
        --jobs $(($NPROC+0)) \
        --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=0" \
        -c opt //tensorflow/tools/pip_package:build_pip_package
    # use the command below instead of the command above, if you have some problem with memory usage
    # && bazel build -c opt --local_resources ${LOCAL_RESOURCES} //tensorflow/tools/pip_package:build_pip_package

# Build python wheel
RUN cd /tmp/tensorflow-${TENSORFLOW_VERSION} \
    && ./bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg

# Copy Tensorflow wheel file to /wheels
RUN mkdir -p /wheels \
    && cp /tmp/tensorflow_pkg/tensorflow-${TENSORFLOW_VERSION}-*.whl /wheels

# Make sure it's built properly
RUN pip install --no-cache-dir /wheels/tensorflow-${TENSORFLOW_VERSION}-*.whl \
    && python -c 'import tensorflow'

# Cleaning stuff
RUN rm -rf \
        /var/cache/apk/* \
        /tmp/* \
        /var/tmp/* \
    && apk del --purge build-deps

CMD ["/bin/sh"]
