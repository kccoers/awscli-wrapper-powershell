<#
.SYNOPSIS
Login to the AWS CLI with SSO

.DESCRIPTION
Logs into the AWS CLI with SSO utilizing the provided SSO Session Name

.PARAMETER SsoSessionName
Specifies the SSO Session Name to login with

.EXAMPLE
PS> ./Login-Sso.ps1 -SsoSessionName SESSION_NAME
#>


param(
    [Parameter(Mandatory=$true)]
    [string]$SsoSessionName
)

aws sso login --sso-session $SsoSessionName
