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
$mdf=Get-Folder -Server $serv -Name "4910 Dogpark" -Location "03-Production"
#$foldcontents=Get-Folder -Server $serv -Location $mdf
<#
foreach ($person in $studentprofile) {
    $vmfolder=Get-Folder -Server $Serv -Name ($person).Name -Location $mdf
    $vms=Get-VM -Location $vmfolder 
    
    

    $stud = ($person).Name
    foreach ($vm in $vms) {
       
        

        $vm | get-networkadapter | where {$_.NetworkName -ne 'DH-NAT-USERS'} | set-networkadapter -NetworkName "PenTest Dogpark-SubScreen-$stud" -confirm:$false

        if (($vm).PowerState -eq "PoweredOn") {
            Restart-VM -VM $vm -Confirm:$false 
        }
    }
}
#>
#$vm | get-networkadapter | where {$_.NetworkName -eq "PenTest Dogpark-SubScreen"} | set-networkadapter -NetworkName "PenTest Dogpark-lan-$fold" -confirm:$false

$vmfolder=Get-Folder -Server $Serv -Location $mdf
foreach ($fold in $vmfolder) {
    $vms = Get-VM -Location $fold
    foreach($vm in $vms) {
        if (($vm).Name -eq "Dogpark CentOS Database") {
            $vm | get-networkadapter | set-networkadapter -NetworkName "PenTest Dogpark-SubScreen-$fold" -confirm:$false
            if (($vm).PowerState -eq "PoweredOn") {
                Restart-VM -VM $vm -Confirm:$false
            }
        }
        if (($vm).Name -eq "Dogpark Kali") {
            $vm | get-networkadapter | set-networkadapter -NetworkName "PenTest Dogpark-DMZ-$fold" -confirm:$false
            if (($vm).PowerState -eq "PoweredOn") {
                Restart-VM -VM $vm -Confirm:$false
            }
        }
        if (($vm).Name -eq "Dogpark PFSense Firewall") {
            $vm | get-networkadapter | where {$_.Name -eq "Network adapter 1"} | set-networkadapter -NetworkName "PenTest Dogpark-DMZ-$fold" -confirm:$false
            $vm | get-networkadapter | where {$_.Name -eq "Network adapter 2"} | set-networkadapter -NetworkName "PenTest Dogpark-SubScreen-$fold" -confirm:$false
            $vm | get-networkadapter | where {$_.Name -eq "Network adapter 3"} | set-networkadapter -NetworkName "PenTest Dogpark-IntToPF-$fold" -confirm:$false
            if (($vm).PowerState -eq "PoweredOn") {
                Restart-VM -VM $vm -Confirm:$false
            }
        }
        if (($vm).Name -eq "Dogpark Ubuntu Client") {
            $vm | get-networkadapter | set-networkadapter -NetworkName "PenTest Dogpark-lan-$fold" -confirm:$false
            if (($vm).PowerState -eq "PoweredOn") {
                Restart-VM -VM $vm -Confirm:$false
            }
        }
        if (($vm).Name -eq "Dogpark Vyatta Router LAN") {
            $vm | get-networkadapter | where {$_.Name -eq "Network adapter 1"} | set-networkadapter -NetworkName "PenTest Dogpark-IntToPF-$fold" -confirm:$false
            $vm | get-networkadapter | where {$_.Name -eq "Network adapter 2"} | set-networkadapter -NetworkName "PenTest Dogpark-lan-$fold" -confirm:$false
            if (($vm).PowerState -eq "PoweredOn") {
                Restart-VM -VM $vm -Confirm:$false
            }
        }
        if (($vm).Name -eq "Dogpark Vyatta Router WAN") {
            $vm | get-networkadapter | where {$_.Name -eq "Network adapter 2"} | set-networkadapter -NetworkName "PenTest Dogpark-DMZ-$fold" -confirm:$false
            if (($vm).PowerState -eq "PoweredOn") {
                Restart-VM -VM $vm -Confirm:$false
            }
        }
        if (($vm).Name -eq "Dogpark Windows 7") {
            $vm | get-networkadapter | set-networkadapter -NetworkName "PenTest Dogpark-lan-$fold" -confirm:$false
            if (($vm).PowerState -eq "PoweredOn") {
                Restart-VM -VM $vm -Confirm:$false
            }
        }
        if (($vm).Name -eq "Dogpark Windows AD-DNS") {
            $vm | get-networkadapter | set-networkadapter -NetworkName "PenTest Dogpark-lan-$fold" -confirm:$false
            if (($vm).PowerState -eq "PoweredOn") {
                Restart-VM -VM $vm -Confirm:$false
            }
        }
        if (($vm).Name -eq "Dogpark Windows WebServer") {
            $vm | get-networkadapter | set-networkadapter -NetworkName "PenTest Dogpark-SubScreen-$fold" -confirm:$false
            if (($vm).PowerState -eq "PoweredOn") {
            Restart-VM -VM $vm -Confirm:$false
            }
        }
    }
}
    