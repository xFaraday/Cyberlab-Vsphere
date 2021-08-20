#Deploy script P O W E R CLI
#inputs:
#user array, deployment name, VMs that are not supposed to be shown, cluster host, datastore

$serv = Connect-VIServer -Server <REDACTED>

#for loop
#create folder under master production->mastergroupfoldername with name of user
#clone portgroup with name of user appened to it
#clone VMs to that folder
#get user info
#Add user permissions as students
#Add instructor permissions to that folder
$users=get-content secondround.txt

$masterdeploymentname="GenCyber"
#VMs to clone
$srcvms = get-vm -location GenCyber
$datastore = Get-Datastore RS2-ISO-DS

$vmhost = get-vmhost <REDACTED>
#Portgroup to clone
$portgroup = "GenCyber"
$portgroupsrc = Get-VDPortgroup -Name $portgroup
$portgroupsrcname = (Get-VDPortgroup -Name $portgroup).Name
#Student role for permissions
$studentrole = Get-VIRole -name Student
$prod = Get-Folder -Server $serv -Name 03-Production
$masterdeploymentfolder=Get-Folder -Server $serv -Name GenCyber -Location 03-Production
#$masterdeploymentfolder = New-Folder -Name $masterdeploymentname -Location $prod

foreach ($u in $users) {
    $createdfolder = New-Folder -Name $u -Location $masterdeploymentfolder
    $createdportgroup = Get-VDSwitch -Name "Pods" | New-VDPortgroup -Name "$portgroupsrcname $u" -ReferencePortgroup $portgroupsrc
    
    $vmuser = Get-VIAccount -Domain cyberlab.csusb.edu | where {$_.Name -eq "CYBERLAB.CSUSB.EDU\$u"}
    Foreach ($srcvm in $srcvms) {
        #name, VM, cluster host, datastore, datastore format, location, async
        new-vm -name ($srcvm).Name -vm $srcvm -vmhost $vmhost -datastore $datastore -DiskStorageFormat Thin -Location $createdfolder
    }
    $newvms = get-vm -location $createdfolder
    Foreach ($newvm in $newvms){
        $newvm | get-networkadapter | where {$_.NetworkName -eq "GenCyber"} | Set-NetworkAdapter -NetworkName $createdportgroup -confirm:$false
    }

    $Kali=Get-vm -location $createdfolder | where {$_.Name -eq "Kali 2.0"}
    New-VIPermission -Role $studentrole -Principal "CYBERLAB.CSUSB.EDU\$u" -Entity $Kali
}
