Param(
  [parameter(Mandatory=$False)]
  [switch]$cloud,
  [parameter(Mandatory=$False)]
  [switch]$hybrid,    
  [parameter(Mandatory=$False)]
  [switch]$local
)

If(-NOT (($cloud) -or ($hybrid) -or ($local))) {
  Write-Host "You did not choose Cloud, Hybrid, or Local. Please run this script again and specify the required switch."
  Exit
}

$File = "Disable-ADAADUser_log_$(Get-Date -Format ddMMyyyy_HHMMss).txt"
$Logfilepath = "$env:USERPROFILE\Desktop\"
$AzureADManagementUPN = Read-Host "Enter the Azure Active Directory Management UserPrincipalName"
Connect-AzureAD -AccountID $AzureADManagementUPN
Get-AzureADUser | Select-Object DisplayName, UserPrincipalName, AccountEnabled
$UPN = Read-Host "Enter the User Principal Name of the account which is suspected of being compromised"

Function DisableAADUserandRegisteredDevices() {
  "Disabling $UPN" | Tee-Object -FilePath "$Logfilepath\$File" -Append | Write-Host -ForegroundColor Green
  Get-AzureADUser -ObjectID $UPN | Set-AzureADUser -AccountEnabled $false
  "Revoking all Azure Active Directory tokens issued for $UPN" | Tee-Object -FilePath "$Logfilepath\$File" -Append | Write-Host -ForegroundColor Green
  Get-AzureADUser -ObjectID $UPN | Revoke-AzureADUserAllRefreshToken
  "Getting the Azure Active Directory account status of $UPN" | Tee-Object -FilePath "$Logfilepath\$File" -Append | Write-Host -ForegroundColor Green
  Get-AzureADUser -ObjectID $UPN | Select-Object UserPrincipalName, AccountEnabled
  $DisableAzureADuserRegisteredDevicesConfirmDecision = Read-host "If you continue, the Azure AD User Registered Devices associated with $UPN will be disabled. Do you want to proceed? (Yes/No)"
  If ($DisableAzureADUserRegisteredDevicesConfirmDecision -like "Yes") {
      "Disabling all Azure Active Directory User Registered Devices associated with $UPN" | Tee-Object -FilePath "$Logfilepath\$File" -Append | Write-Host -ForegroundColor Green
      Get-AzureADUserRegisteredDevice -ObjectId $UPN | Set-AzureADDevice -AccountEnabled $false
      "Getting the status of Azure Active Directory User Registered Devices associated with $UPN" | Tee-Object -FilePath "$Logfilepath\$File" -Append | Write-Host -ForegroundColor Green
  }
  Disconnect-AzureAD -Confirm:$false
}

Function CreateNewPassword() {
  $null = $Random
  $Random = New-Object -TypeName PSObject
  $Random | Add-Member -MemberType ScriptProperty -Name "Random" -Value {('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+[{]}\|;:,<.>/?'.ToCharArray() | Sort-Object {Get-Random})[0..30] -join ''}
  $Random = $Random | ConvertTo-SecureString -AsPlainText -Force
}

Function ChangePassword() {
  CreateNewPassword
  Get-ADUser -Filter "UserPrincipalName -eq '$EmployeeUPN'" | Set-ADAccountPassword -NewPassword $Random
}
Function DisableADUser() {
  Get-ADUser -Filter "UserPrincipalName -eq '$EmployeeUPN'" | Disable-ADAccount
  ChangePassword
  ChangePassword
}

If(($cloud) -or ($hybrid)){
  If (-Not (Get-Module -Name AzureAD)) {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    Install-Module -Name AzureAD -Force
}
  Import-Module -Name AzureAD -ErrorAction:SilentlyContinue
}

If(($hybrid) -or ($local)) {
  $DomainControllers = Get-ADDomainController -Filter * | Select-Object Name -ExpandProperty Name
  $NamingContext = Get-ADRootDSE | Select-Object rootDomainNamingContext -ExpandProperty rootDomainNamingContext
  $name = hostname
  If ($DomainControllers -notcontains $name) {
      Write-Host "You are not logged into a Domain Controller. There are pre-requisites for running this script with the local switch from a non-Domain Controller. Please verify that this computer is a Domain Joined computer with RSAT installed."
      Import-Module -Name ActiveDirectory -ErrorAction:SilentlyContinue
      If (-Not (Get-Module -Name ActiveDirectory)) {
          Add-WindowsCapability -Online -name "RSAT.ActiveDirectory.DS-LDS.Tools"
          Import-Module -Name ActiveDirectory -ErrorAction:SilentlyContinue
      }
  }
    If ($DomainControllers -contains $name) {
          Import-Module ActiveDirectory
    }
}

If($cloud) {
  $DisableAzureADUserConfirmDecision = Read-host "If you continue, the AzureAD user $UPN will be disabled and active AzureAD tokens used for authentication by $UPN will be revoked. Do you want to proceed? (Yes/No)"
  If ($DisableAzureADUserConfirmDecision -like "Yes") {
    DisableAADUserandRegisteredDevices
  }
  If ($DisableAzureADUserConfirmDecision -notlike "Yes") {
    Write-Host "You decided not to disable the AzureAD user $UPN and revoke all AzureAD tokens for AzureAD user $UPN. You also indicated you believe the AzureAD account $UPN is compromised. If you meant to disable the AzureAD account $UPN and revoke all AzureAD tokens for the AzureAD account $UPN, please run the script again and answer the questions correctly."
  }
}
If($hybrid) {
  $DisableHybridAADUserConfirmDecision = Read-host "If you continue, the AD user $UPN will be disabled, the AzureAD user $UPN will be disabled, and active AzureAD tokens used for authentication by $UPN will be revoked. Do you want to proceed? (Yes/No)"
  If ($DisableAzureADUserConfirmDecision -like "Yes") {
    DisableAADUserandRegisteredDevices
    DisableADUser
    Start-ADSyncSyncCycle -PolicyType Delta
  }
  If ($DisableHybridAADUserConfirmDecision -notlike "Yes") {
    Write-Host "You decided not to disable the AD user $UPN, the AzureAD user $UPN, nor to revoke all AzureAD tokens for AzureAD user $UPN. You also indicated you believe the AD account $UPN and/or AzureAD account $UPN is compromised. If you meant to disable the AD account $UPN and AzureAD account $UPN and revoke all AzureAD tokens for the AzureAD account $UPN, please run the script again and answer the questions correctly."
  }
}

If($local) {
  $DisableADUserConfirmDecision = Read-host "If you continue, the AD user $UPN will be disabled. Do you want to proceed? (Yes/No)"
  If ($DisableADUserConfirmDecision -like "Yes") {
    DisableADUser
  }
  If ($DisableADUserConfirmation -notlike "Yes") {
    Write-Host "You decided not to disable the AD user $UPN. You also indicated you believe the AD account $UPN is compromised. If you meant to disable the AD account $UPN, please run the script again and answer the questions correctly."
  }
}


