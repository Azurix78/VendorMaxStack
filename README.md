# VendorMaxStack

An addon for **WoW Forever 1.60.1 / interface 16001**, by **Syntaxucre**.

A **×N** button on each eligible merchant row buys one full stack. For example, **×20 buys 20 items**, even when the merchant sells bundles of five. Items you already own do not reduce the purchase amount.

## One-click installation on Windows

Double-click **Installer-Addon.cmd**, keeping the project files alongside it. The addon will be copied to:

```text
C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\VendorMaxStack
```

If Windows denies access, the script requests administrator privileges. Accept the prompt to complete installation. Restart WoW after the first installation. To update an already loaded addon, run the installer again, then type `/reload` in game.

The script verifies the copied files, preserves other addons and leaves game-folder permissions unchanged. Extra files in an existing VendorMaxStack folder are not deleted. Installer messages are in French.

Use a different destination or preview installation without copying files:

```powershell
.\Install-Addon.ps1 -AddOnsPath 'D:\Games\World of Warcraft\_classic_beta_\Interface\AddOns'
.\Install-Addon.ps1 -WhatIf
```

## Usage

Open a merchant and click **×N**. Hover over the button to see the quantity, total price and any reason the purchase is unavailable. The button is disabled when money, stock, bag space or an item limit prevents buying a full stack. It never substitutes a smaller purchase or automatically retries a failed one.

Non-stackable items and purchases requiring special currencies are excluded. The Buyback tab and standard item-icon clicks remain available. Items with shared unique limits use the standard purchase button, because the owned count of a single item cannot establish the remaining allowance. Specialty bags are checked for compatibility; bank slots do not count as available bag space.

All addon text follows the client language: English, French, German, Spanish (Spain and Latin America), Italian, Brazilian Portuguese, Russian, Korean, Simplified Chinese and Traditional Chinese. English is the fallback. No configuration or other addons are required.

## Distribution and development

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Build-Release.ps1
npm install
npm test
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Packaging.Tests.ps1
```

The release ZIP is `dist/VendorMaxStack-1.0.0.zip`. It contains the installable addon folder and its documentation, excluding Windows scripts, tests and development dependencies. The builder reads the version from the TOC. Install this ZIP with an addon manager or extract it manually.

- [Player guide](VendorMaxStack/README.md)
- [CurseForge descriptions and publishing guide (French)](docs/PUBLISHING.fr.md)
- [In-game validation checklist (French)](docs/VALIDATION.fr.md)
- [Changelog](CHANGELOG.md) · [MIT license](LICENSE)

Automated checks cover Lua 5.1 syntax, simulated purchases, translations and packaging. **Layout, actual purchases, confirmation dialogs and the absence of taint still require validation in the Forever client.** Automated tests do not replace this step, and compatibility with other WoW editions is not claimed.
