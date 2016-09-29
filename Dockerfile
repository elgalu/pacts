# debian:jessie -- https://goo.gl/bOr38O
# |==> buildpack-deps:jessie-curl -- https://goo.gl/5hSvwt
#      |==> buildpack-deps:jessie-scm -- https://goo.gl/AfBc8C
#           |==> buildpack-deps:jessie -- https://goo.gl/hnND7b
#                |==> ruby:2.3.0 -- https://goo.gl/eDlvs7
#                     |==> HERE
# FROM ruby:2.3.0

# Changing to jRuby for AppDynamics support
# Latest:
#  https://hub.docker.com/_/jruby/
# More details
#   https://github.com/tianon/docker-brew-debian/blob/d431f09a37/jessie/Dockerfile
#   https://github.com/docker-library/openjdk/blob/89851f0abc3a8/8-jre/Dockerfile
#   https://github.com/cpuguy83/docker-jruby/blob/2448a2d7288d/9000/jre/Dockerfile
# FROM jruby:9.0.5.0-jre
# FROM jruby:9.1.2.0-jre

# When maintaining our own jRuby docker image
FROM elgalu/jruby:9.0.5e
# FROM elgalu/jruby:9.1.2a #not working

MAINTAINER Leo Gallucci <elgalu3@gmail.com>

ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true

USER root

# Get latest `gem` binary
# RUN  gem install rubygems-update \
#   && gem update --system
RUN gem install bundler -v 1.11.2

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

#-------------------------------------
# To be able to install gems from git
#-------------------------------------
#= Git =#
RUN apt-get update -qqy \
  && apt-get -qqy install \
    git-core \
  && rm -rf /var/lib/apt/lists/*

#--------------------------------------------------
# To be able to url enconde via perl -MURI::Escape
#--------------------------------------------------
RUN apt-get update -qqy \
  && apt-get -qqy install \
    jq \
    curl \
    make \
    perl \
    libpq-dev \
    libdbi-perl \
    libmodule-signature-perl \
    software-properties-common \
  && rm -rf /var/lib/apt/lists/*

#------
# CPAN
#------
# RUN apt-get update -qqy \
#   && apt-get -qqy install \
#     cpanminus \
#   && cpanm --sudo Digest::SHA1 \
#   && rm -rf /var/lib/apt/lists/*
# # RUN curl "https://raw.githubusercontent.com/miyagawa/cpanminus/b2eeedf9d5395f100c97e9a80e6b8bc39421143e/cpanm" | perl - App::cpanminus
# ADD container/usr/bin/install_cpanm /usr/bin/
# # Securely: https://github.com/miyagawa/cpanminus/issues/505
# RUN install_cpanm -M "https://cpan.metacpan.org/" --verify App::cpanminus
# RUN cpanm URI::Escape

#------------------
# Python3 and zign
#------------------
RUN add-apt-repository ppa:fkrull/deadsnakes \
  && apt-get update -qqy \
  && apt-get -qqy install \
    python3.5 \
    python3-pip \
  && pip3 install -U pip \
  && pip3 install -U stups-zign \
  && rm -rf /var/lib/apt/lists/*

#-----------------------------
# Torquebox web server part 1
#-----------------------------
# http://torquebox.org/download/
ENV TORQ_VER="3.1.2" \
    TORQUEBOX_HOME="/root/torquebox"
ENV JBOSS_HOME=${TORQUEBOX_HOME}/jboss \
    JRUBY_HOME=${TORQUEBOX_HOME}/jruby
ENV PATH=${JRUBY_HOME}/bin:${PATH}
# If you dont have the zip locally then uncomment the wget section
ADD root /root
# RUN cd /root \
#   && wget -nv "http://torquebox.org/release/org/torquebox/torquebox-dist/${TORQ_VER}/torquebox-dist-${TORQ_VER}-bin.zip" \
# md5sum torquebox-dist-3.1.2-bin.zip #=> ff6f34c8a29b7745de9f23acd77e5ad0
RUN cd /root \
  && echo "ff6f34c8a29b7745de9f23acd77e5ad0  torquebox-dist-${TORQ_VER}-bin.zip" > torquebox.md5 \
  && md5sum --check torquebox.md5

#-------------
# Pact Broker
#-------------
ENV APP_HOME=/root/pact_broker
RUN rm -f /etc/service/nginx/down \
  && rm -f /etc/nginx/sites-enabled/default
ADD container /
ADD pact_broker/ ${APP_HOME}/
WORKDIR ${APP_HOME}
RUN bundle install --without='development test'

#------------------
# Torquebox part 2
#------------------
RUN cd /root \
  && unzip -qx torquebox-dist-${TORQ_VER}-bin.zip \
  && mv torquebox-${TORQ_VER} torquebox
RUN jruby -S torquebox deploy

ENV PACT_BROKER_PORT=443 \
    BIND_TO=0.0.0.0 \
    SKIP_HTTPS_ENFORCER=true \
    RACK_THREADS_COUNT=20 \
    RACK_LOG=/var/log/rack.log

# Restore
ENV DEBIAN_FRONTEND="" \
    DEBCONF_NONINTERACTIVE_SEEN=""

#=====================================================
# Meta JSON file to hold commit info of current build
#=====================================================
COPY scm-source.json /
# Ensure the file is up-to-date else you should update it by running
#  ./script/gen-scm-source.sh
# on the host machine

EXPOSE ${PACT_BROKER_PORT}
CMD ["/usr/bin/entry.sh"]
