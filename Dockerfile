ARG ALPINE_VERSION="3.19"

FROM alpine:${ALPINE_VERSION}

ARG BASH_VERSION="5"
ARG AWS_CLI_VERSION="2"
ARG JQ_VERSION="1"
ARG CURL_VERSION="8"
ARG GIT_VERSION="2"
ARG GITHUB_CLI_VERSION="2"

WORKDIR /scripts

RUN apk update --no-cache; \
    apk upgrade --no-cache; \
    apk add --no-cache bash~=${BASH_VERSION} aws-cli~=${AWS_CLI_VERSION} jq~=${JQ_VERSION} curl~=${CURL_VERSION} git~=${GIT_VERSION}; \
    rm -rf /var/cache/apk/*

ENV LOG_LEVEL "INFO"
ENV LOG_TIMESTAMPED "true"
ENV DEBUG_MODE "false"

COPY scripts/utils.sh .
COPY scripts/gh-utils.sh .
COPY scripts/script.sh .

ENTRYPOINT ["/scripts/script.sh"]
