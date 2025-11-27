# 📝 Guia Oficial de Publicação - Feline Living Collective

Este é o método **único e automatizado** para publicar novos artigos no blog, garantindo que imagens e formatação funcionem perfeitamente.

---

## 🚀 O Fluxo de Trabalho (3 Passos)

### 1. Exporte do Medium
Se você escreveu no Medium, baixe seus dados:
1.  Vá em **Settings > Download your information**.
2.  Baixe o `.zip` e extraia.
3.  Pegue o arquivo `.html` do seu post (fica na pasta `posts` do zip).

### 2. Coloque na Pasta de Importação
1.  Copie o arquivo `.html` para a pasta:
    `F:\Blog netfly\feline-living-collective\medium-export`

### 3. Execute o Script Mágico
1.  Abra o terminal na pasta do projeto.
2.  Rode este comando:
    ```powershell
    .\import-medium.ps1
    ```

---

## 🤖 O Que o Script Faz?
O script `import-medium.ps1` é o cérebro da operação. Ele automaticamente:
1.  **Lê o HTML** que você colocou na pasta.
2.  **Cria o Post** na estrutura correta do Hugo (Page Bundle).
3.  **Baixa as Imagens** originais do Medium em alta qualidade (usando uma técnica para evitar bloqueios).
4.  **Organiza Tudo** na pasta `content/posts/nome-do-post/images`.
5.  **Atualiza o Código** para usar nossos componentes visuais (`img-advanced`).

---

## ✅ Como Verificar
Depois de rodar o script:
1.  Rode o servidor de testes:
    ```powershell
    hugo server
    ```
2.  Abra `http://localhost:1313` e veja seu novo post.

---

## 🛠️ Manutenção (Apenas para Devs)
*   **Script Principal**: `import-medium.ps1` (Usa `medium-2-md` + `curl`).
*   **Shortcode de Imagem**: `layouts/shortcodes/img-advanced.html`.
*   **Estilos**: `static/css/style.css`.
