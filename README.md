# dasudian/riakcs

Basho riak clould storage images.

## Tags

- [`2.1.1`,`latest` (dockerfile)](https://github.com/Dasudian/docker-riak/blob/master/Dockerfile)  

 
## Expose ports

- 8080  (riakcs-rest) 

## Volumes

- `/var/lib/riak`   (data)  

## ENV

- STANCHION_NODE=[yes/no] - Default value is 'yes', indicate it's primary node (running stanchion in cluster) or not.  
- NODE_HOST=[ip/hostname] - When no NODE_HOSt indicate, the nodename is '\*@127.0.0.1', for cluster  deployment, must to indicate a domainname, and should be same with network alias.  
- ROOT_HOST=[hostname] - Default value is 's3.amazonaws.com', use to change riak-cs configuration 'root_host'.   
- ADMIN_USER=[string] - Default value is 'admin', used to generate the admin.key in the primary node.  
ADMIN_EMAIL=[email_address] - Default value is 'admin@maildomian.com', used to generate the admin.key in the primary node.  
- ADMIN_KEY=[string] - No default, when deploy other cluster node, used to indicate the 'admin.key' generated in primary node.  
- ADMIN_SECRET=[string] - No default, when deploy other cluster node, used to indicate the 'admin.secret' generated in primary node.  
- PRIMARY_NOTE_HOST=[hostname] - No Default, when deploy other cluster node, used to indicate the NODE_HOST of primary node.  

## Usage

### Deploy a standalone riak-cs node application

`docker run -d dasudian/riakcs`

Wait about 30s, then use below command to check the init result:  

`docker exec -it [container_name or id] cat /init-riakcs.log`

### Deploy a riak-cs cluster

**Note: Must use custom bridge or overlay network to deploy cluster.**  

The example is deploying 2 nodes on the same docker host.  

1. Create bridge network:  

`docker network create -d bridge cs_bridge`  

2. Run the primary node:  

```shell
docker run --name primary_riakcs \
--net cs_bridge \
--net-alias riakcs1.db \
-e NODE_HOST=riakcs1.db \
-d dasudian/riakcs
```

Wait about 30s, then use below command to check the init result:  

`docker exec -it primary_riakcs cat /init-riakcs.log`

The example output:  
```
===============================================
Admin Key and Secre are below:
{
    "display_name": "admin",
    "email": "admin@maildomain.com",
    "id": "a9e5b04aa91d4d0342c761099b560bbd5b575956d0b642d7c997aa9b5c3ce31e",
    "key_id": "Z6NVQ3ERM3UR5VGT3SZS",
    "key_secret": "ROftHdocdPRrsP3k-WhT5Dyc2-J2_UreWE_Bng==",
    "name": "admin",
    "status": "enabled"
}
===============================================
The primary riakcs node started!
```

Save the 'key_id' & 'key_secret', which will used to run the cluster node.  
If you missed the output log, can find this information in data directory */var/lib/riak/admin.json* .  

3. Run the cluster node:  

```shell
export ADMIN_KEY=Z6NVQ3ERM3UR5VGT3SZS    
export ADMIN_SECRET=ROftHdocdPRrsP3k-WhT5Dyc2-J2_UreWE_Bng==  
docker run --name riakcs_node2 \
--net cs_bridge \
--net-alias riakcs2.db \
-e NODE_HOST=riakcs2.db \
-e STANCHION_NODE=no \
-e PRIMARY_NOTE_HOST=riakcs1.db \
-e ADMIN_KEY=${ADMIN_KEY} \
-e ADMIN_SECRET=${ADMIN_SECRET} \
-d dasudian/riakcs`  
```

Wait about 30s, then use below command to check init result:  

`docker exec -it riakcs_node2 cat /init-riakcs.log`
