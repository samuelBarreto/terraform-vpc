#!/bin/bash

# =============================================================================
# TESTE DO NGINX INGRESS CONTROLLER
# =============================================================================

set -e

CLUSTER_NAME=${CLUSTER_NAME:-"my-eks-cluster"}
AWS_REGION=${AWS_REGION:-"us-east-1"}

echo "================================
TESTE DO NGINX INGRESS CONTROLLER
================================
[INFO] Cluster: $CLUSTER_NAME
[INFO] Região: $AWS_REGION
================================
1. VERIFICANDO NGINX INGRESS CONTROLLER
================================
[INFO] Verificando namespace ingress-nginx..."
kubectl get namespace ingress-nginx

echo "[INFO] Verificando pods do NGINX Ingress Controller..."
kubectl get pods -n ingress-nginx

echo "[INFO] Verificando service do NGINX Ingress Controller..."
kubectl get svc -n ingress-nginx

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
3. APLICANDO EXEMPLO DE APLICAÇÃO
================================
[INFO] Aplicando exemplo de aplicação..."
kubectl apply -f examples/nginx-ingress-example.yaml

echo "[INFO] Aguardando pods da aplicação ficarem prontos..."
kubectl wait --for=condition=Ready pod -l app=nginx-example -n example-app --timeout=300s

echo "[INFO] Verificando pods da aplicação..."
kubectl get pods -n example-app

echo "================================
4. TESTANDO O INGRESS
================================
[INFO] Verificando Ingress..."
kubectl get ingress -n example-app

echo "[INFO] Testando conectividade..."
echo "[INFO] Teste manual: curl -H 'Host: example-app.local' http://$LB_HOSTNAME"

echo "================================
5. INFORMAÇÕES IMPORTANTES
================================
[INFO] Para acessar a aplicação, adicione ao /etc/hosts:"
echo "$LB_HOSTNAME example-app.local"
echo ""
echo "[INFO] Ou teste diretamente:"
echo "curl -H 'Host: example-app.local' http://$LB_HOSTNAME"
echo ""
echo "[INFO] Para ver logs do Ingress Controller:"
echo "kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx"
echo ""
echo "[INFO] Para ver logs da aplicação:"
echo "kubectl logs -n example-app -l app=nginx-example"
echo ""
echo "================================
TESTE CONCLUÍDO!
================================ 