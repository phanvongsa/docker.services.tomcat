FROM tomcat:8.5-alpine
LABEL maintainer="guy.phanvongsa@dpie.nsw.gov.au"

#COPY ./conf/tomcat-users.xml /usr/local/tomcat/conf/tomcat-users.xml
RUN mkdir wars
#ADD ./wars/servicesLocal.war /usr/local/tomcat/webapps/
#RUN apk add nano

COPY ./conf/tomcat-users.xml /usr/local/tomcat/conf/tomcat-users.xml
COPY ./conf/manager/META-INF/context.xml /usr/local/tomcat/webapps/manager/META-INF/context.xml

EXPOSE 8080
CMD ["catalina.sh", "run"]
