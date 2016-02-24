# Dockerized Pact Broker with OAuth2 support [![Build Status](https://travis-ci.org/elgalu/pact_broker-docker.svg)](https://travis-ci.org/elgalu/pact_broker-docker)

This projects starts at https://github.com/bethesque/pact_broker please read those docs first.

## Requirements

* Latest stable docker

* [STUPS](http://stups.readthedocs.org/en/latest/) AWS ecosystem with [OAuth2](http://stups.readthedocs.org/en/latest/user-guide/access-control.html) solution. You can use [DiUS pact broker](https://github.com/DiUS/pact_broker-docker) instead if you don't have STUPS tools.

## Docs

* To have a postgres docker running see [postgres.md][]

* For the docker build & docker run flow see [local-build-run.md][]

* For the docker build & push flow see [CONTRIBUTING.md][]

* To curl the service see [curl.md][]

* To see the service on your browser see [Chrome OAuth Bearer Plugin][]

* To run in in the host machine see [on-host.md][]

* How the team etcd cluster was deployed: [etcd.md][]

* How PostgreSQL was deployed to AWS using Spilo: [spilo.md][]

* How the app was deployed to AWS: [pacts.md][]

* Monitoring through New Relic [newrelic.md][]

[Chrome OAuth Bearer Plugin]: https://github.com/zalando/chrome-oauth-bearer-plugin
[postgres.md]: ./docs/postgres.md
[CONTRIBUTING.md]: ./docs/CONTRIBUTING.md
[local-build-run.md]: ./docs/local-build-run.md
[curl.md]: ./docs/curl.md
[on-host.md]: ./docs/on-host.md
[etcd.md]: ./docs/etcd.md
[spilo.md]: ./docs/spilo.md
[pacts.md]: ./docs/pacts.md
[newrelic.md]: ./docs/newrelic.md
