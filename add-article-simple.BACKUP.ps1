# ========================================
# SCRIPT OFICIAL: Adicionar Artigo do Medium (SEM DEPENDÊNCIAS)
# ========================================
#
# Este script NÃO requer medium-2-md ou outras dependências externas!
# Faz parsing direto do HTML exportado do Medium.
#
# USO:
#   1. Exportar artigo do Medium (Settings > Download your information)
#   2. Copiar arquivo .html para: medium-export/
#   3. Executar: .\add-article-simple.ps1
#
# ========================================

param(
    [string]$HtmlFile = "",
    [switch]$Help
)

# Cores
$ColorInfo = "Cyan"
$ColorSuccess = "Green"
$ColorWarning = "Yellow"
$ColorError = "Red"
$ColorStep = "Magenta"

# ========================================
# AJUDA
# ========================================
if ($Help) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor $ColorInfo
    Write-Host "  ADICIONAR ARTIGO DO MEDIUM (SIMPLES)" -ForegroundColor $ColorInfo
    Write-Host "========================================" -ForegroundColor $ColorInfo
    Write-Host ""
    Write-Host "USO:" -ForegroundColor $ColorStep
    Write-Host "  .\add-article-simple.ps1                    # Processa todos os .html"
    Write-Host "  .\add-article-simple.ps1 -HtmlFile nome.html # Arquivo específico"
    Write-Host ""
    Write-Host "VANTAGENS:" -ForegroundColor $ColorStep
    Write-Host "  ✅ SEM dependências externas"
    Write-Host "  ✅ Parsing direto do HTML"
    Write-Host "  ✅ Mais rápido e confiável"
    Write-Host ""
    exit
}

# ========================================
# INÍCIO
# ========================================
Write-Host ""
Write-Host "========================================" -ForegroundColor $ColorInfo
Write-Host "  CONVERSÃO DE ARTIGO DO MEDIUM" -ForegroundColor $ColorInfo
Write-Host "========================================" -ForegroundColor $ColorInfo
Write-Host ""

# Verificar pasta
if (-not (Test-Path "medium-export")) {
    Write-Host "❌ Pasta 'medium-export' não encontrada!" -ForegroundColor $ColorError
    Write-Host "Criar: mkdir medium-export" -ForegroundColor $ColorWarning
    exit 1
}

# Encontrar arquivos
Write-Host "📂 Procurando arquivos HTML..." -ForegroundColor $ColorStep

$htmlFilePaths = @()
if ($HtmlFile) {
    $fullPath = Join-Path (Get-Location) "medium-export\$HtmlFile"
    if (Test-Path $fullPath) {
        $htmlFilePaths += $fullPath
    }
    else {
        Write-Host "❌ Arquivo não encontrado: $HtmlFile" -ForegroundColor $ColorError
        exit 1
    }
}
else {
    $htmlFilePaths = (Get-ChildItem -Path "medium-export\*.html" -File).FullName
}

if ($htmlFilePaths.Count -eq 0) {
    Write-Host "❌ Nenhum arquivo .html encontrado" -ForegroundColor $ColorError
    exit 1
}

Write-Host "✅ Encontrados $($htmlFilePaths.Count) arquivo(s)" -ForegroundColor $ColorSuccess

# ========================================
# PROCESSAR CADA ARQUIVO
# ========================================
$processedCount = 0

foreach ($htmlFilePath in $htmlFilePaths) {
    $htmlFile = Get-Item $htmlFilePath
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor $ColorInfo
    Write-Host "  PROCESSANDO: $($htmlFile.Name)" -ForegroundColor $ColorInfo
    Write-Host "========================================" -ForegroundColor $ColorInfo
    
    try {
        # ========================================
        # PASSO 1: Ler HTML
        # ========================================
        Write-Host ""
        Write-Host "📄 [1/5] Lendo HTML..." -ForegroundColor $ColorStep
        
        $htmlContent = Get-Content -Path $htmlFilePath -Raw -Encoding UTF8
        
        if (-not $htmlContent) {
            throw "Arquivo HTML vazio ou não pôde ser lido"
        }
        
        # ========================================
        # PASSO 2: Extrair Metadados
        # ========================================
        Write-Host "📋 [2/5] Extraindo metadados..." -ForegroundColor $ColorStep
        
        # Título
        if ($htmlContent -match '<h1 class="p-name">([^<]+)</h1>') {
            $title = $matches[1].Trim()
        }
        else {
            $title = $htmlFile.BaseName
        }
        
        # Subtítulo/Descrição
        if ($htmlContent -match '<section data-field="subtitle"[^>]*>([^<]+)</section>') {
            $description = $matches[1].Trim()
        }
        else {
            $description = ""
        }
        
        # URL Canônica
        if ($htmlContent -match '<a href="([^"]+)" class="p-canonical">') {
            $canonicalUrl = $matches[1]
        }
        else {
            $canonicalUrl = ""
        }
        
        # Data
        if ($htmlContent -match '<time[^>]+datetime="([^"]+)"') {
            $dateStr = $matches[1]
            $date = [DateTime]::Parse($dateStr).ToString("yyyy-MM-dd")
        }
        else {
            $date = (Get-Date).ToString("yyyy-MM-dd")
        }
        
        Write-Host "  📌 Título: $title" -ForegroundColor Gray
        Write-Host "  📅 Data: $date" -ForegroundColor Gray
        
        # ========================================
        # PASSO 3: Extrair Conteúdo
        # ========================================
        Write-Host "✏️  [3/5] Extraindo conteúdo..." -ForegroundColor $ColorStep
        
        # Extrair seção de conteúdo (usando regex com Singleline para pegar quebras de linha)
        $bodyMatch = [regex]::Match($htmlContent, '<section data-field="body"[^>]*>(.*?)</section>\s*</section>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        
        if ($bodyMatch.Success) {
            $bodyHtml = $bodyMatch.Groups[1].Value
        }
        else {
            # Tentar padrão alternativo
            $bodyMatch = [regex]::Match($htmlContent, '<section data-field="body"[^>]*>(.*)', [System.Text.RegularExpressions.RegexOptions]::Singleline)
            if ($bodyMatch.Success) {
                $bodyHtml = $bodyMatch.Groups[1].Value
                $markdown = $markdown -replace '<img[^>]*>', ''
        
                # Headings (processar antes de parágrafos)
                $markdown = $markdown -replace '<h3[^>]*>([^<]+)</h3>', "`n### `$1`n"
                $markdown = $markdown -replace '<h2[^>]*>([^<]+)</h2>', "`n## `$1`n"
                $markdown = $markdown -replace '<h1[^>]*>([^<]+)</h1>', "`n# `$1`n"
        
                # Links (processar antes de parágrafos)
                $markdown = $markdown -replace '<a[^>]+href="([^"]+)"[^>]*>([^<]+)</a>', '[$2]($1)'
        
                # Bold e Italic (processar antes de parágrafos)
                $markdown = $markdown -replace '<strong[^>]*>([^<]+)</strong>', '**$1**'
                $markdown = $markdown -replace '<em[^>]*>([^<]+)</em>', '*$1*'
        
                # Parágrafos (remover tags mas manter conteúdo)
                $markdown = $markdown -replace '<p[^>]*>', ''
                $markdown = $markdown -replace '</p>', "`n`n"
        
                # Remover outras tags HTML
                $markdown = $markdown -replace '</?div[^>]*>', ''
                $markdown = $markdown -replace '</?section[^>]*>', ''
                $markdown = $markdown -replace '</?figure[^>]*>', ''
                $markdown = $markdown -replace '</?span[^>]*>', ''
                $markdown = $markdown -replace '<hr[^>]*>', "`n---`n"
        
                # Limpar atributos HTML restantes (class, id, name)
                $markdown = $markdown -replace '\s+(class|id|name)="[^"]*"', ''
        
                # Limpar espaços extras
                $markdown = $markdown -replace '\n\s*\n\s*\n+', "`n`n"
                $markdown = $markdown -replace '^\s+', ''
                $markdown = $markdown -replace '\s+$', ''
                $markdown = $markdown.Trim()
        
                # ========================================
                # PASSO 4: Criar Page Bundle
                # ========================================
                Write-Host "📦 [4/5] Criando Page Bundle..." -ForegroundColor $ColorStep
        
                # Gerar slug
                $slug = $title -replace '[^a-zA-Z0-9\s-]', '' -replace '\s+', '-' -replace '--+', '-'
                $slug = $slug.ToLower().Substring(0, [Math]::Min(50, $slug.Length))
                $slug = $slug -replace '^-|-$', ''
        
                $bundlePath = "content\posts\$slug"
                $imagesPath = "$bundlePath\images"
        
                # Criar estrutura
                New-Item -ItemType Directory -Path $bundlePath -Force | Out-Null
                New-Item -ItemType Directory -Path $imagesPath -Force | Out-Null
        
                Write-Host "  ✅ Bundle: $bundlePath" -ForegroundColor $ColorSuccess
        
                # ========================================
                # PASSO 5: Baixar Imagens e Criar Markdown Final
                # ========================================
                Write-Host "🖼️  [5/5] Processando imagens..." -ForegroundColor $ColorStep
        
                # Frontmatter (sem --- duplicado)
                $finalMarkdown = @"
---
title: "$title"
date: $date
description: "$description"
canonicalUrl: "$canonicalUrl"
image: "images/hero.png"
---

"@
        
                # Processar imagens e inserir no markdown
                $imageIndex = 1
                $heroSet = $false
        
                foreach ($img in $images) {
                    try {
                        # Nome do arquivo
                        $extension = if ($img.Url -match '\.(jpg|jpeg|png|gif|webp)') { $matches[1] } else { "png" }
                        $imageName = if (-not $heroSet) { "hero.$extension" } else { "image-$imageIndex.$extension" }
                        $imagePath = Join-Path $imagesPath $imageName
                
                        # Baixar
                        Write-Host "    Baixando $imageName..." -ForegroundColor Gray -NoNewline
                
                        $webClient = New-Object System.Net.WebClient
                        $webClient.Headers.Add("User-Agent", "Mozilla/5.0")
                        $webClient.DownloadFile($img.Url, $imagePath)
                
                        Write-Host " ✅" -ForegroundColor $ColorSuccess
                
                        # Adicionar ao markdown
                        $finalMarkdown += "`n{{< img-advanced src=`"images/$imageName`" alt=`"$($img.Alt)`" >}}`n`n"
                
                        if (-not $heroSet) { $heroSet = $true }
                        $imageIndex++
                
                    }
                    catch {
                        Write-Host " ⚠️ Falhou" -ForegroundColor $ColorWarning
                        # Usar ImageKit fallback
                        $finalMarkdown += "`n{{< img src=`"$($img.Url)`" alt=`"$($img.Alt)`" >}}`n`n"
                    }
                }
        
                # Adicionar conteúdo de texto
                $finalMarkdown += $markdown
        
                # Salvar
                $indexPath = Join-Path $bundlePath "index.md"
                Set-Content -Path $indexPath -Value $finalMarkdown -Encoding UTF8 -NoNewline
        
                Write-Host ""
                Write-Host "✅ SUCESSO: $($htmlFile.Name)" -ForegroundColor $ColorSuccess
                Write-Host "   📁 $bundlePath" -ForegroundColor Gray
        
                $processedCount++
        
            }
            catch {
                Write-Host ""
                Write-Host "❌ ERRO: $_" -ForegroundColor $ColorError
            }
        }

        # ========================================
        # RESUMO
        # ========================================
        Write-Host ""
        Write-Host "========================================" -ForegroundColor $ColorInfo
        Write-Host "  RESUMO" -ForegroundColor $ColorInfo
        Write-Host "========================================" -ForegroundColor $ColorInfo
        Write-Host ""
        Write-Host "  ✅ Processados: $processedCount" -ForegroundColor $ColorSuccess
        Write-Host ""

        if ($processedCount -gt 0) {
            Write-Host "🚀 PRÓXIMOS PASSOS:" -ForegroundColor $ColorStep
            Write-Host ""
            Write-Host "  1. Testar:" -ForegroundColor White
            Write-Host "     .\hugo.exe server" -ForegroundColor Cyan
            Write-Host "  2. Acessar: http://localhost:1313" -ForegroundColor White
            Write-Host "  3. Publicar:" -ForegroundColor White
            Write-Host "     git add ." -ForegroundColor Cyan
            Write-Host "     git commit -m `"feat: Add article`"" -ForegroundColor Cyan
            Write-Host "     git push origin main" -ForegroundColor Cyan
            Write-Host ""
        }
