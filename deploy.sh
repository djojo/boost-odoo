#!/bin/bash

# Script de déploiement automatique sur le VPS
# Usage: ./deploy.sh [production|staging]

set -e

ENV=${1:-production}
REMOTE_USER="root"
REMOTE_HOST="votre-vps-ip-ou-domaine"
REMOTE_PATH="/opt/boost-odoo"

echo "🚀 Déploiement de Boost Odoo en mode: $ENV"

# Couleurs pour les logs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Vérifier que nous sommes sur la bonne branche
CURRENT_BRANCH=$(git branch --show-current)
echo -e "${YELLOW}📌 Branche actuelle: $CURRENT_BRANCH${NC}"

if [ "$ENV" = "production" ] && [ "$CURRENT_BRANCH" != "main" ] && [ "$CURRENT_BRANCH" != "master" ]; then
    echo -e "${RED}⚠️  Attention: Vous n'êtes pas sur la branche main/master${NC}"
    read -p "Continuer quand même? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Vérifier qu'il n'y a pas de modifications non commitées
if [[ -n $(git status -s) ]]; then
    echo -e "${RED}❌ Il y a des modifications non commitées${NC}"
    git status -s
    exit 1
fi

# Pusher les dernières modifications
echo -e "${GREEN}📤 Push des modifications sur Git...${NC}"
git push origin $CURRENT_BRANCH

# Se connecter au VPS et déployer
echo -e "${GREEN}🔧 Connexion au VPS et déploiement...${NC}"

ssh $REMOTE_USER@$REMOTE_HOST << ENDSSH
    set -e
    
    # Aller dans le dossier du projet
    cd $REMOTE_PATH
    
    echo "📥 Pull des dernières modifications..."
    git pull origin $CURRENT_BRANCH
    
    # Vérifier que le fichier .env existe
    if [ ! -f .env ]; then
        echo "⚠️  Le fichier .env n'existe pas. Création à partir de .env.example..."
        cp .env.example .env
        echo "⚠️  IMPORTANT: Modifiez le fichier .env avec vos valeurs de production !"
        exit 1
    fi
    
    echo "🐳 Reconstruction et redémarrage des conteneurs..."
    docker-compose -f docker-compose.yml -f docker-compose.prod.yml pull
    docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build
    
    echo "🧹 Nettoyage des images inutilisées..."
    docker system prune -f
    
    echo "📊 État des conteneurs:"
    docker-compose ps
    
    echo "✅ Déploiement terminé avec succès!"
ENDSSH

echo -e "${GREEN}🎉 Déploiement terminé!${NC}"
echo -e "${YELLOW}📝 N'oubliez pas de:${NC}"
echo "   1. Vérifier les logs: ssh $REMOTE_USER@$REMOTE_HOST 'cd $REMOTE_PATH && docker-compose logs -f'"
echo "   2. Mettre à jour vos modules dans Odoo si nécessaire"
echo "   3. Tester votre application sur https://votre-domaine.com"

