#!/bin/bash
cd /opt/atlassian/pipelines/agent/build

# Check if the RUN_SONAR_ANALYSIS variable is set and is true
if [[ -n "$RUN_SONAR_ANALYSIS" && "$RUN_SONAR_ANALYSIS" == "true" ]]; then
    echo "RUN_SONAR_ANALYSIS is set to true. Proceeding with SonarQube analysis..."
else
    echo "RUN_SONAR_ANALYSIS is not set to true or is unset. Skipping SonarQube analysis."
    exit 0
fi

TAG_NAME="$BITBUCKET_TAG"

# Checkout the commit corresponding to the tag
git checkout "$(git rev-list -n 1 $TAG_NAME)"

# Get the branch name of the current commit
CURRENT_BRANCH=$(git branch --contains HEAD | grep -v "*" | head -n 1 | awk '{$1=$1};1')

# Get the main branch name from the remote repository
MAIN_BRANCH=$(git remote show origin | grep "HEAD branch" | cut -d ":" -f 2 | sed 's/^[[:space:]]*//')
if [ -z "$MAIN_BRANCH" ]; then
  MAIN_BRANCH="master"  # Fallback to "master" if main branch not found
fi

echo "Tag Name: $TAG_NAME"
echo "Current Branch: $CURRENT_BRANCH"
echo "Name of the main branch: $MAIN_BRANCH"

# Go back to the previous branch
git checkout "$BITBUCKET_TAG"

echo "Returned to branch: $BITBUCKET_TAG"

# Check if the main branch was tagged with the $BITBUCKET_TAG

echo "Preparing project key..."
BRANCH_KEY=$(echo "$MAIN_BRANCH" | tr '/' '-')
PROJECT_KEY=$(echo "ngage::${BITBUCKET_REPO_SLUG}::${BRANCH_KEY}" | tr '\\' '-')

echo "Setting the latest tag for the project..."
curl -X POST -H "Authorization: Bearer $SONAR_USER_TOKEN" -H "Content-Type: application/json" "$SONAR_HOST_URL/api/project_tags/set?project=$PROJECT_KEY&tags=$TAG_NAME"

sonar-scanner \
        -Dsonar.projectKey="$PROJECT_KEY" \
        -Dsonar.sources="." \
        -Dsonar.exclusions="**/vendor/**" \
        -Dsonar.host.url="$SONAR_HOST_URL" \
        -Dsonar.token="$SONAR_TOKEN" \
        -Dsonar.projectDescription="latest analysis version is $TAG_NAME" \
        -Dsonar.analysis.comment="$TAG_NAME" \
        -Dsonar.qualitygate.wait=true \
        -Dsonar.scm.provider=git

