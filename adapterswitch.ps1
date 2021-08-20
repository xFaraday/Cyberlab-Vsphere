#switch adapter by groups of hosts P O W E R CLI

#display teams
if (Get-InstalledModule -Name VMware.PowerCLI) {
    Write-Output "PowerCLI already installed"
} else {
    Write-Output "Installing PowerCLI..."
    Install-Module -Name VMware.PowerCLI
}
$serv = Connect-VIServer -Server <REDACTED>
$masterdeploymentfolder= Read-Host "Master deployment folder?"
$orig= Read-Host "Origination adapter name?"
$mdf=Get-Folder -Server $serv -Name $masterdeploymentfolder -Location "03-Production"
$foldcontents=Get-Folder -Server $serv -Location $mdf

#1..7 | % {echo "Team $_" (Get-Folder -Server $serv -Name "Team $_" -Location "Dogpark Red Team" |  Get-Folder).Name}
#$teamswitch=Read-Host "Which Red Team do you want to select? Ex: Team 1"

#$blueteam=Read-Host "
#Team 1
#Team 1-2
#Team 2
#Team 2-2
#Team 3
#Team 3-2
#Team 6
#Team 6-2
#Which blueteam do you want to switch to? Ex: Team 1
#"

#$adapter=Read-Host "
#Lan
#IntToPF
#SubScreen
#DMZ
#Which network do you want to change to? Ex: Lan
#"

foreach ($person in $foldcontents) {
#network adapter format
#$masterdeploymentfolder - Name - classVMandlab - (Pods)
#ex: 6720-Final-Michalak-David-Ethan-511-Final-Template (Pods)
    $portgroup="$masterdeploymentfolder-$person-$orig (Pods)"

    $vmfolder=Get-Folder -Server $Serv -Name $person -Location $mdf
    $vms=Get-VM -Location $vmfolder 
    #$port=Get-VDSwitch -Name "Pods" | Get-VDPortgroup -Name $portgroup.replace(' ', '')
    $port=Get-VDSwitch -Name "Pods" | Get-VDPortgroup -Name $portgroup


    foreach ($vm in $vms) {
        if (($vm).Name -ne "Router") {
        $vm | get-networkadapter | set-networkadapter -NetworkName $port -confirm:$false
        if (($vm).PowerState -eq "PoweredOn") {
            Restart-VM -VM $vm -Confirm:$false 
        }
        }
        else {
            $vm | get-networkadapter | where {$_.NetworkName -ne 'DH-NAT-USERS'} | set-networkadapter -NetworkName $port -confirm:$false
            if (($vm).PowerState -eq "PoweredOn") {
                Restart-VM -VM $vm -Confirm:$false 
            }
        }
    }
}
