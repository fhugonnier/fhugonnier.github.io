---
layout: post
title: "La VM idéale sur ESXi : bonnes pratiques de configuration"
date: 2026-04-22
categories: [virtualisation, vmware]
tags: [esxi, vm, vcpu, vmxnet3, pvscsi, numa, vmware-tools, bonnes-pratiques]
---

Il n'existe pas de configuration « magique » universelle, car tout dépend de la charge de travail (Workload). Cependant, pour obtenir une VM performante, stable et optimisée sur ESXi, il existe des bonnes pratiques (Best Practices) que tout administrateur système devrait suivre.

Voici la recette de la "VM idéale" selon les standards actuels de VMware.

---

## 1. Le processeur (vCPU) : la règle du "Moins, c'est mieux"

L'erreur classique est de sur-provisionner les vCPU. Cela provoque du **CPU Ready**, un état où la VM attend que l'hyperviseur trouve assez de cœurs physiques libres pour s'exécuter.

- **Dimensionnement** : Commencez avec 1 ou 2 vCPU. Augmentez uniquement si vous observez une saturation réelle.
- **Topologie** : Préférez augmenter le nombre de "Sockets" plutôt que le nombre de "Cores per Socket", sauf contrainte de licence logicielle.
- **NUMA** : Essayez de ne pas dépasser le nombre de cœurs physiques présents sur un seul processeur physique (nœud NUMA) pour éviter les latences mémoire.

---

## 2. La mémoire (RAM)

- **Réservation** : Pour les applications critiques (SQL, Oracle), réservez toute la RAM pour éviter le "swapping" sur le disque.
- **Dimensionnement** : Évitez de donner trop de RAM ; si l'OS invité ne l'utilise pas, ESXi peut avoir du mal à la gérer efficacement via le ballooning.

---

## 3. Stockage et contrôleurs

Le choix du contrôleur est crucial pour les performances d'entrée/sortie (I/O).

| Composant | Recommandation | Pourquoi ? |
|---|---|---|
| Contrôleur SCSI | **VMware Paravirtual (PVSCSI)** | Moins d'utilisation CPU et meilleur débit pour les charges intensives. |
| Type de disque | **Thin Provisioning** (généralement) | Gain d'espace. Utilisez le Thick Provision Lazy Zeroed uniquement pour des besoins de performance extrêmes. |
| Contrôleur NVMe | **NVMe Virtuel** | À privilégier pour les OS modernes (Win 10/11, Server 2019+) sur stockage SSD/NVMe. |

---

## 4. Réseau : le standard VMXNET3

N'utilisez **jamais** le pilote E1000 (émulation Intel) sauf si l'OS est trop vieux pour reconnaître autre chose.

**VMXNET3** est un pilote paravirtualisé qui offre des performances 10Gbps+ et décharge le CPU des calculs réseau (offloading).

---

## 5. Optimisations "Hygiène"

Une VM propre est une VM rapide :

- **VMware Tools** : Toujours installés et à jour. C'est le pont entre l'hyperviseur et l'OS.
- **Suppression du superflu** : Supprimez le lecteur de disquette, le contrôleur USB (si inutile) et déconnectez le lecteur CD/ISO après l'installation. Chaque périphérique virtuel consomme un peu de ressources.
- **Synchronisation horaire** : Activez la synchronisation du temps avec l'hôte via les VMware Tools.

---

> ⚠️ **Note importante** : N'oubliez pas de choisir le bon **Guest OS Family** dans les paramètres de la VM. Cela permet à ESXi d'appliquer des optimisations spécifiques au système d'exploitation et d'exposer les bons pilotes par défaut.
