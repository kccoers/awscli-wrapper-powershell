<#
.SYNOPSIS
Setup the AWS config file with SSO Profile

.DESCRIPTION
Sets up the AWS config file with the specififed SSO Profile. This script can
also be used to add/remove new accounts/roles as access is granted/revoked.

.PARAMETER SsoSessionName
Specifiy the SSO Session Name to be created

.PARAMETER SsoStartUrl
Specifies the SSO Start URL provided in your AWS console

.PARAMETER SsoRegion
Specifies the associated SSO Region (defaults to us-east-1, if not provided)

.PARAMETER SsoRegistrationScopes
Specifies the SSO Registration Scopes (defaults to sso:account:access, if not provided)

.EXAMPLE
PS> ./Setup-Sso.ps1 -SsoSessionName SESSION_NAME -SsoStartUrl START_URL -SsoRegion us-east-1 -SsoRegistrationScopes sso:account:access
#>


param(
    [Parameter(Mandatory=$true)]
    [string]$SsoSessionName,
    [Parameter(Mandatory=$true)]
    [string]$SsoStartUrl,
    [Parameter()]
    [string]$SsoRegion = "us-east-1",
    [Parameter()]
    [string]$SsoRegistrationScopes = "sso:account:access"
)

# Setup Modules Import
$modules_dir = "$((Get-Item $PSScriptRoot).Parent.FullName)/Modules"

# Import Modules
Import-Module "$($modules_dir)/Set-AwsConfig.ps1" -Force
Import-Module "$($modules_dir)/Get-AwsCliToken.ps1" -Force

# Check to make sure the AWS CLI is installed. If not, download the installer
# and istall the AWS CLI
$aws_version = aws --version

if ($null -ne $aws_version) {
    $aws_version_info = $aws_version.Split(" ")
    
    $aws_version_info = $aws_version_info |
        Where-Object { $_.StartsWith("aws-cli") }

    $aws_version_info = $aws_version_info.Split("/")[1]

    if ($aws_version_info.StartsWith("2")) {
        Write-Host "AWS CLI [Major] Version 2 detected...Proceed with AWS Config Setup" -ForegroundColor Green
    
    }

} else {
    Write-Host "AWS CLI Not Installed - Download and install AWS CLI" -ForegroundColor Yellow
    
    if ($IsMacOS) {
        Invoke-WebRequest "https://awscli.amazonaws.com/AWSCLIV2.pkg" -OutFile "AWSCLIV2.pkg"
    
        sudo installer -pkg AWSCLIV2.pkg -target /
        
        Remove-Item -Path "./AWSCLIV2.pkg"
    
    } elseif ($IsLinux) {
        Invoke-WebRequest "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -OutFile "awscliv2.zip"

        unzip ./awscliv2.zip

        sudo ./aws/install

        Remove-Item -Path "./aws" -Force
        Remove-Item -Path "./awscliv2.zip"

    } elseif ($IsWindows) {
        Invoke-WebRequest "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile "AWSCLIV2.msi"

        msiexec.exe /i ./AWSCLIV2.msi /qn

        Remove-Item -Path ./AWSCLIV2.msi

    }

}

# Check to see if the AWS config file already exists. If so, back it up,
# alert the user, then proceed
if ($IsMacOS -or $IsLinux) {
    $aws_config_dir = "~/.aws/"

} elseif ($IsWindows) {
    $username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $aws_config_dir = "C:\Users\$($username)\.aws"

}

$aws_config_exists = Get-Item -Path "$($aws_config_dir)/config" -ErrorAction SilentlyContinue

if ($null -ne $aws_config_exists) {
    Write-Host "AWS Config file already exists, backing up config file and overwriting current contents." -ForegroundColor Yellow

    $aws_config_backup_filename = "config.backup-$((Get-Date).ToString("yyyyMMddHHmmss"))"
    Copy-Item -Path "$($aws_config_dir)/config" -Destination "$($aws_config_dir)/$($aws_config_backup_filename)"

    $verify_backup = Get-Item -Path "$($aws_config_dir)/$($aws_config_backup_filename)"

    if ($null -ne $verify_backup) {
        Write-Host "AWS Backup Config created : Verifying contents." -ForegroundColor Yellow
        
        $aws_config_current = Get-FileHash -Algorithm SHA512 "$($aws_config_dir)/config"
        $aws_config_backup  = Get-FileHash -Algorithm SHA512 "$($aws_config_dir)/$($aws_config_backup_filename)"

        if ($aws_config_current.Hash -eq $aws_config_backup.Hash) {
            Write-Host "AWS Config Backup Validated!!!!!" -ForegroundColor Green
            Write-Host "Removing current AWS Config File" -ForegroundColor Yellow

            Remove-Item -Path "~/.aws/config"

            Write-Host "AWS Config Removed, setting up AWS config file" -ForegroundColor Yellow

            $splat_set_aws_config = @{
                SsoSessionName        = $SsoSessionName
                SsoStartUrl           = $SsoStartUrl
                SsoRegion             = $SsoRegion
                SsoRegistrationScopes = $SsoRegistrationScopes
            }
            $set_aws_config = Set-AwsConfig @splat_set_aws_config
            

        } else {
            Write-Host "AWS Config Backup different" -BackgroundColor Black -ForegroundColor Red
        
        }
    
    } else {
        Write-Host "AWS Config Backup file not created"
    
    }
    

} else {
    Write-Host "AWS Config File does not exist"

    $splat_set_aws_config = @{
        SsoSessionName        = $SsoSessionName
        SsoStartUrl           = $SsoStartUrl
        SsoRegion             = $SsoRegion
        SsoRegistrationScopes = $SsoRegistrationScopes
    }
    $set_aws_config = Set-AwsConfig @splat_set_aws_config

}

if ($true -eq $set_aws_config) {
    Write-Host "AWS Config Set!!!!!" -ForegroundColor Green

    aws sso login --sso-session $SsoSessionName

    # Get Accounts
    $aws_accounts = aws sso list-accounts --region $SsoRegion --access-token "$(Get-AwsCliToken)"

    $aws_accounts = $aws_accounts | ConvertFrom-Json
    $aws_accounts_number_digits = $aws_accounts.accountList.Length.ToString().Length
    
    if ($aws_accounts.accountList.Length -ge 1) {
        Write-Host "Found $($aws_accounts.accountList.Length) that you have access to. Getting Roles." -ForegroundColor Green

        $aws_account_counter = 0

        $aws_accounts.accountList | ForEach-Object {
            $aws_account_info = $_

            $aws_account_counter += 1
            $aws_account_counter_display = "{0:d$($aws_accounts_number_digits)}" -f $aws_account_counter


            Write-Host "`n[$($aws_account_counter_display)/$($aws_accounts.accountList.Length)] Working on AWS Account :: Account ID: $($aws_account_info.accountId)"
            
            $aws_account_roles = aws sso list-account-roles --region $SsoRegion --access-token "$(Get-AwsCliToken)" --account-id $aws_account_info.accountId

            $aws_account_roles = $aws_account_roles | ConvertFrom-Json

            if ($aws_account_roles.roleList.Length -ge 1) {
                Write-Host "Found $($aws_account_roles.roleList.Length) role[s] :: Account ID: $($aws_account_info.accountId) :: $($aws_account_info.accountName)" -ForegroundColor Green

                $aws_account_roles.roleList | ForEach-Object {
                    $profile_name = "$($aws_account_info.accountName.Replace(' ', ''))-$($_.roleName)"
                    
                    $aws_config_file_role  = "`n[profile $($profile_name)]`n"
                    $aws_config_file_role += "sso_session = $SsoSessionName`n"
                    $aws_config_file_role += "sso_account_id = $($_.accountId)`n"
                    $aws_config_file_role += "sso_role_name = $($_.roleName)`n"
                    $aws_config_file_role += "region = $SsoRegion`n"
                    $aws_config_file_role += "output = json"
    
                    Write-Host "Adding :: Account ID: $($_.accountId) :: Role: $($_.roleName)" -ForegroundColor Yellow
                    Add-Content -Path "$($aws_config_dir)/config" -Value $aws_config_file_role

                    $profiles = aws configure list-profiles

                    if ($true -eq $profiles.Contains($profile_name)) {
                        Write-Host "Added  :: Account ID: $($_.accountId) :: Role: $($_.roleName)" -ForegroundColor Green
                    
                    } else {
                        Write-Host "Not Added :: Account ID: $($_.accountId) :: Role: $($_.roleName) Please copy and paste output below into the AWS Config File" -ForegroundColor Red
                        Write-Host "$($aws_config_file_role)`n"

                    }

                }
            
            } else {
                Write-Host "Found 0 role[s] :: Account ID: $($_.accountId) :: $($_.accountName)" -ForegroundColor Yellow

            }
    
        }

    } else {
        Write-Host "You don't appear to have access to any accounts. Please re-run this script and login with an identity that has access to at least 1 AWS account via SSO." -ForegroundColor Yellow
        
        Exit
    
    }

    # Get Roles for each Account

} else {
    Write-Host "Error Creating AWS Config File. Please run this script again." -ForegroundColor Red
    
    Exit

}

# Verify AWS Config Profiles
Write-Host "`nBegin AWS Profile Validation"

$profiles = aws configure list-profiles

$profiles = $profiles | Sort-Object

$number_of_profiles = $profiles.Length
$number_of_profiles_digits = $number_of_profiles.ToString().Length

$loop_counter_profile = 0

foreach ($profile in $profiles) {
    $loop_counter_profile += 1
    $loop_counter_display = "{0:d$($number_of_profiles_digits)}" -f $loop_counter_profile
    
    $iam_roles = aws iam list-roles --profile $profile

    $iam_roles = $iam_roles | ConvertFrom-Json

    if ($iam_roles.Length -eq 1) {
        $iam_roles_list = $iam_roles.Roles

        if ($iam_roles_list.Length -ge 1) {
            Write-Host "[$($loop_counter_display)/$($number_of_profiles)] Profile Verfied :: $($profile)" -ForegroundColor Green

        } else {
            Write-Host "[$($loop_counter_display)/$($number_of_profiles)] Profile Verfied :: $($profile) :: Message: You may not have permissions to list IAM roles" -ForegroundColor Yellow

        }

    } elseif($LASTEXITCODE) {
        Write-Host "[$($loop_counter_display)/$($number_of_profiles)] Profile Verfied :: $($profile) :: Message: You may not have permissions to list IAM roles" -ForegroundColor Yellow

    } else {
        Write-Host "[$($loop_counter_display)/$($number_of_profiles)] Profile Verification Failed :: $($profile)" -ForegroundColor Red

    }

}

Write-Host "`n`nAWS CLI Config has been successfully configured to use SSO!"
Write-Host "`nWhen calling AWS CLI commands, ensure that you login before using:"
Write-Host "`taws sso login --sso-session $($SsoSessionName)"
Write-Host "`n`nOr call the included PowerShell helper script:"
Write-Host "`tPS> /path/to/awscli-wrapper-powershell/Scripts/Login-Sso.ps1 -SsoSessionName $($SsoSessionName)"
Write-Host "`nExample Command Usage (After logging in with the above CLI command or PowerShell script)"
Write-Host "`taws ec2 describe-instances --region $($SsoRegion) --profile $((aws configure list-profiles) | Get-Random)"

$emoji = "`u{1F600}"
Write-Host "`n`n$($emoji * 3) Happy Hacking $($emoji * 3)`n`n"
