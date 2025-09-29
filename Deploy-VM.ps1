# PowerShell script to deploy VM with marketplace image, disk encryption, and Trusted Launch
param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "East US",
    
    [Parameter(Mandatory=$false)]
    [string]$ParametersFile = "mainTemplate.parameters.json"
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "Starting VM deployment with marketplace image and disk encryption..." -ForegroundColor Green

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

    # Validate template
    Write-Host "Validating ARM template..." -ForegroundColor Yellow
    $validation = Test-AzResourceGroupDeployment `
        -ResourceGroupName $ResourceGroupName `
        -TemplateFile "mainTemplate.json" `
        -TemplateParameterFile $ParametersFile

    if ($validation.Count -gt 0) {
        Write-Host "Template validation failed with errors:" -ForegroundColor Red
        $validation | ForEach-Object { Write-Host $_.Message -ForegroundColor Red }
        exit 1
    }

    Write-Host "Template validation passed!" -ForegroundColor Green

    # Deploy the template
    Write-Host "Deploying ARM template..." -ForegroundColor Yellow
    $deployment = New-AzResourceGroupDeployment `
        -ResourceGroupName $ResourceGroupName `
        -TemplateFile "mainTemplate.json" `
        -TemplateParameterFile $ParametersFile `
        -Name "VMDeployment-$(Get-Date -Format 'yyyyMMdd-HHmmss')" `
        -Verbose

    if ($deployment.ProvisioningState -eq "Succeeded") {
        Write-Host "VM deployment completed successfully!" -ForegroundColor Green
        Write-Host "VM Resource ID: $($deployment.Outputs.vmResourceId.Value)" -ForegroundColor Cyan
        Write-Host "Public IP Address: $($deployment.Outputs.publicIPAddress.Value)" -ForegroundColor Cyan
        Write-Host "Disk Encryption Set ID: $($deployment.Outputs.diskEncryptionSetId.Value)" -ForegroundColor Cyan
        
        # Save deployment outputs for image creation
        $deployment.Outputs | ConvertTo-Json | Out-File -FilePath "deployment-outputs.json"
        Write-Host "Deployment outputs saved to deployment-outputs.json" -ForegroundColor Yellow
    } else {
        Write-Host "VM deployment failed with state: $($deployment.ProvisioningState)" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "Error occurred during deployment: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "VM deployment script completed!" -ForegroundColor Green
