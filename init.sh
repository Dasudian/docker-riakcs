#!/bin/bash

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
  exit 1
fi

sleep 1
echo "Start riak-cs service ..."
/usr/bin/supervisorctl start riak-cs

if [[ $? -ne 0 ]]; then
  echo "Start riak-cs service failed!"
  exit 1
fi

exit 0
