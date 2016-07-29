#!/bin/bash
set -m

# Set the permision for the riak data directory
chown riak:riak /var/lib/riak

if [[ "$1" = "supervisord" ]]; then
  echo "Run the container in supervisord mode."
  supervisord -c /etc/supervisor/supervisord.conf
else
  exec $@
fi
