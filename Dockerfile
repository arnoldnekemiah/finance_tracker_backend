# syntax = docker/dockerfile:1

ARG RUBY_VERSION=3.3.1
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim as base

WORKDIR /rails

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

FROM base as builder

# Install packages needed for building
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    libpq-dev \
    libvips \
    pkg-config && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

# Install specific bundler version
RUN gem install bundler -v 2.5.22

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle _2.5.22_ config set --local without 'development test' && \
    bundle _2.5.22_ install --jobs 20 --retry 5 && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Copy application code
COPY . .

# Precompile bootsnap code
RUN bundle exec bootsnap precompile app/ lib/

# Final stage
FROM base

# Install runtime dependencies only
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    libvips \
    postgresql-client && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

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
