# Keycloak ARM Guide für Versionen < 17


Terminal Befehl zum Starten:

``` ./keycloak-m1-builder.sh ```




# Keycloak Quarkus Guide (17 und höher)

### Major Differences

- Keycloak now relies on Quarkus instead of Wildlfy
- Quarkus is a jvm framework, which is pretty efficient and has fast loading times, made for virtual machines. But other than wildfly it is not an java apllication server, so certain dependencies could be missing and have to be added manually.
- Changes affecting the providers or runtime configuration can no longer be made during server up time, only initially before start up (this makes .CLI-Files mostly irrelevant).

### **For M1 Mac users only:** Build the image


The following script will build a local image of Keycloak 17.0.0 on M1 Macs. By enabling the last line an instance of Keycloak will directly start on [http://localhost:8080/auth/](http://localhost:8080/auth/)

The Version number can be changed, but so far this is only tested for 17.0.0 and M1 Macs.

You can as well just execute the script step by step in your terminal.

[keycloak-quarkus-m1-builder.sh](./keycloak-quarkus-m1-builder.sh)



```Bash
VERSION=17.0.0 # set version here

cd /tmp
git clone git@github.com:keycloak/keycloak.git
cd keycloak/quarkus/container
git checkout $VERSION
docker build -t "quarkus-keycloak:$VERSION" .
#docker run -p 8080:8080 -e KEYCLOAK_ADMIN=admin -e KEYCLOAK_ADMIN_PASSWORD=admin "quarkus-keycloak:$VERSION" start-dev --http-relative-path /auth
```


You might aswell want to change the name of the image to something other than „quarkus-keycloak :$VERSION“, but beware that if you name the image „quay.io/keycloak/keycloak:$VERSION“ (the official image name) docker will probaply pull the official image and will not use the one you already build.

### Start the container


Starting a Keycloak container that is using a quarkus image is fundamentaly different. Before you can start a container with the image, you have to build the image. This is mostly for runtime optimization.

The following documentation is given (you can skip this for now):

```shell
Keycloak - Open Source Identity and Access Management 

Find more information at: https://www.keycloak.org/docs/latest
 
Usage:

kc.sh [OPTIONS] [COMMAND]

Use this command-line tool to manage your Keycloak cluster.
Make sure the command is available on your "PATH" or prefix it with "./" (e.g.:
"./kc.sh") to execute from the current folder.

Options:

-cf, --config-file <file> Set the path to a configuration file. By default, 
							  configuration properties are read from the "keycloak.conf"
							  file in the "conf" directory.
-h, --help                This help message.
-v, --verbose             Print out error details when running this command.
-V, --version             Show version information

keycloak_1  | Commands:

  build                   Creates a new and optimized server image.
  start                   Start the server.
  start-dev               Start the server in development mode.
  export                  Export data from realms to a file or directory.
  import                  Import data from a directory or a file.
  show-config             Print out the current configuration.
  tools                   Utilities for use and interaction with the server.
  completion            Generate bash/zsh completion script for kc.sh.

Examples:

  Start the server in development mode for local development or testing:

      $ kc.sh start-dev

  Building an optimized server runtime:

      $ kc.sh build <OPTIONS>

  Start the server in production mode:

      $ kc.sh start <OPTIONS>

  Enable auto-completion to bash/zsh:

      $ source <(kc.sh tools completion)

  Please, take a look at the documentation for more details before deploying in
production.

Use "kc.sh start --help" for the available options when starting the server.
Use "kc.sh <command> --help" for more information about other commands.
```


This is useful, when you want to start and configure your keycloak instance solely through your command line (this article is most useful for that: [https://blog.codecentric.de/en/2021/12/keycloak-keycloak-x/](https://blog.codecentric.de/en/2021/12/keycloak-keycloak-x/))

But you will probably just use a dockerfile.

### Configure Dockerfile


In projects where there is a custom docker image needed, the dockerfile builds that image according to the set parameters. The following is an example from keycloak event listener:

```shell
FROM quarkus-keycloak:17.0.0 as builder
COPY target/keycloak-to-rabbit-2.1.jar /opt/keycloak/providers
RUN /opt/keycloak/bin/kc.sh

FROM quarkus-keycloak:17.0.0
COPY --from=builder /opt/keycloak/lib/quarkus/ /opt/keycloak/lib/quarkus/
COPY --from=builder /opt/keycloak/providers /opt/keycloak/providers
WORKDIR /opt/keycloak
ENV KEYCLOAK_ADMIN=admin
ENV KEYCLOAK_ADMIN_PASSWORD=admin
ENV KC_HTTP_ENABLED=true
ENV KC_HTTP_PORT=8080
ENV KC_HOSTNAME=localhost:8080
ENV KC_HOSTNAME_STRICT=false
ENV KC_HTTP_RELATIVE_PATH=/auth
ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "start-dev"]
```


The first three lines build the image. As you can see, I used the custom image I build earlier for M1 Macs. Once the official verison is out or if you are using an Intel Mac, you can use the official image. The second line loads my custom SPI in that image and the third one is the acutal building step.

The rest of the file uses this image and applies configurations onto that. Note that you have to copy here any folder you modified, for example providers, because of my custom SPI. You especially have to copy the „/opt/keycloak/lib/quarkus/„ folder. 

From there on you just configure the image according to your needs. For compability reasons it could be useful to change „KC_HTTP_RELATIVE_PATH" to „/auth“ because in 17.0.0 this got removed.

You can also consult this documentation for any further modification: [https://www.keycloak.org/server/all-config](https://www.keycloak.org/server/all-config)

Note that in the last line the container starts in developer mode. This should be changed to just „start" before deployment.

### Dependencies


Because quarkus is not an java application server, some dependencies that are necessary for your project will not be loaded. To check this you should take a look into your target folder and compare the contents with your pom file. If certain dependencies did not load, add them manually.

If you are using the maven assemble plugin it might also be necessary to restrict transative dependencies, because this could result in an overlapping of different versions of the same dependency. Do this by adding a custom descriptor in your maven assembly plugin. It should look like that:

```xml
<assembly xmlns="http://maven.apache.org/ASSEMBLY/2.1.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/ASSEMBLY/2.1.0 http://maven.apache.org/xsd/assembly-2.1.0.xsd">
    <id>jar-with-dependencies</id>
    <formats>
        <format>jar</format>
    </formats>
    <includeBaseDirectory>false</includeBaseDirectory>
    <dependencySets>
        <dependencySet>
            <outputDirectory>/</outputDirectory>
            <useProjectArtifact>true</useProjectArtifact>
            <unpack>true</unpack>
            <scope>runtime</scope>
            <useTransitiveDependencies>false</useTransitiveDependencies>
        </dependencySet>
    </dependencySets>
</assembly>
```


The only relevant part here is „useTransitiveDependencies“ which you want to set to false. By doing this you might have to add some dependencies manually.

### TL;DR:

- Before using an image you have to build it
- configuration is necessary in dockerfile
- KEYCLOAK_USER is now KEYCLOAK_ADMIN
- KEYCLOAK_PASSWORD is now KEYCLOAK_ADMIN_PASSWORD
- SPI (.jar) folder changed to /opt/keycloak/providers
- CLI`s probably will not work anymore, so a workaround is needed
- modification of pom.xml file is necessary
