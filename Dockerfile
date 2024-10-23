# Start from the base image
FROM alpine:latest

ARG SFTP_USERNAME=sftpuser
ARG SFTP_PASSWORD=sftppassword

#RUN SFTP_PASSWORD=$(echo "${SFTP_PASSWORD}" | sed 's/\$/$$/g')
#RUN export SFTP_PASSWORD=$(echo "${SFTP_PASSWORD}" | sed 's/\$/$$/g')

#ENV SFTP_PASSWORD_ESC=$(echo "$SFTP_PASSWORD" | sed 's/\$/\\$/g')
# Use the ARG value to set an environment variable in the container
# ENV SFTP_USERNAME=${SFTP_USERNAME}
# ENV SFTP_PASSWORD=${SFTP_PASSWORD}
# Install OpenSSH, OpenJDK, and curl
# RUN apk add --no-cache openssh openjdk11 curl openrc nano
RUN apk add openssh openjdk11 curl openrc nano

# Set Tomcat version
ENV TOMCAT_VERSION=9.0.96
ENV TOMCAT_HOME=/usr/local/tomcat

# Create directories for Tomcat and SFTP
RUN mkdir -p ${TOMCAT_HOME} /home/${SFTP_USERNAME}

#RUN echo "SFTP_PASSWORD:${SFTP_PASSWORD}"
# Create SFTP user
RUN addgroup -S sftp && \
    adduser -S ${SFTP_USERNAME} -G sftp -h /home/${SFTP_USERNAME} -s /bin/sh && \
    echo "${SFTP_USERNAME}:${SFTP_PASSWORD}" | chpasswd && \
    mkdir -p /home/${SFTP_USERNAME}/uploads && \
    chown root:sftp /home/${SFTP_USERNAME} && \
    chmod 755 /home/${SFTP_USERNAME} && \
    chown ${SFTP_USERNAME}:sftp /home/${SFTP_USERNAME}/uploads

# Generate SSH host keys
RUN ssh-keygen -A

# Configure SSH for SFTP
# RUN echo "Match Group sftp\n\
#     ChrootDirectory /home/sftpuser\n\
#     ForceCommand internal-sftp\n\
#     AllowTcpForwarding no" >> /etc/ssh/sshd_config
# Configure SSH for SFTP
# Match Group sftp
# ChrootDirectory /home/sftpuser\n\
# ForceCommand internal-sftp\n\
# AllowTcpForwarding no

# Download and extract Tomcat
RUN curl -fsSL https://downloads.apache.org/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz \
    | tar -xz -C /usr/local && \
    mv /usr/local/apache-tomcat-${TOMCAT_VERSION} ${TOMCAT_HOME} && \
    rm -rf /usr/local/apache-tomcat-${TOMCAT_VERSION}

# Generate SSH host keys
RUN ssh-keygen -A

# Create necessary directories for SSH
RUN mkdir -p /run/openrc && touch /run/openrc/softlevel

COPY ./conf/tomcat-users.xml /usr/local/tomcat/conf/tomcat-users.xml
COPY ./conf/manager/META-INF/context.xml /usr/local/tomcat/webapps/manager/META-INF/context.xml

# Copy the startup script into the container
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Expose the necessary ports for SSH and Tomcat
EXPOSE 22 8080

# Set the command to run the startup script
CMD ["/usr/local/bin/start.sh"]


# LABEL maintainer="guy.phanvongsa@dpie.nsw.gov.au"
# FROM tomcat:8.5-alpinelsls

# #COPY ./conf/tomcat-users.xml /usr/local/tomcat/conf/tomcat-users.xml
# RUN mkdir wars
# #ADD ./wars/servicesLocal.war /usr/local/tomcat/webapps/
# RUN apk update
# RUN apk add openssh-server nano openrc

# # Install shadow utilities, bash, and create the sftp group/user
# RUN apk add --no-cache bash shadow && \
#     addgroup -S sftp && \
#     adduser -S -G sftp -s /sbin/nologin -D valro && \
#     echo 'valro:GRE\$Ntr33sd' | chpasswd


# RUN  mkdir -p /run/openrc && touch /run/openrc/softlevel
# #RUN rc-service sshd start
# RUN rc-update add sshd

# COPY ./conf/tomcat-users.xml /usr/local/tomcat/conf/tomcat-users.xml
# COPY ./conf/manager/META-INF/context.xml /usr/local/tomcat/webapps/manager/META-INF/context.xml

# EXPOSE 22

# EXPOSE 8080
# CMD ["/usr/sbin/sshd", "-D"]
# CMD ["catalina.sh", "run"]
