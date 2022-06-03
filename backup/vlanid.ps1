$serv = Connect-VIServer -Server cyberlab.csusb.edu

function generatenewvlanID() {
    $ran = Get-Random -Maximum 3500
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
        write-warning $id
        break
    }
}

$portgroup = "Quiz3"
$portgroupsrc = Get-VDPortgroup -Name $portgroup
$portgroupsrcname = (Get-VDPortgroup -Name $portgroup).Name

$createdportgroup = Get-VDSwitch -Name "Pods" | New-VDPortgroup -Name "$portgroupsrcname-test" -ReferencePortgroup $portgroupsrc     
$createdportgroup | set-VDPortgroup -VlanID $id