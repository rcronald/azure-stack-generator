# Global Variables
$resourceGroupName = "rg-customer-009"
$location = "eastus2"
$vnetName = "vnet-customer-eastus-009"
$vmSubnetName = "snet-customer-009"
$networkInterfaceName = "vm-customer-009-nic"
$virtualMachineName = "vm-customer-009"
#$virtualMachineFamily = "Standard_B2ls_v2"
$virtualMachineFamily = "Standard_DS1_v2"
$databaseServerName = "dertec-db-009-customer"
$databaseName = "George"
$privateEndpointName = "pep-customer-009"

# Snapshot Variables
$resourceGroupNameSnapshot = "rg-snapshots"
$snapshotOSName = "mySnapshot-OSData"
$osDiskName = "C"
$snapshotDataName = "mySnapshot-Data"
$dataDiskName = "F"

# Bastion Variables
$bastionSubnetName = "subnet-bastion-1"
$bastionHostName = "bastion-demo-host"
$bastionIPName = "bastion-demo-ip"


# Resource Group
$rg = @{
    Name = $resourceGroupName
    Location = $location
}
New-AzResourceGroup @rg


# Virtual Network
$subnetConfig = New-AzVirtualNetworkSubnetConfig -Name $vmSubnetName -AddressPrefix 172.16.9.0/24

$bastsubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $bastionSubnetName -AddressPrefix 172.16.10.0/24

$vnetParameters = @{
    Name = $vnetName
    ResourceGroupName = $resourceGroupName
    Location = $location
    AddressPrefix = "172.16.0.0/16"
    Subnet = $subnetConfig, $bastsubnetConfig
}
$vnet = New-AzVirtualNetwork @vnetParameters

# Bastion
$bastionIP = @{
    Name = $bastionIPName
    ResourceGroupName = $resourceGroupName
    Location = $location
    Sku = 'Standard'
    AllocationMethod = 'Static'
}
$publicip = New-AzPublicIpAddress @bastionIP

$bastionParameters = @{
    ResourceGroupName = $resourceGroupName
    Name = $bastionHostName
    PublicIpAddress = $publicip
    VirtualNetwork = $vnet
}
New-AzBastion @bastionParameters


#Virtual Machine (Standard_B2ls_v2)
$cred = Get-Credential

$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName

$netWorkParameters = @{
    Name = $networkInterfaceName
    ResourceGroupName = $resourceGroupName
    Location = $location
    Subnet = $vnet.Subnets[0]
}
$nicVM = New-AzNetworkInterface @netWorkParameters

$vmParams = @{
    VMName = $virtualMachineName
    VMSize = $virtualMachineFamily
}
$vmOS = @{
    ComputerName = "vmcustomerprd"
    Credential = $cred
}
$vmImage = @{
    PublisherName = 'MicrosoftWindowsServer'
    Offer = 'WindowsServer'
    Skus = '2022-datacenter-azure-edition'
    Version = 'latest'
}
$vmConfig = New-AzVMConfig @vmParams | Set-AzVMOperatingSystem -Windows @vmOS | Set-AzVMSourceImage @vmImage | Add-AzVMNetworkInterface -Id $nicVM.Id

## Create the virtual machine ##
New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig

## Create OS Disk ##
$snapshotOS = Get-AzSnapshot -ResourceGroupName $resourceGroupNameSnapshot -SnapshotName $snapshotOSName
$diskOSConfig = New-AzDiskConfig -Location $location -SourceResourceId $snapshotOS.Id -CreateOption Copy
$diskOS = New-AzDisk -Disk $diskOSConfig -ResourceGroupName $resourceGroupName -DiskName $osDiskName

## Create Data Disk ##
$snapshotData = Get-AzSnapshot -ResourceGroupName $resourceGroupNameSnapshot -SnapshotName $snapshotDataName
$diskDataConfig = New-AzDiskConfig -Location $location -SourceResourceId $snapshotData.Id -CreateOption Copy
$diskData = New-AzDisk -Disk $diskDataConfig -ResourceGroupName $resourceGroupName -DiskName $dataDiskName



# Create Azure SQL Server
$cred = Get-Credential

$sqlConfig = @{
    ResourceGroupName = $resourceGroupName
    ServerName = $databaseServerName
    SqlAdministratorCredentials = $cred
    Location = $location
}
New-AzSqlServer @sqlConfig

$sqlDatabaseConfig = @{
    ResourceGroupName = $resourceGroupName
    ServerName = $databaseServerName
    DatabaseName = $databaseName
    RequestedServiceObjectiveName = 'S0'
    SampleName = 'AdventureWorksLT'
}
New-AzSqlDatabase @sqlDatabaseConfig


# Create Endpoint
$server = Get-AzSqlServer -ResourceGroupName $resourceGroupName -ServerName $databaseServerName

## Create private endpoint connection. ##
$privateEndpointConnectionConfig = @{
    Name = 'myConnection'
    PrivateLinkServiceId = $server.ResourceID
    GroupID = 'sqlserver'
}
$privateEndpointConnection = New-AzPrivateLinkServiceConnection @privateEndpointConnectionConfig

## Place virtual network into variable. ##
$vnet = Get-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Name $vnetName

## Disable private endpoint network policy ##
$vnet.Subnets[0].PrivateEndpointNetworkPolicies = "Disabled"
$vnet | Set-AzVirtualNetwork

## Create private endpoint
$privateEndpointConfig = @{
    ResourceGroupName = $resourceGroupName
    Name = $privateEndpointName
    Location = $location
    Subnet = $vnet.Subnets[0]
    PrivateLinkServiceConnection = $privateEndpointConnection
}
New-AzPrivateEndpoint @privateEndpointConfig


# Private DNS Zone
## Place virtual network into variable. ##
$vnet = Get-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Name $vnetName

## Create private dns zone. ##
$dnsZoneConfig = @{
    ResourceGroupName = $resourceGroupName
    Name = 'privatelink.database.windows.net'
}
$zone = New-AzPrivateDnsZone @dnsZoneConfig

## Create dns network link. ##
$dnsNetworkLinkConfig = @{
    ResourceGroupName = $resourceGroupName
    ZoneName = 'privatelink.database.windows.net'
    Name = 'myLink'
    VirtualNetworkId = $vnet.Id
}
$link = New-AzPrivateDnsVirtualNetworkLink @dnsNetworkLinkConfig

## Create DNS configuration ##
$dnsConfig = @{
    Name = 'privatelink.database.windows.net'
    PrivateDnsZoneId = $zone.ResourceId
}
$config = New-AzPrivateDnsZoneConfig @dnsConfig

## Create DNS zone group. ##
$dnsZoneGroupConfig = @{
    ResourceGroupName = $resourceGroupName
    PrivateEndpointName = $privateEndpointName
    Name = 'myZoneGroup'
    PrivateDnsZoneConfig = $config
}
New-AzPrivateDnsZoneGroup @dnsZoneGroupConfig
