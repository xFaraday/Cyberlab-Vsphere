#perm ps1
# P O W E R C L I 

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

$masterdeploymentfolder = Get-Folder -Name "RedTeam"

$studentrole = Get-VIRole -name Student

foreach ($student in $studentprofile) {
    $stuname = ($student).Name 
    $stuid = ($student).ID
    $subfold = Get-Folder -Name $stuname -Location $masterdeploymentfolder
    $vms = Get-VM -Location $subfold
    foreach ($vm in $vms) {
        $perms = get-vm -name ($vm).Name | Get-VIPermission
        $builtprincipal = "CSUSB\$stuid"
        if (($perms).Principal -notcontains $builtprincipal) {
            New-VIPermission -Role $studentrole -Principal $builtprincipal -Entity $vm 
        }
    }
}

