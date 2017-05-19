FROM ruby:2.4.1

ARG TEST_HOME=/statefully
ADD *.gemspec $TEST_HOME/
ADD Gemfile $TEST_HOME/
WORKDIR $TEST_HOME

RUN bundle install --jobs 8 --retry 5

ADD . $TEST_HOME
