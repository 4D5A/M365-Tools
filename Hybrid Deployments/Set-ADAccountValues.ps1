#Requires -RunAsAdministrator
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
If (-Not (Get-Module -Name AzureAD)) {
    Install-Module -Name AzureAD -Force
}
If (-Not (Get-Module -Name ExchangeOnlineManagement)) {
    Install-Module -Name ExchangeOnlineManagement -Force
}
Update-Module -Name ExchangeOnlineManagement
Import-Module ActiveDirectory
Import-Module ExchangeOnlineManagement
function New-RandomString($length=15)
{
    $Assembly = Add-Type -AssemblyName System.Web
    $securepassword = [System.Web.Security.Membership]::GeneratePassword($length,2)
    return $securepassword
}

$securepassword = New-RandomString

$AzureADConnectHost = "AD"

Function CreateNewUser($GivenName, $Surname)
{
		
		$GivenName = Read-Host "Please enter the employee's first name";
		$Surname = Read-Host "Please enter the employee's last name";
		$Title = Read-Host "Please enter the employee's title";
		$username=$GivenName.substring(0,1)+$Surname
		$EmailAddress = "$username@example.com";
		$Company = "COMPANY";
		$Path = "OU=Current, OU=O365 Users, OU=O365, DC=example, DC=com";
		$StreetAddress = "STREET ADDRESS";
		$City = "CITY";
		$State = "ST";
		$PostalCode = "00000";
		$OfficePhone = "000-555-1234";
		$FaxNumber = "000-555-1235";
        $Country = "US"
		$GeneralGroups = @("All Staff");
        $Change = Read-Host "Please select the type of change you need to make
        1 Create a Domain Account
        2 Disable a Domain Account
        3 Enable and Unlock a Domain Account
        4 Reset a Domain Account's Password
        "
		Switch ($Change) {
			1	{
				$SpecialGroups = @("Remote Desktop Users")
                New-ADUser -GivenName "$GivenName" -Surname "$Surname" -Name "$GivenName $Surname" -SamAccountName "$username" -UserPrincipalName "$EmailAddress" -ChangePasswordAtLogon $true -AccountPassword (ConvertTo-SecureString –AsPlaintext "$securepassword" –Force) -DisplayName "$GivenName $Surname" -Company "$Company" -StreetAddress "$StreetAddress" -City "$City" -State "$State" -PostalCode "$PostalCode" -Country "$Country" -OfficePhone "$OfficePhone" -Fax "$FaxNumber" -Path $Path -Title "$Title" -EmailAddress $EmailAddress -Enabled $True -ProfilePath "\\FS\profiles\$username" -ScriptPath "logon.bat" -HomeDirectory "\\FS\home\$username" -HomeDrive "Z"
				Set-ADUser -Identity $username -Add @{Proxyaddresses="SMTP:"+$EmailAddress}
				Set-ADUser -Identity $username -Add @{Proxyaddresses="SIP:"+$EmailAddress}
				Write-Host "The temporary Domain Account password for $GivenName $Surname is $securepassword"
				ForEach ($GeneralGroup in $GeneralGroups) {
	                Add-ADGroupMember -Identity $GeneralGroup -Members $username
					}
				ForEach ($SpecialGroup in $SpecialGroups) {
					Add-ADGroupMember -Identity $SpecialGroup -Members $username
					}
			}
            2	{
				Disable-ADAccount -Identity $username
				Set-ADAccountPassword -Identity $username -Reset -NewPassword (ConvertTo-SecureString –AsPlaintext "$securepassword" –Force)
			}
			3	{
                Enable-ADAccount -Identity $username		
                Unlock-ADAccount -Identity $username
			}
			4	{
				Set-ADAccountPassword -Identity $username -Reset -NewPassword (ConvertTo-SecureString –AsPlaintext "$securepassword" –Force)
                Write-Host "The temporary Domain Account password for $GivenName $Surname is $securepassword"
			}
		}
		Invoke-Command -ComputerName $AzureADConnectHost -ScriptBlock {
			Import-Module ADSync
			Start-ADSyncSyncCycle -PolicyType Delta
		}
}
CreateNewUser