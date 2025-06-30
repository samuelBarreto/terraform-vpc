#!/bin/bash

# =============================================================================
# DEPLOY COM VARIÁVEIS DE AMBIENTE
# =============================================================================

set -e

echo "================================
DEPLOY COM VARIÁVEIS DE AMBIENTE
================================

[INFO] Verificando variáveis de ambiente..."

# Verificar se as variáveis de ambiente estão definidas
if [ -n "$INGRESS_SUBNETS" ]; then
    echo "[INFO] Usando subnets do Ingress via variável de ambiente:"
    echo "INGRESS_SUBNETS=$INGRESS_SUBNETS"
    
    # Criar arquivo terraform.tfvars temporário com as subnets
    cat > terraform.tfvars.env << EOF
# Configuração via variável de ambiente
ingress_subnets = "$INGRESS_SUBNETS"

# Outras configurações do terraform.tfvars original
$(grep -v "ingress_subnets" terraform.tfvars)
EOF
    
    echo "[INFO] Arquivo terraform.tfvars.env criado com as subnets personalizadas"
    echo "[INFO] Execute: terraform plan -var-file=terraform.tfvars.env"
    echo "[INFO] Execute: terraform apply -var-file=terraform.tfvars.env"
    
else
    echo "[INFO] Variável INGRESS_SUBNETS não definida"
    echo "[INFO] Usando subnets automáticas do Terraform"
    echo "[INFO] Execute: terraform plan"
    echo "[INFO] Execute: terraform apply"
fi

echo ""
echo "================================
OPÇÕES DE USO:
================================

1. **Usar subnets automáticas (padrão):**
   terraform plan
   terraform apply

2. **Usar subnets via variável de ambiente:**
   export INGRESS_SUBNETS=\"subnet-123,subnet-456,subnet-789\"
   ./scripts/deploy-with-env.sh
   terraform plan -var-file=terraform.tfvars.env
   terraform apply -var-file=terraform.tfvars.env

3. **Usar subnets via linha de comando:**
   terraform plan -var='ingress_subnets=\"subnet-123,subnet-456,subnet-789\"'
   terraform apply -var='ingress_subnets=\"subnet-123,subnet-456,subnet-789\"'

================================
CONFIGURAÇÃO CONCLUÍDA!
================================ 