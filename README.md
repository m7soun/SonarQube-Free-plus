# SonarQube Free+ Custom Script

## Overview

This project enhances the free version of SonarQube by adding features typically found in paid versions. Leveraging
Docker, this custom script extends the capabilities of SonarQube, providing comprehensive code analysis and quality
management for your projects without the need for a paid subscription.

## Features

- Enhanced Analysis: Adds advanced analysis features such as code duplication detection, security vulnerability
  detection, and more.
- Quality Gates: Define custom quality gates to enforce quality standards for your projects.
- Project Management: Manage multiple projects and repositories with ease.
- Custom Rules: Implement custom rules tailored to your organization's coding standards.
- Integration: Seamlessly integrates with CI/CD pipelines for automated code analysis and feedback.

## Usage

### Prerequisites

- Docker installed on your system.
- Access to the DockerHub repository where the custom SonarQube image is hosted.

### Integration with CI/CD Pipeline

- Pull Custom SonarQube Image: Pull the custom SonarQube Docker image from the DockerHub repository.

```
docker pull your-custom-sonarqube-image:tag
```

- Run SonarQube Container: Start a Docker container using the custom SonarQube image, specifying any necessary
  configurations.

```
docker run -d --name sonarqube -p 9000:9000 your-custom-sonarqube-image:tag
```

- Configure Pipeline: Add a step in your CI/CD pipeline configuration to execute code analysis using SonarQube.

Example (GitLab CI):

```
sonarqube:
image: your-custom-sonarqube-image:tag
script:
- sonar-scanner -Dsonar.projectKey=my_project -Dsonar.sources=. -Dsonar.host.url=http://localhost:9000 -Dsonar.login=my_token
only:
- master
```

- View Reports: Access the SonarQube dashboard to view detailed code analysis reports and insights.

## Customization

- Configuration: Customize SonarQube settings and configurations to match your project requirements.
- Extensions: Install additional plugins or extensions to extend the functionality further.
- Integration: Integrate with other tools and services in your development workflow as needed.

## Contributing

Contributions to this project are welcome! Feel free to submit bug reports, feature requests, or pull requests via
  GitHub.
