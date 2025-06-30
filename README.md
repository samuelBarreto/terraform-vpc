# Terraform EKS Cluster com VPC

Este projeto Terraform cria uma infraestrutura completa para um cluster EKS (Elastic Kubernetes Service) na AWS, incluindo VPC com subnets públicas e privadas, cluster EKS com node groups gerenciados, e configurações avançadas de segurança e automação.

## 🏗️ Arquitetura

O projeto cria a seguinte infraestrutura:

- **VPC** com subnets públicas e privadas em múltiplas AZs
- **NAT Gateway** para conectividade das subnets privadas
- **Cluster EKS** com criptografia KMS
- **Managed Node Groups** para workers EC2
- **EKS Addons**: CoreDNS, kube-proxy, VPC-CNI
- **IAM Roles** para cluster e nodes
- **AWS Auth ConfigMap** para controle de acesso
- **Helm Releases** para instalação automática de aplicações

## 📁 Estrutura do Projeto

```
terraform-lab/
├── main.tf                 # Configuração principal
├── variables.tf            # Variáveis do projeto
├── outputs.tf              # Outputs do projeto
├── versions.tf             # Versões dos providers
├── terraform.tfvars        # Valores das variáveis
├── README.md               # Documentação
├── scripts/                # Scripts de automação
│   ├── connect-to-cluster.sh    # Conectar ao cluster EKS
│   ├── update-cluster.sh        # Update completo do cluster (inclui recursos Kubernetes)
│   ├── update-cluster-direct.sh # Update direto do cluster (apenas cluster e node groups)
│   ├── post-deploy.sh           # Verificação completa pós-deploy
│   ├── deploy-with-env.sh       # Deploy com variáveis de ambiente
│   ├── validate-ingress.sh      # Validar ingress controller
│   ├── test-ingress.sh          # Teste rápido do ingress
│   ├── setup-route53.sh         # Configuração completa Route53
│   ├── apply-route53.sh         # Aplicar configuração Route53
│   ├── test-route53.sh          # Testar configuração Route53
│   └── help.sh                  # Ajuda e documentação
├── examples/               # Exemplos de aplicações
│   ├── name-app.yaml   # Aplicação exemplo
│   ├── nginx-ingress-example.yaml
│   └── advanced-eks.tf
├── docs/                   # Documentação adicional
│   ├── architecture-diagram.md
│   └── architecture-ascii.txt
└── modules/
    ├── vpc/
    │   ├── main.tf         # Módulo VPC
    │   ├── variables.tf    # Variáveis do VPC
    │   └── outputs.tf      # Outputs do VPC
    └── eks/
        ├── main.tf         # Módulo EKS
        ├── variables.tf    # Variáveis do EKS
        └── outputs.tf      # Outputs do EKS
```

## 🚀 Funcionalidades

### ✅ Cluster EKS (Control Plane)
- Versão configurável do Kubernetes
- Criptografia de secrets com KMS
- Endpoints público e privado configuráveis
- Logs habilitados para auditoria

### ✅ Managed Node Groups
- Múltiplos node groups com configurações diferentes
- Suporte a labels e taints
- Auto-scaling configurável
- Diferentes tipos de instância

### ✅ IAM Roles
- **Cluster Role**: Permissões para o control plane EKS
- **Node Group Role**: Permissões para os workers
- **AWS Auth**: Controle de acesso de usuários e roles

### ✅ KMS Key
- Criptografia de dados em repouso
- Rotação automática de chaves
- Criptografia de secrets do Kubernetes

### ✅ EKS Addons
- **CoreDNS**: Resolução DNS interna
- **kube-proxy**: Networking do cluster
- **VPC-CNI**: Plugin de rede AWS

### ✅ Helm Integration
- Instalação automática de aplicações via Helm
- Suporte a múltiplos charts
- Configuração via values e set

### ✅ Scripts de Automação
- **Conectividade**: Scripts para conectar ao cluster EKS
- **Update**: Scripts para atualizar versão e configurações do cluster
- **Validação**: Verificação automática do ingress controller
- **Route53**: Configuração automática de DNS
- **Testes**: Validação de conectividade e DNS
- **Flexibilidade**: Parâmetros configuráveis via linha de comando

## 📋 Pré-requisitos

- Terraform >= 1.0
- AWS CLI configurado
- kubectl instalado
- Helm instalado (opcional)
- curl instalado (para scripts de teste)
- nslookup instalado (para testes DNS)
- Bash shell (para execução dos scripts)

## 🔧 Configuração

### 1. Configurar AWS Credentials

```bash
aws configure
```

### 2. Personalizar `terraform.tfvars`

Edite o arquivo `terraform.tfvars` com suas configurações:

```hcl
aws_region = "us-east-1"
name       = "my-eks-cluster"
profile    = "default"
environment = "dev"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

# EKS Configuration
cluster_version = "1.28"
service_ipv4_cidr = "172.20.0.0/16"

# Node Groups
node_groups = {
  default = {
    name                   = "default"
    instance_types         = ["t3.medium"]
    capacity_type          = "ON_DEMAND"
    min_size               = 1
    max_size               = 3
    desired_size           = 2
    disk_size              = 20
    ami_type               = "AL2_x86_64"
    force_update_version   = true
    labels = {
      "node.kubernetes.io/role" = "worker"
      "environment"             = "dev"
    }
    taints = []
  }
}

# AWS Auth Users/Roles
aws_auth_users = [
  {
    userarn  = "arn:aws:iam::123456789012:user/admin-user"
    username = "admin-user"
    groups   = ["system:masters"]
  }
]

# Helm Releases
helm_releases = {
  nginx_ingress = {
    name             = "nginx-ingress"
    repository       = "https://kubernetes.github.io/ingress-nginx"
    chart            = "ingress-nginx"
    version          = "4.7.1"
    namespace        = "ingress-nginx"
    create_namespace = true
    values = {
      controller = {
        service = {
          type = "LoadBalancer"
        }
      }
    }
  }
}
```

### 3. Deploy da Infraestrutura

```bash
# Inicializar Terraform
terraform init

# Verificar o plano
terraform plan

# Aplicar as mudanças
terraform apply
```

### 4. Configurar kubectl

Após o deploy, configure o kubectl:

```bash
# Opção 1: Manual
aws eks update-kubeconfig --region us-east-1 --name my-eks-cluster

# Opção 2: Usando script de automação (recomendado)
./scripts/connect-to-cluster.sh

# Verificar conexão
kubectl get nodes
```

## 🚀 Scripts de Automação

Este projeto inclui scripts de automação para facilitar o gerenciamento do cluster EKS e configuração do Route53. Todos os scripts aceitam parâmetros via linha de comando com valores padrão.

### 📋 Scripts Disponíveis

#### 🔗 **Conectar ao Cluster**
```bash
# Uso: ./scripts/connect-to-cluster.sh [CLUSTER_NAME] [AWS_REGION] [AWS_PROFILE]
./scripts/connect-to-cluster.sh my-eks-cluster us-east-1 default

# Valores padrão
./scripts/connect-to-cluster.sh
# → CLUSTER_NAME=my-eks-cluster
# → AWS_REGION=us-east-1
# → AWS_PROFILE=default
```

#### 🔄 **Atualizar Cluster EKS**
```bash
# Tornar o script executável (primeira vez)
chmod +x scripts/update-cluster.sh

# Uso: ./scripts/update-cluster.sh [CLUSTER_NAME] [AWS_REGION] [AWS_PROFILE]
./scripts/update-cluster.sh my-eks-cluster us-east-1 default

# Valores padrão
./scripts/update-cluster.sh
# → CLUSTER_NAME=my-eks-cluster
# → AWS_REGION=us-east-1
# → AWS_PROFILE=default
```

#### 🔍 **Verificação Pós-Deploy**
```bash
# Uso: CLUSTER_NAME=my-eks-cluster AWS_REGION=us-east-1 AWS_PROFILE=default ./scripts/post-deploy.sh
export CLUSTER_NAME=my-eks-cluster
export AWS_REGION=us-east-1
export AWS_PROFILE=default
./scripts/post-deploy.sh

# Ou com variáveis inline
CLUSTER_NAME=my-eks-cluster AWS_REGION=us-east-1 AWS_PROFILE=default ./scripts/post-deploy.sh

# Valores padrão (se não especificado)
# → CLUSTER_NAME=my-eks-cluster
# → AWS_REGION=us-east-1
# → AWS_PROFILE=default
```

#### 🚀 **Deploy com Variáveis de Ambiente**
```bash
# Uso: INGRESS_SUBNETS="subnet-123,subnet-456,subnet-789" ./scripts/deploy-with-env.sh
export INGRESS_SUBNETS="subnet-08120d581b9165503,subnet-02c590a3dbf9bfe79,subnet-0dc24e4208685768d"
./scripts/deploy-with-env.sh

# Ou com variável inline
INGRESS_SUBNETS="subnet-123,subnet-456,subnet-789" ./scripts/deploy-with-env.sh
```

**📋 O que o script faz:**
1. **🔍 Verifica variáveis** - Verifica se INGRESS_SUBNETS está definida
2. **📝 Cria arquivo temporário** - Gera terraform.tfvars.env com subnets personalizadas
3. **⚙️ Configura deploy** - Prepara comandos para usar subnets específicas
4. **📋 Mostra opções** - Exibe diferentes formas de fazer o deploy

**🎯 Casos de uso:**
- ✅ **Subnets automáticas** - Usa subnets padrão do Terraform
- ✅ **Subnets personalizadas** - Usa subnets específicas via variável de ambiente
- ✅ **Deploy flexível** - Permite diferentes configurações sem editar arquivos
- ✅ **Automação** - Útil para CI/CD e scripts automatizados

**⚠️ Importante:** Este script é útil quando você precisa usar subnets específicas para o Ingress Controller sem editar manualmente o terraform.tfvars.

#### 🌐 **Configuração de Subnets para Ingress**

**Opções de configuração de subnets:**

##### **1. Subnets Automáticas (Padrão)**
```bash
# Usa as subnets públicas criadas pelo Terraform
terraform plan
terraform apply
```

##### **2. Subnets via Variável de Ambiente**
```bash
# Definir subnets específicas
export INGRESS_SUBNETS="subnet-08120d581b9165503,subnet-02c590a3dbf9bfe79,subnet-0dc24e4208685768d"

# Usar script para configurar
./scripts/deploy-with-env.sh

# Aplicar com arquivo temporário
terraform plan -var-file=terraform.tfvars.env
terraform apply -var-file=terraform.tfvars.env
```

##### **3. Subnets via Linha de Comando**
```bash
# Aplicar diretamente com subnets específicas
terraform plan -var='ingress_subnets=["subnet-08120d581b9165503","subnet-02c590a3dbf9bfe79","subnet-0dc24e4208685768d"]'
terraform apply -var='ingress_subnets=["subnet-08120d581b9165503","subnet-02c590a3dbf9bfe79","subnet-0dc24e4208685768d"]'
```

**💡 Dica:** Use o script `deploy-with-env.sh` para facilitar a configuração de subnets específicas sem editar arquivos manualmente.

#### 🔍 **Validar Ingress Controller**
```bash
# Uso: ./scripts/validate-ingress.sh [NAMESPACE] [SERVICE_NAME] [TIMEOUT]
./scripts/validate-ingress.sh ingress-nginx nginx-ingress-ingress-nginx-controller 300

# Valores padrão
./scripts/validate-ingress.sh
# → NAMESPACE=ingress-nginx
# → SERVICE_NAME=nginx-ingress-ingress-nginx-controller
# → TIMEOUT=300
```

#### 🧪 **Teste Rápido do Ingress**
```bash
# Uso: ./scripts/test-ingress.sh [NAMESPACE] [SERVICE_NAME] [TIMEOUT]
./scripts/test-ingress.sh ingress-nginx nginx-ingress-ingress-nginx-controller 60

# Valores padrão
./scripts/test-ingress.sh
# → NAMESPACE=ingress-nginx
# → SERVICE_NAME=nginx-ingress-ingress-nginx-controller
# → TIMEOUT=60
```

#### 🌐 **Configurar Route53 (Completo)**
```bash
# Uso: ./scripts/setup-route53.sh [DOMAIN_NAME] [CLUSTER_NAME] [AWS_REGION] [AWS_PROFILE]
./scripts/setup-route53.sh name.com my-eks-cluster us-east-1 default

# Valores padrão
./scripts/setup-route53.sh
# → DOMAIN_NAME=name.com
# → CLUSTER_NAME=my-eks-cluster
# → AWS_REGION=us-east-1
# → AWS_PROFILE=default
```

#### 🌐 **Aplicar Configuração Route53**
```bash
# Uso: ./scripts/apply-route53.sh [DOMAIN_NAME] [AWS_REGION] [AWS_PROFILE]
./scripts/apply-route53.sh name.com us-east-1 default

# Valores padrão
./scripts/apply-route53.sh
# → DOMAIN_NAME=name.com
# → AWS_REGION=us-east-1
# → AWS_PROFILE=default
```

#### 🌐 **Testar Configuração Route53**
```bash
# Uso: ./scripts/test-route53.sh [DOMAIN_NAME] [AWS_REGION] [AWS_PROFILE]
./scripts/test-route53.sh name.com us-east-1 default

# Valores padrão
./scripts/test-route53.sh
# → DOMAIN_NAME=name.com
# → AWS_REGION=us-east-1
# → AWS_PROFILE=default
```

#### ❓ **Ajuda e Documentação**
```bash
# Mostra como usar todos os scripts
./scripts/help.sh
```

### 🔧 **Fluxo Recomendado**

#### **🔄 Para Atualizações do Cluster:**
```bash
# Sequência completa de update
chmod +x scripts/*.sh
./scripts/update-cluster-direct.sh
./scripts/connect-to-cluster.sh
./scripts/validate-ingress.sh
```

**🎯 Para mais detalhes, consulte a seção [Manutenção](#-manutenção)**

#### **🚀 Para Configuração Inicial:**
```bash
# 1. Conectar ao cluster
./scripts/connect-to-cluster.sh

# 2. Verificação completa pós-deploy
./scripts/post-deploy.sh

# 3. Validar o ingress controller
./scripts/validate-ingress.sh

# 4. Configurar Route53
./scripts/apply-route53.sh
```

### 📝 **Exemplos de Uso com Parâmetros**

```bash
# Usar cluster diferente
./scripts/connect-to-cluster.sh meu-cluster-prod us-west-2 admin-prod

# Usar domínio diferente
./scripts/apply-route53.sh meudominio.com us-east-1 default

# Usar timeout maior para ingress
./scripts/validate-ingress.sh ingress-nginx nginx-ingress-ingress-nginx-controller 600

# Configuração completa personalizada
./scripts/setup-route53.sh meudominio.com meu-cluster-prod us-west-2 admin-prod
```

### ⚙️ **Configuração dos Scripts**

#### **Pré-requisitos**
- AWS CLI configurado com perfil
- kubectl instalado
- curl instalado (para testes de conectividade)
- nslookup instalado (para testes DNS)

#### **Permissões AWS Necessárias**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:DescribeCluster",
                "eks:UpdateKubeconfig",
                "route53:ListHostedZones",
                "route53:GetChange",
                "route53:ChangeResourceRecordSets",
                "route53:WaitForResourceRecordSetsChanged"
            ],
            "Resource": "*"
        }
    ]
}
```

#### **HostedZoneIds por Região**
| Região | HostedZoneId |
|--------|--------------|
| us-east-1 | Z26RNL4JYFTOTI |
| us-west-2 | Z1H1FL5HABSF5 |
| eu-west-1 | Z2IFOLAFXWLO4F |
| ap-southeast-1 | Z1LMS91P8CMLE5 |

### 🎯 **Funcionalidades dos Scripts**

#### **Validação Inteligente**
- ✅ Verifica se recursos existem antes de aguardar
- ✅ Detecta automaticamente o HostedZoneId correto
- ✅ Testa conectividade HTTP e DNS
- ✅ Mostra status detalhado dos recursos

#### **Flexibilidade**
- ✅ Parâmetros opcionais com valores padrão
- ✅ Suporte a múltiplas regiões AWS
- ✅ Configuração de perfil AWS
- ✅ Timeouts configuráveis

#### **Robustez**
- ✅ Tratamento de erros
- ✅ Mensagens informativas
- ✅ Verificações de pré-requisitos
- ✅ Logs detalhados

### 🔍 **Troubleshooting**

#### **Problemas Comuns**

**Erro: "Namespace não existe"**
```bash
# Verificar namespaces disponíveis
kubectl get namespaces

# Verificar se o ingress controller foi instalado
kubectl get pods -n ingress-nginx
```

**Erro: "Load Balancer não está pronto"**
```bash
# Aguardar mais tempo
./scripts/validate-ingress.sh ingress-nginx nginx-ingress-ingress-nginx-controller 600

# Verificar status do serviço
kubectl describe service nginx-ingress-ingress-nginx-controller -n ingress-nginx
```

**Erro: "Zona hospedada não encontrada"**
```bash
# Verificar zonas hospedadas
aws route53 list-hosted-zones --profile default

# Verificar se o domínio está configurado no Route53
aws route53 list-hosted-zones --profile default --query "HostedZones[?Name=='seu-dominio.com.']"
```

**Erro: "HostedZoneId incorreto"**
```bash
# O script detecta automaticamente o HostedZoneId correto
# Se persistir, verificar a região do Load Balancer
kubectl get svc nginx-ingress-ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

**Erro: "configmaps aws-auth is forbidden" ou "secrets is forbidden"**
```bash
# Este erro ocorre quando o Terraform não consegue autenticar no cluster
# Solução: Use o script de atualização que configura a autenticação automaticamente

# Opção 1: Script automático (recomendado)
chmod +x scripts/update-cluster.sh
./scripts/update-cluster.sh

# Opção 2: Manual
aws eks update-kubeconfig --region us-east-1 --name my-eks-cluster --profile default
export AWS_PROFILE=default
export AWS_REGION=us-east-1
terraform plan
```

**Erro: "User system:anonymous cannot get resource"**
```bash
# Problema de autenticação Kubernetes
# Verificar se o kubectl está funcionando
kubectl get nodes

# Se funcionar, o problema é com o Terraform
# Usar o script de atualização
./scripts/update-cluster.sh
```

**Erro: "Recursos Kubernetes não encontrados"**
```bash
# Usar script de update direto
./scripts/update-cluster-direct.sh

# Ou recriar recursos manualmente
kubectl apply -f examples/name-app.yaml
```

## 🔐 Configuração de Acesso

### AWS Auth ConfigMap

O módulo cria automaticamente o `aws-auth` ConfigMap com:

- Mapeamento da role dos node groups
- Usuários e roles configurados via variáveis
- Permissões de acesso ao cluster

### Exemplo de Configuração de Usuário

```hcl
aws_auth_users = [
  {
    userarn  = "arn:aws:iam::123456789012:user/developer"
    username = "developer"
    groups   = ["system:authenticated"]
  }
]
```

### Exemplo de Configuração de Role

```hcl
aws_auth_roles = [
  {
    rolearn  = "arn:aws:iam::123456789012:role/eks-admin"
    username = "eks-admin"
    groups   = ["system:masters"]
  }
]
```

## 🎯 Helm Releases

### Instalação Automática de Aplicações

O módulo suporta instalação automática de aplicações via Helm:

```hcl
helm_releases = {
  nginx_ingress = {
    name             = "nginx-ingress"
    repository       = "https://kubernetes.github.io/ingress-nginx"
    chart            = "ingress-nginx"
    version          = "4.7.1"
    namespace        = "ingress-nginx"
    create_namespace = true
    values = {
      controller = {
        service = {
          type = "LoadBalancer"
        }
      }
    }
  }
}
```

### Aplicações Recomendadas

- **nginx-ingress**: Load balancer e ingress controller
- **cert-manager**: Gerenciamento de certificados SSL
- **metrics-server**: Métricas do cluster
- **prometheus-operator**: Monitoramento
- **fluent-bit**: Logging

## 📊 Outputs Importantes

Após o deploy, você terá acesso aos seguintes outputs:

```bash
# Informações do cluster
terraform output cluster_name
terraform output cluster_endpoint
terraform output cluster_oidc_issuer_url

# Configuração kubectl
terraform output kubeconfig

# Informações dos node groups
terraform output node_groups

# ARNs das IAM roles
terraform output cluster_iam_role_arn
terraform output node_group_iam_role_arn
```

## 🔧 Manutenção

### 🔄 **Update do Cluster EKS**

#### **Sequência Recomendada para Updates**

```bash
# 1. Preparação (primeira vez apenas)
chmod +x scripts/*.sh

# 2. Update do cluster (principal)
./scripts/update-cluster-direct.sh

# 3. Verificação pós-update
./scripts/connect-to-cluster.sh
./scripts/validate-ingress.sh
```

#### **Scripts de Update Disponíveis**

##### **🔄 Update Direto (Recomendado)**
```bash
# Atualiza apenas cluster e node groups (evita problemas de autenticação)
./scripts/update-cluster-direct.sh
```

**O que faz:**
- ✅ Atualiza versão do cluster (ex: 1.30 → 1.31)
- ✅ Atualiza versão dos node groups
- ✅ Aguarda cluster ficar pronto
- ✅ Ignora recursos Kubernetes problemáticos
- ✅ Pergunta se quer atualizar recursos Kubernetes depois

##### **🔄 Update Completo**
```bash
# Atualiza tudo, incluindo recursos Kubernetes
./scripts/update-cluster.sh
```

**O que faz:**
- ✅ Atualiza cluster e node groups
- ✅ Atualiza aws-auth configmap
- ✅ Atualiza Helm releases
- ⚠️ Pode ter problemas de autenticação

#### **Casos de Uso**

**Para atualização de versão:**
```bash
# 1. Editar terraform.tfvars
# cluster_version = "1.31"

# 2. Executar update
./scripts/update-cluster-direct.sh
```

**Para mudanças de configuração:**
```bash
# 1. Editar terraform.tfvars
# 2. Executar update
./scripts/update-cluster-direct.sh
```

**Para atualização de addons:**
```bash
# 1. Editar versões dos addons no terraform.tfvars
# 2. Executar update
./scripts/update-cluster-direct.sh
```

#### **Verificação Pós-Update**

```bash
# Verificar versão do cluster
kubectl version --short

# Verificar nodes
kubectl get nodes

# Verificar addons
kubectl get pods -n kube-system

# Verificar ingress controller
./scripts/validate-ingress.sh
```

#### **Troubleshooting de Updates**

**Erro: "Cluster não está pronto"**
```bash
# Aguardar cluster ficar ativo
aws eks wait cluster-active --name my-eks-cluster --region us-east-1 --profile default

# Verificar status
aws eks describe-cluster --name my-eks-cluster --region us-east-1 --profile default
```

**Erro: "Node groups não estão prontos"**
```bash
# Aguardar node groups ficarem ativos
aws eks wait nodegroup-active --cluster-name my-eks-cluster --nodegroup-name default --region us-east-1 --profile default

# Verificar status
aws eks describe-nodegroup --cluster-name my-eks-cluster --nodegroup-name default --region us-east-1 --profile default
```

**Erro: "Problemas de conectividade"**
```bash
# Reconectar ao cluster
./scripts/connect-to-cluster.sh

# Verificar kubeconfig
kubectl config current-context
```

### Atualização do Cluster

```bash
# Atualizar versão do Kubernetes
terraform apply -var="cluster_version=1.29"
```

### Escalar Node Groups

```bash
# Modificar tamanho dos node groups
terraform apply -var='node_groups={"default":{"name":"default","instance_types":["t3.medium"],"capacity_type":"ON_DEMAND","min_size":2,"max_size":5,"desired_size":3,"disk_size":20,"ami_type":"AL2_x86_64","force_update_version":true,"labels":{"node.kubernetes.io/role":"worker"},"taints":[]}}'
```

### Adicionar Helm Releases

```bash
# Adicionar nova aplicação
terraform apply -var='helm_releases={"new-app":{"name":"new-app","repository":"https://repo.example.com","chart":"my-chart","version":"1.0.0","namespace":"my-app","create_namespace":true,"values":{},"set":[]}}'
```

## 🧹 Limpeza

Para destruir toda a infraestrutura:

```bash
terraform destroy
```

**⚠️ Atenção**: Este comando irá deletar todo o cluster EKS e todos os recursos associados.

## 🔄 Para Atualizações do Recurso

### **📋 Guia Completo de Atualizações**

Esta seção explica como atualizar diferentes recursos da infraestrutura EKS de forma segura e organizada.

#### **🔄 Sequência Padrão para Qualquer Update**

```bash
# 1. Preparação (primeira vez apenas)
chmod +x scripts/*.sh

# 2. Backup do estado atual
terraform state pull > terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)

# 3. Verificar mudanças
terraform plan

# 4. Aplicar mudanças
terraform apply
```

#### **🎯 Tipos de Atualizações**

##### **1. Atualização de Versão do Cluster**
```bash
# Editar terraform.tfvars
# cluster_version = "1.31"

# Executar update
./scripts/update-cluster-direct.sh
```

##### **2. Atualização de Node Groups**
```bash
# Editar terraform.tfvars - seção node_groups
# Exemplo: aumentar número de nodes
node_groups = {
  default = {
    min_size     = 3  # Era 2
    max_size     = 6  # Era 5
    desired_size = 4  # Era 3
  }
}

# Executar update
./scripts/update-cluster-direct.sh
```

##### **3. Atualização de Addons EKS**
```bash
# Editar versões no terraform.tfvars ou módulo EKS
# Exemplo: atualizar kube-proxy
addon_version = "v1.31.0-eksbuild.1"  # Nova versão

# Executar update
./scripts/update-cluster-direct.sh
```

##### **4. Atualização de Helm Releases**
```bash
# Editar terraform.tfvars - seção helm_releases
helm_releases = {
  nginx_ingress = {
    version = "4.8.0"  # Nova versão
  }
}

# Executar update completo
./scripts/update-cluster.sh
```

##### **5. Atualização de Configurações de Rede**
```bash
# Editar terraform.tfvars - seção VPC
public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"]
private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24", "10.0.14.0/24"]

# Executar update
terraform plan
terraform apply
```

#### **🔧 Scripts Específicos por Tipo de Update**

##### **Para Updates de Cluster (Recomendado)**
```bash
# Update seguro - apenas cluster e node groups
./scripts/update-cluster-direct.sh
```

##### **Para Updates Completos**
```bash
# Update completo - inclui recursos Kubernetes
./scripts/update-cluster.sh
```

##### **Para Verificações Pós-Update**
```bash
# Conectar ao cluster
./scripts/connect-to-cluster.sh

# Validar ingress controller
./scripts/validate-ingress.sh

# Testar aplicações
./scripts/test-ingress.sh
```

#### **⚠️ Considerações Importantes**

##### **Antes de Fazer Updates**
- ✅ **Backup do estado**: Sempre faça backup do terraform.tfstate
- ✅ **Teste em ambiente de desenvolvimento**: Teste mudanças primeiro
- ✅ **Verifique compatibilidade**: Confirme se as versões são compatíveis
- ✅ **Planeje downtime**: Alguns updates podem causar interrupção

##### **Durante o Update**
- ✅ **Monitore o progresso**: Use `kubectl get nodes` para verificar status
- ✅ **Aguarde conclusão**: Não interrompa o processo
- ✅ **Verifique logs**: Monitore logs do cluster se necessário

##### **Após o Update**
- ✅ **Valide conectividade**: Teste se consegue conectar ao cluster
- ✅ **Verifique aplicações**: Confirme se as aplicações estão funcionando
- ✅ **Teste funcionalidades**: Execute testes específicos da sua aplicação

#### **🔄 Exemplos Práticos**

##### **Exemplo 1: Update de Versão Menor (1.30 → 1.31)**
```bash
# 1. Editar terraform.tfvars
cluster_version = "1.31"

# 2. Executar update
./scripts/update-cluster-direct.sh

# 3. Verificar
kubectl version --short
kubectl get nodes
```

##### **Exemplo 2: Escalar Node Group**
```bash
# 1. Editar terraform.tfvars
node_groups = {
  default = {
    min_size     = 3
    max_size     = 6
    desired_size = 4
  }
}

# 2. Executar update
./scripts/update-cluster-direct.sh

# 3. Verificar
kubectl get nodes
```

##### **Exemplo 3: Atualizar Helm Release**
```bash
# 1. Editar terraform.tfvars
helm_releases = {
  nginx_ingress = {
    version = "4.8.0"
  }
}

# 2. Executar update
./scripts/update-cluster.sh

# 3. Verificar
kubectl get pods -n ingress-nginx
```

#### **🚨 Troubleshooting de Updates**

##### **Problemas Comuns e Soluções**

**Erro: "Cluster não está pronto"**
```bash
# Aguardar cluster ficar ativo
aws eks wait cluster-active --name my-eks-cluster --region us-east-1 --profile default

# Verificar status
aws eks describe-cluster --name my-eks-cluster --region us-east-1 --profile default
```

**Erro: "Node groups não estão prontos"**
```bash
# Aguardar node groups ficarem ativos
aws eks wait nodegroup-active --cluster-name my-eks-cluster --nodegroup-name default --region us-east-1 --profile default

# Verificar status
aws eks describe-nodegroup --cluster-name my-eks-cluster --nodegroup-name default --region us-east-1 --profile default
```

**Erro: "Problemas de conectividade"**
```bash
# Reconectar ao cluster
./scripts/connect-to-cluster.sh

# Verificar kubeconfig
kubectl config current-context
```

**Erro: "Recursos Kubernetes não encontrados"**
```bash
# Usar script de update direto
./scripts/update-cluster-direct.sh

# Ou recriar recursos manualmente
kubectl apply -f examples/name-app.yaml
```

### Atualização do Cluster

```bash
# Atualizar versão do Kubernetes
terraform apply -var="cluster_version=1.29"
```

## 🧹 Limpeza

Para destruir toda a infraestrutura:

```bash
terraform destroy
```

**⚠️ Atenção**: Este comando irá deletar todo o cluster EKS e todos os recursos associados.

## 🔒 Segurança


## **🌐 Configuração de Domínio Personalizado**

### **Usando seu próprio domínio (ex: name.com)**

1. **Configure o NGINX Ingress Controller:**
   ```bash
   # As subnets são injetadas automaticamente pelo Terraform
   terraform init
   terraform plan
   terraform apply
   ```

2. **Configure o Route 53:**
   ```bash
   # Opção 1: Script completo (recomendado)
   chmod +x scripts/setup-route53.sh
   ./scripts/setup-route53.sh
   
   # Opção 2: Script específico para Route53
   chmod +x scripts/apply-route53.sh
   ./scripts/apply-route53.sh
   
   # Opção 3: Testar configuração
   chmod +x scripts/test-route53.sh
   ./scripts/test-route53.sh
   ```

3. **Aplique sua aplicação:**
   ```bash
   # Use o exemplo fornecido ou crie sua própria aplicação
   kubectl apply -f examples/name-app.yaml
   ```

### **Vantagens da Configuração Dinâmica:**

- ✅ **Subnets automáticas**: Não precisa atualizar manualmente os IDs das subnets
- ✅ **Flexibilidade**: Funciona em qualquer região ou conta AWS
- ✅ **Manutenibilidade**: Mudanças na infraestrutura são refletidas automaticamente
- ✅ **Escalabilidade**: Fácil de replicar para outros ambientes

### **Verificar Subnets Atuais:**
```bash
# Ver subnets públicas atuais
./scripts/update-subnets.sh

# Ou via Terraform
terraform output public_subnet_ids
```

---

## ⚡ Quick Start 

```bash
# 1. Clone o repositório
git clone <repository-url>
cd terraform-lab

# 2. Configure suas variáveis
cp terraform.tfvars.example terraform.tfvars
# Edite terraform.tfvars com suas configurações

# 3. Deploy da infraestrutura
terraform init
terraform plan
terraform apply

# 4. Conecte ao cluster (usando scripts de automação)
chmod +x scripts/*.sh
./scripts/connect-to-cluster.sh

# 5. Valide o ingress controller
./scripts/validate-ingress.sh

# 6. Configure Route53 (se necessário)
./scripts/apply-route53.sh

# 7. Teste a configuração
./scripts/test-route53.sh
```

**🔄 Para Atualizações do Cluster:**
```bash
# Sequência completa de update
chmod +x scripts/*.sh
./scripts/update-cluster-direct.sh
./scripts/connect-to-cluster.sh
./scripts/validate-ingress.sh
```

## 📋 Revisão Completa: Criar, Atualizar e Deletar

### **🎯 Guia Passo a Passo para Todas as Operações**

Esta seção fornece um guia completo para todas as operações principais do projeto.

#### **🚀 1. CRIAR INFRAESTRUTURA (Primeira Vez)**

##### **Passo 1: Preparação**
```bash
# 1. Clone o repositório
git clone <repository-url>
cd terraform-vpc

# 2. Configure AWS CLI
aws configure --profile default

# 3. Configure terraform.tfvars
cp terraform.tfvars.example terraform.tfvars
# Edite terraform.tfvars com suas configurações
```

##### **Passo 2: Deploy da Infraestrutura**
```bash
# 1. Inicializar Terraform
terraform init

# 2. Verificar o plano
terraform plan

# 3. Aplicar as mudanças
terraform apply
```

##### **Passo 3: Configurar Acesso**
```bash
# 1. Tornar scripts executáveis
chmod +x scripts/*.sh

# 2. Conectar ao cluster
./scripts/connect-to-cluster.sh

# 3. Verificar conectividade
kubectl get nodes
```

##### **Passo 4: Validar Funcionamento**
```bash
# 1. Verificação completa pós-deploy
./scripts/post-deploy.sh

# 2. Verificar ingress controller
./scripts/validate-ingress.sh

# 3. Testar aplicação (se configurada)
./scripts/test-ingress.sh

# 4. Configurar Route53 (se necessário)
./scripts/apply-route53.sh
```

#### **🔄 2. ATUALIZAR INFRAESTRUTURA**

##### **Passo 1: Backup e Preparação**
```bash
# 1. Backup do estado atual
terraform state pull > terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)

# 2. Verificar status atual
kubectl get nodes
kubectl version --short
```

##### **Passo 2: Atualizar Cluster (Primeiro)**
```bash
# 1. Editar terraform.tfvars (se necessário)
# cluster_version = "1.31"

# 2. Executar update do cluster
./scripts/update-cluster-direct.sh

# 3. Aguardar conclusão e verificar
kubectl get nodes
kubectl version --short
```

##### **Passo 3: Atualizar Recursos Kubernetes (Depois)**
```bash
# 1. Reconectar ao cluster atualizado
./scripts/connect-to-cluster.sh

# 2. Atualizar recursos Kubernetes (se necessário)
./scripts/update-cluster.sh

# 3. Verificar recursos
kubectl get pods -n kube-system
kubectl get pods -n ingress-nginx
```

##### **Passo 4: Validação Pós-Update**
```bash
# 1. Verificar conectividade
./scripts/connect-to-cluster.sh

# 2. Validar ingress controller
./scripts/validate-ingress.sh

# 3. Testar aplicações
./scripts/test-ingress.sh

# 4. Verificar Route53 (se configurado)
./scripts/test-route53.sh
```

#### **🧹 3. DELETAR INFRAESTRUTURA**

##### **Passo 1: Preparação para Deletar**
```bash
# 1. Backup final do estado
terraform state pull > terraform.tfstate.final.$(date +%Y%m%d_%H%M%S)

# 2. Verificar recursos que serão deletados
terraform plan -destroy

# 3. Listar recursos atuais
terraform state list
```

##### **Passo 2: Deletar Recursos Kubernetes (Primeiro)**
```bash
# 1. Deletar aplicações Helm
kubectl delete namespace ingress-nginx --ignore-not-found=true

# 2. Deletar outras aplicações
kubectl delete -f examples/name-app.yaml --ignore-not-found=true

# 3. Verificar se não há recursos pendentes
kubectl get all --all-namespaces
```

##### **Passo 3: Deletar Infraestrutura AWS**
```bash
# 1. Executar destroy
terraform destroy

# 2. Confirmar quando perguntado
# Digite 'yes' para confirmar

# 3. Aguardar conclusão
```

##### **Passo 4: Limpeza Final**
```bash
# 1. Remover arquivos locais
rm -rf .terraform
rm -f .terraform.lock.hcl

# 2. Limpar kubeconfig (opcional)
kubectl config delete-context arn:aws:eks:us-east-1:ACCOUNT:cluster/my-eks-cluster

# 3. Verificar se tudo foi deletado
aws eks list-clusters --region us-east-1 --profile default
```

#### **📋 Checklist de Operações**

##### **✅ Checklist para Criação**
- [ ] AWS CLI configurado
- [ ] terraform.tfvars configurado
- [ ] terraform init executado
- [ ] terraform plan sem erros
- [ ] terraform apply concluído
- [ ] kubectl conectado ao cluster
- [ ] Nodes funcionando
- [ ] Verificação pós-deploy executada
- [ ] Ingress controller validado
- [ ] Aplicações testadas

##### **✅ Checklist para Update**
- [ ] Backup do terraform.tfstate
- [ ] terraform.tfvars atualizado
- [ ] Cluster atualizado primeiro
- [ ] Recursos Kubernetes atualizados depois
- [ ] Conectividade verificada
- [ ] Aplicações testadas
- [ ] Route53 validado (se aplicável)

##### **✅ Checklist para Deletar**
- [ ] Backup final do terraform.tfstate
- [ ] Aplicações Kubernetes deletadas
- [ ] terraform destroy executado
- [ ] Recursos AWS deletados
- [ ] Arquivos locais limpos
- [ ] kubeconfig limpo

#### **🚨 Troubleshooting por Operação**

##### **Problemas na Criação**
```bash
# Erro: "Provider não encontrado"
terraform init -upgrade

# Erro: "Permissões AWS"
aws sts get-caller-identity --profile default

# Erro: "VPC já existe"
terraform import aws_vpc.this vpc-12345678
```

##### **Problemas no Update**
```bash
# Erro: "Cluster não está pronto"
aws eks wait cluster-active --name my-eks-cluster --region us-east-1 --profile default

# Erro: "Autenticação Kubernetes"
./scripts/update-cluster-direct.sh

# Erro: "Recursos não encontrados"
kubectl get all --all-namespaces
```

##### **Problemas na Deleção**
```bash
# Erro: "Recursos dependentes"
terraform destroy -target=module.eks.helm_release.apps

# Erro: "Load Balancer não deletado"
aws elbv2 describe-load-balancers --region us-east-1 --profile default

# Erro: "VPC não deletado"
aws ec2 describe-vpcs --region us-east-1 --profile default
```

#### **⏱️ Tempos Estimados**

| Operação | Tempo Estimado | Observações |
|----------|----------------|-------------|
| **Criação** | 15-20 minutos | Depende da velocidade da AWS |
| **Update Cluster** | 10-15 minutos | Apenas versão do cluster |
| **Update Completo** | 20-30 minutos | Cluster + recursos Kubernetes |
| **Deleção** | 10-15 minutos | Pode variar com dependências |

#### **🔧 Comandos de Verificação Rápida**

```bash
# Status geral
terraform show
kubectl get nodes
kubectl version --short

# Recursos específicos
terraform state list | grep eks
kubectl get pods -n kube-system
kubectl get svc -n ingress-nginx

# Logs e debugging
terraform logs
kubectl logs -n kube-system deployment/coredns
```

#### **📞 Suporte e Recursos**

- **Documentação AWS EKS**: https://docs.aws.amazon.com/eks/
- **Terraform EKS**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster
- **Kubernetes**: https://kubernetes.io/docs/
- **Issues do Projeto**: GitHub Issues

---

**💡 Dica**: Sempre teste operações críticas em ambiente de desenvolvimento antes de aplicar em produção!

**🎯 Para mais detalhes, consulte a seção [Manutenção](#-manutenção)**

### Boas Práticas Implementadas

- **Criptografia**: Secrets criptografados com KMS
- **IAM**: Roles com privilégios mínimos
- **Networking**: Subnets privadas para nodes
- **Logs**: Auditoria habilitada
- **Updates**: Versões fixas para addons

### Recomendações Adicionais

- Configure Network Policies
- Use Pod Security Standards
- Implemente RBAC granular
- Configure backup de etcd
- Monitore logs de auditoria

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo LICENSE para mais detalhes.

## 🆘 Suporte

Para suporte e dúvidas:

- Abra uma issue no GitHub
- Consulte a documentação da AWS EKS
- Verifique os logs do Terraform

**Desenvolvido com ❤️ para a comunidade Kubernetes**