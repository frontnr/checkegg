-- ====== CONFIG ======
getgenv().Configuration = {
    WEBHOOK = [[https://discord.com/api/webhooks/1406587046868553798/IJg0yE_3UTPefIuBIsneA7BRdLM1wepy0GSyuPUeo8yht8tZrRZG0kz5gZZl1w8Sb1Eo]],
    USE_DISPLAY_NAME = true,
    STATUS_ORDER = {"Golden", "Diamond", "Electric", "Fire", "Jurassic", "Normal"}
}

-- ฟังก์ชันสร้าง emoji string
local function emoji(name, id)
    return string.char(60) .. ":" .. name .. ":" .. id .. string.char(62)
end

-- Mapping Egg Icons
local EGG_ICONS = {
    BasicEgg     = emoji("Basic", "1409497968976986172"),
    DinoEgg      = emoji("Dino", "1409427300788998144"),
    VoidEgg      = emoji("Void", "1409427316274237521"),
    BoneDragonEgg= emoji("bonedragon", "1409427235148140615"),
    BowserEgg    = emoji("bowser", "1409427237941411880"),
    UnicornEgg   = emoji("Unicorn", "1409427313375842335"),
    UltraEgg     = emoji("Ultra", "1409427302894407760"),
    CornEgg      = emoji("Corn", "1409427240445284373"),
    DemonEgg     = emoji("Demon", "1409427243452600382"),
}

-- Mapping Tier Icons
local TIER_ICONS = {
    Basic      = emoji("Basic", "1409497968976986172"),
    Rare       = emoji("Rare", "1409497981648113785"),
    Superrare  = emoji("Superrare", "1409497984059576332"),
    Epic       = emoji("Epic", "1409497971585974432"),
    Legend     = emoji("Legend", "1409497977046831144"),
    Hyper      = emoji("Hyper", "1409497974735769622"),
    Prismatic  = emoji("Prismatic", "1409497979404029982"),
    Arrow      = emoji("arrow", "1409512392429408347")
}

-- Mapping Fruits
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

-- ====== HTTP ======
local cfg = getgenv().Configuration
local Http = game:GetService("HttpService")
local url = tostring(cfg.WEBHOOK or "")
if url == "" then return end
local req = (syn and syn.request) or (http and http.request) or http_request or request
if not req then return end

local plr = game:GetService("Players").LocalPlayer
local who = cfg.USE_DISPLAY_NAME and (plr.DisplayName or plr.Name) or plr.Name

-- ====== เวลาไทย ======
local function getThaiTime()
    local timeStr, dateStr
    local ok = pcall(function()
        local res = game:HttpGet("http://worldtimeapi.org/api/timezone/Asia/Bangkok")
        local data = Http:JSONDecode(res)
        local datetime = data.datetime
        local y, m, d, H, M, S = datetime:match("^(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)")
        if y then
            dateStr = string.format("%d/%d/%d", tonumber(m), tonumber(d), tonumber(y))
            timeStr = string.format("%02d:%02d:%02d", tonumber(H), tonumber(M), tonumber(S))
        end
    end)
    if not ok or not timeStr then
        local utc = os.time(os.date("!*t"))
        local thTime = os.date("*t", utc + (11*60*60)) -- ✅ ใช้ +11 ที่ตรงในเครื่องคุณ
        timeStr = string.format("%02d:%02d:%02d", thTime.hour, thTime.min, thTime.sec)
        dateStr = string.format("%d/%d/%d", thTime.month, thTime.day, thTime.year)
    end
    return timeStr, dateStr
end

-- ====== Check Eggs ======
local eggFolder = plr.PlayerGui:FindFirstChild("Data") and plr.PlayerGui.Data:FindFirstChild("Egg")
local eggCounts, eggTotals, eggTotalAll = {}, {}, 0
if eggFolder then
    for _, it in ipairs(eggFolder:GetChildren()) do
        local t = it:GetAttribute("T")
        if t then
            local m = it:GetAttribute("M")
            m = (m and tostring(m) ~= "" and m) or "Normal"
            local displayM = DISPLAY_NAME_MAP[m] or m
            eggCounts[t] = eggCounts[t] or {}
            eggCounts[t][displayM] = (eggCounts[t][displayM] or 0) + 1
            eggTotals[t] = (eggTotals[t] or 0) + 1
            eggTotalAll += 1
        end
    end
end

local eggLines = {}
for egg, byStatus in pairs(eggCounts) do
    local total = eggTotals[egg] or 0
    local parts = {}
    for _, s in ipairs(cfg.STATUS_ORDER) do
        local c = byStatus[s]
        if c and c > 0 then
            table.insert(parts, s.." "..c.." ใบ")
        end
    end
    local icon = EGG_ICONS[egg] or ""
    local arrow = TIER_ICONS.Arrow or "•"
    if #parts > 0 then
        table.insert(eggLines, icon.." "..egg.." x"..total.."\n"..arrow.." "..table.concat(parts, " / "))
    else
        table.insert(eggLines, icon.." "..egg.." x"..total)
    end
end

-- ====== Check Fruits ======
local FRUITS = {
    "Strawberry","Blueberry","Watermelon","Apple","Orange","Corn",
    "Banana","Grape","Pear","Pineapple","GoldMango",
    "BloodstoneCycad","ColossalPinecone","VoltGinkgo"
}
local FRUIT_SET = {} for _,v in ipairs(FRUITS) do FRUIT_SET[v]=true end

local fruitLines = {}
local fruitScroll = plr.PlayerGui:WaitForChild("ScreenStorage"):WaitForChild("Frame"):WaitForChild("ContentFood"):WaitForChild("ScrollingFrame")
if fruitScroll then
    for _, node in ipairs(fruitScroll:GetChildren()) do
        if FRUIT_SET[node.Name] then
            local fname = node.Name
            local qty = 1
            local btn = node:FindFirstChild("BTN")
            if btn and btn:FindFirstChild("Stat") and btn.Stat:FindFirstChild("NUM") then
                local numLabel = btn.Stat.NUM
                local txt = tostring(numLabel.ContentText or numLabel.Text or ""):gsub("%D","")
                qty = tonumber(txt) or 1
            end
            local ficon = FRUIT_ICONS[fname] or ""
            table.insert(fruitLines, ficon.." "..fname.." x"..qty)
        end
    end
end

-- ====== Embed ======
local timeStr, dateStr = getThaiTime()
local embed = {
    username = "CheckInventory",
    embeds = {{
        title = "📦 ของในกระเป๋าของ " .. who,
        color = 0x3498DB,
        fields = {
            { name = "🥚 Eggs", value = (#eggLines>0 and table.concat(eggLines,"\n")) or "-", inline = true },
            { name = "🍎 Fruits", value = (#fruitLines>0 and table.concat(fruitLines,"\n")) or "-", inline = true }
        },
        footer = { text = "ณ เวลา " .. timeStr .. " | วันที่ " .. dateStr .. " (เวลาไทย)" }
    }}
}

req({ Url = url, Method = "POST", Headers = {["Content-Type"]="application/json"}, Body = Http:JSONEncode(embed) })

-- ====== Frame Notify ======
local function showNotify()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = plr:WaitForChild("PlayerGui")

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 1, 0)
    Frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    Frame.BackgroundTransparency = 0.4
    Frame.Parent = ScreenGui

    local TextLabel = Instance.new("TextLabel")
    TextLabel.Size = UDim2.new(1, 0, 1, 0)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Text = "✅ เช็คของเสร็จสิ้น ตรวจสอบผลลัพธ์ใน Discord"
    TextLabel.TextColor3 = Color3.fromRGB(255,255,255)
    TextLabel.TextScaled = true
    TextLabel.Font = Enum.Font.SourceSansBold
    TextLabel.Parent = Frame

    task.delay(10,function() ScreenGui:Destroy() end)
end

showNotify()
