function Invoke-Deployment {
<#
.SYNOPSIS

This script will deploy a new set of the specified VM's according to specification
#>

[CmdletBinding()] Param(
    [Parameter(Mandatory=$true)]
    [string]$UserFile
)

    $credentials = Get-VICredentialStoreItem -Host cyberlab.csusb.edu -File C:\Users\Administrator\Documents\Cyberlab-vsphere-master\creds.xml
    $serv = Connect-VIServer cyberlab.csusb.edu -User $credentials.User -Password $credentials.Password

    $srcvms = get-vm -location $VMTemplates 

    $csv = Import-csv -Path $UserFile

    #Portgroup to clone
    $portgroupsrc = Get-VDPortgroup -Name $PortGroup
    $portgroupsrcname = (Get-VDPortgroup -Name $PortGroup).Name

    $studentprofile = @()
    $i=0
    foreach($stu in $csv){
        $studentprofile += [PSCustomObject]@{
            'Name' = ($stu).Student
            'ID' = ($stu).ID.Substring(0,9)
        }
        $i++
    }

    function get-deploymentname {
        $section=$UserFile.split("\")[-1].split("-", 2)[-1].split(".")[0]
        $masterdeploymentname = $section + "-" + $VMTemplates
        return $masterdeploymentname
    }

    #TO BE HANDLED BY LOAD BALANCING MECHANISM
    $datastore = Get-Datastore RS2-Prod3-DS
    $vmhost = get-vmhost host17.cyberlab.csusb.edu


    #Student role for permissions
    $studentrole = Get-VIRole -name Student
    $prod = Get-Folder -Server $serv -Name 03-Production

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

        if ($PortGroup) {
            #generate new vlan ID for the new portgroup to be created
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
            }
        } else {
            $newvms = get-vm -location $createdfolder
            Foreach ($newvm in $newvms){
                $permid = ($u).ID


                #if(($newvm).Name -eq "Forensics-VM") {
                New-VIPermission -Role $studentrole -Principal "CSUSB\$permid" -Entity $newvm
                #}
            }
        }
    }
}