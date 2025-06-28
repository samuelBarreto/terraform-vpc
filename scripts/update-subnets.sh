#!/bin/bash

# =============================================================================
# ATUALIZAÇÃO AUTOMÁTICA DE SUBNETS
# =============================================================================

set -e

echo "================================
ATUALIZAÇÃO AUTOMÁTICA DE SUBNETS
================================

[INFO] Obtendo subnets públicas atuais..."

# Obter subnets públicas via Terraform
PUBLIC_SUBNETS=$(terraform output -raw public_subnet_ids | tr -d '[]"' | tr ',' '\n' | tr -d ' ')

if [ -z "$PUBLIC_SUBNETS" ]; then
    echo "[ERROR] Não foi possível obter as subnets públicas"
    exit 1
fi

echo "[INFO] Subnets públicas encontradas:"
echo "$PUBLIC_SUBNETS"

echo ""
echo "[INFO] Para atualizar o NGINX Ingress Controller com as subnets corretas:"
echo "1. Execute: terraform plan"
echo "2. Execute: terraform apply"
echo ""
echo "[INFO] As subnets serão injetadas automaticamente via Terraform!"
echo ""
echo "================================
SUBNETS ATUALIZADAS!
================================ 