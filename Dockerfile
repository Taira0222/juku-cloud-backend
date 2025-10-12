# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t juku_cloud_backend .
# docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name juku_cloud_backend juku_cloud_backend

# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
# === Base ===
# ここでRubyのバージョンを指定。自分が使っているバージョンに変更してください
ARG RUBY_VERSION=3.4.4 
FROM docker.io/library/ruby:${RUBY_VERSION}-slim AS base

WORKDIR /rails

# 必要最小のランタイム依存をインストール
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl \
      libjemalloc2 \
      libvips \
      libpq5 \
      ca-certificates \
      tzdata \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

# 本番系のEnv
ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    RAILS_LOG_TO_STDOUT=1 \
    TZ=Asia/Tokyo
# Rubyのメモリ管理を高速＆省メモリ化するためのライブラリ(jemalloc)を有効化
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

# === Build ===
FROM base AS build

# gemビルドに必要な依存のみ
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      git \
      libpq-dev \
      libyaml-dev \
      pkg-config \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

# 依存解決（キャッシュ最大化のため先に Gemfile* のみ）
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# アプリ本体をコピー
COPY . .

# bootsnap precompile（アプリ起動時の読み込みをキャッシュ）
RUN bundle exec bootsnap precompile app/ lib/

# （Railsにassetsがある場合のみ）
# RUN bundle exec rake assets:precompile

# === Final ===
FROM base

# gem とアプリをコピー
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# 非root実行
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

# Railsを3000番で外部公開（ECS/ALBの設定と一致させる）
EXPOSE 3000

# Rails起動（puma経由でもOK）
CMD ["bash", "-lc", "bundle exec rails server -b 0.0.0.0 -p 3000"]
