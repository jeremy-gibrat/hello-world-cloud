#!/bin/bash

# Script pour construire les images Docker et les charger dans Minikube

set -e

echo "🔨 Construction de l'image Docker du backend..."
cd backend
docker build -t hello-backend:latest .
cd ..

echo "🔨 Construction de l'image Docker du frontend..."
cd frontend
docker build -t hello-frontend:latest .
cd ..

echo "📦 Chargement des images dans Minikube..."
minikube image load hello-backend:latest
minikube image load hello-frontend:latest

echo "✅ Images construites et chargées avec succès!"
echo ""
echo "Images disponibles:"
minikube image ls | grep hello
