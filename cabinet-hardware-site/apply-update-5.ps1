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
git commit -m "add search, sort/pagination, product image gallery, reviews, GA4 hook, next/image, about/shipping/returns/privacy/terms pages"
git push origin main

Write-Host ""
Write-Host "Done. Check https://vercel.com for the new deployment in a minute or two."
Write-Host ""
Write-Host "===== ONE MORE STEP (do this before the deploy, order doesn't matter much) ====="
Write-Host "Open Supabase -> SQL Editor -> paste the contents of migration-reviews.sql"
Write-Host "(in this same update) -> click Run. This adds the reviews table."
Write-Host "Safe to re-run if you're ever unsure whether it already ran."
Write-Host ""
Write-Host "===== OPTIONAL: turn on Google Analytics ====="
Write-Host "In Vercel -> Project -> Settings -> Environment Variables, add:"
Write-Host "  NEXT_PUBLIC_GA_ID = your GA4 Measurement ID (looks like G-XXXXXXXXXX)"
Write-Host "Leave it out and the site just runs with no analytics, same as before."
