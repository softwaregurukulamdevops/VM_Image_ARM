# PowerShell script to deploy VM with Trusted Launch (without disk encryption)
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

Write-Host "Starting VM deployment with Trusted Launch..." -ForegroundColor Green

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
        -TemplateFile "mainTemplate-simple.json" `
        -TemplateParameterFile "mainTemplate-simple.parameters.json"

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
        -TemplateFile "mainTemplate-simple.json" `
        -TemplateParameterFile "mainTemplate-simple.parameters.json" `
        -Name "VMTrustedLaunch-$(Get-Date -Format 'yyyyMMdd-HHmmss')" `
        -Verbose

    if ($deployment.ProvisioningState -eq "Succeeded") {
        Write-Host "VM deployment completed successfully!" -ForegroundColor Green
        Write-Host "VM Resource ID: $($deployment.Outputs.vmResourceId.Value)" -ForegroundColor Cyan
        Write-Host "Public IP Address: $($deployment.Outputs.publicIPAddress.Value)" -ForegroundColor Cyan
        
        Write-Host ""
        Write-Host "VM Features:" -ForegroundColor Yellow
        Write-Host "✅ Trusted Launch enabled (Secure Boot + vTPM)" -ForegroundColor Green
        Write-Host "✅ Generation 2 VM with marketplace image" -ForegroundColor Green
        Write-Host "⚠️  Disk encryption can be added later via Azure portal" -ForegroundColor Yellow
        
        # Save deployment outputs
        $deployment.Outputs | ConvertTo-Json | Out-File -FilePath "deployment-simple-outputs.json"
        Write-Host "Deployment outputs saved to deployment-simple-outputs.json" -ForegroundColor Yellow
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
