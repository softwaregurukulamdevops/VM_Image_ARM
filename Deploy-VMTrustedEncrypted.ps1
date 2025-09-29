# PowerShell script to deploy VM with both Trusted Launch and disk encryption
param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "East US"
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "Starting VM deployment with Trusted Launch and disk encryption..." -ForegroundColor Green

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

    # Validate that the disk encryption set exists
    Write-Host "Validating disk encryption set availability..." -ForegroundColor Yellow
    try {
        $des = Get-AzDiskEncryptionSet -ResourceGroupName $ResourceGroupName -Name "imagetest-des" -ErrorAction Stop
        Write-Host "Disk encryption set found: $($des.Id)" -ForegroundColor Green
    } catch {
        Write-Host "Warning: Disk encryption set not found. Will attempt deployment anyway." -ForegroundColor Yellow
        Write-Host "If deployment fails, ensure the encryption set exists or remove encryption from the template." -ForegroundColor Yellow
    }

    # Validate template
    Write-Host "Validating ARM template..." -ForegroundColor Yellow
    $validation = Test-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile "deployTrustedWithEncryption.json" -TemplateParameterFile "deployTrustedWithEncryption.parameters.json"

    if ($validation.Count -gt 0) {
        Write-Host "Template validation failed with errors:" -ForegroundColor Red
        $validation | ForEach-Object { Write-Host $_.Message -ForegroundColor Red }
        exit 1
    }

    Write-Host "Template validation passed!" -ForegroundColor Green

    # Deploy the template
    Write-Host "Deploying VM with advanced security features..." -ForegroundColor Yellow
    Write-Host "This deployment includes:" -ForegroundColor Cyan
    Write-Host "  Marketplace Windows Server 2022 Gen2 image" -ForegroundColor Cyan
    Write-Host "  Trusted Launch security (Secure Boot + vTPM)" -ForegroundColor Cyan
    Write-Host "  Customer-managed key disk encryption" -ForegroundColor Cyan
    Write-Host "  Premium SSD storage" -ForegroundColor Cyan
    
    $deployment = New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile "deployTrustedWithEncryption.json" -TemplateParameterFile "deployTrustedWithEncryption.parameters.json" -Name "VMTrustedEncrypted-$(Get-Date -Format 'yyyyMMdd-HHmmss')" -Verbose

    if ($deployment.ProvisioningState -eq "Succeeded") {
        Write-Host ""
        Write-Host "VM deployment completed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "DEPLOYMENT SUMMARY:" -ForegroundColor Yellow
        Write-Host "VM Resource ID: $($deployment.Outputs.vmResourceId.Value)" -ForegroundColor Cyan
        Write-Host "Public IP Address: $($deployment.Outputs.publicIPAddress.Value)" -ForegroundColor Cyan
        Write-Host "Disk Encryption Set: $($deployment.Outputs.diskEncryptionSetUsed.Value)" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "SECURITY FEATURES ENABLED:" -ForegroundColor Green
        Write-Host "  Trusted Launch (Secure Boot + vTPM)" -ForegroundColor Green
        Write-Host "  Customer-managed key disk encryption" -ForegroundColor Green
        Write-Host "  Premium SSD storage" -ForegroundColor Green
        Write-Host "  Network security group with RDP access" -ForegroundColor Green
        Write-Host ""
        Write-Host "ACCESS:" -ForegroundColor Yellow
        Write-Host "  RDP: $($deployment.Outputs.publicIPAddress.Value):3389" -ForegroundColor Cyan
        Write-Host "  Username: azureuser" -ForegroundColor Cyan
        
        # Save deployment outputs
        $deployment.Outputs | ConvertTo-Json | Out-File -FilePath "encrypted-vm-outputs.json"
        Write-Host ""
        Write-Host "Deployment outputs saved to encrypted-vm-outputs.json" -ForegroundColor Yellow
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
Write-Host "VM deployment with encryption completed!" -ForegroundColor Green
