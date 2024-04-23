#!/bin/bash
cd /opt/atlassian/pipelines/agent/build

# Check if the RUN_SONAR_ANALYSIS variable is set and is true
if [[ -n "$RUN_SONAR_ANALYSIS" && "$RUN_SONAR_ANALYSIS" == "true" ]]; then
    echo "RUN_SONAR_ANALYSIS is set to true. Proceeding with SonarQube analysis..."
else
    echo "RUN_SONAR_ANALYSIS is not set to true or is unset. Skipping SonarQube analysis."
    exit 0
fi
# Fetch the latest commit message
LATEST_COMMIT_LOG=$(git log --first-parent --merges -1 --pretty=%B)

# Extract branch name from the commit message using grep
LATEST_BRANCH=$(echo "$LATEST_COMMIT_LOG" | grep -o "Merged in [^ ]*" | cut -d ' ' -f 3)

# Print the latest merged branch
echo "Latest merged branch: $LATEST_BRANCH"

# Replace '/' with '-' in the branch name
BRANCH_KEY=$(echo "$LATEST_BRANCH" | tr '/' '-')

# Check if the branch is a hotfix branch and append ::hotfix if true
if [[ "$LATEST_BRANCH" == hotfix/* ]]; then
    PROJECT_KEY="ngage::${BITBUCKET_REPO_SLUG}::${BRANCH_KEY}::hotfix"
else
    PROJECT_KEY="ngage::${BITBUCKET_REPO_SLUG}::${BRANCH_KEY}"
fi

# Replace '\\' with '-' in the project key (if necessary)
PROJECT_KEY=$(echo "$PROJECT_KEY" | tr '\\' '-')

curl -X POST -H "Authorization: Bearer $SONAR_USER_TOKEN" -H "Content-Type: application/json" "$SONAR_HOST_URL/api/projects/delete?project=$PROJECT_KEY"



