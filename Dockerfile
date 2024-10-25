# Use Debian as the base image
FROM debian:latest

ARG SERVER_UN=server_user__
ARG SERVER_PW=server_password__

ARG TOMCAT_UN=tomcat_user__
ARG TOMCAT_PW=tomcat_password__

#10.1.13
# Set environment variables
ENV TOMCAT_VERSION=8.5.0 \
    TOMCAT_HOME=/usr/local/tomcat

# Install necessary packages (Java, wget, etc.)
RUN apt-get update && \
    apt-get install -y openjdk-17-jre wget tar nano openssh-server sudo && \
    rm -rf /var/lib/apt/lists/*

# Set up OpenSSH
RUN mkdir /var/run/sshd

# Create the valro user and set password
RUN useradd -ms /bin/bash $SERVER_UN && \
    echo "$SERVER_UN:$SERVER_PW" | chpasswd

# Create Tomcat user and group
RUN groupadd -r tomcat && \
    useradd -r -s /bin/bash -g tomcat -d $TOMCAT_HOME -p $(openssl passwd -6 "$TOMCAT_PW") $TOMCAT_UN

    # tomcat_pw=$(openssl passwd -6 "$TOMCAT_PW")
    # # Create the user with the hashed password
    # sudo useradd -m -p "$tomcat_pw" valro

# Download and install Apache Tomcat
RUN wget https://archive.apache.org/dist/tomcat/tomcat-8/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz && \
    tar xvfz apache-tomcat-$TOMCAT_VERSION.tar.gz && \
    mv apache-tomcat-$TOMCAT_VERSION $TOMCAT_HOME && \
    rm apache-tomcat-$TOMCAT_VERSION.tar.gz

RUN echo '<?xml version="1.0" encoding="UTF-8"?> \
    <tomcat-users> \
    <role rolename="manager-gui"/> \
    <role rolename="admin-gui"/> \
    <user username="'$TOMCAT_UN'" password="'$TOMCAT_PW'" roles="manager-gui,admin-gui"/> \
    </tomcat-users>' > $TOMCAT_HOME/conf/tomcat-users.xml

## allow acccess via localhost + ips
COPY ./conf/manager/META-INF/context.xml /usr/local/tomcat/webapps/manager/META-INF/context.xml

# Change ownership of the Tomcat directory
RUN chown -R $TOMCAT_UN:tomcat $TOMCAT_HOME

# Set ownership of valro's home directory
RUN chown -R $SERVER_UN:$SERVER_UN /home/$SERVER_UN

# Allow valro to SSH
RUN mkdir -p /home/$SERVER_UN/.ssh && \
    chown -R $SERVER_UN:$SERVER_UN /home/$SERVER_UN/.ssh && \
    chmod 700 /home/$SERVER_UN/.ssh

RUN mkdir -p /home/$SERVER_UN/wars && \
  chown -R $SERVER_UN:$SERVER_UN /home/$SERVER_UN/wars

# Add valro to the sudoers file to allow switching to tomcat user without password
RUN echo "$SERVER_UN ALL=(ALL) /bin/su - $TOMCAT_UN" >> /etc/sudoers

# Expose the default Tomcat port
EXPOSE 8080 22

# Create a startup script to run both SSH and Tomcat
RUN echo '#!/bin/bash\n' \
    'service ssh start\n' \
    'bash /usr/local/tomcat/bin/catalina.sh run\n' > /start.sh && \
    chmod +x /start.sh

# Switch to the Tomcat user
#USER $TOMCAT_UN
CMD ["/start.sh"]


# # Start from the base image
# FROM alpine:latest

# ARG SERVER_UN=server_user__
# ARG SERVER_PW=server_password__

# ARG WEBSERVER_UN=webserber_user__
# ARG WEBSERVER_PW=webserber_password__

# # Set Tomcat version
# ENV TOMCAT_VERSION=9.0.96
# ENV TOMCAT_HOME=/usr/local/tomcat

# # Create directories for Tomcat and SFTP
# RUN mkdir -p ${TOMCAT_HOME} /home/${SERVER_UN}

# # Create SFTP/Server user
# RUN addgroup -S sftp && \
#     adduser -S ${SERVER_UN} -G sftp -h /home/${SERVER_UN} -s /bin/sh && \
#     echo "${SERVER_UN}:${SERVER_PW}" | chpasswd && \
#     mkdir -p /home/${SERVER_UN}/uploads && \
#     chown root:sftp /home/${SERVER_UN} && \
#     chmod 755 /home/${SERVER_UN} && \
#     chown ${SERVER_UN}:sftp /home/${SERVER_UN}/uploads

# RUN apk add openssh openjdk11 curl openrc nano
# # Generate SSH host keys
# RUN ssh-keygen -A

# # Configure SSH for SFTP
# # RUN echo "Match Group sftp\n\
# #     ChrootDirectory /home/sftpuser\n\
# #     ForceCommand internal-sftp\n\
# #     AllowTcpForwarding no" >> /etc/ssh/sshd_config
# # Configure SSH for SFTP
# # Match Group sftp
# # ChrootDirectory /home/sftpuser\n\
# # ForceCommand internal-sftp\n\
# # AllowTcpForwarding no


# # Download and extract Tomcat
# RUN curl -fsSL https://downloads.apache.org/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz \
#     | tar -xz -C /usr/local && \
#     mv /usr/local/apache-tomcat-${TOMCAT_VERSION} ${TOMCAT_HOME} && \
#     rm -rf /usr/local/apache-tomcat-${TOMCAT_VERSION}

# # Generate SSH host keys
# RUN ssh-keygen -A

# # Create necessary directories for SSH
# RUN mkdir -p /run/openrc && touch /run/openrc/softlevel

# COPY ./conf/tomcat-users.xml /usr/local/tomcat/conf/tomcat-users.xml
# COPY ./conf/manager/META-INF/context.xml /usr/local/tomcat/webapps/manager/META-INF/context.xml

# # Copy the startup script into the container
# COPY start.sh /usr/local/bin/start.sh
# RUN chmod +x /usr/local/bin/start.sh

# # Expose the necessary ports for SSH and Tomcat
# EXPOSE 22 8080

# # Set the command to run the startup script
# CMD ["/usr/local/bin/start.sh"]


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
