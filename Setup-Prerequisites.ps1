# PowerShell script to set up prerequisites for the ARM template deployment
param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$KeyVaultName,
    
    [Parameter(Mandatory=$true)]
    [string]$DiskEncryptionKeyName,
    
    [Parameter(Mandatory=$true)]
    [string]$ComputeGalleryName,
    
    [Parameter(Mandatory=$true)]
    [string]$ImageDefinitionName,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "East US"
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "Setting up prerequisites for ARM template deployment..." -ForegroundColor Green

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

    # Create resource group if it doesn't exist
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (!$rg) {
        Write-Host "Creating resource group: $ResourceGroupName" -ForegroundColor Yellow
        New-AzResourceGroup -Name $ResourceGroupName -Location $Location
    }

    # Verify Key Vault exists (using existing)
    Write-Host "Verifying Key Vault exists: $KeyVaultName" -ForegroundColor Yellow
    $kv = Get-AzKeyVault -VaultName $KeyVaultName -ErrorAction SilentlyContinue
    if (!$kv) {
        Write-Host "Error: Key Vault '$KeyVaultName' not found. Please ensure it exists." -ForegroundColor Red
        exit 1
    }
    Write-Host "Key Vault found: $($kv.VaultName)" -ForegroundColor Green

    # Create disk encryption key if it doesn't exist
    $key = Get-AzKeyVaultKey -VaultName $KeyVaultName -Name $DiskEncryptionKeyName -ErrorAction SilentlyContinue
    if (!$key) {
        Write-Host "Creating disk encryption key: $DiskEncryptionKeyName" -ForegroundColor Yellow
        $key = Add-AzKeyVaultKey -VaultName $KeyVaultName -Name $DiskEncryptionKeyName -Destination Software
    } else {
        Write-Host "Disk encryption key already exists: $($key.Name)" -ForegroundColor Green
    }

    # Enable Key Vault for disk encryption
    Write-Host "Ensuring Key Vault is enabled for disk encryption..." -ForegroundColor Yellow
    Set-AzKeyVaultAccessPolicy -VaultName $KeyVaultName -EnabledForDiskEncryption

    # Verify compute gallery exists (using existing)
    Write-Host "Verifying compute gallery exists: $ComputeGalleryName" -ForegroundColor Yellow
    $gallery = Get-AzGallery -Name $ComputeGalleryName -ErrorAction SilentlyContinue
    if (!$gallery) {
        Write-Host "Error: Compute gallery '$ComputeGalleryName' not found. Please ensure it exists." -ForegroundColor Red
        exit 1
    }
    Write-Host "Compute gallery found: $($gallery.Name)" -ForegroundColor Green

    # Create image definition if it doesn't exist
    $imageDef = Get-AzGalleryImageDefinition -GalleryName $ComputeGalleryName -Name $ImageDefinitionName -ErrorAction SilentlyContinue
    if (!$imageDef) {
        Write-Host "Creating image definition: $ImageDefinitionName" -ForegroundColor Yellow
        $imageDef = New-AzGalleryImageDefinition `
            -GalleryName $ComputeGalleryName `
            -Name $ImageDefinitionName `
            -Location $Location `
            -Publisher "MyPublisher" `
            -Offer "WindowsServer" `
            -Sku "2022-datacenter-g2" `
            -OsType Windows `
            -OsState Generalized `
            -HyperVGeneration V2 `
            -Feature @{Name="SecurityType"; Value="TrustedLaunch"}
    } else {
        Write-Host "Image definition already exists: $($imageDef.Name)" -ForegroundColor Green
    }

    Write-Host "Prerequisites setup completed successfully!" -ForegroundColor Green
    Write-Host "Key Vault: $($kv.VaultName)" -ForegroundColor Cyan
    Write-Host "Disk Encryption Key: $($key.Name)" -ForegroundColor Cyan
    Write-Host "Compute Gallery: $($gallery.Name)" -ForegroundColor Cyan
    Write-Host "Image Definition: $($imageDef.Name)" -ForegroundColor Cyan

    # Update parameters file with actual values
    Write-Host "Updating parameters file with actual values..." -ForegroundColor Yellow
    $parametersFile = Get-Content "mainTemplate.parameters.json" | ConvertFrom-Json
    $parametersFile.parameters.keyVaultName.value = $KeyVaultName
    $parametersFile.parameters.keyVaultResourceGroup.value = $ResourceGroupName
    $parametersFile.parameters.diskEncryptionKeyName.value = $DiskEncryptionKeyName
    $parametersFile.parameters.computeGalleryName.value = $ComputeGalleryName
    $parametersFile.parameters.computeGalleryResourceGroup.value = $ResourceGroupName
    $parametersFile.parameters.imageDefinitionName.value = $ImageDefinitionName
    
    $parametersFile | ConvertTo-Json -Depth 10 | Set-Content "mainTemplate.parameters.json"
    Write-Host "Parameters file updated successfully!" -ForegroundColor Green
}
catch {
    Write-Host "Error occurred during prerequisites setup: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "Prerequisites setup script completed!" -ForegroundColor Green
