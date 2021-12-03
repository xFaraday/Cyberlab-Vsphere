# P O W E R C L I 
# mass undeploy vm script
 
$serv = Connect-VIServer -Server 
 
#vm folder to destroy
$masterdeploymentname=""
 
$vms = get-vm -Location $masterdeploymentname
$networklist=(Get-VM -Location $masterdeploymentname | get-networkadapter).NetworkName | select -Unique
 
foreach ($vm in $vms) {
    if (($vm).PowerState -eq "PoweredOn") {
        stop-vm -VM $vm -Confirm:$false 
    }
    Remove-VM -VM $vm -DeletePermanently -RunAsync -confirm:$false
}
 
foreach ($portgroup in $networklist) {
    Get-VirtualPortgroup | where {($_.Name -eq $portgroup) -and ($_.Name -ne "DH-NAT-USERS")} | Remove-VirtualPortGroup -confirm:$false
}