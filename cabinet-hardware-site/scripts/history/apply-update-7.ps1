$zipPath = "$HOME\Downloads\cabinet-hardware-site.zip"
$repoPath = "$HOME\Desktop\NewSite\cabinet-hardware-site"
$tempExtract = "$HOME\Downloads\_update-temp"

cd "$HOME\Desktop\NewSite"
git pull origin main

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
git commit -m "add homepage testimonials from Facebook reviews, allow reviews without a product"
git push origin main

Write-Host ""
Write-Host "Done. Check https://vercel.com for the new deployment in a minute or two."
Write-Host ""
Write-Host "===== ONE MORE STEP ====="
Write-Host "Open Supabase -> SQL Editor -> paste the contents of migration-testimonials.sql"
Write-Host "(in this same update) -> click Run. This adds the 7 reviews from Facebook."
Write-Host "Safe to re-run if you're ever unsure whether it already ran."
