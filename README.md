## alpine-tomcat8

alpine-tomcat8 is Alpine Linux based Tomcat 8 installation. See CHANGELOG.md for detail description.


## Prerequisites
Tested with

- Docker 18.09.2
- bash 3.2.57

## Contains
- Alpine Linux
- Java Open JDK 8
- Tomcat 8.5.24
- Tomcat Native 1.2.17

## Build

Clone repo

```
git clone git@github.com:alex-ber/alpine-tomcat8.git
```

Create image

```
docker build . -t alexberkovich/alpine-tomcat8
```

Or even, if you run the daemon with experimental features enabled: 

```
docker build --squash . -t alexberkovich/alpine-tomcat8
```

In Docker 1.13, a new --squash parameter was added. It can be used to reduce the size of an image by removing files 
which are not present anymore, and reduce multiple layers to a single one between the origin and the latest stage. 



You may want to do some cleanup first:

```
docker rm -f openjdk8; docker rmi alexberkovich/alpine-tomcat8
```

## DockerHub

Image available on DockerHub

```
docker pull alexberkovich/alpine-tomcat8
```

## Test

`Enusre that you don't have running container

docker rm -f openjdk8; 


Explicitly start the container:

```
docker run -d --name tomcat8 alpine-tomcat8
```


You can access bash with the following command

```
docker exec -it alpine-tomcat8 bash
```

