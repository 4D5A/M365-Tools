Import-Module -Name AzureAD -ErrorAction:SilentlyContinue
If(-Not (Get-Module -Name AzureAD)) {
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
  Install-Module -Name AzureAD -Force
  Import-Module -Name AzureAD
}

$File = "Disable-ADAADUser_log_$(Get-Date -Format ddMMyyyy_HHMMss).txt"
$Logfilepath = "$env:USERPROFILE\Desktop\"
$AzureADManagementUPN = Read-Host "Enter the Azure Active Directory Management UserPrincipalName"
Connect-AzureAD -AccountID $AzureADManagementUPN
Clear-Host
Get-AzureADUser | Select-Object DisplayName, UserPrincipalName, AccountEnabled
$UPN = Read-Host "Enter the User Principal Name of the account which is suspected of being compromised"
    $DisableAzureADUserConfirm = Read-host "If you continue, the AzureAD user $UPN will be disabled and active AzureAD tokens used for authentication by $UPN will be revoked. Do you want to proceed? (Yes/No)"
    If($DisableAzureADUserConfirm -like "Yes") {
        "Disabling $UPN" | Tee-Object -FilePath "$Logfilepath\$File" -Append | Write-Host -ForegroundColor Green
        Set-AzureADUser -ObjectId $UPN -AccountEnabled $false
        "Revoking all Azure Active Directory refresh tokens issued for $UPN" | Tee-Object -FilePath "$Logfilepath\$File" -Append | Write-Host -ForegroundColor Green
        Revoke-AzureADUserAllRefreshToken -ObjectId $UPN
        $DisableAzureADDevicesConfirm = Read-host "Do you want to disable $UPN's Azure Active Directory devices from connecting to Microsoft 365? (Yes/No)"
        If($DisableAADDevices -like "Yes") {
            "Disabling access from $UPN's Azure Active Directory Devices" | Tee-Object -FilePath "$Logfilepath\$File" -Append | Write-Host -ForegroundColor Green
            Get-AzureADUserRegisteredDevice -ObjectId $UPN | Set-AzureADDevice -AccountEnabled $false
        }
        "Getting the Azure Active Directory account status of $UPN" | Tee-Object -FilePath "$Logfilepath\$File" -Append | Write-Host -ForegroundColor Green
        Get-AzureADUser -ObjectID $UPN | Select-Object UserPrincipalName, AccountEnabled | Tee-Object -FilePath "$Logfilepath\$File" -Append | Write-Host -ForegroundColor Green
        "Getting the Azure Active Directory status of devices registered to $UPN" | Tee-Object -FilePath "$Logfilepath\$File" -Append | Write-Host -ForegroundColor Green
        Get-AzureADUserRegisteredDevice -All:$True -ObjectId $UPN | Select-Object ObjectId, DisplayName, DeviceOSType, DeviceOSVersion, DeviceTrustType, ProfileType, AccountEnabled
    }
    If($DisableAzureADUserConfirm -notlike "Yes") {
        Write-Host "You decided not to disable the AzureAD user $UPN and revoke all AzureAD tokens for AzureAD user $UPN. You also indicated you believe the AzureAD account $UPN is compromised. If you meant to disable the AzureAD account $UPN and revoke all AzureAD tokens for the AzureAD account $UPN, please run the script again and answer the questions correctly."
    }
Disconnect-AzureAD -Confirm:$false