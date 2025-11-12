# 🚀 Boost Odoo - Environnement de développement

Environnement Docker pour développer localement Odoo Community 18.0 en mode multi-tenant.

## 📋 Prérequis

- Docker Desktop installé
- Docker Compose v3.8+
- 4 Go de RAM minimum disponible pour Docker

## 🏗️ Architecture

```
Boost Odoo/
├── docker-compose.yml    # Configuration des conteneurs
├── odoo.conf            # Configuration Odoo
├── .gitignore          # Fichiers à ignorer
├── Makefile            # Commandes rapides
├── addons/             # Vos modules custom
├── data/               # Filestore Odoo (ignoré par git)
└── postgres/           # Données PostgreSQL (ignoré par git)
```

## 🚀 Démarrage rapide

### 1. Lancer l'environnement

```bash
docker-compose up -d
```

### 2. Accéder à Odoo

Ouvrez votre navigateur : [http://localhost:8069](http://localhost:8069)

### 3. Créer une base de données

- Master password : `admin`
- Database name : `odoo_dev` (ou le nom de votre choix)
- Email : votre email
- Password : votre mot de passe
- Demo data : Cochez si vous voulez des données de démo

## 📝 Commandes utiles

### Avec Makefile (recommandé)

```bash
make start         # Démarrer les conteneurs
make stop          # Arrêter les conteneurs
make restart       # Redémarrer les conteneurs
make logs          # Voir les logs en temps réel
make ps            # Voir l'état des conteneurs
make clean         # Arrêter et supprimer les conteneurs
make shell         # Accéder au shell Odoo
make db-shell      # Accéder au shell PostgreSQL
```

### Avec Docker Compose

```bash
docker-compose up -d              # Démarrer en arrière-plan
docker-compose down               # Arrêter et supprimer
docker-compose logs -f odoo       # Logs Odoo
docker-compose logs -f db         # Logs PostgreSQL
docker-compose restart odoo       # Redémarrer Odoo
docker-compose exec odoo bash     # Shell dans le conteneur Odoo
```

## 🔧 Développement de modules

### Créer un nouveau module

1. Créez un dossier dans `addons/` :

```bash
mkdir -p addons/mon_module
```

2. Créez la structure du module :

```
addons/mon_module/
├── __init__.py
├── __manifest__.py
├── models/
│   ├── __init__.py
│   └── mon_model.py
├── views/
│   └── mon_view.xml
└── security/
    └── ir.model.access.csv
```

3. Redémarrez Odoo et mettez à jour la liste des apps :
   - Settings → Apps → Update Apps List
   - Cherchez votre module et installez-le

### Hot reload

Pour éviter de redémarrer à chaque modification, vous pouvez :

1. Activer le mode développeur dans Odoo (Settings → Activate Developer Mode)
2. Utiliser l'option "Update" sur votre module après modifications

## 🏢 Multi-tenant

Le système multi-tenant utilise le module OCA `dbfilter_from_header` qui permet à Caddy d'envoyer le nom de la base via un header HTTP. Cela offre une flexibilité totale pour gérer tous types de domaines.

### Convention de nommage

Le nom de base est formé en **concaténant le sous-domaine + première partie du domaine** (sans points) :

| URL                          | Base de données      |
|------------------------------|---------------------|
| `erp.casaobrasibiza.com`     | `erpcasaobrasibiza` |
| `crm.boost.com`              | `crmboost`          |
| `boostcrm.com`               | `boostcrm`          |
| `odoo.ibizaboost.com`        | `odooibizaboost`    |

✅ **Avantages** :
- Support pour tous types de domaines (avec ou sans sous-domaine)
- Pas de limitation sur la structure du domaine
- Configuration explicite via Caddy

### Configuration locale

Pour tester en local avec plusieurs bases, ajoutez à votre `/etc/hosts` :

```
127.0.0.1  erp.casaobras.local
127.0.0.1  crm.boost.local
```

Puis accédez :
- `http://erp.casaobras.local:8069` → base `erpcasaobras`
- `http://crm.boost.local:8069` → base `crmboost`

### En production (VPS)

1. **Configurer le DNS** : Pointez vos domaines vers l'IP du VPS
2. **Créer la configuration Caddy** avec le script :

```bash
./scripts/add-client.sh casaobrasibiza.com erp  # → base: erpcasaobrasibiza
./scripts/add-client.sh boost.com crm           # → base: crmboost
./scripts/add-client.sh boostcrm.com            # → base: boostcrm (sans sous-domaine)
```

3. **Créer la base de données** via le Database Manager avec le nom exact
4. **Déployer** : `git push` puis `git pull` sur le VPS et redémarrer Caddy

Voir [docs/WORKFLOW_CLIENT.md](./docs/WORKFLOW_CLIENT.md) pour le workflow complet.

## 🔐 Sécurité

⚠️ **IMPORTANT** : Avant de déployer en production, modifiez :

1. Dans `odoo.conf` :
   - `admin_passwd` → changez le master password
   
2. Dans `docker-compose.yml` :
   - `POSTGRES_PASSWORD` → mot de passe sécurisé
   - Utilisez la configuration de production avec Caddy pour le SSL automatique

3. Créez un fichier `.env` pour les variables sensibles :

```env
POSTGRES_PASSWORD=votre_mot_de_passe_fort
ADMIN_PASSWD=votre_master_password_fort
```

## 📦 Déploiement sur VPS avec SSL automatique

### 1. Préparer le VPS

```bash
# Installer Docker et Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Installer Docker Compose v2
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
```

### 2. Cloner le projet

```bash
git clone votre-repo.git boost-odoo
cd boost-odoo
```

### 3. Configurer pour la production

Créez un fichier `.env` avec vos identifiants :

```env
POSTGRES_USER=odoo
POSTGRES_PASSWORD=VotreMotDePasseFort123!
POSTGRES_DB=postgres

ADMIN_PASSWD=VotreMasterPassword456!

# Votre domaine
DOMAIN=erp.votredomaine.com
LETSENCRYPT_EMAIL=contact@votredomaine.com
```

**Important** : Configurez votre DNS pour pointer vers l'IP de votre VPS.

### 4. Créer les dossiers nécessaires

```bash
mkdir -p /var/lib/odoo/{data,postgres,caddy/{data,config,logs}}
```

### 5. Lancer en production

```bash
# Avec Caddy pour SSL automatique
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Vérifier les logs de Caddy (SSL automatique)
docker logs caddy -f
```

**Le SSL sera configuré automatiquement par Caddy via Let's Encrypt !** 🔒

Après 1-2 minutes, accédez à : `https://votre-domaine.com`

### 6. Reverse proxy Caddy

Caddy gère automatiquement :
- ✅ Certificats SSL via Let's Encrypt
- ✅ Renouvellement automatique des certificats
- ✅ Redirection HTTP → HTTPS
- ✅ Support multi-domaines (sous-domaines pour multi-tenant)
- ✅ HTTP/3 activé

## 🔄 Sauvegardes

### Sauvegarder une base

```bash
docker-compose exec db pg_dump -U odoo nom_base > backup_$(date +%Y%m%d_%H%M%S).sql
```

### Restaurer une base

```bash
docker-compose exec -T db psql -U odoo -d postgres -c "CREATE DATABASE nom_base;"
docker-compose exec -T db psql -U odoo -d nom_base < backup.sql
```

### Sauvegarder les filestores

```bash
tar -czf data_backup_$(date +%Y%m%d_%H%M%S).tar.gz data/
```

## 🐛 Dépannage

### Odoo ne démarre pas

```bash
docker-compose logs odoo
```

### Base de données inaccessible

```bash
docker-compose logs db
```

### Port 8069 déjà utilisé

Modifiez le port dans `docker-compose.yml` :

```yaml
ports:
  - "8070:8069"  # Utilisez le port 8070 localement
```

### Réinitialiser complètement

⚠️ **Attention : cela supprimera toutes vos données !**

```bash
docker-compose down -v
rm -rf data/* postgres/*
docker-compose up -d
```

## 📚 Ressources

- [Documentation Odoo 18](https://www.odoo.com/documentation/18.0/)
- [Odoo Developer Documentation](https://www.odoo.com/documentation/18.0/developer.html)
- [Forum Odoo](https://www.odoo.com/forum)

## 📄 Licence

Ce projet est sous licence MIT.

