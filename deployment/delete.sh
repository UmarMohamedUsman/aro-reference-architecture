RGNAME=spoke-rg
AROCLUSTER=ftaarocluster

# 1. Delete ARO cluster
az aro delete --resource-group $RGNAME --name $AROCLUSTER
