FROM alpine:3.7
LABEL maintainer "kautsar.ab@gmail.com"

ENV REFRESHED_AT=2018-06-30 \
    LANG=en_US.UTF-8 \
    # Default workdir that owned by current user root
    HOME=/opt/app/ \
    # Set this so that CTRL+G works properly
    TERM=xterm \
    # Change this to latest ver if needed
    ERLANG_VERSION=21.0 \
    ELIXIR_VERSION=1.6.6 \
    ALPINE_VERSION=3.7

WORKDIR /tmp/erlang-build

# Install Erlang
RUN \
    # Create default user and home directory, set owner to default
    mkdir -p "${HOME}" \
    && adduser -s /bin/sh -u 1001 -G root -h "${HOME}" -S -D default \
    && chown -R 1001:0 "${HOME}" \
    # Add tagged repos as well as the edge repo so that we can selectively install edge packages
    && echo "@main http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/main" >> /etc/apk/repositories \
    && echo "@community http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/community" >> /etc/apk/repositories \
    && echo "@edge http://nl.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories \
    # Upgrade Alpine and base packages
    && apk --no-cache --update upgrade \    
    && apk add --no-cache --update \
        # Distillery requires bash
        bash@main \
        # Install Erlang/OTP deps
        pcre@edge \  
        ca-certificates@main \
        openssl-dev@main \
        ncurses-dev@main \
        unixodbc-dev@main \
        zlib-dev@main \
    # Erlang build step
    # Install Erlang/OTP build deps
    && apk add --no-cache --update --virtual .build-deps \
        dpkg-dev@main \
        dpkg@main \
        git \
        autoconf@main \
        build-base@main \
        perl-dev@main \
    # Shallow clone Erlang/OTP
    && git clone -b OTP-$ERLANG_VERSION --single-branch --depth 1 https://github.com/erlang/otp.git . \
    # Erlang/OTP build env
    && export ERL_TOP=/tmp/erlang-build \
    && export PATH=$ERL_TOP/bin:$PATH \
    && export CPPFlAGS="-D_BSD_SOURCE -O3 -mtune=native $CPPFLAGS" \
    # Configure
    && ./otp_build autoconf \
    && ./configure --prefix=/usr \
      --build="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
      --sysconfdir=/etc \
      --mandir=/usr/share/man \
      --infodir=/usr/share/info \
      --without-javac \
      --without-wx \
      --without-debugger \
      --without-observer \
      --without-jinterface \
      --without-cosEvent\
      --without-cosEventDomain \
      --without-cosFileTransfer \
      --without-cosNotification \
      --without-cosProperty \
      --without-cosTime \
      --without-cosTransactions \
      --without-et \
      --without-gs \
      --without-ic \
      --without-megaco \
      --without-orber \
      --without-percept \
      --without-typer \
      --enable-threads \
      --enable-shared-zlib \
      --enable-ssl=dynamic-ssl-lib \
      --enable-hipe \
    # Build
    && make -j4 && make install \    
    # Elixir build step
    && mkdir -p "/tmp/elixir-build" \
    && cd /tmp/elixir-build \
    && git clone https://github.com/elixir-lang/elixir --depth 1 --branch v$ELIXIR_VERSION \
    && cd elixir \
    && make && make install \
    && mix local.hex --force \
    && mix local.rebar --force \
    # Cleanup
    && rm -rf /tmp/elixir-build \
    && rm -rf /tmp/erlang-build \
    && rm -rf /var/cache/apk/* \
    && apk del --force .build-deps \
    # Set location to /opt/app/
    && cd $HOME \
    # Update ca certificates
    && update-ca-certificates --fresh

WORKDIR ${HOME}

CMD ["/bin/sh"]