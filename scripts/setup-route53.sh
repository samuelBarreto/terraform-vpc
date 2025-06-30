#!/bin/bash

# =============================================================================
# CONFIGURAÇÃO DO ROUTE 53 PARA name.COM
# =============================================================================
# Uso: ./scripts/setup-route53.sh [DOMAIN_NAME] [CLUSTER_NAME] [AWS_REGION] [AWS_PROFILE]
# Exemplo: ./scripts/setup-route53.sh name.com my-eks-cluster us-east-1 default

set -e

# Parâmetros via linha de comando com valores padrão
DOMAIN_NAME=${1:-"teste.com"}
CLUSTER_NAME=${2:-"my-eks-cluster"}
AWS_REGION=${3:-"us-east-1"}
AWS_PROFILE=${4:-"default"}

echo "================================
CONFIGURAÇÃO DO ROUTE 53
================================
[INFO] Domínio: $DOMAIN_NAME
[INFO] Cluster: $CLUSTER_NAME
[INFO] Região: $AWS_REGION
[INFO] Perfil AWS: $AWS_PROFILE
================================
1. VERIFICANDO ZONA HOSPEDADA
================================
[INFO] Verificando se a zona hospedada existe..."

ZONE_ID=$(aws route53 list-hosted-zones --profile $AWS_PROFILE --query "HostedZones[?Name=='$DOMAIN_NAME.'].Id" --output text)

if [ -z "$ZONE_ID" ]; then
    echo "[ERROR] Zona hospedada para $DOMAIN_NAME não encontrada!"
    echo "[INFO] Certifique-se de que o domínio está configurado no Route 53"
    exit 1
fi

echo "[INFO] Zona hospedada encontrada: $ZONE_ID"

echo "================================
2. OBTENDO ENDEREÇO DO LOAD BALANCER
================================
[INFO] Verificando se o Ingress Controller está funcionando..."

# Verificar se o namespace existe
if ! kubectl get namespace ingress-nginx >/dev/null 2>&1; then
    echo "[ERROR] Namespace ingress-nginx não existe!"
    echo "[INFO] Execute: kubectl get namespaces"
    exit 1
fi

# Verificar se o serviço existe
if ! kubectl get service nginx-ingress-ingress-nginx-controller -n ingress-nginx >/dev/null 2>&1; then
    echo "[ERROR] Serviço nginx-ingress-ingress-nginx-controller não existe!"
    echo "[INFO] Verificando todos os serviços no namespace:"
    kubectl get services -n ingress-nginx
    exit 1
fi

# Verificar se o Load Balancer já tem um endereço
LB_HOSTNAME=$(kubectl get svc nginx-ingress-ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

if [ -n "$LB_HOSTNAME" ]; then
    echo "[INFO] Load Balancer já está pronto: $LB_HOSTNAME"
else
    echo "[INFO] Aguardando o Load Balancer ficar pronto..."
    kubectl wait --for=condition=Ready service/nginx-ingress-ingress-nginx-controller -n ingress-nginx --timeout=300s
    
    echo "[INFO] Obtendo endereço do Load Balancer..."
    LB_HOSTNAME=$(kubectl get svc nginx-ingress-ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
fi

if [ -z "$LB_HOSTNAME" ]; then
    echo "[ERROR] Não foi possível obter o endereço do Load Balancer"
    echo "[INFO] Verificando status do serviço:"
    kubectl describe service nginx-ingress-ingress-nginx-controller -n ingress-nginx
    exit 1
fi

echo "[INFO] Load Balancer: $LB_HOSTNAME"

echo "================================
3. DETECTANDO HOSTED ZONE ID DO LOAD BALANCER
================================
[INFO] Detectando HostedZoneId baseado na região..."

# Detectar HostedZoneId baseado na região do Load Balancer
if [[ "$LB_HOSTNAME" == *".elb.us-east-1.amazonaws.com" ]]; then
    LB_HOSTED_ZONE_ID="Z26RNL4JYFTOTI"
elif [[ "$LB_HOSTNAME" == *".elb.us-west-2.amazonaws.com" ]]; then
    LB_HOSTED_ZONE_ID="Z1H1FL5HABSF5"
elif [[ "$LB_HOSTNAME" == *".elb.eu-west-1.amazonaws.com" ]]; then
    LB_HOSTED_ZONE_ID="Z2IFOLAFXWLO4F"
elif [[ "$LB_HOSTNAME" == *".elb.ap-southeast-1.amazonaws.com" ]]; then
    LB_HOSTED_ZONE_ID="Z1LMS91P8CMLE5"
else
    echo "[ERROR] Região do Load Balancer não suportada: $LB_HOSTNAME"
    echo "[INFO] Regiões suportadas: us-east-1, us-west-2, eu-west-1, ap-southeast-1"
    exit 1
fi

echo "[INFO] HostedZoneId do Load Balancer: $LB_HOSTED_ZONE_ID"

echo "================================
4. CRIANDO RECORD SET NO ROUTE 53
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
                    "HostedZoneId": "$LB_HOSTED_ZONE_ID",
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
                    "HostedZoneId": "$LB_HOSTED_ZONE_ID",
                    "DNSName": "$LB_HOSTNAME",
                    "EvaluateTargetHealth": true
                }
            }
        }
    ]
}
EOF

echo "[INFO] Aplicando mudanças no Route 53..."
CHANGE_ID=$(aws route53 change-resource-record-sets --profile $AWS_PROFILE --hosted-zone-id $ZONE_ID --change-batch file://route53-change.json --query 'ChangeInfo.Id' --output text)

echo "[INFO] Change ID: $CHANGE_ID"

echo "================================
5. AGUARDANDO PROPAGAÇÃO DNS
================================
[INFO] Aguardando propagação do DNS..."
aws route53 wait resource-record-sets-changed --profile $AWS_PROFILE --id $CHANGE_ID

echo "[INFO] DNS propagado com sucesso!"

echo "================================
6. APLICANDO APLICAÇÃO
================================
[INFO] Aplicando aplicação do name..."
kubectl apply -f examples/name-app.yaml

echo "[INFO] Aguardando pods ficarem prontos..."
kubectl wait --for=condition=Ready pod -l app=name-app -n name --timeout=300s

echo "================================
7. TESTANDO CONECTIVIDADE
================================
[INFO] Verificando Ingress..."
kubectl get ingress -n name

echo "[INFO] Testando conectividade..."
echo "[INFO] Teste manual: curl -H 'Host: $DOMAIN_NAME' http://$LB_HOSTNAME"

echo "================================
8. INFORMAÇÕES IMPORTANTES
================================
[INFO] Seu domínio está configurado:"
echo "http://$DOMAIN_NAME"
echo "http://www.$DOMAIN_NAME"
echo ""
echo "[INFO] Para verificar se está funcionando:"
echo "curl -I http://$DOMAIN_NAME"
echo ""
echo "[INFO] Para ver logs da aplicação:"
echo "kubectl logs -n name -l app=name-app"
echo ""
echo "[INFO] Para ver logs do Ingress:"
echo "kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx"
echo ""
echo "================================
CONFIGURAÇÃO CONCLUÍDA!
================================" 