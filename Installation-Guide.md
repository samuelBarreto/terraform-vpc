# 🛠️ Guia de Instalação

## 📋 **Pré-requisitos**

### **1. Ferramentas Necessárias**

```bash
# Terraform (versão 1.7.0 ou superior)
terraform --version

# AWS CLI (versão 2.0 ou superior)
aws --version

# kubectl (versão 1.28 ou superior)
kubectl version --client

# Helm (versão 3.0 ou superior)
helm version
```

### **2. Configuração AWS**

```bash
# Configure suas credenciais AWS
aws configure

# Ou use um profile específico
aws configure --profile production
```

### **3. Permissões AWS Necessárias**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "eks:*",
        "iam:*",
        "kms:*",
        "vpc:*",
        "elasticloadbalancing:*",
        "autoscaling:*",
        "cloudwatch:*",
        "logs:*",
        "s3:*"
      ],
      "Resource": "*"
    }
  ]
}
```

## 🚀 **Instalação Passo a Passo**

### **Passo 1: Clone o Repositório**

```bash
# Clone o repositório
git clone https://github.com/seu-usuario/terraform-vpc.git
cd terraform-vpc

# Verifique a estrutura
ls -la
```

### **Passo 2: Configure as Variáveis**

```bash
# Copie o arquivo de exemplo
cp terraform.tfvars.example terraform.tfvars

# Edite as variáveis
nano terraform.tfvars
```

**Exemplo de configuração:**

```hcl
# Configurações básicas
name = "meu-eks-cluster"
environment = "production"
aws_region = "us-east-1"

# VPC
vpc_cidr = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

# EKS
cluster_version = "1.28"
service_ipv4_cidr = "172.20.0.0/16"

# Node Groups
node_groups = {
  system = {
    instance_types = ["t3.medium"]
    capacity_type = "ON_DEMAND"
    min_size = 1
    max_size = 3
    desired_size = 2
  }
  application = {
    instance_types = ["t3.large"]
    capacity_type = "SPOT"
    min_size = 2
    max_size = 10
    desired_size = 3
  }
}
```

### **Passo 3: Inicialize o Terraform**

```bash
# Inicialize o Terraform
terraform init

# Verifique se tudo está configurado
terraform validate
```

### **Passo 4: Planeje a Infraestrutura**

```bash
# Gere o plano
terraform plan -out=tfplan

# Revise o plano cuidadosamente
terraform show tfplan
```

### **Passo 5: Aplique as Mudanças**

```bash
# Aplique a infraestrutura
terraform apply tfplan

# Ou aplique diretamente (não recomendado para produção)
terraform apply
```

### **Passo 6: Configure o kubectl**

```bash
# Atualize o kubeconfig
aws eks update-kubeconfig --name meu-eks-cluster --region us-east-1

# Teste a conexão
kubectl get nodes
kubectl get pods --all-namespaces
```

## 🔧 **Configurações Avançadas**

### **1. Múltiplos Ambientes**

```bash
# Desenvolvimento
terraform workspace new dev
terraform apply -var-file=dev.tfvars

# Staging
terraform workspace new staging
terraform apply -var-file=staging.tfvars

# Produção
terraform workspace new prod
terraform apply -var-file=prod.tfvars
```

### **2. Backend Remoto (S3)**

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket = "meu-terraform-state"
    key    = "eks/terraform.tfstate"
    region = "us-east-1"
  }
}
```

### **3. Variáveis de Ambiente**

```bash
# Configure variáveis de ambiente
export TF_VAR_environment="production"
export TF_VAR_aws_region="us-east-1"
export TF_VAR_cluster_version="1.28"
```

## 🧪 **Verificação da Instalação**

### **1. Teste o Cluster EKS**

```bash
# Verifique os nodes
kubectl get nodes -o wide

# Verifique os namespaces
kubectl get namespaces

# Verifique os pods do sistema
kubectl get pods -n kube-system
```

### **2. Teste o Load Balancer**

```bash
# Verifique os Load Balancers
aws elbv2 describe-load-balancers --region us-east-1

# Verifique os Security Groups
aws ec2 describe-security-groups --filters Name=group-name,Values=*eks*
```

### **3. Teste o Ingress Controller**

```bash
# Verifique se o NGINX Ingress está funcionando
kubectl get pods -n ingress-nginx

# Teste o acesso
kubectl get svc -n ingress-nginx
```

## 🚨 **Troubleshooting**

### **Problemas Comuns**

#### **1. Erro de Permissões AWS**
```bash
# Verifique suas credenciais
aws sts get-caller-identity

# Configure o profile correto
export AWS_PROFILE=production
```

#### **2. Erro de VPC**
```bash
# Verifique se a VPC existe
aws ec2 describe-vpcs --filters Name=tag:Name,Values=*eks*

# Verifique as subnets
aws ec2 describe-subnets --filters Name=vpc-id,Values=vpc-xxxxx
```

#### **3. Erro de EKS**
```bash
# Verifique o status do cluster
aws eks describe-cluster --name meu-eks-cluster --region us-east-1

# Verifique os node groups
aws eks describe-nodegroup --cluster-name meu-eks-cluster --nodegroup-name system
```

## 📊 **Monitoramento Pós-Instalação**

### **1. CloudWatch Logs**

```bash
# Verifique os logs do cluster
aws logs describe-log-groups --log-group-name-prefix /aws/eks/meu-eks-cluster
```

### **2. Métricas do Cluster**

```bash
# Verifique as métricas no CloudWatch
aws cloudwatch list-metrics --namespace AWS/EKS
```

### **3. Custos**

```bash
# Verifique os custos no Cost Explorer
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 --granularity MONTHLY --metrics BlendedCost
```

## 🔄 **Atualizações**

### **1. Atualizar o Cluster**

```bash
# Planeje a atualização
terraform plan -var="cluster_version=1.29"

# Aplique a atualização
terraform apply
```

### **2. Atualizar Node Groups**

```bash
# Atualize as configurações dos node groups
terraform plan -var='node_groups={"system":{"instance_types=["t3.large"]}}'

# Aplique as mudanças
terraform apply
```

## 📚 **Próximos Passos**

1. **Deploy de Aplicações**: [Application-Deployment](Application-Deployment)
2. **Configuração de Monitoramento**: [Logging-and-Monitoring](Logging-and-Monitoring)
3. **Configuração de Segurança**: [Security-and-Compliance](Security-and-Compliance)
4. **Troubleshooting**: [Troubleshooting](Troubleshooting)

---

**Versão do Guia**: 1.0.0  
**Última Atualização**: $(date) 