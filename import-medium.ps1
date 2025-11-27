# Script Oficial de Importação do Medium
# Combina conversão de texto e download robusto de imagens
# Autor: Antigravity (Google DeepMind)

Write-Host "🚀 Iniciando Importação Oficial do Medium..." -ForegroundColor Cyan

# Verifica diretório de entrada
if (-not (Test-Path "medium-export\*.html")) {
    Write-Host "❌ Nenhum arquivo .html encontrado em 'medium-export'." -ForegroundColor Red
    exit
}

# Loop por cada arquivo HTML
Get-ChildItem "medium-export\*.html" | ForEach-Object {
    $htmlFile = $_
    $slug = $htmlFile.BaseName
    $targetDir = "content\posts\$slug"
    $imagesDir = "$targetDir\images"
    
    Write-Host "`n📦 Processando: $slug" -ForegroundColor Yellow

    # 1. Cria estrutura de diretórios
    New-Item -ItemType Directory -Path $imagesDir -Force | Out-Null

    # 2. Converte HTML para Markdown (sem baixar imagens ainda)
    # Usamos medium-2-md apenas para o texto e frontmatter
    Write-Host "  📄 Convertendo texto..." -ForegroundColor Gray
    $tempMd = "medium-export\$slug.md"
    
    # Executa medium-2-md (mantendo links remotos)
    # Nota: O output vai para o mesmo diretório do input por padrão
    medium-2-md convertLocal "$($htmlFile.FullName)" -f
    
    if (-not (Test-Path $tempMd)) {
        Write-Host "  ❌ Falha na conversão do Markdown." -ForegroundColor Red
        return
    }

    # 3. Processa o Markdown para baixar imagens e arrumar shortcodes
    $content = Get-Content $tempMd -Raw
    
    # Regex para encontrar imagens do Medium
    # Formato: ![alt](url)
    # Exemplo: ![desc](https://cdn-images-1.medium.com/max/...)
    $imagePattern = '!\[(.*?)\]\((https://cdn-images-1\.medium\.com/[^)]+)\)'
    
    $newContent = [regex]::Replace($content, $imagePattern, {
            param($match)
            $alt = $match.Groups[1].Value
            $url = $match.Groups[2].Value
        
            # Gera nome de arquivo limpo a partir da URL (pega o ID da imagem)
            $fileName = $url.Split("/")[-1]
            # Remove caracteres inválidos do nome
            $fileName = $fileName -replace "[^a-zA-Z0-9\._-]", ""
        
            # Se não tiver extensão, assume .png (comum no Medium)
            if ($fileName -notmatch "\.(jpg|jpeg|png|gif|webp)$") {
                $fileName = "$fileName.png"
            }

            $localPath = "$imagesDir\$fileName"
        
            # Download com Curl (Bypass Bot Detection)
            Write-Host "  ⬇️  Baixando: $fileName" -ForegroundColor Gray
            $userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        
            # Verifica se já existe para não baixar de novo
            if (-not (Test-Path $localPath)) {
                $process = Start-Process -FilePath "curl.exe" -ArgumentList "-A `"$userAgent`"", "-L", "`"$url`"", "-o", "`"$localPath`"", "--silent", "--fail" -Wait -PassThru -NoNewWindow
            
                if ($process.ExitCode -ne 0) {
                    Write-Host "      ⚠️ Falha no download ($($process.ExitCode)). Mantendo link remoto." -ForegroundColor Red
                    return $match.Value # Retorna original se falhar
                }
            }

            # Retorna o novo Shortcode
            return "{{< img-advanced src=`"images/$fileName`" alt=`"$alt`" >}}"
        })

    # 4. Salva o resultado final no Page Bundle
    Set-Content -Path "$targetDir\index.md" -Value $newContent -Encoding UTF8
    
    # 5. Limpeza
    Remove-Item $tempMd -Force
    
    Write-Host "  ✅ Concluído!" -ForegroundColor Green
}

Write-Host "`n🎉 Todos os artigos foram importados com sucesso!" -ForegroundColor Cyan
Write-Host "👉 Execute 'hugo server' para verificar." -ForegroundColor White
