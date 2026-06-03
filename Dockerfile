# syntax=docker/dockerfile:1

# ---------- Build stage ----------
FROM ruby:3.4.9-slim AS build

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_WITHOUT=development:test \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLER_VERSION=2.7.2

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libsqlite3-dev libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock .ruby-version ./
RUN gem install bundler -v "${BUNDLER_VERSION}" && \
    bundle install && \
    rm -rf "${BUNDLE_PATH}"/ruby/*/cache

COPY . .

# The real database.yml is environment-specific and git-ignored; derive it from
# the committed example so the build is reproducible from a clean checkout.
RUN cp config/database.yml.example config/database.yml

# Precompile bootsnap and assets. SECRET_KEY_BASE_DUMMY lets us build assets
# without baking a real secret into the image.
RUN bundle exec bootsnap precompile app/ lib/ || true && \
    SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

# ---------- Runtime stage ----------
FROM ruby:3.4.9-slim AS runtime

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_WITHOUT=development:test \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLER_VERSION=2.7.2 \
    RAILS_SERVE_STATIC_FILES=1 \
    RAILS_LOG_TO_STDOUT=1 \
    PORT=3000

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y libsqlite3-0 libyaml-0-2 && \
    rm -rf /var/lib/apt/lists/* && \
    gem install bundler -v "${BUNDLER_VERSION}"

# Run as an unprivileged user.
RUN groupadd --system --gid 1000 rails && \
    useradd --system --uid 1000 --gid 1000 --create-home rails

WORKDIR /app

COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app /app

RUN mkdir -p db log tmp && chown -R rails:rails db log tmp
USER rails

EXPOSE 3000

ENTRYPOINT ["./bin/docker-entrypoint"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
