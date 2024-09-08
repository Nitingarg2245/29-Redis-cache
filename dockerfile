FROM openjdk::11
WORKDIR /app/
COPY target/springbootapp.jar  /app/
EXPOSE 8080 
ENTRYPOINT  ["java","-jar","springbootapp.jar "]
