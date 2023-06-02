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

