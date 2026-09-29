local _, addon = ...
local API = {}
addon.API = API
local Logic = addon.Logic

local function ItemFunction(name)
    return C_Item and C_Item[name] or _G[name]
end

function API.ReadItem(index)
    local info
    if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
        info = C_MerchantFrame.GetItemInfo(index)
    elseif GetMerchantItemInfo then
        local name, texture, price, bundle, available, purchasable, usable, extended = GetMerchantItemInfo(index)
        if name then
            info = { name = name, texture = texture, price = price, stackCount = bundle,
                numAvailable = available, isUsable = usable, isPurchasable = purchasable, hasExtendedCost = extended }
        end
    end
    if not info then return nil end
    local link = GetMerchantItemLink(index)
    local item = { index = index, name = info.name, link = link, texture = info.texture,
        price = info.price, bundle = info.stackCount, available = info.numAvailable,
        purchasable = info.isPurchasable, extendedCost = info.hasExtendedCost,
        currency = info.currencyID or info.spellID, owned = 0 }
    if not link then return item end
    local getInfo = ItemFunction("GetItemInfo")
    if not getInfo then return item end
    item.maxStack = select(8, getInfo(link))
    local getFamily = ItemFunction("GetItemFamily")
    item.family = getFamily and getFamily(link)
    local getCount = ItemFunction("GetItemCount")
    item.owned = getCount and getCount(link, true) or 0
    local getUnique = ItemFunction("GetItemUniquenessByID")
    if getUnique then
        local isUnique, _, categoryCount, categoryID = getUnique(link)
        -- Shared/equipped-only categories cannot be safely inferred from this item's count.
        -- Leave these rare purchases to Blizzard's standard item button.
        if categoryID and categoryID > 0 then
            item.uniqueBlocked = true
        elseif isUnique then
            item.uniqueLimit = categoryCount and categoryCount > 0 and categoryCount or 1
        end
    end
    return item
end

function API.ReadBags()
    if not C_Container or not C_Container.GetContainerNumSlots or not C_Container.GetContainerNumFreeSlots then
        return nil
    end
    local bags = {}
    -- Backpack and equipped bags only, never bank/account-bank slots.
    local lastBag = NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4
    for bagID = 0, lastBag do
        local size = C_Container.GetContainerNumSlots(bagID)
        if size and size > 0 then
            local _, family = C_Container.GetContainerNumFreeSlots(bagID)
            local bag = { family = family, slots = {} }
            for slotID = 1, size do
                local slot = C_Container.GetContainerItemInfo(bagID, slotID)
                if slot then
                    bag.slots[#bag.slots + 1] = { count = slot.stackCount or 0,
                        link = slot.hyperlink or C_Container.GetContainerItemLink(bagID, slotID), locked = slot.isLocked }
                else
                    bag.slots[#bag.slots + 1] = { empty = true }
                end
            end
            bags[#bags + 1] = bag
        end
    end
    return bags
end

function API.Evaluate(index, bags)
    local item = API.ReadItem(index)
    local capacity
    if item and bags then capacity = Logic.Capacity(item, bags, bit and bit.band) end
    return Logic.Evaluate(item, GetMoney(), capacity)
end

function API.Snapshot(index, result, session)
    return { index = index, link = result.item and result.item.link, quantity = result.quantity,
        total = result.total, page = MerchantFrame.page, merchant = UnitGUID("npc"), session = session }
end

function API.Buy(index, result, nativeButton)
    local item = result.item
    local highCost = result.total >= (MERCHANT_HIGH_PRICE_COST or 1500000)
    if nativeButton.showNonrefundablePrompt and MerchantFrame_ConfirmExtendedItemCost then
        -- A separate data object avoids changing the native row's price/count.
        local proxy = { price = result.total, count = result.quantity, name = item.name,
            link = item.link, texture = item.texture, showNonrefundablePrompt = true,
            GetID = function() return index end }
        MerchantFrame_ConfirmExtendedItemCost(proxy, result.quantity)
        return "CONFIRM_PURCHASE_NONREFUNDABLE_ITEM"
    elseif highCost and MerchantFrame_ConfirmHighCostItem then
        local proxy = { price = item.price / item.bundle, link = item.link,
            GetID = function() return index end }
        MerchantFrame_ConfirmHighCostItem(proxy, result.quantity)
        return "CONFIRM_HIGH_COST_ITEM"
    elseif highCost or nativeButton.showNonrefundablePrompt then
        return nil, "Unavailable"
    else
        BuyMerchantItem(index, result.quantity)
    end
end
