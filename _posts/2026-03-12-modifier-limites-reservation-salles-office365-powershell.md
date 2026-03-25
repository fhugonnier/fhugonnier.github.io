---
layout: post
title: "Modifier les limites de réservation des salles dans Office 365 en PowerShell"
date: 2026-03-12
categories: [office365]
tags: [powershell, office365, exchange, salles, ressources]
---

Quand vous gérez des salles de réunion ou des équipements dans Office 365, vous allez vite tomber sur un problème : les limites de réservation par défaut sont trop restrictives. Impossible de réserver une salle plus de 24h, pas plus de 180 jours à l'avance... Voici comment modifier ces limites en PowerShell, sur une seule ressource ou sur toutes d'un coup.

## Se connecter à Exchange Online

Avant toute chose, il faut se connecter à Exchange Online. Si vous n'avez pas encore le module, installez-le :

```powershell
# Installer le module Exchange Online (une seule fois)
Install-Module ExchangeOnlineManagement

# Se connecter
Connect-ExchangeOnline -UserPrincipalName admin@votredomaine.com
```

## Vérifier la configuration actuelle

Avant de modifier quoi que ce soit, vérifiez les paramètres actuels de votre ressource :

```powershell
Get-CalendarProcessing -Identity "NomDeLaRessource" | 
    Select-Object MaximumDurationInMinutes, BookingWindowInDays, MaximumConflictInstances
```

Remplacez `"NomDeLaRessource"` par l'alias, l'email ou le nom complet de la boîte de ressources.

## Les paramètres clés

Voici les paramètres que vous pouvez modifier sur le traitement calendrier d'une ressource :

| Paramètre | Description | Valeur par défaut |
|---|---|---|
| `MaximumDurationInMinutes` | Durée maximale d'une réservation | 1440 (24h) |
| `BookingWindowInDays` | Combien de jours à l'avance on peut réserver | 180 |
| `MaximumConflictInstances` | Nombre de conflits tolérés (réunions récurrentes) | 0 |
| `PercentageAllowedDegradation` | % de dégradation des récurrents autorisé | 0 |
| `AllowConflicts` | Autoriser les réservations en conflit | $false |

## Modifier une seule ressource

```powershell
Set-CalendarProcessing -Identity "NomDeLaRessource" `
    -MaximumDurationInMinutes 1440 `
    -MaximumConflictInstances 5 `
    -BookingWindowInDays 365 `
    -AllowConflicts $false
```

Dans cet exemple :
- La durée max d'une réservation est de **24 heures** (1440 minutes)
- On peut réserver jusqu'à **1 an** à l'avance (365 jours)
- Les réunions récurrentes tolèrent jusqu'à **5 conflits**
- Les conflits directs restent **interdits**

## Modifier TOUTES les ressources d'un coup

C'est là que ça devient intéressant. Si vous avez 50 salles de réunion, pas question de le faire une par une. Voici la commande qui applique les mêmes paramètres à **toutes les boîtes aux lettres de ressources** (salles + équipements) :

```powershell
Get-Mailbox -RecipientTypeDetails RoomMailbox,EquipmentMailbox -ResultSize Unlimited | ForEach-Object {
    Set-CalendarProcessing -Identity $_.Identity `
        -MaximumDurationInMinutes 1440 `
        -MaximumConflictInstances 5 `
        -BookingWindowInDays 365 `
        -AllowConflicts $false

    Write-Host "Mis à jour : $($_.DisplayName)" -ForegroundColor Green
}
```

Le paramètre `-ResultSize Unlimited` est important : sans lui, Exchange ne retourne que les 1000 premiers résultats.

### Tester avant d'appliquer (dry-run)

Avant de lancer la modification en masse, affichez d'abord la liste des ressources concernées :

```powershell
Get-Mailbox -RecipientTypeDetails RoomMailbox,EquipmentMailbox -ResultSize Unlimited | 
    Select-Object DisplayName, Identity
```

Ça vous permettra de vérifier que vous ne touchez pas à une ressource par erreur.

### Version avec gestion d'erreurs (recommandée en production)

En environnement de production, utilisez toujours un `try/catch` pour éviter qu'une erreur sur une ressource n'arrête tout le script :

```powershell
Get-Mailbox -RecipientTypeDetails RoomMailbox,EquipmentMailbox -ResultSize Unlimited | ForEach-Object {
    try {
        Set-CalendarProcessing -Identity $_.Identity `
            -MaximumDurationInMinutes 1440 `
            -MaximumConflictInstances 5 `
            -BookingWindowInDays 365 `
            -AllowConflicts $false

        Write-Host "Mis à jour : $($_.DisplayName)" -ForegroundColor Green
    } catch {
        Write-Host "Erreur sur : $($_.DisplayName) - $($_.Exception.Message)" -ForegroundColor Red
    }
}
```

Si une salle pose problème (permissions manquantes, boîte corrompue...), le script continue avec les suivantes au lieu de s'arrêter.

## Vérifier les modifications

Après avoir appliqué les changements, vérifiez que tout est bon :

```powershell
Get-Mailbox -RecipientTypeDetails RoomMailbox,EquipmentMailbox -ResultSize Unlimited | ForEach-Object {
    $config = Get-CalendarProcessing -Identity $_.Identity
    [PSCustomObject]@{
        Salle = $_.DisplayName
        DureeMax = "$($config.MaximumDurationInMinutes) min"
        FenetreReservation = "$($config.BookingWindowInDays) jours"
        ConflitsMax = $config.MaximumConflictInstances
    }
} | Format-Table -AutoSize
```

Cette commande affiche un tableau propre avec les paramètres de chaque ressource.

## Récapitulatif

| Action | Commande |
|---|---|
| Voir la config d'une salle | `Get-CalendarProcessing -Identity "Salle"` |
| Modifier une salle | `Set-CalendarProcessing -Identity "Salle" -BookingWindowInDays 365` |
| Lister toutes les ressources | `Get-Mailbox -RecipientTypeDetails RoomMailbox,EquipmentMailbox` |
| Modifier toutes les salles | Boucle `ForEach-Object` (voir ci-dessus) |

Pensez à toujours tester sur une seule ressource avant de déployer en masse, et à utiliser le `try/catch` en production.
