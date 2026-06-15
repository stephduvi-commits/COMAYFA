# AGENTS.md

## Vue d’ensemble
- Ce dépôt contient une application web statique en HTML/CSS/JS sans framework ni build.
- Les fichiers principaux sont :
  - `index.html` : page publique pour les clients / panneau d’information.
  - `admin.html` : interface d’administration.
- Le projet est hébergé en statique (GitHub Pages) et utilise `localStorage` pour la persistance.

## Conventions importantes
- Ne pas ajouter de dépendances de build, de bundler ou de framework si ce n’est pas déjà présent.
- Préserver le mode mobile-first et la logique single-file déjà en place.
- Les données utilisateur sont stockées avec les clés `panneau_v4` et `panneau_lang`.
- Les changements doivent rester compatibles avec les contenus déjà présents dans `DEFAULT` et avec les scripts existants.

## Règles de modification
- Quand vous modifiez la logique UI, vérifier la cohérence entre `index.html` et `admin.html`.
- Si vous ajoutez des nouveaux onglets ou contenus, garder la structure bilingue FR/NL/EN déjà utilisée.
- Les textes et libellés doivent rester lisibles sur mobile et ne pas casser le design actuel.
- Les correctifs doivent être raisonnables et minimalistes : ce projet est déjà volumineux et fortement inline.

## Points de vigilance
- Les fonctions de rendu et de traduction sont sensibles au changement de langue ; conserver la logique existante.
- La gestion de `SortableJS` dans `admin.html` est déjà spécifique ; ne pas réécrire l’architecture sans raison.
- Les données de configuration sont stockées dans `localStorage`; les modifications doivent rester rétrocompatibles.

## Référence utile
- Voir `DEBUG_PROMPT.md` pour les problèmes connus, les corrections déjà documentées et les zones à vérifier lors d’un correctif.
