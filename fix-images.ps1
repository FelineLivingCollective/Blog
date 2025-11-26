# Script para baixar imagens remotas e corrigir capas
# Autor: Antigravity

$postsDir = "content/posts"
$imgDir = "static/images/medium"

# Cria diretório de imagens se não existir
if (-not (Test-Path $imgDir)) {
    New-Item -ItemType Directory -Path $imgDir | Out-Null
}

$files = Get-ChildItem $postsDir -Filter "*.md"

foreach ($file in $files) {
    Write-Host "Processando $($file.Name)..." -ForegroundColor Cyan
    $content = Get-Content $file.FullName -Raw
    $newContent = $content
    $firstImage = $null

    # Encontrar imagens no formato shortcode {{< img src="..." >}} ou {{< product ... img="..." >}}
    # Regex para capturar URLs http/https dentro de src="" ou img=""
    $pattern = 'src="(https?://[^"]+)"|img="(https?://[^"]+)"'
    $matches = [regex]::Matches($content, $pattern)

    foreach ($match in $matches) {
        $url = $null
        if ($match.Groups[1].Success) { $url = $match.Groups[1].Value }
        elseif ($match.Groups[2].Success) { $url = $match.Groups[2].Value }

        if ($url) {
            # Gerar nome de arquivo local baseado no hash da URL
            $filename = [System.IO.Path]::GetFileName($url.Split("?")[0])
            # Limpar nome do arquivo de caracteres estranhos
            $filename = $filename -replace "[^a-zA-Z0-9\._-]", ""
            # Se não tiver extensão, assumir .jpg (comum no Medium)
            if (-not [System.IO.Path]::HasExtension($filename)) {
                $filename = "$filename.jpg"
            }
            
            $localPath = Join-Path $imgDir $filename
            $publicPath = "/images/medium/$filename"

            # Baixar imagem se não existir
            if (-not (Test-Path $localPath)) {
                Write-Host "  Baixando: $filename"
                try {
                    Invoke-WebRequest -Uri $url -OutFile $localPath -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
                }
                catch {
                    Write-Host "  ❌ Erro ao baixar $url" -ForegroundColor Red
                    continue
                }
            }

            # Substituir URL no conteúdo
            $newContent = $newContent.Replace($url, $publicPath)

            # Guardar a primeira imagem encontrada para ser a capa
            if (-not $firstImage) {
                $firstImage = $publicPath
            }
        }
    }

    # Atualizar capa (frontmatter image:) se tivermos encontrado uma imagem
    if ($firstImage) {
        # Regex para substituir image: "..."
        $newContent = $newContent -replace 'image: ".*?"', "image: `"$firstImage`""
        Write-Host "  Capa atualizada para: $firstImage" -ForegroundColor Green
    }

    # Salvar arquivo se houve alterações
    if ($content -ne $newContent) {
        Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8
        Write-Host "  ✅ Arquivo atualizado!" -ForegroundColor Green
    }
}
