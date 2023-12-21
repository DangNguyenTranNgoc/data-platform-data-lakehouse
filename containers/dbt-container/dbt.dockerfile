FROM python:3.10.13-slim-bullseye

WORKDIR /app

COPY ./requirements.txt .
COPY ./profiles.yml .

SHELL ["/bin/bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]

RUN mkdir /.local && chmod g+rwX /.local

RUN apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get install -y --no-install-recommends \
    && apt-get clean \
    && rm -rf \
    /var/lib/apt/lists \
    /var/cache/apt/archives \
    /tmp/* \
    /var/tmp/*

RUN python -m pip install --upgrade pip setuptools wheel --no-cache-dir \
    && python -m pip install -r requirements.txt

RUN localedef -c -f UTF-8 -i en_US en_US.UTF-8
RUN update-locale LANG=C.UTF-8 LC_MESSAGES=POSIX && \
    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales
RUN echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen && locale-gen
RUN chmod g+rwX /app

USER 1001

# Only for TESTING
ENTRYPOINT ["tail", "-f", "/dev/null"] 
