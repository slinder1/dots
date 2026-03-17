FROM ubuntu:24.04

RUN apt-get -y update \
&& apt-get install -y --no-install-recommends sudo curl ca-certificates \
&& rm -rf /var/lib/apt/lists/*

RUN useradd -ms /bin/bash -G sudo slinder1 \
&& echo slinder1:pass | chpasswd

USER slinder1
WORKDIR /home/slinder1

