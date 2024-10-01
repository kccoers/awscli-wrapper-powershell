<#
.SYNOPSIS
Gets the current CLI Access Token for SSO

.INPUTS
None. You cannot pipe objects to Set-AwsConfig.ps1.

.OUTPUTS
Get-AwsCliToken outputs the string value of the Access Token

.EXAMPLE
PS> $aws_cli_token = Get-AwsCliToken

#>


Function Get-AwsCliToken {
    if ($IsMacOS -or $IsLinux) {
        $aws_cli_token_directory = "~/.aws/sso/cache"
    
    } elseif ($IsWindows) {
        $aws_cli_token_directory = "$($env:USERPROFILE)\.aws\sso\cache"
    
    }
    
    $aws_cli_token = Get-ChildItem -Path $aws_cli_token_directory |
        Sort-Object LastWriteTime -Descending |
        Select-Object FullName -First 1
    
    $aws_cli_token = Get-Content -Path $aws_cli_token.FullName |
        ConvertFrom-Json
    
    return $aws_cli_token.AccessToken
    
}
