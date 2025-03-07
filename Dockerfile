FROM ruby:3.3.7-alpine3.20 AS runtime

RUN apk -U upgrade
RUN apk add --no-cache gcompat git libpq-dev libxml2 libxslt imagemagick nodejs npm shared-mime-info yarn

FROM runtime AS build
ARG BUNDLER_GITHUB_OAUTH_KEY

ENV BUILD_ENV=1
ENV DATABASE_URL=postgres://fake@localhost/fake
ENV DOMAIN=example.com
ENV GEONAMES_USERNAME=1
ENV POSTMARK_API_TOKEN=1
ENV RACK_ENV=production
ENV RAILS_ENV=production
ENV SECRET_KEY_BASE_DUMMY=1

RUN apk add --no-cache --virtual .gem-installdeps build-base \
                                                  imagemagick-c++ \
                                                  imagemagick-dev \
                                                  imagemagick-libs \
                                                  libxml2-dev \
                                                  libxslt-dev

RUN gem update --system
RUN gem install bundler -v 2.5.21
RUN gem install nokogiri -v 1.16.6 --platform=ruby -- --use-system-libraries

COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
WORKDIR /app

RUN bundle config set global frozen && \
    bundle config set without 'development test' && \
    bundle config github.com $BUNDLER_GITHUB_OAUTH_KEY && \
    bundle install --jobs $(nproc) --retry 5 && \
    rm -rf /usr/local/bundle/cache && \
    rm -rf /app && \
    apk del .gem-installdeps

COPY . /app

RUN bin/rails assets:precompile

FROM runtime
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app /app

WORKDIR /app

ENV LANG=en_US.UTF-8
ENV RACK_ENV=production
ENV RAILS_ENV=production
ENV RAILS_LOG_TO_STDOUT=1
ENV RAILS_SERVE_STATIC_FILES=true

RUN mkdir -p tmp/pids
RUN bundle exec bootsnap precompile app/ lib/

EXPOSE 3000
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
