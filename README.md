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
terraform-vpc/
├── main.tf                 # Configuração principal
├── variables.tf            # Variáveis do projeto
├── outputs.tf              # Outputs do projeto
├── versions.tf             # Versões dos providers
├── terraform.tfvars        # Valores das variáveis
├── README.md               # Documentação
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

## 📋 Pré-requisitos

- Terraform >= 1.0
- AWS CLI configurado
- kubectl instalado
- Helm instalado (opcional)

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
# Atualizar kubeconfig
aws eks update-kubeconfig --region us-east-1 --name my-eks-cluster

# Verificar conexão
kubectl get nodes
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
    set = [
      {
        name  = "controller.service.externalTrafficPolicy"
        value = "Local"
      }
    ]
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

## 🔒 Segurança

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

## **🌐 Configuração de Domínio Personalizado**

### **Usando seu próprio domínio (ex: plannerdirect.com)**

1. **Configure o NGINX Ingress Controller:**
   ```bash
   # As subnets são injetadas automaticamente pelo Terraform
   terraform init
   terraform plan
   terraform apply
   ```

2. **Configure o Route 53:**
   ```bash
   # Execute o script de configuração do Route 53
   chmod +x scripts/setup-route53.sh
   ./scripts/setup-route53.sh
   ```
lo fornecido o
3. **Aplique sua aplicação:**
   ```bash
   # Use o exempu crie sua própria aplicação
   kubectl apply -f examples/plannerdirect-app.yaml
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

**Desenvolvido com ❤️ para a comunidade Kubernetes**