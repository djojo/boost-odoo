# 📚 Documentation Boost Odoo

Documentation complète pour la plateforme multi-tenant Odoo 18.

## 📑 Guides disponibles

### 🏢 [WORKFLOW_CLIENT.md](./WORKFLOW_CLIENT.md)
**Guide complet de gestion des clients**

- Architecture multi-tenant
- Convention de nommage des bases
- Ajout d'un nouveau client (script automatique + manuel)
- Configuration Caddy
- Configuration DNS
- Déploiement sur VPS
- Exemples de configurations
- Dépannage
- Checklist de déploiement

**À consulter pour** : Ajouter un nouveau client, configurer un domaine, gérer le multi-tenant

---

### 🚀 [PRODUCTION_WORKFLOW.md](./PRODUCTION_WORKFLOW.md)
**Guide de gestion en production**

- Gestion quotidienne du VPS
- Monitoring et logs
- Sauvegardes (bases de données + filestores)
- Mises à jour Odoo
- Gestion des modules
- Optimisation des performances
- Sécurité
- Procédures d'urgence

**À consulter pour** : Opérations quotidiennes, maintenance, monitoring, sauvegardes

---

### 🛠️ [DEPLOYMENT.md](./DEPLOYMENT.md)
**Guide de déploiement initial**

- Prérequis VPS
- Installation Docker
- Configuration initiale
- Déploiement de l'application
- Configuration Caddy & SSL
- Premier client
- Tests de validation

**À consulter pour** : Déploiement initial sur un nouveau VPS

---

## 🎯 Démarrage rapide

**Nouveau au projet ?** Consultez dans l'ordre :

1. **[../README.md](../README.md)** - Vue d'ensemble et démarrage local
2. **[DEPLOYMENT.md](./DEPLOYMENT.md)** - Déploiement sur VPS
3. **[WORKFLOW_CLIENT.md](./WORKFLOW_CLIENT.md)** - Ajout de clients
4. **[PRODUCTION_WORKFLOW.md](./PRODUCTION_WORKFLOW.md)** - Gestion quotidienne

## 🔍 Recherche rapide

| Besoin | Document |
|--------|----------|
| Ajouter un client | [WORKFLOW_CLIENT.md](./WORKFLOW_CLIENT.md) |
| Faire une sauvegarde | [PRODUCTION_WORKFLOW.md](./PRODUCTION_WORKFLOW.md) |
| Voir les logs | [PRODUCTION_WORKFLOW.md](./PRODUCTION_WORKFLOW.md) |
| Problème de SSL | [WORKFLOW_CLIENT.md](./WORKFLOW_CLIENT.md#dépannage) |
| Mise à jour Odoo | [PRODUCTION_WORKFLOW.md](./PRODUCTION_WORKFLOW.md) |
| Config Caddy | [WORKFLOW_CLIENT.md](./WORKFLOW_CLIENT.md) |
| Installer un module | [PRODUCTION_WORKFLOW.md](./PRODUCTION_WORKFLOW.md) |
| Déployer sur nouveau VPS | [DEPLOYMENT.md](./DEPLOYMENT.md) |

## 💡 Guidelines Cursor

Les guidelines pour l'assistant IA Cursor sont dans :
**[../.cursor/rules/guidelines.mdc](../.cursor/rules/guidelines.mdc)**

## 📞 Support

Pour des questions spécifiques :
- **Multi-tenant** → WORKFLOW_CLIENT.md
- **Opérations** → PRODUCTION_WORKFLOW.md  
- **Installation** → DEPLOYMENT.md
- **Développement** → README.md (racine)

