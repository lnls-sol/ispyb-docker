# ISPYB Docker

It sets up a ISPyB instance by using docker in Debian 8.

Steps are:
- [x] Install debian packages
- [x] Install JAVA
- [x] Install Maven
- [x] Download, install and configure JBOSS Wildfly 8.2
- [x] Download ISPyB from github then build it
- [x] Install MySQL DB and configure it passing newest scripts
- [ ] Ingest data from User portal. Not done yet automatically
- [ ] Ingest data for BioSAXS experiments
- [ ] Ingest data for MX experiments
- [ ] Ingest data for CryoEM experiments


## Installation

It requires docker installed.
Configure the proxies in DockerFile before building the container.

## Building ISPyB

### With no cache
```
docker build  -t dockcs.esrf.fr/dau/ispyb:1.0.0 --no-cache=true . 
```

### With cache
```
docker build  -t dockcs.esrf.fr/dau/ispyb:1.0.0 . 
```

## Running ISPyB

```
run.sh
```

or

```
docker run -p 8085:8080 -i -t dockcs.esrf.fr/dau/ispyb:1.0.0
```

## Accesing to ISPyB UI

user: mx415
password: password

```
http://localhost:8085/ispyb
```

## Accesing to DB

user: pxuser
password: pxuser
