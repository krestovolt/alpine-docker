FROM frolvlad/alpine-glibc:alpine-3.7

LABEL maintainer="kautsar ab <kautsar.ab@gmail.com>"

ENV LANG=C.UTF-8

# minimal python
RUN apk add --no-cache python && \
    python -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip install --upgrade pip setuptools && \
    rm -r /root/.cache

# other deps
RUN apk add --update \
        dumb-init \
        build-base \
        python2-tkinter \
        py-numpy \
        py-numpy-f2py \
        freetype \
        libpng \
        libjpeg-turbo \
        imagemagick \
        graphviz \
        git \
        libexecinfo
    
# build deps
ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
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
        py-numpy-dev \
        rsync \
        sed \
        swig \
        zip && \
    pip install --no-cache-dir \
        wheel \
        cython \
        mock \
        enum34 \
        pathlib \
        backports.inspect \
        backports.pbkdf2 \
        backports.datetime_timestamp

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

# Download Tensorflow
ENV TENSORFLOW_VERSION 1.7.0
RUN cd /tmp \
    && curl -H \
        "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.133 Safari/537.36"\
        -SL https://github.com/tensorflow/tensorflow/archive/v${TENSORFLOW_VERSION}.tar.gz \
        | tar xzf -

# Config Build Tensorflow
RUN cd /tmp/tensorflow-${TENSORFLOW_VERSION} \
    && : musl-libc does not have "secure_getenv" function \
    && sed -i -e '/JEMALLOC_HAVE_SECURE_GETENV/d' third_party/jemalloc.BUILD \
    && sed -i -e '/define TF_GENERATE_BACKTRACE/d' tensorflow/core/platform/default/stacktrace.h \
    && sed -i -e '/define TF_GENERATE_STACKTRACE/d' tensorflow/core/platform/stacktrace_handler.cc \
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

# Build Tensorflow
RUN cd /tmp/tensorflow-${TENSORFLOW_VERSION} \
    && bazel build \        
        -c opt --cxxopt="-D_GLIBCXX_USE_CXX11_ABI=0" //tensorflow/tools/pip_package:build_pip_package

# Build python wheel
RUN cd /tmp/tensorflow-${TENSORFLOW_VERSION} \
    && ./bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg

# Copy Tensorflow wheel file to /wheels
RUN mkdir -p /wheels \
    && cp /tmp/tensorflow_pkg/tensorflow-${TENSORFLOW_VERSION}-*.whl /wheels

# Make sure it's built properly
RUN pip install --no-cache-dir /wheels/tensorflow-${TENSORFLOW_VERSION}-*.whl \
    && python -c 'import tensorflow'

CMD ["/bin/sh"]
