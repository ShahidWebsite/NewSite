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
git commit -m "fix logo caching, add edit product page, categories page, dropdown presets"
git push origin main

Write-Host ""
Write-Host "Done. Check https://vercel.com for the new deployment in a minute or two."
Write-Host ""
Write-Host "IMPORTANT MANUAL STEP for photo uploads to work:"
Write-Host "1. Go to Supabase -> Storage -> New bucket -> name it exactly: product-images -> turn ON Public bucket -> Save"
Write-Host "2. Then run the UPDATED storage-setup.sql once in Supabase's SQL Editor (it only sets permissions now, bucket is made in step 1)"