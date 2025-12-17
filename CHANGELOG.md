# DPSLight Changelog

## Version 1.1 - Performance & UI Update

### Améliorations majeures

#### Performance
- **Cache de classes optimisé** : Les classes des joueurs sont maintenant mises en cache pour éviter les erreurs "Unknown unit name"
- **Scan intelligent** : Mise à jour automatique du cache toutes les 2 secondes seulement
- **Réduction des messages de debug** : Suppression de tous les messages inutiles qui polluaient le chat

#### Interface utilisateur
- **Redimensionnement intelligent** : La fenêtre se redimensionne automatiquement avec contraintes minimales (350x300)
- **Auto-reflow** : Tous les éléments se repositionnent automatiquement lors du redimensionnement
- **Footer amélioré** : Affiche maintenant les statistiques de performance en temps réel
  - Temps de combat
  - FPS actuel
  - Latence réseau
  - Usage mémoire de l'addon

#### Corrections de bugs
- Correction des erreurs "Unknown unit name" lors de la détection de classes
- Meilleure gestion des couleurs de classes pour tous les joueurs du raid/groupe
- Calculs DPS/HPS corrigés quand la durée de combat est 0

### Commandes disponibles
- `/dps show` - Afficher la fenêtre
- `/dps hide` - Masquer la fenêtre
- `/dps test` - Générer des données de test
- `/dps debug` - Mode debug pour diagnostic
- `/dps stats` - Afficher les statistiques du parser

### Utilisation
1. L'addon démarre automatiquement au chargement du jeu
2. Utilisez `/dps show` pour afficher la fenêtre
3. Cliquez sur les onglets Damage/Healing/Deaths pour changer de vue
4. Redimensionnez la fenêtre en glissant le coin inférieur droit
5. Les statistiques de performance sont visibles en bas de la fenêtre

### Optimisations techniques
- Système de pooling d'objets pour réduire le garbage collection
- Parser Classic optimisé avec cache de patterns
- Stockage de données avec hash index pour accès O(1)
- Virtual scrolling pour afficher des milliers d'entrées sans lag
