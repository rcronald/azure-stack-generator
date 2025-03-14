# Global Variables
$resourceGroupName = "rg_santander-001"
$location = "eastus"
$vnetName = "vnet-santander-eastus-001"

# Database variables
$databaseServerName = "dertec-db-003-santander"
$databaseName = "George"
$privateEndpointName = "pep-santander-003"

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
