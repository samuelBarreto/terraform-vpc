#!/bin/bash

# =============================================================================
# CONFIGURAÇÃO DO ROUTE 53 PARA PLANNERDIRECT.COM
# =============================================================================

set -e

DOMAIN_NAME="plannerdirect.com"
CLUSTER_NAME=${CLUSTER_NAME:-"my-eks-cluster-helm"}
AWS_REGION=${AWS_REGION:-"us-east-1"}

echo "================================
CONFIGURAÇÃO DO ROUTE 53
================================
[INFO] Domínio: $DOMAIN_NAME
[INFO] Cluster: $CLUSTER_NAME
[INFO] Região: $AWS_REGION
================================
1. VERIFICANDO ZONA HOSPEDADA
================================
[INFO] Verificando se a zona hospedada existe..."

ZONE_ID=$(aws route53 list-hosted-zones --query "HostedZones[?Name=='$DOMAIN_NAME.'].Id" --output text)

if [ -z "$ZONE_ID" ]; then
    echo "[ERROR] Zona hospedada para $DOMAIN_NAME não encontrada!"
    echo "[INFO] Certifique-se de que o domínio está configurado no Route 53"
    exit 1
fi

echo "[INFO] Zona hospedada encontrada: $ZONE_ID"

echo "================================
2. OBTENDO ENDEREÇO DO LOAD BALANCER
================================
[INFO] Aguardando o Load Balancer ficar pronto..."
kubectl wait --for=condition=Ready service/nginx-ingress-ingress-nginx-controller -n ingress-nginx --timeout=300s

echo "[INFO] Obtendo endereço do Load Balancer..."
LB_HOSTNAME=$(kubectl get svc nginx-ingress-ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

if [ -z "$LB_HOSTNAME" ]; then
    echo "[ERROR] Não foi possível obter o endereço do Load Balancer"
    exit 1
fi

echo "[INFO] Load Balancer: $LB_HOSTNAME"

echo "================================
3. CRIANDO RECORD SET NO ROUTE 53
================================
[INFO] Criando arquivo de configuração do Route 53..."

cat > route53-change.json << EOF
{
    "Changes": [
        {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "$DOMAIN_NAME",
                "Type": "A",
                "AliasTarget": {
                    "HostedZoneId": "Z35SXDOTRQ7X7K",
                    "DNSName": "$LB_HOSTNAME",
                    "EvaluateTargetHealth": true
                }
            }
        },
        {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "www.$DOMAIN_NAME",
                "Type": "A",
                "AliasTarget": {
                    "HostedZoneId": "Z35SXDOTRQ7X7K",
                    "DNSName": "$LB_HOSTNAME",
                    "EvaluateTargetHealth": true
                }
            }
        }
    ]
}
EOF

echo "[INFO] Aplicando mudanças no Route 53..."
CHANGE_ID=$(aws route53 change-resource-record-sets --hosted-zone-id $ZONE_ID --change-batch file://route53-change.json --query 'ChangeInfo.Id' --output text)

echo "[INFO] Change ID: $CHANGE_ID"

echo "================================
4. AGUARDANDO PROPAGAÇÃO DNS
================================
[INFO] Aguardando propagação do DNS..."
aws route53 wait resource-record-sets-changed --id $CHANGE_ID

echo "[INFO] DNS propagado com sucesso!"

echo "================================
5. APLICANDO APLICAÇÃO
================================
[INFO] Aplicando aplicação do PlannerDirect..."
kubectl apply -f examples/plannerdirect-app.yaml

echo "[INFO] Aguardando pods ficarem prontos..."
kubectl wait --for=condition=Ready pod -l app=plannerdirect-app -n plannerdirect --timeout=300s

echo "================================
6. TESTANDO CONECTIVIDADE
================================
[INFO] Verificando Ingress..."
kubectl get ingress -n plannerdirect

echo "[INFO] Testando conectividade..."
echo "[INFO] Teste manual: curl -H 'Host: $DOMAIN_NAME' http://$LB_HOSTNAME"

echo "================================
7. INFORMAÇÕES IMPORTANTES
================================
[INFO] Seu domínio está configurado:"
echo "http://$DOMAIN_NAME"
echo "http://www.$DOMAIN_NAME"
echo ""
echo "[INFO] Para verificar se está funcionando:"
echo "curl -I http://$DOMAIN_NAME"
echo ""
echo "[INFO] Para ver logs da aplicação:"
echo "kubectl logs -n plannerdirect -l app=plannerdirect-app"
echo ""
echo "[INFO] Para ver logs do Ingress:"
echo "kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx"
echo ""
echo "================================
CONFIGURAÇÃO CONCLUÍDA!
================================ 