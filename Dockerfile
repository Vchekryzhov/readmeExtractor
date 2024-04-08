ARG RUBY_VERSION=3.3.0
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim as base
RUN gem install readmeExtractor
RUN mkdir -p /data/rubygems
CMD ["readmeExtractor", "start", "--from", "/data/rubygems/gems", "--to", "/data/rubygems/readmes"]