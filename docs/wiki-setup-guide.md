# 📚 Guia de Configuração da Wiki

## 🎯 **O que é a Wiki**

A Wiki do projeto é uma documentação completa e interativa que contém:

- 📖 **Guias detalhados** de instalação e configuração
- 🏗️ **Documentação da arquitetura** com diagramas
- 🔄 **Instruções do pipeline** CI/CD
- 🚨 **Troubleshooting** e soluções de problemas
- 🎯 **Exemplos práticos** de uso

## 🚀 **Como Configurar a Wiki**

### **Opção 1: Usando o Script Automático**

```bash
# 1. Execute o script de configuração
./scripts/setup-wiki.sh

# 2. Siga as instruções na tela
# 3. Ative a Wiki no GitHub
```

### **Opção 2: Configuração Manual**

#### **Passo 1: Criar Branch da Wiki**

```bash
# Crie uma nova branch para a Wiki
git checkout -b wiki

# Copie os arquivos da pasta wiki para a raiz
cp -r wiki/* .

# Remova a pasta wiki original
rm -rf wiki
```

#### **Passo 2: Configurar Sidebar**

Crie o arquivo `_Sidebar.md`:

```markdown
# 📚 Terraform EKS Wiki

## 🏗️ Infraestrutura
- [🏠 Home](Home)
- [🏗️ Visão da Arquitetura](Architecture-Overview)
- [🛠️ Guia de Instalação](Installation-Guide)

## 🔄 CI/CD
- [🔄 Pipeline CI/CD](CI-Pipeline)
- [🔒 Segurança](Security-and-Compliance)

## 📊 Monitoramento
- [📊 Logs e Monitoramento](Logging-and-Monitoring)
- [🚨 Troubleshooting](Troubleshooting)

---
*Última atualização: $(date)*
```

#### **Passo 3: Configurar Footer**

Crie o arquivo `_Footer.md`:

```markdown
---

**📚 Terraform EKS Infrastructure Wiki**  
**Versão**: 1.0.0  
**Última Atualização**: $(date)  
**Mantido por**: [Sua Equipe]

---
*[Reportar Problema](https://github.com/seu-usuario/terraform-vpc/issues) | [Contribuir](https://github.com/seu-usuario/terraform-vpc/pulls)*
```

#### **Passo 4: Commit e Push**

```bash
# Adicione todos os arquivos
git add .

# Faça o commit
git commit -m "📚 Adiciona Wiki completa do projeto

- Adiciona documentação completa da infraestrutura EKS
- Inclui guias de instalação, configuração e troubleshooting
- Adiciona documentação do pipeline CI/CD
- Configura sidebar e footer da Wiki

Versão: 1.0.0"

# Push para o repositório
git push origin wiki
```

#### **Passo 5: Ativar no GitHub**

1. Vá para `https://github.com/seu-usuario/terraform-vpc`
2. Clique em **Settings**
3. Role até **Features**
4. Marque **Wikis**
5. Clique em **Save**

## 📖 **Estrutura da Wiki**

```
📚 Wiki/
├── 📄 Home.md                    # Página principal
├── 🏗️ Architecture-Overview.md   # Visão da arquitetura
├── 🛠️ Installation-Guide.md      # Guia de instalação
├── 🔄 CI-Pipeline.md             # Pipeline CI/CD
├── 🔒 Security-and-Compliance.md # Segurança
├── 🧪 Automated-Testing.md       # Testes
├── 📊 Logging-and-Monitoring.md  # Monitoramento
├── 🚀 Application-Deployment.md  # Deploy de apps
├── 🔧 Troubleshooting.md         # Solução de problemas
├── 📖 README.md                  # Guia da Wiki
├── _Sidebar.md                   # Navegação lateral
└── _Footer.md                    # Rodapé
```

## 🎯 **Páginas Principais**

### **🏠 Home**
- Índice completo da Wiki
- Links para todas as seções
- Informações do projeto

### **🏗️ Architecture-Overview**
- Diagrama da arquitetura
- Componentes principais
- Configurações de segurança

### **🛠️ Installation-Guide**
- Pré-requisitos
- Instalação passo a passo
- Configurações avançadas

### **🔄 CI-Pipeline**
- Visão geral do pipeline
- Jobs e configurações
- Segurança e monitoramento

## 🔧 **Personalização**

### **1. Atualizar Informações do Projeto**

Edite o arquivo `Home.md`:

```markdown
## 📈 **Status do Projeto**

- **Versão Atual**: 1.0.0
- **Terraform**: 1.7.0
- **EKS**: 1.28
- **Status**: ✅ Produção
```

### **2. Adicionar Novas Páginas**

1. Crie um novo arquivo `.md`
2. Use o template padrão
3. Adicione links no `_Sidebar.md`
4. Atualize o índice na `Home.md`

### **3. Customizar Sidebar**

Edite `_Sidebar.md` para reorganizar a navegação:

```markdown
# 📚 Terraform EKS Wiki

## 🚀 Início Rápido
- [🏠 Home](Home)
- [🛠️ Instalação](Installation-Guide)

## 🏗️ Infraestrutura
- [🏗️ Arquitetura](Architecture-Overview)
- [🔧 Configuração](Configuration)

## 🔄 Operações
- [🔄 CI/CD](CI-Pipeline)
- [📊 Monitoramento](Logging-and-Monitoring)
- [🚨 Troubleshooting](Troubleshooting)
```

## 📊 **Monitoramento da Wiki**

### **1. Analytics**

- **Visualizações**: Monitore páginas mais acessadas
- **Feedback**: Solicite feedback dos usuários
- **Atualizações**: Mantenha conteúdo atualizado

### **2. Versionamento**

```bash
# Tag de versão da Wiki
git tag wiki-v1.0.0
git push origin wiki-v1.0.0
```

### **3. Backup**

```bash
# Backup da Wiki
git archive --format=zip --output=wiki-backup.zip wiki
```

## 🚨 **Troubleshooting**

### **Problemas Comuns**

#### **1. Wiki não aparece**
- Verifique se foi ativada nas configurações do GitHub
- Confirme se a branch `wiki` existe
- Verifique se os arquivos estão na raiz

#### **2. Links quebrados**
- Verifique se os nomes dos arquivos estão corretos
- Confirme se os links no `_Sidebar.md` estão corretos
- Teste todos os links

#### **3. Formatação incorreta**
- Verifique a sintaxe Markdown
- Use o preview do GitHub para testar
- Valide emojis e caracteres especiais

### **Debug**

```bash
# Verificar estrutura da branch wiki
git checkout wiki
ls -la

# Verificar conteúdo dos arquivos
cat _Sidebar.md
cat _Footer.md
```

## 📚 **Recursos Adicionais**

### **1. Documentação do GitHub**
- [GitHub Wiki](https://docs.github.com/en/communities/documenting-your-project-with-wikis)
- [Markdown Guide](https://docs.github.com/en/github/writing-on-github)

### **2. Ferramentas Úteis**
- **GitHub CLI**: Para configuração via linha de comando
- **Markdown Lint**: Para validar sintaxe
- **Mermaid**: Para diagramas

### **3. Templates**
- [Awesome GitHub Wikis](https://github.com/awesome-wikis/awesome-github-wikis)
- [Wiki Templates](https://github.com/topics/wiki-template)

## 🎯 **Próximos Passos**

1. **Configure a Wiki** usando o script ou manualmente
2. **Personalize o conteúdo** para seu projeto
3. **Adicione informações específicas** da sua infraestrutura
4. **Mantenha atualizada** regularmente
5. **Solicite feedback** da equipe

## 📞 **Suporte**

- 📧 **Email**: [samukacfc1@gmail.com]
- 💬 **Linkedin**: [https://www.linkedin.com/in/samuel-barreto-de-oliveira-dev/]
- 🐛 **Issues**: [GitHub Issues](https://github.com/samuelBarreto/terraform-lab/issues)

---

**Versão do Guia**: 1.0.0  
**Última Atualização**: $(date) 