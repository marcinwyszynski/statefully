FROM ruby:2.5.0-alpine
RUN apk add --no-cache git

ADD . /statefully
WORKDIR /statefully
RUN bundle install --jobs 8 --retry 5
