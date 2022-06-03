function Invoke-Pipeline {
    <#
    .SYNOPSIS
    
    This script is the start of the deployment pipeline.
    
    .PARAMETER UserFile
    
    a CSV file specifiying the user's names in the first column and their account identifier
    Ex:
    John Smith, jsmith033
    
    .PARAMETER VMTemplates
    w
    Folder name containing VMs to clone for deployment.
    
    .PARAMETER Hidden
    
    Specifies any virtual machines in the set that should be hidden from the user.
    
    .PARAMETER PortGroup
    
    Specifies Portgroup to base the creation of the VM's sub portgroups on.
    
    .PARAMETER autoloadbalance
    
    Will engage load balancing mechanism and split the load between the cluster and avaliable datastores.
    
    #>
    
    [CmdletBinding()] Param(
        [Parameter(Mandatory=$true)]
        [string]$UserFile,
        [Parameter(Mandatory=$true)]
        [string]$VMTemplates,
        [Parameter(Mandatory=$true, default="All")]
        [string]$Visible,
        [Parameter(Mandatory=$true)]
        [string]$PortGroup
    )
        if (Test-Path $creds) {
            continue
        } else {
            Write-Error "No credential file found.  Please store credentials in a file with the following
            New-VICredentialStoreItem -Host vcsa.vmmaster.local -User 'user@vsphere' -Password 'pass' -File D:\pwd.xml"
            Exit 2
        }
    
        $credentials = Get-VICredentialStoreItem -Host cyberlab.csusb.edu -File C:\Users\Administrator\Documents\Cyberlab-vsphere-master\creds.xml
        $serv = Connect-VIServer cyberlab.csusb.edu -User $credentials.User -Password $credentials.Password
    
        $vmprofile = @()
        $srcvms = get-vm -location $VMTemplates 
        foreach ($vm in $srcvms) {
            $vmprofile += [PSCustomObject]@{
                'Name' = ($vm).Name
                'MemoryGB' = ($vm).MemoryGB
                'UsedSpaceGB' = ($vm).UsedSpaceGB
                'MaxMhz' = ($vm | Select-Object -Property @{Name='MaxHostCpuMhz';Expression={$_.NumCpu * $_.VMHost.CpuTotalMhz / $_.VMHost.NumCpu}}).MaxHostCpuMhz 
            }
        }
        
        #check if the user file exists
        if (Test-Path $UserFile) {
            continue
        } else {
            Exit 2
            Write-Error "User file does not exist"
        }
        #creating student profile and count of students
        $csv = Import-csv -Path $UserFile
        if ($csv.Count -eq 0) {
            Write-Error "User file is empty"
            Exit 2
        } Elseif ($null -eq $csv[0].Student -or $null -eq $csv[0].ID) {
            Write-Error "Invalid format for student csv file.  Needs to be 'Student, ID'"
            Exit 2
        }
        $studentprofile = @()
        $studentcount=0
        foreach($stu in $csv){
            $studentprofile += [PSCustomObject]@{
                'Name' = ($stu).Student
                'ID' = ($stu).ID.Substring(0,9)
            }
            $studentcount++
        }
        
        #check if vm adapter exists in pods
        if(Get-VDPortGroup -Name $PortGroup -VDSwitch "Pods") {
            continue
        } else {
            Write-Error "Portgroup does not exist"
            Exit 2
        }

        Invoke-LoadBalance -VMProfile $vmprofile -StudentProfile $studentprofile -StudentCount $studentcount -Visible $Visible -PortGroup $PortGroup
}