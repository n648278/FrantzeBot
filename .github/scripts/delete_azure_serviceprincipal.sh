#!/bin/bash
GITHUB_REPO_NAME=$(basename -s .git `git config --get remote.origin.url`)
SP_NAME="sp-${GITHUB_REPO_NAME}-githubactions";
AZ_COMMAND=$(which az)

## Check for az command
which az > /dev/null
if [ $? -ne "0" ]; then
  echo "az command not present. Bailing out."
  exit 1
fi

## Delete Serviceprincipal in Azure
$AZ_COMMAND ad sp delete --id http://${SP_NAME} --query appId --output tsv
