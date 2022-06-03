# P O W E R CLI Infrastructure Health Script
$serv = Connect-VIServer -Server cyberlab.csusb.edu

<#
things to collect
datacenter information
- stats on hardware
|> cpu, ram, datastores

-vm information
|>list of current deployments
|>the deployment VMs, the resources being used, 
-
#>

#WHITELISTS FOR DEPLOYMENTS
[regex]$DatastoreWhitelist = 'RS1-Prod2-DS | RS2-Prod3-DS | Production'
[regex]$DatastoreBlacklist = 'ISOs | Templates | DH2-Local | DH3-Local | DH1-Local'

#for forensics
[regex]$DeploymentSpecificHost = 'host16.cyberlab.csusb.edu'

$date = Get-Date -Format yyyy-MM-dd
$time = get-date -Format HH:mm:ss
$datetime = $date + "|" + $time

$cluster = Get-Cluster
$hostsincluster = get-vmhost -Location $cluster
$hostinfo = @()
$i=1
foreach ($hosts in $hostsincluster) {
    Write-Progress -Activity "host info" -Status "Filling New Object hostinfo" -PercentComplete (($i / $hostsincluster.Count) * 100)
    $hostinfo += [PSCustomObject]@{
        'Name' = ($hosts).Name
        'CpuFreeMhz' = ($hosts).CpuTotalMhz-($hosts).CpuUsageMhz
        'CpuTotalMhz' = ($hosts).CpuTotalMhz
        'CpuUsageMhz' = ($hosts).CpuUsageMhz
        'MemFreeGB' = ($hosts).MemoryTotalGB-($hosts).MemoryUsageGB
        'MemTotalGB' = ($hosts).MemoryTotalGB
        'MemUsageGB' = ($hosts).MemoryUsageGB
    }
   $i++    
}
$hostinfo



$stores = @()
$datastores = Get-Datastore
$i=1
foreach($store in $datastores){
    Write-Progress -Activity "datastore" -Status "Filling New Object datastore" -PercentComplete (($i     / $datastores.Count) * 100)
    $stores += [PSCustomObject]@{
	   'Name' = ($store).Name 
	   'SpaceTotalGB' = ($store).CapacityGB
	   'SpaceFreeGB' = ($store).FreeSpaceGB
	   'SpaceUsedGB' = ($store).CapacityGB-($store).FreeSpaceGB
    }
    $i++
}
$stores



$folds= Get-Folder -norecursion -server $serv -Location "03-Production"
$foldobj = @()
$i=1
foreach($f in $folds) {
    $subfolds = Get-Folder -norecursion -server $serv -Location $f
    $num = $subfolds.count
    $foldobj += [PSCustomObject]@{
        'Basedir' = $f
        'IDBasedir' = ($f).Id 
        'Subdir' = $subfolds
        'Count' = $num
        'IDSubdir' = ($subfolds).Id
    }
    $vms=get-vm -Location $subfolds[0]
    $ramusage=0
    $cpuusage=0
    $storage=0
    if ($num -gt 0) {
        $vms | % {$ramusage=$_.MemoryGB+$ramusage}
        $vms | % {$cpuusage=$_.NumCpu+$cpuusage}
        $vms | % {$storage=$_.UsedSpaceGB+$storage}
    }
}
$foldobj


#loop through and send to move my shit
<#
foreach($f in $folds){
    $subfolds = Get-Folder -norecursion -server $serv -Location $f
    foreach($person in $subfolds){
        $vms=get-vm -Location $person | where {$_.FolderId -eq ($person).Id}
        $vms | % {$ramusage=$_.MemoryGB+$ramusage}
        $vms | % {$cpuusage=$_.NumCpu+$cpuusage}
        $vms | % {$storage=$_.UsedSpaceGB+$storage}
        Write-Warning "VM: ($vms).Name"
        Write-Warning "Ramusage: $ramusage"
        Write-Warning "Cpuusage: $cpuusage"
        Write-Warning "Storage: $storage"

        $ramusage=0
        $cpuusage=0
        $storage=0
    }
}
#>

function movemyshit() {
    #move vm command
    Get-VM -id $id | Move-VM -Destination $host -Datastore $store -DiskStorageFormat 'Thin' -RunAsync
}

function DetermineLeastUtilizedDatastore() {
    #figure out why my stupid lists arent working god damn you microsoft
    #$storageaval=$stores | where {$_.Name -eq 'Production' -or $_.Name -eq 'RS1-Prod2-DS' -or $_.Name -eq 'RS2-Prod3-DS'}
    #$storagechoice = $storagechoice | Measure 
    #$storagechoice
    #microsfot again making me sad bruh
    #$storageaval=get-datastore | where {$_.Name -eq 'Production' -or $_.Name -eq 'RS1-Prod2-DS' -or $_.Name -eq 'RS2-Prod3-DS'}
    #$storagechoice = ($storageaval).FreeSpaceGB | Measure -Maximum
    $datastorechoice=(get-datastore | where {$_.Name -eq 'Production' -or $_.Name -eq 'RS1-Prod2-DS' -or $_.Name -eq 'RS2-Prod3-DS'}).FreeSpaceGB | Measure -Maximum
    $storagechoice=($datastorechoice).Maximum
    $tmps = Get-Datastore | Where {$_.FreeSpaceGB -eq $storagechoice}
    Write-warning $tmps
    return $tmps
}

function DetermineLeastUtilizedHost() {
    #use typecase or use least used cuz it references back to get-host
    $Memchoice=($hostinfo).MemFreeGb | Measure -Maximum -Minimum -Average -StandardDeviation
    $hostchoice=($memchoice).Maximum
    $hostchoice
    $tmph = ($hostinfo | where {$_.MemFreeGb -eq $hostchoice}).Name
    $hostinfo | where {$_.MemFreeGb -eq $hostchoice}


    $cpuchoice=($hostinfo).CpuFreeMhz | Measure -Maximum -Minimum -Average -StandardDeviation
    #[int]$num= [convert]::ToInt32($numobj, 10)
    #$num
    #write-host $hostinfo[$num-1]
    Write-warning $tmph
    return $tmph
    #Write-Warning $storageaval[($storagechoice).Count]
    
}
DetermineLeastUtilizedHost
DetermineLeastUtilizedDatastore
#$dir = get-childitem | ? {$_.Name -eq "cyberlabinventory"}
<#
$folds= Get-Folder -norecursion -server $serv -Location "03-Production"
$foldobj = @()
$i=1
foreach($f in $folds) {
    Write-Progress -Activity "FoldObj" -Status "Filling New Object foldobj" -PercentComplete (($i         / $folds.Count) * 100)
    $subfolds = Get-Folder -norecursion -server $serv -Location $f
    $subfolds
    foreach ($vmfold in $subfolds) {
    	$vms=Get-VM -Location $vmfold
	$foldobj += [PSCustomObject]@{
		'FolderName(Individual)' = ($vmfold).Name
		'CpuUsage' = $vms | % {$_.NumCpu}
		'MemoryUsageGB' = $vms | % {$_.MemoryGB}
		'VMHost' = $vm
		'Datastore' = Get-Datastore -RelatedObject $vm
	}

    }

    #get-vm -Location $f
    $i++
}
#>

