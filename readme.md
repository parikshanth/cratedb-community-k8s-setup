# Building a docker container with the community edition of crate

use the 2 phase build dockerfile to build the community edition of crate, this us using the previous stable version of 4.8

`docker build -t <image_name> .`

Test the working image using

`docker run -d --publish 4200:4200 --publish 5432:5432 <image_name> -Cdiscovery.type=single-node`

### Run on Kubernetes

use the ymls in the k8s directory to create the services and stateful set to run the containers, the containers are not having any physical volume claims, they are using memory mapped drive, which has to be changed in order to persist between restarts.

Refer the documentation on the link https://crate.io/blog/how-to-set-up-a-cratedb-cluster-with-kubernetes

`kubectl apply -f .`

## secure
This configuration is done to prevent any external access to the crate cluster, the deployer has to first connect to one of the running crate pods and use these steps to create an alternate admin user to be able to use the database cluster

` kubectl exec -it crate-0 bash `

use the crash command line management utility to create a user and assign permissions 

`
crash

create user crateadmin with (password = '<password>');
grant AL to crateadmin;
grant DQL to crateadmin;
grant DDL to crateadmin;
grant DML to crateadmin;

`

## coming up
a application repo to connect and use this cluster


### References
these were the inspiration for this work

https://hub.docker.com/r/orchestracities/crate
https://github.com/orchestracities/crate-ce
https://github.com/r2dedios/crate-ce-docker
