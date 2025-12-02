#!/bin/bash

# Script pour configurer l'Ingress sur Azure AKS
# Ce script active Azure Application Gateway Ingress Controller ou NGINX Ingress

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

cd "$PROJECT_ROOT"

separator
log_step "Configuration de l'Ingress pour Azure AKS"
separator

# Vérifier les prérequis
check_prerequisites kubectl helm az || exit 1

# Charger la configuration
load_env || exit 1

# Obtenir le cluster name
if [ -f "$PROJECT_ROOT/terraform/terraform.tfstate" ]; then
    cd "$PROJECT_ROOT/terraform"
    CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "")
    RESOURCE_GROUP=$(terraform output -raw resource_group_name 2>/dev/null || echo "")
    cd "$PROJECT_ROOT"
else
    log_error "Terraform state non trouvé. Déployez d'abord l'infrastructure."
    exit 1
fi

if [ -z "$CLUSTER_NAME" ] || [ -z "$RESOURCE_GROUP" ]; then
    log_error "Impossible de récupérer les informations du cluster"
    exit 1
fi

log_info "Cluster: $CLUSTER_NAME"
log_info "Resource Group: $RESOURCE_GROUP"

separator
log_step "Choix du type d'Ingress Controller"
separator

echo "Sélectionnez le type d'Ingress Controller:"
echo "  1) Azure Application Routing (Recommandé - Gratuit, intégré)"
echo "  2) NGINX Ingress Controller (Standard, flexible)"
echo ""
read -p "Votre choix [1]: " choice
choice=${choice:-1}

case $choice in
    1)
        log_step "Configuration d'Azure Application Routing..."
        
        # Vérifier si déjà activé
        addon_enabled=$(az aks show -g "$RESOURCE_GROUP" -n "$CLUSTER_NAME" \
            --query "ingressProfile.webAppRouting.enabled" -o tsv 2>/dev/null || echo "false")
        
        if [ "$addon_enabled" = "true" ]; then
            log_success "Azure Application Routing déjà activé"
        else
            log_info "Activation d'Azure Application Routing..."
            az aks enable-addons \
                --resource-group "$RESOURCE_GROUP" \
                --name "$CLUSTER_NAME" \
                --addons web_application_routing
            
            log_success "Azure Application Routing activé"
        fi
        
        INGRESS_CLASS="webapprouting.kubernetes.azure.com"
        ;;
        
    2)
        log_step "Installation de NGINX Ingress Controller..."
        
        # Ajouter le repo Helm
        helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx 2>/dev/null || true
        helm repo update
        
        # Installer ou upgrader NGINX
        if helm list -n ingress-nginx | grep -q nginx-ingress; then
            log_info "Mise à jour de NGINX Ingress..."
            helm upgrade nginx-ingress ingress-nginx/ingress-nginx \
                --namespace ingress-nginx \
                --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz
        else
            log_info "Installation de NGINX Ingress..."
            kubectl create namespace ingress-nginx 2>/dev/null || true
            helm install nginx-ingress ingress-nginx/ingress-nginx \
                --namespace ingress-nginx \
                --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz
        fi
        
        log_success "NGINX Ingress Controller installé"
        INGRESS_CLASS="nginx"
        ;;
        
    *)
        log_error "Choix invalide"
        exit 1
        ;;
esac

separator
log_step "Configuration du domaine"
separator

echo ""
read -p "Entrez votre domaine (ex: hello-world.example.com) [hello-world.local]: " domain
domain=${domain:-hello-world.local}

log_info "Domaine configuré: $domain"

# Mettre à jour values-azure.yaml
log_step "Mise à jour de values-azure.yaml..."

# Utiliser sed pour mettre à jour le fichier
sed -i.bak "s/className: .*/className: \"$INGRESS_CLASS\"/" "$PROJECT_ROOT/helm/values-azure.yaml"
sed -i.bak "s/host: .*/host: $domain/" "$PROJECT_ROOT/helm/values-azure.yaml"
sed -i.bak "s/enabled: false  # Ingress/enabled: true/" "$PROJECT_ROOT/helm/values-azure.yaml"

log_success "Configuration mise à jour"

separator
log_step "Configuration SSL/TLS (optionnel)"
separator

if confirm "Voulez-vous activer HTTPS avec Let's Encrypt ?" "no"; then
    log_info "Installation de cert-manager..."
    
    # Installer cert-manager
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
    
    log_info "Attendre que cert-manager soit prêt..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=300s
    
    # Créer ClusterIssuer
    cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@${domain}
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: ${INGRESS_CLASS}
EOF
    
    # Activer TLS dans values-azure.yaml
    sed -i.bak "s/enabled: false  # Activez pour HTTPS/enabled: true/" "$PROJECT_ROOT/helm/values-azure.yaml"
    sed -i.bak "s/secretName: \"\"/secretName: hello-world-tls/" "$PROJECT_ROOT/helm/values-azure.yaml"
    sed -i.bak "s/# cert-manager.io/cert-manager.io/" "$PROJECT_ROOT/helm/values-azure.yaml"
    
    log_success "SSL/TLS configuré avec Let's Encrypt"
else
    log_info "HTTPS non activé (peut être activé plus tard)"
fi

# Nettoyer les backups
rm -f "$PROJECT_ROOT/helm/values-azure.yaml.bak"

separator
log_success "Configuration de l'Ingress terminée!"
separator

log_info "Prochaines étapes:"
echo ""
echo "  1. Déployez l'application:"
echo "     make deploy-azure"
echo ""
echo "  2. Récupérez l'IP publique:"
echo "     kubectl get ingress hello-world-ingress"
echo ""
echo "  3. Configurez votre DNS:"
echo "     $domain -> [IP_PUBLIQUE]"
echo ""
echo "  4. Accédez à l'application:"
echo "     http://$domain"
echo ""

if [ "$choice" = "2" ]; then
    log_info "Pour NGINX, vous pouvez aussi obtenir l'IP avec:"
    echo "     kubectl get service -n ingress-nginx"
fi

separator
