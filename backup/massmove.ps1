#P O W E R C L I 
#mass relocate

if (Get-InstalledModule -Name VMware.PowerCLI) {
    Write-Output "PowerCLI already installed"
} else {
    Write-Output "Installing PowerCLI..."
    Install-Module -Name VMware.PowerCLI
}

$credentials = Get-VICredentialStoreItem -Host cyberlab.csusb.edu -File C:\Users\Administrator\Documents\Cyberlab-vsphere-master\creds.xml
$serv = Connect-VIServer cyberlab.csusb.edu -User $credentials.User -Password $credentials.Password

$deploymentname = "4620-61 Labman"
$datastoretomv = "Temp-ITS-DS"

$mdf=Get-Folder -Server $serv -Name $deploymentname -Location "03-Production"

$folds = $mdf | Get-Folder

foreach ($fold in $folds) {
    get-vm -Location $fold | move-vm -Datastore $datastoretomv -DiskStorageFormat "Thin" -RunAsync -Confirm:$false
}