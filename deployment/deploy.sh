#!/usr/bin/env bash

RGNAME=spoke-rg
LOCATION=westus
AROCLUSTER=ftaarocluster                 # the name of your ARO cluster
AROVNET=aro-vnet
PULLSECRETLOCATION=@/mnt/c/Users/umarm/Downloads/pull-secret.txt

# IP Addresses
AROVNET_PREFIX=10.0.0.0/22
MASTERSUBNET_PREFIX=10.0.0.0/23
WORKERSUBNET_PREFIX=10.0.2.0/23

# 1. creates the resource group
az group create --name $RGNAME --location $LOCATION

# 2. ARO needs minimum of 40 cores, check to make sure your subscription Limit is 40 cores or more
az vm list-usage -l $LOCATION \
--query "[?contains(name.value, 'standardDSv3Family')]" \
-o table

# 3. Register the necessary resource providers
az provider register -n Microsoft.RedHatOpenShift --wait
az provider register -n Microsoft.Compute --wait
az provider register -n Microsoft.Storage --wait
az provider register -n Microsoft.Authorization --wait

# 4. Create a virtual network
az network vnet create \
   --resource-group $RGNAME \
   --name $AROVNET \
   --address-prefixes $AROVNET_PREFIX

# 5. Add an empty subnet for the master nodes. (Removed Service endpoints param from doc, as we will be adding private endpoint for ACR)
az network vnet subnet create \
  --resource-group $RGNAME \
  --vnet-name $AROVNET \
  --name master-subnet \
  --address-prefixes $MASTERSUBNET_PREFIX
  
# 6. Add an empty subnet for the worker nodes. (Removed Service endpoints param from doc, as we will be adding private endpoint for ACR)
az network vnet subnet create \
  --resource-group $RGNAME \
  --vnet-name $AROVNET \
  --name worker-subnet \
  --address-prefixes $WORKERSUBNET_PREFIX

# 7. Disable subnet private endpoint policies on the master subnet. This is required for the service to be able to connect to and manage the cluster.
az network vnet subnet update \
  --name master-subnet \
  --resource-group $RGNAME \
  --vnet-name $AROVNET \
  --disable-private-link-service-network-policies true

# 8. Create private ARO cluster
az aro create \
  --resource-group $RGNAME \
  --name $AROCLUSTER \
  --vnet $AROVNET \
  --master-subnet master-subnet \
  --worker-subnet worker-subnet \
  --apiserver-visibility Private \
  --ingress-visibility Private \
  --pull-secret $PULLSECRETLOCATION
  # --domain foo.example.com # [OPTIONAL] custom domain

# 9. Connect to ARO cluster
az aro list-credentials \
  --name $AROCLUSTER \
  --resource-group $RGNAME

# 10. Find the ARO cluster console URL and browse using your browser
az aro show \
    --name $AROCLUSTER \
    --resource-group $RGNAME \
    --query "consoleProfile.url" -o tsv

# 11. Download the latest OpenShift 4 CLI for Linux.
cd ~
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz

mkdir openshift
tar -zxvf openshift-client-linux.tar.gz -C openshift
echo 'export PATH=$PATH:~/openshift' >> ~/.bashrc && source ~/.bashrc

# 12. Connect using the OpenShift CLI
apiServer=$(az aro show -g $RGNAME -n $AROCLUSTER --query apiserverProfile.url -o tsv)

# 13. Login to the OpenShift cluster's API server
oc login $apiServer -u kubeadmin -p "He3GZ-mnpLA-vmgoZ-PMVvU"

# 14. To display all namespaces
oc get ns