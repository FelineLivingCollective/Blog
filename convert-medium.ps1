# Script para converter artigos do Medium para Hugo
# Uso: Coloque os arquivos .html do Medium na pasta 'medium-export' e execute este script.

Write-Host "🔄 Iniciando conversão de artigos do Medium..." -ForegroundColor Cyan

# Verifica se existem arquivos HTML na pasta
if (-not (Test-Path "medium-export\*.html")) {
    Write-Host "❌ Nenhum arquivo .html encontrado na pasta 'medium-export'." -ForegroundColor Red
    Write-Host "👉 Exporte seus dados do Medium, extraia o zip e coloque os arquivos .html da pasta 'posts' aqui em 'medium-export'." -ForegroundColor Yellow
    exit
}

# Executa a conversão
# -d: Download images
# -f: Add frontmatter
# -i: Use local images
medium-2-md convertLocal "medium-export\*.html" -dfi

# Move os arquivos convertidos para a pasta de posts
Write-Host "📦 Movendo arquivos convertidos para content/posts..." -ForegroundColor Cyan
Move-Item -Path "medium-export\*.md" -Destination "content\posts" -Force

# Move as imagens baixadas (se houver)
if (Test-Path "medium-export\img") {
    Write-Host "🖼️ Movendo imagens..." -ForegroundColor Cyan
    # Cria diretório de imagens se não existir
    if (-not (Test-Path "static\images\medium")) {
        New-Item -ItemType Directory -Path "static\images\medium" | Out-Null
    }
    Copy-Item -Path "medium-export\img\*" -Destination "static\images\medium" -Recurse -Force
}

Write-Host "✅ Conversão concluída com sucesso!" -ForegroundColor Green
Write-Host "👉 Verifique a pasta 'content/posts' para ver seus novos artigos." -ForegroundColor Yellow
