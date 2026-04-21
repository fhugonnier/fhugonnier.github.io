#!/bin/bash
# ============================================================================
# NOOBS Blog — Script de publication rapide
# Usage : ./publish.sh mon-article.md
#         ./publish.sh mon-article.md "Message de commit personnalisé"
# ============================================================================

set -euo pipefail

# ── Configuration ──────────────────────────────────────────────────────────
BLOG_DIR="$HOME/fhugonnier.github.io"    # ← Adapter si votre dépôt est ailleurs
POSTS_DIR="$BLOG_DIR/_posts"
BRANCH="main"                             # ← ou "master" selon votre config

# ── Couleurs ───────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ── Fonctions ──────────────────────────────────────────────────────────────
info()  { echo -e "${CYAN}[NOOBS]${NC} $1"; }
ok()    { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

# ── Vérifications ──────────────────────────────────────────────────────────
[[ $# -lt 1 ]] && error "Usage : $0 <fichier.md> [message de commit]"

SOURCE_FILE="$1"
COMMIT_MSG="${2:-}"

[[ ! -f "$SOURCE_FILE" ]] && error "Fichier introuvable : $SOURCE_FILE"
[[ ! -d "$BLOG_DIR" ]] && error "Dépôt blog introuvable : $BLOG_DIR\n  → Clonez-le d'abord : git clone git@github.com:fhugonnier/fhugonnier.github.io.git"
[[ ! -d "$POSTS_DIR" ]] && mkdir -p "$POSTS_DIR"

# ── Vérifier le format du nom de fichier ───────────────────────────────────
FILENAME=$(basename "$SOURCE_FILE")

if [[ ! "$FILENAME" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-.+\.md$ ]]; then
    # Ajouter la date du jour si absente
    TODAY=$(date +%Y-%m-%d)
    FILENAME="${TODAY}-${FILENAME}"
    warn "Nom de fichier sans date → renommé en : $FILENAME"
fi

# ── Vérifier le front matter ──────────────────────────────────────────────
if ! head -1 "$SOURCE_FILE" | grep -q "^---"; then
    error "Le fichier ne contient pas de front matter Jekyll (doit commencer par ---)"
fi

# ── Extraire le titre pour le commit ──────────────────────────────────────
TITLE=$(grep -m1 "^title:" "$SOURCE_FILE" | sed 's/title: *"\{0,1\}\(.*\)"\{0,1\}/\1/' | sed 's/"$//')

if [[ -z "$COMMIT_MSG" ]]; then
    COMMIT_MSG="📝 Nouvel article : $TITLE"
fi

# ── Copier l'article ──────────────────────────────────────────────────────
info "Copie de l'article vers $POSTS_DIR/$FILENAME"
cp "$SOURCE_FILE" "$POSTS_DIR/$FILENAME"
ok "Article copié"

# ── Git : add, commit, push ───────────────────────────────────────────────
cd "$BLOG_DIR"

info "Synchronisation avec le dépôt distant..."
git pull --rebase origin "$BRANCH" 2>/dev/null || warn "Pull échoué (pas grave si premier push)"

info "Ajout et commit..."
git add "_posts/$FILENAME"
git commit -m "$COMMIT_MSG"

info "Publication en cours..."
git push origin "$BRANCH"

echo ""
ok "Article publié avec succès !"
echo -e "${CYAN}   📄 ${FILENAME}${NC}"
echo -e "${CYAN}   🌐 https://fhugonnier.github.io/${NC}"
echo -e "${CYAN}   💬 ${COMMIT_MSG}${NC}"
echo ""
info "Le site sera en ligne dans ~30 secondes (build GitHub Pages)."
