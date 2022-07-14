$AdminAuditLogEnabled = Get-AdminAuditLogConfig | Select-Object -ExpandProperty UnifiedAuditLogIngestionEnabled
$Dehydrated = Get-OrganizationConfig | Select-Object -ExpandProperty IsDehydrated

If ($Dehydrated -eq $True) {
  Write-Host "Organization Customization is disabled in this tenant. Enabling Organization Customization in this tenant."
  Enable-OrganizationCustomization
  Write-Host "Enabling the Admin Audit Log."
  Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $True
}
If ($Dehydrated -eq $False) {
  If ($AdminAuditLogEnabled -eq $False) {
    Write-Host "Enabling the Admin Audit Log."
    Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $True
  }
}