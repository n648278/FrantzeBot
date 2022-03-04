#!/bin/bash

# Colors for printf. Hell yeah!...
RED='\033[0;31m'
BRED='\033[1;31m'
GREEN='\033[0;32m'
BGREEN='\033[1;32m'
CYAN='\033[0;36m'
BCYAN='\033[1;36m'
NC='\033[0m' # No Color

if [[ ! $(command -v az &> /dev/null) -eq 0 && ! $(command -v kubectl &> /dev/null) -eq 0 ]]
then
    printf "${BRED}This script requires a logged in Azure-CLI and authenticated Kubectl!${NC}\n\n"
    exit 1
fi

if [[ $(uname -s) == "Darwin" ]]
then
    SED_ARG="-i \'\'"
else
    SED_ARG="-i"
fi

## -Set some variables
printf "Insert the namespace where the deployment will reside:\n"
read K8S_NAMESPACE

CURRENT_DIR=$(pwd)
GITHUB_REPO_NAME=$(basename -s .git `git config --get remote.origin.url`)
K8S_SA_NAME="${GITHUB_REPO_NAME}-githubactions"
K8S_HOST=$(kubectl -n ingress-nginx get certificate ingress-wildcard -o "jsonpath={.spec.dnsNames[0]}")

printf "\n${BGREEN}----------------------------------------${NC}\n"
printf "${RED}Make sure you are connected to the VPN in order to reach the cluster API${NC}\n"
printf "${RED}Make sure you have kubectl set to correct context (Cluster and namespace) and that the namespace ${BRED}exist${RED} before continuing!${NC}\n"
printf "${GREEN}If you need to create the namespace first, do this via the mknamespace url for your corresponding cluster: ${CYAN}https://confluence.nrk.no/display/PLAT/Liste+over+kubernetes+clustre+og+config${NC}\n\n"
printf "\nThe deployment will get the name: ${BCYAN}${GITHUB_REPO_NAME}${NC}"
printf "\nThe service will get the name: ${BCYAN}${GITHUB_REPO_NAME}${NC}"
printf "\nThe ingress will get the name: ${BCYAN}${GITHUB_REPO_NAME}${NC}"
printf "\nIt will be deployed in the namespace: ${BCYAN}${K8S_NAMESPACE}${NC}"
printf "\nKubernetes Service account will be named: ${BCYAN}${K8S_SA_NAME}${NC}"
printf "\nThe hostname of the ingress will be: ${BCYAN}${GITHUB_REPO_NAME}.${K8S_HOST:2}${NC}"
printf "\nThe Azure Service Principal will be named: ${BCYAN}${SP_NAME}${NC}"
printf "\n${BGREEN}----------------------------------------${NC}\n\n"

read -p $'\e[1;32mPress [Enter] key to create...\e[0m' key

kubectl apply -f .github/scripts/roles/sa.yml
kubectl apply -f .github/scripts/roles/role.yml
kubectl apply -f .github/scripts/roles/rolebinding.yml

K8S_SA_SECRET=$(kubectl get secret --namespace ${K8S_NAMESPACE} $(kubectl get serviceaccounts --namespace ${K8S_NAMESPACE} ${K8S_SA_NAME} -o 'jsonpath={.secrets[*].name}') -o yaml)

## Print final info and instructions
printf "\n\n"
printf "You need to create secrets that the output needs to be put into on the repo ( ${CYAN}https://github.com/nrkno/${GITHUB_REPO_NAME}/settings/secrets${NC} ):\n"
printf "secret name:           secret value:\n"
printf "K8S_SA_SECRET: \n ${BCYAN}${K8S_SA_SECRET}${NC} \n"
printf "\n"
printf '(You may call it something else, but remember to also change the workflow yml file)\n\n'
