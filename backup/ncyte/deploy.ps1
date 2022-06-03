#Deploy script P O W E R CLI
#inputs:
#user array, deployment name, VMs that are not supposed to be shown, cluster host, datastore
$credentials = Get-VICredentialStoreItem -Host cyberlab.csusb.edu -File C:\Users\Administrator\Documents\Cyberlab-vsphere-master\creds.xml
$serv = Connect-VIServer cyberlab.csusb.edu -User $credentials.User -Password $credentials.Password
$ErrorActionPreference = 'Stop'

#importing students
#$csv = Import-csv -Path 'C:\Users\administrator\Documents\Cyberlab-Vsphere-master\2022\ncyte\teams.csv'

$studentprofile = @()
$i=0
foreach($stu in $csv){
    $studentprofile += [PSCustomObject]@{
        'Name' = ($stu).Student
        'ID' = ($stu).ID.Substring(0,9)
    }
    $i++
}

#folder name to create
$masterdeploymentname="Ncyte Dogpark"

#VMs to clone, TEMPLATES
$srcvms = get-vm -location "Dogpark Blue Team" | where {$_.Name -eq "Windows 10"}

#resources
$datastore = Get-Datastore Temp-ITS-DS
$vmhost = get-vmhost host17.cyberlab.csusb.edu

#Portgroup to clone
#$changeadapter=$false
#portgroup name, if there are multiple specify with commands but NO SPACES.  ex: bruh,bruh2,bruh3

#to dO GENERATE ID UP HERE AND THEN ADD IT TO PROFILE
<#
$portgroup = "Quiz3"
$portgroups = @()
if($portgroup -Match ",") {
    $splitwithcommas = $portgroup.Split(",")
    foreach ($p in $splitwithcommas) {
        $portgroupsrc = Get-VDPortgroup -Name $p
        $portgroupsrcname = (Get-VDPortgroup -Name $p).Name
        $portgroups += [PSCustomObject]@{
            'Name' = $portgroupsrcname
            'Reference' = $portgroupsrc
        }
    }
} else {
    $portgroupsrc = Get-VDPortgroup -Name $portgroup
    $portgroupsrcname = (Get-VDPortgroup -Name $portgroup).Name
    $portgroups += [PSCustomObject]@{
        'Name' = $portgroupsrcname
        'Reference' = $portgroupsrc
    }
}
#>

#Student role for permissions
$studentrole = Get-VIRole -name Student
$prod = Get-Folder -Server $serv -Name 03-Production

$masterdeploymentfolder=Get-Folder -Server $serv -Name $masterdeploymentname -Location 03-Production
#$masterdeploymentfolder = New-Folder -Name $masterdeploymentname -Location $prod

function get-thebestdatastore() {

}

<#
function generatenewvlanID() {
    $ran = Get-Random -Maximum 3500
    $vlan = (Get-VDPortGroup -VDSwitch "Pods").VlanConfiguration
    if($vlan | where {$_.VlanID -eq $ran}) {
        return $NULL
    } else {
        return $ran
    }
}

function fetchid() {
    while (1) {
        $id=generatenewvlanID
        if ($id -eq $NULL){
            generatenewvlanID
        } else {
            return $id
            break
        }
    }
}
#>
for (($i=1); $i -lt 7; $i++) {
    $createdfolder = Get-Folder -Name "Team $i" -Location $masterdeploymentfolder
    #clone new vms
    Foreach ($srcvm in $srcvms) {
        #name, VM, cluster host, datastore, datastore format, location, async
        new-vm -name ($srcvm).Name -vm $srcvm -vmhost $vmhost -datastore $datastore -DiskStorageFormat Thin -Location $createdfolder -RunAsync 
    }
    #assign network adapter on new vms
    <#
    $studentadaptername=($u).Name
    foreach ($pg in $portgroups) {
        $portgroupsrcname = ($pg).Name
        $portgroupsrc = ($pg).Reference
        $id = fetchid
        $createdportgroup = Get-VDSwitch -Name "Pods" | New-VDPortgroup -Name "$portgroupsrcname-$studentadaptername" -ReferencePortgroup $portgroupsrc     
        $createdportgroup | set-VDPortgroup -VlanID $id   
    }
    #>
    <#
    $newvms = get-vm -location $createdfolder
    Foreach ($newvm in $newvms) {
        #$newvm | get-networkadapter | where {$_.NetworkName -eq $portgroup} | Set-NetworkAdapter -NetworkName $createdportgroup -confirm:$false
        $permid = ($u).ID
        if(($newvm).Name -eq "Kali") {
            New-VIPermission -Role $studentrole -Principal "CSUSB\$permid" -Entity $newfolder
        }
    }
    #>
    #New-VIPermission -Role $studentrole -Principal "CSUSB\$permid" -Entity $newfolder -Propagate $true
}
