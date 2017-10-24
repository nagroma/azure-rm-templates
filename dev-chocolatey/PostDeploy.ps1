choco install -y nodejs python2 visualstudiocode notepadplusplus googlechrome
refreshenv
npm install -g bower
npm install -g grunt-cli

Copy-Item C:\Python27\python.exe C:\Python27\python2.exe
#New-Item $env:userprofile\desktop\PartsUnlimitedHOL -type directory -force
Set-Location $env:userprofile\desktop
git clone https://github.com/Microsoft/PartsUnlimited.git
Remove-Item .\PartsUnlimited\src\PartsUnlimitedWebsite\node_modules -Force -Recurse
