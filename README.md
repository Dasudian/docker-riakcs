# dasudian/riakcs

Basho riak clould storage images.

## Tags

- [`2.1.1` (2.1.1/dockerfile)](https://github.com/Dasudian/docker-riak/blob/master/Dockerfile)  

 
## Expose ports

- 8080  (riakcs-rest)
- 8098  (riak-rest)  
- 8087  (riak-protobuf)  

## Volumes

- `/var/lib/riak`   (data)  
- `/etc/riak-cs`    (config)  
- `/etc/stanchion`    (config) 

**NOTE:** if use `-e /srv/riak/data:/var/lib/riak`, make sure the directories */srv/riak/data* have full write permisions for all users.
