# 🚀 Projet Kubernetes – API Python + MySQL sur Azure AKS

## 🎯 Objectif du projet
Déployer automatiquement une application complète sur **Azure Kubernetes Service (AKS)** composée de :
- Une **API Python (FastAPI)**,
- Une **base de données MySQL**,
- Un **Ingress Controller (NGINX)** pour l’accès public à l’API.

Le déploiement est automatisé avec le script **PowerShell `init-k8s.ps1`**.

---

## ⚙️ Déploiement automatisé

### 1️⃣ Prérequis
- Avoir un cluster AKS actif et configuré (`az login`, `az aks get-credentials`).
- Avoir **kubectl** et **Azure CLI** installés.
- PowerShell (≥ 7.0).

### 2️⃣ Lancer le déploiement
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
trash.txt         # Fichier ignoré (non utilisé)
```

---

## 🌐 API exposée

| Méthode | URL | Description |
|----------|-----|-------------|
| `GET` | `/okotwica/health` | Vérifie l’état de l’API |
| `GET` / `POST` | `/okotwica/clients` | Liste ou ajoute un client |
| `GET` / `DELETE` | `/okotwica/clients/{id}` | Lecture ou suppression d’un client |

> Exemple : `curl http://<IP_PUBLIC>/okotwica/health`

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
