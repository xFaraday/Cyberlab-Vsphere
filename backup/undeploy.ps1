# P O W E R C L I 
# mass undeploy vm script
#$serv = Connect-VIServer -Server cyberlab.csusb.edu
$credentials = Get-VICredentialStoreItem -Host cyberlab.csusb.edu -File C:\Users\Administrator\Documents\Cyberlab-vsphere-master\creds.xml
$serv = Connect-VIServer cyberlab.csusb.edu -User $credentials.User -Password $credentials.Password
$ErrorActionPreference = 'Stop'

#vm folder to destroy
$masterdeploymentname="prodquiz2"
$portgroup = "Quiz-2"
$portgroupsrcname = (Get-VDPortgroup -Name $portgroup).Name

$vms = get-vm -Location $masterdeploymentname

#importing students
$csv = Import-csv -Path 'C:\Users\administrator\Documents\Cyberlab-Vsphere-master\2022\IST-4620-61.csv'

$studentprofile = @()
$i=0
foreach($stu in $csv){
    $studentprofile += [PSCustomObject]@{
        'Name' = ($stu).Student
        'ID' = ($stu).ID.Substring(0,9)
    }
    $i++
}

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
$networklist=(Get-VM -Location $masterdeploymentname | get-networkadapter).NetworkName | select -Unique
foreach($u in $studentprofile) {
    $studentadaptername=($u).Name
    $createdportgroup = Get-VDSwitch -Name "Pods" | Get-VDPortgroup -Name "$portgroupsrcname-$studentadaptername"
    if($networklist -contains $createdportgroup) {
        $createdportgroup | Get-VDPortgroup | Remove-VDPortGroup -confirm:$false
    } 
}

Remove-Folder -Folder $masterdeploymentname -confirm:$false