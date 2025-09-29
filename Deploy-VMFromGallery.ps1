# PowerShell script to deploy VM from gallery image with Trusted Launch and disk encryption
param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "East US",
    
    [Parameter(Mandatory=$false)]
    [string]$ParametersFile = "deployFromGallery.parameters.json"
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "Starting VM deployment from gallery image with Trusted Launch and disk encryption..." -ForegroundColor Green

try {
    # Connect to Azure if not already connected
    $context = Get-AzContext
    if (!$context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Yellow
        Connect-AzAccount
    }

    # Set subscription context
    Write-Host "Setting subscription context to: $SubscriptionId" -ForegroundColor Yellow
    Set-AzContext -SubscriptionId $SubscriptionId

    # Check if resource group exists
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (!$rg) {
        Write-Host "Creating resource group: $ResourceGroupName" -ForegroundColor Yellow
        New-AzResourceGroup -Name $ResourceGroupName -Location $Location
    }

    # Validate that the gallery image exists
    Write-Host "Validating gallery image availability..." -ForegroundColor Yellow
    $parametersContent = Get-Content $ParametersFile | ConvertFrom-Json
    $galleryName = $parametersContent.parameters.galleryName.value
    $galleryRG = $parametersContent.parameters.galleryResourceGroup.value
    $imageDefName = $parametersContent.parameters.imageDefinitionName.value
    $imageVersion = $parametersContent.parameters.imageVersionName.value

    try {
        $galleryImage = Get-AzGalleryImageVersion -ResourceGroupName $galleryRG -GalleryName $galleryName -GalleryImageDefinitionName $imageDefName -Name $imageVersion -ErrorAction Stop
        Write-Host "✅ Gallery image found: $($galleryImage.Id)" -ForegroundColor Green
    } catch {
        Write-Host "❌ Error: Gallery image not found. Please ensure the image exists." -ForegroundColor Red
        Write-Host "Looking for: $galleryRG/$galleryName/$imageDefName/$imageVersion" -ForegroundColor Yellow
        exit 1
    }

    # Check Key Vault and encryption key availability
    Write-Host "Validating Key Vault and encryption key..." -ForegroundColor Yellow
    $kvName = $parametersContent.parameters.keyVaultName.value
    $kvRG = $parametersContent.parameters.keyVaultResourceGroup.value
    $keyName = $parametersContent.parameters.diskEncryptionKeyName.value

    try {
        $key = Get-AzKeyVaultKey -VaultName $kvName -Name $keyName -ErrorAction Stop
        Write-Host "✅ Encryption key found: $($key.Id)" -ForegroundColor Green
    } catch {
        Write-Host "❌ Error: Encryption key not found. Please ensure the key exists in Key Vault." -ForegroundColor Red
        Write-Host "Looking for key: $keyName in vault: $kvName" -ForegroundColor Yellow
        exit 1
    }

    # Validate template
    Write-Host "Validating ARM template..." -ForegroundColor Yellow
    $validation = Test-AzResourceGroupDeployment `
        -ResourceGroupName $ResourceGroupName `
        -TemplateFile "deployFromGallery.json" `
        -TemplateParameterFile $ParametersFile

    if ($validation.Count -gt 0) {
        Write-Host "Template validation failed with errors:" -ForegroundColor Red
        $validation | ForEach-Object { Write-Host $_.Message -ForegroundColor Red }
        exit 1
    }

    Write-Host "Template validation passed!" -ForegroundColor Green

    # Deploy the template
    Write-Host "Deploying VM from gallery image..." -ForegroundColor Yellow
    Write-Host "This deployment includes:" -ForegroundColor Cyan
    Write-Host "  • Custom gallery image with your configurations" -ForegroundColor Cyan
    Write-Host "  • Trusted Launch security (Secure Boot + vTPM)" -ForegroundColor Cyan
    Write-Host "  • Customer managed key disk encryption" -ForegroundColor Cyan
    Write-Host "  • Premium SSD storage" -ForegroundColor Cyan
    
    $deployment = New-AzResourceGroupDeployment `
        -ResourceGroupName $ResourceGroupName `
        -TemplateFile "deployFromGallery.json" `
        -TemplateParameterFile $ParametersFile `
        -Name "VMFromGallery-$(Get-Date -Format 'yyyyMMdd-HHmmss')" `
        -Verbose

    if ($deployment.ProvisioningState -eq "Succeeded") {
        Write-Host ""
        Write-Host "🎉 VM deployment completed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📊 DEPLOYMENT SUMMARY:" -ForegroundColor Yellow
        Write-Host "VM Resource ID: $($deployment.Outputs.vmResourceId.Value)" -ForegroundColor Cyan
        Write-Host "Public IP Address: $($deployment.Outputs.publicIPAddress.Value)" -ForegroundColor Cyan
        Write-Host "Disk Encryption Set ID: $($deployment.Outputs.diskEncryptionSetId.Value)" -ForegroundColor Cyan
        Write-Host "Gallery Image ID: $($deployment.Outputs.galleryImageId.Value)" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "✅ FEATURES ENABLED:" -ForegroundColor Green
        Write-Host "  ✅ Custom gallery image deployed" -ForegroundColor Green
        Write-Host "  ✅ Trusted Launch enabled (Secure Boot + vTPM)" -ForegroundColor Green
        Write-Host "  ✅ Customer managed key encryption active" -ForegroundColor Green
        Write-Host "  ✅ Premium SSD storage with encryption" -ForegroundColor Green
        Write-Host "  ✅ Network security group with RDP access" -ForegroundColor Green
        Write-Host ""
        Write-Host "🔐 SECURITY:" -ForegroundColor Yellow
        Write-Host "  • Disk encryption using Key Vault: $kvName" -ForegroundColor Cyan
        Write-Host "  • Encryption key: $keyName" -ForegroundColor Cyan
        Write-Host "  • Trusted Launch security enabled" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "🌐 ACCESS:" -ForegroundColor Yellow
        Write-Host "  • RDP: $($deployment.Outputs.publicIPAddress.Value):3389" -ForegroundColor Cyan
        Write-Host "  • Username: $($parametersContent.parameters.adminUsername.value)" -ForegroundColor Cyan
        
        # Save deployment outputs
        $deployment.Outputs | ConvertTo-Json | Out-File -FilePath "gallery-vm-deployment-outputs.json"
        Write-Host ""
        Write-Host "Deployment outputs saved to gallery-vm-deployment-outputs.json" -ForegroundColor Yellow
    } else {
        Write-Host "VM deployment failed with state: $($deployment.ProvisioningState)" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "Error occurred during deployment: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "VM from gallery deployment script completed!" -ForegroundColor Green
