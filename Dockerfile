FROM tomcat:8.0-alpine

LABEL maintainer="Khader Mohideen"

ADD target/helloworldproject-1.0.war /usr/local/tomcat/webapps/

EXPOSE 8080

CMD ["catalina.sh", "run"]
