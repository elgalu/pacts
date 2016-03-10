# debian:jessie -- https://goo.gl/bOr38O
# |==> buildpack-deps:jessie-curl -- https://goo.gl/5hSvwt
#      |==> buildpack-deps:jessie-scm -- https://goo.gl/AfBc8C
#           |==> buildpack-deps:jessie -- https://goo.gl/hnND7b
#                |==> ruby:2.3.0 -- https://goo.gl/eDlvs7
#                     |==> HERE
FROM ruby:2.3.0

MAINTAINER Leo Gallucci <elgalu3@gmail.com>

#----------------------------------------------
# To avoid using `curl --insecure` you need to
# add Zalando CA or your specific company CA
#----------------------------------------------
# RUN curl https://secure-static.ztat.net/ca/zalando-service.ca > /usr/local/share/ca-certificates/zalando-service.crt
# RUN curl https://secure-static.ztat.net/ca/zalando-root.ca > /usr/local/share/ca-certificates/zalando-root.crt
ADD certs/zalando-service.crt /usr/local/share/ca-certificates/
ADD certs/zalando-root.crt /usr/local/share/ca-certificates/
# add AWS RDS CA bundle
RUN mkdir /tmp/rds-ca && \
    curl https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem > /tmp/rds-ca/aws-rds-ca-bundle.pem
# split the bundle into individual certs (prefixed with xx)
# see http://blog.swwomm.com/2015/02/importing-new-rds-ca-certificate-into.html
RUN cd /tmp/rds-ca && csplit -sz aws-rds-ca-bundle.pem '/-BEGIN CERTIFICATE-/' '{*}'
RUN for CERT in /tmp/rds-ca/xx*; do mv $CERT /usr/local/share/ca-certificates/aws-rds-ca-$(basename $CERT).crt; done
RUN update-ca-certificates

#--------------------------------------------------
# To be able to url enconde via perl -MURI::Escape
#--------------------------------------------------
RUN apt-get update -qqy \
  && apt-get -qqy install \
    jq \
    curl \
  && rm -rf /var/lib/apt/lists/*
RUN curl -L http://cpanmin.us | perl - App::cpanminus
RUN cpanm URI::Escape

#-------------
# Pact Broker
#-------------
ENV APP_HOME=/root/pact_broker
RUN rm -f /etc/service/nginx/down
RUN rm -f /etc/nginx/sites-enabled/default
ADD container /

ADD pact_broker/Gemfile $APP_HOME/
ADD pact_broker/Gemfile.lock $APP_HOME/

WORKDIR $APP_HOME
RUN bundle install --deployment --without='development test'

USER root
ADD pact_broker/ $APP_HOME/

ENV PACT_BROKER_PORT=443 \
    BIND_TO=127.0.0.1 \
    RACK_THREADS_COUNT=20 \
    RACK_LOG=/var/log/rack.log

EXPOSE $PACT_BROKER_PORT
CMD /usr/bin/entry.sh

#=====================================================
# Meta JSON file to hold commit info of current build
#=====================================================
COPY scm-source.json /
# Ensure the file is up-to-date else you should update it by running
#  ./script/gen-scm-source.sh
# on the host machine
