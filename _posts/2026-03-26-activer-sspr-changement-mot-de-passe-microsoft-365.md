---
layout: post
title: "Activer le changement de mot de passe en libre-service dans Microsoft 365"
date: 2026-03-26
categories: [office365]
tags: [office365, entra, sspr, mot-de-passe, active-directory, powershell]
---

Comment permettre aux utilisateurs de changer ou réinitialiser leur mot de passe eux-mêmes dans Microsoft 365, sans passer par le helpdesk ? La réponse s'appelle **SSPR** (Self-Service Password Reset). Ce guide couvre l'activation, la configuration des méthodes d'authentification, le Password Writeback pour les environnements hybrides, le déploiement progressif et le dépannage.

## Le principe

Par défaut, les utilisateurs peuvent changer leur mot de passe (s'ils connaissent l'ancien) depuis [myaccount.microsoft.com](https://myaccount.microsoft.com) → Sécurité → Mot de passe. Le **SSPR** va plus loin : il permet aux utilisateurs de **réinitialiser** un mot de passe oublié, sans intervention de l'administrateur.

## Activer le SSPR

1. Connectez-vous au **Centre d'administration Microsoft Entra** ([entra.microsoft.com](https://entra.microsoft.com))
2. Allez dans `Protection` → `Réinitialisation du mot de passe`
3. Sous **Réinitialisation du mot de passe en libre-service activée**, choisissez :
   - **Tous** : pour tous les utilisateurs
   - **Sélectionné** : pour un groupe spécifique (recommandé pour commencer)
4. Configurez les méthodes d'authentification requises
5. Cliquez **Enregistrer**

### Licences requises

| Fonctionnalité | Licence minimale |
|---|---|
| Changement de mot de passe (connaît l'ancien) | Tous les plans M365 |
| Réinitialisation de mot de passe oublié | Entra ID P1 (inclus dans M365 Business Premium, E3, E5) |
| Password Writeback (hybride) | Entra ID P1 ou P2 |

---

## Méthodes d'authentification

Dans `Entra` → `Protection` → `Réinitialisation du mot de passe` → `Méthodes d'authentification`, vous configurez deux choses : le nombre de méthodes requises et les méthodes disponibles.

### Nombre de méthodes requises

Vous pouvez exiger **1 ou 2 méthodes** pour qu'un utilisateur puisse réinitialiser son mot de passe. Deux méthodes est recommandé pour plus de sécurité.

### Méthodes disponibles

| Méthode | Description | Sécurité |
|---|---|---|
| Microsoft Authenticator | Notification push ou code TOTP | Recommandée |
| Téléphone mobile | SMS ou appel vocal | Bonne |
| E-mail | Code envoyé à une adresse alternative (pas l'adresse M365) | Correcte |
| Téléphone professionnel | Appel vocal uniquement | Correcte |
| Questions de sécurité | Questions prédéfinies | Faible (vulnérable à l'ingénierie sociale) |

> **Recommandation** : privilégiez **Microsoft Authenticator + téléphone mobile** comme combinaison. Évitez les questions de sécurité seules.

### Enregistrement des utilisateurs

Dans l'onglet **Inscription**, activez l'option **Demander aux utilisateurs de s'inscrire lors de la connexion**. La prochaine fois qu'ils se connectent, ils seront invités à enregistrer leurs méthodes. Vous pouvez aussi définir un délai (en jours) après lequel ils doivent reconfirmer leurs informations.

---

## Password Writeback (environnement hybride)

Si vous synchronisez Microsoft 365 avec un **Active Directory local** via Microsoft Entra Connect, le Password Writeback permet de répercuter les changements de mot de passe du cloud vers l'AD on-premises.

### Prérequis

- **Microsoft Entra Connect** installé et fonctionnel
- Une licence **Entra ID P1 ou P2** pour les utilisateurs concernés
- Un compte de service avec les droits de réinitialisation de mot de passe sur l'AD local

### Activation

1. Sur le serveur Entra Connect, lancez l'assistant de configuration
2. Choisissez **Personnaliser les options de synchronisation**
3. Cochez **Écriture différée du mot de passe** (Password Writeback)
4. Terminez l'assistant et laissez la synchronisation s'effectuer
5. Côté portail Entra : `Protection` → `Réinitialisation du mot de passe` → `Intégration locale` → vérifiez que **Écrire les mots de passe dans votre annuaire local** est activé

### Permissions AD requises

Le compte de service Entra Connect doit avoir ces permissions sur les OUs concernées :

- Réinitialiser le mot de passe
- Modifier le mot de passe
- Écrire `lockoutTime`
- Écrire `pwdLastSet`

> **Important** : les stratégies de mot de passe de votre AD local (complexité, longueur minimale, historique) s'appliquent toujours. Si le mot de passe choisi ne respecte pas ces règles, le changement échouera.

---

## Déploiement progressif

L'idée est d'y aller par étapes pour limiter les risques et faciliter le support.

### Phase 1 — Préparation

- Vérifiez vos licences (Entra ID P1 minimum pour le SSPR complet)
- En environnement hybride, confirmez que Entra Connect est à jour et que le Password Writeback est activé
- Documentez vos stratégies de mot de passe côté AD local pour anticiper les conflits

### Phase 2 — Groupe pilote

- Créez un groupe de sécurité dans Entra ID (par exemple `SSPR-Pilote`) avec une dizaine d'utilisateurs volontaires
- Dans `Protection` → `Réinitialisation du mot de passe`, sélectionnez **Sélectionné** et associez ce groupe
- Faites-leur tester le changement et la réinitialisation, puis recueillez les retours

### Phase 3 — Extension progressive

- Ajoutez progressivement d'autres groupes (par service, par site...)
- Envoyez un e-mail explicatif avec un guide pas-à-pas pour l'enregistrement
- Prévoyez un support helpdesk renforcé pendant les premières semaines

### Phase 4 — Déploiement global

- Passez le SSPR sur **Tous**
- Surveillez les rapports dans `Entra` → `Protection` → `Réinitialisation du mot de passe` → `Journaux d'audit` et `Utilisation et insights`

---

## Dépannage des erreurs courantes

### "Votre compte n'est pas activé pour la réinitialisation du mot de passe"

**Causes** : l'utilisateur n'est pas membre du groupe ciblé, le SSPR est désactivé, ou il manque la licence Entra ID P1/P2.

**Solution** : vérifiez l'appartenance au groupe, l'état du SSPR et les licences dans le portail Entra.

### "Votre mot de passe ne respecte pas les exigences"

**Causes** : en environnement hybride, le mot de passe ne respecte pas la stratégie AD local (longueur, complexité, historique).

**Solution** : alignez les exigences entre Entra ID et votre AD local. Vérifiez les GPO : `Default Domain Policy` → `Computer Configuration` → `Policies` → `Windows Settings` → `Security Settings` → `Account Policies` → `Password Policy`.

### "Erreur de writeback" ou "On-premises writeback failed"

**Causes** : le service Entra Connect Sync ne tourne pas, le compte de service n'a pas les permissions AD suffisantes, ou un pare-feu bloque le port 443 sortant.

**Solutions** :

- Vérifiez que le service **Microsoft Azure AD Sync** est démarré sur le serveur
- Relancez l'assistant Entra Connect et revalidez les identifiants
- Vérifiez les permissions AD du compte de service avec `dsacls` ou via la console AD (onglet Sécurité de l'OU)
- Consultez les journaux : `Observateur d'événements` → `Applications and Services Logs` → `Azure AD Connect`

### "L'utilisateur n'a pas enregistré de méthodes d'authentification"

**Causes** : l'inscription obligatoire n'est pas activée, ou l'utilisateur a ignoré l'invite.

**Solutions** :

- Activez **Demander aux utilisateurs de s'inscrire lors de la connexion** dans l'onglet Inscription
- Pré-remplissez les informations via PowerShell :

```powershell
Update-MgUser -UserId "user@domaine.com" -MobilePhone "+33612345678"
```

### "Le SSPR fonctionne dans le cloud mais pas sur l'écran de connexion Windows"

**Causes** : la réinitialisation depuis l'écran de verrouillage nécessite Windows 10/11 joint à Entra ID, et une connexion Internet.

**Solutions** :

- Vérifiez le type de jointure de la machine :

```powershell
dsregcmd /status
```

Cherchez `AzureAdJoined : YES` ou `DomainJoined : YES` + `AzureAdJoined : YES`.

- Assurez-vous que la connectivité réseau est disponible à l'écran de connexion

### Problèmes de synchronisation

Si les changements ne se propagent pas, forcez une synchronisation manuelle sur le serveur Entra Connect :

```powershell
# Synchronisation Delta (rapide)
Start-ADSyncSyncCycle -PolicyType Delta

# Synchronisation complète (plus longue)
Start-ADSyncSyncCycle -PolicyType Initial
```

---

## Outils de diagnostic

| Outil | Chemin | Usage |
|---|---|---|
| Journaux d'audit SSPR | Entra → Protection → Réinitialisation du mot de passe → Journaux d'audit | Filtrer par "Reset password" ou "Change password" |
| Rapport d'inscription | Entra → Protection → Réinitialisation du mot de passe → Utilisation et insights | Voir combien d'utilisateurs ont enregistré leurs méthodes |
| Entra Connect Health | Portail Entra (licence P1/P2) | Monitoring détaillé de la synchronisation |
| Event Viewer | Sur le serveur Entra Connect : source "ADSync" et "PasswordResetService" | Debug des erreurs de writeback |

---

## Notifications

Pensez à activer les notifications dans l'onglet **Notifications** du SSPR :

- **Notifier les utilisateurs lors de la réinitialisation** : l'utilisateur reçoit un e-mail confirmant le changement
- **Notifier les administrateurs lors de la réinitialisation par un autre admin** : alerte si un admin réinitialise le mot de passe d'un autre admin

Ces notifications sont importantes pour détecter des réinitialisations non autorisées.

## Récapitulatif

| Action | Où |
|---|---|
| Activer le SSPR | Entra → Protection → Réinitialisation du mot de passe |
| Configurer les méthodes | Même endroit → Méthodes d'authentification |
| Activer le Writeback | Assistant Entra Connect + Entra → Intégration locale |
| Tester | [mysignins.microsoft.com](https://mysignins.microsoft.com) |
| Surveiller | Entra → Journaux d'audit + Utilisation et insights |
