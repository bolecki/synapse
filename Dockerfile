# build stage
FROM arm64v8/elixir:1.18.2-otp-27-alpine as build

# install build dependencies
RUN apk add --update git build-base nodejs npm yarn python3

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV="prod"

# install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY priv priv

COPY lib lib

COPY assets assets

# compile assets
RUN mix assets.deploy

# Compile the release
RUN mix compile

# Changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/

# COPY rel rel
RUN mix phx.gen.release
RUN mix release

# prepare release image
FROM alpine:3.21.3 AS app

RUN apk add --update bash openssl postgresql-client libstdc++
RUN apk add --no-cache gcompat

WORKDIR "/app"

ENV MIX_ENV="prod"

COPY --from=build --chown=nobody:root /app/_build/${MIX_ENV}/rel/synapse ./
# COPY --from=build --chown=nobody:root /app/rel/overlays ./
COPY entrypoint.sh .

RUN chown nobody /app
USER nobody

ENV HOME=/app
CMD ["bash", "/app/entrypoint.sh"]

