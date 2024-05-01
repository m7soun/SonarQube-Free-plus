#!/bin/bash
cd /opt/atlassian/pipelines/agent/build

# Check if the RUN_SONAR_ANALYSIS variable is set and is true
if [[ -n "$RUN_SONAR_ANALYSIS" && "$RUN_SONAR_ANALYSIS" == "true" ]]; then
    echo "RUN_SONAR_ANALYSIS is set to true. Proceeding with SonarQube analysis..."
else
    echo "RUN_SONAR_ANALYSIS is not set to true or is unset. Skipping SonarQube analysis."
    exit 0
fi

# Extract the branch name from the tag
BRANCH_NAME=$(git for-each-ref --format '%(refname:short)' "refs/tags/$TAG_NAME" | cut -d '/' -f 2-)
echo "Branch name associated with the tag: $BRANCH_NAME"

# Check if the branch name is not empty
if [[ -z "$BRANCH_NAME" ]]; then
    echo "Error: Unable to determine the branch name associated with the tag."
    exit 1
fi

# Check if the main branch was tagged with the $BITBUCKET_TAG
TAG_NAME="$BITBUCKET_TAG"

echo "Preparing project key..."
BRANCH_KEY=$(echo "$BRANCH_NAME" | tr '/' '-')
PROJECT_KEY=$(echo "${BITBUCKET_WORKSPACE}::${BITBUCKET_REPO_SLUG}::${BRANCH_KEY}::hotfix" | tr '\\' '-')

echo "Setting the latest tag for the project..."
curl -X POST -H "Authorization: Bearer $SONAR_USER_TOKEN" -H "Content-Type: application/json" "$SONAR_HOST_URL/api/project_tags/set?project=$PROJECT_KEY&tags=$TAG_NAME"

sonar-scanner \
        -Dsonar.projectKey="$PROJECT_KEY" \
        -Dsonar.sources="." \
        -Dsonar.exclusions="$EXTRA_EXCLUSIONS,**/*.pdf,**/*.csv,**/*.xlsx,**/*.xls,**/*.doc,**/*.docx,**/*.ppt,**/*.pptx,**/*.odt,**/*.ods,**/*.odp,**/*.odg,**/*.otp,**/*.ots,**/*.otp,**/*.ott,**/*.rtf,**/*.jpg,**/*.jpeg,**/*.gif,**/*.png,**/*.bmp,**/*.ico,**/*.tif,**/*.tiff,**/*.psd,**/*.ai,**/*.eps,**/*.svg,**/*.jar,**/*.zip,**/*.tar.gz,**/*.tgz,**/*.tar.bz2,**/*.tar,**/*.gz,**/*.bz2,**/*.xz,**/*.rar,**/*.7z,**/*.class,**/*.war,**/*.ear,**/*.aar,**/*.apk,**/*.exe,**/*.dll,**/*.lib,**/*.obj,**/*.so,**/*.a,**/*.pdb,**/*.lib,**/*.dll,**/*.exp,**/*.manifest,**/*.txt,**/*.log,**/*.zsh,**/*.ksh,**/*.csh,**/*.tcsh,**/*.rc,**/*.prefs,**/*.coffee,**/*.erb,**/*.rjs,**/*.jspf,**/*.jspc,**/*.jsf,**/*.tmpl,**/*.tpl,**/*.vbhtml,**/*.as,**/*.m,**/*.mm,**/*.l,**/*.flex,**/*.xsd,**/*.xsl,**/*.xslt,**/*.dtd,**/*.ent,**/*.cc,**/*.h++,**/*.mjs,**/*.wasm,**/*.cson,**/*.pxd,**/*.pxi,**/*.rmd,**/*.Rmd,**/*.Rnw,**/*.Rnw,**/*.ddl,**/*.dml,**/*.dcl,**/*.plb,**/*.pld,**/*.plh,**/*.spl,**/*.ada,**/*.adb,**/*.ads,**/*.pm,**/*.pl,**/*.t,**/*.v,**/*.sv,**/*.svh,**/*.vh,**/*.vhd,**/*.vhi,**/*.vho,**/*.vhs,**/*.sv,**/*.svh,**/*.vlog,**/*.vlogh,**/*.vams,**/*.vams,**/*.ahk,**/*.ahkl,**/*.bas,**/*.vbs,**/*.vbscript,**/*.wsf,**/*.wsc,**/*.wsh,**/*.sc,**/*.sik,**/*.RData,**/*.rds,**/*.rda,**/*.rk,**/*.Rk,**/*.rkt,**/*.Rkt,**/*.rktl,**/*.Rktl,**/*.scm,**/*.SS,**/*.ss,**/*.sch,**/*.scm,**/*.tcl,**/*.tk,**/*.itcl,**/*.itk,**/*.upr,**/*.upp,**/*.ucf,**/*.bsc,**/*.s,**/*.asm,**/*.sasm,**/*.S,**/*.inc,**/*.erb,**/*.rhtml,**/*.rjs,**/*.pug,**/*.toml,**/*.ini,**/*.cnf,**/*.plist,**/*.strings,**/*.po,**/*.pot,**/*.mo,**/*.mos,**/*.locale,**/*.babelrc,**/*.eslintrc,**/*.jshintrc,**/*.jscsrc,**/*.jscs.json,**/*.app,**/*.dll,**/*.lib,**/*.so,**/*.a,**/*.dylib,**/*.jnilib,**/*.rpm,**/*.deb,**/*.gem,**/*.udeb,**/*.ko,**/*.la,**/*.lai,**/*.pr"\
        -Dsonar.host.url="$SONAR_HOST_URL" \
        -Dsonar.token="$SONAR_TOKEN" \
        -Dsonar.projectDescription="latest analysis version is $TAG_NAME" \
        -Dsonar.analysis.comment="$TAG_NAME" \
        -Dsonar.qualitygate.wait=true \
        -Dsonar.scm.provider=git

