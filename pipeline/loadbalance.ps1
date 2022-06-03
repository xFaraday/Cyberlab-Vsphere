function Invoke-Pipeline {
    <#
    .SYNOPSIS
    
    This script determines allocation of resources, where to efficiently place VMs in adaptive fashion based on current resource usage.
    
    #>
    
    [CmdletBinding()] Param(
        [Parameter(Mandatory=$true)]
        [string]$Studentprofile,
        [Parameter(Mandatory=$true)]
        [string]$vmprofile,
        [Parameter(Mandatory=$true, default="All")]
        [string]$Visible,
        [Parameter(Mandatory=$true)]
        [string]$PortGroup
    )

    <#
        Rule Variable block, includes regex for certain hosts or datastores.

    #>

    #host with key server
    [regex]$forensicshost='host16.cyberlab.csusb.edu'

    #datastore avaliable for hosting on production
    [regex]$DatastoreWhitelist = 'RS1-Prod2-DS | RS2-Prod3-DS | DH1-Local | Temp-ITS-DS | RS2-ISO-DS'


    <#
        End of variable block.
    #>


    #host information
    $cluster = Get-Cluster
    $hostsincluster = get-vmhost -Location $cluster
    $hostinfo = @()
    $i=1
    foreach ($hosts in $hostsincluster) {
        Write-Progress -Activity "host info" -Status "Filling New Object hostinfo" -PercentComplete (($i / $hostsincluster.Count) * 100)
        $hostinfo += [PSCustomObject]@{
            'Name' = ($hosts).Name
            'CpuFreeMhz' = ($hosts).CpuTotalMhz-($hosts).CpuUsageMhz
            'MemFreeGB' = ($hosts).MemoryTotalGB-($hosts).MemoryUsageGB
        }
    $i++    
    }

    #datastore information
    $stores = @()
    $datastores = Get-Datastore
    $i=1
    foreach($store in $datastores){
        Write-Progress -Activity "datastore" -Status "Filling New Object datastore" -PercentComplete (($i     / $datastores.Count) * 100)
        $stores += [PSCustomObject]@{
            'Name' = ($store).Name 
            'SpaceFreeGB' = ($store).FreeSpaceGB
        }
        $i++
    }

    $storehigh = ($stores | measure-object -Property SpaceFreeGB -maximum).Maximum
    $selectedstore = $stores | where {$_.SpaceFreeGB -eq $storehigh} 

    $hostmemhigh = ($hostinfo | measure-object -Property MemFreeGB -maximum).Maximum
    $selectedhost = $hostinfo | where {$_.MemFreeGB -eq $hostmemhigh}


    $deployobj = @()   


    foreach($stu in $Studentprofile) {

        foreach($vm in $vmprofile) {
            $primer=($vm).UsedSpaceGB
            $storehigh = ($stores | measure-object -Property SpaceFreeGB -maximum).Maximum
            $selectedstore = $stores | where {$_.SpaceFreeGB -eq $storehigh} 
            $new = $storehigh - $primer
            $deployobj | add-member -NotePropertyName ($vm).Name -NotePropertyValue $selectedstore.Name
        }

    $deployobj += [PSCustomObject]@{
        'Student' = ($stu).Student
        'ID' = ($stu).ID
        'host' = $selectedhost[0].Name

    }
    #invoke deployment for each student with their own object
    Invoke-Deployment -package $deployobj
}