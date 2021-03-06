FROM elixir:1.10-alpine as build

# install build dependencies
RUN apk add --update git build-base nodejs npm yarn python openssh

# prepare build dir
RUN mkdir /app
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
  mix local.rebar --force

# set build ENV
ENV MIX_ENV=prod

ENV SECRET_KEY_BASE=6v+LKpr/9fjcvPUUTEH5syAyMptcOds9P1dCnAYaWlv7dZn48Nchk5004OFw0/NJ

RUN mkdir /root/.ssh/

ARG SSH_KEY_B64
RUN echo "${SSH_KEY_B64}" > /root/ssh_key.b64
RUN base64 -d /root/ssh_key.b64 > /root/.ssh/id_rsa
RUN chmod 600 /root/.ssh/id_rsa
RUN ls -la /root/.ssh/ 
RUN ssh-keyscan -H github.com >> /root/.ssh/known_hosts

# install mix dependencies
COPY mix.exs mix.lock ./
COPY config config
COPY lib lib
COPY test test

RUN cat ~/.ssh/id_rsa

RUN mix deps.get
RUN mix deps.compile

# build project
RUN mix compile

# run tests
RUN mix test

# build/install/run CLI image
RUN mix escript.build
RUN mix escript.install --force
RUN ~/.mix/escripts/sdlti
