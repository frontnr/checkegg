-- ====== CONFIG ======
getgenv().Configuration = {
    WEBHOOK = [[https://discord.com/api/webhooks/1409792526683996211/VbppxARxiwOBFYLvLAlaFX7p26OVHOywaLEvdn1UEAev80FdFZWtXYcDN7SGFUY7R7W1]],
    USE_DISPLAY_NAME = true,
    STATUS_ORDER = {"Golden", "Diamond", "Electric", "Fire", "Jurassic", "Normal"}
}

-- ====== UTILS ======
local function emoji(name, id)
    return string.char(60) .. ":" .. name .. ":" .. id .. string.char(62)
end

local Http = game:GetService("HttpService")
local Players = game:GetService("Players")
local plr = Players.LocalPlayer
local cfg = getgenv().Configuration
local url = tostring(cfg.WEBHOOK or "")
if url == "" then return end
local req = (syn and syn.request) or (http and http.request) or http_request or request
if not req then return end
local who = cfg.USE_DISPLAY_NAME and (plr.DisplayName or plr.Name) or plr.Name

-- ====== ICONS ======
local ARROW_ICON = emoji("arrow", "1409512392429408347")

local EGG_ICONS = {
    BasicEgg       = emoji("Basic", "1409497968976986172"),
    RareEgg        = emoji("Rare", "1409497981648113785"),
    SuperRareEgg   = emoji("Superrare", "1409497984059576332"),
    EpicEgg        = emoji("Epic", "1409497971585974432"),
    LegendEgg      = emoji("Legend", "1409497977046831144"),
    HyperEgg       = emoji("Hyper", "1409497974735769622"),
    PrismaticEgg   = emoji("Prismatic", "1409497979404029982"),
    DinoEgg        = emoji("Dino", "1409427300788998144"),
    VoidEgg        = emoji("Void", "1409427316274237521"),
    BoneDragonEgg  = emoji("bonedragon", "1409427235148140615"),
    BowserEgg      = emoji("bowser", "1409427237941411880"),
    UnicornEgg     = emoji("Unicorn", "1409427313375842335"),
    UltraEgg       = emoji("Ultra", "1409427302894407760"),
    CornEgg        = emoji("Corn", "1409427240445284373"),
    DemonEgg       = emoji("Demon", "1409427243452600382"),
}

local FRUIT_ICONS = {
    Watermelon      = emoji("Watermelon", "1409497865167831071"),
    Strawberry      = emoji("Strawberry", "1409497861124784189"),
    Blueberry       = emoji("Blueberry", "1409497845450408077"),
    Apple           = emoji("Apple", "1409497838374879343"),
    Orange          = emoji("Orange", "1409497856305401930"),
    Corn            = emoji("Corn", "1409427240445284373"),
    Banana          = emoji("Banana", "1409497840673095830"),
    Grape           = emoji("Grape", "1409497854413770816"),
    Pear            = emoji("Pear", "1409497859107061820"),
    Pineapple       = emoji("Pineapple", "1409515598815432724"),
    GoldMango       = emoji("Goldmango", "1409497852631191663"),
    BloodstoneCycad = emoji("BloodStone", "1409497842695012424"),
    ColossalPinecone= emoji("Colossa", "1409497847564337152"),
    VoltGinkgo      = emoji("Volt", "1409497862936592516"),
}

local DISPLAY_NAME_MAP = { Dino = "Jurassic" }
local FRUITS = {
    "Strawberry", "Blueberry", "Watermelon", "Apple", "Orange", "Corn",
    "Banana", "Grape", "Pear", "Pineapple", "GoldMango",
    "BloodstoneCycad", "ColossalPinecone", "VoltGinkgo"
}
local FRUIT_SET = {} for _,v in ipairs(FRUITS) do FRUIT_SET[v]=true end

-- ====== TIME ======
local function getThaiTime()
    local utc = os.time(os.date("!*t"))
    local thTime = os.date("*t", utc + (11*60*60))
    return string.format("%02d:%02d:%02d", thTime.hour, thTime.min, thTime.sec),
           string.format("%d/%d/%d", thTime.month, thTime.day, thTime.year)
end

-- ====== SCAN EGGS ======
local eggFolder = plr:FindFirstChild("PlayerGui") and plr.PlayerGui:FindFirstChild("Data") and plr.PlayerGui.Data:FindFirstChild("Egg")
local eggCounts, eggTotals, eggLines = {}, {}, {}
if eggFolder then
    for _, it in ipairs(eggFolder:GetChildren()) do
        local t = it:GetAttribute("T")
        if t then
            local m = it:GetAttribute("M") or "Normal"
            local displayM = DISPLAY_NAME_MAP[m] or m
            eggCounts[t] = eggCounts[t] or {}
            eggCounts[t][displayM] = (eggCounts[t][displayM] or 0) + 1
            eggTotals[t] = (eggTotals[t] or 0) + 1
        end
    end
end
for egg, byStatus in pairs(eggCounts) do
    local total = eggTotals[egg] or 0
    local parts = {}
    for _, s in ipairs(cfg.STATUS_ORDER) do
        local c = byStatus[s]
        if c then table.insert(parts, s.." "..c.." ใบ") end
    end
    local icon = EGG_ICONS[egg] or "🥚"
    local statusText = (#parts > 0 and "\n" .. ARROW_ICON .. " " .. table.concat(parts, " / ")) or ""
    table.insert(eggLines, icon .. " " .. egg .. " x" .. total .. statusText)
end

-- ====== SCAN FRUITS ======
local fruitLines = {}
local fruitScroll = plr.PlayerGui:WaitForChild("ScreenStorage"):WaitForChild("Frame"):WaitForChild("ContentFood"):WaitForChild("ScrollingFrame")
for _, node in ipairs(fruitScroll:GetChildren()) do
    if FRUIT_SET[node.Name] then
        local qty = 1
        local btn = node:FindFirstChild("BTN")
        if btn and btn:FindFirstChild("Stat") and btn.Stat:FindFirstChild("NUM") then
            local label = btn.Stat.NUM
            local txt = tostring(label.ContentText or label.Text or ""):gsub("%D", "")
            local number = tonumber(txt)
            if number then qty = number end
        end
        table.insert(fruitLines, (FRUIT_ICONS[node.Name] or "").." "..node.Name.." x"..qty)
    end
end

-- ====== SCAN PETS ======
local petLines, rangeCount = {}, {}
local scroll = plr.PlayerGui.ScreenStorage.Frame.ContentPet.ScrollingFrame
for _, pet in ipairs(scroll:GetChildren()) do
    local btn = pet:FindFirstChild("BTN")
    if btn and btn:IsA("ImageButton") and not (btn:FindFirstChild("Big") and btn.Big.Visible) then
        local val = btn:FindFirstChild("Stat") and btn.Stat.Price and btn.Stat.Price.Value
        if val and val:IsA("TextLabel") then
            local raw = tostring(val.Text or ""):gsub("%D", "")
            local price = tonumber(raw)
            if price and price >= 19000 then
                local k = math.floor(price / 1000)
                rangeCount[k] = (rangeCount[k] or 0) + 1
            end
        end
    end
end
for k = 19, 299 do
    if rangeCount[k] then
        table.insert(petLines, tostring(k).."K จำนวน "..rangeCount[k].." ตัว")
    end
end

-- ====== EMBEDS ======
local timeStr, dateStr = getThaiTime()

-- Embed1: Eggs + Fruits
local embed1 = {
    title = " Eggs และ  Fruits ของ: " .. who,
    color = 0xea123c,
    fields = {
        { name = "Eggs", value = (#eggLines > 0 and table.concat(eggLines, "\n")) or "-", inline = true },
        { name = "Fruits", value = (#fruitLines > 0 and table.concat(fruitLines, "\n")) or "-", inline = true }
    },
    footer = { text = "📅 เวลา " .. timeStr .. " | วันที่ " .. dateStr .. " (TH)" }
}

-- Embed2: Animals
local embed2 = {
    title = " Animals ของ: " .. who,
    color = 0xea123c,
    fields = {
        { name = "Animals", value = (#petLines > 0 and table.concat(petLines, "\n")) or "❌ ไม่พบสัตว์ที่มีราคาตั้งแต่ 19K ขึ้นไป", inline = false }
    },
    footer = { text = "📅 เวลา " .. timeStr .. " | วันที่ " .. dateStr .. " (TH)" }
}

-- ====== SEND WEBHOOK ======
pcall(function()
    req({
        Url = url,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = Http:JSONEncode({
            username = "📊 Backpack Scanner",
            embeds = {embed1, embed2}
        })
    })
end)
