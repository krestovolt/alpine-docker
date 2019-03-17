FROM alpine:3.8
LABEL maintainer "kautsar.ab@gmail.com"

ENV REFRESHED_AT=2018-06-30 \
    ELIXIR_VERSION=1.8.1 \
    HOME=/opt/app/
ENV PATH="$PATH:/opt/elixir-${ELIXIR_VERSION}/bin"

WORKDIR /tmp/elixir

RUN \
    # Install Erlang and Bash
    apk upgrade --no-cache --update && \
    apk add --no-cache --update \
        erlang erlang-ssl erlang-inets erlang-crypto erlang-erts erlang-observer \
        erlang-hipe erlang-public-key erlang-asn1 erlang-tools \
        bash && \
    # make /opt/app dir for Home
    mkdir -p "${HOME}" && \
    adduser -s /bin/sh -u 1001 -G root -h "${HOME}" -S -D default && \
    apk add --update --virtual build-dependencies wget ca-certificates && \
    wget --no-check-certificate https://github.com/elixir-lang/elixir/releases/download/v${ELIXIR_VERSION}/Precompiled.zip && \
    mkdir -p /opt/elixir-${ELIXIR_VERSION}/ && \
    unzip Precompiled.zip -d /opt/elixir-${ELIXIR_VERSION}/ && \
    rm Precompiled.zip && \
    # go home
    cd $HOME && \
    PATH="$PATH:/opt/elixir-${ELIXIR_VERSION}/bin" &&\
    mix local.hex --force && \
    mix local.rebar --force && \
    # clean
    apk del build-dependencies && \
    rm -rf /etc/ssl && \
    rm -rf /tmp/elixir && \
    rm -rf /var/cache/apk/*

WORKDIR $HOME

CMD ["/bin/sh"]
