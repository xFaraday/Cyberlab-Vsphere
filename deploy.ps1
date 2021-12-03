#Deploy script P O W E R CLI
#inputs:
#user array, deployment name, VMs that are not supposed to be shown, cluster host, datastore
$serv = Connect-VIServer -Server 
 
#userlist
$users=get-content ""
 
#folder name
$masterdeploymentname= ""
 
#VMs to clone, TEMPLATES
$srcvms = get-vm -location ""
 
#resources
$datastore = Get-Datastore RS2-Prod3-DS
$vmhost = get-vmhost 
 
#Portgroup to clone
$portgroup = ""
$portgroupsrc = Get-VDPortgroup -Name $portgroup
$portgroupsrcname = (Get-VDPortgroup -Name $portgroup).Name
 
#Student role for permissions
$studentrole = Get-VIRole -name Student
$prod = Get-Folder -Server $serv -Name 03-Production
 
#$masterdeploymentfolder=Get-Folder -Server $serv -Name GenCyber -Location 03-Production
$masterdeploymentfolder = New-Folder -Name $masterdeploymentname -Location $prod
 
function generatenewvlanID() {
    $ran = Get-Random -Maximum 3500
    $vlan = (Get-VDPortGroup -VDSwitch "Pods").VlanConfiguration
    if($vlan | where {$_.VlanID -eq $ran}) {
        return $NULL
    } else {
        return $ran
    }
}
 
foreach ($u in $users) {
    $createdfolder = New-Folder -Name $u -Location $masterdeploymentfolder
    #clone new vms
    Foreach ($srcvm in $srcvms) {
        #name, VM, cluster host, datastore, datastore format, location, async
        new-vm -name ($srcvm).Name -vm $srcvm -vmhost $vmhost -datastore $datastore -DiskStorageFormat Thin -Location $createdfolder
    }
    #assign network adapter on new vms
    while (1) {
        $id=generatenewvlanID
        if ($id -eq $NULL){
            generatenewvlanID
        } else {
            write-warning $id
            break
        }
    }
    $createdportgroup = Get-VDSwitch -Name "Pods" | New-VDPortgroup -Name "$portgroupsrcname-$u" -ReferencePortgroup $portgroupsrc     
    $createdportgroup | set-VDPortgroup -VlanID $id     
    $newvms = get-vm -location $createdfolder
    Foreach ($newvm in $newvms){
        $newvm | get-networkadapter | where {$_.NetworkName -eq $portgroup} | Set-NetworkAdapter -NetworkName $createdportgroup -confirm:$false
        if(($newvm).Name -eq "Kali") {
            New-VIPermission -Role $studentrole -Principal "CSUSB\$u" -Entity $newvm
        }
    }
}