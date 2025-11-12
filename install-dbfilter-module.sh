#!/bin/bash
# Script pour installer le module dbfilter_from_header pour Odoo 18
# Ce module permet à Caddy d'envoyer le nom de la base via header HTTP

set -e

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Installation du module dbfilter_from_header${NC}"
echo ""

# Vérifier si on est sur le VPS
if [ ! -d "/opt/boost-odoo" ]; then
    echo -e "${RED}❌ Ce script doit être exécuté sur le VPS dans /opt/boost-odoo${NC}"
    exit 1
fi

cd /opt/boost-odoo

# 1. Télécharger le module OCA
echo -e "${YELLOW}📥 Téléchargement du module depuis GitHub OCA...${NC}"
if [ -d "/tmp/server-tools" ]; then
    rm -rf /tmp/server-tools
fi

git clone --depth 1 --branch 18.0 https://github.com/OCA/server-tools.git /tmp/server-tools

# 2. Copier dans le dossier addons
echo -e "${YELLOW}📂 Copie du module dans ./addons/${NC}"
mkdir -p ./addons
cp -r /tmp/server-tools/dbfilter_from_header ./addons/

# 3. Vérifier que le module est bien là
if [ -f "./addons/dbfilter_from_header/__manifest__.py" ]; then
    echo -e "${GREEN}✅ Module copié avec succès${NC}"
else
    echo -e "${RED}❌ Erreur: Le module n'a pas été copié correctement${NC}"
    exit 1
fi

# 4. Renommer les bases existantes pour la nouvelle convention
echo ""
echo -e "${YELLOW}📊 Renommage des bases de données...${NC}"
echo -e "${BLUE}Convention: concatener domaine+sous-domaine${NC}"
echo -e "  casaobrasibiza → erpcasaobrasibiza"
echo -e "  ibizaboost → erpibizaboost"
echo ""

docker exec odoo_db psql -U odoo -d postgres << 'SQL'
-- Vérifier si les bases existent avant de les renommer
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_database WHERE datname = 'casaobrasibiza') THEN
        ALTER DATABASE casaobrasibiza RENAME TO erpcasaobrasibiza;
        RAISE NOTICE 'Base casaobrasibiza renommée en erpcasaobrasibiza';
    END IF;
    
    IF EXISTS (SELECT 1 FROM pg_database WHERE datname = 'ibizaboost') THEN
        ALTER DATABASE ibizaboost RENAME TO erpibizaboost;
        RAISE NOTICE 'Base ibizaboost renommée en erpibizaboost';
    END IF;
END $$;
SQL

echo -e "${GREEN}✅ Bases renommées${NC}"

# 5. Redémarrer Odoo pour charger le module
echo ""
echo -e "${YELLOW}🔄 Redémarrage d'Odoo...${NC}"
docker-compose -f docker-compose.yml -f docker-compose.prod.yml down
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

echo ""
echo -e "${YELLOW}⏳ Attente du démarrage d'Odoo (20 secondes)...${NC}"
sleep 20

# 6. Vérifier que le module est chargé
echo ""
echo -e "${BLUE}🔍 Vérification du chargement du module...${NC}"
if docker logs odoo_app 2>&1 | grep -q "dbfilter_from_header"; then
    echo -e "${GREEN}✅ Module dbfilter_from_header chargé !${NC}"
else
    echo -e "${YELLOW}⚠️  Module peut-être pas encore chargé, vérifiez les logs${NC}"
fi

# 7. Afficher les bases actuelles
echo ""
echo -e "${BLUE}📋 Bases de données disponibles :${NC}"
docker exec odoo_db psql -U odoo -d postgres -c "SELECT datname FROM pg_database WHERE datistemplate = false AND datname NOT IN ('postgres') ORDER BY datname;"

echo ""
echo -e "${GREEN}🎉 Installation terminée !${NC}"
echo ""
echo -e "${BLUE}📋 Prochaines étapes :${NC}"
echo -e "1. Testez : ${GREEN}https://erp.casaobrasibiza.com/web/login${NC}"
echo -e "2. Si ça fonctionne, la base ${GREEN}erpcasaobrasibiza${NC} devrait être sélectionnée automatiquement"
echo -e "3. Pour ajouter d'autres clients, utilisez : ${GREEN}./scripts/add-client.sh${NC}"
echo ""

