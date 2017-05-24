FROM ruby:2.4.1

ARG TEST_HOME=/statefully
ADD Gemfile *.gemspec $TEST_HOME/
RUN mkdir -p $TEST_HOME/lib/statefully
ADD lib/statefully/version.rb $TEST_HOME/lib/statefully/
WORKDIR $TEST_HOME

RUN bundle install --jobs 8 --retry 5

ADD . $TEST_HOME
