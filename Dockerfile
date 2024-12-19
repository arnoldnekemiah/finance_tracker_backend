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

# Install packages needed for building (modified approach)
RUN rm -f /var/lib/apt/lists/lock /var/cache/apt/archives/lock /var/lib/dpkg/lock* && \
    apt-get clean && \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    libpq-dev \
    libvips \
    pkg-config && \
    rm -rf /var/lib/apt/lists/*

# Install specific bundler version
RUN gem install bundler -v 3.5.22

# Install gems
RUN bundle install

# Copy application code
COPY . .

# Precompile bootsnap code
RUN bundle exec bootsnap precompile app/ lib/

# Final stage
FROM base

# Install runtime dependencies only
RUN rm -f /var/lib/apt/lists/lock /var/cache/apt/archives/lock /var/lib/dpkg/lock* && \
    apt-get clean && \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    libvips \
    postgresql-client && \
    rm -rf /var/lib/apt/lists/*

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
