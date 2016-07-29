#!/bin/bash

set -m

ADMIN_JSON_FILE="/var/lib/riak/admin.json"

_init_with_stanchion() {
  echo "Start init the riak service ..."
  /usr/bin/supervisorctl start riak
  if [[ $? -ne 0 ]]; then
    echo "Start riak service failed!"
    exit 1
  fi

  echo "Waiting 20s to start stanchion and riak-cs services ..."
  sleep 20

  echo "Start stanchion service ..."
  /usr/bin/supervisorctl start stanchion
  if [[ $? -ne 0 ]]; then
    echo "Start stanchion service failed!"
    /usr/bin/supervisorctl stop riak
    exit 1
  fi

  sleep 1
  echo "Start riak-cs service ..."
  /usr/bin/supervisorctl start riak-cs
  if [[ $? -ne 0 ]]; then
    echo "Start riak-cs service failed!"
    /usr/bin/supervisorctl stop stanchion riak
    exit 1
  fi
}

_init_without_stanchion() {
  echo "Start init the riak service ..."
  /usr/bin/supervisorctl start riak
  if [[ $? -ne 0 ]]; then
    echo "Start riak service failed!"
    exit 1
  fi

  sleep 15
  riak-admin cluster status | grep "${PRIMARY_NOTE_HOST}" >/dev/null
  if [[ $? -ne 0 ]]; then
    echo "Join the cluster ..."
    riak-admin cluster join riak@${PRIMARY_NOTE_HOST}
    riak-admin cluster plan
    riak-admin cluster commit
  fi

  sleep 5
  echo "Start riak-cs service ..."
  /usr/bin/supervisorctl start riak-cs
  if [[ $? -ne 0 ]]; then
    echo "Start riak-cs service failed!"
    /usr/bin/supervisorctl stop stanchion riak
    exit 1
  fi
}

_replace_admin() {
  if [[ -e ${ADMIN_JSON_FILE} ]]; then
    ADMIN_KEY=$(cat ${ADMIN_JSON_FILE} | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["key_id"]')
    ADMIN_SECRET=$(cat ${ADMIN_JSON_FILE} | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["key_secret"]')
  fi
  
  sed -ri "s|^admin.key = admin-key|admin.key = ${ADMIN_KEY}|" ${RIAKCS_CONFIG}
  sed -ri "s|^admin.secret = admin-secret|admin.secret = ${ADMIN_SECRET}|" $RIAKCS_CONFIG
  sed -ri "s|^admin.key = admin-key|admin.key = ${ADMIN_KEY}|" ${STANCHION_CONFIG}
  sed -ri "s|^admin.secret = admin-secret|admin.secret = ${ADMIN_SECRET}|" ${STANCHION_CONFIG}
}

if [[ -n ${NODE_HOST} ]]; then
  if [[ ${NODE_HOST} =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]];then
    echo "Use the IP as the NODE_HOST, the nodename of riak is riak@$NODE_HOST"
  else
    C_IP=$(ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
    grep -E "${NODE_HOST}" /etc/hosts
    if [[ $? -ne 0 ]];then
      echo "${C_IP} ${NODE_HOST}" >> /etc/hosts
    else
      sed -ri "s|.* ${NODE_HOST}|${C_IP} ${NODE_HOST}|" /etc/hosts
    fi
    echo "Use a HOST NAME as the NODE_HOST, the nodename of riak is riak@${NODE_HOST}"
  fi
  sed -ri "s|nodename = riak@127.0.0.1|nodename = riak@${NODE_HOST}|" ${RIAK_CONFIG}
  sed -ri "s|nodename = riak-cs@127.0.0.1|nodename = riak-cs@${NODE_HOST}|" ${RIAKCS_CONFIG}
fi

[[ -n ${ROOT_HOST} ]] && sed -ri "s|^root_host = s3.amazonaws.com|root_host = ${ROOT_HOST}|" ${RIAKCS_CONFIG}

if [[ "${STANCHION_NODE}" == "yes" ]]; then
  # The main riakcs node which should run stanchion
  # Check if already creat the admin key
  if [[ -e ${ADMIN_JSON_FILE} ]]; then
    $(_replace_admin)
    
    $(_init_with_stanchion)
    
    echo ""
    echo "==============================================="
    echo "Admin Key and Secre are below:"
    cat ${ADMIN_JSON_FILE}
    echo "==============================================="
    echo "The primary riakcs node started!"
  else
    sed -ri "s|^anonymous_user_creation = .*|anonymous_user_creation = on|" ${RIAKCS_CONFIG}
    
    $(_init_with_stanchion)
    sleep 5
    echo "Create the admin key ..."
    CMD=$(cat <<EOF
curl -s -XPOST -H 'Content-Type: application/json' \
http://localhost:8080/riak-cs/user \
-d '{"email":"${ADMIN_EMAIL}","name":"${ADMIN_USER}"}'
EOF
    )
    
    RET=$(eval ${CMD})
    if [[ $? -ne 0 ]]; then
      echo "Create the admin key failed!"
      /usr/bin/supervisorctl stop riak-cs stanchion riak
      exit 1
    fi
    echo ${RET}  | python -mjson.tool > ${ADMIN_JSON_FILE}
    chown riak:riak ${ADMIN_JSON_FILE}
    $(_replace_admin)
    sed -ri "s|^anonymous_user_creation = .*|anonymous_user_creation = off|" ${RIAKCS_CONFIG}
    /usr/bin/supervisorctl restart stanchion riak-cs
    if [[ $? -ne 0 ]]; then
      echo "Restart stanchion & riak-cs failed!"
      /usr/bin/supervisorctl stop riak
      exit 1
    fi
    
    echo ""
    echo "==============================================="
    echo "Admin Key and Secre are below:"
    cat ${ADMIN_JSON_FILE}
    echo "==============================================="
    echo "The primary riakcs node started!"
  fi
else
  # The cluster node without stanchion
  $(_replace_admin)
  sed -ri "s|^stanchion_host = 127.0.0.1:8085|stanchion_host = ${PRIMARY_NOTE_HOST}:8085|" ${RIAKCS_CONFIG}
  $(_init_without_stanchion)
  
  echo ""
  echo "==============================================="
  echo "Admin Key and Secre are below:"
  echo "admin.key = ${ADMIN_KEY}"
  echo "admin.secret = ${ADMIN_SECRET}"
  echo "==============================================="
  echo "The cluster riakcs node started!"
fi

exit 0
