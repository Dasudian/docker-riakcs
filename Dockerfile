# This is a Dockerfile to build a riakcs storage system image.
FROM buildpack-deps:trusty-curl
MAINTAINER Mengz <mz@dasudian.com>

ENV DEBIAN_FRONTEND="noninteractive" \
  RIAK_VERSION="2.1.4-1" \
  RIAKCS_VERSION="2.1.1-1" \
  STANCHION_VERSION="2.1.1-1" \
  STORAGE_BACKEND="leveldb" \
  RIAK_CONFIG="/etc/riak/riak.conf" \
  RIAKCS_CONFIG="/etc/riak-cs/riak-cs.conf" \
  STANCHION_CONFIG="/etc/stanchion/stanchion.conf" \
  NODE_HOST="127.0.0.1" \
  ANONY_USER_CREATION="off" \
  RIAKCS_ROOT_HOST="s3.amazonaws.com"
  # Default CONF
  # ADMIN_KEY="" \
  # ADMIN_SECRET="" \

# Setup the repositories
RUN curl -fsSL https://packagecloud.io/install/repositories/basho/riak/script.deb.sh | sudo bash && \
  curl -s https://packagecloud.io/install/repositories/basho/stanchion/script.deb.sh | sudo bash && \
  curl -s https://packagecloud.io/install/repositories/basho/riak-cs/script.deb.sh | sudo bash

RUN apt-get update && \
  apt-get install --no-install-recommends -y --force-yes supervisor riak=$RIAK_VERSION stanchion=$STANCHION_VERSION riak-cs=$RIAKCS_VERSION && \
  mkdir -p /var/log/supervisor && \
  locale-gen en_US en_US.UTF-8 && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

RUN sed -ri "s|^listener.http.internal = .*|listener.http.internal = 0.0.0.0:8098|" $RIAK_CONFIG && \
  sed -ri "s|^listener.protobuf.internal = .*|listener.protobuf.internal = 0.0.0.0:8087|" $RIAK_CONFIG && \
  sed -ri "s|^listener = .*|listener = 0.0.0.0:8080|" $RIAKCS_CONFIG && \
  sed -ri "s|^distributed_cookie = .*|distributed_cookie = riak-cs|" $RIAK_CONFIG && \
  sed -ri "s|^distributed_cookie = .*|distributed_cookie = riak-cs|" $RIAKCS_CONFIG && \
  sed -ri "s|^distributed_cookie = .*|distributed_cookie = riak-cs|" $STANCHION_CONFIG && \
  sed -ri "s|^storage_backend = bitcask|buckets.default.allow_mult = true|" $RIAK_CONFIG && \
  sed -ri "s|^## admin.listener = .*|admin.listener = 0.0.0.0:8000|" $RIAKCS_CONFIG

COPY riak-advanced.config /etc/riak/advanced.config
COPY supervisord-riakcs.conf /etc/supervisor/conf.d/
COPY entrypoint.sh /

EXPOSE 8087 8098 8080 8000

VOLUME ["/var/lib/riak","/etc/riak-cs","/etc/stanchion"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord"]
