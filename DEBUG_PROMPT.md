# 🛠️ PROMPT DE DÉBOGAGE — Panneau d'information ELU
## À coller dans Claude / Copilot directement depuis VSCode

---

## CONTEXTE DU PROJET

Je travaille sur une application web HTML/CSS/JS **single-file** (sans framework, sans bundler) :
- `index.html` — Page publique clients, mobile-first, ~144 KB
- `admin.html` — Interface administration PC, ~183 KB
- Hébergement : **GitHub Pages** (statique, pas de serveur)
- Données persistées via **localStorage** (clé `panneau_v4`)
- Langue active stockée dans **localStorage** (`panneau_lang`)
- Logo ELU embarqué en **base64** inline dans le JS (`ELU_LOGO_SRC`)
- Navigation dépendance externe : **SortableJS 1.15.0** (CDN jsDelivr)

---

## 🔴 PROBLÈMES IDENTIFIÉS À DÉBOGUER

### PROBLÈME 1 — `renderAll()` n'appelle pas `renderNavGrid()`
**Fichier :** `index.html`
**Symptôme :** Après `enterApp()` ou `changeLang()`, la grille de navigation reste vide ou affiche l'ancienne langue.
**Cause identifiée :** `renderAll()` met à jour le header (titre, langue, horloge) mais ne déclenche **pas** `renderNavGrid()`. La fonction existe mais n'est pas appelée dans `renderAll`.

```js
// ÉTAT ACTUEL de renderAll() — manque l'appel final :
function renderAll(){
  applyColor(DATA.accentColor||'#F49634');
  // ... mise à jour header ...
  // ❌ renderNavGrid() manquant ici
}

// CORRECTION à appliquer :
function renderAll(){
  applyColor(DATA.accentColor||'#F49634');
  const ttl=document.getElementById('hdr-title');
  const sub=document.getElementById('hdr-subtitle');
  const lsb=document.getElementById('lang-switch-btn');
  if(ttl) ttl.textContent=DATA.titre;
  if(sub) sub.textContent=DATA.sousTitre;
  if(lsb) lsb.textContent=I18N[LANG].langSwitch;
  const now=new Date();
  const hd=document.getElementById('hdr-date');
  if(hd) hd.innerHTML=now.toLocaleDateString(
    LANG==='nl'?'nl-BE':LANG==='en'?'en-GB':'fr-BE',
    {weekday:'short',day:'numeric',month:'short'}
  ).replace(/^\w/,c=>c.toUpperCase())+'<br>'+
  now.toLocaleTimeString('fr-BE',{hour:'2-digit',minute:'2-digit'});
  renderNavGrid(); // ✅ AJOUTER CETTE LIGNE
}
```

---

### PROBLÈME 2 — Changement de langue en sous-menu ne recharge pas le contenu
**Fichier :** `index.html`
**Symptôme :** L'utilisateur est dans "Consignes" (FR), change la langue en NL → le titre de la topbar change mais le contenu reste en FR.
**Cause :** `changeLang()` cherche l'onglet actif via `document.getElementById('content-topbar-title')?.textContent` mais ce titre peut ne pas correspondre exactement à `tl(t.nom)` si la langue vient de changer.

```js
// CORRECTION — identifier l'onglet par data-attribute plutôt que par le texte :
// Dans openContent(), stocker l'id de l'onglet actif :
document.getElementById('content-screen').dataset.activeTab = tabId;

// Dans changeLang(), retrouver l'onglet par cet id :
function changeLang(lang){
  LANG=lang;
  localStorage.setItem('panneau_lang',lang);
  hideLangPicker();
  const lsb=document.getElementById('lang-switch-btn');
  if(lsb) lsb.textContent=I18N[lang].langSwitch;
  const ttl=document.getElementById('hdr-title');
  const sub=document.getElementById('hdr-subtitle');
  if(ttl) ttl.textContent=DATA.titre;
  if(sub) sub.textContent=DATA.sousTitre;

  const cs=document.getElementById('content-screen');
  if(cs && cs.style.display!=='none'){
    const activeTabId = cs.dataset.activeTab; // ✅ via data-attribute
    if(activeTabId) openContent(activeTabId);  // ✅ recharge tout
  } else {
    renderNavGrid();
  }
}
```

---

### PROBLÈME 3 — SortableJS drag & drop ne fonctionne pas dans admin.html
**Fichier :** `admin.html`
**Symptôme :** La poignée ⠿ ne permet pas de glisser les onglets. Les boutons ▲▼ fonctionnent mais le drag visuel est absent.
**Causes possibles à vérifier dans l'ordre :**

**3a. SortableJS non chargé (réseau)**
```js
// Ajouter dans initSortableTabs(), AVANT Sortable.create() :
if(typeof Sortable === 'undefined'){
  console.error('SortableJS non chargé. Vérifier la connexion réseau et le CDN.');
  // Les boutons ▲▼ restent disponibles comme fallback
  return;
}
console.log('SortableJS version:', Sortable.version);
```

**3b. L'élément `#tabs-config-list` n'existe pas encore quand initSortableTabs est appelé**
```js
// Vérifier dans initSortableTabs() :
const el = document.getElementById('tabs-config-list');
if(!el){
  console.error('tabs-config-list introuvable dans le DOM');
  return;
}
```

**3c. L'instance précédente n'est pas détruite avant recréation**
```js
// Pattern correct de destruction :
if(_sortableInstance){
  try{ _sortableInstance.destroy(); } catch(e){ console.warn('destroy failed:', e); }
  _sortableInstance = null;
}
```

**3d. Le handle `.drag-handle` ne correspond à aucun élément**
```js
// Dans la config Sortable, vérifier :
_sortableInstance = Sortable.create(el, {
  handle: '.drag-handle',  // doit matcher exactement la classe CSS
  animation: 180,
  onEnd: function(evt){
    console.log('Drag terminé:', evt.oldIndex, '→', evt.newIndex);
    // ...
  }
});
// Tester dans la console : document.querySelectorAll('.drag-handle').length
// Si 0 → la classe n'est pas appliquée dans loadTabsConfig()
```

---

### PROBLÈME 4 — Grille mobile : carte orpheline sur une ligne
**Fichier :** `index.html`
**Symptôme :** Selon le nombre d'onglets actifs, une carte se retrouve seule sur la dernière ligne.
**Cause :** Le calcul `lastNormalIdx` exclut les cartes FULL_TABS mais ne prend pas en compte que FULL_TABS elles-mêmes occupent une ligne entière dans la grille CSS `1fr 1fr`.

```js
// CORRECTION dans renderNavGrid() :
// Compter uniquement les cartes en grille 2 colonnes (non-full)
const active = DATA.tabs.filter(t=>t.active);
const forcedFull = active.filter(t => FULL_TABS.includes(t.id));
const normalCards = active.filter(t => !FULL_TABS.includes(t.id));

// Si nombre impair de cartes normales → la dernière devient full
const orphanId = (normalCards.length % 2 !== 0)
  ? normalCards[normalCards.length - 1]?.id
  : null;

// Dans le map :
const isFull = FULL_TABS.includes(tab.id) || tab.id === orphanId;
```

---

### PROBLÈME 5 — localStorage v4 écrase les données au rechargement si DEFAULT a changé
**Fichier :** `index.html` et `admin.html`
**Symptôme :** Après une mise à jour des fichiers, l'utilisateur voit toujours les anciennes données car localStorage a la priorité.
**Solution recommandée :** Versionner les données avec un numéro de schéma :

```js
const SCHEMA_VERSION = 4;

let DATA = (()=>{
  try{
    const stored = JSON.parse(localStorage.getItem('panneau_v4'));
    if(stored && stored._schemaVersion === SCHEMA_VERSION) return stored;
    // Version différente ou absente → réinitialiser
    console.log('Schéma mis à jour, réinitialisation des données');
    return JSON.parse(JSON.stringify(DEFAULT));
  } catch(e){
    return JSON.parse(JSON.stringify(DEFAULT));
  }
})();

// Dans saveAll(), ajouter le numéro de version :
DATA._schemaVersion = SCHEMA_VERSION;
localStorage.setItem('panneau_v4', JSON.stringify(DATA));
```

---

## 🔧 COMMANDES DE DÉBOGAGE — Console navigateur

Ouvrir DevTools (F12) et coller ces commandes pour diagnostiquer :

```js
// 1. Vérifier les données chargées
console.log('DATA:', JSON.parse(localStorage.getItem('panneau_v4')));
console.log('LANG:', localStorage.getItem('panneau_lang'));

// 2. Vérifier SortableJS dans admin.html
console.log('Sortable disponible:', typeof Sortable !== 'undefined');
if(typeof Sortable !== 'undefined') console.log('Version:', Sortable.version);

// 3. Vérifier les handles de drag
console.log('Handles trouvés:', document.querySelectorAll('.drag-handle').length);

// 4. Vérifier le tab actif en sous-menu (index.html)
console.log('Onglet actif:', document.getElementById('content-screen')?.dataset.activeTab);

// 5. Forcer le rechargement des données DEFAULT (efface localStorage)
localStorage.removeItem('panneau_v4');
location.reload();

// 6. Vérifier renderNavGrid
console.log('renderNavGrid:', typeof renderNavGrid);
renderNavGrid(); // Forcer le rendu

// 7. Tester changeLang manuellement
changeLang('nl'); // Doit recharger toute l'interface en NL

// 8. Inspecter les onglets actifs
DATA.tabs.filter(t=>t.active).forEach((t,i)=>console.log(i, t.id, tl(t.nom)));
```

---

## 📁 STRUCTURE DES FICHIERS À MODIFIER

```
/panneau-info/
├── index.html       ← Page publique (modifier renderAll, changeLang, renderNavGrid)
├── admin.html       ← Admin PC (modifier initSortableTabs, loadTabsConfig)
└── DEBUG_PROMPT.md  ← Ce fichier
```

---

## ✅ ORDRE DE CORRECTION RECOMMANDÉ

1. **`renderAll()` → ajouter `renderNavGrid()`** — 2 minutes, impact maximal
2. **`changeLang()` → utiliser `data-activeTab`** — 5 minutes
3. **`openContent()` → setter `dataset.activeTab`** — 1 minute
4. **SortableJS → ajouter logs de diagnostic** — tester dans DevTools
5. **Schéma version** — pour les prochaines mises à jour

---

*Généré automatiquement par Claude — Projet Panneau d'information ELU / Camp Adjudant Brasseur*
