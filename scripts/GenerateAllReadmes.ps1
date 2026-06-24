$modules = Get-ChildItem -Directory | Where-Object {
  Test-Path (Join-Path $_.FullName "Fontes")
}

foreach ($module in $modules) {

  $fontesPath = Join-Path $module.FullName "Fontes"

  if (Test-Path $fontesPath) {

    $readmePath = Join-Path $module.FullName "README.md"

    $files = Get-ChildItem $fontesPath -Recurse -File |
    Where-Object { $_.Extension -in ".prw", ".tlpp" } |
    Sort-Object DirectoryName, Name

    $moduleTitle = $module.Name `
      -replace "modulo-", "" `
      -replace "-", " " `
      -replace "\s+", " "

    $moduleTitle = (Get-Culture).TextInfo.ToTitleCase($moduleTitle.Trim())

    # Monta linhas da tabela (mais eficiente e limpo)
    $rows = foreach ($file in $files) {
      $name = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
      "| $name |"
    }

    $content = @"
# Modulo $moduleTitle

Repositorio dos fontes customizados do modulo.

---

| Fonte |
|------|
$($rows -join "`n")
"@

    Set-Content -Path $readmePath -Value $content -Encoding UTF8

    Write-Host "README atualizado:" $module.Name
  }
}