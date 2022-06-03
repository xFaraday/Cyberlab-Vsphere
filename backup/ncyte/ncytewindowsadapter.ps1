#switch adapter by groups of hosts P O W E R CLI

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

#$orig= Read-Host "Origination adapter name?"
$mdf=Get-Folder -Server $serv -Name "Ncyte Dogpark" -Location "03-Production"
#$foldcontents=Get-Folder -Server $serv -Location $mdf

#$vm | get-networkadapter | where {$_.NetworkName -eq "PenTest Dogpark-SubScreen"} | set-networkadapter -NetworkName "PenTest Dogpark-lan-$fold" -confirm:$false

$vmfolder=Get-Folder -Server $Serv -Location $mdf
foreach ($fold in $vmfolder) {
    $vms = Get-VM -Location $fold
    $team=($fold).Name
    $teamnum=[regex]::Matches($team, "\d+(?!.*\d+)").value
    foreach($vm in $vms) {
        if (($vm).Name -eq "Windows 10") {
            $vm | get-networkadapter | where {$_.Name -eq "Network adapter 1"} | set-networkadapter -NetworkName "NCYTE team $teamnum Lan" -confirm:$false
            if (($vm).PowerState -eq "PoweredOn") {
                Restart-VM -VM $vm -Confirm:$false
            }
        }
    }
}
    