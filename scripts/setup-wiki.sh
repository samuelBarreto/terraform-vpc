#!/bin/bash

# Script para configurar a Wiki do projeto no GitHub
# Este script ajuda a criar e configurar a Wiki do repositório

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir mensagens coloridas
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Setup Wiki - Terraform EKS   ${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Verificar se estamos no diretório correto
check_directory() {
    if [ ! -f "main.tf" ] || [ ! -d "modules" ]; then
        print_error "Este script deve ser executado na raiz do projeto Terraform EKS"
        exit 1
    fi
}

# Verificar se a pasta wiki existe
check_wiki_directory() {
    if [ ! -d "wiki" ]; then
        print_error "Pasta 'wiki' não encontrada. Execute primeiro o script de criação da Wiki."
        exit 1
    fi
}

# Verificar dependências
check_dependencies() {
    print_message "Verificando dependências..."
    
    if ! command -v git &> /dev/null; then
        print_error "Git não está instalado"
        exit 1
    fi
    
    if ! command -v gh &> /dev/null; then
        print_warning "GitHub CLI não está instalado. Você precisará configurar manualmente."
    fi
    
    print_message "Dependências verificadas ✓"
}

# Obter informações do repositório
get_repo_info() {
    print_message "Obtendo informações do repositório..."
    
    # Tentar obter via GitHub CLI
    if command -v gh &> /dev/null; then
        REPO_URL=$(gh repo view --json url -q .url 2>/dev/null || echo "")
    fi
    
    # Se não conseguir via CLI, tentar via git remote
    if [ -z "$REPO_URL" ]; then
        REPO_URL=$(git remote get-url origin 2>/dev/null || echo "")
    fi
    
    if [ -z "$REPO_URL" ]; then
        print_warning "Não foi possível detectar a URL do repositório automaticamente"
        read -p "Digite a URL do seu repositório GitHub: " REPO_URL
    fi
    
    # Extrair nome do usuário e repositório
    if [[ $REPO_URL =~ github\.com[:/]([^/]+)/([^/]+) ]]; then
        GITHUB_USER="${BASH_REMATCH[1]}"
        REPO_NAME="${BASH_REMATCH[2]}"
        REPO_NAME="${REPO_NAME%.git}"  # Remove .git se presente
    else
        print_error "URL do repositório inválida"
        exit 1
    fi
    
    print_message "Repositório: $GITHUB_USER/$REPO_NAME"
}

# Criar branch da Wiki
create_wiki_branch() {
    print_message "Criando branch da Wiki..."
    
    # Verificar se já existe uma branch wiki
    if git branch -a | grep -q "remotes/origin/wiki"; then
        print_warning "Branch 'wiki' já existe. Fazendo checkout..."
        git checkout wiki
        git pull origin wiki
    else
        # Criar nova branch
        git checkout -b wiki
        print_message "Branch 'wiki' criada ✓"
    fi
}

# Copiar arquivos da Wiki
copy_wiki_files() {
    print_message "Copiando arquivos da Wiki..."
    
    # Copiar todos os arquivos da pasta wiki para a raiz
    cp -r wiki-page/* .
    
    # Remover a pasta wiki original
    rm -rf wiki
    
    print_message "Arquivos da Wiki copiados ✓"
}

# Configurar arquivo _Sidebar.md
setup_sidebar() {
    print_message "Configurando sidebar da Wiki..."
    
    cat > _Sidebar.md << 'EOF'
# 📚 Terraform EKS Wiki

## 🏗️ Infraestrutura
- [🏠 Home](Home)
- [🏗️ Visão da Arquitetura](Architecture-Overview)
- [🛠️ Guia de Instalação](Installation-Guide)

## 🔄 CI/CD
- [🔄 Pipeline CI/CD](CI-Pipeline)
- [🔒 Segurança](Security-and-Compliance)
- [🧪 Testes](Automated-Testing)

## 📊 Monitoramento
- [📊 Logs e Monitoramento](Logging-and-Monitoring)
- [🚨 Troubleshooting](Troubleshooting)

## 🎯 Exemplos
- [🚀 Deploy de Aplicações](Application-Deployment)
- [🔧 Configuração de Ingress](Ingress-Configuration)

---
*Última atualização: $(date)*
EOF

    print_message "Sidebar configurada ✓"
}

# Configurar arquivo _Footer.md
setup_footer() {
    print_message "Configurando footer da Wiki..."
    
    cat > _Footer.md << 'EOF'
---

**📚 Terraform EKS Infrastructure Wiki**  
**Versão**: 1.0.0  
**Última Atualização**: $(date)  
**Mantido por**: [Sua Equipe]

---
*[Reportar Problema](https://github.com/$GITHUB_USER/$REPO_NAME/issues) | [Contribuir](https://github.com/$GITHUB_USER/$REPO_NAME/pulls)*
EOF

    print_message "Footer configurado ✓"
}

# Fazer commit das mudanças
commit_changes() {
    print_message "Fazendo commit das mudanças..."
    
    git add .
    git commit -m "📚 Adiciona Wiki completa do projeto

- Adiciona documentação completa da infraestrutura EKS
- Inclui guias de instalação, configuração e troubleshooting
- Adiciona documentação do pipeline CI/CD
- Configura sidebar e footer da Wiki

Versão: 1.0.0"
    
    print_message "Commit realizado ✓"
}

# Push para o repositório
push_to_repo() {
    print_message "Enviando para o repositório..."
    
    git push origin wiki
    
    print_message "Push realizado ✓"
}

# Configurar Wiki no GitHub
setup_github_wiki() {
    print_message "Configurando Wiki no GitHub..."
    
    if command -v gh &> /dev/null; then
        # Tentar configurar via GitHub CLI
        gh repo edit --enable-wiki=true 2>/dev/null || print_warning "Não foi possível configurar via CLI"
    fi
    
    print_message "Para ativar a Wiki no GitHub:"
    echo "1. Vá para https://github.com/$GITHUB_USER/$REPO_NAME"
    echo "2. Clique em 'Settings'"
    echo "3. Role até 'Features'"
    echo "4. Marque 'Wikis'"
    echo "5. Clique em 'Save'"
}

# Mostrar próximos passos
show_next_steps() {
    print_message "Próximos passos:"
    echo ""
    echo "1. 📝 Ative a Wiki no GitHub:"
    echo "   https://github.com/$GITHUB_USER/$REPO_NAME/settings"
    echo ""
    echo "2. 🔗 Acesse a Wiki:"
    echo "   https://github.com/$GITHUB_USER/$REPO_NAME/wiki"
    echo ""
    echo "3. 📚 Personalize o conteúdo:"
    echo "   - Edite as páginas conforme necessário"
    echo "   - Adicione informações específicas do seu projeto"
    echo "   - Atualize links e exemplos"
    echo ""
    echo "4. 🔄 Mantenha atualizada:"
    echo "   - Revise regularmente"
    echo "   - Adicione novas funcionalidades"
    echo "   - Solicite feedback da equipe"
}

# Função principal
main() {
    print_header
    
    check_directory
    check_wiki_directory
    check_dependencies
    get_repo_info
    
    echo ""
    print_message "Iniciando configuração da Wiki..."
    echo ""
    
    create_wiki_branch
    copy_wiki_files
    setup_sidebar
    setup_footer
    commit_changes
    push_to_repo
    setup_github_wiki
    
    echo ""
    print_message "✅ Wiki configurada com sucesso!"
    echo ""
    
    show_next_steps
}

# Executar função principal
main "$@" 