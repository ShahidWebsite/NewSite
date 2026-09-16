# Run this from INSIDE your cabinet-hardware-site folder (the one on your
# Desktop, already connected to GitHub) — AFTER you've extracted the new
# zip directly into that same folder, overwriting the old files.
#
# Right-click inside the folder -> "Open in Terminal" (or "Open PowerShell
# window here"), then paste these lines in and press Enter.

git add .
git commit -m "fix logo transparency, add photo upload, show/hide password, fix swatch contrast"
git push origin main

Write-Host ""
Write-Host "Done. Check https://vercel.com for the new deployment in a minute or two."
Write-Host "IMPORTANT: also run storage-setup.sql once in Supabase's SQL Editor -"
Write-Host "this is a new file needed for photo uploads to work."
