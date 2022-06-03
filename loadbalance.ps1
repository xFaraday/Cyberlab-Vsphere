# P O W E R CLI Infrastructure Health Script

#$serv = Connect-VIServer -Server cyberlab.csusb.edu
$credentials = Get-VICredentialStoreItem -Host cyberlab.csusb.edu -File C:\Users\Administrator\Documents\Cyberlab-vsphere-master\creds.xml
$serv = Connect-VIServer cyberlab.csusb.edu -User $credentials.User -Password $credentials.Password

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
[regex]$DatastoreWhitelist = 'RS1-Prod2-DS | RS2-Prod3-DS | DH1-Local | DH2-Local | DH3-Local'
#for forensics
[regex]$DeploymentSpecificHostForensics = 'host16.cyberlab.csusb.edu'

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

#$dir = get-childitem | ? {$_.Name -eq "cyberlabinventory"}

###More for inventory

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

#get-vm -Location 'Michalak-Ethan' | format-list *
