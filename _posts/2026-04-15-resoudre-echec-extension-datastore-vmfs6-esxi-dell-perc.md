---
layout: post
title: "Résoudre l'échec d'extension d'un datastore VMFS-6 sur ESXi avec un contrôleur Dell PERC"
date: 2026-04-15
categories: [virtualisation, vmware, storage]
tags: [esxi, vmfs, dell-perc, datastore, gpt, partedutil, vmkfstools]
---

**Symptôme** : « Échec du développement de la banque de données VMFS — Échec de la mise à jour des partitions de disque »

---

## Contexte

Après avoir étendu un volume logique côté contrôleur RAID Dell PERC 755, l'extension du datastore VMFS-6 échoue systématiquement depuis le client vSphere avec le message :

> *Échec du développement de la banque de données VMFS datastore1 — Échec de la mise à jour des partitions de disque pour /vmfs/devices/disks/naa.xxxx*

L'erreur persiste même après un rescan du stockage. Voici la démarche complète de diagnostic et de résolution menée en SSH sur l'hôte ESXi.

---

## Étape 1 — Identifier le problème de table GPT

La première chose à faire est d'inspecter la table de partitions du disque concerné :

```bash
partedUtil getptbl /vmfs/devices/disks/naa.xxxx
```

Dans notre cas, la commande renvoyait immédiatement deux avertissements :

- **« The backup GPT table is not at the end of the disk »** — La table GPT de secours est restée positionnée à l'ancienne fin du disque.
- **« Not all of the space available appears to be used »** — ESXi détecte un décalage entre la taille réelle du disque et la position du backup GPT.

La table de partitions montrait 5 partitions, dont la partition 8 de type `vmfs` (le datastore) qui se terminait bien avant la fin du disque.

---

## Étape 2 — Corriger le backup GPT header

La commande `fix` déplace la table GPT de secours à la bonne position :

```bash
partedUtil fix /vmfs/devices/disks/naa.xxxx
```

Vérification :

```bash
partedUtil getptbl /vmfs/devices/disks/naa.xxxx
```

Les messages d'avertissement doivent avoir disparu. La table de partitions s'affiche proprement, mais la partition vmfs n'a pas encore changé de taille — c'est normal.

---

## Étape 3 — Tenter l'extension via vSphere (échec)

À ce stade, on retente l'extension depuis le client vSphere... et le même message d'erreur réapparaît.

L'analyse des logs révèle la cause profonde :

```bash
tail -50 /var/log/vmkernel.log | grep -i "partition\|vmfs\|error\|fail"
```

Résultat :

```
WARNING: Partition: 2144: naa.xxxx: in-use partition 7 can not be shrunk
```

**La partition 7 (vmfsl)**, utilisée par VMFS-6 pour le journal/metadata, bloque l'opération. Le client vSphere tente de réorganiser la table de partitions et échoue car cette partition est verrouillée en écriture.

---

## Étape 4 — Vérifier que ESXi voit la bonne taille du disque

Avant d'aller plus loin, il faut confirmer que le device a la bonne taille :

```bash
esxcli storage core device list -d naa.xxxx | grep "Size"
```

Si la taille affichée est toujours l'ancienne, un reboot de l'hôte peut être nécessaire. Les contrôleurs Dell PERC ne propagent pas toujours le changement de taille à chaud. Un rescan classique (`esxcli storage core adapter rescan --all`) ne suffit pas toujours.

On vérifie ensuite l'espace utilisable :

```bash
partedUtil getUsableSectors /vmfs/devices/disks/naa.xxxx
```

Cette commande retourne le premier et le dernier secteur disponible. Si le dernier secteur correspond à la nouvelle taille du disque, on peut procéder.

---

## Étape 5 — Étendre manuellement la partition et le filesystem

C'est la solution qui a fonctionné. On contourne le client vSphere en procédant directement en CLI.

### Étendre la partition vmfs

```bash
partedUtil resize /vmfs/devices/disks/naa.xxxx 8 <secteur_debut> <dernier_secteur_utilisable>
```

Exemple concret :

```bash
partedUtil resize /vmfs/devices/disks/naa.xxxx 8 268437504 11245977566
```

Les valeurs se trouvent dans la sortie de `getptbl` (secteur de début de la partition 8) et `getUsableSectors` (dernier secteur utilisable).

> **Alternative** : si `resize` n'est pas disponible sur votre version d'ESXi, utilisez `setptbl` en réécrivant l'intégralité de la table de partitions avec la nouvelle valeur de fin pour la partition 8. Attention à reprendre exactement les valeurs des autres partitions.

### Étendre le filesystem VMFS

```bash
vmkfstools --growfs /vmfs/devices/disks/naa.xxxx:8 /vmfs/devices/disks/naa.xxxx:8
```

Le `:8` désigne le numéro de la partition vmfs.

---

## Étape 6 — Vérifier le résultat

```bash
vmkfstools -Ph /vmfs/volumes/datastore1
```

Le datastore doit afficher sa nouvelle capacité. Dans notre cas, il est passé de 2,5 TB à 5,1 TB avec succès.

---

## Récapitulatif des causes

| Problème | Commande de diagnostic | Solution |
|---|---|---|
| Backup GPT header mal positionné | `partedUtil getptbl` | `partedUtil fix` |
| Partition vmfsl (7) verrouillée | `vmkernel.log` | Contourner vSphere, passer en CLI |
| Device ESXi ne voit pas la nouvelle taille | `esxcli storage core device list` | Reboot de l'hôte |
| Partition vmfs non étendue | `partedUtil getUsableSectors` | `partedUtil resize` |
| Filesystem VMFS non étendu | `vmkfstools -Ph` | `vmkfstools --growfs` |

---

## Points à retenir

- Après une extension de LUN côté contrôleur RAID Dell PERC, un **reboot de l'hôte ESXi** est parfois indispensable pour que le driver relise la géométrie du disque.
- Le client vSphere peut échouer à étendre un datastore VMFS-6 à cause de la **partition vmfsl (partition 7)** qui est verrouillée. L'extension manuelle en CLI contourne ce problème.
- Toujours commencer par un `partedUtil fix` si la table GPT de secours n'est plus alignée avec la fin du disque.
- Les commandes `partedUtil resize` + `vmkfstools --growfs` sont la combinaison gagnante quand l'interface graphique refuse de coopérer.
