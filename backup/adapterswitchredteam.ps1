#switch adapter by groups of hosts P O W E R CLI
$ErrorActionPreference = 'Stop'
#display teams
if (Get-InstalledModule -Name VMware.PowerCLI) {
    Write-Output "PowerCLI already installed"
} else {
    Write-Output "Installing PowerCLI..."
    Install-Module -Name VMware.PowerCLI
}

$credentials = Get-VICredentialStoreItem -Host cyberlab.csusb.edu -File C:\Users\Administrator\Documents\Cyberlab-vsphere-master\creds.xml
$serv = Connect-VIServer cyberlab.csusb.edu -User $credentials.User -Password $credentials.Password

#importing students
$csv = Import-csv -Path 'C:\Users\administrator\Documents\Cyberlab-Vsphere-master\2022\redteamdogpark.csv'

$studentprofile = @()
$i=0
foreach($stu in $csv){
    $studentprofile += [PSCustomObject]@{
        'Name' = ($stu).Student
        'ID' = ($stu).ID.Substring(0,9)
    }
    $i++
}

#$orig= Read-Host "Origination adapter name?"
$mdf=Get-Folder -Server $serv -Name "Kali Slaves" -Location "03-Production"

<#
foreach ($f in $folds) {
    $team=($f).Name
    $teamnum=[regex]::Matches($team, "\d+(?!.*\d+)").value
    $vms=get-vm -Location $f
    foreach($vm in $vms) {
        Write-Output "PenTest Dogpark-DMZ-Team $teamnum"
        $vm | get-networkadapter | where {$_.NetworkName -ne 'DH-NAT-USERS'} | set-networkadapter -NetworkName "PenTest Dogpark-DMZ-Team $teamnum" -confirm:$false
        if (($vm).PowerState -eq "PoweredOn") {
            Restart-VM -VM $vm -Confirm:$false
        }
    }
}
#>


$vms = get-vm -Location $mdf
foreach($vm in $vms) {
    $team=($vm).Name
    $teamnum=[regex]::Matches($team, "\d+(?!.*\d+)").value
    Write-Output "PenTest Dogpark-DMZ-Team $teamnum"
    $vm | get-networkadapter | where {$_.Name -eq 'Network adapter 2'} | set-networkadapter -NetworkName "PenTest Dogpark-lan-Team $teamnum" -confirm:$false
    if (($vm).PowerState -eq "PoweredOn") {
        Restart-VM -VM $vm -Confirm:$false
    }
}
<#
$folds=Get-Folder -Server $serv -Location $mdf -NoRecursion

foreach ($f in $folds) {
    $team=($f).Name
    $teamnum=[regex]::Matches($team, "\d+(?!.*\d+)").value
    $vms=get-vm -Location $f
    foreach($vm in $vms) {
        Write-Output "$teamnum"
        #if (($vm).PowerState -eq "PoweredOn") {
        #    Stop-VM -VM $vm -Confirm:$false
        #}
        $vm | get-networkadapter | where {$_.NetworkName -ne 'DH-NAT-USERS'} | set-networkadapter -NetworkName "PenTest Dogpark-lan-Team $teamnum" -confirm:$false
        if (($vm).PowerState -eq "PoweredOn") {
            Restart-VM -VM $vm -Confirm:$false
        }
    }
}

#>

#$foldcontents=Get-Folder -Server $serv -Location $mdf
<#
foreach ($person in $studentprofile) {
    $vmfolder=Get-Folder -Server $Serv -Name ($person).Name -Location $mdf
    $vms=Get-VM -Location $vmfolder 
    $stud = ($person).Name
    foreach ($vm in $vms) {
        $vm | get-networkadapter | where {$_.NetworkName -ne 'DH-NAT-USERS'} | set-networkadapter -NetworkName "meta3" -confirm:$false
        if (($vm).PowerState -eq "PoweredOn") {
            Restart-VM -VM $vm -Confirm:$false 
        }
    }
}
#>

#$vm | get-networkadapter | where {$_.NetworkName -eq "PenTest Dogpark-SubScreen"} | set-networkadapter -NetworkName "PenTest Dogpark-lan-$fold" -confirm:$false

