# Run this from ANYWHERE. Assumes:
#   - cabinet-hardware-site.zip is in your Downloads folder
#   - your git-connected project is at Desktop\NewSite\cabinet-hardware-site
# Edit the two paths below first if either is different on your machine.

$zipPath = "$HOME\Downloads\cabinet-hardware-site.zip"
$repoPath = "$HOME\Desktop\NewSite\cabinet-hardware-site"
$tempExtract = "$HOME\Downloads\_update-temp"

if (Test-Path $tempExtract) { Remove-Item -Recurse -Force $tempExtract }
Expand-Archive -Path $zipPath -DestinationPath $tempExtract -Force

Copy-Item "$tempExtract\cabinet-hardware-site\*" $repoPath -Recurse -Force

cd $repoPath
Write-Host ""
Write-Host "===== Files changed (should NOT be empty): ====="
git status
Write-Host "================================================="
Write-Host ""

git add .
git commit -m "fix homepage being frozen as a static snapshot at build time"
git push origin main

Write-Host ""
Write-Host "Done. Check https://vercel.com for the new deployment in a minute or two."
Write-Host "Once live, your homepage should immediately show the two product photos"
Write-Host "you already uploaded -- no need to re-upload anything."
