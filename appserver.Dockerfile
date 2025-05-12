FROM tomcat:latest

# Maintainer
MAINTAINER your_name your_email

# Remove default webapps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy your WAR file into the Tomcat webapps directory
COPY your-app.war /usr/local/tomcat/webapps/

# Expose port 8080 for Tomcat
EXPOSE 8080

# Define default command
CMD ["catalina.sh", "run"]
