# NOOBS — Terminal Dark Theme pour Jekyll

## Installation rapide

1. **Stoppez** le serveur Jekyll actuel (`Ctrl+C`)

2. **Supprimez** les fichiers du thème Minima :
   ```bash
   rm -f assets/main.scss index.md about.md
   ```

3. **Copiez** tous les fichiers de ce dossier dans votre projet :
   ```bash
   cp -r _layouts/ /Users/franck/fhugonnier.github.io/
   cp -r _includes/ /Users/franck/fhugonnier.github.io/
   cp -r assets/ /Users/franck/fhugonnier.github.io/
   cp -r _posts/ /Users/franck/fhugonnier.github.io/
   cp _config.yml /Users/franck/fhugonnier.github.io/
   cp Gemfile /Users/franck/fhugonnier.github.io/
   cp index.html /Users/franck/fhugonnier.github.io/
   cp about.md /Users/franck/fhugonnier.github.io/
   cp categories.md /Users/franck/fhugonnier.github.io/
   ```

4. **Installez** les dépendances et lancez :
   ```bash
   cd /Users/franck/fhugonnier.github.io
   bundle install
   bundle exec jekyll serve
   ```

5. Ouvrez **http://localhost:4000** — Terminal Dark !

## Structure des fichiers

```
_layouts/
  default.html     → Layout principal (HTML head/body)
  post.html        → Template d'article
  page.html        → Template de page statique
_includes/
  header.html      → Navigation NOOBS.dev
  footer.html      → Pied de page
assets/
  css/style.css    → CSS Terminal Dark complet
  images/          → Vos images (à remplir)
_posts/            → Vos articles en Markdown
_config.yml        → Configuration Jekyll
Gemfile            → Dépendances Ruby
index.html         → Page d'accueil avec grille
about.md           → Page À propos
categories.md      → Page des catégories
```
