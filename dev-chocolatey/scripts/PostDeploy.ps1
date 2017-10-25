Param(
    [Parameter(Mandatory=$true)][string]$ChocoPackages,
    [Parameter(Mandatory=$true)][string]$VmAdminUserName,
    [Parameter(Mandatory=$true)][string]$VmAdminPassword
    )

cls

New-Item "c:\choco" -type Directory -force | Out-Null
$LogFile = "c:\choco\Script.log"
$ChocoPackages | Out-File $LogFile -Append
$VmAdminUserName | Out-File $LogFile -Append
$VmAdminPassword | Out-File $LogFile -Append

$secPassword = ConvertTo-SecureString $VmAdminPassword -AsPlainText -Force		
$credential = New-Object System.Management.Automation.PSCredential("$env:COMPUTERNAME\$($VmAdminUserName)", $secPassword)

# Ensure that current process can run scripts. 
#"Enabling remoting" | Out-File $LogFile -Append
Enable-PSRemoting -Force -SkipNetworkProfileCheck

#"Changing ExecutionPolicy" | Out-File $LogFile -Append
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

#"Install each Chocolatey Package"
$ChocoPackages.Split(";") | ForEach {
    $command = "cinst " + $_ + " -y -force"
    $command | Out-File $LogFile -Append
    $sb = [scriptblock]::Create("$command")

    # Use the current user profile
    Invoke-Command -ScriptBlock $sb -ArgumentList $ChocoPackages -ComputerName $env:COMPUTERNAME -Credential $credential | Out-Null
}

$AddedLocation ="$env:userprofile\AppData\Roaming\npm"
$Reg = "Registry::HKLM\System\CurrentControlSet\Control\Session Manager\Environment"
$OldPath = (Get-ItemProperty -Path "$Reg" -Name PATH).Path
"OldPath: $OldPath" | Out-File $LogFile -Append
$NewPath= $OldPath + ';' + $AddedLocation
Invoke-Command -ScriptBlock {Set-ItemProperty -Path "$Reg" -Name PATH -Value $NewPath} -ComputerName $env:COMPUTERNAME -Credential $credential | Out-File $LogFile -Append
$UpdatedPath = (Get-ItemProperty -Path "$Reg" -Name PATH).Path
"UpdatedPath: $UpdatedPath" | Out-File $LogFile -Append

$slnPath = "C:\PartsUnlimitedHOL"

Invoke-Command -ScriptBlock {refreshenv} -ComputerName $env:COMPUTERNAME -Credential $credential | Out-File $LogFile -Append
Invoke-Command -ScriptBlock {npm install bower -g} -ComputerName $env:COMPUTERNAME -Credential $credential | Out-File $LogFile -Append
Invoke-Command -ScriptBlock {npm install grunt-cli -g} -ComputerName $env:COMPUTERNAME -Credential $credential | Out-File $LogFile -Append
Invoke-Command -ScriptBlock {npm install -g grunt-cli} -ComputerName $env:COMPUTERNAME -Credential $credential | Out-File $LogFile -Append
Invoke-Command -ScriptBlock {Copy-Item C:\Python27\python.exe C:\Python27\python2.exe} -ComputerName $env:COMPUTERNAME -Credential $credential | Out-File $LogFile -Append
Invoke-Command -ScriptBlock {New-Item $slnPath -type directory -force} -ComputerName $env:COMPUTERNAME -Credential $credential | Out-File $LogFile -Append
Invoke-Command -ScriptBlock {CD $slnPath} -ComputerName $env:COMPUTERNAME -Credential $credential | Out-File $LogFile -Append
Invoke-Command -ScriptBlock {git clone https://github.com/Microsoft/PartsUnlimited.git $slnPath\} -ComputerName $env:COMPUTERNAME -Credential $credential | Out-File $LogFile -Append
#Invoke-Command -ScriptBlock {Remove-Item .\PartsUnlimited\src\PartsUnlimitedWebsite\node_modules -Force -Recurse} -ComputerName $env:COMPUTERNAME -Credential $credential | Out-File $LogFile -Append

#A few more settings that I like but are not required for the PartsUnlimitedHOL
# Show file extensions (have to restart Explorer for this to take effect if run maually - Stop-Process -processName: Explorer -force)
Invoke-Command -ScriptBlock {Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name HideFileExt -Value "0"} -ComputerName $env:COMPUTERNAME -Credential $credential | Out-File $LogFile -Append

Invoke-Command -ScriptBlock {buildVS "$slnPath\PartsUnlimited.sln" -nuget $true -clean $false} -ComputerName $env:COMPUTERNAME -Credential $credential | Out-File $LogFile -Append

Remove-Item .\PartsUnlimited\src\PartsUnlimitedWebsite\node_modules -Force -Recurse

Invoke-Command -ScriptBlock {buildVS "$slnPath\PartsUnlimited.sln" -nuget $true -clean $true} -ComputerName $env:COMPUTERNAME -Credential $credential | Out-File $LogFile -Append

Disable-PSRemoting -Force

function buildVS 
{
    param
    (
        [parameter(Mandatory=$true)]
        [String] $path,

        [parameter(Mandatory=$false)]
        [bool] $nuget = $true,
        
        [parameter(Mandatory=$false)]
        [bool] $clean = $true
    )
    process
    {
        $msBuildExe = 'C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\msbuild.exe'

        if ($nuget) {
            Write-Host "Restoring NuGet packages" -foregroundcolor green
            nuget restore "$($path)"
        }

        if ($clean) {
            Write-Host "Cleaning $($path)" -foregroundcolor green
            & "$($msBuildExe)" "$($path)" /t:Clean /m
        }

        Write-Host "Building $($path)" -foregroundcolor green
        & "$($msBuildExe)" "$($path)" /t:Build /m
    }
}
