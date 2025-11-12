# 🏢 Workflow Multi-tenant - Gestion des clients

Ce guide explique comment ajouter et gérer des clients Odoo avec leurs propres domaines.

## 🎯 Architecture

Chaque client a :
- **Un domaine dédié** : `erp.casaobrasibiza.com`, `odoo.ibizaboost.com`, etc.
- **Une base de données isolée** avec nom explicite
- **Un certificat SSL automatique** : Géré par Caddy
- **Des logs séparés** : `/var/log/caddy/clientname.log`

### Convention de nommage

Le système utilise le module OCA `dbfilter_from_header`. Caddy envoie le nom de base via le header `X-Odoo-dbfilter`.

Le nom de base est formé en **concaténant le sous-domaine + première partie du domaine** (sans points) :

| URL                          | Base de données      |
|------------------------------|---------------------|
| `erp.casaobrasibiza.com`     | `erpcasaobrasibiza` |
| `crm.boost.com`              | `crmboost`          |
| `boostcrm.com`               | `boostcrm`          |
| `odoo.ibizaboost.com`        | `odooibizaboost`    |

✅ **Avantages** : Support pour tous types de domaines, pas de limitation sur la structure.

---

## 🚀 Méthode 1 : Script automatique (Recommandé)

### Depuis votre machine locale

```bash
cd /opt/boost-odoo

# Syntaxe
./scripts/add-client.sh <domaine> [sous-domaine]

# Exemples
./scripts/add-client.sh casaobrasibiza.com erp    # → DB: erpcasaobrasibiza
./scripts/add-client.sh boost.com crm             # → DB: crmboost
./scripts/add-client.sh boostcrm.com              # → DB: boostcrm (sans sous-domaine)
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

Créez un fichier : `caddy/sites/erpcasaobrasibiza.caddy`

```caddy
# Configuration pour Casa Obras Ibiza
# Domaine: erp.casaobrasibiza.com → Base: erpcasaobrasibiza
erp.casaobrasibiza.com {
    # Compression
    encode gzip
    
    # Websocket et Longpolling - Port 8072
    handle /websocket* {
        reverse_proxy odoo:8072 {
            header_up X-Odoo-dbfilter erpcasaobrasibiza
        }
    }
    
    handle /longpolling/* {
        reverse_proxy odoo:8072 {
            header_up X-Odoo-dbfilter erpcasaobrasibiza
        }
    }
    
    # Route principale - Port 8069
    handle {
        # Cache pour les assets statiques
        @static {
            path *.js *.css *.png *.jpg *.jpeg *.gif *.ico *.svg *.woff *.woff2 *.ttf *.eot
        }
        header @static Cache-Control "public, max-age=31536000"
        
        reverse_proxy odoo:8069 {
            header_up X-Odoo-dbfilter erpcasaobrasibiza
        }
    }
    
    log {
        output file /var/log/caddy/casaobrasibiza.log
    }
}
```

**Important** :
- Le nom du fichier doit être descriptif : `erpcasaobrasibiza.caddy`
- Le header `X-Odoo-dbfilter` doit contenir le nom EXACT de la base : `erpcasaobrasibiza`

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

**Fichier** : `caddy/sites/erpcasaobrasibiza.caddy`

```caddy
# Domaine: erp.casaobrasibiza.com → Base: erpcasaobrasibiza
erp.casaobrasibiza.com {
    encode gzip
    
    handle /websocket* {
        reverse_proxy odoo:8072 {
            header_up X-Odoo-dbfilter erpcasaobrasibiza
        }
    }
    
    handle /longpolling/* {
        reverse_proxy odoo:8072 {
            header_up X-Odoo-dbfilter erpcasaobrasibiza
        }
    }
    
    handle {
        @static {
            path *.js *.css *.png *.jpg *.jpeg *.gif *.ico *.svg *.woff *.woff2 *.ttf *.eot
        }
        header @static Cache-Control "public, max-age=31536000"
        reverse_proxy odoo:8069 {
            header_up X-Odoo-dbfilter erpcasaobrasibiza
        }
    }
    
    log {
        output file /var/log/caddy/casaobrasibiza.log
    }
}
```

**Accès** : https://erp.casaobrasibiza.com  
**Base de données** : `erpcasaobrasibiza` (défini via header X-Odoo-dbfilter)

---

### Exemple 2 : Odoo pour Ibiza Boost

**Fichier** : `caddy/sites/odooibizaboost.caddy`

```caddy
# Domaine: odoo.ibizaboost.com → Base: odooibizaboost
odoo.ibizaboost.com {
    encode gzip
    
    handle /websocket* {
        reverse_proxy odoo:8072 {
            header_up X-Odoo-dbfilter odooibizaboost
        }
    }
    
    handle /longpolling/* {
        reverse_proxy odoo:8072 {
            header_up X-Odoo-dbfilter odooibizaboost
        }
    }
    
    handle {
        @static {
            path *.js *.css *.png *.jpg *.jpeg *.gif *.ico *.svg *.woff *.woff2 *.ttf *.eot
        }
        header @static Cache-Control "public, max-age=31536000"
        reverse_proxy odoo:8069 {
            header_up X-Odoo-dbfilter odooibizaboost
        }
    }
    
    log {
        output file /var/log/caddy/ibizaboost.com.log
    }
}
```

**Accès** : https://odoo.ibizaboost.com  
**Base de données** : `odooibizaboost` (défini via header X-Odoo-dbfilter)

---

### Exemple 3 : Domaine sans sous-domaine

**Fichier** : `caddy/sites/boostcrm.caddy`

```caddy
# Domaine racine: boostcrm.com → Base: boostcrm
boostcrm.com {
    encode gzip
    
    handle /websocket* {
        reverse_proxy odoo:8072 {
            header_up X-Odoo-dbfilter boostcrm
        }
    }
    
    handle /longpolling/* {
        reverse_proxy odoo:8072 {
            header_up X-Odoo-dbfilter boostcrm
        }
    }
    
    handle {
        @static {
            path *.js *.css *.png *.jpg *.jpeg *.gif *.ico *.svg *.woff *.woff2 *.ttf *.eot
        }
        header @static Cache-Control "public, max-age=31536000"
        reverse_proxy odoo:8069 {
            header_up X-Odoo-dbfilter boostcrm
        }
    }
    
    log {
        output file /var/log/caddy/boostcrm.log
    }
}
```

**Accès** : https://boostcrm.com  
**Base de données** : `boostcrm` (pas de sous-domaine)

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

- [ ] La base de données est créée avec le nom **exact** (ex: `erpcasaobrasibiza`)
- [ ] Le nom de la base ne contient pas d'espaces, points ni tirets (utilisez uniquement lettres/chiffres)
- [ ] Le fichier `.caddy` est créé dans `caddy/sites/` avec le bon nom
- [ ] Le header `X-Odoo-dbfilter` correspond **exactement** au nom de la base
- [ ] Les 3 blocs `reverse_proxy` (websocket, longpolling, main) incluent le header
- [ ] Le DNS est configuré et propagé (testez avec `ping`)
- [ ] Les modifications sont commitées et pushées
- [ ] Caddy a été rechargé sur le VPS (`docker-compose restart caddy`)
- [ ] Le site est accessible en HTTPS
- [ ] Le certificat SSL est valide
- [ ] `list_db = False` est activé dans `odoo.conf` (sécurité production)

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

### Redirection vers /web/database/selector

Si vous êtes redirigé vers le sélecteur de bases :

```bash
# 1. Vérifier que dbfilter_from_header est chargé
docker logs odoo_app | grep dbfilter_from_header

# 2. Vérifier que list_db est à False
docker exec odoo_app grep list_db /etc/odoo/odoo.conf

# 3. Vérifier que le header est envoyé
docker logs caddy | grep "X-Odoo-dbfilter"

# 4. Tester avec curl
curl -I https://erp.casaobrasibiza.com

# 5. Vérifier le nom exact de la base
docker exec odoo_db psql -U odoo -d postgres -c "\l" | grep erp
```

**Solutions** :
- Assurez-vous que le header `X-Odoo-dbfilter` est présent dans TOUS les blocs `reverse_proxy`
- Vérifiez que le nom de base correspond exactement (pas de typo)
- Effacez les cookies du navigateur ou testez en mode incognito

**Rappel** : Convention de nommage :
- `erp.casaobrasibiza.com` → base : `erpcasaobrasibiza`
- `odoo.ibizaboost.com` → base : `odooibizaboost`
- `boostcrm.com` → base : `boostcrm`

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

