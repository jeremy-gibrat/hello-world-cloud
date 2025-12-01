#!/bin/bash

# Script pour supprimer le déploiement

set -e

RELEASE_NAME="hello-world"

echo "🗑️  Suppression du déploiement Helm..."
helm uninstall $RELEASE_NAME || true

echo "🧹 Nettoyage terminé!"
