### Tomcat Version 	      JVM Version 	              JVM Vendor 	OS Name 	OS Version 	                        OS Architecture 	Hostname 	IP Address
### Apache Tomcat/8.5.41 	1.8.0_212-b04 	            IcedTea 	  Linux 	  5.15.153.1-microsoft-standard-WSL2 	amd64 	          02d5394a556b 	10.0.1.8
### Apache Tomcat/8.5.41 	17.0.13+11-Debian-2deb12u1 	Debian 	    Linux 	  5.15.153.1-microsoft-standard-WSL2 	amd64 	          e5f553132690 	10.0.1.9
FROM tomcat:8.5-alpine

ARG SERVER_UN=server_user__
ARG SERVER_PW=server_password__
ARG TOMCAT_UN=tomcat_user__
ARG TOMCAT_PW=tomcat_password__

# Set environment variables
ENV TOMCAT_VERSION=8.5.41 \
    TOMCAT_HOME=/usr/local/tomcat

# Install OpenSSH and sudo
RUN apk update && \
    apk add --no-cache openssh sudo

# Create users "valro" and "tomcat" with passwords
RUN adduser -D -s /bin/sh $SERVER_UN && \
    echo "$SERVER_UN:$SERVER_PW" | chpasswd && \
    adduser -D -s /bin/sh $TOMCAT_UN && \
    echo "$TOMCAT_UN:$TOMCAT_PW" | chpasswd

# Allow valro to use 'su' to switch to tomcat without a password
RUN echo "$SERVER_UN ALL=(ALL) /bin/su - $TOMCAT_UN" >> /etc/sudoers

RUN echo '<?xml version="1.0" encoding="UTF-8"?> \
    <tomcat-users> \
    <role rolename="manager-gui"/> \
    <role rolename="admin-gui"/> \
    <user username="'$TOMCAT_UN'" password="'$TOMCAT_PW'" roles="manager-gui,admin-gui"/> \
    </tomcat-users>' > $TOMCAT_HOME/conf/tomcat-users.xml

## allow acccess via localhost + ips
COPY ./conf/manager/META-INF/context.xml /usr/local/tomcat/webapps/manager/META-INF/context.xml


# Generate SSH host keys
RUN ssh-keygen -A

# Configure SSH for password authentication
RUN echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config

RUN mkdir /home/$TOMCAT_UN/wars
RUN mkdir /home/$TOMCAT_UN/wars.archive

RUN mkdir /home/$SERVER_UN/wars
RUN chown -R $TOMCAT_UN:$TOMCAT_UN $TOMCAT_HOME
RUN chown -R $TOMCAT_UN:$TOMCAT_UN /home/$TOMCAT_UN
RUN chown -R $SERVER_UN:$SERVER_UN /home/$SERVER_UN
# Expose Tomcat and SSH ports
EXPOSE 8080 22

# Start SSH and Tomcat when container runs
CMD /usr/sbin/sshd && catalina.sh run

#COPY start__.sh /usr/local/bin/start.sh
#CMD ["/usr/local/bin/start.sh"]
#CMD ["catalina.sh", "run"]
############ ^^^ WORKING.ALPINE ^^^ ############

# # Use Debian as the base image
# FROM debian:latest

# ARG SERVER_UN=server_user__
# ARG SERVER_PW=server_password__

# ARG TOMCAT_UN=tomcat_user__
# ARG TOMCAT_PW=tomcat_password__

# #10.1.13
# # Set environment variables
# ENV TOMCAT_VERSION=8.5.41 \
#     TOMCAT_HOME=/usr/local/tomcat

# # Install necessary packages (Java, wget, etc.)
# RUN apt-get update && \
#     apt-get install -y openjdk-11-jdk wget tar nano openssh-server sudo && \
#     rm -rf /var/lib/apt/lists/*

# # Set up OpenSSH
# RUN mkdir /var/run/sshd

# # Create the valro user and set password
# RUN useradd -ms /bin/bash $SERVER_UN && \
#     echo "$SERVER_UN:$SERVER_PW" | chpasswd

# # Create Tomcat user and group
# RUN groupadd -r tomcat && \
#     useradd -r -s /bin/bash -g tomcat -d $TOMCAT_HOME -p $(openssl passwd -6 "$TOMCAT_PW") $TOMCAT_UN

# # Download and install Apache Tomcat
# RUN wget https://archive.apache.org/dist/tomcat/tomcat-8/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz && \
#     tar xvfz apache-tomcat-$TOMCAT_VERSION.tar.gz && \
#     mv apache-tomcat-$TOMCAT_VERSION $TOMCAT_HOME && \
#     rm apache-tomcat-$TOMCAT_VERSION.tar.gz

# RUN echo '<?xml version="1.0" encoding="UTF-8"?> \
#     <tomcat-users> \
#     <role rolename="manager-gui"/> \
#     <role rolename="admin-gui"/> \
#     <user username="'$TOMCAT_UN'" password="'$TOMCAT_PW'" roles="manager-gui,admin-gui"/> \
#     </tomcat-users>' > $TOMCAT_HOME/conf/tomcat-users.xml

# ## allow acccess via localhost + ips
# COPY ./conf/manager/META-INF/context.xml /usr/local/tomcat/webapps/manager/META-INF/context.xml

# # Change ownership of the Tomcat directory
# RUN chown -R $TOMCAT_UN:tomcat $TOMCAT_HOME

# # Set ownership of valro's home directory
# RUN chown -R $SERVER_UN:$SERVER_UN /home/$SERVER_UN

# # Allow valro to SSH
# RUN mkdir -p /home/$SERVER_UN/.ssh && \
#     chown -R $SERVER_UN:$SERVER_UN /home/$SERVER_UN/.ssh && \
#     chmod 700 /home/$SERVER_UN/.ssh

# RUN mkdir -p /home/$SERVER_UN/wars && \
#   chown -R $SERVER_UN:$SERVER_UN /home/$SERVER_UN/wars

# # Add valro to the sudoers file to allow switching to tomcat user without password
# RUN echo "$SERVER_UN ALL=(ALL) /bin/su - $TOMCAT_UN" >> /etc/sudoers

# # Expose the default Tomcat port
# EXPOSE 8080 22

# # Create a startup script to run both SSH and Tomcat
# RUN echo '#!/bin/bash\n' \
#     'service ssh start\n' \
#     'bash /usr/local/tomcat/bin/catalina.sh run\n' > /start.sh && \
#     chmod +x /start.sh

# # Switch to the Tomcat user
# USER $TOMCAT_UN
# CMD ["/start.sh"]
############ ^^^ WORKING ^^^ ############
# FROM tomcat:8.5.100-jdk11-temurin-jammy

# ARG SERVER_UN=server_user__
# ARG SERVER_PW=server_password__
# ARG TOMCAT_UN=tomcat_user__
# ARG TOMCAT_PW=tomcat_password__

# # Set non-interactive environment variable for Alpine
# ARG DEBIAN_FRONTEND=noninteractive

# # Install OpenSSH and any other necessary packages
# RUN apt-get update && \
#     apt-get install -y openssh-server sudo nano && \
#     rm -rf /var/lib/apt/lists/*

# # Add users "valro" and "tomcat" with default settings
# RUN useradd -m -s /bin/bash $SERVER_UN && \
#     useradd -m -s /bin/bash $TOMCAT_UN

# # Set passwords for the new users (replace "password1" and "password2")
# RUN echo "$SERVER_UN:$SERVER_PW" | chpasswd && \
#     echo "$TOMCAT_UN:$TOMCAT_PW" | chpasswd

# # Add valro to the sudoers file to allow switching to tomcat user without password
# RUN echo "$SERVER_UN ALL=(ALL) /bin/su $TOMCAT_UN" >> /etc/sudoers

# # Configure SSH to start on container launch
# RUN mkdir /var/run/sshd
# # Enable password authentication in the SSH config (if disabled by default)
# RUN sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# RUN chown -R $TOMCAT_UN:$TOMCAT_UN /usr/local/tomcat

# # Expose both Tomcat and SSH ports
# EXPOSE 8080 22

# # Start SSH and Tomcat server
# CMD service ssh start && catalina.sh run