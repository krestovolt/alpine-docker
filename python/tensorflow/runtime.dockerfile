FROM alpine:3.7 as base

FROM base as builder

COPY wheels /wheels

RUN \
    apk add --no-cache python && \
    python -m ensurepip && \
    pip install --upgrade pip setuptools && \
    mkdir -p /install && \
    cd /install && \
    pip install --prefix=/install --no-index --find-links=/wheels --no-warn-script-location \
        numpy \
        scipy \
        apache-airflow \
        keras \
        h5py \
        tensorflow && \
    rm -rf \
        /usr/lib/python*/ensurepip \
        /var/cache/apk/* \
        /tmp/* \
        /usr/.cache \
        /var/tmp/* \
        /usr/share/man \
        /usr/share/doc

FROM base

COPY --from=builder /install /usr

RUN \
    apk add --no-cache python libstdc++ openblas && \
    python -m ensurepip && \
    rm -rf \
        /usr/lib/python*/ensurepip \
        /var/cache/apk/* \
        /tmp/* \
        /usr/.cache \
        /var/tmp/* \
        /usr/share/man \
        /usr/share/doc

EXPOSE 6006

CMD ["/bin/sh"]
