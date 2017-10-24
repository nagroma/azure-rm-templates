choco install -y nodejs python2 visualstudiocode notepadplusplus googlechrome
refreshenv
npm install -g bower
npm install -g grunt-cli

New-Item C:\PartsUnlimitedHOL -type directory -force
Set-Location C:\PartsUnlimitedHOL
git clone https://github.com/Microsoft/PartsUnlimited.git
Remove-Item .\PartsUnlimited\src\PartsUnlimitedWebsite\node_modules -Force -Recurse
