FROM postgres:15-alpine

WORKDIR /app

SHELL ["/bin/bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]

RUN apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get install -y --no-install-recommends \
    && apt-get clean \
    && rm -rf \
    /var/lib/apt/lists \
    /var/cache/apt/archives \
    /tmp/* \
    /var/tmp/*

ENTRYPOINT ["tail", "-f", "/dev/null"] 
