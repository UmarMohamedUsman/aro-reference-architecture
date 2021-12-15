#############################
#Install Azure CLI
#############################
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'
Remove-Item -Path .\AzureCLI.msi


#############################
#Install Docker -
# Need to figure out how to do this in quiet mode
#############################
Install-Module -Name DockerMsftProvider -Repository PSGallery -Force
Install-Package -Name docker -ProviderName DockerMsftProvider
#  A restart is required to enable the containers feature. *** Restart the machine***
Start-Service Docker

#############################
#Install Kubectl
#############################
curl -LO "https://dl.k8s.io/release/v1.23.0/bin/windows/amd64/kubectl.exe"
Install-Script -Name 'install-kubectl' -Scope CurrentUser -Force
install-kubectl.ps1 -DownloadLocation ./


#############################
#Install Helm
#############################

#############################
#Install OC CLI
#############################