FROM ruby:3.2.3-alpine3.19 AS runtime

RUN apk -U upgrade && apk add --no-cache git libpq-dev libxml2 libxslt imagemagick nodejs npm shared-mime-info yarn

FROM runtime AS build
ARG BUNDLER_GITHUB_OAUTH_KEY

ENV BUILD_ENV 1
ENV BUNDLER_WITHOUT development test
ENV DATABASE_URL postgres://fake@localhost/fake
ENV DOMAIN=example.com
ENV GEONAMES_USERNAME 1
ENV POSTMARK_API_TOKEN 1
ENV RACK_ENV production
ENV RAILS_ENV production
ENV SECRET_KEY_BASE_DUMMY=1

COPY . /app
WORKDIR /app

RUN apk add --no-cache --virtual .gem-installdeps build-base \
                                                  imagemagick-c++ \
                                                  imagemagick-dev \
                                                  imagemagick-libs \
                                                  libxml2-dev \
                                                  libxslt-dev && \
    gem install bundler -v 2.5.5 && \
    gem install nokogiri -v 1.16.2 --platform=ruby -- --use-system-libraries && \
    bundle config github.com $BUNDLER_GITHUB_OAUTH_KEY && \
    bundle install --retry 5 && \
    bundle exec bootsnap precompile app/ lib/ && \
    bin/rails assets:precompile && \
    rm -rf $GEM_HOME/cache && \
    apk del .gem-installdeps

FROM runtime
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app /app

WORKDIR /app

RUN mkdir -p tmp/pids

ENV RAILS_LOG_TO_STDOUT 1
ENV RAILS_SERVE_STATIC_FILES true

EXPOSE 3000
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]