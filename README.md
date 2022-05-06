# Keycloak M1 ARM Guide 

###  Build the image for Keycloak Version >= 17 (Quarkus based)

The following script will build a local image of Keycloak 17.0.0 on M1 Macs. 

By enabling the last line an instance of Keycloak will directly start on [http://localhost:8080/auth/](http://localhost:8080/auth/)

The Version number can be changed, but so far this is only tested for 17.0.0 and M1 Macs.


You can as well just execute the script step by step in your terminal.

[keycloak-quarkus-m1-builder.sh](./keycloak-quarkus-m1-builder.sh)

```Bash
VERSION=17.0.0 # set version here

cd /tmp
git clone git@github.com:keycloak/keycloak.git
cd keycloak/quarkus/container
git checkout $VERSION
docker build -t "quay.io/keycloak/keycloak:$VERSION" .
#docker run -p 8080:8080 -e KEYCLOAK_ADMIN=admin -e KEYCLOAK_ADMIN_PASSWORD=admin "quay.io/keycloak/keycloak:$VERSION" start-dev --http-relative-path /auth
```
Start with this command: ```./keycloak-m1-builder.sh```





###  Build the image for Keycloak Version <= 16.1.0 (WildFly based)

For building versions older or equal 16.1.0 use:

```
#/bin/zsh

VERSION=16.1.0 # set version here

cd /tmp
git clone git@github.com:keycloak/keycloak-containers.git
cd keycloak-containers/server
git checkout $VERSION
docker build -t "jboss/keycloak:${VERSION}" .
docker build -t "quay.io/keycloak/keycloak:${VERSION}" .
```

Referenced from this comment: https://github.com/docker/for-mac/issues/5310#issuecomment-877653653
