# P O W E R C L I 
# mass undeploy vm script
$credentials = Get-VICredentialStoreItem -Host cyberlab.csusb.edu -File C:\Users\Administrator\Documents\Cyberlab-vsphere-master\creds.xml
$serv = Connect-VIServer cyberlab.csusb.edu -User $credentials.User -Password $credentials.Password

#vm folder to destroy
$masterdeploymentname=""

$vms = get-vm -Location $masterdeploymentname
$networklist=(Get-VM -Location $masterdeploymentname | get-networkadapter).NetworkName | select -Unique

function jobcheck() {
    $jobs = Get-Job
    foreach($job in $jobs) {
        if (($job).State -eq "Running") {
            return $false
        }  
        else {
            return $true
        }
    }
}

foreach ($vm in $vms) {
    if (($vm).PowerState -eq "PoweredOn") {
        stop-vm -VM $vm -Confirm:$false 
    }
    #Start-Job -ScriptBlock {
        
    Remove-VM -VM $vm -Server $serv -DeletePermanently -RunAsync -confirm:$false
    #}
}

#Do {
#    Start-Sleep -s 5
#} Until(jobcheck)

start-sleep -s 45

foreach ($portgroup in $networklist) {
    Get-VDPortGroup | where {($_.Name -eq $portgroup) -and ($_.Name -ne "DH-NAT-USERS")} | Remove-VDPortgroup -RunAsync -confirm:$false
}

Remove-Folder -Folder $masterdeploymentname -confirm:$false