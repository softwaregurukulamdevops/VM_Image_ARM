# PowerShell script to create new gallery and capture VM image
param(
    [Parameter(Mandatory=$true)]
    [string]$SourceVmName,
    
    [Parameter(Mandatory=$true)]
    [string]$SourceVmResourceGroup,
    
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$NewGalleryName = "acg_avd",
    
    [Parameter(Mandatory=$false)]
    [string]$NewGalleryResourceGroup = "RG_AVD",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "East US"
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "Starting image capture and new gallery creation process..." -ForegroundColor Green

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

    # Check if source VM exists
    Write-Host "Checking source VM: $SourceVmName in $SourceVmResourceGroup" -ForegroundColor Yellow
    $sourceVM = Get-AzVM -ResourceGroupName $SourceVmResourceGroup -Name $SourceVmName -ErrorAction SilentlyContinue
    if (!$sourceVM) {
        Write-Host "Error: Source VM '$SourceVmName' not found in resource group '$SourceVmResourceGroup'" -ForegroundColor Red
        exit 1
    }
    Write-Host "Source VM found: $($sourceVM.Name)" -ForegroundColor Green

    # Check VM status and stop if running
    Write-Host "Checking VM status..." -ForegroundColor Yellow
    $vmStatus = Get-AzVM -ResourceGroupName $SourceVmResourceGroup -Name $SourceVmName -Status
    $powerState = ($vmStatus.Statuses | Where-Object { $_.Code -like "PowerState/*" }).DisplayStatus
    Write-Host "VM Status: $powerState" -ForegroundColor Cyan

    if ($powerState -eq "VM running") {
        Write-Host "Stopping VM before image capture..." -ForegroundColor Yellow
        Stop-AzVM -ResourceGroupName $SourceVmResourceGroup -Name $SourceVmName -Force
        Write-Host "VM stopped successfully" -ForegroundColor Green
    }

    # Generalize the VM
    Write-Host "Generalizing VM..." -ForegroundColor Yellow
    Set-AzVM -ResourceGroupName $SourceVmResourceGroup -Name $SourceVmName -Generalized
    Write-Host "VM generalized successfully" -ForegroundColor Green

    # Create target resource group if it doesn't exist
    $targetRG = Get-AzResourceGroup -Name $NewGalleryResourceGroup -ErrorAction SilentlyContinue
    if (!$targetRG) {
        Write-Host "Creating target resource group: $NewGalleryResourceGroup" -ForegroundColor Yellow
        New-AzResourceGroup -Name $NewGalleryResourceGroup -Location $Location
    }

    # Update parameters file with current values
    Write-Host "Updating parameters file..." -ForegroundColor Yellow
    $parametersFile = Get-Content "createImageToNewGallery.parameters.json" | ConvertFrom-Json
    $parametersFile.parameters.sourceVmName.value = $SourceVmName
    $parametersFile.parameters.sourceVmResourceGroup.value = $SourceVmResourceGroup
    $parametersFile.parameters.newGalleryName.value = $NewGalleryName
    $parametersFile.parameters.newGalleryResourceGroup.value = $NewGalleryResourceGroup
    
    $parametersFile | ConvertTo-Json -Depth 10 | Set-Content "createImageToNewGallery.parameters.json"

    # Validate template
    Write-Host "Validating ARM template..." -ForegroundColor Yellow
    $validation = Test-AzResourceGroupDeployment `
        -ResourceGroupName $NewGalleryResourceGroup `
        -TemplateFile "createImageToNewGallery.json" `
        -TemplateParameterFile "createImageToNewGallery.parameters.json"

    if ($validation.Count -gt 0) {
        Write-Host "Template validation failed with errors:" -ForegroundColor Red
        $validation | ForEach-Object { Write-Host $_.Message -ForegroundColor Red }
        exit 1
    }

    Write-Host "Template validation passed!" -ForegroundColor Green

    # Deploy the template
    Write-Host "Creating new gallery and capturing image..." -ForegroundColor Yellow
    Write-Host "This process may take 10-15 minutes..." -ForegroundColor Cyan
    
    $deployment = New-AzResourceGroupDeployment `
        -ResourceGroupName $NewGalleryResourceGroup `
        -TemplateFile "createImageToNewGallery.json" `
        -TemplateParameterFile "createImageToNewGallery.parameters.json" `
        -Name "GalleryImageCapture-$(Get-Date -Format 'yyyyMMdd-HHmmss')" `
        -Verbose

    if ($deployment.ProvisioningState -eq "Succeeded") {
        Write-Host "Gallery and image creation completed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "🎉 DEPLOYMENT SUMMARY:" -ForegroundColor Yellow
        Write-Host "Gallery Resource ID: $($deployment.Outputs.galleryResourceId.Value)" -ForegroundColor Cyan
        Write-Host "Image Definition ID: $($deployment.Outputs.imageDefinitionResourceId.Value)" -ForegroundColor Cyan
        Write-Host "Image Version ID: $($deployment.Outputs.imageVersionResourceId.Value)" -ForegroundColor Cyan
        Write-Host "Image Version: $($deployment.Outputs.imageVersionName.Value)" -ForegroundColor Cyan
        Write-Host "Gallery Name: $($deployment.Outputs.galleryName.Value)" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "✅ New compute gallery created: $NewGalleryName" -ForegroundColor Green
        Write-Host "✅ VM image captured and stored in gallery" -ForegroundColor Green
        Write-Host "✅ Trusted Launch features preserved in image" -ForegroundColor Green
        Write-Host "✅ Ready for AVD deployment" -ForegroundColor Green
        
        # Save deployment outputs
        $deployment.Outputs | ConvertTo-Json | Out-File -FilePath "gallery-deployment-outputs.json"
        Write-Host "Deployment outputs saved to gallery-deployment-outputs.json" -ForegroundColor Yellow
    } else {
        Write-Host "Gallery and image creation failed with state: $($deployment.ProvisioningState)" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "Error occurred during gallery and image creation: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "Gallery and image creation script completed!" -ForegroundColor Green
