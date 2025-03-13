$resourceGroupName = "rg-demo-snapshot-314156"
$location = "eastus2"
$vmName = 'myVM'
$snapshotOSName = 'mySnapshot-OSData’
$snapshotDataName = 'mySnapshot-Data’

$vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName
$vm.StorageProfile

$snapshotOS =  New-AzSnapshotConfig -SourceUri $vm.StorageProfile.OsDisk.ManagedDisk.Id -Location $location -CreateOption copy
New-AzSnapshot -Snapshot $snapshotOS -SnapshotName $snapshotOSName -ResourceGroupName $resourceGroupName

$snapshotData =  New-AzSnapshotConfig -SourceUri $vm.StorageProfile.DataDisks.ManagedDisk.Id -Location $location -CreateOption copy
New-AzSnapshot -Snapshot $snapshotData -SnapshotName $snapshotDataName -ResourceGroupName $resourceGroupName



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