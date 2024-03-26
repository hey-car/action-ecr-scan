ARG BASE_RUNNER_IMAGE_VERSION="1.2.0"

FROM ghcr.io/hey-car/infra-docker-actions:${BASE_RUNNER_IMAGE_VERSION}

WORKDIR /scripts

ENV LOG_LEVEL "INFO"
ENV LOG_TIMESTAMPED "true"
ENV DEBUG_MODE "false"

COPY scripts/utils.sh .
COPY scripts/gh-utils.sh .
COPY scripts/script.sh .

ENTRYPOINT ["/scripts/script.sh"]
