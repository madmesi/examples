FROM openjdk:11-jre
COPY /target/myfile-*.jar /app/file.jar
WORKDIR /app
EXPOSE 8080
CMD ["java", "-jar", "file.jar"]
