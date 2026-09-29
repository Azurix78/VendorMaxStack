# Validation

## Automatique

Résultats du 29 septembre 2026 : **52 scénarios Lua réussis**, syntaxe Lua 5.1 vérifiée sur les quatre fichiers de l’addon et le harness ; **42 vérifications PowerShell/distribution réussies**. Les scénarios Lua ont été exécutés avec Fengari 0.1.5 et luaparse 0.3.1 dans le moteur Node disponible pour le développement. Une simulation `-WhatIf` a également validé le chemin du jeu demandé sans y copier de fichiers.

`npm test` vérifie la syntaxe Lua 5.1, les calculs, les sacs spécialisés, les limites uniques, les callbacks réels de l’interface avec API simulées et les traductions. Le harness charge les fichiers dans l’ordre du TOC. Les confirmations Blizzard sont simulées : leur rendu et leur comportement sur Forever doivent être vérifiés en jeu.

`powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Packaging.Tests.ps1` vérifie la syntaxe PowerShell, l’installation, une mise à jour, le mode `-WhatIf`, les erreurs et le contenu du ZIP dans un dossier temporaire du projet.

L’élévation UAC est prévue dans l’installateur, mais elle n’est pas déclenchée par les tests automatiques.

## À vérifier en jeu — non exécuté

Client installé repéré lors de la préparation : **1.60.1.70009**, interface **16001**. Aucun achat réel n’a été effectué par les tests de développement.

1. Installer l’addon, redémarrer WoW et confirmer qu’il apparaît et se charge dans la liste des addons.
2. Ouvrir un marchand de boissons. Vérifier le bouton ×20 à droite, sans chevauchement avec le prix ou le nom, à plusieurs échelles d’interface. Survoler pour lire le nom complet et le prix total.
3. Pour un objet vendu par lots de 5, noter argent et quantité, cliquer ×20 et confirmer le gain de 20 unités et le débit de quatre lots au tarif affiché.
4. Refaire avec une pile déjà entamée : le gain doit rester de 20, quitte à se répartir entre plusieurs emplacements.
5. Vérifier manque d’argent, stock limité et sacs pleins : bouton grisé et motif lisible, aucun achat partiel. Tester un sac spécialisé compatible puis incompatible.
6. Changer de page, de marchand, ouvrir Rachat, fermer puis rouvrir la fenêtre. Vérifier que chaque bouton correspond à son objet et que la largeur des noms est restaurée sur les lignes sans bouton.
7. Vérifier les objets à monnaies spéciales et non empilables : aucun bouton. Vérifier un objet à limite unique.
8. Vérifier les confirmations applicables aux achats coûteux/non remboursables, leur quantité et leur prix. Annuler puis changer de page pendant une confirmation : aucun achat involontaire.
9. Consulter BugSack/BugGrabber et vérifier l’absence d’erreurs Lua ou de blocage d’action/taint. Vérifier la fenêtre marchand déplacée par BlizzMove si utilisé.
10. Vérifier les traductions longues et les polices asiatiques dans les clients disponibles. Toutes les langues sont fournies ; **aucun rendu de langue n’est actuellement marqué comme validé**.

Les messages du jeu restent l’autorité finale en cas de stock ou de place modifiés entre le clic et la réponse serveur. L’addon n’effectue jamais de nouvelle tentative automatique.

## Références techniques

- [Interface marchand Blizzard (miroir du code source)](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/MerchantFrame.lua) : quantités explicites, prix par lot, hooks et confirmations.
- [API C_MerchantFrame](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/MerchantFrameDocumentation.lua).
- [API C_Item](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua).

Ces références concernent le client moderne et ne constituent pas une validation de bout en bout du client Forever installé.
