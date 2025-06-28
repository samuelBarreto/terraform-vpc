# 📊 Diagramas de Arquitetura - EKS Cluster

Este diretório contém os diagramas de arquitetura do projeto EKS Cluster com VPC.

## 📁 Arquivos

- **`architecture-diagram.md`** - Diagramas Mermaid interativos
- **`architecture-ascii.txt`** - Diagrama ASCII simples
- **`README.md`** - Este arquivo

## 🎯 Como Visualizar os Diagramas

### Diagramas Mermaid

Os diagramas Mermaid podem ser visualizados em:

1. **GitHub**: Os diagramas são renderizados automaticamente no GitHub
2. **VS Code**: Instale a extensão "Mermaid Preview"
3. **Online**: Use o [Mermaid Live Editor](https://mermaid.live/)

### Diagrama ASCII

O diagrama ASCII pode ser visualizado em qualquer editor de texto ou terminal.

## 🏗️ Componentes da Arquitetura

### 🌐 **Camada de Rede**
- **VPC**: Rede isolada 10.0.0.0/16
- **Subnets**: 3 AZs com subnets públicas e privadas
- **Internet Gateway**: Conectividade com internet
- **NAT Gateway**: Internet para subnets privadas
- **Route Tables**: Controle de roteamento

### ⚙️ **Camada do EKS**
- **Control Plane**: Kubernetes 1.28 gerenciado pela AWS
- **Node Groups**: Workers EC2 com auto-scaling
- **Addons**: CoreDNS, kube-proxy, VPC-CNI
- **Encryption**: Secrets criptografados com KMS

### 🔐 **Camada de Segurança**
- **IAM Roles**: Permissões mínimas necessárias
- **AWS Auth**: Mapeamento IAM → Kubernetes
- **KMS**: Criptografia de dados em repouso
- **Security Groups**: Controle de tráfego

### 📦 **Camada de Aplicações**
- **Helm Releases**: Instalação automática de apps
- **Ingress Controllers**: Load balancing
- **Cert Managers**: SSL/TLS
- **Monitoring**: Métricas e logs

## 🔄 Fluxo de Dados

1. **Internet** → **Internet Gateway** → **VPC**
2. **VPC** → **Subnets Públicas** → **NAT Gateway**
3. **NAT Gateway** → **Subnets Privadas** → **Worker Nodes**
4. **Worker Nodes** → **EKS Control Plane**
5. **EKS Control Plane** → **Applications**

## 🛡️ Camadas de Segurança

### Rede
- Isolamento VPC
- Subnets privadas para workers
- Security Groups
- Network ACLs

### Acesso
- IAM Roles com privilégios mínimos
- RBAC Kubernetes
- AWS Auth ConfigMap

### Criptografia
- KMS para secrets
- Criptografia em trânsito
- Criptografia em repouso

### Monitoramento
- CloudWatch Logs
- Audit Logs
- Métricas do cluster

## 📈 Benefícios da Arquitetura

✅ **Alta Disponibilidade**: Múltiplas AZs  
✅ **Segurança**: Múltiplas camadas de proteção  
✅ **Escalabilidade**: Auto-scaling automático  
✅ **Manutenibilidade**: Infrastructure as Code  
✅ **Observabilidade**: Logs e métricas completos  
✅ **Flexibilidade**: Helm para aplicações  

## 🚀 Como Usar

1. **Visualize os diagramas** para entender a arquitetura
2. **Use o diagrama ASCII** para apresentações simples
3. **Use os diagramas Mermaid** para documentação técnica
4. **Personalize** conforme suas necessidades

## 🔧 Personalização

Para personalizar os diagramas:

1. Edite os arquivos `.md` para diagramas Mermaid
2. Edite o arquivo `.txt` para diagrama ASCII
3. Ajuste cores, estilos e componentes conforme necessário

---
