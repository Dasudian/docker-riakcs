#!/bin/bash
set -m

# Set the permision for the riak data directory
chown riak:riak /var/lib/riak

if [[ "$1" = "supervisord" ]]; then
  echo "Run the container in supervisord mode."
  echo ""
  echo "Note: After the init-riakcs finished, pleasce use below command to check the init result:"
  echo "`docker exec -it [container_name or id] cat /init-riakcs.log`"
  echo ""
  supervisord -c /etc/supervisor/supervisord.conf
else
  exec $@
fi
