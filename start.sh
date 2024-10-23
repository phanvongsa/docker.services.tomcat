#!/bin/sh

# Start the SSH daemon
/usr/sbin/sshd -D

# Start the Tomcat server
catalina.sh run
