#!/bin/bash

# This script runs SonarQube analysis based on the branch or tag

echo "Current branch: $BITBUCKET_BRANCH"
echo "Current tag: $BITBUCKET_TAG"

pwd
cd /app/sonar
pwd


if [ -n "$BITBUCKET_TAG" ]; then
    echo "Running SonarQube analysis for tag: $BITBUCKET_TAG"
    if [[ "$BITBUCKET_TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+-rc ]]; then
        echo "Running SonarQube analysis for RC tag..."
        chmod +x master_rc_tag_sonar_analysis.sh
        ./master_rc_tag_sonar_analysis.sh
    elif [[ "$BITBUCKET_TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+-alpha ]]; then
        echo "Running SonarQube analysis for ALPHA tag..."
        chmod +x master_rc_tag_sonar_analysis.sh
        ./master_rc_tag_sonar_analysis.sh
    elif [[ "$BITBUCKET_TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+-hf ]]; then
        echo "Running SonarQube analysis for hotfix tag..."
        chmod +x hotfix_tag_sonar_analysis.sh
        ./hotfix_tag_sonar_analysis.sh
    else
        echo "Running SonarQube analysis for final tag..."
        chmod +x master_final_tag_sonar_analysis.sh
        ./master_final_tag_sonar_analysis.sh
    fi
else
    case "$BITBUCKET_BRANCH" in
        hotfix/*)
            echo "Running SonarQube analysis for hotfix branch: $BITBUCKET_BRANCH"
            chmod +x hotfix_sonar_analysis.sh
            ./hotfix_sonar_analysis.sh
            ;;
        main)
            echo "Running delete merged branch to master SonarQube analysis..."
            chmod +x delete_merged_branch_to_master_sonar_analysis.sh
            ./delete_merged_branch_to_master_sonar_analysis.sh

            cd /app/sonar


            echo "Running main SonarQube analysis..."
            chmod +x master_sonar_analysis.sh
            ./master_sonar_analysis.sh
            ;;
        *)
            echo "Running default SonarQube analysis for branch: $BITBUCKET_BRANCH"
            chmod +x sonar_analysis.sh
            ./sonar_analysis.sh
            ;;
    esac
fi
