# Local environment with HDFS/HBase and kerberos

This project is created to bring together all pieces of HBase locally for development and testing.

It includes these services:

* KDC
* Zookeeper
* HDFS Name node
* HDFS Data node
* HBase Region node - currently disabled because of kerberos problems at hbase-master
* HBase Master node - currently disabled because of kerberos problems

# Setup

All instruction here assumes that your current folder is a root folder of this project.

* Generate certificates: `./scripts/generate-certs.sh`
* Generate keytabs: `./scripts/generate-keytabs.sh`
* Pull all latest images - call `docker-compose pull --parallel` 

# Usage

## Running something

### Run all services

```bash
docker-compose up -d
```

### Run a single service and other services it depends on

```bash
docker-compose up -d <service_name>
```
 
### Run a single service, other services it depends on and watch logs of the service

```bash
docker-compose up <service name>
```

### Run a container with a service but using a different entrypoint

```bash
docker-compose run --rm --entrypoint /bin/bash <service_name>
```

This command may also include `-v` arguments to mount additional volumes into the container, 
`-u` to run it under a non-default user, `-e` to set or redefine environment variables, `--no-deps` to run only the container 
and skip any dependencies.

### Run an arbitrary container with access to the environment

```bash
docker run -it --rm --net localhbase_lh ubuntu /bin/bash
```

Please pay attention to a name of the network: `localhbase_lh`. Docker compose file has a definition
of a network called `lh`, which is the last segment of the name. The 1st segment of the name is name of a folder
where this project is cloned to, without spaces, dashes and underscores. If for example you cloned the project to 
`/Users/user/projects/local_dev` then name of the network will be `localdev_lh`. You can use command `docker network ls`
to get a list of all networks. The same naming rule applies to volumes. 

## Stopping something

### Stop a service

```bash
docker-compose stop <service_name>
```

This will preserve logs and a container. By calling `docker-compose start <service_name>` it will resume the container.

### Stop a service and remove a container

```bash
docker-compose rm -s <service_name>
```

This will stop the service, remove the container so if the service will be started later - it'll start from a
clean image. You may want to add `-v` key to remove all volumes associated with the container.

### Full stop and cleanup of the environment

```bash
docker-compose rm -s -v
docker volume rm $(docker volume ls -q | grep localhbase)
```

This will stop all containers, will remove all the containers, will clean all volumes including persistent volumes (probably).

## Monitor service

Watch logs of a service:
```bash
docker-compose logs -f <service_name>
```

SSH to a container with a service:
```bash
docker-compose exec <service_name> /bin/bash
```

# Known problems

* generate-certs.sh doesn't work on macOS 10.13

Version of LibreSSL library (is used as openssl in the system) that comes with macOS 10.13 does not support env variables
when it works with a config file used to generate certificates.

Workaround is to install an openssl with homebrew and use it to generate certificates.

To install the OpenSSL with Homebrew call `brew install openssl`

To generate certificates using OpenSSL from Homebrew call `OPENSSL=$(brew list openssl | grep bin/openssl | head -n 1) ./scripts/generate-certs.sh`