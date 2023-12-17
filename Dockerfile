# Docker file for running Ferus in an Ubuntu 23.10 container
# Authors:
# 
# moigagoo (moigagoo at duck dot com)

FROM ubuntu:mantic

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y curl gcc git xz-utils firejail
RUN curl https://nim-lang.org/choosenim/init.sh -O
RUN sh init.sh -y
RUN rm init.sh

ENV PATH=/root/.nimble/bin:$PATH

WORKDIR /usr/src/app
COPY . /usr/src/app

RUN nimble install -yd

