---
layout: post
title: "Supprimer les sessions Windows inutilisées (Windows 10/11/Server)"
date: 2026-04-21
categories: [windows, administration]
tags: [sessions, rdp, powershell, cmd, gpo, windows-server]
---

Quand on administre un serveur Windows (ou même un poste partagé), les sessions utilisateur qui traînent finissent par consommer de la RAM et des ressources pour rien. Voici la procédure complète pour les identifier, les fermer, et automatiser le ménage.

---

## 1. Identifier les sessions actives

### CMD / PowerShell — Lister toutes les sessions

Ouvrir une invite de commande (admin) et exécuter :

```cmd
query session
# ou
qwinsta
```

Cela affiche l'ID, le nom d'utilisateur, l'état (Active / Disc) et le type de session.

### PowerShell — Lister avec détails supplémentaires

```powershell
Get-Process -IncludeUserName | Select-Object UserName, SessionId | Sort-Object SessionId -Unique
```

### Interface graphique — Gestionnaire des tâches

Ouvrir le Gestionnaire des tâches → onglet **Utilisateurs**. Chaque ligne correspond à une session ouverte.

---

## 2. Identifier les sessions à supprimer

Cibler les sessions présentant l'un des états suivants :

- **Disc** — session déconnectée (utilisateur non actif)
- **Listen** — session en écoute sans utilisateur connecté
- **Inactivité prolongée** — vérifiable via les journaux d'événements (Event ID 4634 / 4647)

---

## 3. Supprimer une session

### CMD — Fermer une session par son ID

```cmd
logoff [ID_SESSION]
# Exemple :
logoff 3
```

Remplacer `[ID_SESSION]` par le numéro obtenu avec `query session`.

### CMD — Déconnecter sans fermer la session (optionnel)

```cmd
tsdiscon [ID_SESSION]
```

Cela déconnecte l'utilisateur mais conserve la session en mémoire (état Disc).

### Interface graphique — Via le Gestionnaire de tâches

Onglet **Utilisateurs** → clic droit sur la session → **Déconnecter** ou **Fermer la session**.

### PowerShell — Fermer toutes les sessions déconnectées en lot

```powershell
query session | Select-String "Disc" | ForEach-Object {
    $id = ($_ -split '\s+')[3]
    logoff $id
}
```

---

## 4. Automatiser la déconnexion (optionnel)

### GPO — Configurer un délai d'expiration via stratégie de groupe

Chemin dans `gpedit.msc` :

```
Config. ordi. → Modèles d'admin. → Composants Windows
→ Services Bureau à distance → Hôte de session Bureau à distance
→ Limites de durée de session
```

Paramètres recommandés : **Limiter les sessions déconnectées** et **Mettre fin aux sessions actives mais inactives**.

---

> ⚠️ **Attention** : Vérifier qu'aucun processus critique (sauvegarde, script en cours) n'est actif dans la session avant de la fermer. La commande `logoff` termine immédiatement la session sans avertir l'utilisateur.
