# syntax = docker/dockerfile:1

ARG RUBY_VERSION=3.3.1
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim as base

WORKDIR /rails

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3

FROM base as builder

# Install packages needed for building
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    build-essential \
    git \
    pkg-config && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Install database and image processing dependencies
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    libpq-dev \
    libvips && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Install bundler
RUN gem install bundler

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local without 'development test' && \
    bundle install --full-index && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Copy application code
COPY . .

# Precompile bootsnap code
RUN bundle exec /usr/local/bundle/bin/bootsnap precompile app/ lib/

# Final stage
FROM base

# Install runtime dependencies only
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    libvips \
    postgresql-client && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Copy built artifacts
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /rails /rails

# Setup non-root user
RUN useradd rails --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER rails:rails

EXPOSE 3001
ENTRYPOINT ["/rails/bin/docker-entrypoint"]
CMD ["./bin/rails", "server"]
