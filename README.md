# Azure VM ARM Template with Marketplace Image, Disk Encryption, and Trusted Launch

This ARM template project creates a Virtual Machine from an Azure Marketplace image with the following features:
- **Customer Managed Key (CMK) Disk Encryption** using Azure Key Vault
- **Trusted Launch** security features (Secure Boot + vTPM)
- **Image Capture** and publishing to Azure Compute Gallery

## Architecture Overview

The solution consists of two main ARM templates:
1. **mainTemplate.json** - Creates VM with encryption and Trusted Launch
2. **imageTemplate.json** - Captures VM image and creates gallery image version

## Prerequisites

Before deploying this template, ensure you have:
- Azure PowerShell module installed
- Appropriate Azure permissions (Contributor role minimum)
- An Azure subscription

## Quick Start

### 1. Setup Prerequisites
Run the setup script to create required resources:

```powershell
.\Setup-Prerequisites.ps1 `
    -SubscriptionId "your-subscription-id" `
    -ResourceGroupName "your-resource-group" `
    -KeyVaultName "your-keyvault-name" `
    -DiskEncryptionKeyName "your-encryption-key" `
    -ComputeGalleryName "your-gallery-name" `
    -ImageDefinitionName "your-image-definition" `
    -Location "East US"
```

### 2. Deploy the VM
Deploy the VM with marketplace image and encryption:

```powershell
.\Deploy-VM.ps1 `
    -ResourceGroupName "your-resource-group" `
    -SubscriptionId "your-subscription-id" `
    -Location "East US"
```

### 3. Create Gallery Image
After VM configuration, capture and create gallery image:

```powershell
.\Create-Image.ps1 `
    -ResourceGroupName "your-resource-group" `
    -SubscriptionId "your-subscription-id" `
    -VmName "vm-marketplace-encrypted"
```

## File Structure

```
VM_Image_ARM/
├── mainTemplate.json                   # Main VM deployment template
├── mainTemplate.parameters.json        # Parameters for VM deployment
├── imageTemplate.json                  # Image capture template
├── imageTemplate.parameters.json       # Parameters for image creation
├── Setup-Prerequisites.ps1             # Prerequisites setup script
├── Deploy-VM.ps1                      # VM deployment script
├── Create-Image.ps1                   # Image creation script
└── README.md                          # This file
```

## Template Features

### Main Template (mainTemplate.json)
- **Virtual Machine** with Trusted Launch security type
- **Disk Encryption Set** using customer managed keys
- **Managed Identity** for Key Vault access
- **Virtual Network** with security group
- **Public IP** for remote access
- **Marketplace Image** support (Windows Server 2022 by default)

### Image Template (imageTemplate.json)
- **Gallery Image Version** creation from generalized VM
- **Multi-region replication** support
- **Storage account type** configuration

## Configuration Parameters

### VM Configuration
- `vmName`: Name of the virtual machine
- `vmSize`: VM size (must support Trusted Launch)
- `adminUsername`: Administrator username
- `adminPassword`: Administrator password (secure string)

### Marketplace Image
- `marketplaceImagePublisher`: Image publisher (default: MicrosoftWindowsServer)
- `marketplaceImageOffer`: Image offer (default: WindowsServer)
- `marketplaceImageSku`: Image SKU (default: 2022-datacenter-g2)

### Encryption Settings
- `keyVaultName`: Name of the Key Vault
- `keyVaultResourceGroup`: Resource group of Key Vault
- `diskEncryptionKeyName`: Name of encryption key in Key Vault

### Compute Gallery
- `computeGalleryName`: Name of the compute gallery
- `computeGalleryResourceGroup`: Resource group of gallery
- `imageDefinitionName`: Name of image definition
- `imageVersionName`: Version of the image to create

## Security Features

### Trusted Launch
- **Secure Boot**: Prevents unauthorized OS and bootloader modifications
- **vTPM**: Virtual Trusted Platform Module for attestation
- **Generation 2 VM**: Required for Trusted Launch features

### Disk Encryption
- **Customer Managed Keys**: Full control over encryption keys
- **Key Vault Integration**: Secure key management
- **User Assigned Identity**: Secure access to Key Vault

## Supported VM Sizes

The following VM sizes support Trusted Launch:
- Standard_B2ms, Standard_B4ms, Standard_B8ms
- Standard_D2s_v3, Standard_D4s_v3, Standard_D8s_v3
- Standard_D2s_v4, Standard_D4s_v4, Standard_D8s_v4
- Standard_E2s_v3, Standard_E4s_v3, Standard_E8s_v3

## Supported Marketplace Images

Ensure the marketplace image supports Trusted Launch:
- Windows Server 2022 Datacenter (Gen2)
- Windows Server 2019 Datacenter (Gen2)
- Windows 11 Enterprise (Gen2)
- Ubuntu 20.04 LTS (Gen2)

## Deployment Steps

1. **Prerequisites Setup**: Creates Key Vault, encryption key, and compute gallery
2. **VM Deployment**: Deploys VM with encryption and Trusted Launch
3. **VM Configuration**: Install/configure software as needed
4. **VM Generalization**: Prepare VM for image capture
5. **Image Creation**: Capture VM and create gallery image version

## Troubleshooting

### Common Issues

**Template Validation Errors**
- Ensure VM size supports Trusted Launch
- Verify marketplace image supports Gen2/Trusted Launch
- Check Key Vault permissions and key accessibility

**Deployment Failures**
- Verify subscription has sufficient quota
- Ensure Key Vault is in same region as VM
- Check resource naming conventions

**Image Creation Issues**
- VM must be stopped and generalized before image capture
- Ensure compute gallery and image definition exist
- Verify permissions to access source VM

## Cleanup

To remove all resources created by this template:

```powershell
# Remove resource group (removes all resources)
Remove-AzResourceGroup -Name "your-resource-group" -Force

# Or remove individual resources
Remove-AzVM -ResourceGroupName "your-resource-group" -Name "vm-marketplace-encrypted" -Force
Remove-AzGalleryImageVersion -ResourceGroupName "your-resource-group" -GalleryName "your-gallery-name" -GalleryImageDefinitionName "your-image-definition" -Name "1.0.0"
```

## Additional Resources

- [Azure Trusted Launch Documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/trusted-launch)
- [Azure Disk Encryption with Customer Managed Keys](https://docs.microsoft.com/en-us/azure/virtual-machines/disk-encryption)
- [Azure Compute Gallery Documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/shared-image-galleries)
- [ARM Template Reference](https://docs.microsoft.com/en-us/azure/templates/)

## Support

For issues and questions:
1. Check the troubleshooting section above
2. Review Azure Activity Log for deployment errors
3. Consult Azure documentation for specific error codes
