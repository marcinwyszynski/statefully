FROM ruby:2.4.1

ARG TEST_HOME=/statefully
ADD Gemfile *.gemspec $TEST_HOME/
WORKDIR $TEST_HOME

RUN bundle install --jobs 8 --retry 5

ADD . $TEST_HOME
