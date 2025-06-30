#!/bin/bash

# Script para aplicar a configuração do Route53
# Uso: ./scripts/apply-route53.sh [DOMAIN_NAME] [AWS_REGION] [AWS_PROFILE]
# Exemplo: ./scripts/apply-route53.sh plannerdirect.com us-east-1 admin-samuel

set -e

# Parâmetros via linha de comando com valores padrão
DOMAIN_NAME=${1:-"plannerdirect.com"}
AWS_REGION=${2:-"us-east-1"}
AWS_PROFILE=${3:-"admin-samuel"}

echo "🌐 APLICANDO CONFIGURAÇÃO ROUTE 53"
echo "=================================="
echo ""
echo "📋 Parâmetros utilizados:"
echo "   Domínio: $DOMAIN_NAME"
echo "   Região: $AWS_REGION"
echo "   Perfil AWS: $AWS_PROFILE"
echo ""

echo "📋 Verificando zona hospedada..."

# Verificar se a zona hospedada existe
ZONE_ID=$(aws route53 list-hosted-zones --profile $AWS_PROFILE --query "HostedZones[?Name=='$DOMAIN_NAME.'].Id" --output text)

if [ -z "$ZONE_ID" ]; then
    echo "❌ Zona hospedada para $DOMAIN_NAME não encontrada!"
    echo "   Certifique-se de que o domínio está configurado no Route 53"
    exit 1
fi

echo "✅ Zona hospedada encontrada: $ZONE_ID"

echo ""
echo "🔍 Obtendo endereço do Load Balancer..."

# Obter endereço do Load Balancer
LB_HOSTNAME=$(kubectl get svc nginx-ingress-ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

if [ -z "$LB_HOSTNAME" ]; then
    echo "❌ Não foi possível obter o endereço do Load Balancer"
    echo "   Execute primeiro: ./scripts/validate-ingress.sh"
    exit 1
fi

echo "✅ Load Balancer: $LB_HOSTNAME"

echo ""
echo "🔍 Detectando HostedZoneId do Load Balancer..."

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
    echo "❌ Região do Load Balancer não suportada: $LB_HOSTNAME"
    echo "   Regiões suportadas: us-east-1, us-west-2, eu-west-1, ap-southeast-1"
    exit 1
fi

echo "✅ HostedZoneId do Load Balancer: $LB_HOSTED_ZONE_ID"

echo ""
echo "📝 Criando arquivo de configuração..."

# Criar arquivo de configuração
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

echo "✅ Arquivo route53-change.json criado"

echo ""
echo "🚀 Aplicando mudanças no Route 53..."

# Aplicar mudanças
CHANGE_ID=$(aws route53 change-resource-record-sets --profile $AWS_PROFILE --hosted-zone-id $ZONE_ID --change-batch file://route53-change.json --query 'ChangeInfo.Id' --output text)

echo "✅ Change ID: $CHANGE_ID"

echo ""
echo "⏳ Aguardando propagação do DNS..."

# Aguardar propagação
aws route53 wait resource-record-sets-changed --profile $AWS_PROFILE --id $CHANGE_ID

echo "✅ DNS propagado com sucesso!"

echo ""
echo "🎉 Configuração do Route53 aplicada!"
echo "===================================="
echo "📝 Resumo:"
echo "   ✅ Zona hospedada: $ZONE_ID"
echo "   ✅ Load Balancer: $LB_HOSTNAME"
echo "   ✅ HostedZoneId: $LB_HOSTED_ZONE_ID"
echo "   ✅ Change ID: $CHANGE_ID"
echo ""
echo "🌐 URLs configuradas:"
echo "   http://$DOMAIN_NAME"
echo "   http://www.$DOMAIN_NAME"
echo ""
echo "🔍 Para testar, execute:"
echo "   ./scripts/test-route53.sh $DOMAIN_NAME $AWS_REGION $AWS_PROFILE" 