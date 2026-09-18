---
layout: post
title: "Peut-on renommer un compte O365 sans tout casser ?"
date: 2025-06-25
categories: [office365, entra-id, microsoft-365]
tags: [office365, entra, microsoft-365, upn, renommer, compte, utilisateur, azure-ad]
---

Oui, c'est tout à fait possible et c'est une opération courante dans Microsoft 365 (changement de nom, de domaine ou de nom de famille).

Cependant, comme le **UPN (User Principal Name)** sert d'identifiant principal pour l'authentification et les chemins d'accès aux données, le changement entraîne des **déconnexions temporaires** et quelques ajustements côté poste utilisateur.

---

## Ce qui ne casse pas (Géré automatiquement)

### ✅ Historique des emails et droits
L'**ID unique (GUID / Object ID)** du compte dans **Entra ID (Azure AD)** ne change pas. L'utilisateur conserve **tous ses accès, licences, groupes, canaux Teams et fichiers**.

### ✅ Réception des emails
Par défaut, **l'ancienne adresse email passe automatiquement en alias SMTP**. L'utilisateur continue donc de recevoir les messages envoyés à son ancienne adresse.

---

## Les impacts à prévoir (Côté utilisateur)

Lors de la modification du UPN, **les applications Microsoft de l'utilisateur vont demander une réauthentification**.

### 1. Outlook (PC, Mac, Mobile)
**Impact :** Une fenêtre pop-up demandera de se reconnecter avec le nouvel identifiant.

**Point d'attention :** Sur certains postes (surtout Windows avec d'anciens profils), Outlook peut bloquer ou tourner en boucle. La résolution consiste simplement à **recréer le profil Outlook** ou **effacer le cache des identifiants Windows** (Gestionnaire d'identifiants).

### 2. OneDrive pour Entreprise
**Impact :** Le lien de synchronisation local va se rompre temporairement.

**Ce qui se passe :** La cible de l'URL SharePoint du OneDrive personnel change (ex: de `/personal/ancien_nom@domaine.com` à `/personal/nouveau_nom@domaine.com`). OneDrive va se fermer, demander la reconnexion et **resynchroniser le dossier sous son nouveau nom** (OneDrive - NomSociété (NouveauUPN)).

### 3. Microsoft Teams
**Impact :** Déconnexion automatique sous quelques minutes à quelques heures.

**Action :** L'utilisateur doit se déconnecter manuellement et se reconnecter avec la nouvelle adresse s'il n'est pas invité à le faire automatiquement.

### 4. Applications tierces et Single Sign-On (SSO)
**⚠️ Attention particulière :** Si vous utilisez le compte M365 en SSO pour des applications tierces (SaaS, VPN, etc.), vérifiez comment l'application identifie l'utilisateur. Si elle s'appuie **strictement sur le UPN** (et non sur l'Object ID), l'utilisateur pourrait être perçu comme un **nouveau compte** dans cette application.

---

## Bonne pratique pour procéder

1. **Informer l'utilisateur à l'avance** (prévenir qu'il devra ressaisir son mot de passe sur son téléphone et son PC).

2. **Préférer effectuer le changement en fin de journée** ou hors des heures de pointe pour laisser le temps à la **réplication Entra ID / Microsoft 365** de se faire (compter entre **15 minutes et 2 heures** pour une propagation complète).

3. **Renommer le compte depuis le centre d'administration Microsoft 365** :
   - **Utilisateurs actifs** > **Modifier le nom d'utilisateur et l'adresse email**

4. **Vérifier que l'ancienne adresse est bien conservée en alias**.

5. **Accompagner l'utilisateur** pour la reconnexion à sa session/Office le lendemain matin.
