# Diagrama de Arquitetura - EKS Cluster com VPC

## Visão Geral da Arquitetura

Este diagrama mostra a infraestrutura completa criada pelo projeto Terraform, incluindo VPC, EKS Cluster, Node Groups, IAM Roles, KMS e componentes de rede.

## Diagrama Principal

```mermaid
    graph TB
    %% Estilo dos nós
    classDef vpc fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef eks fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef iam fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef security fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef network fill:#fce4ec,stroke:#880e4f,stroke-width:2px
    classDef compute fill:#f1f8e9,stroke:#33691e,stroke-width:2px

    %% Internet
    Internet[🌐 Internet]
    
    %% VPC e Componentes de Rede
    subgraph VPC ["🏢 VPC (10.0.0.0/16)"]
        subgraph AZ1 ["🔄 Availability Zone 1 (us-east-1a)"]
            PublicSubnet1["🌍 Public Subnet 1<br/>(10.0.1.0/24)"]
            PrivateSubnet1["🔒 Private Subnet 1<br/>(10.0.11.0/24)"]
        end
        
        subgraph AZ2 ["🔄 Availability Zone 2 (us-east-1b)"]
            PublicSubnet2["🌍 Public Subnet 2<br/>(10.0.2.0/24)"]
            PrivateSubnet2["🔒 Private Subnet 2<br/>(10.0.12.0/24)"]
        end
        
        subgraph AZ3 ["🔄 Availability Zone 3 (us-east-1c)"]
            PublicSubnet3["🌍 Public Subnet 3<br/>(10.0.3.0/24)"]
            PrivateSubnet3["🔒 Private Subnet 3<br/>(10.0.13.0/24)"]
        end
        
        IGW["🌐 Internet Gateway"]
        NAT["🌐 NAT Gateway"]
        EIP["📡 Elastic IP"]
        
        RouteTablePublic["🗺️ Public Route Table<br/>(0.0.0.0/0 → IGW)"]
        RouteTablePrivate["🗺️ Private Route Table<br/>(0.0.0.0/0 → NAT)"]
    end
    
    %% EKS Cluster
    subgraph EKS ["⚙️ EKS Cluster (name)"]
        ControlPlane["🎛️ Control Plane<br/>Kubernetes 1.28"]
        
        subgraph NodeGroups ["🖥️ Managed Node Groups"]
            NodeGroupDefault["📦 Default Node Group<br/>t3.medium x2"]
            NodeGroupCritical["🚨 Critical Node Group<br/>t3.large x1"]
        end
        
        subgraph Addons ["🔧 EKS Addons"]
            CoreDNS["🌐 CoreDNS<br/>DNS Resolution"]
            KubeProxy["🔗 kube-proxy<br/>Networking"]
            VPCCNI["🌐 VPC-CNI<br/>AWS Networking"]
        end
    end
    
    %% IAM Roles
    subgraph IAM ["🔐 IAM Roles & Policies"]
        ClusterRole["👑 EKS Cluster Role<br/>AmazonEKSClusterPolicy"]
        NodeRole["🖥️ Node Group Role<br/>AmazonEKSWorkerNodePolicy<br/>AmazonEKS_CNI_Policy<br/>AmazonEC2ContainerRegistryReadOnly"]
    end
    
    %% KMS
    subgraph KMS ["🔑 KMS Encryption"]
        KMSKey["🔐 KMS Key<br/>EKS Encryption"]
        KMSAlias["🏷️ KMS Alias<br/>alias/my-eks-cluster-eks-key"]
    end
    
    %% AWS Auth
    subgraph Auth ["🔐 AWS Auth ConfigMap"]
        AuthConfigMap["📋 aws-auth<br/>kube-system namespace"]
        UserMapping["👤 User Mappings<br/>IAM Users → K8s Groups"]
        RoleMapping["🎭 Role Mappings<br/>IAM Roles → K8s Groups"]
    end
    
    %% Helm Releases (Futuro)
    subgraph Helm ["📦 Helm Releases Opcional"]
        NginxIngress["🌐 nginx-ingress<br/>Load Balancer"]
        CertManager["🔒 cert-manager<br/>SSL Certificates"]
        MetricsServer["📊 metrics-server<br/>Cluster Metrics"]
    end
    
            %% Conexões
            Internet --> IGW
            IGW --> RouteTablePublic
            RouteTablePublic --> PublicSubnet1
            RouteTablePublic --> PublicSubnet2
            RouteTablePublic --> PublicSubnet3
            
            PublicSubnet1 --> NAT
            PublicSubnet2 --> NAT
            PublicSubnet3 --> NAT
            NAT --> EIP
            EIP --> Internet
            
            RouteTablePrivate --> PrivateSubnet1
            RouteTablePrivate --> PrivateSubnet2
            RouteTablePrivate --> PrivateSubnet3
            
            PrivateSubnet1 --> NodeGroupDefault
            PrivateSubnet2 --> NodeGroupDefault
            PrivateSubnet3 --> NodeGroupDefault
            
            PrivateSubnet1 --> NodeGroupCritical
            PrivateSubnet2 --> NodeGroupCritical
            
            ControlPlane --> CoreDNS
            ControlPlane --> KubeProxy
            ControlPlane --> VPCCNI
            
            NodeGroupDefault --> CoreDNS
            NodeGroupDefault --> KubeProxy
            NodeGroupDefault --> VPCCNI
            NodeGroupCritical --> CoreDNS
            NodeGroupCritical --> KubeProxy
            NodeGroupCritical --> VPCCNI
            
            ClusterRole --> ControlPlane
            NodeRole --> NodeGroupDefault
            NodeRole --> NodeGroupCritical
            
            KMSKey --> ControlPlane
            KMSAlias --> KMSKey
            
            AuthConfigMap --> UserMapping
            AuthConfigMap --> RoleMapping
            AuthConfigMap --> ControlPlane
            
            NginxIngress --> ControlPlane
            CertManager --> ControlPlane
            MetricsServer --> ControlPlane
            
            %% Aplicar estilos
            class VPC,AZ1,AZ2,AZ3,IGW,NAT,EIP,RouteTablePublic,RouteTablePrivate vpc
            class EKS,ControlPlane,NodeGroups,NodeGroupDefault,NodeGroupCritical,Addons,CoreDNS,KubeProxy,VPCCNI eks
            class IAM,ClusterRole,NodeRole iam
            class KMS,KMSKey,KMSAlias security
            class PublicSubnet1,PublicSubnet2,PublicSubnet3,PrivateSubnet1,PrivateSubnet2,PrivateSubnet3 network
            class NodeGroupDefault,NodeGroupCritical compute
        ```

        ## Diagrama de Segurança

        ```mermaid
        graph LR
            %% Estilo dos nós
            classDef security fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
            classDef network fill:#fce4ec,stroke:#880e4f,stroke-width:2px
            classDef encryption fill:#fff3e0,stroke:#e65100,stroke-width:2px
            
            subgraph Security ["🔒 Camadas de Segurança"]
                subgraph NetworkSecurity ["🌐 Segurança de Rede"]
                    VPCIsolation["🔒 Isolamento VPC"]
                    PrivateSubnets["🔒 Subnets Privadas"]
                    SecurityGroups["🛡️ Security Groups"]
                    NACLs["🛡️ Network ACLs"]
                end
                
                subgraph AccessControl ["🔐 Controle de Acesso"]
                    IAMRoles["👑 IAM Roles"]
                    RBAC["🎭 RBAC Kubernetes"]
                    AWSAuth["📋 AWS Auth ConfigMap"]
                end
                
                subgraph Encryption ["🔐 Criptografia"]
                    KMSEncryption["🔑 KMS Encryption"]
                    SecretsEncryption["🔐 Secrets Encryption"]
                    TransitEncryption["🔐 Transit Encryption"]
                end
                
                subgraph Monitoring ["📊 Monitoramento"]
                    CloudWatchLogs["📝 CloudWatch Logs"]
                    AuditLogs["📋 Audit Logs"]
                    Metrics["📊 Metrics"]
                end
            end
            
            VPCIsolation --> PrivateSubnets
            PrivateSubnets --> SecurityGroups
            SecurityGroups --> NACLs
            
            IAMRoles --> RBAC
            RBAC --> AWSAuth
            
            KMSEncryption --> SecretsEncryption
            SecretsEncryption --> TransitEncryption
            
            CloudWatchLogs --> AuditLogs
            AuditLogs --> Metrics
            
            class Security,NetworkSecurity,VPCIsolation,PrivateSubnets,SecurityGroups,NACLs,AccessControl,IAMRoles,RBAC,AWSAuth,Encryption,KMSEncryption,SecretsEncryption,TransitEncryption,Monitoring,CloudWatchLogs,AuditLogs,Metrics security
        ```

        ## Diagrama de Fluxo de Dados

        ```mermaid
        sequenceDiagram
            participant User as 👤 Usuário
            participant Terraform as 🏗️ Terraform
            participant AWS as ☁️ AWS
            participant EKS as ⚙️ EKS Cluster
            participant Nodes as 🖥️ Worker Nodes
            participant Apps as 📦 Applications
            
            User->>Terraform: terraform apply
            Terraform->>AWS: Criar VPC
            AWS-->>Terraform: VPC criada
            
            Terraform->>AWS: Criar Subnets
            AWS-->>Terraform: Subnets criadas
            
            Terraform->>AWS: Criar IAM Roles
            AWS-->>Terraform: IAM Roles criadas
            
            Terraform->>AWS: Criar KMS Key
            AWS-->>Terraform: KMS Key criada
            
            Terraform->>AWS: Criar EKS Cluster
            AWS->>EKS: Provisionar Control Plane
            EKS-->>AWS: Control Plane pronto
            AWS-->>Terraform: EKS Cluster criado
            
            Terraform->>AWS: Criar Node Groups
            AWS->>Nodes: Provisionar EC2 Instances
            Nodes->>EKS: Registrar nodes
            EKS-->>AWS: Nodes registrados
            AWS-->>Terraform: Node Groups criados
            
            Terraform->>EKS: Instalar Addons
            EKS->>EKS: CoreDNS
            EKS->>EKS: kube-proxy
            EKS->>EKS: VPC-CNI
            EKS-->>Terraform: Addons instalados
            
            Terraform->>EKS: Configurar AWS Auth
            EKS-->>Terraform: AWS Auth configurado
            
            Terraform-->>User: ✅ Infraestrutura criada
            
            User->>AWS: aws eks update-kubeconfig
            AWS-->>User: kubeconfig atualizado
            
            User->>EKS: kubectl get nodes
            EKS-->>User: Lista de nodes
            
            User->>Apps: Deploy applications
            Apps->>Nodes: Schedule pods
            Nodes-->>Apps: Pods running
        ```

        ## Componentes da Arquitetura

        ### 🏢 **VPC e Networking**
        - **VPC**: Rede isolada 10.0.0.0/16
        - **Subnets Públicas**: Para Load Balancers e NAT Gateway
        - **Subnets Privadas**: Para Worker Nodes do EKS
        - **Internet Gateway**: Conectividade com internet
        - **NAT Gateway**: Internet para subnets privadas
        - **Route Tables**: Controle de roteamento

        ### ⚙️ **EKS Cluster**
        - **Control Plane**: Kubernetes 1.28 gerenciado pela AWS
        - **Node Groups**: Workers EC2 gerenciados
        - **Addons**: CoreDNS, kube-proxy, VPC-CNI
        - **Encryption**: Secrets criptografados com KMS

        ### 🔐 **Segurança**
        - **IAM Roles**: Permissões mínimas necessárias
        - **AWS Auth**: Mapeamento IAM → Kubernetes
        - **KMS**: Criptografia de dados em repouso
        - **Security Groups**: Controle de tráfego

        ### 📦 **Aplicações (Opcional)**
        - **Helm Releases**: Instalação automática de apps
        - **Ingress Controllers**: Load balancing
        - **Cert Managers**: SSL/TLS
        - **Monitoring**: Métricas e logs

        ## Benefícios da Arquitetura

        ✅ **Alta Disponibilidade**: Múltiplas AZs  
        ✅ **Segurança**: Subnets privadas + IAM + KMS  
        ✅ **Escalabilidade**: Auto-scaling de nodes  
        ✅ **Manutenibilidade**: Terraform + módulos  
        ✅ **Observabilidade**: Logs e métricas  
        ✅ **Flexibilidade**: Helm para aplicações  

        ---
