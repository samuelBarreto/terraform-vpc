# =============================================================================
# EXEMPLO AVANÇADO - EKS CLUSTER COM MÚLTIPLAS CONFIGURAÇÕES
# =============================================================================

# Este arquivo demonstra como usar o módulo EKS com configurações avançadas
# Incluindo múltiplos node groups, aplicações Helm e configurações de segurança

# =============================================================================
# CONFIGURAÇÃO AVANÇADA DE NODE GROUPS
# =============================================================================

# Node Group para aplicações gerais
node_groups_general = {
  general = {
    name                   = "general"
    instance_types         = ["t3.medium", "t3.large"]
    capacity_type          = "ON_DEMAND"
    min_size               = 2
    max_size               = 5
    desired_size           = 3
    disk_size              = 30
    ami_type               = "AL2_x86_64"
    force_update_version   = true
    labels = {
      "node.kubernetes.io/role" = "worker"
      "environment"             = "production"
      "node-type"               = "general"
    }
    taints = []
  }
}

# Node Group para aplicações críticas (GPU)
node_groups_critical = {
  critical = {
    name                   = "critical"
    instance_types         = ["g4dn.xlarge", "g4dn.2xlarge"]
    capacity_type          = "ON_DEMAND"
    min_size               = 1
    max_size               = 3
    desired_size           = 2
    disk_size              = 50
    ami_type               = "AL2_x86_64_GPU"
    force_update_version   = true
    labels = {
      "node.kubernetes.io/role" = "worker"
      "environment"             = "production"
      "node-type"               = "critical"
      "accelerator"             = "gpu"
    }
    taints = [
      {
        key    = "dedicated"
        value  = "critical"
        effect = "NO_SCHEDULE"
      }
    ]
  }
}

# Node Group para Spot Instances (economia)
node_groups_spot = {
  spot = {
    name                   = "spot"
    instance_types         = ["t3.medium", "t3.large", "m5.large"]
    capacity_type          = "SPOT"
    min_size               = 1
    max_size               = 10
    desired_size           = 3
    disk_size              = 20
    ami_type               = "AL2_x86_64"
    force_update_version   = true
    labels = {
      "node.kubernetes.io/role" = "worker"
      "environment"             = "production"
      "node-type"               = "spot"
    }
    taints = [
      {
        key    = "spot"
        value  = "true"
        effect = "NO_SCHEDULE"
      }
    ]
  }
}

# =============================================================================
# CONFIGURAÇÃO AVANÇADA DE HELM RELEASES
# =============================================================================

# Stack completo de monitoramento
helm_releases_monitoring = {
  # Prometheus Operator
  prometheus_operator = {
    name             = "prometheus"
    repository       = "https://prometheus-community.github.io/helm-charts"
    chart            = "kube-prometheus-stack"
    version          = "55.5.0"
    namespace        = "monitoring"
    create_namespace = true
    values = {
      prometheus = {
        prometheusSpec = {
          retention = "7d"
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp2"
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "10Gi"
                  }
                }
              }
            }
          }
        }
      }
      grafana = {
        adminPassword = "admin123"
        persistence = {
          enabled = true
          size = "5Gi"
        }
      }
    }
    set = [
      {
        name  = "grafana.enabled"
        value = "true"
      }
    ]
  }
}

# Stack de logging
helm_releases_logging = {
  # Fluent Bit
  fluent_bit = {
    name             = "fluent-bit"
    repository       = "https://fluent.github.io/helm-charts"
    chart            = "fluent-bit"
    version          = "0.20.9"
    namespace        = "logging"
    create_namespace = true
    values = {
      config = {
        service = {
          parsers = {
            docker = {
              format = "json"
              timeKey = "time"
              timeFormat = "%Y-%m-%dT%H:%M:%S.%L"
            }
          }
        }
      }
    }
    set = []
  }
}

# Stack de ingress e certificados
helm_releases_ingress = {
  # Cert Manager
  cert_manager = {
    name             = "cert-manager"
    repository       = "https://charts.jetstack.io"
    chart            = "cert-manager"
    version          = "v1.13.3"
    namespace        = "cert-manager"
    create_namespace = true
    values = {
      installCRDs = true
      global = {
        leaderElection = {
          namespace = "cert-manager"
        }
      }
    }
    set = []
  }
  
  # NGINX Ingress Controller
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
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
            "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
          }
        }
        config = {
          "use-proxy-protocol" = "false"
          "proxy-real-ip-cidr" = "0.0.0.0/0"
        }
        resources = {
          requests = {
            cpu = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu = "200m"
            memory = "256Mi"
          }
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

# Stack de aplicações de exemplo
helm_releases_apps = {
  # Wordpress
  wordpress = {
    name             = "wordpress"
    repository       = "https://charts.bitnami.com/bitnami"
    chart            = "wordpress"
    version          = "19.0.0"
    namespace        = "wordpress"
    create_namespace = true
    values = {
      wordpressUsername = "admin"
      wordpressPassword = "admin123"
      mariadb = {
        enabled = true
        auth = {
          rootPassword = "rootpass"
          database = "wordpress"
          username = "wordpress"
          password = "wordpress"
        }
        primary = {
          persistence = {
            enabled = true
            size = "8Gi"
          }
        }
      }
      persistence = {
        enabled = true
        size = "10Gi"
      }
    }
    set = []
  }
  
  # Redis
  redis = {
    name             = "redis"
    repository       = "https://charts.bitnami.com/bitnami"
    chart            = "redis"
    version          = "17.11.3"
    namespace        = "redis"
    create_namespace = true
    values = {
      auth = {
        enabled = true
        sentinel = true
      }
      master = {
        persistence = {
          enabled = true
          size = "8Gi"
        }
      }
    }
    set = []
  }
}

# =============================================================================
# CONFIGURAÇÃO AVANÇADA DE AWS AUTH
# =============================================================================

# Usuários com diferentes níveis de acesso
aws_auth_users_advanced = [
  # Administrador
  {
    userarn  = "arn:aws:iam::123456789012:user/admin"
    username = "admin"
    groups   = ["system:masters"]
  },
  # Desenvolvedor
  {
    userarn  = "arn:aws:iam::123456789012:user/developer"
    username = "developer"
    groups   = ["system:authenticated", "developers"]
  },
  # DevOps
  {
    userarn  = "arn:aws:iam::123456789012:user/devops"
    username = "devops"
    groups   = ["system:authenticated", "devops"]
  }
]

# Roles com diferentes níveis de acesso
aws_auth_roles_advanced = [
  # Role para CI/CD
  {
    rolearn  = "arn:aws:iam::123456789012:role/eks-cicd-role"
    username = "cicd"
    groups   = ["system:authenticated", "cicd"]
  },
  # Role para aplicações
  {
    rolearn  = "arn:aws:iam::123456789012:role/eks-app-role"
    username = "app"
    groups   = ["system:authenticated", "applications"]
  }
]

# =============================================================================
# CONFIGURAÇÃO DE SEGURANÇA AVANÇADA
# =============================================================================

# Configurações de segurança do cluster
cluster_security_config = {
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  cluster_endpoint_public_access_cidrs = [
    "10.0.0.0/8",    # VPC CIDR
    "172.16.0.0/12", # VPN CIDR
    "192.168.0.0/16" # Office CIDR
  ]
  
  service_ipv4_cidr = "172.20.0.0/16"
  
  # Logs de auditoria
  enabled_cluster_log_types = [
    "api",
    "audit", 
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
}

# =============================================================================
# EXEMPLO DE USO COMPLETO
# =============================================================================

# Para usar esta configuração, você pode combinar as configurações:

# 1. Node Groups combinados
node_groups_combined = merge(
  node_groups_general,
  node_groups_critical,
  node_groups_spot
)

# 2. Helm Releases combinados
helm_releases_combined = merge(
  helm_releases_monitoring,
  helm_releases_logging,
  helm_releases_ingress,
  helm_releases_apps
)

# 3. AWS Auth combinado
aws_auth_combined = {
  users = aws_auth_users_advanced
  roles = aws_auth_roles_advanced
}

# Exemplo de como usar no terraform.tfvars:
# node_groups = node_groups_combined
# helm_releases = helm_releases_combined
# aws_auth_users = aws_auth_combined.users
# aws_auth_roles = aws_auth_combined.roles 