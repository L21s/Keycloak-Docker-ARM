VERSION=17.0.0 # set version here

cd /tmp
git clone git@github.com:keycloak/keycloak.git
cd keycloak/quarkus/container
git checkout $VERSION
docker build -t "quarkus-keycloak:$VERSION" .
#docker run -p 8080:8080 -e KEYCLOAK_ADMIN=admin -e KEYCLOAK_ADMIN_PASSWORD=admin "quarkus-keycloak:$VERSION" start-dev --http-relative-path /auth
