# 🔄 Pipeline de Integração Contínua

## 📊 **Visão Geral do Pipeline**

Nosso pipeline de CI/CD é baseado em **GitHub Actions** e automatiza todo o processo de desenvolvimento, teste e deploy da infraestrutura EKS.

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Push/PR       │───▶│   Validate      │───▶│   Security      │
│                 │    │   Terraform     │    │   Scan          │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                       │
                                ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Cost          │◀───│   Plan          │    │   Test          │
│   Estimation    │    │   Terraform     │    │   Infrastructure│
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │   Deploy        │
                       │   (CD)          │
                       └─────────────────┘
```

## 🎯 **Jobs do Pipeline**

### **1. Validate (Validação)**

**Objetivo**: Validar a sintaxe e configuração do Terraform

```yaml
validate:
  name: Validate Terraform
  runs-on: ubuntu-latest
  
  steps:
  - name: Checkout code
    uses: actions/checkout@v4

  - name: Setup Terraform
    uses: hashicorp/setup-terraform@v3
    with:
      terraform_version: "1.7.0"

  - name: Terraform Init
    run: terraform init

  - name: Terraform Validate
    run: terraform validate

  - name: Terraform Plan
    run: terraform plan -out=tfplan
```

**O que faz:**
- ✅ Valida sintaxe do Terraform
- ✅ Verifica dependências
- ✅ Gera plano de execução
- ✅ Salva plano como artefato

### **2. Security (Segurança)**

**Objetivo**: Verificar vulnerabilidades e compliance

```yaml
security:
  name: Security Scan
  runs-on: ubuntu-latest
  
  steps:
  - name: Run TFSec
    uses: aquasecurity/tfsec-action@v1.0.0
    with:
      format: sarif
      out: tfsec-results.sarif
      soft_fail: true
```

**Ferramentas de Segurança:**
- 🔍 **TFSec**: Análise estática de segurança
- 📊 **SARIF**: Formato padronizado de relatórios

### **3. Cost Estimation (Estimativa de Custos)**

**Objetivo**: Estimar custos antes do deploy

```yaml
cost-estimation:
  name: Cost Estimation
  runs-on: ubuntu-latest
  if: github.event_name == 'pull_request'
  
  steps:
  - name: Generate Cost Report
    run: |
      terraform plan -out=tfplan
      terraform show -json tfplan > plan.json

  - name: Run Infracost
    uses: infracost/actions/comment@v2
    with:
      path: plan.json
      behavior: update
      github-token: ${{ secrets.GITHUB_TOKEN }}
```

**Benefícios:**
- 💰 **Transparência**: Custos visíveis antes do deploy
- 📈 **Otimização**: Identifica recursos caros
- 🎯 **Aprovação**: Facilita aprovação de mudanças

### **4. Test (Testes)**

**Objetivo**: Testar a infraestrutura em ambiente temporário

```yaml
test:
  name: Test Infrastructure
  runs-on: ubuntu-latest
  needs: [validate, security]
  if: github.ref == 'refs/heads/main'
  
  steps:
  - name: Terraform Apply (Test Environment)
    run: |
      terraform apply -auto-approve \
        -var="environment=test" \
        -var="name=test-eks-cluster"

  - name: Test EKS Cluster
    run: |
      aws eks wait cluster-active --name test-eks-cluster
      aws eks update-kubeconfig --name test-eks-cluster
      kubectl get nodes
      kubectl get pods --all-namespaces

  - name: Cleanup Test Environment
    if: always()
    run: terraform destroy -auto-approve
```

**Testes Realizados:**
- 🏗️ **Deploy**: Criação da infraestrutura
- 🔗 **Conectividade**: Teste de conexão com cluster
- 🧪 **Funcionalidade**: Verificação de componentes
- 🧹 **Cleanup**: Limpeza automática

## 🔧 **Configuração do Pipeline**

### **1. Triggers (Gatilhos)**

```yaml
on:
  push:
    branches: [ main, develop ]
    paths:
      - '**.tf'
      - '**.tfvars'
      - '.github/workflows/terraform-ci.yml'
  pull_request:
    branches: [ main, develop ]
    paths:
      - '**.tf'
      - '**.tfvars'
      - '.github/workflows/terraform-ci.yml'
```

### **2. Variáveis de Ambiente**

```yaml
env:
  TF_VERSION: "1.7.0"
  AWS_REGION: "us-east-1"
  #AWS_PROFILE: "default"
```

### **3. Secrets Necessários**

```yaml
# Configure no GitHub Secrets
AWS_ACCESS_KEY_ID: "AKIA..."
AWS_SECRET_ACCESS_KEY: "secret..."
GITHUB_TOKEN: "ghp_..."  # Automático
```

## 🚀 **Workflow de Deploy (CD)**

### **1. Deploy Automático**

```yaml
deploy:
  name: Deploy to Production
  runs-on: ubuntu-latest
  needs: [validate, security, test]
  if: github.ref == 'refs/heads/main'
  
  steps:
  - name: Deploy Infrastructure
    run: terraform apply -auto-approve
```

### **2. Deploy Manual**

```yaml
deploy-manual:
  name: Manual Deploy
  runs-on: ubuntu-latest
  if: github.event_name == 'workflow_dispatch'
  
  steps:
  - name: Deploy with Approval
    run: |
      echo "Deploying to ${{ github.event.inputs.environment }}"
      terraform apply -auto-approve \
        -var="environment=${{ github.event.inputs.environment }}"
```

## 📊 **Monitoramento do Pipeline**

### **1. Status Checks**

- ✅ **Required**: Validação obrigatória
- ✅ **Optional**: Testes opcionais
- ✅ **Blocking**: Bloqueia merge se falhar

### **2. Notificações**

```yaml
- name: Notify Linkedin
  uses: 8398a7/action-Linkedin@v3
  with:
    status: ${{ job.status }}
    channel: '#devops'
    webhook_url: ${{ secrets.Linkedin_WEBHOOK }}
```

### **3. Artefatos**

```yaml
- name: Upload Terraform Plan
  uses: actions/upload-artifact@v4
  with:
    name: terraform-plan
    path: tfplan
    retention-days: 30
```

## 🔒 **Segurança do Pipeline**

### **1. OIDC (OpenID Connect)**

```yaml
- name: Configure AWS Credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789012:role/github-actions
    aws-region: us-east-1
```

### **2. Secrets Management**

- 🔐 **GitHub Secrets**: Para credenciais sensíveis
- 🔐 **AWS Secrets Manager**: Para secrets da aplicação
- 🔐 **HashiCorp Vault**: Para secrets empresariais

### **3. Branch Protection**

```yaml
# Configure no GitHub
- Require status checks to pass before merging
- Require branches to be up to date before merging
- Require pull request reviews before merging
- Restrict pushes that create files
```

## 🎯 **Melhores Práticas**

### **1. Estrutura de Branches**

```
main          # Produção
├── develop   # Desenvolvimento
├── feature/* # Features
└── hotfix/*  # Correções urgentes
```

### **2. Versionamento**

```yaml
- name: Tag Release
  if: github.ref == 'refs/heads/main'
  run: |
    git tag v1.0.0
    git push origin v1.0.0
```

### **3. Rollback Strategy**

```yaml
- name: Rollback on Failure
  if: failure()
  run: |
    terraform apply -auto-approve \
      -var-file=previous.tfvars
```

## 📈 **Métricas e Analytics**

### **1. Pipeline Metrics**

- ⏱️ **Tempo de Execução**: Monitorar performance
- 📊 **Taxa de Sucesso**: Identificar problemas
- 🔄 **Frequência de Deploy**: Otimizar processo

### **2. Cost Tracking**

```yaml
- name: Track Costs
  run: |
    infracost breakdown --path . --format json > cost-report.json
    # Enviar para sistema de monitoramento
```

## 🚨 **Troubleshooting**

### **1. Problemas Comuns**

#### **Timeout no Deploy**
```yaml
- name: Increase Timeout
  timeout-minutes: 30
```

#### **Erro de Permissões**
```bash
# Verificar IAM roles
aws sts get-caller-identity
```

#### **Conflito de Estado**
```bash
# Forçar refresh
terraform refresh
terraform plan
```

### **2. Debug Mode**

```yaml
- name: Debug Info
  run: |
    terraform version
    aws --version
    kubectl version --client
```

## 📚 **Próximos Passos**

1. **Configuração de Segurança**: [Security-and-Compliance](Security-and-Compliance)
2. **Testes Automatizados**: [Automated-Testing](Automated-Testing)
3. **Monitoramento**: [Logging-and-Monitoring](Logging-and-Monitoring)
4. **Troubleshooting**: [Troubleshooting](Troubleshooting)

---

**Pipeline Versão**: 1.0.0  
**Última Atualização**: $(date) 