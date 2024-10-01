# awscli-wrapper-powershell
AWS CLI wrapper written PowerShell.

## Environment Setup
Install the latest version of [PowerShell](https://aka.ms/powershell-release?tag=stable) for your system.

## Initial Setup
    git clone https://github.com/kccoers/awscli-wrapper-powershell.git
    cd awscli-wrapper-powershell/Scripts
    pwsh Setup-Sso.ps1

*Setup-Sso.ps1 will automatically determine if the AWS CLI is installed and install it, if necessary*

### SSO Setup
You will need the following information to allow `Setup-Sso.ps1` to create your SSO Session in the AWS config file:

* SSO Session Name
* SSO Start URL
* SSO Region (this will default to "us-east-1", if not provided)
* SSO Registration Scopes (this will default to "sso:account:access", if not provided)

`Setup-Sso.ps1` will attempt to obtain this information dynamically. Alternatively, it can be supplied by calling the script with the following paramters:

`pwsh Setup-Sso.ps1 -SsoSessionName SESSION_NAME -SsoStartUrl START_URL -SsoRegion REGION -SsoRegistrationScopes SCOPES`

## Login via SSO
Once your SSO configuration is setup, login to an SSO session using the following

### AWS CLI Directly
    aws sso login --sso-session SESSION_NAME

### PowerShell Script in this Repository
    cd /path/to/awscli-wrapper-powershell
    pwsh Login-Sso.ps1 -SsoSessionName SESSION_NAME

Once you are logged in, any script that references your SSO session will work as long as your token is valid

## General Usage
Use scripts to get information about services or deployments across multiple AWS accounts/roles using PowerShell background jobs. This comes in handy with multiple accounts, eliminating the need to loop through each account and allows gathering of information across accounts simultaneously.

Example:

    cd /path/to/awscli-wrapper-powershell
    pwsh Get-Ec2.ps1