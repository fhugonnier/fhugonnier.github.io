---
layout: post
title: "Configuration VLAN VoIP sur Zyxel GS1900-24HP"
date: 2026-04-21
categories: [reseau, voip]
tags: [vlan, voip, zyxel, gs1900, switch, qos, 802.1q]
---

Le GS1900-24HP est un switch manageable PoE avec interface web, très répandu en PME. Voici comment configurer un VLAN dédié à la VoIP pour séparer proprement le trafic voix du trafic données.

---

## 1. Accéder à l'interface d'administration

Connectez-vous à l'interface web du switch (par défaut : `192.168.1.1`, identifiants `admin` / `1234`).

---

## 2. Créer le VLAN VoIP

Allez dans **VLAN > Static VLAN** puis cliquez sur **Add** :

- **VLAN ID** : choisissez un identifiant, par exemple `100`
- **Name** : `VOIP`
- Cochez les ports concernés :
  - Les ports où sont branchés les téléphones IP → **Untagged (U)**
  - Le ou les ports uplink (vers le routeur/serveur VoIP) → **Tagged (T)**
  - Les ports non concernés → **Not Member (—)**

Cliquez sur **Apply**.

---

## 3. Configurer le PVID des ports téléphones

Allez dans **VLAN > VLAN Port Setting**. Pour chaque port où un téléphone est branché directement (sans PC derrière) :

- **PVID** : `100` (le VLAN VoIP)
- **Frame Type** : `All`

Cela garantit que le trafic non taggé arrivant sur ces ports sera automatiquement placé dans le VLAN 100.

---

## 4. Cas courant : téléphone + PC sur le même port

Si un PC est branché derrière le téléphone (daisy-chain), il faut utiliser le **Voice VLAN** du switch :

- Allez dans **VLAN > Voice VLAN**
- Activez la fonctionnalité Voice VLAN
- **Voice VLAN ID** : `100`
- **Priority** : `6` (valeur recommandée pour la VoIP, correspond à EF/DSCP 46)
- Sélectionnez les ports concernés et activez-les

Le switch détectera alors automatiquement les téléphones IP (via les OUI des adresses MAC ou LLDP-MED) et séparera le trafic voix (VLAN 100 taggé) du trafic data (VLAN 1 non taggé).

---

## 5. Ajouter les OUI si nécessaire

Dans **Voice VLAN > OUI Settings**, vérifiez que le fabricant de vos téléphones est listé. Les OUI courants sont souvent pré-configurés (Cisco, Polycom, etc.), mais vous pouvez en ajouter manuellement si besoin en entrant les 3 premiers octets de l'adresse MAC de vos téléphones.

---

## 6. Configurer la QoS (recommandé)

Pour prioriser le trafic voix, allez dans **QoS > General** :

- Activez la QoS
- **Mode** : `802.1p` (basé sur la priorité VLAN)
- Vérifiez que la priorité `6` est bien mappée sur la queue la plus haute

---

## 7. Configurer le port uplink

Le port qui remonte vers votre routeur ou serveur IPBX doit être **Tagged** sur le VLAN 100, et généralement aussi **Untagged** sur le VLAN 1 (données). Le routeur/pare-feu en face devra aussi gérer le trunk 802.1Q avec le VLAN 100.

---

## 8. Sauvegarder

Pensez à aller dans **Management > Save Configuration** pour sauvegarder en mémoire permanente, sinon les changements seront perdus au redémarrage.

---

## Résumé du schéma type

```
PC ──► Téléphone IP ──► Port switch (PVID=1, Voice VLAN=100 taggé)
                                │
                         Port uplink (Tagged VLAN 100 + Untagged VLAN 1)
                                │
                         Routeur / IPBX
```

---

## Points à retenir

- Le **Voice VLAN** est la fonctionnalité clé quand un PC et un téléphone partagent le même port : le switch sépare automatiquement les flux.
- La **priorité 802.1p à 6** assure que les paquets voix passent en premier, même en cas de congestion réseau.
- N'oubliez pas de **sauvegarder la config** — le GS1900 ne le fait pas automatiquement.
- Côté routeur/pare-feu, pensez à créer l'interface VLAN 100 avec son propre sous-réseau et son serveur DHCP dédié aux téléphones.
