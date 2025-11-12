#!/bin/bash

# Script pour ajouter un nouveau client Odoo multi-tenant
# Usage: ./add-client.sh <db_name> <domain> [subdomain]
#
# Exemples:
#   ./add-client.sh casaobras casaobras.com erp
#   ./add-client.sh iya iya.com crm
#   ./add-client.sh client3 client3.com admin

set -e

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
DB_NAME=$1
DOMAIN=$2
SUBDOMAIN=${3:-erp}  # Par défaut: erp
FULL_DOMAIN="${SUBDOMAIN}.${DOMAIN}"
CADDY_FILE="./caddy/sites/${DB_NAME}.caddy"

# Validation
if [ -z "$DB_NAME" ] || [ -z "$DOMAIN" ]; then
    echo -e "${RED}❌ Usage: $0 <db_name> <domain> [subdomain]${NC}"
    echo ""
    echo "Exemples:"
    echo "  $0 casaobras casaobras.com erp"
    echo "  $0 iya iya.com crm"
    echo ""
    exit 1
fi

echo -e "${BLUE}🚀 Configuration d'un nouveau client Odoo${NC}"
echo ""
echo -e "${YELLOW}Base de données:${NC} $DB_NAME"
echo -e "${YELLOW}Domaine complet:${NC} $FULL_DOMAIN"
echo ""

# Vérifier si le fichier existe déjà
if [ -f "$CADDY_FILE" ]; then
    echo -e "${RED}⚠️  Le fichier $CADDY_FILE existe déjà!${NC}"
    read -p "Voulez-vous le remplacer? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Annulé."
        exit 1
    fi
fi

# Créer le fichier Caddy
echo -e "${GREEN}📝 Création de la configuration Caddy...${NC}"
cat > "$CADDY_FILE" << EOF
# Configuration pour le client: $DB_NAME
# Domaine: $FULL_DOMAIN
# Généré le: $(date)

$FULL_DOMAIN {
    # Websocket et Longpolling - Port 8072
    handle /websocket* {
        reverse_proxy odoo:8072
    }
    
    handle /longpolling/* {
        reverse_proxy odoo:8072
    }
    
    # Route principale - Port 8069
    handle {
        # Ajouter le paramètre db si absent
        @no_db {
            not query db=*
        }
        rewrite @no_db {uri}?db=$DB_NAME
        
        reverse_proxy odoo:8069
    }
    
    log {
        output file /var/log/caddy/${DB_NAME}.log
    }
}
EOF

echo -e "${GREEN}✅ Fichier créé: $CADDY_FILE${NC}"
echo ""

# Instructions
echo -e "${BLUE}📋 Prochaines étapes:${NC}"
echo ""
echo -e "${YELLOW}1. Créer la base de données Odoo:${NC}"
echo "   - Allez sur: https://votre-domaine-principal.com/web/database/manager"
echo "   - Créez une base nommée: ${GREEN}$DB_NAME${NC}"
echo ""
echo -e "${YELLOW}2. Configurer le DNS:${NC}"
echo "   Type: A"
echo "   Nom: ${GREEN}$SUBDOMAIN${NC}"
echo "   Domaine: $DOMAIN"
echo "   Valeur: ${GREEN}[IP_DE_VOTRE_VPS]${NC}"
echo ""
echo -e "${YELLOW}3. Déployer sur le VPS:${NC}"
echo "   ${GREEN}git add caddy/sites/${DB_NAME}.caddy${NC}"
echo "   ${GREEN}git commit -m \"feat: Ajout du client $DB_NAME\"${NC}"
echo "   ${GREEN}git push origin main${NC}"
echo ""
echo -e "${YELLOW}4. Sur le VPS, récupérer et recharger:${NC}"
echo "   ${GREEN}cd /opt/boost-odoo${NC}"
echo "   ${GREEN}git pull origin main${NC}"
echo "   ${GREEN}docker-compose -f docker-compose.yml -f docker-compose.prod.yml restart caddy${NC}"
echo ""
echo -e "${YELLOW}5. Tester:${NC}"
echo "   ${GREEN}https://$FULL_DOMAIN${NC}"
echo ""
echo -e "${GREEN}🎉 Configuration terminée!${NC}"
echo ""
echo -e "${BLUE}💡 Note:${NC} Le certificat SSL sera généré automatiquement par Caddy"
echo "    après la configuration DNS (1-2 minutes)."

