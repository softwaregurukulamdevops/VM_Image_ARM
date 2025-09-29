<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# ARM Template Project Instructions

This is an Azure Resource Manager (ARM) template project for deploying VMs with marketplace images, customer managed key encryption, and Trusted Launch security features.

## Project Context
- **Main Template**: `mainTemplate.json` - Deploys VM with encryption and Trusted Launch
- **Image Template**: `imageTemplate.json` - Captures VM image for compute gallery
- **PowerShell Scripts**: Automated deployment and setup scripts
- **Target Platform**: Microsoft Azure
- **Security Features**: Customer Managed Keys, Trusted Launch, Disk Encryption

## Code Guidelines
When working with this project:

1. **ARM Template Best Practices**:
   - Use appropriate API versions for resource types
   - Include metadata descriptions for all parameters
   - Use variables for complex expressions and resource names
   - Implement proper dependencies between resources

2. **Security Considerations**:
   - Ensure all VMs use Trusted Launch when supported
   - Implement disk encryption with customer managed keys
   - Use managed identities for secure access to Key Vault
   - Follow principle of least privilege for permissions

3. **PowerShell Scripts**:
   - Include error handling and validation
   - Use Write-Host with colors for better user experience
   - Implement parameter validation
   - Provide detailed logging and output

4. **Resource Naming**:
   - Use consistent naming conventions
   - Include resource type prefixes where appropriate
   - Consider resource naming limits and restrictions

5. **Template Structure**:
   - Group related resources logically
   - Use outputs for important resource IDs and properties
   - Include comprehensive parameter descriptions
   - Validate template compatibility with target regions

## Common Tasks
- VM size must support Trusted Launch (Gen2 VMs)
- Marketplace images must support Generation 2 VMs
- Key Vault must be enabled for disk encryption
- Compute gallery requires proper image definition setup
