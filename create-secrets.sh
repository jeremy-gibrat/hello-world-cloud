#!/bin/bash

# Script pour créer ou mettre à jour les secrets Kubernetes depuis .env

set -e

echo "🔐 Création/mise à jour des secrets Kubernetes depuis .env"
echo ""

# Vérifier que .env existe
if [ ! -f .env ]; then
    echo "❌ Fichier .env non trouvé!"
    echo "   Copiez .env.example vers .env et configurez vos secrets:"
    echo "   cp .env.example .env"
    exit 1
fi

# Charger les variables depuis .env
echo "📝 Chargement de la configuration depuis .env"
export $(cat .env | grep -v '^#' | xargs)

# Vérifier que les variables nécessaires sont définies
if [ -z "$POSTGRES_DB" ] || [ -z "$POSTGRES_USER" ] || [ -z "$POSTGRES_PASSWORD" ]; then
    echo "❌ Variables PostgreSQL manquantes dans .env"
    echo "   Vérifiez: POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD"
    exit 1
fi

if [ -z "$RABBITMQ_USER" ] || [ -z "$RABBITMQ_PASSWORD" ]; then
    echo "❌ Variables RabbitMQ manquantes dans .env"
    echo "   Vérifiez: RABBITMQ_USER, RABBITMQ_PASSWORD"
    exit 1
fi

echo "✅ Variables chargées depuis .env"
echo ""

# Créer/mettre à jour le secret
echo "🔧 Création du secret Kubernetes 'app-secrets'..."

kubectl create secret generic app-secrets \
    --from-literal=postgres-db="$POSTGRES_DB" \
    --from-literal=postgres-user="$POSTGRES_USER" \
    --from-literal=postgres-password="$POSTGRES_PASSWORD" \
    --from-literal=rabbitmq-user="$RABBITMQ_USER" \
    --from-literal=rabbitmq-password="$RABBITMQ_PASSWORD" \
    --dry-run=client -o yaml | kubectl apply -f -

if [ $? -eq 0 ]; then
    echo "✅ Secret 'app-secrets' créé/mis à jour avec succès"
    echo ""
    echo "📋 Secrets configurés:"
    echo "   - PostgreSQL DB: $POSTGRES_DB"
    echo "   - PostgreSQL User: $POSTGRES_USER"
    echo "   - PostgreSQL Password: [HIDDEN]"
    echo "   - RabbitMQ User: $RABBITMQ_USER"
    echo "   - RabbitMQ Password: [HIDDEN]"
else
    echo "❌ Échec de la création du secret"
    exit 1
fi

echo ""
echo "💡 Note: Ce secret sera utilisé par Helm lors du déploiement"
echo "   Les secrets ne sont PAS stockés dans values.yaml"
