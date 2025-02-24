$resourceGroupName = 'rgdemo314156' 
$location = 'us-east-2'
$vmName = 'vmdemo314156'
$snapshotName = 'mySnapshot-1'
$vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName
$vm.StorageProfile
$snapshot =  New-AzSnapshotConfig -SourceUri $vm.StorageProfile.OsDisk.ManagedDisk.Id -Location $location -CreateOption copy
New-AzSnapshot -Snapshot $snapshot -SnapshotName $snapshotName -ResourceGroupName $resourceGroupName
$location = 'East US 2'

New-AzSnapshot -Snapshot $snapshot -SnapshotName $snapshotName -ResourceGroupName $resourceGroupName
$vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName

$snapshotName = 'mySnapshot-1’
$snapshot =  New-AzSnapshotConfig -SourceUri $vm.StorageProfile.OsDisk.ManagedDisk.Id -Location $location -CreateOption copy
New-AzSnapshot -Snapshot $snapshot -SnapshotName $snapshotName -ResourceGroupName $resourceGroupName

$snapshotName = 'mySnapshotData-1’
$snapshot =  New-AzSnapshotConfig -SourceUri $vm.StorageProfile.DataDisks.ManagedDisk.Id -Location $location -CreateOption copy
New-AzSnapshot -Snapshot $snapshot -SnapshotName $snapshotName -ResourceGroupName $resourceGroupName