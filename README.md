# Template for automated build and deploy of docker images to kubernetes

This template is a way to get started with docker and kubernetes as well as Github Actions. We assume you have a docker container ready to be built and deployed.

### Prerequisites
All this needs to be done **BEFORE** you run the script mentioned below.
You need to install:
  * [KubeCtl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
    * Get config to your cluster from [this list](https://confluence.nrk.no/display/PLAT/Liste+over+kubernetes+clustre+og+config)
  * [Create the namespace](https://nrkconfluence.atlassian.net/wiki/spaces/KUB/pages/2850891/Liste+over+kubernetes+clustre+og+config) in the choosen cluster with the mknamespace app corresponding to the cluster to deploy to
  * Optionally: [Github cli](https://cli.github.com/)

**WARNING**

We are assuming that you are creating a new namespace, hence you have the correct permissions on that namespace (admin).
If you choose to use this template on an existing namespace, might be that your permissions have to be adjusted for the scripts to work correctly.

### Getting started
To get started:
  * Click the green button with the text "**Use this template**" and fill in the required information to create your new repository ([naming strategy for repos in NRK](https://blåbok.intern-we.drift.azure.nrk.cloud/Standarder/RFC-9-reponavngiving.html))
  * Clone your new repo
  * Edit the Dockerfile and insert the magic you have done for your wonderful app. (You don't have to do this at this point, but you can).
  * Run `.github/scripts/run.sh`: the scripts does some important things:
    * It populates the template for a `main` branch pipeline with the kubernetes cluster of your choice, the namespace of your choice, the name of the app and so on.
    * It populates the template for a kubernetes deployment of the named app with the corresponding variables.
    * It creates Kubernetes Service Account to deploy to kubernetes cluster. If you have [github cli](https://cli.github.com/) it will create the github secrets for you. If you do not have [github cli](https://cli.github.com/) installed, it returns the snippet you have to cut and paste into the "secrets" section of your repo. In this picture ![In this picture](/images/new_secrets.png) you are given an example: K8S_SA_SECRET must be in place,you have to create this secret manually in the GUI and call it *exactly* like shown (if you don't want to edit the workflows instead). Populate it with the corresponding yaml you get from the script. As you can see there are also other secrets that are at an organizazion level: two of them fix the permission to push to the Docker registry, one is the plattform registry, two is for MyGet, and one is for NPM.
  * Git commit your changes and push them upstream. This should start a `main` build and deployment of your app: in the "Actions" section of your repository you can see the output of your pipeline. Since we are now using the aquasecurity/trivy-action action, the docker images built with this template will be tested for vulnerabilities before they are deployed to kubernetes. If the test fails, you are trying to deploy a docker image containing vulnerabilities. This is not good and you should fix it: it will just get more expensive in term of technical debt to try to avoid it. If you choose to ignore this, be warned this can bite you back in other ways and you will have to take the pain (and responsibility). 

### More pipelines!
  * If you later on decide you want a "test" pipeline, you will have to populate the corresponding pipeline variables. You can find a test pipeline in the .github directory ("docker-build-push-test.yaml"), you will have to populate the following variables (use the `main` pipeline as a guide):
    * K8S_NAMESPACE: the namespace in the test cluster of your choice (of course you need to create it, if you haven't done this yet).
    * Once the namespace is created, log in the new cluster for your test pipeline using the appropriate tools, and use the appropriate tools to log into the namespace you are going to use.
    * K8S_API_URL: this is the address of the API of the cluster you are going to use. We can't assume that this will be a different cluster than the one you used for your `main` branch, (this is up to You to decide), however we populated it with the same cluster to begin with. This means that if you don't edit this value, you will deploy your test pods in the same namespace that you used for the `main` branch. If you want to use another namespace instead, create a namespace on the cluster of your choice, log in to the second cluster using the azure-cli or gcloud commands, and you can then fetch the API_URL using the script fetch_api.sh in the scripts directory. Populate the docker-build-push-test.yaml file accordingly.
    * If you have created your `main` branch pipeline at this point, the yaml files containing the k8s roles you need to use to create a k8s Service Account are populated (you can find them under .github/scripts/roles/ ) with the data relative to your (you created it first) `main` branch. These were populated automatically by run.sh. If you want to deploy your next branch to a different namespace (maybe even in another cluster) these roles now have to be edited accordingly (if you are deploying you next branch to a namespace with a different name) to the namespace (again, you have to be logged into it) you want to use. Edit the namespace field in the roles before you go to the next step. Keep in mind: the SA and the roles are namespace specific, and have to exist in all the different clusters / namespaces you are using.
    * You will have to add a new secret for your test pipeline if you are not using the same namespace / cluster you used for `main`, so you will need a corresponding secret manually created in the "secrets" section of your github repository. We have a script to do only this, it creates the roles (that are namespace specific and need to be edited before you run the script, see previous point), and a secret for the cluster you are logged in. Always double-check where you are logged in (cluster / namespace) before you run scripts.
    * Run the script sa.sh, it will create the roles for the namespace, and output the necessary data you will have to use to create the corresponding secret in the GUI.
    * Again, use the picture as a reference, and edit docker-build-push-test.yaml to match it.
    * The manifests for your new pipeline (the k8s deployment files, determining your pod,service,ingress layout into your namespace) are determined by the values you can find in the corresponding ( maybe docker-build-push-test.yaml ) file. If you are using that file, you can find them under manifests/test. But also those have been populated by run.sh as if you were deploying your test pipeline in the same namespace of you `main` pipeline. If this is not the case for you, you have to edit these as well. Mainly you have to look at the ingress.yml, where your namespace could be different, and the host / hosts variables should be adjusted according to the cluster you are using here. An overview of correct host values can be found into [Confluence](https://confluence.nrk.no/pages/viewpage.action?spaceKey=PLAT&title=Liste+over+kubernetes+clustre+og+config). If you want you can run this oneliner to find out the value for the cluster you are logged in:
    ```
    kubectl -n ingress-nginx get certificate ingress-wildcard -o "jsonpath={.spec.dnsNames[0]}"
    ```
    * Once all this is done, you can push your changes upstream so that the new pipeline will be triggered.
    * Repeat the process for even more pipelines.

### Some more notes about K8S_SA_SECRET
Unluckily this is not just a secret to authenticate to a corresponding namespace in a cluster (defined in a "sa" object in k8s), but it also contains the SSL certificate of the cluster you are conneting to. This means that if/when the certificate changes, you also have to update your secret, of the deployment will fail.
To help with this we have provided a script (you can find it under .github/scripts/output_sa_secret.sh), where you can find the commands that have to be ran.
The script as is has to be ran from a github repo directory for your app, while connected to the corresponding namespace, and will output the K8S_SA_SECRET including the new certificate. It is thought to be used as a complement to this template.

### Various
Keep in mind that this is just a sample and a "get started"-template. You will have to dig into the [Github Actions documentation](https://docs.github.com/en/actions). Yes, you do need to. For example, we can't know in advance what is your workflow, but assuming that you will merge from a branch to another, you will have to adjust the pipelines, in order to avoid triggering builds for the wrong pipeline when you merge. This is controlled by the "paths-ignore" value in your different pipelines / branch, and you are the boss here.

### I need help!
You can get support from Plattform in the #ci-cd-prosjekt-plattform channel on Slack. Don't query people privately so that your problem will be noticed by more people, possibly leaving a trace for the others using the same pipeline. You will both increase your chances to get help, and help others that might come after you ( the backlog is gold ).
