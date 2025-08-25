-- ====== CONFIG (บังคับเซ็ตใหม่ทุกครั้ง) ======
getgenv().Configuration = {
    WEBHOOK = [[https://discord.com/api/webhooks/1406587046868553798/IJg0yE_3UTPefIuBIsneA7BRdLM1wepy0GSyuPUeo8yht8tZrRZG0kz5gZZl1w8Sb1Eo]],
    USE_DISPLAY_NAME = true,
    STATUS_ORDER = {"Golden", "Diamond", "Electric", "Fire", "Jurassic", "Normal"}
}

print("[DEBUG] Script started")

-- ฟังก์ชันสร้าง emoji string
local function emoji(name, id)
    return string.char(60) .. ":" .. name .. ":" .. id .. string.char(62)
end

-- Mapping Egg -> Emoji
local EGG_ICONS = {
    DinoEgg       = emoji("Dino", "1409427300788998144"),
    VoidEgg       = emoji("Void", "1409427316274237521"),
    BoneDragonEgg = emoji("bonedragon", "1409427235148140615"),
    BowserEgg     = emoji("bowser", "1409427237941411880"),
    UnicornEgg    = emoji("Unicorn", "1409427313375842335"),
    UltraEgg      = emoji("Ultra", "1409427302894407760"),
    CornEgg       = emoji("Corn", "1409427240445284373"),
    DemonEgg      = emoji("Demon", "1409427243452600382"),
}

local DISPLAY_NAME_MAP = { Dino = "Jurassic" }

-- ====== ตรวจสอบ HTTP ======
local cfg = getgenv().Configuration
local Http = game:GetService("HttpService")

print("[DEBUG] Full Configuration =", Http:JSONEncode(cfg))
local url = tostring(cfg.WEBHOOK or "")
print("[DEBUG] WEBHOOK =", url)

if url == "" then
    warn("[DEBUG] ❌ Webhook URL ว่าง หยุดการทำงาน")
    return
end

local req = (syn and syn.request) or (http and http.request) or http_request or request
if not req then
    warn("[DEBUG] ❌ Executor ของคุณไม่รองรับ HTTP request (req = nil)")
    return
end
print("[DEBUG] HTTP request function OK")

-- ====== ตรวจสอบ Player ======
local plr = game:GetService("Players").LocalPlayer
if not plr then
    warn("[DEBUG] ❌ LocalPlayer ไม่เจอ")
    return
end
print("[DEBUG] LocalPlayer:", plr.Name)

local who = cfg.USE_DISPLAY_NAME and (plr.DisplayName or plr.Name) or plr.Name

-- ========== เวลาไทย ==========
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
        local thTime = os.date("*t", utc + (11*60*60)) -- ✅ ใช้ +11 (ที่ตรงในเครื่องคุณ)
        timeStr = string.format("%02d:%02d:%02d", thTime.hour, thTime.min, thTime.sec)
        dateStr = string.format("%d/%d/%d", thTime.month, thTime.day, thTime.year)
    end
    return timeStr, dateStr
end

-- ========== Check Eggs ==========
print("[DEBUG] Start checking Eggs...")
local eggFolder = plr:FindFirstChild("PlayerGui") 
    and plr.PlayerGui:FindFirstChild("Data") 
    and plr.PlayerGui.Data:FindFirstChild("Egg")
if not eggFolder then
    warn("[DEBUG] ❌ Egg folder not found")
else
    print("[DEBUG] Egg folder OK, found:", #eggFolder:GetChildren(), "items")
end

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
        if c and c > 0 then table.insert(parts, s.." "..c.." ใบ") end
    end
    for s, c in pairs(byStatus) do
        if not table.find(cfg.STATUS_ORDER, s) then
            table.insert(parts, s.." "..c.." ใบ")
        end
    end
    local icon = EGG_ICONS[egg] or "" 
    table.insert(eggLines, icon.." "..egg.." x"..total.."\n• "..table.concat(parts, " / "))
end

-- ========== Check Fruits (Auto scan + ContentText) ==========
print("[DEBUG] Start checking Fruits...")
local fruitScroll
pcall(function()
    fruitScroll = plr.PlayerGui
        :WaitForChild("ScreenStorage")
        :WaitForChild("Frame")
        :WaitForChild("ContentFood")
        :WaitForChild("ScrollingFrame")
end)

if not fruitScroll then
    warn("[DEBUG] ❌ Fruit ScrollingFrame not found")
end

local fruitLines = {}
if fruitScroll then
    for _, node in ipairs(fruitScroll:GetChildren()) do
        if node:IsA("Folder") or node:IsA("Frame") then
            local fname = node.Name
            local qty = 1

            local btn = node:FindFirstChild("BTN")
            if btn and btn:FindFirstChild("Stat") then
                local numLabel = btn.Stat:FindFirstChild("NUM")
                if numLabel and numLabel:IsA("TextLabel") then
                    local txt = tostring(numLabel.ContentText or numLabel.Text or ""):gsub("%D", "")
                    qty = tonumber(txt) or 1
                end
            end

            table.insert(fruitLines, fname .. " x" .. qty)
        end
    end
    print("[DEBUG] ✅ Fruits scanned:", #fruitLines)
end

-- ========== Embed Payload ==========
local timeStr, dateStr = getThaiTime()
local embed = {
    username = "CheckInventory",
    embeds = {{
        title = "📦 ของในกระเป๋าของ " .. who,
        color = 0x3498DB,
        fields = {
            {
                name = "🥚 Eggs",
                value = (#eggLines>0 and table.concat(eggLines, "\n")) or "-",
                inline = true
            },
            {
                name = "🍎 Fruits",
                value = (#fruitLines>0 and table.concat(fruitLines, "\n")) or "-",
                inline = true
            }
        },
        footer = { text = "ณ เวลา " .. timeStr .. " | วันที่ " .. dateStr .. " (เวลาไทย)" }
    }}
}

print("[DEBUG] Sending data to Discord...")

req({
    Url = url,
    Method = "POST",
    Headers = {["Content-Type"] = "application/json"},
    Body = Http:JSONEncode(embed)
})

print("[DEBUG] ✅ Script finished, payload sent")
