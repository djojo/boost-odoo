# 🛡️ Workflow sécurisé en production

Ce guide explique comment gérer votre installation Odoo en production en préservant vos données.

## ⚠️ RÈGLE D'OR

**JAMAIS** utiliser `docker-compose down -v` en production !
Le flag `-v` supprime les volumes et donc **TOUTES VOS DONNÉES**.

---

## 📦 Persistance des données

Vos données sont stockées dans des dossiers sur le serveur :

| Dossier | Contenu | Critique |
|---------|---------|----------|
| `/var/lib/odoo/postgres/` | Base de données PostgreSQL | 🔴 Critique |
| `/var/lib/odoo/data/` | Filestores Odoo (fichiers uploadés) | 🔴 Critique |
| `/var/lib/odoo/letsencrypt/` | Certificats SSL | 🟡 Important |
| `/opt/boost-odoo/addons/` | Vos modules custom | 🟢 Versionné Git |

Ces dossiers **persistent automatiquement** tant que vous ne les supprimez pas manuellement.

---

## 🔄 Opérations courantes

### 1. Arrêter Odoo temporairement

**Situation** : Maintenance serveur, mise à jour système, etc.

```bash
cd /opt/boost-odoo

# Arrêter tous les services (les données restent)
docker-compose stop

# Vérifier que tout est arrêté
docker-compose ps
```

**Résultat** : Odoo est arrêté, mais **TOUTES les données sont préservées**.

---

### 2. Redémarrer Odoo

**Situation** : Après un arrêt, redémarrage serveur, etc.

```bash
cd /opt/boost-odoo

# Redémarrer tous les services
docker-compose start

# Ou avec -d pour démarrer en arrière-plan
docker-compose up -d

# Vérifier que tout tourne
docker-compose ps
```

**Résultat** : Odoo redémarre avec **TOUTES vos données intactes**.

---

### 3. Redémarrer uniquement Odoo (pas la base de données)

**Situation** : Après une mise à jour de code, changement de config, etc.

```bash
cd /opt/boost-odoo

# Redémarrer seulement le conteneur Odoo
docker-compose restart odoo

# Voir les logs
docker-compose logs -f odoo
```

**Résultat** : Seul Odoo redémarre, PostgreSQL continue de tourner.

---

### 4. Mettre à jour le code depuis Git

**Situation** : Vous avez poussé de nouveaux modules ou modifications.

```bash
cd /opt/boost-odoo

# 1. Récupérer les modifications
git pull origin main

# 2. Redémarrer Odoo pour prendre en compte les changements
docker-compose restart odoo

# 3. Voir les logs
docker-compose logs -f odoo

# 4. Dans Odoo, mettez à jour vos modules :
# Settings → Apps → Update Apps List
# Puis "Upgrade" sur vos modules modifiés
```

**Résultat** : Code mis à jour, **données préservées**.

---

### 5. Reconstruire les conteneurs (nouvelle version Odoo)

**Situation** : Mise à jour de l'image Docker Odoo.

```bash
cd /opt/boost-odoo

# 1. Télécharger la nouvelle image
docker-compose pull odoo

# 2. Arrêter les services
docker-compose stop

# 3. Supprimer les anciens conteneurs (pas les données !)
docker-compose rm

# 4. Recréer et démarrer avec la nouvelle image
docker-compose up -d

# 5. Vérifier
docker-compose logs -f
```

**Résultat** : Nouvelle version Odoo, **données préservées**.

---

### 6. Voir les logs en temps réel

**Situation** : Débogage, surveillance.

```bash
# Tous les logs
docker-compose logs -f

# Seulement Odoo
docker-compose logs -f odoo

# Seulement PostgreSQL
docker-compose logs -f db

# Les 100 dernières lignes
docker-compose logs --tail=100 odoo
```

---

### 7. Accéder au shell des conteneurs

**Situation** : Débogage avancé, maintenance.

```bash
# Shell du conteneur Odoo
docker exec -it odoo_app bash

# Shell PostgreSQL
docker exec -it odoo_db bash

# Accès direct psql
docker exec -it odoo_db psql -U odoo -d nom_base
```

---

## 💾 Sauvegardes

### Sauvegarde manuelle complète

```bash
#!/bin/bash
# Créer un dossier de sauvegarde
mkdir -p /root/backups
cd /root/backups

DATE=$(date +%Y%m%d_%H%M%S)

# 1. Sauvegarder TOUTES les bases PostgreSQL
echo "📦 Sauvegarde des bases de données..."
docker exec odoo_db pg_dumpall -U odoo | gzip > db_backup_${DATE}.sql.gz

# 2. Sauvegarder les filestores
echo "📦 Sauvegarde des filestores..."
tar -czf filestore_backup_${DATE}.tar.gz /var/lib/odoo/data/

# 3. Sauvegarder les modules custom
echo "📦 Sauvegarde des modules custom..."
tar -czf addons_backup_${DATE}.tar.gz /opt/boost-odoo/addons/

echo "✅ Sauvegarde terminée dans /root/backups/"
ls -lh /root/backups/*${DATE}*
```

### Restauration d'une sauvegarde

```bash
# 1. Arrêter Odoo (pas la DB)
docker-compose stop odoo

# 2. Restaurer la base de données
gunzip < db_backup_20241112_100000.sql.gz | docker exec -i odoo_db psql -U odoo

# 3. Restaurer les filestores
cd /
tar -xzf /root/backups/filestore_backup_20241112_100000.tar.gz

# 4. Redémarrer Odoo
docker-compose start odoo
```

### Sauvegarde automatique (cron)

Créez `/root/backup-odoo.sh` :

```bash
#!/bin/bash
BACKUP_DIR="/root/backups"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7

mkdir -p $BACKUP_DIR

# Sauvegarde DB
docker exec odoo_db pg_dumpall -U odoo | gzip > $BACKUP_DIR/db_backup_${DATE}.sql.gz

# Sauvegarde filestores
tar -czf $BACKUP_DIR/filestore_backup_${DATE}.tar.gz /var/lib/odoo/data/

# Supprimer les sauvegardes de plus de 7 jours
find $BACKUP_DIR -name "*.gz" -mtime +$RETENTION_DAYS -delete

echo "✅ Sauvegarde terminée: $DATE"
```

Rendez-le exécutable :

```bash
chmod +x /root/backup-odoo.sh
```

Ajoutez au crontab :

```bash
crontab -e
```

Ajoutez cette ligne (sauvegarde tous les jours à 2h du matin) :

```
0 2 * * * /root/backup-odoo.sh >> /var/log/odoo-backup.log 2>&1
```

---

## 🚨 Commandes DANGEREUSES (à éviter en production)

### ⛔ DANGER - Supprime TOUT

```bash
# NE JAMAIS FAIRE EN PRODUCTION !
docker-compose down -v
```

Le flag `-v` supprime les volumes = **PERTE DE TOUTES LES DONNÉES**.

### ⛔ DANGER - Supprime les données

```bash
# NE JAMAIS FAIRE EN PRODUCTION !
rm -rf /var/lib/odoo/*
```

Supprime physiquement tous les fichiers = **PERTE DÉFINITIVE**.

### ⛔ DANGER - Supprime une base

```bash
# Attention : irréversible
docker exec odoo_db psql -U odoo -c "DROP DATABASE nom_base;"
```

---

## 🆘 Problèmes courants

### Odoo ne démarre pas

```bash
# 1. Voir les logs
docker-compose logs --tail=100 odoo

# 2. Vérifier l'état des conteneurs
docker-compose ps

# 3. Redémarrer
docker-compose restart
```

### Problème de connexion à la base

```bash
# 1. Vérifier que PostgreSQL tourne
docker-compose ps db

# 2. Tester la connexion
docker exec odoo_db psql -U odoo -c "\l"

# 3. Vérifier les variables dans odoo.conf
docker exec odoo_app cat /etc/odoo/odoo.conf
```

### Manque d'espace disque

```bash
# Voir l'espace utilisé
df -h

# Nettoyer les images Docker inutilisées
docker system prune -a

# Voir la taille des dossiers
du -sh /var/lib/odoo/*

# Compresser les anciennes sauvegardes
gzip /root/backups/*.sql
```

### Odoo est lent

```bash
# 1. Voir l'utilisation CPU/RAM
docker stats

# 2. Augmenter les workers dans odoo.conf
# workers = 4  (au lieu de 2)

# 3. Redémarrer
docker-compose restart odoo
```

---

## 📊 Monitoring

### Vérifier l'état quotidien

```bash
# État des conteneurs
docker-compose ps

# Espace disque
df -h

# Dernières erreurs Odoo
docker-compose logs --tail=50 odoo | grep -i error

# Dernières erreurs PostgreSQL
docker-compose logs --tail=50 db | grep -i error
```

### Vérifier les sauvegardes

```bash
# Lister les sauvegardes
ls -lh /root/backups/

# Vérifier la dernière sauvegarde
ls -lt /root/backups/ | head -5

# Taille totale des sauvegardes
du -sh /root/backups/
```

---

## 📋 Checklist maintenance mensuelle

- [ ] Vérifier l'espace disque disponible
- [ ] Vérifier que les sauvegardes automatiques fonctionnent
- [ ] Tester une restauration de sauvegarde (sur un environnement de test)
- [ ] Mettre à jour les modules Odoo si nécessaire
- [ ] Vérifier les logs pour des erreurs récurrentes
- [ ] Nettoyer les anciennes sauvegardes (> 30 jours)
- [ ] Vérifier les certificats SSL (Traefik)
- [ ] Mettre à jour le système : `apt update && apt upgrade`

---

## 🔐 Sécurité

### Vérifier les mots de passe

```bash
# Le .env ne doit être lisible que par root
chmod 600 /opt/boost-odoo/.env
chown root:root /opt/boost-odoo/.env
```

### Vérifier le firewall

```bash
# Ports ouverts
ufw status

# Doit montrer :
# 22/tcp  (SSH)
# 80/tcp  (HTTP)
# 443/tcp (HTTPS)
```

### Désactiver le listing des bases

Dans `/opt/boost-odoo/odoo.conf` :

```ini
list_db = False
```

Puis redémarrer :

```bash
docker-compose restart odoo
```

---

## 📞 Aide

En cas de problème grave :

1. **Ne paniquez pas** - vos données sont dans `/var/lib/odoo/`
2. **Faites une sauvegarde immédiate** avant toute action
3. **Consultez les logs** : `docker-compose logs --tail=200`
4. **Documentez le problème** : date, erreur, ce qui a été fait

**Ressources** :
- Documentation Odoo : https://www.odoo.com/documentation/18.0/
- Forum Odoo : https://www.odoo.com/forum
- Logs : `/var/log/` et `docker-compose logs`

---

**Dernière mise à jour** : 12 novembre 2024

