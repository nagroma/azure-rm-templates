param([Parameter(Mandatory=$true)][string]$chocoPackages)
cls

New-Item "c:\choco" -type Directory -force | Out-Null
$LogFile = "c:\choco\JDScript.log"
$chocoPackages | Out-File $LogFile -Append

# Get username/password & machine name
$userName = "artifactInstaller"
[Reflection.Assembly]::LoadWithPartialName("System.Web") | Out-Null
$password = $([System.Web.Security.Membership]::GeneratePassword(12,4))
$cn = [ADSI]"WinNT://$env:ComputerName"

# Create new user
$user = $cn.Create("User", $userName)
$user.SetPassword($password)
$user.SetInfo()
$user.description = "Choco artifact installer"
$user.SetInfo()

# Add user to the Administrators group
$group = [ADSI]"WinNT://$env:ComputerName/Administrators,group"
$group.add("WinNT://$env:ComputerName/$userName")

# Create pwd and new $creds for remoting
$secPassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential("$env:COMPUTERNAME\$($username)", $secPassword)

# Ensure that current process can run scripts. 
#"Enabling remoting" | Out-File $LogFile -Append
Enable-PSRemoting -Force -SkipNetworkProfileCheck

#"Changing ExecutionPolicy" | Out-File $LogFile -Append
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

#"Install each Chocolatey Package"
$chocoPackages.Split(";") | ForEach {
    $command = "cinst " + $_ + " -y -force"
    $command | Out-File $LogFile -Append
    $sb = [scriptblock]::Create("$command")

    # Use the current user profile
    Invoke-Command -ScriptBlock $sb -ArgumentList $chocoPackages -ComputerName $env:COMPUTERNAME -Credential $credential | Out-Null
}

Invoke-Command -ScriptBlock {refreshenv} -ComputerName $env:COMPUTERNAME -Credential $credential | Out-Null
Invoke-Command -ScriptBlock {npm install -g bower} -ComputerName $env:COMPUTERNAME -Credential $credential | Out-Null
Invoke-Command -ScriptBlock {npm install -g grunt-cli} -ComputerName $env:COMPUTERNAME -Credential $credential | Out-Null
Invoke-Command -ScriptBlock {Copy-Item C:\Python27\python.exe C:\Python27\python2.exe} -ComputerName $env:COMPUTERNAME -Credential $credential | Out-Null
Invoke-Command -ScriptBlock {Set-Location C:\} -ComputerName $env:COMPUTERNAME -Credential $credential | Out-Null
Invoke-Command -ScriptBlock {git clone https://github.com/Microsoft/PartsUnlimited.git} -ComputerName $env:COMPUTERNAME -Credential $credential | Out-Null
Invoke-Command -ScriptBlock {Remove-Item .\PartsUnlimited\src\PartsUnlimitedWebsite\node_modules -Force -Recurse} -ComputerName $env:COMPUTERNAME -Credential $credential | Out-Null

Disable-PSRemoting -Force

# Delete the artifactInstaller user
$cn.Delete("User", $userName)

# Delete the artifactInstaller user profile
gwmi win32_userprofile | where { $_.LocalPath -like "*$userName*" } | foreach { $_.Delete() }
