local _, addon = ...
local Logic = {}
addon.Logic = Logic

-- All quantities are individual items, not merchant bundles.
function Logic.Evaluate(item, money, capacity)
    if not item or item.extendedCost or item.currency then
        return { visible = false }
    end
    local result = { visible = true, quantity = item.maxStack, item = item }
    if not item.maxStack or not item.link or not item.bundle or item.bundle < 1 then
        result.reason = "Loading"
    elseif item.maxStack <= 1 then
        result.visible = false
    elseif item.maxStack % item.bundle ~= 0 then
        result.reason = "Bundle"
    elseif type(item.price) ~= "number" or item.price < 0 then
        result.reason = "Loading"
    else
        result.total = item.price * (item.maxStack / item.bundle)
        if item.available == nil then
            result.reason = "Loading"
        elseif item.available >= 0 and item.available < item.maxStack then
            result.reason = "Stock"
        elseif item.uniqueBlocked or (item.uniqueLimit and item.owned + item.maxStack > item.uniqueLimit) then
            result.reason = "Unique"
        elseif item.purchasable == false then
            result.reason = "Unavailable"
        elseif money < result.total then
            result.reason = "Money"
        elseif capacity == nil then
            result.reason = "Loading"
        elseif capacity < item.maxStack then
            result.reason = "Bags"
        end
    end
    result.enabled = result.visible and result.reason == nil
    return result
end

-- Ignore link presentation/player context; retain enchants, gems, suffix and bonuses.
function Logic.StackKey(link)
    local payload = link and link:match("item:([^|]+)")
    if not payload then return nil end
    local fields = {}
    for field in (payload .. ":"):gmatch("(.-):") do
        fields[#fields + 1] = field == "" and "0" or field
    end
    for i = 1, 13 do fields[i] = fields[i] or "0" end
    for _, i in ipairs({8, 9, 10, 12}) do fields[i] = "0" end
    while #fields > 13 and fields[#fields] == "0" do table.remove(fields) end
    return table.concat(fields, ":")
end

function Logic.Capacity(item, bags, band)
    if not item.maxStack or not item.family then return nil end
    local capacity, key = 0, Logic.StackKey(item.link)
    if not key then return nil end
    for _, bag in ipairs(bags) do
        if not bag.family then return nil end
        local compatible = bag.family == 0 or (band and band(bag.family, item.family) ~= 0)
        for _, slot in ipairs(bag.slots) do
            if slot.empty then
                if compatible then capacity = capacity + item.maxStack end
            elseif not slot.locked and Logic.StackKey(slot.link) == key then
                capacity = capacity + math.max(0, item.maxStack - slot.count)
            end
        end
    end
    return capacity
end

function Logic.SameOffer(a, b)
    return a and b and a.merchant == b.merchant and a.session == b.session
        and a.page == b.page and a.index == b.index and a.link == b.link
        and a.quantity == b.quantity and a.total == b.total
end
