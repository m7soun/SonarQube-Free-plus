# Use the SonarSource Sonar Scanner CLI image
FROM sonarsource/sonar-scanner-cli:latest

# Set the working directory to /app/sonar
WORKDIR /app/sonar

# Copy the contents of the repository into the container at /app/sonar
COPY ./sonar /app/sonar

# Make sure all shell scripts are executable
RUN find /app/sonar -type f -iname "*.sh" -exec chmod +x {} \;

# Install Git
RUN apk update && apk add git

# Set the default script to run when the container starts
CMD ["/bin/sh", "/app/sonar/run.sh"]
