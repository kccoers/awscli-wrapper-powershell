<#
.SYNOPSIS
Sets SSO session data in the AWS config file

.DESCRIPTION
Populates SSO session data into the AWS config file

.INPUTS
None. You cannot pipe objects to Set-AwsConfig.ps1.

.OUTPUTS
Set-AwsConfig outputs a bool with success or failure information

.EXAMPLE
PS> $splat_aws_config = @{
>>      SsoSessionName        = SSO_SESSION_NAME
>>      SsoStartUrl           = SSO_START_URL
>>      SsoRegion             = SSO_REGION
>>      SsoRegistrationScopes = SSO_REGISTRATION_SCOPES
>>  }
PS> $set_aws_config = Set-AwsConfig @splat_aws_config

.EXAMPLE
PS> $set_aws_config = Set-AwsConfig -SsoSessionName SSO_SESSION_NAME -SsoStartUrl SSO_START_URL -SsoRegion SSO_REGION -SsoRegistrationScopes SSO_REGISTRATION_SCOPES

#>


Function Set-AwsConfig {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SsoSessionName,
        [Parameter(Mandatory=$true)]
        [string]$SsoStartUrl,
        [Parameter(Mandatory=$true)]
        [string]$SsoRegion,
        [Parameter(Mandatory=$true)]
        [string]$SsoRegistrationScopes
    )

    $aws_config_contents  = "[sso-session $($SsoSessionName)]`n"
    $aws_config_contents += "sso_start_url = $($SsoStartUrl)`n"
    $aws_config_contents += "sso_region = $($SsoRegion)`n"
    $aws_config_contents += "sso_registration_scopes = $($SsoRegistrationScopes)`n"

    $aws_config_file_created = New-Item -ItemType File -Path "$($aws_config_dir)/config" -Value $aws_config_contents

    if ($null -ne $aws_config_file_created) {
        $aws_config_set = $true
    
    } else {
        $aws_config_set = $false

    }

    return $aws_config_set

}