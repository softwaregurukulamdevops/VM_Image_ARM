# PowerShell script to capture VM image and create image version in compute gallery
param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$true)]
    [string]$VmName,
    
    [Parameter(Mandatory=$false)]
    [string]$ParametersFile = "imageTemplate.parameters.json"
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "Starting VM image capture and gallery image creation..." -ForegroundColor Green

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

    # Check if VM exists and is running
    Write-Host "Checking VM status..." -ForegroundColor Yellow
    $vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName -Status
    if (!$vm) {
        Write-Host "VM '$VmName' not found in resource group '$ResourceGroupName'" -ForegroundColor Red
        exit 1
    }

    $vmStatus = ($vm.Statuses | Where-Object { $_.Code -like "PowerState/*" }).DisplayStatus
    Write-Host "VM Status: $vmStatus" -ForegroundColor Cyan

    if ($vmStatus -eq "VM running") {
        Write-Host "Stopping VM before image capture..." -ForegroundColor Yellow
        Stop-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName -Force
        Write-Host "VM stopped successfully" -ForegroundColor Green
    }

    # Generalize the VM
    Write-Host "Generalizing VM..." -ForegroundColor Yellow
    Set-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName -Generalized
    Write-Host "VM generalized successfully" -ForegroundColor Green

    # Validate image template
    Write-Host "Validating image template..." -ForegroundColor Yellow
    $validation = Test-AzResourceGroupDeployment `
        -ResourceGroupName $ResourceGroupName `
        -TemplateFile "imageTemplate.json" `
        -TemplateParameterFile $ParametersFile

    if ($validation.Count -gt 0) {
        Write-Host "Template validation failed with errors:" -ForegroundColor Red
        $validation | ForEach-Object { Write-Host $_.Message -ForegroundColor Red }
        exit 1
    }

    Write-Host "Image template validation passed!" -ForegroundColor Green

    # Deploy the image template
    Write-Host "Creating image version in compute gallery..." -ForegroundColor Yellow
    $imageDeployment = New-AzResourceGroupDeployment `
        -ResourceGroupName $ResourceGroupName `
        -TemplateFile "imageTemplate.json" `
        -TemplateParameterFile $ParametersFile `
        -Name "ImageDeployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')" `
        -Verbose

    if ($imageDeployment.ProvisioningState -eq "Succeeded") {
        Write-Host "Image creation completed successfully!" -ForegroundColor Green
        Write-Host "Image Version Resource ID: $($imageDeployment.Outputs.imageVersionResourceId.Value)" -ForegroundColor Cyan
        Write-Host "Image Version Name: $($imageDeployment.Outputs.imageVersionName.Value)" -ForegroundColor Cyan
        
        # Save image deployment outputs
        $imageDeployment.Outputs | ConvertTo-Json | Out-File -FilePath "image-deployment-outputs.json"
        Write-Host "Image deployment outputs saved to image-deployment-outputs.json" -ForegroundColor Yellow
    } else {
        Write-Host "Image creation failed with state: $($imageDeployment.ProvisioningState)" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "Error occurred during image creation: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "Image capture and gallery creation script completed!" -ForegroundColor Green
