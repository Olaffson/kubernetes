# 🚀 Projet Kubernetes – API Python + MySQL sur Azure AKS

## 🎯 Objectif du projet
L’objectif est de déployer une architecture applicative moderne composée de :
- Une **API Python (FastAPI)** conteneurisée,
- Une **base de données MySQL**,
- Hébergées dans un **cluster Azure Kubernetes Service (AKS)**,
- Avec un **Ingress Controller (NGINX)** pour exposer l’API publiquement.

Le système doit être **scalable**, **résilient** et prêt à accueillir un futur front-end consommant l’API.

---

## 🧱 Architecture technique

```
        +----------------------------+
        |      Utilisateurs          |
        +-------------+--------------+
                      |
                      v
          +-------------------------+
          |  Ingress Controller     |
          |  (NGINX - IP: 4.251.145.205) |
          +-------------------------+
                      |
                      v
          +-------------------------+
          | Service API (ClusterIP) |
          +-----------+-------------+
                      |
                      v
          +-------------------------+
          |  Pod API (FastAPI)      |
          +-------------------------+
                      |
                      v
          +-------------------------+
          | Service MySQL (ClusterIP)|
          +-----------+-------------+
                      |
                      v
          +-------------------------+
          |  Pod MySQL + PVC        |
          +-------------------------+
```

---

## 📦 Images Docker utilisées

| Composant | Image Docker | Description |
|------------|---------------|--------------|
| **Base de données** | `sengsathit/brief-mysql:latest` | Image MySQL 8.4 avec scripts d’initialisation (`init/`) |
| **API Python** | `sengsathit/brief-api:latest` | API FastAPI/uvicorn exposée sur le port 8000 |

---

## 🌐 API Endpoints attendus

| Méthode | URL publique | Description |
|----------|---------------|--------------|
| `GET` | http://4.251.145.205/okotwica/health | Probe de santé |
| `GET` / `POST` | http://4.251.145.205/okotwica/clients | Liste ou création de clients |
| `GET` / `DELETE` | http://4.251.145.205/okotwica/clients/{id} | Lecture ou suppression d’un client |

---

## 📁 Structure du projet

```
k8s/
├─ namespace.yaml
├─ secrets.yaml
├─ mysql/
│  ├─ pvc.yaml
│  ├─ deployment.yaml
│  └─ service.yaml
├─ api/
│  ├─ deployment.yaml
│  └─ service.yaml
└─ ingress.yaml
```

---

## ⚙️ Pré-requis

Avant de déployer :

1. **Être connecté à Azure**
   ```bash
   az account show
   ```
   Si besoin :
   ```bash
   az login
   ```

2. **Récupérer les credentials du cluster AKS**
   ```bash
   az aks get-credentials --resource-group RG_PROMO --name cluster_promo
   ```

3. **Vérifier la connexion**
   ```bash
   kubectl get nodes
   ```

---

## 🧩 Étapes de déploiement

### 1️⃣ Créer le namespace
```bash
kubectl apply -f k8s/namespace.yaml
```

### 2️⃣ Créer les secrets (identifiants MySQL)
```bash
kubectl apply -f k8s/secrets.yaml
```

### 3️⃣ Déployer MySQL
```bash
kubectl apply -f k8s/mysql/pvc.yaml
kubectl apply -f k8s/mysql/deployment.yaml
kubectl apply -f k8s/mysql/service.yaml
```

Vérifie :
```bash
kubectl get pods -n okotwica
kubectl get svc -n okotwica
```

### 4️⃣ Déployer l’API Python
```bash
kubectl apply -f k8s/api/deployment.yaml
kubectl apply -f k8s/api/service.yaml
```

Vérifie :
```bash
kubectl get pods -n okotwica
```

### 5️⃣ Créer l’Ingress (NGINX)
```bash
kubectl apply -f k8s/ingress.yaml
```

Vérifie :
```bash
kubectl get ingress -n okotwica -o wide
```

---

## 🔍 Tests et vérifications

### 🧠 1. Vérifier le contexte Kubernetes
```bash
kubectl config current-context
```

### ⚙️ 2. Vérifier les pods
```bash
kubectl get pods -n okotwica -o wide
```

### 🌍 3. Tester les endpoints de l’API
```bash
# Health check
curl http://4.251.145.205/okotwica/health

# Liste des clients
curl http://4.251.145.205/okotwica/clients

# Ajouter un client
curl -X POST http://4.251.145.205/okotwica/clients   -H "Content-Type: application/json"   -d '{"name":"Alice","email":"alice@example.com"}'
```

---

## 🧰 Commandes utiles

| Action | Commande |
|---------|-----------|
| Voir les logs d’un pod | `kubectl logs -n okotwica pod/<nom-du-pod>` |
| Supprimer une ressource | `kubectl delete -f <fichier.yaml>` |
| Voir tous les services | `kubectl get svc -n okotwica` |
| Voir tous les ingress | `kubectl get ingress -n okotwica` |
| Déployer tout le projet d’un coup | `kubectl apply -f k8s/` |

---

## 🧼 Nettoyage complet

Pour supprimer toutes les ressources du namespace :
```bash
kubectl delete namespace okotwica
```

---

## 🛠️ Dépannage rapide

| Problème | Cause probable | Solution |
|-----------|----------------|-----------|
| `CrashLoopBackOff` sur MySQL | Mauvais mots de passe ou init SQL invalide | Vérifie les logs avec `kubectl logs -n okotwica pod/<mysql-pod>` |
| `Connection refused` entre API et DB | Mauvais `DB_HOST` ou secret manquant | Vérifie `env` et la présence du service `db` |
| 404 sur l’URL publique | Ingress NGINX non configuré ou IP différente | Vérifie `kubectl get ingress -A` et `kubectl get svc -n ingress-nginx` |
| `Forbidden` en kubectl | Permissions RBAC insuffisantes | Vérifie ton rôle AKS (service principal ou utilisateur) |

---

## 📖 Notes complémentaires

- L’Ingress suppose que le **NGINX Ingress Controller** est déjà installé.
  Vérifie avec :
  ```bash
  kubectl get svc -n ingress-nginx
  ```
  Si tu vois une IP publique (ici `4.251.145.205`), tout est bon.

- Pour l’installation rapide de NGINX Ingress :
  ```bash
  helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
  helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx     --namespace ingress-nginx --create-namespace
  ```

---

## ✅ Résultat attendu

Une fois tout déployé :
- `kubectl get pods -n okotwica` → tous en **Running**
- `curl http://4.251.145.205/okotwica/health` → renvoie `{"status":"ok"}` (ou équivalent)
- L’API est accessible via les endpoints publics.

---

🧑‍💻 Auteur : *Olivier KOTWICA*  
📅 Projet : *Déploiement AKS – Simplon HDF - Data Engineer P1*
