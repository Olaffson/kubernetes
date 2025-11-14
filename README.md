# 🚀 Projet Kubernetes – API Python + MySQL sur Azure AKS

## 🎯 Objectif du projet
Déployer automatiquement une application complète sur **Azure Kubernetes Service (AKS)** composée de :
- Une **API Python (FastAPI)**,  
- Une **base de données MySQL**,  
- Un **Ingress Controller (NGINX)** pour l’accès public à l’API,  
- Et un **workflow GitHub Actions** pour déployer automatiquement depuis le dépôt.

Le déploiement est géré par le script **PowerShell `init-k8s.ps1`**, et le workflow **GitHub Actions `deploy-aks.yml`** permet d’automatiser ce processus depuis GitHub.

---

## ⚙️ Déploiement automatisé

### 1️⃣ Prérequis
- Avoir un cluster AKS actif et configuré (`az login`, `az aks get-credentials`).
- Avoir **kubectl**, **Azure CLI**, et **PowerShell (≥ 7.0)** installés.
- Disposer d’un **Service Principal Azure** avec les droits *Contributor* sur le Resource Group de ton cluster.
- Secrets configurés dans GitHub (voir plus bas).

---

### 2️⃣ Déploiement local (manuel)
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process

# Lancer le script d’initialisation
.\init-k8s.ps1
```

Ce script :
1. Supprime et recrée le namespace `okotwica`,
2. Applique tous les manifestes du dossier `k8s/`,
3. Crée les secrets, services, déploiements et ingress,
4. Vérifie la disponibilité des pods, services et ingress.

#### 🔐 Secrets à renseigner dans GitHub

Avant de lancer le workflow, tu dois créer **4 secrets GitHub** (dans *Settings → Secrets and variables → Actions*) :

| Nom du secret | Description |
|----------------|-------------|
| `AZURE_SUBSCRIPTION_ID` | ID de ton abonnement Azure |
| `AZURE_RESOURCE_GROUP` | Nom du Resource Group contenant le cluster AKS |
| `AKS_CLUSTER_NAME` | Nom du cluster AKS à déployer (ex: `cluster_promo`) |
| `AZURE_CREDENTIALS` | JSON du Service Principal Azure, au format suivant : |

```json
{
  "clientId": "<APP_ID>",
  "clientSecret": "<PASSWORD>",
  "subscriptionId": "<SUBSCRIPTION_ID>",
  "tenantId": "<TENANT_ID>",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

---

### 3️⃣ Déploiement via GitHub Actions

Le workflow **`.github/workflows/deploy-aks.yml`** permet d’exécuter le même déploiement depuis GitHub.

#### 🔁 Déclenchement 
- **Manuel** via l’onglet **Actions → Deploy AKS (init-k8s.ps1)** → *Run workflow*.

#### ⚙️ Ce que fait le workflow :
1. Se connecte à **Azure** avec le secret `AZURE_CREDENTIALS`.
2. Configure le **contexte Kubernetes** sur le cluster AKS cible.
3. Exécute le script **PowerShell `init-k8s.ps1`** pour (re)déployer toutes les ressources.
4. Vérifie la présence des pods, services et ingress.
5. Affiche un état final du namespace.

---

## 🧱 Architecture technique

```
+----------------------------+
|        Utilisateurs        |
+-------------+--------------+
              |
              v
   +-------------------------+
   | Ingress Controller      |
   | (NGINX - IP publique)   |
   +-------------------------+
              |
              v
   +-------------------------+
   | Service API (ClusterIP) |
   +-----------+-------------+
               |
               v
   +-------------------------+
   | Pod API (FastAPI)       |
   +-------------------------+
               |
               v
   +-------------------------+
   | Service MySQL (ClusterIP)|
   +-----------+-------------+
               |
               v
   +-------------------------+
   | Pod MySQL + PVC         |
   +-------------------------+
```

---

## 📁 Structure du projet

```
.github/
└─ workflows/
   └─ deploy-aks.yml      # Workflow GitHub Actions pour déploiement automatique

k8s/
├─ api_deployment.yaml
├─ api_service.yaml
├─ ingress.yaml
├─ mysql_deployment.yaml
├─ mysql_pvc.yaml
├─ mysql_service.yaml
├─ namespace.yaml
└─ secrets.yaml

screen/
├─ client1.png
├─ clients.png
├─ health.png
└─ okotwica.png

init-k8s.ps1      # Script PowerShell de déploiement automatisé
.gitignore        # Exclut cluster/ et trash.txt
LICENSE           # Licence du projet
README.md         # Documentation principale
```

---

## 🌐 API exposée

| Méthode | URL | Description |
|----------|-----|-------------|
| `GET` | `/okotwica/health` | Vérifie l’état de l’API |
| `GET` / `POST` | `/okotwica/clients` | Liste ou ajoute un client |
| `GET` / `DELETE` | `/okotwica/clients/{id}` | Lecture ou suppression d’un client |

> Exemple :  
> `curl http://<IP_PUBLIC>/okotwica/health`

---

## 🧩 Vérification du déploiement

```powershell
kubectl get pods -n okotwica
kubectl get svc -n okotwica
kubectl get ingress -n okotwica
```

Tous les pods doivent être en **Running**, et l’ingress doit afficher une **adresse IP publique**.

---

## 🧰 Commandes utiles

| Action | Commande |
|---------|-----------|
| Vérifier le contexte | `kubectl config current-context` |
| Logs d’un pod | `kubectl logs -n okotwica pod/<nom>` |
| Supprimer une ressource | `kubectl delete -f <fichier.yaml>` |
| Re-déployer tout | `.\init-k8s.ps1` |

---

## 🧼 Nettoyage

Pour tout supprimer :
```powershell
kubectl delete namespace okotwica
```

---

## 📸 Captures d’écran

Le dossier `screen/` contient plusieurs impressions d’écran du déploiement et des tests réussis :
- `client1.png` : consultation d’un client spécifique  
- `clients.png` : liste des clients  
- `health.png` : vérification de la santé de l’API  
- `okotwica.png` : vue globale du namespace et des ressources

---

## 🧑‍💻 Auteur
**Olivier KOTWICA**  
Projet : *Déploiement AKS – Simplon HDF (Data Engineer P1)*  
Date : *Novembre 2025*
