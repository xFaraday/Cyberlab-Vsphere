#perm ps1
# P O W E R C L I 

$credentials = Get-VICredentialStoreItem -Host cyberlab.csusb.edu -File C:\Users\Administrator\Documents\Cyberlab-vsphere-master\creds.xml
$serv = Connect-VIServer cyberlab.csusb.edu -User $credentials.User -Password $credentials.Password
$ErrorActionPreference = 'Stop'

#importing students
$csv = Import-csv -Path 'C:\Users\administrator\Documents\Cyberlab-Vsphere-master\2022\ncyte\teams.csv'

$studentprofile = @()
$i=0
foreach($stu in $csv){
    $studentprofile += [PSCustomObject]@{
        'Name' = ($stu).Student
        'ID' = ($stu).ID.Substring(0,9)
        'teamnum'= ($stu).team
    }
    $i++
}

$masterdeploymentfolder = Get-Folder -Name "Ncyte Dogpark"

$studentrole = Get-VIRole -name Student

foreach ($student in $studentprofile) {
    $stuid = ($student).ID
    $stuteam = ($student).teamnum
    $subfolds = Get-Folder -Location $masterdeploymentfolder
    foreach ($f in $subfolds) {
        $team=($f).Name
        $teamnum=[regex]::Matches($team, "\d+(?!.*\d+)").value
        if($teamnum -eq $stuteam) {
            $builtprincipal = "CSUSB\$stuid"
            New-VIPermission -Role $studentrole -Principal $builtprincipal -Entity $f -Propagate $true
        }
    }
}

