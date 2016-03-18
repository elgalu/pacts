# Contributing

## Setup
    rvm install .
    bundle install

## Test
    bundle exec rake

## Build
    gem uninstall pact_broker || rm -f *.gem && bundle exec gem build pact_broker.gemspec
