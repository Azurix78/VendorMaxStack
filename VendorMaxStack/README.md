# VendorMaxStack

Buy one full stack with a single click at a merchant in **World of Warcraft: Forever**.

Each eligible item gets a small **×N** button. **×20 buys 20 individual items**, even when the merchant sells bundles of five. Hover over the button to see the full price. Items you already own do not reduce the purchase amount; WoW can merge the new items into existing stacks.

The button is disabled when a full stack cannot be purchased: insufficient money, stock, bag space or a unique item limit. It never silently buys a smaller amount or retries an unsuccessful purchase. Shared unique-limit categories use the standard purchase button. Unknown item data is loaded before the button becomes available.

Only stackable items bought with gold, silver or copper are supported. Items requiring tokens or other currencies and the Buyback tab do not get a button. Standard merchant clicks and applicable Blizzard confirmations remain available. No setup or dependencies required.

## Installation

Extract the release ZIP into your Forever client's `Interface/AddOns` directory. The final path must be `Interface/AddOns/VendorMaxStack/VendorMaxStack.toc`. Restart WoW after first installation and enable the addon. For an update of an already loaded addon, use `/reload`.

The Windows one-click installer is available in the source project; it is not needed for CurseForge or manual ZIP installation.

## Languages

All addon text is included for English (US/UK), French, German, Spanish (Spain/Latin America), Italian, Brazilian Portuguese, Russian, Korean, Simplified Chinese and Traditional Chinese. The client language is selected automatically, with English fallback.

## Compatibility and feedback

Targets **Forever 1.60.1 / interface 16001**, using Blizzard's merchant UI. Replacement merchant interfaces and other WoW editions are not supported. In-game validation of this initial version is pending; automated checks cover the purchase logic and simulated UI interactions. Translations have not been reviewed in every language's client.

For bug reports, include the addon version, `/dump GetBuildInfo()` output, client language, merchant/item name, reproduction steps and any Lua error. Author: **Syntaxucre**. License: **MIT**.
