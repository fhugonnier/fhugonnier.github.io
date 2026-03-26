---
layout: post
title: "Configurer un VPN IPsec IKEv2 avec LDAP Synology sur FortiGate 40"
date: 2026-03-26
categories: [reseau]
tags: [fortigate, vpn, ipsec, ikev2, ldap, synology, fortinet]
---

Comment mettre en place un VPN IPsec IKEv2 sur un FortiGate 40 avec authentification LDAP hébergé sur un **NAS Synology** (paquet LDAP Server) ? Ce guide couvre la configuration complète en **CLI** et en **interface graphique**, avec le diagnostic en cas de problème.

## Architecture

```
Client (Windows/macOS/FortiClient)
        │
        │  IKEv2 + EAP (user/pass)
        ▼
   ┌──────────┐        ┌──────────────────┐
   │ FortiGate │───────▶│ NAS Synology     │
   │    40     │  LDAP  │ Paquet LDAP Server│
   │  wan1     │◀───────│ 192.168.1.10     │
   └──────────┘        └──────────────────┘
        │
        │  Tunnel IPsec
        │  10.10.10.x → 192.168.1.0/24
        ▼
   Réseau interne
```

Le principe : le client VPN se connecte au FortiGate en IKEv2, s'authentifie avec son login/mot de passe LDAP (stocké sur le NAS Synology), et accède au réseau interne à travers un tunnel chiffré.

## Prérequis côté Synology

Avant de configurer le FortiGate, assurez-vous que le paquet **LDAP Server** est installé et configuré sur votre NAS Synology.

### Vérifier la configuration LDAP Server sur le NAS

Ouvrez **LDAP Server** sur le DSM de votre Synology et notez ces informations :

| Information | Où la trouver | Exemple |
|---|---|---|
| FQDN ou IP du NAS | Paramètres réseau du NAS | 192.168.1.10 |
| Base DN | LDAP Server → Paramètres | dc=mondomaine,dc=com |
| Port LDAP | LDAP Server → Paramètres | 389 (LDAP) ou 636 (LDAPS) |
| Compte Bind DN | Créé dans LDAP Server | uid=ldap-bind,cn=users,dc=mondomaine,dc=com |

### Structure LDAP Synology vs Active Directory

Le paquet LDAP Server de Synology utilise un schéma LDAP standard (pas le schéma Active Directory). Les principales différences :

| Élément | Active Directory | Synology LDAP Server |
|---|---|---|
| Identifiant utilisateur | sAMAccountName | uid |
| Base des utilisateurs | CN=Users,DC=... | cn=users,dc=... |
| Base des groupes | OU=Groups,DC=... | cn=groups,dc=... |
| Classe d'objet utilisateur | user | posixAccount |
| Classe d'objet groupe | group | posixGroup |
| Port sécurisé | 636 (LDAPS) | 636 (LDAPS) |
| Bind DN | CN=user,OU=... | uid=user,cn=users,dc=... |

### Créer un compte de service LDAP sur le NAS

Dans **LDAP Server** → **Utilisateurs**, créez un compte dédié pour le FortiGate (ne pas utiliser le compte admin) :

- **Nom** : ldap-bind
- **Mot de passe** : un mot de passe complexe
- Ce compte servira uniquement au FortiGate pour interroger l'annuaire

### Créer un groupe pour les utilisateurs VPN

Dans **LDAP Server** → **Groupes**, créez un groupe :

- **Nom** : vpn-users
- Ajoutez les utilisateurs autorisés à se connecter au VPN

---

## Partie 1 — Configuration en CLI

### 1. Configurer le serveur LDAP (Synology)

```
config user ldap
    edit "SYNOLOGY-LDAP"
        set server "192.168.1.10"
        set cnid "uid"
        set dn "dc=mondomaine,dc=com"
        set type regular
        set username "uid=ldap-bind,cn=users,dc=mondomaine,dc=com"
        set password "MotDePasseCompte"
        set port 389
    next
end
```

> **Différences clés avec Active Directory** : le `cnid` est `uid` (pas `sAMAccountName`), et le format du `username` (Bind DN) suit la syntaxe LDAP standard `uid=xxx,cn=users,dc=xxx` au lieu du format AD `CN=xxx,OU=xxx,DC=xxx`.

Pour activer LDAPS (chiffré) si votre NAS le supporte :

```
config user ldap
    edit "SYNOLOGY-LDAP"
        set secure ldaps
        set port 636
    next
end
```

### 2. Créer un groupe d'utilisateurs lié au LDAP Synology

```
config user group
    edit "VPN-IPSEC-Users"
        set member "SYNOLOGY-LDAP"
        config match
            edit 1
                set server-name "SYNOLOGY-LDAP"
                set group-name "cn=vpn-users,cn=groups,dc=mondomaine,dc=com"
            next
        end
    next
end
```

> **Attention** : le DN du groupe suit la structure Synology `cn=vpn-users,cn=groups,dc=...` et non `CN=VPN-Users,OU=Groups,DC=...` comme en Active Directory.

### 3. Phase 1 — Tunnel IKEv2

#### Variante avec certificat

```
config vpn ipsec phase1-interface
    edit "VPN-IKEv2-RemoteAccess"
        set type dynamic
        set interface "wan1"
        set ike-version 2
        set authmethod signature
        set mode aggressive
        set peertype any
        set net-device disable
        set mode-cfg enable
        set proposal aes256-sha256 aes256-sha512
        set dpd on-idle
        set dpd-retryinterval 30
        set certificate "Fortinet_Factory"
        set xauthtype auto
        set authusrgrp "VPN-IPSEC-Users"
        set ipv4-start-ip 10.10.10.1
        set ipv4-end-ip 10.10.10.50
        set ipv4-netmask 255.255.255.0
        set dns-mode auto
        set ipv4-split-include "LAN-interne"
        set keylife 86400
        set nattraversal enable
    next
end
```

#### Variante avec PSK (Pre-Shared Key) + EAP

```
config vpn ipsec phase1-interface
    edit "VPN-IKEv2-PSK"
        set type dynamic
        set interface "wan1"
        set ike-version 2
        set peertype any
        set net-device disable
        set mode-cfg enable
        set authmethod psk
        set psksecret "VotreCléPartagéeComplexe!"
        set proposal aes256-sha256
        set dpd on-idle
        set dpd-retryinterval 30
        set xauthtype auto
        set authusrgrp "VPN-IPSEC-Users"
        set ipv4-start-ip 10.10.10.1
        set ipv4-end-ip 10.10.10.50
        set ipv4-netmask 255.255.255.0
        set dns-mode auto
        set ipv4-split-include "LAN-interne"
        set nattraversal enable
        set keylife 86400
    next
end
```

### 4. Phase 2 — Paramètres de chiffrement du tunnel

```
config vpn ipsec phase2-interface
    edit "VPN-IKEv2-P2"
        set phase1name "VPN-IKEv2-RemoteAccess"
        set proposal aes256-sha256
        set pfs enable
        set dhgrp 14
        set keylifeseconds 3600
    next
end
```

### 5. Définir les objets réseau

```
config firewall address
    edit "LAN-interne"
        set subnet 192.168.1.0 255.255.255.0
    next
end

config firewall address
    edit "VPN-Pool"
        set type iprange
        set start-ip 10.10.10.1
        set end-ip 10.10.10.50
    next
end
```

### 6. Politiques de pare-feu

#### Accès VPN vers le LAN

```
config firewall policy
    edit 0
        set name "VPN-IPsec-to-LAN"
        set srcintf "VPN-IKEv2-RemoteAccess"
        set dstintf "internal"
        set srcaddr "VPN-Pool"
        set dstaddr "LAN-interne"
        set action accept
        set schedule "always"
        set service "ALL"
        set groups "VPN-IPSEC-Users"
        set logtraffic all
    next
end
```

#### Accès VPN vers Internet (optionnel)

```
config firewall policy
    edit 0
        set name "VPN-IPsec-to-WAN"
        set srcintf "VPN-IKEv2-RemoteAccess"
        set dstintf "wan1"
        set srcaddr "VPN-Pool"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "ALL"
        set groups "VPN-IPSEC-Users"
        set nat enable
        set logtraffic all
    next
end
```

---

## Partie 2 — Configuration en interface graphique

### Étape 1 — Configurer le serveur LDAP Synology

**Chemin** : `User & Authentication` → `LDAP Servers` → `Create New`

| Champ | Valeur |
|---|---|
| Name | SYNOLOGY-LDAP |
| Server IP/Name | 192.168.1.10 |
| Server Port | 389 (LDAP) ou 636 (LDAPS) |
| Common Name Identifier | **uid** |
| Distinguished Name | dc=mondomaine,dc=com |
| Bind Type | Regular |
| Username | uid=ldap-bind,cn=users,dc=mondomaine,dc=com |
| Password | (mot de passe du compte de service) |
| Secure Connection | Cocher si LDAPS (port 636) |

> **Point crucial** : le champ **Common Name Identifier** doit être `uid` et non `sAMAccountName`. C'est la différence fondamentale avec Active Directory. Si vous mettez `sAMAccountName`, l'authentification échouera systématiquement.

Cliquez sur **Test Connectivity** puis sur **Test User Credentials** avec un compte LDAP existant pour valider. Cliquez **OK**.

### Étape 2 — Créer le groupe d'utilisateurs

**Chemin** : `User & Authentication` → `User Groups` → `Create New`

| Champ | Valeur |
|---|---|
| Name | VPN-IPSEC-Users |
| Type | Firewall |
| Remote Groups → Add | |
| → Remote Server | SYNOLOGY-LDAP |
| → Groups | Parcourez l'arborescence LDAP pour sélectionner `cn=vpn-users,cn=groups,dc=mondomaine,dc=com` |

> **Astuce** : si vous ne voyez pas les groupes en parcourant l'arborescence, vérifiez que le compte Bind DN a bien les droits de lecture sur `cn=groups` dans les paramètres LDAP Server du Synology.

Cliquez **OK**.

### Étape 3 — Créer l'objet adresse du réseau LAN

**Chemin** : `Policy & Objects` → `Addresses` → `Create New`

| Champ | Valeur |
|---|---|
| Name | LAN-interne |
| Type | Subnet |
| Subnet | 192.168.1.0/24 |
| Interface | internal |

Cliquez **OK**.

### Étape 4 — Créer le tunnel VPN IPsec

**Chemin** : `VPN` → `IPsec Tunnels` → `Create New` → `IPsec Tunnel`

#### 4a. Assistant — Étape 1

| Champ | Valeur |
|---|---|
| Name | VPN-IKEv2-RemoteAccess |
| Template Type | Remote Access |
| Remote Device Type | Client-based (FortiClient, Windows natif...) |

Cliquez **Next**.

#### 4b. Assistant — Étape 2 : Authentication

| Champ | Valeur |
|---|---|
| Incoming Interface | wan1 |
| Authentication Method | Pre-shared Key |
| Pre-shared Key | (entrez une clé complexe) |
| User Group | VPN-IPSEC-Users |

Cliquez **Next**.

#### 4c. Assistant — Étape 3 : Policy & Routing

| Champ | Valeur |
|---|---|
| Local Interface | internal |
| Local Address | LAN-interne (192.168.1.0/24) |
| Client Address Range | Start: 10.10.10.1 — End: 10.10.10.50 |
| Subnet Mask | 255.255.255.0 |
| DNS Server | 192.168.1.10 (IP du NAS ou de votre DNS) |
| Enable Split Tunneling | Cocher |
| Accessible Networks | LAN-interne |

Cliquez **Next** puis **Finish**.

### Étape 5 — Forcer IKEv2 sur le tunnel

L'assistant crée le tunnel en IKEv1 par défaut. Il faut le modifier manuellement.

**Chemin** : `VPN` → `IPsec Tunnels` → clic sur `VPN-IKEv2-RemoteAccess` → `Edit`

#### Onglet Network / Phase 1

| Champ | Valeur à modifier |
|---|---|
| IKE Version | Changer de 1 → **2** |
| NAT Traversal | Enable |
| Dead Peer Detection | On Idle |

#### Phase 1 Proposal (Encryption)

| Champ | Valeur |
|---|---|
| Encryption | AES256 |
| Authentication | SHA256 |
| Diffie-Hellman Group | 14 (2048-bit) |
| Key Lifetime (seconds) | 86400 |

#### Phase 2 Selectors → Edit

| Champ | Valeur |
|---|---|
| Encryption | AES256 |
| Authentication | SHA256 |
| Enable PFS | Cocher |
| DH Group | 14 |
| Key Lifetime | 3600 |

Cliquez **OK**.

### Étape 6 — Vérifier les politiques de pare-feu

**Chemin** : `Policy & Objects` → `Firewall Policy`

L'assistant a normalement créé la règle automatiquement. Vérifiez que l'interface source est bien `VPN-IKEv2-RemoteAccess`, la destination `LAN-interne`, et que le groupe `VPN-IPSEC-Users` est bien assigné.

---

## Partie 3 — Configuration côté client

### Windows (client natif)

`Paramètres` → `Réseau` → `VPN` → `Ajouter une connexion VPN`

| Champ | Valeur |
|---|---|
| Fournisseur | Windows (intégré) |
| Type | IKEv2 |
| Adresse serveur | IP publique ou FQDN du FortiGate |
| Type d'authentification | Nom d'utilisateur + mot de passe |

Pour forcer les bons algorithmes de chiffrement via PowerShell :

```powershell
Add-VpnConnection -Name "VPN-Bureau" `
    -ServerAddress "vpn.mondomaine.com" `
    -TunnelType IKEv2 `
    -AuthenticationMethod EAP `
    -EncryptionLevel Maximum

Set-VpnConnectionIPsecConfiguration -ConnectionName "VPN-Bureau" `
    -AuthenticationTransformConstants SHA256128 `
    -CipherTransformConstants AES256 `
    -DHGroup Group14 `
    -IntegrityCheckMethod SHA256 `
    -PfsGroup PFS2048 `
    -EncryptionMethod AES256
```

### macOS

`Préférences Système` → `Réseau` → `+` → `VPN` → `IKEv2`

Renseignez l'adresse du serveur, l'identifiant distant (IP ou FQDN du FortiGate) et le type d'authentification par identifiant/mot de passe.

---

## Partie 4 — Diagnostic et vérification

### Tester l'authentification LDAP Synology

C'est la **première chose à vérifier**. Si le LDAP ne répond pas, rien ne fonctionnera.

En CLI :

```
diagnose test authserver ldap SYNOLOGY-LDAP utilisateur motdepasse
```

En GUI : `User & Authentication` → `LDAP Servers` → clic sur `SYNOLOGY-LDAP` → **Test User Credentials**.

### Problèmes fréquents avec le LDAP Synology

| Symptôme | Cause probable | Solution |
|---|---|---|
| "Connection failed" | Port bloqué ou NAS injoignable | Vérifiez le pare-feu du NAS (port 389 ou 636 ouvert) |
| "Invalid credentials" | Mauvais Bind DN | Vérifiez le format : `uid=xxx,cn=users,dc=xxx,dc=xxx` |
| "User not found" | cnid incorrect | Le cnid doit être `uid`, pas `sAMAccountName` |
| "No matching group" | Mauvais DN de groupe | Vérifiez : `cn=vpn-users,cn=groups,dc=xxx,dc=xxx` |
| Timeout | LDAPS sans certificat valide | Testez d'abord en LDAP (389) puis passez en LDAPS |

### Monitorer les tunnels actifs

En CLI :

```
diagnose vpn ike gateway list
diagnose vpn tunnel list
get vpn ipsec tunnel summary
```

En GUI : `Monitor` → `IPsec Monitor`

### Debug IKEv2 en temps réel

```
diagnose debug application ike -1
diagnose debug enable
```

Pour arrêter :

```
diagnose debug disable
diagnose debug reset
```

### Consulter les logs

En GUI : `Log & Report` → `Events` → `VPN Events`

---

## Points importants pour le FortiGate 40

- **Nombre de tunnels** : le modèle 40 supporte un nombre limité de tunnels simultanés. Vérifiez avec `get system status`.
- **Performance crypto** : privilégiez AES256-SHA256 plutôt que des suites plus lourdes.
- **FortiOS minimum** : IKEv2 avec mode-cfg et EAP nécessite au minimum FortiOS 5.6+. Idéalement, passez en 7.x.
- **NAT-T** : activez toujours `nattraversal enable` car la majorité des clients sont derrière du NAT.
- **Pare-feu du NAS** : n'oubliez pas d'ouvrir le port LDAP (389 ou 636) dans le pare-feu du Synology, pas seulement celui du FortiGate.

## Les causes d'échec les plus fréquentes

1. **cnid incorrect** : `uid` pour Synology LDAP Server, jamais `sAMAccountName`
2. **Format du Bind DN** : `uid=user,cn=users,dc=xxx` et non `CN=user,OU=xxx,DC=xxx`
3. **Format du groupe** : `cn=groupe,cn=groups,dc=xxx` et non `CN=groupe,OU=Groups,DC=xxx`
4. **Version IKE** : client et FortiGate doivent être sur IKEv2 tous les deux
5. **Algorithmes de chiffrement** : les proposals Phase 1 et Phase 2 doivent correspondre
6. **Pare-feu du NAS** : le port LDAP doit être ouvert sur le Synology
7. **Ports UDP** : les ports 500 et 4500 doivent être ouverts sur le réseau du client
