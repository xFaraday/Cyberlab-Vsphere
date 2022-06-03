$credentials = Get-VICredentialStoreItem -Host cyberlab.csusb.edu -File C:\Users\Administrator\Documents\Cyberlab-vsphere-master\creds.xml
$serv = Connect-VIServer cyberlab.csusb.edu -User $credentials.User -Password $credentials.Password

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

$studentprofile

$portgroup = "511-Final-Template"
$bruhgroups = @()
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
    $bruhgroups += [PSCustomObject]@{
        'Name' = $portgroupsrcname
        'Reference' = $portgroupsrc
    }
}

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


foreach ($u in $studentprofile) {
    #assign network adapter on new vms
    $studentadaptername=($u).Name
    #$bruhgroups
    
    foreach ($bruh in $bruhgroups){
        $portgroupsrcname = ($bruh).Name 
        $portgroupsrc = ($bruh).Reference
        $id = fetchid
        $createdportgroup = Get-VDSwitch -Name "Pods" | New-VDPortgroup -Name "$portgroupsrcname-$studentadaptername" -ReferencePortgroup $portgroupsrc     
        $createdportgroup | set-VDPortgroup -VlanID $id   
    }
    <#
    
    foreach ($cpg in $bruhgroups) {
        $portgroupsrcname = $(cpg).Name
        $portgroupsrc = $(cpg).Reference
        $id = fetchid
        $createdportgroup = Get-VDSwitch -Name "Pods" | New-VDPortgroup -Name "$portgroupsrcname-$studentadaptername" -ReferencePortgroup $portgroupsrc     
        $createdportgroup | set-VDPortgroup -VlanID $id   
    }
    #>
}