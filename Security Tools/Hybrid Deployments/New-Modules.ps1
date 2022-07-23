#Requires -RunAsAdministrator
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
If (-Not (Get-Module -Name AzureAD)) {
    Install-Module -Name AzureAD -Force
}