local _, addon = ...
local API, Logic, L = addon.API, addon.Logic, addon.L
local buttons, session, pending = {}, 0, nil
local initialized, queued = false, false
local events = CreateFrame("Frame")

local function OwnsPending()
    return pending and StaticPopup_Visible(pending.dialog)
        and MerchantFrame.itemIndex == pending.offer.index and MerchantFrame.count == pending.offer.quantity
end

local function CancelPending()
    if pending then
        if OwnsPending() then StaticPopup_Hide(pending.dialog) end
        pending = nil
    end
end

local function Tooltip(button)
    local result = button.result
    if not result then return end
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText(result.item and result.item.name or "VendorMaxStack", 1, 1, 1)
    if result.quantity then
        GameTooltip:AddLine(string.format(L.Buy, result.quantity), 1, 0.82, 0, true)
    end
    if result.total then
        GameTooltip:AddLine(string.format(L.Price, GetMoneyString(result.total)), 1, 1, 1, true)
    end
    if result.reason then GameTooltip:AddLine(L[result.reason], 1, 0.3, 0.3, true) end
    GameTooltip:Show()
end

local function HideButton(button)
    button:Hide()
    button.offer, button.result = nil, nil
    if button.nameText and button.originalNameWidth then button.nameText:SetWidth(button.originalNameWidth) end
    if GameTooltip:IsOwned(button) then GameTooltip:Hide() end
end

local function HideAll()
    for _, button in ipairs(buttons) do HideButton(button) end
end

local Refresh
local function Click(button)
    if not button.offer or not MerchantFrame:IsShown() or MerchantFrame.selectedTab ~= 1 then return end
    -- Native confirmations share MerchantFrame fields. Do not overwrite another purchase.
    for _, dialog in ipairs({ "CONFIRM_HIGH_COST_ITEM", "CONFIRM_PURCHASE_NONREFUNDABLE_ITEM",
        "CONFIRM_PURCHASE_TOKEN_ITEM", "CONFIRM_PURCHASE_ITEM_DELAYED", "CONFIRM_MERCHANT_TRADE_TIMER_REMOVAL" }) do
        if StaticPopup_Visible(dialog) then return end
    end
    local index = button.native:GetID()
    local result = API.Evaluate(index, API.ReadBags())
    local offer = API.Snapshot(index, result, session)
    if not result.enabled or not Logic.SameOffer(button.offer, offer) then
        Refresh()
        return
    end
    local dialog, reason = API.Buy(index, result, button.native)
    if dialog and StaticPopup_Visible(dialog) then pending = { dialog = dialog, offer = offer } end
    if reason then
        button.result.reason = reason
        button:Disable()
        Tooltip(button)
    else
        Refresh()
    end
end

local function GetButton(i)
    if buttons[i] then return buttons[i] end
    local row = _G["MerchantItem" .. i]
    local native = row and (row.ItemButton or _G["MerchantItem" .. i .. "ItemButton"])
    if not row or not native then return nil end
    local button = CreateFrame("Button", "VendorMaxStackButton" .. i, row, "UIPanelButtonTemplate")
    button:SetSize(36, 18)
    button:SetPoint("TOPRIGHT", row, "TOPRIGHT", -1, 0)
    button:SetNormalFontObject(GameFontNormalSmall)
    button:SetHighlightFontObject(GameFontHighlightSmall)
    button:SetDisabledFontObject(GameFontDisableSmall)
    button:SetMotionScriptsWhileDisabled(true)
    button:RegisterForClicks("LeftButtonUp")
    button.native = native
    button.nameText = row.Name or _G["MerchantItem" .. i .. "Name"]
    button.originalNameWidth = button.nameText and button.nameText:GetWidth()
    button:SetScript("OnClick", Click)
    button:SetScript("OnEnter", Tooltip)
    button:SetScript("OnLeave", function(self) if GameTooltip:IsOwned(self) then GameTooltip:Hide() end end)
    button:SetScript("OnHide", function(self) if GameTooltip:IsOwned(self) then GameTooltip:Hide() end end)
    buttons[i] = button
    return button
end

Refresh = function()
    if not initialized then return end
    if not MerchantFrame:IsShown() or MerchantFrame.selectedTab ~= 1 then
        CancelPending()
        HideAll()
        return
    end
    local bags = API.ReadBags()
    if pending then
        local result = API.Evaluate(pending.offer.index, bags)
        if not OwnsPending() then
            pending = nil
        elseif not result.enabled or not Logic.SameOffer(pending.offer, API.Snapshot(pending.offer.index, result, session)) then
            CancelPending()
        end
    end
    local perPage = MERCHANT_ITEMS_PER_PAGE or 10
    for i = 1, perPage do
        local button = GetButton(i)
        if button then
            local index = ((MerchantFrame.page or 1) - 1) * perPage + i
            if index <= GetMerchantNumItems() and button.native:GetID() == index then
                local result = API.Evaluate(index, bags)
                if result.visible then
                    button.result = result
                    button.offer = API.Snapshot(index, result, session)
                    button:SetText(result.quantity and ("×" .. result.quantity) or "…")
                    local width = math.max(36, button:GetFontString():GetStringWidth() + 12)
                    button:SetWidth(width)
                    if button.nameText then
                        button.nameText:SetWidth(math.max(30, button.originalNameWidth - width - 3))
                    end
                    button:SetEnabled(result.enabled)
                    button:Show()
                    if GameTooltip:IsOwned(button) then Tooltip(button) end
                else
                    HideButton(button)
                end
            else
                HideButton(button)
            end
        end
    end
end

local function Initialize()
    if initialized or not MerchantFrame or not MerchantFrame_Update then return end
    initialized = true
    hooksecurefunc("MerchantFrame_Update", Refresh)
    MerchantFrame:HookScript("OnHide", function() CancelPending(); HideAll() end)
    MerchantFrame:HookScript("OnShow", Refresh)
end

local function ScheduleRefresh()
    if queued then return end
    queued = true
    C_Timer.After(0, function() queued = false; Refresh() end)
end

events:SetScript("OnEvent", function(_, event)
    if event == "ADDON_LOADED" or event == "PLAYER_LOGIN" then
        Initialize()
    elseif event == "MERCHANT_CLOSED" then
        session = session + 1
        CancelPending()
        HideAll()
    elseif event == "MERCHANT_SHOW" then
        session = session + 1
        CancelPending()
        Initialize()
        ScheduleRefresh()
    elseif initialized and MerchantFrame:IsShown() then
        ScheduleRefresh()
    end
end)
for _, event in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "MERCHANT_SHOW", "MERCHANT_CLOSED",
    "MERCHANT_UPDATE", "MERCHANT_FILTER_ITEM_UPDATE", "PLAYER_MONEY", "BAG_UPDATE_DELAYED",
    "ITEM_LOCK_CHANGED", "GET_ITEM_INFO_RECEIVED", "UI_ERROR_MESSAGE" }) do
    events:RegisterEvent(event)
end
Initialize()
