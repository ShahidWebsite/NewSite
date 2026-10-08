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
git commit -m "support multiple bank accounts at checkout, add Admin -> Bank Accounts screen"
git push origin main

Write-Host ""
Write-Host "Done. Check https://vercel.com for the new deployment in a minute or two."
Write-Host ""
Write-Host "===== ONE MORE STEP ====="
Write-Host "Open Supabase -> SQL Editor -> paste the contents of migration-bank-accounts.sql"
Write-Host "(in this same update) -> click Run. This adds both bank accounts you sent me:"
Write-Host "  Meezan Bank - Shahid Iqbal - 02850106669725"
Write-Host "  Standard Chartered - Shahid Iqbal - 01165940201"
Write-Host "Safe to re-run if you're ever unsure whether it already ran."
Write-Host ""
Write-Host "After that, go to Admin -> Bank Accounts on the live site to check both look right,"
Write-Host "reorder them, or add more banks any time - no more editing Supabase by hand for this."
