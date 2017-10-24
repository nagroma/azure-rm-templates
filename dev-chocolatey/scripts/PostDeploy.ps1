Set-Location $env:userprofile\desktop
git clone https://github.com/Microsoft/PartsUnlimited.git
Remove-Item .\PartsUnlimited\src\PartsUnlimitedWebsite\node_modules -Force -Recurse
