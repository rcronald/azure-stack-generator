# Variables
$resourceGroupName = "rg-bastion-demo-314156"
$location = "eastus2"
$vnetName = "vnet-demo-1"
$vmSubnetName = "subnet-demo-1"
$bastionSubnetName = "AzureBastionSubnet"
$bastionHostName = "bastion-demo-host"
$bastionIPName = "bastion-demo-ip"
$snapshotOSName = "mySnapshot-1"
$osDiskName = "C"
$snapshotDataName = "mySnapshot-1"
$dataDiskName = "F"

# Resource Group
$rg = @{
    Name = $resourceGroupName
    Location = $location
}
New-AzResourceGroup @rg

# Snapshot OSDisk
$snapshot = Get-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $snapshotOSName
$diskOSConfig = New-AzDiskConfig -Location $location -SourceResourceId $snapshot.Id -CreateOption Copy
$diskOS = New-AzDisk -Disk $diskOSConfig -ResourceGroupName $resourceGroupName -DiskName $osDiskName

# Snapshot DataDisk
$snapshot = Get-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $snapshotDataName
$diskDataConfig = New-AzDiskConfig -Location $location -SourceResourceId $snapshot.Id -CreateOption Copy
$diskData = New-AzDisk -Disk $diskDataConfig -ResourceGroupName $resourceGroupName -DiskName $dataDiskName

# Virtual Network
$vnet = @{
    Name = $vnetName 
    ResourceGroupName = $resourceGroupName
    Location = $location
    AddressPrefix = '10.0.0.0/16'
}
$virtualNetwork = New-AzVirtualNetwork @vnet

$subnet = @{
    Name = $vmSubnetName
    VirtualNetwork = $virtualNetwork
    AddressPrefix = '10.0.0.0/24'
}
$subnetConfig = Add-AzVirtualNetworkSubnetConfig @subnet

$virtualNetwork | Set-AzVirtualNetwork

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

# VM

# Set the administrator and password for the VM. ##
$cred = Get-Credential -Message "Enter a username and password for the virtual machine."

## Place the virtual network into a variable. ##
$vnet = Get-AzVirtualNetwork -Name $vnetName  -ResourceGroupName $resourceGroupName

## Create a network interface for the VM. ##
$nic = @{
    Name = "nic-1"
    ResourceGroupName = $resourceGroupName
    Location = $location
    Subnet = $vnet.Subnets[0]
}
$nicVM = New-AzNetworkInterface @nic

## Create a virtual machine configuration. ##
$vmsz = @{
    VMName = "vm-1"
    VMSize = 'Standard_B2ats_v2'  
}
$vmos = @{
    ComputerName = "vm-1"
    Credential = $cred
}
$vmimage = @{
    PublisherName = 'MicrosoftWindowsServer'
    Offer = 'WindowsServer'
    Skus = '2022-datacenter-azure-edition-smalldisk'
    Version = 'latest'    
}
$vmConfig = New-AzVMConfig @vmsz `
    | Set-AzVMOperatingSystem @vmos -Windows `
    | Set-AzVMSourceImage @vmimage `
    | Add-AzVMNetworkInterface -Id $nicVM.Id `
    | Set-AzVMOSDisk -ManagedDiskId $diskOS.Id -CreateOption Attach -Windows
    | Add-AzVMDataDisk -Name $dataDiskName -ManagedDiskId $diskData.Id -Lun 0 -CreateOption Attach



## Create the VM. ##
$vm = @{
    ResourceGroupName = $resourceGroupName
    Location = $location
    VM = $vmConfig
}
New-AzVM @vm