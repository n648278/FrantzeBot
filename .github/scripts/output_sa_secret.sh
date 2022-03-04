#!/bin/bash
BCYAN='\033[1;36m'

KUBE=$(which kubectl)
GITHUB_REPO_NAME=$(basename -s .git `git config --get remote.origin.url`)
K8S_SA_NAME="${GITHUB_REPO_NAME}-githubactions"

## -Set some variables
printf "Insert the namespace where the secret has to be regenerated:\n"
read K8S_NAMESPACE

K8S_SA_SECRET=$($KUBE get secret --namespace ${K8S_NAMESPACE} $($KUBE get serviceaccounts --namespace ${K8S_NAMESPACE} ${K8S_SA_NAME} -o 'jsonpath={.secrets[*].name}') -o yaml)

## Print final info and instructions
printf "\n\n"
printf "K8S_SA_SECRET: \n ${BCYAN}${K8S_SA_SECRET}${NC} \n"
printf "\n"
