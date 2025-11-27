# ========================================
# SCRIPT OFICIAL: Adicionar Novo Artigo do Medium
# ========================================
# 
# Este é o método RECOMENDADO e OFICIAL para adicionar artigos do Medium ao blog.
# O script automaticamente:
#   1. Converte HTML do Medium para Markdown
#   2. Cria estrutura de Page Bundle
#   3. Baixa e organiza imagens
#   4. Converte shortcodes para img-advanced
#   5. Prepara para otimização WebP automática
#
# REQUISITOS:
#   - Node.js instalado
#   - Pacote medium-2-md instalado globalmente: npm install -g medium-2-md
#
# USO:
#   1. Exportar artigo do Medium (Settings > Download your information)
#   2. Copiar arquivo .html para: medium-export/
#   3. Executar: .\add-medium-article.ps1
#
# ========================================

param(
    [string]$HtmlFile = "",
    [switch]$Help
)

# Cores para output
$ColorInfo = "Cyan"
$ColorSuccess = "Green"
$ColorWarning = "Yellow"
$ColorError = "Red"
$ColorStep = "Magenta"

# ========================================
# FUNÇÃO: Mostrar Ajuda
# ========================================
function Show-Help {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor $ColorInfo
    Write-Host "  ADICIONAR ARTIGO DO MEDIUM" -ForegroundColor $ColorInfo
    Write-Host "========================================" -ForegroundColor $ColorInfo
    Write-Host ""
    Write-Host "USO:" -ForegroundColor $ColorStep
    Write-Host "  .\add-medium-article.ps1                    # Processa todos os .html em medium-export/"
    Write-Host "  .\add-medium-article.ps1 -HtmlFile nome.html # Processa arquivo específico"
    Write-Host "  .\add-medium-article.ps1 -Help               # Mostra esta ajuda"
    Write-Host ""
    Write-Host "PASSOS:" -ForegroundColor $ColorStep
    Write-Host "  1. Exportar do Medium (Settings > Download your information)"
    Write-Host "  2. Extrair .zip e pegar arquivos .html da pasta 'posts'"
    Write-Host "  3. Copiar .html para: medium-export/"
    Write-Host "  4. Executar este script"
    Write-Host ""
    Write-Host "RESULTADO:" -ForegroundColor $ColorStep
    Write-Host "  content/posts/nome-artigo/"
    Write-Host "  ├── index.md              # Artigo convertido"
    Write-Host "  └── images/               # Imagens baixadas"
    Write-Host ""
    Write-Host "PRÓXIMO PASSO:" -ForegroundColor $ColorStep
    Write-Host "  .\hugo.exe server         # Testar localmente"
    Write-Host ""
    exit
}

if ($Help) {
    Show-Help
}

# ========================================
# VERIFICAÇÕES INICIAIS
# ========================================
Write-Host ""
Write-Host "========================================" -ForegroundColor $ColorInfo
Write-Host "  CONVERSÃO DE ARTIGO DO MEDIUM" -ForegroundColor $ColorInfo
Write-Host "========================================" -ForegroundColor $ColorInfo
Write-Host ""

# Verificar se medium-2-md está instalado
Write-Host "🔍 Verificando dependências..." -ForegroundColor $ColorStep
try {
    $null = Get-Command medium-2-md -ErrorAction Stop
    Write-Host "  ✅ medium-2-md instalado" -ForegroundColor $ColorSuccess
}
catch {
    Write-Host "  ❌ medium-2-md não encontrado!" -ForegroundColor $ColorError
    Write-Host ""
    Write-Host "INSTALAR:" -ForegroundColor $ColorWarning
    Write-Host "  npm install -g medium-2-md" -ForegroundColor White
    Write-Host ""
    exit 1
}

# Verificar se pasta medium-export existe
if (-not (Test-Path "medium-export")) {
    Write-Host "  ❌ Pasta 'medium-export' não encontrada!" -ForegroundColor $ColorError
    Write-Host ""
    Write-Host "CRIAR PASTA:" -ForegroundColor $ColorWarning
    Write-Host "  mkdir medium-export" -ForegroundColor White
    Write-Host ""
    exit 1
}

# ========================================
# ENCONTRAR ARQUIVOS HTML
# ========================================
Write-Host ""
Write-Host "📂 Procurando arquivos HTML..." -ForegroundColor $ColorStep

$htmlFiles = @()

if ($HtmlFile) {
    # Arquivo específico
    $fullPath = Join-Path "medium-export" $HtmlFile
    if (Test-Path $fullPath) {
        $htmlFiles += Get-Item $fullPath
    }
    else {
        Write-Host "  ❌ Arquivo não encontrado: $HtmlFile" -ForegroundColor $ColorError
        exit 1
    }
}
else {
    # Todos os arquivos .html
    $htmlFiles = Get-ChildItem -Path "medium-export\*.html" -File
}

if ($htmlFiles.Count -eq 0) {
    Write-Host "  ❌ Nenhum arquivo .html encontrado em 'medium-export/'" -ForegroundColor $ColorError
    Write-Host ""
    Write-Host "PASSOS:" -ForegroundColor $ColorWarning
    Write-Host "  1. Exportar do Medium (Settings > Download your information)" -ForegroundColor White
    Write-Host "  2. Extrair .zip" -ForegroundColor White
    Write-Host "  3. Copiar .html da pasta 'posts' para 'medium-export/'" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host "  ✅ Encontrados $($htmlFiles.Count) arquivo(s)" -ForegroundColor $ColorSuccess

# ========================================
# PROCESSAR CADA ARQUIVO
# ========================================
$processedCount = 0
$failedCount = 0

foreach ($htmlFile in $htmlFiles) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor $ColorInfo
    Write-Host "  PROCESSANDO: $($htmlFile.Name)" -ForegroundColor $ColorInfo
    Write-Host "========================================" -ForegroundColor $ColorInfo
    
    # ========================================
    # PASSO 1: Converter HTML para Markdown
    # ========================================
    Write-Host ""
    Write-Host "📄 [1/5] Convertendo HTML para Markdown..." -ForegroundColor $ColorStep
    
    try {
        # Executar medium-2-md para arquivo específico
        $outputDir = "medium-export\temp_$($htmlFile.BaseName)"
        
        # Criar diretório temporário
        if (Test-Path $outputDir) {
            Remove-Item $outputDir -Recurse -Force
        }
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        
        # Converter (sem flags -dfi que causam problemas)
        $convertCmd = "medium-2-md convertLocal `"$($htmlFile.FullName)`" --output=`"$outputDir`""
        Invoke-Expression $convertCmd 2>&1 | Out-Null
        
        # Procurar arquivo .md gerado
        $mdFile = Get-ChildItem -Path $outputDir -Filter "*.md" -File | Select-Object -First 1
        
        if (-not $mdFile) {
            throw "Arquivo .md não foi gerado"
        }
        
        Write-Host "  ✅ Convertido para Markdown" -ForegroundColor $ColorSuccess
        
    }
    catch {
        Write-Host "  ❌ Erro na conversão: $_" -ForegroundColor $ColorError
        $failedCount++
        continue
    }
    
    # ========================================
    # PASSO 2: Criar Page Bundle
    # ========================================
    Write-Host ""
    Write-Host "📦 [2/5] Criando Page Bundle..." -ForegroundColor $ColorStep
    
    # Gerar nome do post (slug)
    $postSlug = $mdFile.BaseName -replace '[^a-zA-Z0-9-]', '-' -replace '--+', '-' -replace '^-|-$', ''
    $postSlug = $postSlug.ToLower()
    
    $bundlePath = "content\posts\$postSlug"
    $imagesPath = "$bundlePath\images"
    
    # Criar estrutura
    New-Item -ItemType Directory -Path $bundlePath -Force | Out-Null
    New-Item -ItemType Directory -Path $imagesPath -Force | Out-Null
    
    Write-Host "  ✅ Bundle criado: $bundlePath" -ForegroundColor $ColorSuccess
    
    # ========================================
    # PASSO 3: Processar Conteúdo
    # ========================================
    Write-Host ""
    Write-Host "✏️  [3/5] Processando conteúdo..." -ForegroundColor $ColorStep
    
    # Ler conteúdo
    $content = Get-Content $mdFile.FullName -Raw -Encoding UTF8
    
    # Extrair imagens do conteúdo
    $imageUrls = @()
    $imageMatches = [regex]::Matches($content, '!\[([^\]]*)\]\(([^)]+)\)')
    
    foreach ($match in $imageMatches) {
        $imageUrls += @{
            Alt      = $match.Groups[1].Value
            Url      = $match.Groups[2].Value
            Original = $match.Value
        }
    }
    
    Write-Host "  📸 Encontradas $($imageUrls.Count) imagens" -ForegroundColor $ColorInfo
    
    # ========================================
    # PASSO 4: Baixar Imagens
    # ========================================
    Write-Host ""
    Write-Host "🖼️  [4/5] Baixando imagens..." -ForegroundColor $ColorStep
    
    $imageIndex = 1
    foreach ($img in $imageUrls) {
        try {
            # Gerar nome de arquivo
            $extension = if ($img.Url -match '\.(jpg|jpeg|png|gif|webp)') { $matches[1] } else { "png" }
            $imageName = "image-$imageIndex.$extension"
            $imagePath = Join-Path $imagesPath $imageName
            
            # Tentar baixar
            Write-Host "    Baixando imagem $imageIndex..." -ForegroundColor Gray -NoNewline
            
            # Usar WebClient para evitar problemas com Cloudflare
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
            $webClient.DownloadFile($img.Url, $imagePath)
            
            Write-Host " ✅" -ForegroundColor $ColorSuccess
            
            # Atualizar conteúdo para usar imagem local
            $newImageRef = "{{< img-advanced src=`"images/$imageName`" alt=`"$($img.Alt)`" >}}"
            $content = $content -replace [regex]::Escape($img.Original), $newImageRef
            
            $imageIndex++
            
        }
        catch {
            Write-Host " ⚠️ Falhou (mantendo URL original)" -ForegroundColor $ColorWarning
            
            # Converter para shortcode img (ImageKit fallback)
            $newImageRef = "{{< img src=`"$($img.Url)`" alt=`"$($img.Alt)`" >}}"
            $content = $content -replace [regex]::Escape($img.Original), $newImageRef
        }
    }
    
    # ========================================
    # PASSO 5: Salvar Arquivo Final
    # ========================================
    Write-Host ""
    Write-Host "💾 [5/5] Salvando arquivo final..." -ForegroundColor $ColorStep
    
    # Salvar index.md
    $indexPath = Join-Path $bundlePath "index.md"
    Set-Content -Path $indexPath -Value $content -Encoding UTF8 -NoNewline
    
    Write-Host "  ✅ Salvo: $indexPath" -ForegroundColor $ColorSuccess
    
    # Limpar diretório temporário
    Remove-Item $outputDir -Recurse -Force -ErrorAction SilentlyContinue
    
    $processedCount++
    
    Write-Host ""
    Write-Host "✅ SUCESSO: $($htmlFile.Name)" -ForegroundColor $ColorSuccess
}

# ========================================
# RESUMO FINAL
# ========================================
Write-Host ""
Write-Host "========================================" -ForegroundColor $ColorInfo
Write-Host "  RESUMO" -ForegroundColor $ColorInfo
Write-Host "========================================" -ForegroundColor $ColorInfo
Write-Host ""
Write-Host "  ✅ Processados: $processedCount" -ForegroundColor $ColorSuccess
if ($failedCount -gt 0) {
    Write-Host "  ❌ Falharam: $failedCount" -ForegroundColor $ColorError
}
Write-Host ""

if ($processedCount -gt 0) {
    Write-Host "🚀 PRÓXIMOS PASSOS:" -ForegroundColor $ColorStep
    Write-Host ""
    Write-Host "  1. Revisar artigos em: content/posts/" -ForegroundColor White
    Write-Host "  2. Testar localmente:" -ForegroundColor White
    Write-Host "     .\hugo.exe server" -ForegroundColor Cyan
    Write-Host "  3. Acessar: http://localhost:1313" -ForegroundColor White
    Write-Host "  4. Publicar:" -ForegroundColor White
    Write-Host "     git add ." -ForegroundColor Cyan
    Write-Host "     git commit -m `"feat: Add article from Medium`"" -ForegroundColor Cyan
    Write-Host "     git push origin main" -ForegroundColor Cyan
    Write-Host ""
}
