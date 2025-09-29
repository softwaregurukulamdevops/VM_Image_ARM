# Azure DevOps Variable Groups Configuration

This document describes all the variable groups and their required variables for the ARM template deployment pipeline.

## Variable Groups Setup

Create the following variable groups in Azure DevOps Library (`Project Settings` → `Pipelines` → `Library`):

### 1. Variable Group: `ARM-Template-Config`
**Description**: General ARM template configuration settings

| Variable Name | Description | Example Value | Required |
|---------------|-------------|---------------|----------|
| `location` | Azure region for deployments | `East US` | ✅ |
| `resourceGroupName` | Target resource group for VM deployment | `RG_Central` | ✅ |
| `galleryResourceGroupName` | Resource group for compute gallery | `RG_AVD` | ✅ |
| `serviceConnection` | Azure DevOps service connection name | `Azure-Production` | ✅ |

### 2. Variable Group: `Azure-Credentials`
**Description**: Azure subscription and authentication details

| Variable Name | Description | Example Value | Required |
|---------------|-------------|---------------|----------|
| `subscriptionId` | Azure subscription ID | `3bc8f069-65c7-4d08-b8de-534c20e56c38` | ✅ |

### 3. Variable Group: `VM-Configuration`
**Description**: Virtual machine configuration settings

| Variable Name | Description | Example Value | Required |
|---------------|-------------|---------------|----------|
| `vmName` | Name of the initial VM | `vm-trusted-$(Build.BuildNumber)` | ✅ |
| `finalVMName` | Name of the final VM from gallery | `vm-production-$(Build.BuildNumber)` | ✅ |
| `vmSize` | Azure VM size | `Standard_D2s_v3` | ✅ |
| `adminUsername` | VM administrator username | `azureuser` | ✅ |
| `adminPassword` | VM administrator password | `P@ssw0rd123!` | ✅ |
| `marketplaceImageOffer` | Windows Server offer | `WindowsServer` | ✅ |
| `marketplaceImagePublisher` | Image publisher | `MicrosoftWindowsServer` | ✅ |
| `marketplaceImageSku` | Windows Server SKU | `2022-datacenter-g2` | ✅ |

### 4. Variable Group: `Security-Config`
**Description**: Encryption and security configuration

| Variable Name | Description | Example Value | Required |
|---------------|-------------|---------------|----------|
| `keyVaultName` | Key Vault name for encryption | `kvimagetest` | ⚠️ |
| `diskEncryptionKeyName` | Disk encryption key name | `imagetest` | ⚠️ |
| `computeGalleryName` | Original compute gallery name | `central` | ⚠️ |
| `imageDefinitionName` | Original image definition name | `imagetest` | ⚠️ |
| `newGalleryName` | New gallery name for captured images | `acg_avd` | ✅ |
| `newImageDefinitionName` | New image definition name | `windows-trusted-launch` | ✅ |
| `imageVersionName` | Image version | `1.0.0` | ✅ |

### 5. Variable Group: `Pipeline-Control`
**Description**: Pipeline execution control flags

| Variable Name | Description | Example Value | Required |
|---------------|-------------|---------------|----------|
| `setupPrerequisites` | Setup Key Vault and prerequisites | `false` | ✅ |
| `deployVM` | Deploy initial VM | `true` | ✅ |
| `captureImage` | Capture VM image to gallery | `true` | ✅ |
| `deployFromGallery` | Deploy VM from gallery image | `true` | ✅ |
| `cleanupResources` | Cleanup temporary resources | `false` | ✅ |
| `cleanupIntermediateVM` | Remove intermediate VM after capture | `false` | ✅ |

## Security Best Practices

### 1. Secure Variables
Mark the following variables as **secret** in Azure DevOps:
- `adminPassword`
- Any sensitive configuration values

### 2. Service Connection
Create an Azure Resource Manager service connection with:
- **Authentication Method**: Service Principal (automatic)
- **Scope Level**: Subscription
- **Resource Group**: Leave empty for subscription-level access

### 3. Permissions Required
The service principal needs the following permissions:
- **Contributor** role on target resource groups
- **Key Vault Administrator** (if using disk encryption)
- **Compute Gallery Administrator** (for image operations)

## Pipeline Configuration Examples

### For Development Environment:
```yaml
# Add to pipeline variables section
variables:
  - group: 'ARM-Template-Config'
  - group: 'Azure-Credentials-Dev'
  - group: 'VM-Configuration-Dev'
  - group: 'Security-Config-Dev'
  - group: 'Pipeline-Control-Dev'
```

### For Production Environment:
```yaml
# Add to pipeline variables section
variables:
  - group: 'ARM-Template-Config-Prod'
  - group: 'Azure-Credentials-Prod'
  - group: 'VM-Configuration-Prod'
  - group: 'Security-Config-Prod'
  - group: 'Pipeline-Control-Prod'
```

## Execution Scenarios

### Scenario 1: Complete Workflow
Set these variables to `true`:
- `deployVM: true`
- `captureImage: true`
- `deployFromGallery: true`

### Scenario 2: Only VM Deployment
Set these variables:
- `deployVM: true`
- `captureImage: false`
- `deployFromGallery: false`

### Scenario 3: Prerequisites Setup Only
Set these variables:
- `setupPrerequisites: true`
- `deployVM: false`
- `captureImage: false`
- `deployFromGallery: false`

## Troubleshooting

### Common Issues:
1. **Service Connection Issues**: Verify the service connection has proper permissions
2. **Variable Group Not Found**: Ensure variable groups are created and accessible to the pipeline
3. **Resource Group Access**: Verify service principal has Contributor access to target resource groups
4. **Key Vault Permissions**: For encryption features, ensure Key Vault access policies are configured

### Pipeline Validation:
The pipeline includes validation stages that will:
- Validate all ARM templates before deployment
- Check resource accessibility
- Verify prerequisites are met

## Variable Group Creation Commands

Use Azure CLI to create variable groups programmatically:

```bash
# Create variable group
az pipelines variable-group create \
  --name "ARM-Template-Config" \
  --variables location="East US" resourceGroupName="RG_Central" \
  --project "YourProject"

# Add secret variable
az pipelines variable-group variable create \
  --group-id <group-id> \
  --name "adminPassword" \
  --value "YourSecurePassword" \
  --secret true
```
