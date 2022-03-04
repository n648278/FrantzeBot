#!/bin/bash
echo "This script assumes you allready have a ServiceAccount!"
echo "Make sure your kubeconfig context is set to same namespace and cluster as your serviceaccount!"
read -p "Name of service account?" SERVICE_ACCOUNT
read -p "Namespace?" NAMESPACE
read -p "What system is the service account for (for example jenkins)?" SYSTEM

clustername="$(kubectl config current-context)"
secretname="${SERVICE_ACCOUNT}-${SYSTEM}"
configfile=$(mktemp)
tmpfile=$(mktemp)


if [[ ${SERVICE_ACCOUNT} != "" && ${NAMESPACE} != "" && ${SYSTEM} != "" ]];
then

     # We create a Secret for an allready existing ServiceAccount
     echo "
     apiVersion: v1
     kind: Secret
     metadata:
       annotations:
         kubernetes.io/service-account.name: ${SERVICE_ACCOUNT}
       name: ${secretname}
       namespace: ${NAMESPACE}
     type: kubernetes.io/service-account-token" | kubectl create -f -
     
     # base64 switch
     d=d
     if [[ "${OSTYPE}" == "darwin"* ]]
       then
         d=D
     fi
     
     # Get CA cert for cluster and save to temp-file
     kubectl get secrets ${secretname} -n ${NAMESPACE} -o go-template='{{ index .data "ca.crt" }}'|base64 -${d} > ${tmpfile}
     # Set server and insert CA-cert into configfile
     kubectl --kubeconfig=${configfile} config set-cluster ${clustername} --embed-certs=true --certificate-authority=${tmpfile} --server=$(kubectl config view -o jsonpath="{.clusters[?(@.name == \"${clustername}\")].cluster.server}")
     # Remove CA-cert temp-file
     rm -- ${tmpfile}
     # Get token from created secret
     token=$(kubectl get secrets ${secretname} -n ${NAMESPACE} -o go-template='{{ index .data "token" }}'|base64 -${d})
     # Set credentials to cluster with token from serviceaccount
     kubectl --kubeconfig=${configfile} config set-credentials "${SERVICE_ACCOUNT}" --token="${token}"
     # Set defult namespace to correct prompted namespace
     kubectl --kubeconfig=${configfile} config set-context ${clustername} --cluster=${clustername} --user="${SERVICE_ACCOUNT}" --namespace="${NAMESPACE}"
     # Set config to use cluster with SA as user
     kubectl --kubeconfig=${configfile} config use-context ${clustername}
     
     echo "Kubernetes config is in: ${configfile}"
     cat $configfile
     echo "run cat ${configfile} | base64"
else
     echo "All input must be provided"
fi
