function Invoke-Deployment {

#Deploy script P O W E R CLI
#inputs:
#user array, deployment name, VMs that are not supposed to be shown, cluster host, datastore
$credentials = Get-VICredentialStoreItem -Host cyberlab.csusb.edu -File C:\Users\Administrator\Documents\Cyberlab-vsphere-master\creds.xml
$serv = Connect-VIServer cyberlab.csusb.edu -User $credentials.User -Password $credentials.Password

#importing students
$csv = Import-csv -Path 'C:\Users\administrator\Documents\Cyberlab-Vsphere-master\2022\IST-4620-60.csv'

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
$masterdeploymentname= "4620-60 Labman"

#VMs to clone, TEMPLATES
$srcvms = get-vm -location "10-Labman"

#resources
$datastore = Get-Datastore RS2-Prod3-DS
$vmhost = get-vmhost host17.cyberlab.csusb.edu

#Portgroup to clone
$changeadapter=$false
$portgroup = "LabMan-Templates"
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

foreach ($u in $studentprofile) {
    $createdfolder = New-Folder -Name ($u).Name -Location $masterdeploymentfolder
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
    $studentadaptername=($u).Name
    $createdportgroup = Get-VDSwitch -Name "Pods" | New-VDPortgroup -Name "$portgroupsrcname-$studentadaptername" -ReferencePortgroup $portgroupsrc     
    $createdportgroup | set-VDPortgroup -VlanID $id   
    
    $newvms = get-vm -location $createdfolder
    Foreach ($newvm in $newvms){
        $newvm | get-networkadapter | where {$_.NetworkName -eq $portgroup} | Set-NetworkAdapter -NetworkName $createdportgroup -confirm:$false
        $permid = ($u).ID
        #if(($newvm).Name -eq "Forensics-VM") {
        New-VIPermission -Role $studentrole -Principal "CSUSB\$permid" -Entity $newvm
        #}
    }
}

}