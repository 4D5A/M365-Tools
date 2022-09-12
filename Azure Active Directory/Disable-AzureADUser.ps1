If (-Not (Get-Module -Name AzureAD)) {
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
  Install-Module -Name AzureAD -Force
}
Import-Module -Name AzureAD -ErrorAction:SilentlyContinue -UseWindowsPowerShell

$File = "Disable-ADAADUser_log_$(Get-Date -Format ddMMyyyy_HHMMss).txt"
$Logfilepath = "$env:USERPROFILE\Desktop\"
$AzureADManagementUPN = Read-Host "Enter the Azure Active Directory Management UserPrincipalName"
Connect-AzureAD -AccountID $AzureADManagementUPN
Clear-Host
Get-AzureADUser | Select-Object DisplayName, UserPrincipalName, AccountEnabled
$UPN = Read-Host "Enter the User Principal Name of the account which is suspected of being compromised"
    $DisableAzureADUserDisableConfirm = Read-host "If you continue, the AzureAD user $UPN will be disabled and active AzureAD tokens used for authentication by $UPN will be revoked. Do you want to proceed? (Yes/No)"
    If ($DisableAzureADUserDisableConfirm -like "Yes") {
        "Disabling $UPN" | Tee-Object -FilePath "$Logfilepath\$File" -Append | Write-Host -ForegroundColor Green
        Get-AzureADUser -ObjectID $UPN | Set-AzureADUser -AccountEnabled $false
        "Revoking all Azure Active Directory tokens issued for $UPN" | Tee-Object -FilePath "$Logfilepath\$File" -Append | Write-Host -ForegroundColor Green
        Get-AzureADUser -ObjectID $UPN | Revoke-AzureADUserAllRefreshToken
        "Getting the Azure Active Directory account status of $UPN" | Tee-Object -FilePath "$Logfilepath\$File" -Append | Write-Host -ForegroundColor Green
        Get-AzureADUser -ObjectID $UPN | Select-Object UserPrincipalName, AccountEnabled
    }
    If ($DisableAzureADUserDisableConfirm -notlike "Yes") {
        Write-Host "You decided not to disable the AzureAD user $UPN and revoke all AzureAD tokens for AzureAD user $UPN. You also indicated you believe the AzureAD account $UPN is compromised. If you meant to disable the AzureAD account $UPN and revoke all AzureAD tokens for the AzureAD account $UPN, please run the script again and answer the questions correctly."
    }
Disconnect-AzureAD -Confirm:$false