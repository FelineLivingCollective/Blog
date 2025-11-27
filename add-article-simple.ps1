# ========================================
# SCRIPT OFICIAL: Adicionar Artigo do Medium
# ========================================
# Versão 3.0 - Com posicionamento correto de imagens
# SEM dependências externas (medium-2-md)
#
# MELHORIAS v3.0:
#   ✅ Imagens intercaladas no texto (não mais todas no topo)
#   ✅ Sistema de placeholders para preservar posições
#   ✅ Extração de imagens melhorada
#   ✅ Limpeza completa de HTML
#   ✅ Fallback automático ImageKit
#
# USO:
#   .\add-article-simple.ps1
#   .\add-article-simple.ps1 -HtmlFile "artigo.html"
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
    Write-Host "  ADICIONAR ARTIGO DO MEDIUM" -ForegroundColor $ColorInfo
    Write-Host "========================================" -ForegroundColor $ColorInfo
    Write-Host ""
    Write-Host "USO:" -ForegroundColor $ColorStep
    Write-Host "  .\add-article-simple.ps1                    # Todos os .html"
    Write-Host "  .\add-article-simple.ps1 -HtmlFile nome.html # Específico"
    Write-Host ""
    Write-Host "NOVIDADE v3.0:" -ForegroundColor $ColorStep
    Write-Host "  ✅ Imagens aparecem nas posições corretas do texto!"
    Write-Host ""
    exit
}

# ========================================
# INÍCIO
# ========================================
Write-Host ""
Write-Host "========================================" -ForegroundColor $ColorInfo
Write-Host "  CONVERSÃO DE ARTIGO DO MEDIUM v3.0" -ForegroundColor $ColorInfo
Write-Host "========================================" -ForegroundColor $ColorInfo
Write-Host ""

# Verificar pasta
if (-not (Test-Path "medium-export")) {
    Write-Host "❌ Pasta 'medium-export' não encontrada!" -ForegroundColor $ColorError
    Write-Host "   Criar: mkdir medium-export" -ForegroundColor $ColorWarning
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
            throw "Arquivo HTML vazio"
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
        
        # Descrição
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
        # PASSO 3: Extrair Conteúdo e Imagens
        # ========================================
        Write-Host "✏️  [3/5] Extraindo conteúdo..." -ForegroundColor $ColorStep
        
        # Extrair body
        $bodyMatch = [regex]::Match($htmlContent, '<section data-field="body"[^>]*>(.*?)</section>\s*</section>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        
        if ($bodyMatch.Success) {
            $bodyHtml = $bodyMatch.Groups[1].Value
        }
        else {
            $bodyMatch = [regex]::Match($htmlContent, '<section data-field="body"[^>]*>(.*)', [System.Text.RegularExpressions.RegexOptions]::Singleline)
            if ($bodyMatch.Success) {
                $bodyHtml = $bodyMatch.Groups[1].Value
            }
            else {
                throw "Não foi possível extrair o conteúdo"
            }
        }
        
        # Extrair imagens e criar placeholders
        $images = @()
        $imageMatches = [regex]::Matches($bodyHtml, '<img[^>]+src="([^"]+)"[^>]*alt="([^"]*)"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        
        $imageIndex = 0
        foreach ($match in $imageMatches) {
            $placeholder = "___IMAGE_PLACEHOLDER_${imageIndex}___"
            $images += @{
                Url         = $match.Groups[1].Value
                Alt         = $match.Groups[2].Value
                Placeholder = $placeholder
            }
            $imageIndex++
        }
        
        # Se não encontrou com alt, tentar sem alt
        if ($images.Count -eq 0) {
            $imageMatches = [regex]::Matches($bodyHtml, '<img[^>]+src="([^"]+)"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            $imageIndex = 0
            foreach ($match in $imageMatches) {
                $placeholder = "___IMAGE_PLACEHOLDER_${imageIndex}___"
                $images += @{
                    Url         = $match.Groups[1].Value
                    Alt         = ""
                    Placeholder = $placeholder
                }
                $imageIndex++
            }
        }
        
        Write-Host "  📸 Encontradas $($images.Count) imagens" -ForegroundColor Gray
        
        # Substituir imagens por placeholders no HTML
        $markdown = $bodyHtml
        foreach ($img in $images) {
            # Substituir primeira ocorrência de <img> pelo placeholder
            $pattern = '<img[^>]*>'
            $pos = $markdown.IndexOf('<img')
            if ($pos -ge 0) {
                $endPos = $markdown.IndexOf('>', $pos) + 1
                $imgTag = $markdown.Substring($pos, $endPos - $pos)
                $markdown = $markdown.Remove($pos, $endPos - $pos).Insert($pos, $img.Placeholder)
            }
        }
        
        # Processar HTML para Markdown
        # Headings
        $markdown = $markdown -replace '<h3[^>]*>([^<]+)</h3>', "`n### `$1`n"
        $markdown = $markdown -replace '<h2[^>]*>([^<]+)</h2>', "`n## `$1`n"
        $markdown = $markdown -replace '<h1[^>]*>([^<]+)</h1>', "`n# `$1`n"
        
        # Links
        $markdown = $markdown -replace '<a[^>]+href="([^"]+)"[^>]*>([^<]+)</a>', '[$2]($1)'
        
        # Bold/Italic
        $markdown = $markdown -replace '<strong[^>]*>([^<]+)</strong>', '**$1**'
        $markdown = $markdown -replace '<em[^>]*>([^<]+)</em>', '*$1*'
        
        # Parágrafos
        $markdown = $markdown -replace '<p[^>]*>', ''
        $markdown = $markdown -replace '</p>', "`n`n"
        
        # Remover outras tags
        $markdown = $markdown -replace '</?div[^>]*>', ''
        $markdown = $markdown -replace '</?section[^>]*>', ''
        $markdown = $markdown -replace '</?figure[^>]*>', ''
        $markdown = $markdown -replace '</?span[^>]*>', ''
        $markdown = $markdown -replace '<hr[^>]*>', "`n---`n"
        
        # Limpar atributos
        $markdown = $markdown -replace '\s+(class|id|name)="[^"]*"', ''
        
        # Limpar espaços (usar \\n para literal newline em regex)
        $markdown = $markdown -replace '\\n\\s*\\n\\s*\\n+', "`n`n"
        $markdown = $markdown.Trim()
        
        # ========================================
        # PASSO 4: Criar Page Bundle
        # ========================================
        Write-Host "📦 [4/5] Criando Page Bundle..." -ForegroundColor $ColorStep
        
        # Gerar slug
        $slug = $title -replace '[^a-zA-Z0-9\s-]', '' -replace '\s+', '-' -replace '--+', '-'
        $slug = $slug.ToLower()
        if ($slug.Length -gt 50) {
            $slug = $slug.Substring(0, 50)
        }
        $slug = $slug -replace '^-|-$', ''
        
        $bundlePath = "content\posts\$slug"
        $imagesPath = "$bundlePath\images"
        
        # Criar diretórios
        New-Item -ItemType Directory -Path $bundlePath -Force | Out-Null
        New-Item -ItemType Directory -Path $imagesPath -Force | Out-Null
        
        Write-Host "  ✅ Bundle: $bundlePath" -ForegroundColor $ColorSuccess
        
        # ========================================
        # PASSO 5: Processar Imagens e Substituir Placeholders
        # ========================================
        Write-Host "🖼️  [5/5] Processando imagens..." -ForegroundColor $ColorStep
        
        # Criar frontmatter
        $finalMarkdown = "---`n"
        $finalMarkdown += "title: `"$title`"`n"
        $finalMarkdown += "date: $date`n"
        $finalMarkdown += "description: `"$description`"`n"
        $finalMarkdown += "canonicalUrl: `"$canonicalUrl`"`n"
        $finalMarkdown += "image: `"images/hero.png`"`n"
        $finalMarkdown += "---`n`n"
        
        # Adicionar markdown com placeholders
        $finalMarkdown += $markdown
        
        # Substituir placeholders por shortcodes
        $imageIndex = 1
        $heroSet = $false
        
        foreach ($img in $images) {
            try {
                # Determinar extensão
                $extension = "png"
                if ($img.Url -match '\.([a-z]{3,4})(\?|$)') {
                    $extension = $matches[1]
                }
                
                # Nome do arquivo
                if (-not $heroSet) {
                    $imageName = "hero.$extension"
                    $heroSet = $true
                }
                else {
                    $imageName = "image-$imageIndex.$extension"
                    $imageIndex++
                }
                
                $imagePath = Join-Path $imagesPath $imageName
                
                # Baixar imagem
                Write-Host "    Baixando $imageName..." -ForegroundColor Gray -NoNewline
                
                $webClient = New-Object System.Net.WebClient
                $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
                $webClient.DownloadFile($img.Url, $imagePath)
                
                Write-Host " ✅" -ForegroundColor $ColorSuccess
                
                # Substituir placeholder por shortcode
                $shortcode = "`n`n{{< img-advanced src=`"images/$imageName`" alt=`"$($img.Alt)`" >}}`n`n"
                $finalMarkdown = $finalMarkdown -replace [regex]::Escape($img.Placeholder), $shortcode
                
            }
            catch {
                Write-Host " ⚠️ Falhou" -ForegroundColor $ColorWarning
                # Fallback: ImageKit CDN
                $shortcode = "`n`n{{< img src=`"$($img.Url)`" alt=`"$($img.Alt)`" >}}`n`n"
                $finalMarkdown = $finalMarkdown -replace [regex]::Escape($img.Placeholder), $shortcode
            }
        }
        
        # Salvar arquivo
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
        Write-Host "   Stack: $($_.ScriptStackTrace)" -ForegroundColor Gray
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
    Write-Host "     git commit -m `"feat: Add article from Medium`"" -ForegroundColor Cyan
    Write-Host "     git push origin main" -ForegroundColor Cyan
    Write-Host ""
}
