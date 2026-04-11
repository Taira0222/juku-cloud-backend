ARG VARIANT=3.4-bookworm
FROM mcr.microsoft.com/vscode/devcontainers/ruby:${VARIANT}

ARG NODE_VERSION="24"
RUN su vscode -c "source /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"

ARG BUNDLER_VERSION='2.6.8'
RUN gem install bundler -v ${BUNDLER_VERSION}
ENV BUNDLE_PATH='/usr/local/bundle'

ARG RAILS_VERSIONS='8.0.2'
RUN gem install rails -v ${RAILS_VERSIONS}
RUN gem install ruby-lsp

RUN apt-get update && apt-get install -y postgresql-client

WORKDIR /app
