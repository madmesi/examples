Steps to genearlize this repo:
1) Dockerfile
2) docker-compose.yaml
3) application.yaml

1 - Dockerfile:
// Source: https://www.katacoda.com/courses/java-in-docker/deploying-kotlin-wasabi-as-docker-container
To run an application inside of a container you first need to build the Docker Image. The Docker Image should contain everything required to start your application, including dependencies and configuration.

Docker Images are created based on a Dockerfile. A Dockerfile is a list of instructions that define how to build and start your application. During the build phase, these instructions are executed. The Dockerfile allows image creation to be automated, repeatable and consistent.

The first part of a Dockerfile is to define the base image. Docker has an embrace and extends approach. Your Dockerfile should only describe the steps required for your application. All runtime dependencies, such as the JVM, should be in the base image. The use of base images improves the build time and allows the image to be shared across multiple projects.

# Dependencies
The next stage of the Dockerfile is to define the dependencies the application requires to start.

The RUN instruction executes the command, similar to launching it from the bash command line. The WORKDIR instruction defines the working directory where commands should be executed from. The COPY instruction copies files and directories from the build directory into the container image. This is used to copy the source code into the image, allowing the build to take place inside the image itself.

All the commands are run in order. Under the covers, Docker is starting the container, running the commands, and then saving the image for the next command.

To deploy the application we need to create a directory for our application and set it as our working directory. We copy the current directory containing our source code into the Docker Image and the /src directory.

Once the code is in place, it's required to execute the build process to create the distribution zip. The distribution zip contains a build binary and libraries required by the process. The zip needs to be unzipped so it can be started when the container is launched. Once this has happened it can be removed.
example of adding dependencies:

```
FROM nginx:alpine
COPY . /src
RUN apk add vim zip unzip 
```

# Application
Once the Dockerfile has the required dependencies it now needs to define how to build and run your application.

The EXPOSE instruction is a description about what ports the application is listening on. This helps describe how the application should be started and run in production. This can be considered part of the documentation, or metadata, about the image and application.

The CMD instruction defines the default command to run when the Docker Container is started. This can be overridden when starting the container.

```
EXPOSE 3000
CMD ["/src/src/bin/src"]
```
