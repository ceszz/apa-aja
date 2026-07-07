local MainLoop
local RedX_Shop_Button
local CheckDisconnect
local Click_Jandel
local Type_Username
local Select_Mail_item
local Click_Send_Mail
local ResetMacro
local ScrollDown
local HyperSleep
local CloseBrowserTab
local CloseChat
local Close_Leaderboard
local KeyDelay = 40

local currentWalk = { pid = "", name = "" }
local settings = {
    AutoMail = {
        username = "Player1",
        itemcount = 20,
    },
    Settings = {
        MoveSpeed = 16,
        VipLink = "",
    },
}

local WKey = "sc011"
local AKey = "sc01e"
local SKey = "sc01f"
local DKey = "sc020"
local RotLeft = "vkBC"
local RotRight = "vkBE"
local RotUp = "sc149"
local RotDown = "sc151"
local ZoomIn = "sc017"
local ZoomOut = "sc018"
local EKey = "sc012"
local RKey = "sc013"
local LKey = "sc026"
local EscKey = "sc001"
local EnterKey = "sc01c"
local SpaceKey = "sc039"
local SlashKey = "vk6F"
local SC_LShift = "sc02a"

local bitmaps = {
    Jandel = Gdip_BitmapFromBase64("iVBORw0KGgoAAAANSUhEUgAAAAUAAAAGCAYAAAAL+1RLAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAABhSURBVBhXRcy7DYAgFEbhCzfEBCx8NLewMTqDve5Cx0iswRasRH4NaDzlVxzCW0oJWms4w6APvfdQSmEbadgeNSCkQERIRjGRrmnMHMsIZxrnPDGGP9Sd/9GEKov31yuB68AWgCRIA+Z8DOAAAAAElFTkSuQmCC"),
    SendButton = Gdip_BitmapFromBase64("iVBORw0KGgoAAAANSUhEUgAAAAgAAAAECAYAAACzzX7wAAAAYElEQVR4ATyMMQ6AIBAEN/cnP+ZffAXPIHQYCkNnR2EorImg4oIJl51m57LigquNeZkrJgyUUb2X8hQ00pVAPfC7772Ulw8kHOGX4FVAW43m+kK+M+xmaRghjFkN4hnxAQAA///lkEavAAAABklEQVQDALjrQjlWWZfVAAAAAElFTkSuQmCC"),
    MailXbutton = Gdip_BitmapFromBase64("iVBORw0KGgoAAAANSUhEUgAAAAMAAAADCAYAAABWKLW/AAAAK0lEQVR4AWI6yMX5/zoQP+Lm+s/0598/hqdA/AaImXj+/2f4AWQ8//uXAQAAAP//Tq+ktQAAAAZJREFUAwCacRZZP4M0TgAAAABJRU5ErkJggg==")
}
bitmaps.CaseSense = 0

local windowX, windowY, windowWidth, windowHeight = 0, 0, 1920, 1080

local function sleep(ms)
    if task and task.wait then
        task.wait(ms / 1000)
    elseif wait then
        wait(ms / 1000)
    else
        os.execute("ping -n " .. math.max(1, math.floor(ms / 1000 + 1)) .. " 127.0.0.1 >nul")
    end
end

local function IniRead(source, section, key, defaultValue)
    if type(source) == "table" then
        if source[section] and source[section][key] ~= nil then
            return source[section][key]
        end
        return defaultValue
    end

    local currentSection
    local f = io.open(source, "r")
    if not f then
        return defaultValue
    end

    for line in f:lines() do
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" and not line:match("^%s*;") then
            local sectionName = line:match("^%[(.-)%]$")
            if sectionName then
                currentSection = sectionName
            else
                local k, v = line:match("^(.-)%s*=%s*(.*)$")
                if k and v and currentSection == section and k == key then
                    f:close()
                    return v
                end
            end
        end
    end

    f:close()
    return defaultValue
end

-- Example use with loadstring:
-- local module = assert(loadstring(code))()
-- module.AutoGiftMail("TargetPlayer", 20, module.GetBitmap("scorch"))

local function Start()
    PlayerStatus("Starting Auto Mail GAG 2 Macro by epic", "0xFFFF00", nil, false, nil, false)
    MainLoop()
end

local function GetBitmap(name)
    return bitmaps[name]
end

local function AutoGiftMail(username, itemCount, imagebitmap)
    PlayerStatus("Auto gift mail start: " .. tostring(username), "0x00ff00")

    Click_Jandel()
    Type_Username(username)

    while itemCount > 0 do
        itemCount = Select_Mail_item(imagebitmap, itemCount)
        Click_Send_Mail()
        sleep(2500)

        if itemCount == 0 then
            break
        end

        -- Jika masih ada item, lakukan lagi setelah jeda pendek.
        sleep(1000)
    end

    PlayerStatus("Auto gift mail completed", "0x00ffff")
end

local function MainLoop()
    ActivateRoblox()
    ResizeRoblox()

    local Username = IniRead(settings, "AutoMail", "username", "Player1")
    local totalItemCount = tonumber(IniRead(settings, "AutoMail", "itemcount", 20)) or 20
    local scorchDir = "./images/scorch.png"
    bitmaps.scorch = Gdip_BitmapFromBase64(ImagePutBase64(scorchDir, "png"))

    RedX_Shop_Button()
    sleep(250)

    AutoGiftMail(Username, totalItemCount, bitmaps.scorch)
end

local function Click_Jandel()
    sleep(500)
    ActivateRoblox()
    local hwnd = GetRobloxHWND()
    GetRobloxClientPos(hwnd)
    local pBMScreen = Gdip_BitmapFromScreen(string.format("%d|%d|%d|%d", windowX, windowY + 30, windowWidth, windowHeight - 30))
    local found, x, y = Gdip_ImageSearch(pBMScreen, bitmaps.Jandel, 25)
    if found then
        MouseMove(windowX + x, windowY + y + 30)
        sleep(300)
        Click()
    else
        Send(string.format("{%s down}", EKey))
        sleep(1500)
        Send(string.format("{%s up}", EKey))
        Gdip_DisposeImage(pBMScreen)
        pBMScreen = Gdip_BitmapFromScreen(string.format("%d|%d|%d|%d", windowX, windowY + 30, windowWidth, windowHeight - 30))
        found, x, y = Gdip_ImageSearch(pBMScreen, bitmaps.Jandel, 25)
        if found then
            MouseMove(windowX + x, windowY + y + 30)
            sleep(300)
            Click()
        end
    end
    Gdip_DisposeImage(pBMScreen)
end

local function Type_Username(username)
    SendText(username)
    sleep(250)
    Send(string.format("{%s}", EnterKey))
    sleep(250)

    local x, y = MouseGetPos()
    MouseMove(x, y + 80)
    sleep(200)
    Click()
    sleep(750)
end

local function Select_Mail_item(imagebitmap, itemCount)
    local LoopAmount
    if itemCount >= 20 then
        LoopAmount = 20
        itemCount = itemCount - 20
    else
        LoopAmount = itemCount
        itemCount = 0
    end

    ActivateRoblox()
    local hwnd = GetRobloxHWND()
    GetRobloxClientPos(hwnd)
    local pBMScreen = Gdip_BitmapFromScreen(string.format("%d|%d|%d|%d", windowX, math.floor(windowY + windowHeight * 0.3 + 0.5), windowWidth, math.floor(windowHeight * 0.5 + 0.5)))
    local found, x, y = Gdip_ImageSearch(pBMScreen, imagebitmap, 50)

    if found then
        MouseMove(windowX + x, windowY + y + windowHeight * 0.3)
        sleep(300)
        for i = 1, LoopAmount do
            Click()
            sleep(20)
        end
    else
        Gdip_DisposeImage(pBMScreen)
        while true do
            if CheckDisconnect() then
                return itemCount
            end
            ScrollDown(0.7)
            sleep(250)
            pBMScreen = Gdip_BitmapFromScreen(string.format("%d|%d|%d|%d", windowX, math.floor(windowY + windowHeight * 0.3 + 0.5), windowWidth, math.floor(windowHeight * 0.5 + 0.5)))
            sleep(250)
            found, x, y = Gdip_ImageSearch(pBMScreen, imagebitmap, 50)
            if found then
                MouseMove(windowX + x, windowY + y + windowHeight * 0.3)
                sleep(300)
                for i = 1, LoopAmount do
                    Click()
                    sleep(20)
                end
                break
            end
            Gdip_DisposeImage(pBMScreen)
        end
    end
    Gdip_DisposeImage(pBMScreen)
    sleep(250)
    return itemCount
end

local function Click_Send_Mail()
    ActivateRoblox()
    local hwnd = GetRobloxHWND()
    GetRobloxClientPos(hwnd)
    local pBMScreen = Gdip_BitmapFromScreen(string.format("%d|%d|%d|%d", windowX, math.floor(windowY + windowHeight * 0.5 + 0.5), windowWidth, math.floor(windowHeight * 0.5 + 0.5)))
    local found, x, y = Gdip_ImageSearch(pBMScreen, bitmaps.SendButton, 50)
    if found then
        MouseMove(windowX + x, windowY + y + windowHeight * 0.5)
        sleep(300)
        Click()
    end
    Gdip_DisposeImage(pBMScreen)
    PlayerStatus("Sent Mail ezz", "0x000000", nil, false, nil, true)
end

local function RedX_Shop_Button(clickit)
    clickit = clickit == nil and 1 or clickit
    ActivateRoblox()
    local hwnd = GetRobloxHWND()
    GetRobloxClientPos(hwnd)
    local capX = windowX + windowWidth * 0.6
    local capY = windowY + windowHeight * 0.1
    local capW = windowWidth * 0.2
    local capH = windowHeight * 0.3
    local pBMScreen = Gdip_BitmapFromScreen(string.format("%d|%d|%d|%d", capX, capY, capW, capH))
    local found, x, y = Gdip_ImageSearch(pBMScreen, bitmaps.MailXbutton, 25)
    if found then
        if clickit == 1 then
            MouseMove(capX + x, capY + y)
            sleep(300)
            Click()
        end
        Gdip_DisposeImage(pBMScreen)
        return true
    end
    Gdip_DisposeImage(pBMScreen)
    return false
end

local function ScrollDown(amount)
    local BaseHeight = 1080
    local Scale = windowHeight / BaseHeight
    local AdjustedAmount = math.floor(-amount * 120 * Scale + 0.5)
    MouseWheel(AdjustedAmount)
end

local function Walk_Studs(studs, MoveKey1, MoveKey2)
    local currentWalkSpeed = tonumber(IniRead(settings, "Settings", "MoveSpeed", 16)) or 16
    local sleepTime = (studs / currentWalkSpeed) * 1000
    Send(string.format("{%s down}", MoveKey1))
    if MoveKey2 then
        Send(string.format("{%s down}", MoveKey2))
    end
    HyperSleep(sleepTime)
    Send(string.format("{%s up}", MoveKey1))
    if MoveKey2 then
        Send(string.format("{%s up}", MoveKey2))
    end
end

local function HyperSleep(ms)
    local start = os.clock()
    while (os.clock() - start) * 1000 < ms do
        -- busy wait, atau ganti dengan fungsi tidur yang lebih tepat
    end
end

local function CheckDisconnect()
    local hwnd = GetRobloxHWND()
    GetRobloxClientPos()
    local pBMScreen = Gdip_BitmapFromScreen(string.format("%d|%d|%d|%d", windowX, windowY + 30, windowWidth, windowHeight - 30))
    local disconnected = Gdip_ImageSearch(pBMScreen, bitmaps.disconnected, 2)
    if disconnected or GetRobloxHWND() == 0 then
        PlayerStatus("Starting Grow A Garden 2", "0x00a838", nil, false, nil, false)
        Gdip_DisposeImage(pBMScreen)
        CloseRoblox()

        local PlaceID = "97598239454123"
        local VipLink = IniRead(settings, "Settings", "VipLink", "")
        local DeepLink = "roblox://placeID=" .. PlaceID

        local match = VipLink:match("privateServerLinkCode=(%d+)")
        if match then
            DeepLink = DeepLink .. "&linkCode=" .. match
        end

        Run(DeepLink)

        for i = 1, 60 do
            if GetRobloxHWND() ~= 0 then
                sleep(500)
                CloseBrowserTab()
                sleep(500)
                ActivateRoblox()
                sleep(500)
                ResizeRoblox()
                sleep(25000)
                MouseMove(windowX + windowWidth * 0.5, windowY + windowHeight * 0.5)
                Click()
                PlayerStatus("Game Succesfully loaded", "0x00a838", nil, false)
                sleep(1000)
                CloseChat()
                Close_Leaderboard()
                sleep(1500)
                Walk_Studs(17, DKey)
                return true
            end
            sleep(1000)
        end
        return false
    end
    Gdip_DisposeImage(pBMScreen)
    return false
end

local function CloseChat()
    ActivateRoblox()
    local pBMScreen = Gdip_BitmapFromScreen(string.format("%d|%d|%.0f|%.0f", windowX, windowY, windowWidth * 0.25, windowHeight * 0.125))
    local found, x, y = Gdip_ImageSearch(pBMScreen, bitmaps.ChatOpen, 25)
    if found then
        MouseMove(windowX + x, windowY + y)
        sleep(300)
        Click()
    end
    Gdip_DisposeImage(pBMScreen)
end

local function Close_Leaderboard()
    ActivateRoblox()
    local capX = windowX + windowWidth - 300
    local pBMScreen = Gdip_BitmapFromScreen(string.format("%d|%d|%d|%d", capX, windowY, 300, 200))
    local found = Gdip_ImageSearch(pBMScreen, bitmaps.Leaderboard, 25)
    if found then
        Send("{Tab}")
        Gdip_DisposeImage(pBMScreen)
        return true
    end
    Gdip_DisposeImage(pBMScreen)
    return false
end

local function CloseBrowserTab()
    -- Implement window enumeration dan fokus untuk menutup tab browser
end

local PauseToggle = true

local function PauseMacro()
    PauseToggle = not PauseToggle
    if PauseToggle then
        Pause(false)
        ToolTip("Macro Unpaused")
    else
        Pause(true)
        ToolTip("Macro Paused")
    end
    SetTimer(function() ToolTip() end, -1000)
end

local function ResetMacro()
    Send(string.format("{%s up}{%s up}{%s up}{%s up}", DKey, WKey, AKey, SKey))
    -- Reload script jika diperlukan
end

local function ScreenResolution()
    if GetScreenDPI() ~= 96 then
        MsgBox("Set Scale to 100%!")
    end
end

-- Placeholder functions
function PlayerStatus(text, color, a, b, c, d) end
function ActivateRoblox() end
function GetRobloxHWND() return 0 end
function GetRobloxClientPos(hwnd) end
function ResizeRoblox() end
function Gdip_Startup() return true end
function Gdip_BitmapFromBase64(b64) return {} end
function Gdip_BitmapFromScreen(screen) return {} end
function Gdip_ImageSearch(image, template, tolerance)
    return false, 0, 0
end
function Gdip_DisposeImage(img) end
function ImagePutBase64(path, ext) return "" end
function Send(text) end
function SendText(text) end
function MouseMove(x, y) end
function Click() end
function MouseGetPos() return 0, 0 end
function MouseWheel(amount) end
function Run(command)
    -- placeholder: replace dengan mekanisme Android / Roblox untuk membuka deep link atau jalankan perintah sesuai platform
end
function MsgBox(text) print(text) end
function Pause(state) end
function ToolTip(text) end
function SetTimer(fn, ms) end
function GetScreenDPI() return 96 end
function CloseRoblox()
end

return {
    Start = Start,
    AutoGiftMail = AutoGiftMail,
    GetBitmap = GetBitmap,
    PauseMacro = PauseMacro,
    ResetMacro = ResetMacro,
    settings = settings,
}
