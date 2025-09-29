# PowerShell script to create Azure DevOps Variable Groups
# This script helps set up all required variable groups for the ARM template pipeline

param(
    [Parameter(Mandatory=$true)]
    [string]$Organization,
    
    [Parameter(Mandatory=$true)]
    [string]$Project,
    
    [Parameter(Mandatory=$false)]
    [string]$Environment = "Dev"
)

# Install Azure DevOps CLI extension if not already installed
if (!(az extension list --query "[?name=='azure-devops']" -o tsv)) {
    Write-Host "Installing Azure DevOps CLI extension..." -ForegroundColor Yellow
    az extension add --name azure-devops
}

# Configure Azure DevOps CLI defaults
az devops configure --defaults organization=$Organization project=$Project

Write-Host "Creating Variable Groups for environment: $Environment" -ForegroundColor Green
Write-Host "Organization: $Organization" -ForegroundColor Cyan
Write-Host "Project: $Project" -ForegroundColor Cyan

try {
    # 1. ARM-Template-Config Variable Group
    Write-Host "Creating ARM-Template-Config variable group..." -ForegroundColor Yellow
    $configGroupId = az pipelines variable-group create `
        --name "ARM-Template-Config-$Environment" `
        --variables `
            location="East US" `
            resourceGroupName="RG_Central_$Environment" `
            galleryResourceGroupName="RG_AVD_$Environment" `
            serviceConnection="Azure-$Environment" `
        --query "id" -o tsv

    Write-Host "✅ Created ARM-Template-Config-$Environment (ID: $configGroupId)" -ForegroundColor Green

    # 2. Azure-Credentials Variable Group
    Write-Host "Creating Azure-Credentials variable group..." -ForegroundColor Yellow
    $credentialsGroupId = az pipelines variable-group create `
        --name "Azure-Credentials-$Environment" `
        --variables `
            subscriptionId="YOUR_SUBSCRIPTION_ID_HERE" `
        --query "id" -o tsv

    Write-Host "✅ Created Azure-Credentials-$Environment (ID: $credentialsGroupId)" -ForegroundColor Green

    # 3. VM-Configuration Variable Group
    Write-Host "Creating VM-Configuration variable group..." -ForegroundColor Yellow
    $vmConfigGroupId = az pipelines variable-group create `
        --name "VM-Configuration-$Environment" `
        --variables `
            vmName="vm-trusted-$Environment" `
            finalVMName="vm-production-$Environment" `
            vmSize="Standard_D2s_v3" `
            adminUsername="azureuser" `
            marketplaceImageOffer="WindowsServer" `
            marketplaceImagePublisher="MicrosoftWindowsServer" `
            marketplaceImageSku="2022-datacenter-g2" `
        --query "id" -o tsv

    # Add admin password as secret variable
    az pipelines variable-group variable create `
        --group-id $vmConfigGroupId `
        --name "adminPassword" `
        --value "P@ssw0rd123!" `
        --secret $true

    Write-Host "✅ Created VM-Configuration-$Environment (ID: $vmConfigGroupId)" -ForegroundColor Green

    # 4. Security-Config Variable Group
    Write-Host "Creating Security-Config variable group..." -ForegroundColor Yellow
    $securityGroupId = az pipelines variable-group create `
        --name "Security-Config-$Environment" `
        --variables `
            keyVaultName="kvimagetest$Environment" `
            diskEncryptionKeyName="imagetest" `
            computeGalleryName="central$Environment" `
            imageDefinitionName="imagetest" `
            newGalleryName="acg_avd_$Environment" `
            newImageDefinitionName="windows-trusted-launch" `
            imageVersionName="1.0.0" `
        --query "id" -o tsv

    Write-Host "✅ Created Security-Config-$Environment (ID: $securityGroupId)" -ForegroundColor Green

    # 5. Pipeline-Control Variable Group
    Write-Host "Creating Pipeline-Control variable group..." -ForegroundColor Yellow
    $pipelineControlGroupId = az pipelines variable-group create `
        --name "Pipeline-Control-$Environment" `
        --variables `
            setupPrerequisites="false" `
            deployVM="true" `
            captureImage="true" `
            deployFromGallery="true" `
            cleanupResources="false" `
            cleanupIntermediateVM="false" `
        --query "id" -o tsv

    Write-Host "✅ Created Pipeline-Control-$Environment (ID: $pipelineControlGroupId)" -ForegroundColor Green

    Write-Host ""
    Write-Host "🎉 All variable groups created successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Update the subscription ID in Azure-Credentials-$Environment" -ForegroundColor Cyan
    Write-Host "2. Configure your Azure DevOps service connection named 'Azure-$Environment'" -ForegroundColor Cyan
    Write-Host "3. Review and adjust variable values as needed" -ForegroundColor Cyan
    Write-Host "4. Update the pipeline YAML file to reference these variable groups" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Variable Groups Created:" -ForegroundColor Yellow
    Write-Host "- ARM-Template-Config-$Environment" -ForegroundColor Cyan
    Write-Host "- Azure-Credentials-$Environment" -ForegroundColor Cyan
    Write-Host "- VM-Configuration-$Environment" -ForegroundColor Cyan
    Write-Host "- Security-Config-$Environment" -ForegroundColor Cyan
    Write-Host "- Pipeline-Control-$Environment" -ForegroundColor Cyan

} catch {
    Write-Error "Failed to create variable groups: $($_.Exception.Message)"
    Write-Host "Please ensure you have proper permissions and are logged in to Azure DevOps CLI" -ForegroundColor Red
    Write-Host "Run 'az login' and 'az devops login' if needed" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Setup completed for environment: $Environment" -ForegroundColor Green
