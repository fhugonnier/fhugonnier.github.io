---
layout: page
title: Catégories
permalink: /categories/
---

{% assign sorted_cats = site.categories | sort %}
{% for cat in sorted_cats %}
<div class="category-section">
  <h2>{{ cat[0] }} ({{ cat[1].size }})</h2>
  <ul class="category-list">
    {% for post in cat[1] %}
    <li>
      <a href="{{ post.url | relative_url }}">{{ post.title }}</a>
      <time>{{ post.date | date: "%d %b %Y" }}</time>
    </li>
    {% endfor %}
  </ul>
</div>
{% endfor %}
