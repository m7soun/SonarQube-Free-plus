#!/bin/bash
cd /opt/atlassian/pipelines/agent/build
COMMIT_HAPPEN=false
# Check if the RUN_SONAR_ANALYSIS variable is set and is true
if [[ -n "$RUN_SONAR_ANALYSIS" && "$RUN_SONAR_ANALYSIS" == "true" ]]; then
    echo "RUN_SONAR_ANALYSIS is set to true. Proceeding with SonarQube analysis..."
else
    echo "RUN_SONAR_ANALYSIS is not set to true or is unset. Skipping SonarQube analysis."
    exit 0
fi

echo "Installing jq..."
apk add jq

echo "Preparing project key..."
BRANCH_KEY=$(echo "$BITBUCKET_BRANCH" | tr '/' '-')
PROJECT_KEY=$(echo "${BITBUCKET_WORKSPACE}::${BITBUCKET_REPO_SLUG}::${BRANCH_KEY}" | tr '\\' '-')

echo "Fetching project information from SonarQube..."
RESPONSE=$(curl -H "Authorization: Bearer $SONAR_USER_TOKEN" -H "Accept: application/json" -H "Content-Type: application/json" "$SONAR_HOST_URL/api/projects/search?projects=$PROJECT_KEY" || echo "Failed to fetch data from SonarQube")
echo "$RESPONSE"  # Echo the response
TOTAL=$(echo "$RESPONSE" | jq -r '.paging.total')

echo "$TOTAL"  # Echo the total

if [ $TOTAL -gt 0 ]; then
    echo "Project $PROJECT_KEY already exists in SonarQube. Skipping analysis."
else
    echo "Fetching latest changes from the remote repository..."
    git fetch --depth=1000000
    git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
    git fetch origin --depth=1000000

    # Determine the main branch
    MAIN_BRANCH=$(git for-each-ref --format '%(refname:short)' refs/remotes/origin | grep -Ei '^(origin/main|origin/master|origin/default)$' | head -n1)

    if [ -z "$MAIN_BRANCH" ]; then
        echo "Failed to determine the main branch. Exiting..."
        exit 1
    fi

    echo "Checking out the main branch: $MAIN_BRANCH..."
    git add .
    git commit -m "Sonar Safe Commit"
    COMMIT_HAPPEN=true
    git checkout --track $MAIN_BRANCH

    echo "Getting the latest tag..."
    LATEST_TAG=$(git describe --tags --abbrev=0)

    echo "Getting the commit short hash of the one before the latest..."
    if [ "$COMMIT_HAPPEN" = true ]; then
        SECOND_LAST_COMMIT_HASH=$(git rev-parse --short HEAD~1)
    else
        SECOND_LAST_COMMIT_HASH=$(git rev-parse --short HEAD)
    fi
    echo "Second last  hash: $SECOND_LAST_COMMIT_HASH"


    echo "Project key for SonarQube: ${PROJECT_KEY}"
    echo "Running SonarQube analysis..."
    sonar-scanner \
        -Dsonar.projectKey="$PROJECT_KEY" \
        -Dsonar.sources="." \
        -Dsonar.exclusions="$EXTRA_EXCLUSIONS,**/*.pdf,**/*.csv,**/*.xlsx,**/*.xls,**/*.doc,**/*.docx,**/*.ppt,**/*.pptx,**/*.odt,**/*.ods,**/*.odp,**/*.odg,**/*.otp,**/*.ots,**/*.otp,**/*.ott,**/*.rtf,**/*.jpg,**/*.jpeg,**/*.gif,**/*.png,**/*.bmp,**/*.ico,**/*.tif,**/*.tiff,**/*.psd,**/*.ai,**/*.eps,**/*.svg,**/*.jar,**/*.zip,**/*.tar.gz,**/*.tgz,**/*.tar.bz2,**/*.tar,**/*.gz,**/*.bz2,**/*.xz,**/*.rar,**/*.7z,**/*.class,**/*.war,**/*.ear,**/*.aar,**/*.apk,**/*.exe,**/*.dll,**/*.lib,**/*.obj,**/*.so,**/*.a,**/*.pdb,**/*.lib,**/*.dll,**/*.exp,**/*.manifest,**/*.txt,**/*.log,**/*.zsh,**/*.ksh,**/*.csh,**/*.tcsh,**/*.rc,**/*.prefs,**/*.coffee,**/*.erb,**/*.rjs,**/*.jspf,**/*.jspc,**/*.jsf,**/*.tmpl,**/*.tpl,**/*.vbhtml,**/*.as,**/*.m,**/*.mm,**/*.l,**/*.flex,**/*.xsd,**/*.xsl,**/*.xslt,**/*.dtd,**/*.ent,**/*.cc,**/*.h++,**/*.mjs,**/*.wasm,**/*.cson,**/*.pxd,**/*.pxi,**/*.rmd,**/*.Rmd,**/*.Rnw,**/*.Rnw,**/*.ddl,**/*.dml,**/*.dcl,**/*.plb,**/*.pld,**/*.plh,**/*.spl,**/*.ada,**/*.adb,**/*.ads,**/*.pm,**/*.pl,**/*.t,**/*.v,**/*.sv,**/*.svh,**/*.vh,**/*.vhd,**/*.vhi,**/*.vho,**/*.vhs,**/*.sv,**/*.svh,**/*.vlog,**/*.vlogh,**/*.vams,**/*.vams,**/*.ahk,**/*.ahkl,**/*.bas,**/*.vbs,**/*.vbscript,**/*.wsf,**/*.wsc,**/*.wsh,**/*.sc,**/*.sik,**/*.RData,**/*.rds,**/*.rda,**/*.rk,**/*.Rk,**/*.rkt,**/*.Rkt,**/*.rktl,**/*.Rktl,**/*.scm,**/*.SS,**/*.ss,**/*.sch,**/*.scm,**/*.tcl,**/*.tk,**/*.itcl,**/*.itk,**/*.upr,**/*.upp,**/*.ucf,**/*.bsc,**/*.s,**/*.asm,**/*.sasm,**/*.S,**/*.inc,**/*.erb,**/*.rhtml,**/*.rjs,**/*.pug,**/*.toml,**/*.ini,**/*.cnf,**/*.plist,**/*.strings,**/*.po,**/*.pot,**/*.mo,**/*.mos,**/*.locale,**/*.babelrc,**/*.eslintrc,**/*.jshintrc,**/*.jscsrc,**/*.jscs.json,**/*.app,**/*.dll,**/*.lib,**/*.so,**/*.a,**/*.dylib,**/*.jnilib,**/*.rpm,**/*.deb,**/*.gem,**/*.udeb,**/*.ko,**/*.la,**/*.lai,**/*.pr"\
        -Dsonar.host.url="$SONAR_HOST_URL" \
        -Dsonar.token="$SONAR_TOKEN" \
        -Dsonar.projectVersion="$LATEST_TAG | $SECOND_LAST_COMMIT_HASH" \
        -Dsonar.projectDescription="latest analysis version is $LATEST_TAG" \
        -Dsonar.analysis.comment="$LATEST_TAG" \
#        -Dsonar.qualitygate.wait=true \
        -Dsonar.scm.provider=git

    echo "Setting the latest tag for the project..."
    curl -X POST -H "Authorization: Bearer $SONAR_USER_TOKEN" -H "Content-Type: application/json" "$SONAR_HOST_URL/api/project_tags/set?project=$PROJECT_KEY&tags=$LATEST_TAG"
fi

echo "Fetching latest changes from the remote repository..."
git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
git fetch origin --depth=1000000

echo "Listing all branches..."
git branch -a

echo "Checking out the branch $BITBUCKET_BRANCH..."
git checkout $BITBUCKET_BRANCH

echo "Getting the commit short hash of the one before the latest..."
if [ "$COMMIT_HAPPEN" = true ]; then
    SECOND_LAST_COMMIT_HASH=$(git rev-parse --short HEAD~1)
else
    SECOND_LAST_COMMIT_HASH=$(git rev-parse --short HEAD)
fi
echo "Second last  hash: $SECOND_LAST_COMMIT_HASH"

echo "Setting the second last commit hash as the tag for the project..."
curl -X POST -H "Authorization: Bearer $SONAR_USER_TOKEN" -H "Content-Type: application/json" "$SONAR_HOST_URL/api/project_tags/set?project=$PROJECT_KEY&tags=$SECOND_LAST_COMMIT_HASH"

echo "Project key for SonarQube: ${PROJECT_KEY}"
echo "Running SonarQube analysis..."
sonar-scanner \
    -Dsonar.projectKey="$PROJECT_KEY" \
    -Dsonar.sources="." \
    -Dsonar.exclusions="$EXTRA_EXCLUSIONS,**/*.pdf,**/*.csv,**/*.xlsx,**/*.xls,**/*.doc,**/*.docx,**/*.ppt,**/*.pptx,**/*.odt,**/*.ods,**/*.odp,**/*.odg,**/*.otp,**/*.ots,**/*.otp,**/*.ott,**/*.rtf,**/*.jpg,**/*.jpeg,**/*.gif,**/*.png,**/*.bmp,**/*.ico,**/*.tif,**/*.tiff,**/*.psd,**/*.ai,**/*.eps,**/*.svg,**/*.jar,**/*.zip,**/*.tar.gz,**/*.tgz,**/*.tar.bz2,**/*.tar,**/*.gz,**/*.bz2,**/*.xz,**/*.rar,**/*.7z,**/*.class,**/*.war,**/*.ear,**/*.aar,**/*.apk,**/*.exe,**/*.dll,**/*.lib,**/*.obj,**/*.so,**/*.a,**/*.pdb,**/*.lib,**/*.dll,**/*.exp,**/*.manifest,**/*.txt,**/*.log,**/*.zsh,**/*.ksh,**/*.csh,**/*.tcsh,**/*.rc,**/*.prefs,**/*.coffee,**/*.erb,**/*.rjs,**/*.jspf,**/*.jspc,**/*.jsf,**/*.tmpl,**/*.tpl,**/*.vbhtml,**/*.as,**/*.m,**/*.mm,**/*.l,**/*.flex,**/*.xsd,**/*.xsl,**/*.xslt,**/*.dtd,**/*.ent,**/*.cc,**/*.h++,**/*.mjs,**/*.wasm,**/*.cson,**/*.pxd,**/*.pxi,**/*.rmd,**/*.Rmd,**/*.Rnw,**/*.Rnw,**/*.ddl,**/*.dml,**/*.dcl,**/*.plb,**/*.pld,**/*.plh,**/*.spl,**/*.ada,**/*.adb,**/*.ads,**/*.pm,**/*.pl,**/*.t,**/*.v,**/*.sv,**/*.svh,**/*.vh,**/*.vhd,**/*.vhi,**/*.vho,**/*.vhs,**/*.sv,**/*.svh,**/*.vlog,**/*.vlogh,**/*.vams,**/*.vams,**/*.ahk,**/*.ahkl,**/*.bas,**/*.vbs,**/*.vbscript,**/*.wsf,**/*.wsc,**/*.wsh,**/*.sc,**/*.sik,**/*.RData,**/*.rds,**/*.rda,**/*.rk,**/*.Rk,**/*.rkt,**/*.Rkt,**/*.rktl,**/*.Rktl,**/*.scm,**/*.SS,**/*.ss,**/*.sch,**/*.scm,**/*.tcl,**/*.tk,**/*.itcl,**/*.itk,**/*.upr,**/*.upp,**/*.ucf,**/*.bsc,**/*.s,**/*.asm,**/*.sasm,**/*.S,**/*.inc,**/*.erb,**/*.rhtml,**/*.rjs,**/*.pug,**/*.toml,**/*.ini,**/*.cnf,**/*.plist,**/*.strings,**/*.po,**/*.pot,**/*.mo,**/*.mos,**/*.locale,**/*.babelrc,**/*.eslintrc,**/*.jshintrc,**/*.jscsrc,**/*.jscs.json,**/*.app,**/*.dll,**/*.lib,**/*.so,**/*.a,**/*.dylib,**/*.jnilib,**/*.rpm,**/*.deb,**/*.gem,**/*.udeb,**/*.ko,**/*.la,**/*.lai,**/*.pr"\
    -Dsonar.host.url="$SONAR_HOST_URL" \
    -Dsonar.token="$SONAR_TOKEN" \
    -Dsonar.projectDescription="latest analysis version is $LATEST_TAG" \
    -Dsonar.analysis.comment="$LATEST_TAG" \
    -Dsonar.qualitygate.wait=true \
    -Dsonar.scm.provider=git
