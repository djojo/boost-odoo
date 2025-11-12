# 🚀 Guide de déploiement - Boost Odoo

Ce guide explique comment déployer votre projet Odoo sur un VPS en production.

## 📋 Prérequis VPS

- Ubuntu 22.04 LTS ou Debian 11+
- 4 Go de RAM minimum (8 Go recommandé)
- 40 Go d'espace disque minimum
- Accès root ou sudo
- Nom de domaine configuré avec DNS pointant vers votre VPS

## 🎯 Stratégie de déploiement

### Architecture
```
Local (Développement)  →  Git (GitHub/GitLab)  →  VPS (Production)
    ↓                          ↓                       ↓
  addons/                   Versionné              Déployé
  odoo.conf                 dans Git               avec Docker
  docker-compose.yml                              + Caddy (SSL auto)
```

### Workflow
1. **Développer en local** : Créez vos modules dans `addons/`
2. **Commit & Push** : Versionnez votre code sur Git
3. **Déployer** : Utilisez le script `deploy.sh` ou déployez manuellement

---

## 📦 Option 1 : Déploiement automatisé (Recommandé)

### 1. Configuration initiale du VPS

Connectez-vous à votre VPS :

```bash
ssh root@votre-vps-ip
```

Installez Docker et Docker Compose :

```bash
# Mise à jour du système
apt update && apt upgrade -y

# Installation de Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Installation de Docker Compose
apt install docker-compose -y

# Vérification
docker --version
docker-compose --version
```

### 2. Clonez votre projet sur le VPS

```bash
# Créez le dossier de déploiement
mkdir -p /opt/boost-odoo
cd /opt/boost-odoo

# Clonez votre repo (remplacez par votre URL)
git clone https://github.com/votre-username/boost-odoo.git .

# Ou configurez le déploiement par clé SSH
```

### 3. Configuration des variables d'environnement

```bash
# Copiez le template
cp .env.example .env

# Éditez avec vos valeurs
nano .env
```

Exemple de `.env` pour la production :

```env
POSTGRES_USER=odoo
POSTGRES_PASSWORD=VotreMotDePasseTresFort123!
POSTGRES_DB=postgres

ADMIN_PASSWD=UnAutreMotDePasseTresFort456!

DOMAIN=votredomaine.com
LETSENCRYPT_EMAIL=contact@votredomaine.com
```

### 4. Configurez votre DNS

Ajoutez ces enregistrements DNS :

```
Type    Nom                 Valeur
A       votredomaine.com    IP_DE_VOTRE_VPS
A       *.votredomaine.com  IP_DE_VOTRE_VPS  (pour les sous-domaines)
```

### 5. Démarrez l'application en production

```bash
cd /opt/boost-odoo

# Première fois : créez les dossiers de données
mkdir -p /var/lib/odoo/{data,postgres,caddy/{data,config,logs}}

# Lancez avec la config production (Caddy + SSL automatique)
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Vérifiez les logs
docker-compose logs -f

# Vérifiez spécifiquement les logs de Caddy (SSL automatique)
docker logs caddy -f
```

### 6. Déploiement depuis votre machine locale

Modifiez `deploy.sh` avec vos informations :

```bash
REMOTE_USER="root"
REMOTE_HOST="votredomaine.com"  # ou l'IP de votre VPS
REMOTE_PATH="/opt/boost-odoo"
```

Ensuite, pour déployer :

```bash
# Depuis votre machine locale
./deploy.sh production
```

---

## 🛠️ Option 2 : Déploiement manuel

### Workflow complet

```bash
# 1. Sur votre machine locale
git add addons/mon_nouveau_module/
git commit -m "Ajout du module mon_nouveau_module"
git push origin main

# 2. Sur le VPS
ssh root@votre-vps
cd /opt/boost-odoo

# Pull des modifications
git pull origin main

# Redémarrer les conteneurs
docker-compose -f docker-compose.yml -f docker-compose.prod.yml restart odoo

# Voir les logs
docker-compose logs -f odoo
```

---

## 🔐 Sécurité en production

### 1. Changez les mots de passe

✅ Dans `.env` :
- `POSTGRES_PASSWORD` : mot de passe fort
- `ADMIN_PASSWD` : master password Odoo fort

### 2. Configurez le firewall

```bash
# Installer UFW
apt install ufw

# Autoriser SSH, HTTP, HTTPS
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp

# Activer le firewall
ufw enable
```

### 3. Désactivez le listing des bases de données

Dans `odoo.conf`, modifiez :

```ini
list_db = False
```

Puis redémarrez :

```bash
docker-compose restart odoo
```

### 4. Sauvegardez régulièrement

Créez un cron pour les sauvegardes automatiques :

```bash
# Éditez le crontab
crontab -e

# Ajoutez (sauvegarde quotidienne à 2h du matin)
0 2 * * * /opt/boost-odoo/backup-script.sh
```

Créez `backup-script.sh` :

```bash
#!/bin/bash
BACKUP_DIR="/var/backups/odoo"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Sauvegarde PostgreSQL
docker exec odoo_db pg_dumpall -U odoo | gzip > $BACKUP_DIR/db_backup_$DATE.sql.gz

# Sauvegarde des filestores
tar -czf $BACKUP_DIR/filestore_backup_$DATE.tar.gz /var/lib/odoo/data/

# Garder seulement les 7 dernières sauvegardes
find $BACKUP_DIR -name "*.gz" -mtime +7 -delete

echo "Sauvegarde terminée: $DATE"
```

---

## 🔄 Workflow de développement recommandé

### Structure Git

```
main/master    → Production (déployé sur le VPS)
staging        → Pré-production (tests)
develop        → Développement actif
feature/*      → Nouvelles fonctionnalités
```

### Exemple de workflow

```bash
# 1. Créez une branche pour une nouvelle fonctionnalité
git checkout -b feature/nouveau-module

# 2. Développez votre module
cd addons/
mkdir nouveau_module
# ... développement ...

# 3. Testez en local
make restart
# Testez sur http://localhost:8069

# 4. Committez
git add addons/nouveau_module/
git commit -m "feat: Ajout du module nouveau_module"

# 5. Pushez et créez une Pull Request
git push origin feature/nouveau-module

# 6. Après validation, mergez dans main

# 7. Déployez en production
git checkout main
git pull
./deploy.sh production
```

---

## 📊 Monitoring et logs

### Voir les logs en temps réel

```bash
# Logs Odoo
docker-compose logs -f odoo

# Logs PostgreSQL
docker-compose logs -f db

# Logs Caddy (reverse proxy + SSL)
docker logs caddy -f
```

### Accéder au shell du conteneur

```bash
# Shell Odoo
docker exec -it odoo_app bash

# Shell PostgreSQL
docker exec -it odoo_db psql -U odoo
```

### Vérifier l'état des conteneurs

```bash
docker-compose ps
```

---

## 🆘 Dépannage

### Le site ne répond pas

```bash
# Vérifiez que les conteneurs tournent
docker-compose ps

# Vérifiez les logs
docker-compose logs --tail=100 odoo

# Redémarrez si nécessaire
docker-compose restart
```

### Certificat SSL non généré

```bash
# Vérifiez les logs de Caddy
docker logs caddy

# Cherchez les erreurs de certificat SSL
docker logs caddy 2>&1 | grep -i "certificate"

# Vérifiez que le DNS pointe bien vers votre VPS
ping votredomaine.com

# Vérifiez les données Caddy
ls -la /var/lib/odoo/caddy/
```

Caddy génère automatiquement les certificats SSL via Let's Encrypt. Si vous voyez des erreurs :
- Vérifiez que votre domaine pointe bien vers votre VPS
- Vérifiez que les ports 80 et 443 sont ouverts
- Attendez 1-2 minutes, Caddy va réessayer automatiquement

### Problème de connexion à la base de données

```bash
# Testez la connexion PostgreSQL
docker exec odoo_db psql -U odoo -c "\l"

# Vérifiez les variables d'environnement
docker exec odoo_app env | grep DB
```

---

## 🎯 Checklist de déploiement

Avant de déployer en production :

- [ ] Les DNS sont configurés et propagés
- [ ] Le fichier `.env` est configuré avec des mots de passe forts
- [ ] Le firewall est activé (ports 22, 80, 443)
- [ ] `list_db = False` dans `odoo.conf`
- [ ] Les sauvegardes automatiques sont configurées
- [ ] Le monitoring est en place
- [ ] Les logs sont accessibles
- [ ] Un plan de rollback est prévu

---

## 📞 Support

Pour toute question :
- Documentation Odoo : https://www.odoo.com/documentation/18.0/
- Forum Odoo : https://www.odoo.com/forum
- Docker : https://docs.docker.com/

---

**Bon déploiement ! 🚀**

