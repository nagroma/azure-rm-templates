Param(
    [Parameter(Mandatory=$true)][string]$chocoPackages,
    [Parameter(Mandatory=$true)][string]$vmAdminUserName,
    [Parameter(Mandatory=$true)][string]$vmAdminPassword
    )

cls

New-Item "c:\choco" -type Directory -force | Out-Null
$LogFile = "c:\choco\Script.log"
$chocoPackages | Out-File $LogFile -Append
$vmAdminUserName | Out-File $LogFile -Append
$vmAdminPassword | Out-File $LogFile -Append

$secPassword = ConvertTo-SecureString $vmAdminPassword -AsPlainText -Force		
$credential = New-Object System.Management.Automation.PSCredential("$env:COMPUTERNAME\$($vmAdminUserName)", $secPassword)

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

$AddedLocation ="$env:userprofile\AppData\Roaming\npm"
$Reg = "Registry::HKLM\System\CurrentControlSet\Control\Session Manager\Environment"
$OldPath = (Get-ItemProperty -Path "$Reg" -Name PATH).Path
"OldPath: $OldPath" | Out-File $LogFile -Append
$NewPath= $OldPath + ’;’ + $AddedLocation
Set-ItemProperty -Path "$Reg" -Name PATH –Value $NewPath
$UpdatedPath = (Get-ItemProperty -Path "$Reg" -Name PATH).Path
"UpdatedPath: $UpdatedPath" | Out-File $LogFile -Append

Invoke-Command -ScriptBlock {refreshenv} -ComputerName $env:COMPUTERNAME -Credential $credential | Out-File $LogFile -Append
Invoke-Command -ScriptBlock {npm install bower -g} -ComputerName $env:COMPUTERNAME -Credential $credential | Out-File $LogFile -Append
Invoke-Command -ScriptBlock {npm install grunt-cli -g} -ComputerName $env:COMPUTERNAME -Credential $credential | Out-File $LogFile -Append
Invoke-Command -ScriptBlock {npm install -g grunt-cli} -ComputerName $env:COMPUTERNAME -Credential $credential | Out-File $LogFile -Append
Invoke-Command -ScriptBlock {Copy-Item C:\Python27\python.exe C:\Python27\python2.exe} -ComputerName $env:COMPUTERNAME -Credential $credential | Out-File $LogFile -Append
Invoke-Command -ScriptBlock {New-Item c:\PartsUnlimitedHOL -type directory -force} -ComputerName $env:COMPUTERNAME -Credential $credential | Out-File $LogFile -Append
Invoke-Command -ScriptBlock {CD C:\PartsUnlimitedHOL\} -ComputerName $env:COMPUTERNAME -Credential $credential | Out-File $LogFile -Append
Invoke-Command -ScriptBlock {git clone https://github.com/Microsoft/PartsUnlimited.git C:\PartsUnlimitedHOL\} -ComputerName $env:COMPUTERNAME -Credential $credential | Out-File $LogFile -Append
#Invoke-Command -ScriptBlock {Remove-Item .\PartsUnlimited\src\PartsUnlimitedWebsite\node_modules -Force -Recurse} -ComputerName $env:COMPUTERNAME -Credential $credential | Out-File $LogFile -Append

Disable-PSRemoting -Force
