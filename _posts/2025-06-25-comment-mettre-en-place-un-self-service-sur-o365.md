---
layout: post
title: "Comment mettre en place un self-service sur O365 ?"
date: 2025-06-25
categories: [office365, entra-id, microsoft-365, self-service]
tags: [office365, entra, microsoft-365, sspr, self-service, gestion-des-acces, teams, groupes]
---

La mise en place du **"self-service"** sur Microsoft 365 dépend principalement de ce que vous souhaitez déléguer aux utilisateurs. En entreprise ou en gestion de parc (MSP), on cible généralement trois grands piliers : la **réinitialisation de mot de passe (SSPR)**, la **demande d'accès aux ressources (Entitlement Management)**, ou la **création de groupes/équipes Teams**.

Voici comment configurer les briques principales pour **décharger le support technique**.

---

## 1. Le Self-Service Password Reset (SSPR)

C'est le plus urgent et le plus rentable en temps de support. Il permet aux utilisateurs de **réinitialiser leur mot de passe sans intervention**, à condition d'avoir configuré leurs méthodes d'authentification (MFA).

### Méthode de configuration

#### 1. Accéder à Microsoft Entra ID
Connectez-vous au **centre d'administration Microsoft Entra** (ex-Azure AD). Allez dans **Protection** > **Réinitialisation du mot de passe** (Password reset).

#### 2. Définir la portée (Scope)
Dans l'onglet **Propriétés**, choisissez si le self-service est activé pour :
- **Aucun**
- **Sélectionné** (recommandé pour un pilote via un groupe de sécurité)
- **Tous**

#### 3. Choisir les méthodes d'authentification
Dans l'onglet **Méthodes d'authentification**, cochez :
- Le **nombre de méthodes requises** (généralement 1 ou 2)
- Les **canaux autorisés** :
  - Application mobile (Microsoft Authenticator)
  - SMS
  - Adresse e-mail de secours

#### 4. Activer l'enregistrement (côté utilisateur)
Dans l'onglet **Enregistrement**, forcez les utilisateurs à s'enregistrer lorsqu'ils se connectent (via l'URL [https://aka.ms/ssprsetup](https://aka.ms/ssprsetup)).

> ⚠️ **Attention aux environnements hybrides** : Si vous synchronisez vos comptes depuis un **Active Directory sur site** (via Entra Connect), vous devez **impérativement activer l'option Password Writeback** (réécriture des mots de passe) dans l'outil de synchronisation pour que la modification remonte sur vos contrôleurs de domaine locaux.

---

## 2. Le Self-Service pour les accès (Groupes, Applications, SharePoint)

Si vous disposez de licences **Microsoft Entra ID P1 / P2** (incluses dans Business Premium, E3, E5), vous pouvez mettre en place la **gestion des droits d'accès** via les **Access Packages** (Gestion des packages d'accès).

Microsoft Entra centralise ces ressources (Groupes, Teams, Apps, Sites) dans un **catalogue** où les utilisateurs internes ou externes font leurs demandes de self-service selon des **politiques strictes**.

### Comment le déployer :

1. Dans le portail **Entra ID**, allez dans **Gouvernance des identités** > **Gestion des requêtes de droits** (Entitlement Management).

2. Créez un **Catalogue** de ressources (regroupant des sites SharePoint, des équipes Teams ou des applications d'entreprise).

3. Créez un **Package d'accès** (Access Package) à l'intérieur de ce catalogue.

4. Configurez la **Politique de demande** (Policy) :
   - Qui peut demander (utilisateurs de l'organisation, invités).
   - Si une **approbation hiérarchique ou technique** est requise (et par qui).
   - La **durée de validité** de l'accès (ex: expiration automatique après 6 mois ou réévaluation via des **Access Reviews**).

5. Les utilisateurs n'ont plus qu'à se rendre sur le portail **MyAccess** ([https://myaccess.microsoft.com](https://myaccess.microsoft.com)) pour **commander leurs droits en toute autonomie**.

---

## 3. Le Self-Service Teams et Groupes Microsoft 365

Par défaut, **n'importe quel utilisateur peut créer un groupe Microsoft 365** (et donc une équipe Teams, un plan Planner ou un site SharePoint associé). Si vous souhaitez **encadrer ce comportement** sans pour autant tout bloquer, il faut appliquer une gouvernance :

- **Le problème du tout-ou-rien** : Si vous laissez faire, vous risquez d'avoir un **"Edge" ou un "Teams" pollué de doublons** (`Test 1`, `Projet Machine 2`). Si vous bloquez tout, le support est inondé de tickets de création de canaux.

- **La bonne pratique** : **Restreindre la création de groupes** à un **groupe de sécurité spécifique** (ex: `G_M365_Createurs_Groupes`). Vous y intégrez les chefs de projet ou les managers. Pour les autres, vous pouvez publier un **formulaire Power Apps / Power Automate** simple qui automatise la création *après* validation de la direction.

---

## Synthèse des prérequis de licence

| Fonctionnalité Self-Service | Niveau de licence requis |
|---|---|
| **SSPR (Cloud uniquement)** | Inclus dans toutes les licences gratuites / de base M365 |
| **SSPR (Hybride / Réécriture AD local)** | Entra ID P1 (Business Premium, M365 E3) |
| **Packages d'accès (MyAccess)** | Entra ID P1 / P2 (Identity Governance requis pour certaines fonctions avancées) |
| **Restriction de création de groupes via AzureAD PowerShell** | Entra ID P1 (pour les utilisateurs concernés par la politique) |
