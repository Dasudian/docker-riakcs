#!/bin/bash
set -m

C_IP=$(ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)

# if [[ $NODE_HOST =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]];then
#   echo "Use the IP as the NODE_HOST, the nodename of riak is riak@$NODE_HOST"
# else
#   grep -E "^$C_IP $NODE_HOST$" /etc/hosts
#   if [ $? -ne 0 ];then
#     echo "$C_IP $NODE_HOST" >> /etc/hosts
#     echo "Use a HOST NAME as the NODE_HOST, the nodename of riak is riak@$NODE_HOST"
#   fi
# fi

# sed -ri "s|nodename = .*|nodename = riak@$NODE_HOST|" $RIAK_CONFIG
sed -ri "s|^anonymous_user_creation = .*|anonymous_user_creation = $ANONY_USER_CREATION|" $RIAKCS_CONFIG
sed -ri "s|^root_host = .*|root_host = $RIAKCS_ROOT_HOST|" $RIAKCS_CONFIG

if [[ -n $ADMIN_KEY && -n $ADMIN_SECRET ]]; then
  sed -ri "s|^admin.key = .*|admin.key = $ADMIN_KEY|" $RIAKCS_CONFIG
  sed -ri "s|^admin.secret = .*|admin.secret = $ADMIN_SECRET|" $RIAKCS_CONFIG
  sed -ri "s|^admin.key = .*|admin.key = $ADMIN_KEY|" $STANCHION_CONFIG
  sed -ri "s|^admin.secret = .*|admin.secret = $ADMIN_SECRET|" $STANCHION_CONFIG
fi

# Set the permision for the riak data directory
chown riak:riak /var/lib/riak

if [ "$1" = "supervisord" ]; then
  supervisord -n &
  echo "Container's IP is $C_IP ."
  fg %1
else
  exec $@
fi
