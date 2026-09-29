# VendorMaxStack

Addon **WoW Forever 1.60.1 / interface 16001**, par **Syntaxucre**.

Un bouton **×N** sur les lignes du marchand achète une pile complète. Par exemple, **×20 achète 20 objets**, même s’ils sont vendus par lots de 5. Les piles déjà possédées ne réduisent pas la quantité achetée.

## Installer en un clic sous Windows

Double-cliquez sur **Installer-Addon.cmd** en conservant les fichiers du projet à côté. L’addon sera copié dans :

```text
C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\VendorMaxStack
```

Si Windows refuse la copie, le script ouvre une demande de droits administrateur. Acceptez-la pour terminer l’installation. Une première installation nécessite de redémarrer WoW. Pour mettre à jour un addon déjà chargé, relancez le script puis tapez `/reload`.

Le script vérifie les fichiers copiés, conserve les autres addons et ne modifie pas les permissions du dossier du jeu. Les fichiers supplémentaires éventuellement présents dans un ancien dossier VendorMaxStack ne sont pas supprimés.

Autre dossier ou simulation sans copie :

```powershell
.\Install-Addon.ps1 -AddOnsPath 'D:\Jeux\World of Warcraft\_classic_beta_\Interface\AddOns'
.\Install-Addon.ps1 -WhatIf
```

## Utilisation

Ouvrez un marchand et cliquez sur **×N**. Survolez le bouton pour voir la quantité, le prix total et la raison d’une indisponibilité. Il reste grisé si une pile complète ne peut pas être achetée : argent, stock, place dans les sacs ou limite de l’objet. Aucun achat réduit ni nouvelle tentative automatique n’est effectué.

Les objets non empilables et les achats avec monnaies spéciales sont exclus. L’onglet Rachat et les clics habituels sur les icônes restent disponibles. Les limites uniques partagées entre plusieurs objets utilisent l’achat habituel, car le nombre possédé d’un seul objet ne suffit pas à les vérifier. Les sacs spécialisés sont pris en compte selon leur type ; les places de banque ne comptent pas comme espace disponible.

Tous les textes de l’addon suivent la langue du client : anglais, français, allemand, espagnol européen et latino-américain, italien, portugais brésilien, russe, coréen, chinois simplifié et traditionnel. L’anglais sert de secours. Aucun réglage ni autre addon requis.

## Distribution et développement

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Build-Release.ps1
npm install
npm test
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Packaging.Tests.ps1
```

Le ZIP public est `dist/VendorMaxStack-1.0.0.zip`. Il contient uniquement le dossier installable et sa documentation, sans les scripts Windows, tests ou dépendances de développement. Le générateur lit la version du TOC. Un gestionnaire d’addons ou une extraction manuelle peut installer ce ZIP.

- [Guide joueur anglais](VendorMaxStack/README.md)
- [Description et dépôt CurseForge](docs/PUBLISHING.fr.md)
- [Vérifications en jeu](docs/VALIDATION.fr.md)
- [Changelog](CHANGELOG.md) · [Licence MIT](LICENSE)

La syntaxe Lua 5.1, les achats simulés, les traductions et la distribution sont vérifiables automatiquement. **Le rendu, les achats réels, les confirmations et l’absence de taint nécessitent encore une validation dans le client Forever.** Aucun test automatisé ne remplace cette étape, et les autres éditions de WoW ne sont pas annoncées compatibles.
