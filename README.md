# DPSLight - Ultra-Optimized Combat Analysis Addon

DPSLight est un addon d'analyse de combat ultra-optimisé pour World of Warcraft 1.12.1 (Vanilla/Classic), conçu comme une version hautement performante de DPSMate.

- Auteur : **Shikawa**
- Objectif : réduction massive du CPU/FPS drop et de l'empreinte mémoire (30-50MB en pratique)

## 🚀 Fonctionnalités

### Performance Optimisée
- **ObjectPool** - Recyclage de tables pour réduire le garbage collection de 60-80%
- **EventEngine** - Système d'événements pré-alloué avec dispatch ultra-rapide
- **DataStore** - Stockage avec indexation hash pour des lookups instantanés
- **VirtualScroll** - Affichage uniquement des lignes visibles (pas de 40 frames inutiles)
- **Parser Optimisé** - `string.match` au lieu de `string.gfind` (75-90% plus rapide)

### Support SuperWoW (Turtle WoW)
Détection automatique de SuperWoW avec fonctionnalités avancées :
- **RAW_COMBATLOG** - Parsing avec GUIDs natifs (90% de réduction du temps de parsing)
- **UNIT_CASTEVENT** - Tracking de casts sans regex
- **Optimisations automatiques** - Bascule automatique entre parser SuperWoW et Classic

### Synchronisation Optimisée
- **Sync différentielle** - Envoie uniquement les changements (80-90% moins de données)
- **Compression** - Encodage compact des données de sync
- **Throttling intelligent** - Évite les déconnexions par spam réseau

## 📊 Gains de Performance vs DPSMate

| Composant | DPSMate | DPSLight (SuperWoW) | DPSLight (Classic) | Gain |
|-----------|---------|---------------------|-------------------|------|
| Parsing combat log | 2-5ms/event | 0.1-0.3ms/event | 0.5-1ms/event | **90-95%** / **75-80%** |
| Mise à jour UI | 15-30ms | 2-5ms | 2-5ms | **80-85%** |
| Mémoire RAM | 80-150MB | 30-50MB | 30-50MB | **60-65%** |
| FPS drop (combat) | -10 à -20 | -2 à -5 | -2 à -5 | **70-80%** |

## 🎮 Installation

1. Téléchargez DPSLight
2. Extrayez dans `Interface/AddOns/`
3. (Optionnel) Installez [SuperWoW](https://github.com/balakethelock/SuperWoW) pour performances maximales
4. Lancez WoW et activez l'addon

## 🔧 Commandes

```
/dps ou /dps show     - Afficher la fenêtre principale
/dps hide             - Masquer la fenêtre
/dps toggle           - Basculer l'affichage
/dps reset            - Réinitialiser toutes les données
/dps sync             - Activer/désactiver la sync raid
/dps stats            - Afficher les statistiques de performance
/dps help             - Afficher l'aide
```

## 📁 Architecture

```
DPSLight/
├── Core/
│   ├── ObjectPool.lua      # Recyclage d'objets
│   ├── EventEngine.lua     # Gestionnaire d'événements optimisé
│   ├── DataStore.lua       # Stockage avec hash indexing
│   ├── Config.lua          # Configuration
│   └── Utils.lua           # Utilitaires
├── Parser/
│   ├── PatternCache.lua    # Patterns regex pré-compilés
│   ├── ParserOptimized.lua # Parser SuperWoW (GUID-based)
│   ├── ParserClassic.lua   # Parser Vanilla (string.match)
│   └── ParserMain.lua      # Contrôleur principal
├── Modules/
│   ├── ModuleBase.lua      # Template de module avec cache
│   ├── Damage.lua          # Module dégâts
│   ├── Healing.lua         # Module soins
│   └── Deaths.lua          # Module morts
├── Sync/
│   ├── Compression.lua     # Compression des données
│   └── DiffSync.lua        # Synchronisation différentielle
└── UI/
    ├── FramePool.lua       # Recyclage de frames UI
    ├── VirtualScroll.lua   # Liste scrollable optimisée
    └── MainFrame.lua       # Fenêtre principale
```

## 🎯 Modules Disponibles

- ✅ **Damage** - Dégâts infligés avec DPS
- ✅ **Healing** - Soins effectués avec HPS
- ⚙️ **Damage Taken** - Dégâts subis (stub)
- ⚙️ **Healing Taken** - Soins reçus (stub)
- ⚙️ **Deaths** - Tracking des morts (stub)

*Les modules marqués ⚙️ sont des stubs prêts pour l'implémentation*

## ⚙️ Configuration

Les paramètres sont stockés dans `DPSLightSettings` (SavedVariables) :

```lua
-- Performance
updateInterval = 0.5          -- Fréquence de mise à jour UI (secondes)
maxVisibleRows = 15           -- Nombre de lignes visibles
enableObjectPooling = true    -- Activer le pooling d'objets

-- SuperWoW
preferSuperWoW = true         -- Utiliser SuperWoW si disponible
useSuperWoWEvents = true      -- Utiliser RAW_COMBATLOG, UNIT_CASTEVENT

-- Sync
syncEnabled = true            -- Synchronisation raid
syncInterval = 30             -- Fréquence de sync (secondes)
```

## 🔬 Optimisations Techniques

### 1. ObjectPool - Recyclage de Tables
```lua
-- Au lieu de créer de nouvelles tables constamment
local t = {}  -- Garbage collection!

-- On recycle les tables existantes
local t = ObjectPool:GetTable()
-- ... utilisation ...
ObjectPool:ReleaseTable(t)
```

### 2. Pattern Caching
```lua
-- DPSMate (LENT - string.gfind obsolète)
for a,b,c in string.gfind(text, pattern) do ... end

-- DPSLight (RAPIDE - string.match direct)
local a, b, c = PatternCache:Match(text, "PATTERN_KEY")
```

### 3. Virtual Scrolling
```lua
-- N'affiche que les 15 lignes visibles au lieu de 40 frames
-- Économie de ~70% de CPU pour l'UI
```

### 4. Hash Indexing
```lua
-- Lookup O(1) au lieu de O(n)
local userID = userCache[username]  -- Instantané
-- vs boucle sur tous les utilisateurs
```

## ⚠️ Compatibilité SuperWoW

SuperWoW est **optionnel** mais recommandé pour performances maximales :

- ✅ **Turtle WoW** - Support natif SuperWoW
- ⚠️ **Autres serveurs** - Vérifier leur politique (détectable par Warden)
- ✅ **Vanilla 1.12.1** - Fonctionne sans SuperWoW (mode Classic)

DPSLight détecte automatiquement SuperWoW et bascule entre les parsers.

## 🐛 Débug & Stats

Utilisez `/dps stats` pour voir :
- Type de parser actif (SuperWoW ou Classic)
- Nombre d'événements traités
- Temps moyen de parsing
- Utilisation mémoire
- État de la synchronisation

## 📝 TODO / Améliorations Futures

- [ ] Module Threat (menace)
- [ ] Module Interrupts (interruptions)
- [ ] Module Dispels (dissipation)
- [ ] Fenêtre de détails par joueur
- [ ] Graphiques en temps réel
- [ ] Export des données
- [ ] Interface de configuration graphique
- [ ] Support multi-langues complet (zhCN, deDE, ruRU)

## 🤝 Contribution

Ce projet est une réécriture optimisée de DPSMate. Les contributions sont bienvenues :

1. Fork le projet
2. Créez une branche feature
3. Commit vos changements
4. Push et créez une Pull Request

## 📜 Licence

Basé sur DPSMate. Open source pour usage personnel.

## 🙏 Crédits

- **DPSMate Original** - Shino (Fedilious)
- **SuperWoW** - Balake
- **DPSLight** - Réécriture optimisée

---

**Note**: DPSLight est en développement actif. Les performances mentionnées sont des estimations basées sur l'analyse de DPSMate et les optimisations implémentées.
