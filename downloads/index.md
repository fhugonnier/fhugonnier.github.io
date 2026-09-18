---
layout: page
title: Téléchargements
date: 2025-06-25 11:00:00 +02:00
permalink: /downloads/
---

<div class="hero-text">
  <h1>Téléchargements</h1>
  <p>Retrouvez ici les outils et applications développés par NOOBS.</p>
</div>

<div class="download-grid">
  {% for file in site.static_files %}
    {% if file.path contains 'downloads/' and file.path != 'downloads/index.md' %}
    <div class="download-card">
      <h3>{{ file.basename }}</h3>
      <p class="meta">
        <strong>Type :</strong> {{ file.extname | upcase | replace: '.', '' }}<br>
        <strong>Taille :</strong> {{ file.size | filesize }}<br>
        <strong>Dernière mise à jour :</strong> {{ file.modified_time | date: "%d %b %Y" }}
      </p>
      <a href="{{ file.path | relative_url }}" class="btn-download" download>Télécharger</a>
    </div>
    {% endif %}
  {% endfor %}
</div>

<style>
  .download-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    gap: 20px;
    margin: 30px 0;
  }
  .download-card {
    background: var(--card-bg, #f8f9fa);
    border-radius: 8px;
    padding: 20px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  }
  .download-card h3 {
    margin: 0 0 10px 0;
    color: var(--text-color, #333);
  }
  .download-card .meta {
    color: var(--text-secondary, #666);
    font-size: 0.9em;
    margin: 10px 0;
  }
  .btn-download {
    display: inline-block;
    background: var(--primary-color, #2563eb);
    color: white;
    padding: 8px 16px;
    border-radius: 4px;
    text-decoration: none;
    font-weight: 500;
    transition: background 0.2s;
  }
  .btn-download:hover {
    background: var(--primary-dark, #1d4ed8);
  }
</style>
