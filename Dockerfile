# syntax=docker/dockerfile:1

FROM eclipse-temurin:25-jdk AS build

WORKDIR /workspace

COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
COPY .gonthera/ .gonthera/
COPY src/ src/

RUN --mount=type=cache,target=/root/.m2 \
    chmod +x mvnw \
    && ./mvnw -B -ntp gonthera-cli:validate \
    && ./mvnw -B -ntp gonthera-cli:generate-sources \
    && ./mvnw -B -ntp clean package

FROM eclipse-temurin:25-jre AS runtime

WORKDIR /app

COPY --from=build --chown=10001:10001 /workspace/target/*.jar /app/app.jar

USER 10001:10001

EXPOSE 8081

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
