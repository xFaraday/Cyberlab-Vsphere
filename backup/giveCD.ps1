#Deploy script P O W E R CLI
#inputs:
#user array, deployment name, VMs that are not supposed to be shown, cluster host, datastore
$credentials = Get-VICredentialStoreItem -Host cyberlab.csusb.edu -File C:\Users\Administrator\Documents\Cyberlab-vsphere-master\creds.xml
$serv = Connect-VIServer cyberlab.csusb.edu -User $credentials.User -Password $credentials.Password
$ErrorActionPreference = 'SilentlyContinue'

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
$masterdeploymentname="4620-60 Final"

#resources
$datastore = Get-Datastore RS2-ISO-DS
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

foreach($u in $studentprofile) {
    $name = ($u).Name
    $createdfolder = Get-Folder -Name "$name" -Location $masterdeploymentfolder

    $newvms = get-vm -location $createdfolder
    Foreach ($newvm in $newvms) {
        #$newvm | get-networkadapter | where {$_.NetworkName -eq $portgroup} | Set-NetworkAdapter -NetworkName $createdportgroup -confirm:$false
        $permid = ($u).ID
        if(($newvm).Name -eq "Win7") {
            if (($newvm).PowerState -eq "PoweredOn") {
                Stop-VM -VM $newvm -Confirm:$false
            }
            $prev = Get-CDDrive -VM $newvm 
            Remove-CDDrive -CD $prev -Confirm:$false
            New-CDDrive -VM $newvm -IsoPath "[RS2-ISO-DS] ITS_DS-ISOs-Backup/IST511/xboot.iso" -StartConnected:$true
        }
    }
}
