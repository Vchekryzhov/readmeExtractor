ARG RUBY_VERSION=3.3.0
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim as base
RUN gem install readmeExtractor
RUN mkdir -p /data/rubygems
COPY docker/entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]