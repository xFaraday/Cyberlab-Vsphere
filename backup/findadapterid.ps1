#display teams
if (Get-InstalledModule -Name VMware.PowerCLI) {
    Write-Output "PowerCLI already installed"
} else {
    Write-Output "Installing PowerCLI..."
    Install-Module -Name VMware.PowerCLI
}

$credentials = Get-VICredentialStoreItem -Host cyberlab.csusb.edu -File C:\Users\Administrator\Documents\Cyberlab-vsphere-master\creds.xml
$serv = Connect-VIServer cyberlab.csusb.edu -User $credentials.User -Password $credentials.Password

function generatenewvlanID() {
    $ran = Get-Random -Maximum 4000
    $vlan = (Get-VDPortGroup -VDSwitch "Pods").VlanConfiguration
    if($vlan | where {$_.VlanID -eq $ran}) {
        return $NULL
    } else {
        return $ran
    }
}

while (1) {
    $id=generatenewvlanID
    if ($id -eq $NULL){
        generatenewvlanID
    } else {
        Write-Warning $id
        break
    }
}