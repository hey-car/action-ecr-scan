ARG BASE_RUNNER_IMAGE_VERSION="1.3.0"

FROM heycardocker/infra-docker-actions:${BASE_RUNNER_IMAGE_VERSION}

WORKDIR /scripts

ENV LOG_LEVEL "INFO"
ENV LOG_TIMESTAMPED "true"
ENV DEBUG_MODE "false"

COPY scripts/utils.sh .
COPY scripts/gh-utils.sh .
COPY scripts/script.sh .

ENTRYPOINT ["/scripts/script.sh"]
