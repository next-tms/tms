# syntax=docker/dockerfile:1.19

FROM golang:1.26.5-alpine3.23 AS caddy
ARG CADDY_VERSION=2.11.2

RUN apk -U upgrade
RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@v0.4.5

WORKDIR /src
ENV XCADDY_GO_BUILD_FLAGS='-trimpath -ldflags "-s -w -extldflags -static" -tags "osusergo,netgo"'
RUN /go/bin/xcaddy build v$CADDY_VERSION --with github.com/ueffel/caddy-brotli

FROM ruby:4.0.7-alpine3.23 AS base
RUN apk add --no-cache -U ca-certificates gcompat imagemagick jemalloc libpq-dev libxml2 libxslt shared-mime-info && \
    update-ca-certificates

ENV BUNDLE_WITHOUT="development:test"
ENV BUNDLER_FORCE_PLATFORM=true
ENV LD_PRELOAD=libjemalloc.so.2
ENV MALLOC_CONF=background_thread:true
ENV RAILS_ENV=production
ENV RUBY_YJIT_ENABLE=1

FROM base AS build
RUN apk add --no-cache --virtual .gem-installdeps build-base \
                                                  git \
                                                  imagemagick-dev \
                                                  imagemagick-libs \
                                                  libxml2-dev \
                                                  libxslt-dev \
                                                  linux-headers \
                                                  yaml-dev

COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock

WORKDIR /app

RUN gem update --system && gem install bundler -v $(grep -A 1 "BUNDLED WITH" Gemfile.lock | tail -n 1 | tr -d '[:space:]')
RUN bundle config set --global frozen 1 && \
    bundle install -j $(nproc) --retry 5

COPY --exclude=.git/ . /app
RUN bundle exec bootsnap precompile app/ lib/
RUN DOMAIN=localhost \
    GEONAMES_USERNAME=fake \
    POSTMARK_API_TOKEN=fake \
    SECRET_KEY_BASE_DUMMY=1 \
    bin/rails dartsass:build assets:precompile
RUN rm -rf $GEM_HOME/cache && \
    find $GEM_HOME -name "*.c" -delete && \
    find $GEM_HOME -name "*.o" -delete && \
    rm -rf $GEM_HOME/*/doc $GEM_HOME/*/cache/*.gem && \
    apk del .gem-installdeps

RUN apk add --no-cache --virtual .compression-installdeps brotli findutils gzip zstd
RUN EXTENSIONS='.*\.(css|eot|html|js|json|map|otf|svg|ttf|txt)$' && \
  test -d public || exit 0 && \
  find public -type f \( -name "*.br" -o -name "*.gz" -o -name "*.zst" \) -delete && \
  find public -regextype posix-extended -type f -size +1024c -regex "$EXTENSIONS" \
  -exec sh -lc '\
  f="$1"; \
  [ ! -e "$f.br"  ] || [ "$f" -nt "$f.br"  ] && brotli -q 11 -f -k "$f"; \
  [ ! -e "$f.gz"  ] || [ "$f" -nt "$f.gz"  ] && gzip -9 -f -k "$f"; \
  [ ! -e "$f.zst" ] || [ "$f" -nt "$f.zst" ] && zstd  -q --ultra -19 -T0 -f "$f" \
  ' _ {} \;
RUN apk del .compression-installdeps

FROM base AS runtime

RUN apk add --no-cache curl

COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app /app
COPY --from=caddy /src/caddy /usr/local/bin/caddy

WORKDIR /app

RUN mkdir -p tmp/pids tmp/sockets

ENV DOMAIN=localhost
ENV FORCE_SSL=true
ENV PORT=3000
ENV PUMA_SOCKET=/app/tmp/sockets/puma.sock
ENV RACK_ENV=production

RUN addgroup -g 1000 liftoff && adduser -u 1000 -G liftoff -s /bin/sh -D liftoff
RUN chown -R liftoff:liftoff /app
USER liftoff

EXPOSE 3000
CMD ["./web.sh"]
