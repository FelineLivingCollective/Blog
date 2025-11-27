# Comandos Rápidos - Workflow de Desenvolvimento

## 🚀 Iniciar Novo Desenvolvimento

```powershell
# 1. Criar branch
git checkout -b feature/nome-da-mudanca

# 2. Iniciar servidor local
hugo server --buildDrafts

# 3. Abrir navegador
# http://localhost:1313/
```

---

## ✅ Aprovar e Enviar para Produção

```powershell
# 1. Commit das mudanças
git add .
git commit -m "Descrição clara da mudança"

# 2. Voltar para main
git checkout main

# 3. Fazer merge
git merge feature/nome-da-mudanca

# 4. Push para produção
git push origin main
```

---

## ❌ Cancelar Mudanças (Não Gostou)

```powershell
# Voltar para main e deletar branch
git checkout main
git branch -D feature/nome-da-mudanca
```

---

## 🔍 Ver o que vai mudar antes do push

```powershell
git diff main
```

---

## 🌐 Testar em Diferentes Tamanhos

No navegador (F12 → Device Toolbar):
- **Desktop:** 1920x1080
- **Tablet:** 768x1024  
- **Mobile:** 375x667

---

## 💾 Salvar Trabalho sem Fazer Commit

```powershell
# Guardar mudanças temporariamente
git stash

# Recuperar depois
git stash pop
```
