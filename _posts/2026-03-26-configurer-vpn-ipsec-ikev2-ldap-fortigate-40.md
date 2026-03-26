---
layout: post
title: "Configurer un VPN IPsec IKEv2 avec LDAP sur FortiGate 40"
date: 2026-03-26
categories: [reseau]
tags: [fortigate, vpn, ipsec, ikev2, ldap, active-directory, fortinet]
---

Comment mettre en place un VPN IPsec IKEv2 sur un FortiGate 40 avec authentification LDAP (Active Directory) ? Ce guide couvre la configuration complète en **CLI** et en **interface graphique**, avec le diagnostic en cas de problème.

## Architecture

```
Client (Windows/macOS/FortiClient)
        │
        │  IKEv2 + EAP (user/pass)
        ▼
   ┌──────────┐        ┌─────────────┐
   │ FortiGate │───────▶│ Serveur LDAP │
   │    40     │  LDAPS │  (AD / DC)   │
   │  wan1     │◀───────│ 192.168.1.10 │
   └──────────┘        └─────────────┘
        │
        │  Tunnel IPsec
        │  10.10.10.x → 192.168.1.0/24
        ▼
   Réseau interne
```

Le principe : le client VPN se connecte au FortiGate en IKEv2, s'authentifie avec son login/mot de passe Active Directory (relayé via LDAP), et accède au réseau interne à travers un tunnel chiffré.

---

## Partie 1 — Configuration en CLI

### 1. Configurer le serveur LDAP

```
config user ldap
    edit "LDAP-SERVER"
        set server "192.168.1.10"
        set cnid "sAMAccountName"
        set dn "DC=mondomaine,DC=local"
        set type regular
        set username "CN=ldap-bind,OU=Service Accounts,DC=mondomaine,DC=local"
        set password "MotDePasseCompte"
        set secure ldaps
        set port 636
    next
end
```

### 2. Créer un groupe d'utilisateurs lié au LDAP

```
config user group
    edit "VPN-IPSEC-Users"
        set member "LDAP-SERVER"
        config match
            edit 1
                set server-name "LDAP-SERVER"
                set group-name "CN=VPN-Users,OU=Groups,DC=mondomaine,DC=local"
            next
        end
    next
end
```

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

Si vous ne souhaitez pas utiliser de certificats côté serveur :

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

### Étape 1 — Configurer le serveur LDAP

**Chemin** : `User & Authentication` → `LDAP Servers` → `Create New`

| Champ | Valeur |
|---|---|
| Name | LDAP-SERVER |
| Server IP/Name | 192.168.1.10 |
| Server Port | 636 (LDAPS) ou 389 (LDAP) |
| Common Name Identifier | sAMAccountName |
| Distinguished Name | DC=mondomaine,DC=local |
| Bind Type | Regular |
| Username | CN=ldap-bind,OU=Service Accounts,DC=mondomaine,DC=local |
| Password | (mot de passe du compte de service) |
| Secure Connection | Cocher si LDAPS (port 636) |

Cliquez sur **Test Connectivity** puis sur **Test User Credentials** avec un compte existant pour valider. Cliquez **OK**.

### Étape 2 — Créer le groupe d'utilisateurs

**Chemin** : `User & Authentication` → `User Groups` → `Create New`

| Champ | Valeur |
|---|---|
| Name | VPN-IPSEC-Users |
| Type | Firewall |
| Remote Groups → Add | |
| → Remote Server | LDAP-SERVER |
| → Groups | Parcourez l'arborescence LDAP pour sélectionner `CN=VPN-Users,OU=Groups,DC=mondomaine,DC=local` |

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
| DNS Server | 192.168.1.10 (ou votre DNS) |
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

L'assistant a normalement créé automatiquement les règles. Vérifiez-les :

**Chemin** : `Policy & Objects` → `Firewall Policy`

#### Règle VPN → LAN

| Champ | Valeur attendue |
|---|---|
| Name | VPN-IKEv2-RemoteAccess_local (auto-généré) |
| Incoming Interface | VPN-IKEv2-RemoteAccess |
| Outgoing Interface | internal |
| Source | all / VPN-IPSEC-Users |
| Destination | LAN-interne |
| Service | ALL |
| Action | Accept |
| Log Allowed Traffic | All Sessions |

Si vous voulez que les clients VPN accèdent aussi à Internet via le FortiGate, créez une nouvelle règle avec le NAT activé et l'interface sortante sur `wan1`.

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

### Tester l'authentification LDAP

En CLI :

```
diagnose test authserver ldap LDAP-SERVER utilisateur motdepasse
```

En GUI : `User & Authentication` → `LDAP Servers` → clic sur `LDAP-SERVER` → **Test User Credentials**.

### Monitorer les tunnels actifs

En CLI :

```
diagnose vpn ike gateway list
diagnose vpn tunnel list
get vpn ipsec tunnel summary
```

En GUI : `Monitor` → `IPsec Monitor` — vous verrez les tunnels actifs, les utilisateurs connectés, les adresses IP attribuées et le volume de trafic.

### Debug IKEv2 en temps réel

```
diagnose debug application ike -1
diagnose debug enable
```

Pour arrêter le debug :

```
diagnose debug disable
diagnose debug reset
```

### Consulter les logs

En GUI : `Log & Report` → `Events` → `VPN Events` — consultez les logs pour diagnostiquer les échecs de connexion.

---

## Points importants pour le FortiGate 40

Le FortiGate 40 est un modèle d'entrée de gamme. Gardez en tête ces contraintes :

- **Nombre de tunnels** : le modèle 40 supporte un nombre limité de tunnels simultanés. Vérifiez votre licence avec `get system status`.
- **Performance crypto** : le FortiGate 40 n'a pas de puce ASIC dédiée au chiffrement sur tous les modèles — privilégiez AES256-SHA256 plutôt que des suites plus lourdes.
- **FortiOS minimum** : IKEv2 avec mode-cfg et EAP nécessite au minimum FortiOS 5.6+. Idéalement, passez en 6.4 ou 7.x pour un meilleur support IKEv2.
- **NAT-T** : activez toujours `nattraversal enable` car la majorité des clients sont derrière du NAT.
- **LDAPS** : si vous utilisez LDAPS (port 636), assurez-vous que le certificat du serveur LDAP est importé ou que la vérification est désactivée.
- **Timeout et 2FA** : pensez à activer le timeout d'inactivité et le 2FA (FortiToken) si la sécurité le requiert.

## Les causes d'échec les plus fréquentes

Si la connexion VPN ne s'établit pas, vérifiez ces points dans l'ordre :

1. **Version IKE** : le client et le FortiGate doivent être sur IKEv2 tous les deux
2. **Algorithmes de chiffrement** : les proposals Phase 1 et Phase 2 doivent correspondre entre le client et le FortiGate
3. **NAT-T** : si le client est derrière un routeur NAT, le NAT Traversal doit être activé
4. **Authentification LDAP** : testez d'abord avec `diagnose test authserver ldap` avant de blâmer le tunnel
5. **Pare-feu** : vérifiez que la politique autorise bien le trafic depuis l'interface VPN vers l'interface interne
6. **Port bloqué** : les ports UDP 500 et 4500 doivent être ouverts sur le réseau du client
