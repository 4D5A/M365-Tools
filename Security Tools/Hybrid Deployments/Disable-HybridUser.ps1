$Logfilepath = "C:\Powershell Log Files\Disable-HybridUser-$(Get-Date -f ddMMMyyyy).log"
Start-Transcript -Path $Logfilepath
Write-Host "Installing required Powershell Modules..."
./New-Modules.ps1
Write-Host "Importing required Powershell Modules..."
./Import-Modules.ps1
$AzureADManagementUPN = Read-Host "Enter the Azure Active Directory Management UserPrincipalName"
Connect-AzureAD -AccountID $AzureADManagementUPN
Clear-Host
$Random = New-Object -TypeName PSObject
$Random | Add-Member -MemberType ScriptProperty -Name "Random" -Value {('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+[{]}\|;:,<.>/?'.ToCharArray() | Sort-Object {Get-Random})[0..30] -join ''}
$Random = $Random | ConvertTo-SecureString -AsPlainText -Force
$EmployeeUPN = Read-Host "Enter the User Principal Name of the account which is compromised"
$DisableHybridUserConfirm = Read-host "If you continue, the Active Directory user $EmployeeUPN and the AzureAD user $EmployeeUPN will be disabled and active AzureAD tokens used for authentication by $UPN will be revoked. Do you want to proceed? (Yes/No)"
If ($DisableHybridUserConfirm -eq "Yes") {
    Get-AzureADUser -ObjectID $EmployeeUPN | Set-AzureADUser -AccountEnabled $false
    Get-AzureADUser -ObjectID $EmployeeUPN | Revoke-AzureADUserAllRefreshToken
    Get-ADUser -Filter "UserPrincipalName -eq '$EmployeeUPN'" | Disable-ADAccount
    Get-ADUser -Filter "UserPrincipalName -eq '$EmployeeUPN'" | Set-ADAccountPassword -NewPassword $Random
    Start-ADSyncSyncCycle -PolicyType Delta
}
$EnableHybridUserConfirm = Read-Host "Do you want to re-enable $EmployeeUPN in the on-premise AD server, Azure AD, both or neither?"
If ($EnableHybridUserConfirm -eq "both") {    
    Get-ADUser -Filter "UserPrincipalName -eq '$EmployeeUPN'" | Enable-ADAccount
    Get-AzureADUser -ObjectID $EmployeeUPN | Set-AzureADUser -AccountEnabled $true
    Start-ADSyncSyncCycle -PolicyType Delta
}
Disconnect-AzureAD
Stop-Transcript