# Préparer la publication sur CurseForge

## Archive

Lancer `powershell -NoProfile -ExecutionPolicy Bypass -File .\Build-Release.ps1` et déposer **dist/VendorMaxStack-1.0.0.zip**. Le ZIP contient un unique dossier `VendorMaxStack/`, avec son TOC, les quatre fichiers Lua, le guide joueur, le changelog et la licence. Les scripts Windows et les tests ne sont pas distribués dans ce ZIP.

Cette structure suit les [indications officielles CurseForge pour les addons WoW](https://support.curseforge.com/support/solutions/articles/9000196615-known-issues?locale=ru). Voir aussi le [guide de création et de dépôt](https://support.curseforge.com/support/solutions/articles/9000197241?locale=fr).

## Fiche proposée

- Nom : **VendorMaxStack**.
- Auteur : **Syntaxucre**.
- Licence : **MIT**.
- Jeu : **World of Warcraft** ; sélectionner **Forever / 1.60.1** dans les choix proposés, sans annoncer d’autres éditions.
- Catégorie suggérée : **Bags & Inventory** ; choisir **Miscellaneous** si aucune catégorie marchands/inventaire n’est proposée.
- Résumé anglais : **Buy one full stack with a single click at merchants in WoW Forever.**
- Résumé français : **Achetez une pile complète en un clic chez les marchands de WoW Forever.**
- Type initial : **Beta**, jusqu’à validation en jeu. Mettre à jour la documentation de validation avant une version Release.
- Changelog : section 1.0.0 de `CHANGELOG.md`.
- Icône, captures en jeu et destination des rapports de bugs : à ajouter au moment de créer le projet CurseForge.

## Description anglaise

**VendorMaxStack adds a small ×N button to Blizzard's merchant window in WoW Forever.**

Click once to buy a full stack of food, drinks, reagents or other stackable items paid for with gold, silver or copper. A ×20 button buys 20 items, including when the merchant sells bundles of five.

Hover to see the total price. The button is disabled when you lack money, stock, bag space or an applicable item allowance. It never substitutes a smaller purchase. Unique category limits use the standard merchant purchase.

No configuration or dependencies. All WoW client languages are included, with automatic language selection and English fallback. Tokens, special currencies and replacement merchant interfaces are outside this version's support.

**Compatibility:** Forever 1.60.1 / interface 16001. This initial beta has automated tests; in-game validation and translation review in every client language are still pending.

## Description française

**VendorMaxStack ajoute un petit bouton ×N dans la fenêtre marchand de Blizzard sur WoW Forever.**

Achetez en un clic une pile complète de nourriture, boissons, composants ou autres objets empilables payables en or, argent ou cuivre. Un bouton ×20 achète 20 objets, même lorsque le marchand les vend par lots de 5.

L’infobulle affiche le prix total. Le bouton reste grisé si votre argent, le stock, la place dans les sacs ou la limite de l’objet ne permettent pas l’achat complet. Il n’achète jamais une quantité réduite à votre place. Les limites uniques partagées utilisent l’achat habituel.

Aucun réglage ni dépendance. Tous les textes de l’addon sont traduits dans les langues de WoW, sélectionnées automatiquement avec l’anglais en secours. Les monnaies spéciales et les interfaces marchands de remplacement ne sont pas prises en charge.

**Compatibilité :** Forever 1.60.1 / interface 16001. Cette première bêta dispose de tests automatisés ; la validation en jeu et la relecture dans chaque langue restent à effectuer.

## Avant de déposer

Suivre la [fiche de validation](VALIDATION.fr.md), ajouter des captures réelles et vérifier les options proposées par CurseForge au moment du dépôt. Le projet et son archive sont préparés localement ; aucune publication n’est effectuée par les scripts.
