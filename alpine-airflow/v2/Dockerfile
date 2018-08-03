FROM python:2.7-alpine3.7

LABEL maintainer="krestovolt"
##########################################
# 1. Copy relevant files into container.
##########################################

# Copy file with python requirements into container.
COPY requirements.txt /tmp/requirements.txt
# Copy file containing commands for installing numpy versus openblas.
COPY install-numpy-openblas.sh /tmp/install-numpy-openblas.sh

##########################################
# 2. Prepare environment variables.
##########################################

# Set versions of numpy and openblas to be installed.
ENV NUMPY_VERSION="1.15.0" \ 
	OPENBLAS_VERSION="0.3.0" \
    ALPINE_VERSION=3.7

##########################################
# 3. Install numpy with openblas.
##########################################

RUN apk --no-cache --update upgrade && \
	# Make setup script executable.
	chmod +x /tmp/install-numpy-openblas.sh && \
	# Install various drivers required by python dependencies.
	apk add --no-cache libffi-dev && \
	apk add --no-cache zlib-dev && \
	apk add --no-cache libxml2 && \
	apk add --no-cache libxml2-dev && \
	apk add --no-cache libxslt-dev && \
	# Workaround to avoid "Text file busy" message.
	sync && \
	# Install numpy with openblas.
 	./tmp/install-numpy-openblas.sh && \
 	# Install python dependencies.
	pip install -r /tmp/requirements.txt && \
	# Cleaning stuff
	apk --no-cache del --purge build-deps && \
    rm -rf \
        /etc/ssl \
        /tmp/elixir \
        /var/cache/apk/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/man \
        /usr/share/doc

CMD ["/bin/sh"]