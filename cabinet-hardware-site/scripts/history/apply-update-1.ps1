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
git commit -m "fix logo transparency, add photo upload, show/hide password, fix swatch contrast"
git push origin main

Write-Host ""
Write-Host "Done. Check https://vercel.com for the new deployment in a minute or two."
Write-Host "IMPORTANT: also run storage-setup.sql once in Supabase's SQL Editor if you haven't -"
Write-Host "this is a new file needed for photo uploads to work."