---
layout: post
title: "Migrer son blog WordPress vers GitHub Pages avec Jekyll"
date: 2026-03-25
categories: [tutoriels]
tags: [wordpress, github, jekyll, migration, blog]
---

Après plusieurs années sur WordPress.com, j'ai décidé de migrer mon blog **NOOBS** vers **GitHub Pages**. Pourquoi ? Parce que le plan gratuit WordPress.com est devenu trop limité : pas de CSS personnalisé, pas de plugins, des pubs imposées. GitHub Pages offre un hébergement **100% gratuit**, un contrôle total du design, et une vitesse imbattable.

Voici le guide complet de ma migration, étape par étape.

## Pourquoi quitter WordPress.com ?

Après 61 articles et plusieurs années sur WordPress.com (plan gratuit), voici les limitations qui m'ont poussé à partir :

- **Pas de CSS personnalisé** — impossible de personnaliser le design sans payer
- **Thème Greyzed vieillissant** — peu de thèmes sombres modernes disponibles
- **Publicités imposées** — WordPress affiche ses pubs sur votre site gratuit
- **Pas de plugins** — aucune extension possible en plan gratuit
- **Performance moyenne** — pages dynamiques plus lentes que du statique

## Pourquoi GitHub Pages + Jekyll ?

- **Gratuit** — hébergement, SSL, même avec un domaine personnalisé
- **Ultra rapide** — pages statiques, pas de base de données
- **Contrôle total** — HTML, CSS, JavaScript, tout est à vous
- **Markdown** — écriture des articles en Markdown, coloration syntaxique native
- **Git** — versioning de tout votre site, backup automatique
- **Communauté** — des centaines de thèmes Jekyll disponibles

## Prérequis

Avant de commencer, installez ces outils :

- **Git** — [git-scm.com](https://git-scm.com/downloads)
- **Ruby** (3.0+) — [rubyinstaller.org](https://rubyinstaller.org/) (Windows) ou via Homebrew (Mac)
- **Jekyll** — installé via Ruby
- **VS Code** — [code.visualstudio.com](https://code.visualstudio.com/)

### Installation sur Mac

```bash
# Installer Homebrew (si pas déjà fait)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Installer Ruby via Homebrew (PAS le Ruby système !)
brew install ruby

# Ajouter au PATH
echo 'export PATH="/opt/homebrew/opt/ruby/bin:$PATH"' >> ~/.zshrc
echo 'export PATH="/opt/homebrew/lib/ruby/gems/4.0.0/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Vérifier
ruby --version   # Doit afficher 3.x ou 4.x
which ruby       # Doit afficher /opt/homebrew/...

# Installer Jekyll
gem install jekyll bundler
```

> **Attention** : n'utilisez jamais `sudo gem install` sur Mac. Si vous avez une erreur de permissions sur `/Library/Ruby/Gems/`, c'est que vous utilisez le Ruby système. Installez Ruby via Homebrew comme indiqué ci-dessus.

### Installation sur Windows

```bash
# Téléchargez Ruby+Devkit depuis rubyinstaller.org
# Après installation :
gem install jekyll bundler
jekyll --version
```

## Étape 1 — Créer le dépôt GitHub

1. Créez un compte sur [github.com](https://github.com) si nécessaire
2. Créez un nouveau dépôt nommé `votre-username.github.io`
3. Clonez-le en local :

```bash
git clone https://github.com/votre-username/votre-username.github.io.git
cd votre-username.github.io
```

> Le nom du dépôt **doit** être `votre-username.github.io` pour que GitHub Pages s'active automatiquement.

## Étape 2 — Initialiser Jekyll

```bash
cd votre-username.github.io
jekyll new . --force
bundle install
bundle exec jekyll serve
```

Ouvrez `http://localhost:4000` — vous verrez le thème par défaut (Minima).

## Étape 3 — Exporter depuis WordPress

1. Connectez-vous sur [wordpress.com/export](https://wordpress.com/export/)
2. Sélectionnez **"Tout le contenu"**
3. Téléchargez le fichier `.xml`
4. Placez-le dans votre projet :

```bash
cp ~/Downloads/*.xml export.xml
```

## Étape 4 — Importer les articles

```bash
# Installer l'importeur
gem install jekyll-import open_uri_redirections

# Lancer l'import
ruby -e "require 'jekyll-import';
JekyllImport::Importers::WordpressDotCom.run({
  'source' => 'export.xml',
  'no_fetch_images' => false,
  'assets_folder' => 'assets/images'
})"
```

L'importeur va :
- Créer un fichier `.md` par article dans `_posts/`
- Télécharger les images dans `assets/images/`
- Conserver les catégories et tags

> **Note** : certaines images externes (hotlinkées depuis d'autres sites) peuvent renvoyer des erreurs 404. C'est normal — ces images n'étaient pas hébergées sur votre WordPress. Vous pouvez les ignorer ou les supprimer des articles concernés.

### Nettoyer les images cassées

Après l'import, supprimez les références aux images dont les liens sont morts :

```bash
# Exemple : supprimer les liens vers un site externe disparu
find _posts/ -name "*.md" -o -name "*.html" | xargs sed -i '' '/site-disparu\.com/d'
```

## Étape 5 — Personnaliser le thème

Le thème Minima par défaut est basique. Pour le remplacer par un thème personnalisé :

### Supprimer Minima

```bash
rm -f assets/main.scss index.md index.markdown about.md about.markdown 404.html
```

Supprimez aussi la ligne `theme: minima` dans `_config.yml`.

### Créer votre propre thème

Créez cette structure :

```
_layouts/
  default.html     → Layout principal
  post.html        → Template d'article
  page.html        → Template de page
_includes/
  header.html      → Navigation
  footer.html      → Pied de page
assets/
  css/style.css    → Votre CSS personnalisé
```

Le layout `default.html` est le squelette de toutes vos pages :

```html
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{% raw %}{% if page.title %}{{ page.title }} | {% endif %}{{ site.title }}{% endraw %}</title>
  <link rel="stylesheet" href="{% raw %}{{ '/assets/css/style.css' | relative_url }}{% endraw %}">
</head>
<body>
  {% raw %}{% include header.html %}{% endraw %}
  <main class="container">
    {% raw %}{{ content }}{% endraw %}
  </main>
  {% raw %}{% include footer.html %}{% endraw %}
</body>
</html>
```

## Étape 6 — Configurer Jekyll

Voici un exemple de `_config.yml` complet :

```yaml
title: NOOBS
description: "Tutoriels IT — VMware, Windows Server, PowerShell"
url: "https://votre-username.github.io"
baseurl: ""
author:
  name: Votre Nom
lang: fr

permalink: /:year/:month/:day/:title/

paginate: 9
paginate_path: "/page/:num/"

markdown: kramdown
highlighter: rouge

plugins:
  - jekyll-feed
  - jekyll-seo-tag
  - jekyll-paginate
  - jekyll-sitemap

exclude:
  - Gemfile
  - Gemfile.lock
  - README.md
  - export.xml
```

## Étape 7 — Déployer sur GitHub Pages

### Tester en local

```bash
bundle exec jekyll serve --livereload
```

Vérifiez que tout fonctionne sur `http://localhost:4000`.

### Pousser sur GitHub

```bash
echo "export.xml" >> .gitignore
git add .
git commit -m "Migration vers Jekyll"
git push origin main
```

> **Important** : GitHub ne supporte plus l'authentification par mot de passe. Vous devez créer un **Personal Access Token** sur [github.com/settings/tokens](https://github.com/settings/tokens) et l'utiliser comme mot de passe.

### Activer GitHub Pages

1. Allez sur votre dépôt → **Settings** → **Pages**
2. Source : **Deploy from a branch**
3. Branch : **main** / dossier **root**
4. Cliquez **Save**

Votre site sera en ligne sur `https://votre-username.github.io` en 1-2 minutes.

## Étape 8 — Domaine personnalisé (optionnel)

Vous pouvez connecter un domaine personnalisé gratuitement :

1. Achetez un domaine (~12€/an chez OVH, Gandi, etc.)
2. Dans Settings → Pages → **Custom domain**, entrez votre domaine
3. Configurez les DNS chez votre registrar :

```
A     @     185.199.108.153
A     @     185.199.109.153
A     @     185.199.110.153
A     @     185.199.111.153
CNAME www   votre-username.github.io
```

Le SSL (HTTPS) est automatique et gratuit. Cochez **"Enforce HTTPS"**.

## Workflow quotidien

Publier un article sur Jekyll, c'est simple :

```bash
# 1. Créer l'article
touch _posts/2026-03-25-mon-nouveau-tuto.md

# 2. Écrire en Markdown avec le front matter
# ---
# layout: post
# title: "Mon super tuto"
# date: 2026-03-25
# categories: [vmware]
# ---
# Contenu de l'article en Markdown...

# 3. Tester
bundle exec jekyll serve --livereload

# 4. Publier
git add .
git commit -m "Nouveau tuto: mon sujet"
git push
```

C'est tout. Pas de tableau de bord, pas de base de données, pas de mise à jour de sécurité. Juste du Markdown et un `git push`.

## Les pièges à éviter

Voici les problèmes que j'ai rencontrés pendant ma migration :

1. **Ruby système sur Mac** — N'utilisez jamais `/usr/bin/ruby`. Installez Ruby via Homebrew.
2. **`gem install` avec permission denied** — Ne faites JAMAIS `sudo gem install`. Corrigez le PATH.
3. **Bundler cassé après mise à jour Ruby** — Relancez `brew unlink ruby && brew link ruby --force` puis `gem install bundler`.
4. **`theme: minima` dans _config.yml** — Si vous utilisez votre propre thème, supprimez cette ligne sinon page blanche.
5. **Fichiers fantômes** — Supprimez `index.markdown`, `about.markdown` et `404.html` du thème par défaut.
6. **Images externes en 404** — Certaines images hotlinkées depuis d'autres sites peuvent avoir disparu. Nettoyez les références.
7. **Authentification GitHub** — Utilisez un Personal Access Token, pas votre mot de passe.

## Conclusion

La migration WordPress → GitHub Pages m'a pris environ une heure. Le résultat : un blog **plus rapide**, **plus beau**, **entièrement personnalisable**, et **100% gratuit**. Si vous avez un blog technique, je recommande cette solution sans hésiter.

Le code source de ce blog est disponible sur [GitHub](https://github.com/fhugonnier/fhugonnier.github.io).
