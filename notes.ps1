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



# Azure Bastion
$subnet = @{
    Name = $bastionSubnetName
    VirtualNetwork = $virtualNetwork
    AddressPrefix = '10.0.1.0/26'
}
$subnetConfig = Add-AzVirtualNetworkSubnetConfig @subnet

$virtualNetwork | Set-AzVirtualNetwork

$ip = @{
        ResourceGroupName = $resourceGroupName
        Name = $bastionIPName
        Location = $location
        AllocationMethod = 'Static'
        Sku = 'Standard'
        Zone = 1
}
New-AzPublicIpAddress @ip

$bastion = @{
    Name = $bastionHostName
    ResourceGroupName = $resourceGroupName
    PublicIpAddressRgName = $resourceGroupName
    PublicIpAddressName = $bastionIPName
    VirtualNetworkRgName = $resourceGroupName
    VirtualNetworkName = $vnetName 
    Sku = 'Basic'
}
New-AzBastion @bastion