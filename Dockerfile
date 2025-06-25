# Используем образ с Maven для сборки
FROM openjdk:17-jdk-slim

WORKDIR /app

COPY pom.xml .

COPY src ./src

RUN apt-get update && apt-get install -y maven && mvn clean package

CMD ["java", "-jar", "target/psyapp-1.0-SNAPSHOT-jar-with-dependencies.jar"]