# 🏢 Workflow Multi-tenant - Gestion des clients

Ce guide explique comment ajouter et gérer des clients Odoo avec leurs propres domaines.

## 🎯 Architecture

Chaque client a :
- **Un domaine dédié** : `erp.casaobrasibiza.com`, `crm.iya.com`, etc.
- **Une base de données isolée** basée sur le **2ème segment du domaine**
- **Un certificat SSL automatique** : Géré par Caddy
- **Des logs séparés** : `/var/log/caddy/clientname.log`

### Convention de nommage automatique

Le `dbfilter = ^[^.]+\.([^.]+)\.` dans `odoo.conf` extrait automatiquement le nom de la base :

| URL                          | Base de données |
|------------------------------|----------------|
| `erp.casaobrasibiza.com`     | `casaobrasibiza` |
| `crm.ibizaboost.com`         | `ibizaboost` |
| `admin.client.fr`            | `client` |

⚠️ **Le sous-domaine (erp, crm, admin, etc.) n'a PAS d'importance** - seul le 2ème segment compte.

---

## 🚀 Méthode 1 : Script automatique (Recommandé)

### Depuis votre machine locale

```bash
cd /opt/boost-odoo

# Syntaxe
./scripts/add-client.sh <domaine> [sous-domaine]

# Exemples
./scripts/add-client.sh casaobrasibiza.com erp    # → DB: casaobrasibiza
./scripts/add-client.sh ibizaboost.com crm        # → DB: ibizaboost
./scripts/add-client.sh client3.fr admin          # → DB: client3
```

Le script va :
1. ✅ Créer le fichier de configuration Caddy
2. ✅ Afficher les instructions de déploiement
3. ✅ Vous guider étape par étape
4. ✅ Calculer automatiquement le nom de la base

---

## 🛠️ Méthode 2 : Manuel (Étape par étape)

### Étape 1 : Créer la base de données Odoo

1. Accédez au Database Manager :
   ```
   https://erp.ibizaboost.com/web/database/manager
   ```

2. Cliquez sur "Create Database"

3. Remplissez :
   - **Master Password** : votre master password
   - **Database Name** : `casaobras` (nom court, sans espaces)
   - **Email** : email de l'administrateur
   - **Password** : mot de passe admin
   - **Language** : Français
   - **Country** : France

4. Cliquez sur "Create database" et attendez 2-3 minutes

---

### Étape 2 : Créer la configuration Caddy

Créez un fichier : `caddy/sites/casaobrasibiza.caddy`

```caddy
# Configuration pour Casa Obras Ibiza
# Domaine: erp.casaobrasibiza.com → Base: casaobrasibiza
erp.casaobrasibiza.com {
    # Compression
    encode gzip
    
    # Websocket et Longpolling - Port 8072
    handle /websocket* {
        reverse_proxy odoo:8072
    }
    
    handle /longpolling/* {
        reverse_proxy odoo:8072
    }
    
    # Route principale - Port 8069
    handle {
        # Cache pour les assets statiques
        @static {
            path *.js *.css *.png *.jpg *.jpeg *.gif *.ico *.svg *.woff *.woff2 *.ttf *.eot
        }
        header @static Cache-Control "public, max-age=31536000"
        
        reverse_proxy odoo:8069
    }
    
    log {
        output file /var/log/caddy/casaobrasibiza.log
    }
}
```

**Important** :
- Le nom du fichier doit correspondre au **2ème segment du domaine** : `casaobrasibiza.caddy`
- Le nom de la base sera automatiquement extrait par Odoo : `casaobrasibiza`

---

### Étape 3 : Configurer le DNS

Chez votre registrar de domaine (OVH, Gandi, Cloudflare, etc.) :

| Type | Nom | Valeur | TTL |
|------|-----|--------|-----|
| A | erp | IP_DE_VOTRE_VPS | 300 |

**Exemple pour Casa Obras** :
```
Type: A
Nom: erp
Domaine: casaobras.com
Valeur: 123.45.67.89
```

**Vérifier la propagation DNS** (depuis votre machine locale) :
```bash
ping erp.casaobras.com
# Doit répondre avec l'IP de votre VPS
```

---

### Étape 4 : Déployer sur le VPS

#### A. Depuis votre machine locale

```bash
# Ajouter le fichier au repo
git add caddy/sites/casaobras.caddy

# Commiter
git commit -m "feat: Ajout du client Casa Obras"

# Pusher
git push origin main
```

#### B. Sur le VPS

```bash
# Se connecter
ssh root@votre-vps-ip

# Aller dans le projet
cd /opt/boost-odoo

# Récupérer les modifications
git pull origin main

# Recharger Caddy (sans downtime!)
docker exec caddy caddy reload --config /etc/caddy/Caddyfile

# Vérifier les logs
docker logs caddy --tail=30
```

---

### Étape 5 : Vérifier

Attendez 1-2 minutes pour la génération du certificat SSL, puis :

```bash
# Depuis le VPS
curl -I https://erp.casaobras.com

# Ou depuis votre navigateur
https://erp.casaobras.com
```

Vous devriez voir la page de connexion Odoo du client ! 🎉

---

## 📊 Exemples de configurations

### Exemple 1 : ERP pour Casa Obras Ibiza

**Fichier** : `caddy/sites/casaobrasibiza.caddy`

```caddy
# Domaine: erp.casaobrasibiza.com → Base: casaobrasibiza
erp.casaobrasibiza.com {
    encode gzip
    
    handle /websocket* {
        reverse_proxy odoo:8072
    }
    
    handle /longpolling/* {
        reverse_proxy odoo:8072
    }
    
    handle {
        @static {
            path *.js *.css *.png *.jpg *.jpeg *.gif *.ico *.svg *.woff *.woff2 *.ttf *.eot
        }
        header @static Cache-Control "public, max-age=31536000"
        reverse_proxy odoo:8069
    }
    
    log {
        output file /var/log/caddy/casaobrasibiza.log
    }
}
```

**Accès** : https://erp.casaobrasibiza.com  
**Base de données** : `casaobrasibiza` (extrait automatiquement)

---

### Exemple 2 : CRM pour Ibiza Boost

**Fichier** : `caddy/sites/ibizaboost.caddy`

```caddy
# Domaine: crm.ibizaboost.com → Base: ibizaboost
crm.ibizaboost.com {
    encode gzip
    
    handle /websocket* {
        reverse_proxy odoo:8072
    }
    
    handle /longpolling/* {
        reverse_proxy odoo:8072
    }
    
    handle {
        @static {
            path *.js *.css *.png *.jpg *.jpeg *.gif *.ico *.svg *.woff *.woff2 *.ttf *.eot
        }
        header @static Cache-Control "public, max-age=31536000"
        reverse_proxy odoo:8069
    }
    
    log {
        output file /var/log/caddy/ibizaboost.log
    }
}
```

**Accès** : https://crm.ibizaboost.com  
**Base de données** : `ibizaboost` (extrait automatiquement)

---

### Exemple 3 : Plusieurs sous-domaines pour le même client

**Fichier** : `caddy/sites/bigclient.caddy`

```caddy
# ERP - Domaine: erp.bigclient.com → Base: bigclient
erp.bigclient.com {
    encode gzip
    handle /websocket* {
        reverse_proxy odoo:8072
    }
    handle /longpolling/* {
        reverse_proxy odoo:8072
    }
    handle {
        reverse_proxy odoo:8069
    }
    log {
        output file /var/log/caddy/bigclient-erp.log
    }
}

# CRM - Domaine: crm.bigclient.com → Base: bigclient (même base!)
crm.bigclient.com {
    encode gzip
    handle /websocket* {
        reverse_proxy odoo:8072
    }
    handle /longpolling/* {
        reverse_proxy odoo:8072
    }
    handle {
        reverse_proxy odoo:8069
    }
    log {
        output file /var/log/caddy/bigclient-crm.log
    }
}
```

⚠️ **Note** : Les deux sous-domaines partagent la **même base** `bigclient` car le 2ème segment est identique.

---

## 🔄 Supprimer un client

### 1. Supprimer la base de données

```
https://erp.ibizaboost.com/web/database/manager
→ Delete → casaobras
```

### 2. Supprimer la configuration Caddy

```bash
# Localement
rm caddy/sites/casaobras.caddy

git add caddy/sites/casaobras.caddy
git commit -m "feat: Suppression du client Casa Obras"
git push origin main

# Sur le VPS
cd /opt/boost-odoo
git pull origin main
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

### 3. Supprimer les logs (optionnel)

```bash
# Sur le VPS
rm /var/lib/odoo/caddy/logs/casaobras.log
```

---

## 📝 Checklist pour un nouveau client

Avant de déployer, vérifiez :

- [ ] La base de données est créée dans Odoo avec le **2ème segment du domaine** comme nom
- [ ] Le nom de la base ne contient pas d'espaces ni de caractères spéciaux
- [ ] Le fichier `.caddy` est créé dans `caddy/sites/`
- [ ] Le nom du fichier correspond au **2ème segment** (ex: `casaobrasibiza.caddy`)
- [ ] Le domaine suit le format `subdomain.clientname.tld` (ex: `erp.casaobrasibiza.com`)
- [ ] Le DNS est configuré et propagé (testez avec `ping`)
- [ ] Les modifications sont commitées et pushées
- [ ] Caddy a été rechargé sur le VPS
- [ ] Le site est accessible en HTTPS
- [ ] Le certificat SSL est valide
- [ ] Le dbfilter dans `odoo.conf` est configuré : `dbfilter = ^[^.]+\.([^.]+)\.`

---

## 🆘 Dépannage

### Le site ne répond pas (404)

```bash
# Vérifier que Caddy a bien chargé la config
docker exec caddy caddy list-modules

# Vérifier les logs Caddy
docker logs caddy --tail=50

# Vérifier que le fichier .caddy existe
ls -la /opt/boost-odoo/caddy/sites/
```

### Certificat SSL non généré

```bash
# Vérifier les logs de Caddy
docker logs caddy | grep -i "casaobras"

# Vérifier le DNS
ping erp.casaobras.com

# Forcer le rechargement
docker restart caddy
```

### Mauvaise base de données affichée

Vérifiez le `dbfilter` dans `odoo.conf` et la correspondance avec votre domaine :

```bash
# Vérifier le dbfilter dans odoo.conf
docker exec odoo_app grep dbfilter /etc/odoo/odoo.conf

# Vérifier le nom de la base
docker exec odoo_db psql -U odoo -c "\l" | grep -E "Name|casaobras|ibizaboost"

# Tester la regex dbfilter en Python
docker exec odoo_app python3 -c "
import re
hostname = 'erp.casaobrasibiza.com'
pattern = r'^[^.]+\.([^.]+)\.'
match = re.search(pattern, hostname)
print(f'Hostname: {hostname}')
print(f'DB extrait: {match.group(1) if match else \"AUCUN\"}')
"
```

**Rappel** : Le nom de la base doit correspondre au **2ème segment du domaine** :
- `erp.casaobrasibiza.com` → base : `casaobrasibiza`
- `crm.ibizaboost.com` → base : `ibizaboost`

---

## 📊 Monitoring

### Voir les logs d'un client

```bash
# Sur le VPS
docker exec caddy tail -f /var/log/caddy/casaobras.log
```

### Lister tous les clients configurés

```bash
cd /opt/boost-odoo
ls -la caddy/sites/*.caddy
```

### Vérifier toutes les bases de données

```bash
docker exec odoo_db psql -U odoo -c "\l"
```

---

## 💡 Bonnes pratiques

1. **Nommage cohérent** : Utilisez le même nom pour :
   - Le nom de la base de données
   - Le nom du fichier `.caddy`
   - Les logs

2. **Documentation** : Commentez vos fichiers `.caddy` avec :
   - Le nom du client
   - La date d'ajout
   - Le contact du client

3. **Backup** : Sauvegardez régulièrement les bases :
   ```bash
   docker exec odoo_db pg_dump -U odoo casaobras | gzip > backup_casaobras_$(date +%Y%m%d).sql.gz
   ```

4. **Monitoring** : Vérifiez régulièrement les logs :
   ```bash
   docker logs caddy | grep -i error
   ```

---

## 📞 Support

Pour toute question :
- Consultez `README.md` pour la configuration générale
- Consultez `DEPLOYMENT.md` pour le déploiement
- Consultez `PRODUCTION_WORKFLOW.md` pour la gestion en production

---

**Dernière mise à jour** : 12 novembre 2024

