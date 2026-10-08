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
git commit -m "add category creation to edit page, sitemap/robots/product SEO, mobile responsiveness, shop filters"
git push origin main

Write-Host ""
Write-Host "Done. Check https://vercel.com for the new deployment in a minute or two."
Write-Host ""
Write-Host "OPTIONAL: add an environment variable NEXT_PUBLIC_SITE_URL in Vercel"
Write-Host "set to https://www.siqbalhwc.com (or whatever domain ends up live) -"
Write-Host "this is used in the new sitemap.xml and robots.txt. Fine to skip for"
Write-Host "now, it just defaults to that address either way."
