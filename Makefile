.PHONY: help start stop restart logs ps clean shell db-shell backup

help: ## Afficher cette aide
	@echo "Commandes disponibles :"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

start: ## Démarrer les conteneurs Odoo et PostgreSQL
	docker-compose up -d
	@echo "✅ Odoo démarré sur http://localhost:8069"

stop: ## Arrêter les conteneurs
	docker-compose stop
	@echo "✅ Conteneurs arrêtés"

restart: ## Redémarrer les conteneurs
	docker-compose restart
	@echo "✅ Conteneurs redémarrés"

logs: ## Afficher les logs en temps réel
	docker-compose logs -f

logs-odoo: ## Afficher les logs Odoo uniquement
	docker-compose logs -f odoo

logs-db: ## Afficher les logs PostgreSQL uniquement
	docker-compose logs -f db

ps: ## Afficher l'état des conteneurs
	docker-compose ps

clean: ## Arrêter et supprimer les conteneurs
	docker-compose down
	@echo "✅ Conteneurs supprimés"

clean-all: ## Arrêter et supprimer les conteneurs + volumes
	@echo "⚠️  ATTENTION : Cela supprimera toutes vos données !"
	@read -p "Êtes-vous sûr ? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker-compose down -v; \
		rm -rf data/* postgres/*; \
		echo "✅ Tout a été nettoyé"; \
	fi

shell: ## Accéder au shell du conteneur Odoo
	docker-compose exec odoo bash

db-shell: ## Accéder au shell PostgreSQL
	docker-compose exec db psql -U odoo -d postgres

backup: ## Créer une sauvegarde de toutes les bases
	@mkdir -p backups
	@echo "💾 Sauvegarde en cours..."
	@docker-compose exec db pg_dumpall -U odoo > backups/backup_$$(date +%Y%m%d_%H%M%S).sql
	@echo "✅ Sauvegarde créée dans backups/"

backup-data: ## Créer une sauvegarde des filestores
	@mkdir -p backups
	@echo "💾 Sauvegarde des filestores..."
	@tar -czf backups/data_backup_$$(date +%Y%m%d_%H%M%S).tar.gz data/
	@echo "✅ Sauvegarde des filestores créée dans backups/"

update-odoo: ## Mettre à jour l'image Odoo
	docker-compose pull odoo
	docker-compose up -d --force-recreate odoo
	@echo "✅ Image Odoo mise à jour"

build: ## Construire/reconstruire les conteneurs
	docker-compose build --no-cache

prune: ## Nettoyer les images et volumes Docker inutilisés
	@echo "🧹 Nettoyage de Docker..."
	docker system prune -f
	@echo "✅ Nettoyage terminé"

# Commandes de déploiement
deploy-prod: ## Déployer en production (nécessite configuration SSH)
	@echo "🚀 Déploiement en production..."
	./deploy.sh production

prod-up: ## Lancer en mode production (local avec config prod)
	docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
	@echo "✅ Mode production démarré"

prod-down: ## Arrêter le mode production
	docker-compose -f docker-compose.yml -f docker-compose.prod.yml down
	@echo "✅ Mode production arrêté"

prod-logs: ## Voir les logs en mode production
	docker-compose -f docker-compose.yml -f docker-compose.prod.yml logs -f

git-status: ## Vérifier l'état Git avant déploiement
	@echo "📊 État Git:"
	@git status
	@echo ""
	@echo "📌 Branche actuelle: $$(git branch --show-current)"

