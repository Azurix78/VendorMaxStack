local passed = 0
local function eq(actual, expected, label)
    if actual ~= expected then error((label or "assertion") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2) end
end
local function test(name, fn)
    local ok, message = pcall(fn)
    if not ok then error("FAIL " .. name .. ": " .. tostring(message), 0) end
    passed = passed + 1
    print("PASS " .. name)
end
local function Load(name, addon)
    local source = TEST_FILES[name]
    assert(source, name)
    return assert((loadstring or load)(source, "@" .. name))("VendorMaxStack", addon)
end
local function link(id, suffix, level)
    return "|cffffffff|Hitem:" .. (id or 117) .. ":0:0:0:0:0:" .. (suffix or 0) .. ":0:" .. (level or 1) .. "|h[Item]|h|r"
end
local function validItem()
    return { link = link(), maxStack = 20, bundle = 5, price = 125, available = -1,
        family = 0, owned = 0, purchasable = true }
end
local addon = {}
Load("Logic.lua", addon)
local L = addon.Logic

test("20 units from bundles of five cost four bundle prices", function()
    local r = L.Evaluate(validItem(), 500, 20)
    eq(r.enabled, true); eq(r.quantity, 20); eq(r.total, 500)
end)
test("money short by one copper blocks the entire purchase", function() eq(L.Evaluate(validItem(), 499, 20).reason, "Money") end)
test("partial stock never buys a smaller quantity", function()
    local item = validItem(); item.available = 19
    eq(L.Evaluate(item, 500, 20).reason, "Stock")
end)
test("stock is measured in units, not merchant bundles", function()
    local item = validItem(); item.available = 20
    eq(L.Evaluate(item, 500, 20).enabled, true)
end)
test("sold out", function() local i = validItem(); i.available = 0; eq(L.Evaluate(i, 500, 20).reason, "Stock") end)
test("full bags", function() eq(L.Evaluate(validItem(), 500, 19).reason, "Bags") end)
test("unknown bag data fails closed", function() eq(L.Evaluate(validItem(), 500, nil).reason, "Loading") end)
test("uncached item data", function() local i = validItem(); i.maxStack = nil; eq(L.Evaluate(i, 500, 20).reason, "Loading") end)
test("invalid lot size", function() local i = validItem(); i.bundle = 0; eq(L.Evaluate(i, 500, 20).reason, "Loading") end)
test("indivisible merchant bundles", function() local i = validItem(); i.bundle = 3; eq(L.Evaluate(i, 500, 20).reason, "Bundle") end)
test("single items are hidden", function() local i = validItem(); i.maxStack = 1; eq(L.Evaluate(i, 500, 20).visible, false) end)
test("extended and mixed costs are hidden", function() local i = validItem(); i.extendedCost = true; eq(L.Evaluate(i, 500, 20).visible, false) end)
test("currency products are hidden", function() local i = validItem(); i.currency = 123; eq(L.Evaluate(i, 500, 20).visible, false) end)
test("missing merchant row is hidden", function() eq(L.Evaluate(nil, 500, 20).visible, false) end)
test("owned items do not reduce purchase size", function() local i = validItem(); i.owned = 7; eq(L.Evaluate(i, 500, 20).quantity, 20) end)
test("unique maximum includes already owned items", function()
    local i = validItem(); i.uniqueLimit = 20; i.owned = 1
    eq(L.Evaluate(i, 500, 20).reason, "Unique")
    i.owned = 0; eq(L.Evaluate(i, 500, 20).enabled, true)
end)
test("shared unique categories use native purchase", function() local i = validItem(); i.uniqueBlocked = true; eq(L.Evaluate(i, 500, 20).reason, "Unique") end)
test("not purchasable", function() local i = validItem(); i.purchasable = false; eq(L.Evaluate(i, 500, 20).reason, "Unavailable") end)
test("200-item stack and discounted price", function()
    local i = validItem(); i.maxStack = 200; i.price = 95
    local r = L.Evaluate(i, 3800, 200); eq(r.total, 3800); eq(r.quantity, 200); eq(r.enabled, true)
end)
test("free gold-only items", function() local i = validItem(); i.price = 0; eq(L.Evaluate(i, 0, 20).enabled, true) end)
test("empty general bag slot holds one stack", function()
    eq(L.Capacity(validItem(), {{family = 0, slots = {{empty = true}}}}), 20)
end)
local function band(a, b) -- Small family masks used by these tests.
    local result, weight = 0, 1
    while a > 0 and b > 0 do
        if a % 2 == 1 and b % 2 == 1 then result = result + weight end
        a = math.floor(a / 2); b = math.floor(b / 2); weight = weight * 2
    end
    return result
end
test("specialty bag rejects incompatible food", function() eq(L.Capacity(validItem(), {{family = 32, slots = {{empty = true}}}}, band), 0) end)
test("specialty bag accepts matching family", function()
    local i = validItem(); i.family = 32
    eq(L.Capacity(i, {{family = 32, slots = {{empty = true}}}}, band), 20)
end)
test("partial stacks combine to provide room", function()
    eq(L.Capacity(validItem(), {{family = 0, slots = {{link = link(), count = 7}, {link = link(nil, nil, 60), count = 13}}}}), 20)
end)
test("locked stacks are excluded", function() eq(L.Capacity(validItem(), {{family = 0, slots = {{link = link(), count = 7, locked = true}}}}), 0) end)
test("different random suffix cannot merge", function() eq(L.Capacity(validItem(), {{family = 0, slots = {{link = link(nil, 5), count = 1}}}}), 0) end)

-- Integration harness loads the real TOC order and executes the actual UI callbacks.
local config, frames, calls, timers, popups
local Frame = {}
function Frame:SetSize(w, h) self.width, self.height = w, h end
function Frame:SetPoint(...) self.point = {...} end
function Frame:SetWidth(w) self.width = w end
function Frame:GetWidth() return self.width or 100 end
function Frame:SetNormalFontObject() end
function Frame:SetHighlightFontObject() end
function Frame:SetDisabledFontObject() end
function Frame:SetMotionScriptsWhileDisabled(v) self.disabledHover = v end
function Frame:RegisterForClicks() end
function Frame:RegisterEvent(event) self.events[event] = true end
function Frame:SetScript(name, fn) self.scripts[name] = fn end
function Frame:HookScript(name, fn)
    local old = self.scripts[name]
    self.scripts[name] = function(...) if old then old(...) end; fn(...) end
end
function Frame:IsShown() return self.shown ~= false end
function Frame:Show() local old = self.shown; self.shown = true; if old == false and self.scripts.OnShow then self.scripts.OnShow(self) end end
function Frame:Hide() local old = self.shown; self.shown = false; if old ~= false and self.scripts.OnHide then self.scripts.OnHide(self) end end
function Frame:SetText(text) self.text = text end
function Frame:GetFontString() return self end
function Frame:GetStringWidth() return #(self.text or "") * 5 end
function Frame:SetEnabled(v) self.enabled = v end
function Frame:Disable() self.enabled = false end
function Frame:GetID() return self.id end
function Frame:GetName() return self.name end
local function emit(event)
    for _, frame in ipairs(frames) do if frame.events[event] then frame.scripts.OnEvent(frame, event) end end
end
local function flush()
    local work = timers; timers = {}
    for _, fn in ipairs(work) do fn() end
end
local function setup(locale)
    config = { money = 500, stock = -1, price = 125, maxStack = 20, bundle = 5, vendor = "VendorA", bagSize = 1,
        slots = {}, itemID = 117, locale = locale or "frFR" }
    frames, calls, timers, popups = {}, {}, {}, {}
    function CreateFrame(_, name)
        local frame = setmetatable({name = name, scripts = {}, events = {}}, {__index = Frame})
        frames[#frames + 1] = frame
        if name then _G[name] = frame end
        return frame
    end
    MerchantFrame = CreateFrame("Frame", "MerchantFrame")
    MerchantFrame.page, MerchantFrame.selectedTab = 1, 1
    MERCHANT_ITEMS_PER_PAGE, NUM_TOTAL_EQUIPPED_BAG_SLOTS, MERCHANT_HIGH_PRICE_COST = 10, 5, 1500000
    for i = 1, 10 do
        local row = CreateFrame("Frame", "MerchantItem" .. i)
        row.ItemButton = CreateFrame("Button", "MerchantItem" .. i .. "ItemButton")
        row.ItemButton.id = i
        row.Name = CreateFrame("FontString", "MerchantItem" .. i .. "Name")
        row.Name.width = 100
    end
    function MerchantFrame_Update()
        for i = 1, 10 do _G["MerchantItem" .. i].ItemButton.id = (MerchantFrame.page - 1) * 10 + i end
    end
    function hooksecurefunc(name, fn) local old = _G[name]; _G[name] = function(...) old(...); fn(...) end end
    function GetLocale() return config.locale end
    function GetMoney() return config.money end
    function UnitGUID() return config.vendor end
    function GetMerchantNumItems() return 21 end
    function GetMerchantItemLink(index) if not config.noLink then return link(config.itemID + index - 1) end end
    function BuyMerchantItem(index, count) calls[#calls + 1] = {index = index, count = count} end
    function GetMoneyString(amount) return tostring(amount) .. " copper" end
    function StaticPopup_Visible(name) return popups[name] end
    function StaticPopup_Hide(name) popups[name] = nil end
    function MerchantFrame_ConfirmHighCostItem(proxy, count)
        MerchantFrame.itemIndex, MerchantFrame.count = proxy:GetID(), count
        calls[#calls + 1] = {dialog = "high", count = count, price = proxy.price}
        popups.CONFIRM_HIGH_COST_ITEM = true
    end
    function MerchantFrame_ConfirmExtendedItemCost(proxy, count)
        MerchantFrame.itemIndex, MerchantFrame.count = proxy:GetID(), count
        if proxy.price < MERCHANT_HIGH_PRICE_COST then BuyMerchantItem(proxy:GetID(), count)
        else
            calls[#calls + 1] = {dialog = "nonrefund", count = count, price = proxy.price}
            popups.CONFIRM_PURCHASE_NONREFUNDABLE_ITEM = true
        end
    end
    C_MerchantFrame = {GetItemInfo = function()
        if config.noInfo then return nil end
        return { name = "Lait glacé", texture = 1, price = config.price, stackCount = config.bundle,
            numAvailable = config.stock, isPurchasable = true, isUsable = false, hasExtendedCost = config.extended }
    end}
    C_Item = {
        GetItemInfo = function() return "Item", link(), 1, 1, 1, "Food", "Food", config.maxStack end,
        GetItemFamily = function() return 0 end,
        GetItemCount = function(_, includeBank) eq(includeBank, true); return config.owned or 0 end,
        GetItemUniquenessByID = function() return config.unique, nil, config.limit, config.category end,
    }
    C_Container = {
        GetContainerNumSlots = function(bag) return bag == 0 and config.bagSize or 0 end,
        GetContainerNumFreeSlots = function() return config.bagSize, 0 end,
        GetContainerItemInfo = function(_, slot) return config.slots[slot] end,
    }
    bit = {band = band}
    C_Timer = {After = function(_, fn) timers[#timers + 1] = fn end}
    GameTooltip = {
        SetOwner = function(self, owner) self.owner = owner; self.lines = {} end,
        IsOwned = function(self, owner) return self.owner == owner end,
        SetText = function(self, text) self.title = text end,
        AddLine = function(self, text) self.lines[#self.lines + 1] = text end,
        Show = function(self) self.shown = true end,
        Hide = function(self) self.shown = false; self.owner = nil end,
    }
    local a = {}
    for line in TEST_TOC:gmatch("[^\r\n]+") do if line:match("%.lua$") then Load(line, a) end end
    emit("MERCHANT_SHOW"); flush(); MerchantFrame_Update()
    return a, VendorMaxStackButton1
end

test("click calls the real adapter with 20 units once", function()
    local _, b = setup(); b.scripts.OnClick(b); eq(#calls, 1); eq(calls[1].count, 20); eq(calls[1].index, 1)
end)
test("not usable due to player level does not prevent buying", function() local _, b = setup(); eq(b.enabled, true) end)
test("button size and name space; restore on buyback", function()
    local _, b = setup(); eq(b.text, "×20"); eq(b.disabledHover, true)
    eq(MerchantItem1.Name.width < 100, true)
    MerchantFrame.selectedTab = 2; MerchantFrame_Update(); eq(b:IsShown(), false); eq(MerchantItem1.Name.width, 100)
end)
test("disabled button shows a translated tooltip", function()
    local _, b = setup(); config.money = 499; emit("PLAYER_MONEY"); flush()
    eq(b.enabled, false); b.scripts.OnEnter(b); eq(GameTooltip.lines[3], "Vous n’avez pas assez d’argent pour une pile complète.")
    b.scripts.OnClick(b); eq(#calls, 0)
end)
test("stale page click buys nothing", function()
    local _, b = setup(); MerchantFrame.page = 2; b.scripts.OnClick(b); eq(#calls, 0)
end)
test("refreshed page buys correct index", function()
    local _, b = setup(); MerchantFrame.page = 2; MerchantFrame_Update(); b.scripts.OnClick(b); eq(calls[1].index, 11)
end)
test("changed merchant invalidates old offer", function()
    local _, b = setup(); config.vendor = "VendorB"; b.scripts.OnClick(b); eq(#calls, 0)
end)
test("changed price requires a fresh click", function()
    local _, b = setup(); config.price = 100; b.scripts.OnClick(b); eq(#calls, 0)
    b.scripts.OnClick(b); eq(#calls, 1)
end)
test("stock is rechecked at click", function() local _, b = setup(); config.stock = 10; b.scripts.OnClick(b); eq(#calls, 0) end)
test("bag capacity is rechecked at click", function()
    local _, b = setup(); config.slots[1] = {stackCount = 20, hyperlink = link()}; b.scripts.OnClick(b); eq(#calls, 0)
end)
test("item info loading and arrival", function()
    local _, b = setup(); config.maxStack = nil; emit("GET_ITEM_INFO_RECEIVED"); flush()
    eq(b.text, "…"); eq(b.enabled, false)
    config.maxStack = 20; emit("GET_ITEM_INFO_RECEIVED"); flush(); eq(b.enabled, true)
end)
test("extended costs hide UI", function() local _, b = setup(); config.extended = true; MerchantFrame_Update(); eq(b:IsShown(), false) end)
test("unique ownership read includes bank", function()
    local _, b = setup(); config.unique = true; config.limit = 20; config.owned = 1; MerchantFrame_Update(); eq(b.result.reason, "Unique")
end)
test("high total uses native confirmation with unit price and exact quantity", function()
    local _, b = setup(); config.price = 400000; config.money = 2000000; MerchantFrame_Update()
    b.scripts.OnClick(b); eq(#calls, 1); eq(calls[1].dialog, "high"); eq(calls[1].count, 20); eq(calls[1].price, 80000)
    b.scripts.OnClick(b); eq(#calls, 1)
end)
test("nonrefundable native confirmation displays full price", function()
    local _, b = setup(); config.price = 400000; config.money = 2000000; b.native.showNonrefundablePrompt = true; MerchantFrame_Update()
    b.scripts.OnClick(b); eq(calls[1].dialog, "nonrefund"); eq(calls[1].count, 20); eq(calls[1].price, 1600000)
end)
test("low-cost nonrefundable path still buys full quantity", function()
    local _, b = setup(); b.native.showNonrefundablePrompt = true; b.scripts.OnClick(b); eq(calls[1].count, 20)
end)
test("own native confirmation canceled on page change", function()
    local _, b = setup(); config.price = 400000; config.money = 2000000; MerchantFrame_Update(); b.scripts.OnClick(b)
    MerchantFrame.page = 2; MerchantFrame_Update(); eq(popups.CONFIRM_HIGH_COST_ITEM, nil)
end)
test("close merchant hides buttons and cancels confirmation", function()
    local _, b = setup(); config.price = 400000; config.money = 2000000; MerchantFrame_Update(); b.scripts.OnClick(b)
    emit("MERCHANT_CLOSED"); eq(b:IsShown(), false); eq(popups.CONFIRM_HIGH_COST_ITEM, nil)
end)
test("refused transaction is not retried by update events", function()
    local _, b = setup(); b.scripts.OnClick(b); emit("UI_ERROR_MESSAGE"); emit("MERCHANT_UPDATE"); flush(); eq(#calls, 1)
end)
test("native purchase functions are not replaced", function()
    setup(); local buy = BuyMerchantItem; emit("MERCHANT_SHOW"); flush(); eq(BuyMerchantItem, buy)
end)
test("existing native confirmation is not overwritten", function()
    local _, b = setup(); popups.CONFIRM_PURCHASE_TOKEN_ITEM = true
    b.scripts.OnClick(b); eq(#calls, 0); eq(popups.CONFIRM_PURCHASE_TOKEN_ITEM, true)
end)
test("another native confirmation is not canceled by our pending state", function()
    local _, b = setup(); config.price = 400000; config.money = 2000000; MerchantFrame_Update(); b.scripts.OnClick(b)
    MerchantFrame.itemIndex = 2
    MerchantFrame.page = 2; MerchantFrame_Update(); eq(popups.CONFIRM_HIGH_COST_ITEM, true)
end)
test("modern legacy merchant tuple keeps purchasability separate from usability", function()
    local a = setup(); C_MerchantFrame = nil
    GetMerchantItemInfo = function() return "Item", 1, 125, 5, -1, true, false, false end
    local r = a.API.Evaluate(1, a.API.ReadBags()); eq(r.enabled, true)
    GetMerchantItemInfo = nil
end)
test("unloaded merchant rows never issue purchases", function()
    local _, b = setup(); config.noInfo = true; b.scripts.OnClick(b); eq(#calls, 0); eq(b:IsShown(), false)
end)

test("every locale has the same keys and format arguments", function()
    local source = TEST_FILES["Localization.lua"]
    local capture = source:gsub("local locales = {", "local locales = {") .. "\nreturn locales"
    GetLocale = function() return "enUS" end
    local all = assert((loadstring or load)(capture))("VendorMaxStack", {})
    for locale, values in pairs(all) do
        local count = 0
        for key, value in pairs(values) do
            count = count + 1
            assert(all.enUS[key], locale .. " unknown key " .. key)
            local args, reference = {}, {}
            for arg in value:gmatch("%%[ds]") do args[#args + 1] = arg end
            for arg in all.enUS[key]:gmatch("%%[ds]") do reference[#reference + 1] = arg end
            eq(table.concat(args), table.concat(reference), locale .. "/" .. key)
        end
        eq(count, 9, locale .. " key count")
        if locale ~= "enUS" and locale ~= "enGB" then assert(TEST_TOC:find("## Notes-" .. locale .. ":", 1, true), locale .. " TOC") end
    end
end)
test("English UK and unknown locales use English", function()
    for _, locale in ipairs({"enGB", "unknown"}) do
        local a = setup(locale); eq(a.L.Buy, "Buy %d items (one full stack)")
    end
end)
print(tostring(passed) .. " scenarios passed")
