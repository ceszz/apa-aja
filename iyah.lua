-- Roblox exploit-friendly Auto Gift Mail script for Grow A Garden 2
-- Sesuaikan uiPath sesuai struktur GUI game/mailing.

-- Local aliases to satisfy linters/editors that flag engine globals
-- Inform common linters that these engine globals are expected
-- luacheck: globals game task wait
---@diagnostic disable: undefined-global

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local settings = {
    AutoMail = {
        username = "Player1", -- GANTI dengan nama akun target penerima
        itemcount = 20,       -- GANTI dengan jumlah item yang mau dikirim
    },
    Settings = {
        MoveSpeed = 16,
    },
}

-- CATATAN: Ganti isi di bawah ini menggunakan nama objek asli dari Dark Dex game
local uiPath = {
    MailButton = {"MailGui", "MainFrame"},
    UsernameBox = {"MailGui", "MainFrame", "UsernameBox"},
    ItemList = {"MailGui", "MainFrame", "ItemList"},
    SendButton = {"MailGui", "MainFrame", "SendButton"},
}

local function sleep(seconds)
    if task and task.wait then
        task.wait(seconds)
    else
        wait(seconds)
    end
end

local function findGui(path)
    local current = PlayerGui
    for _, name in ipairs(path) do
        if not current then
            return nil
        end
        current = current:FindFirstChild(name) or current:FindFirstChild(name, true)
        if not current then
            return nil
        end
    end
    return current
end

local function activateButton(button)
    if not button then
        return false
    end

    if button:IsA("TextButton") or button:IsA("ImageButton") then
        pcall(function()
            button:Activate()
        end)
        return true
    end

    if button:IsA("TextBox") then
        pcall(function()
            button:CaptureFocus()
        end)
        return true
    end

    return false
end

local function setText(box, text)
    if not box or not box:IsA("TextBox") then
        return false
    end

    box.Text = tostring(text)
    return true
end

local function getItemButtons()
    local container = findGui(uiPath.ItemList)
    if not container then
        return {}
    end

    local buttons = {}
    for _, child in ipairs(container:GetDescendants()) do
        if (child:IsA("TextButton") or child:IsA("ImageButton")) and child.Visible then
            table.insert(buttons, child)
        end
    end
    return buttons
end

local function openMailMenu()
    local mailButton = findGui(uiPath.MailButton)
    if mailButton then
        return activateButton(mailButton)
    end
    return findGui(uiPath.MailFrame) ~= nil
end

local function typeUsername(username)
    local box = findGui(uiPath.UsernameBox)
    if not box then
        return false
    end

    if not setText(box, username) then
        return false
    end

    sleep(0.2)
    if box:IsA("TextBox") then
        pcall(function()
            box:ReleaseFocus()
        end)
    end
    return true
end

local function selectMailItems(itemCount)
    local buttons = getItemButtons()
    if #buttons == 0 then
        return itemCount
    end

    for _, button in ipairs(buttons) do
        if itemCount <= 0 then
            break
        end
        activateButton(button)
        itemCount = itemCount - 1
        sleep(0.05)
    end
    return itemCount
end

local function clickSendMail()
    return activateButton(findGui(uiPath.SendButton))
end

local function PlayerStatus(text)
    print("[AutoGiftMail] " .. tostring(text))
end

local function AutoGiftMail(username, itemCount)
    PlayerStatus("Auto gift mail start: " .. tostring(username))

    if not openMailMenu() then
        PlayerStatus("Mail menu open failed (Periksa tabel uiPath!)")
        return false
    end

    sleep(0.5)
    if not typeUsername(username) then
        PlayerStatus("Username entry failed")
        return false
    end

    sleep(0.5)
    while itemCount > 0 do
        local remaining = selectMailItems(itemCount)
        if remaining == itemCount then
            PlayerStatus("No mail items selected")
            break
        end

        itemCount = remaining
        if not clickSendMail() then
            PlayerStatus("Send button not found")
            break
        end

        sleep(1.5)
        if itemCount <= 0 then
            break
        end

        sleep(0.5)
    end

    PlayerStatus("Auto gift mail completed")
    return true
end

local function MainLoop()
    local username = settings.AutoMail.username
    local itemCount = tonumber(settings.AutoMail.itemcount) or 20
    AutoGiftMail(username, itemCount)
end

local function Start()
    MainLoop()
end

-- MENJALANKAN OTOMATIS SAAT DI-EXECUTE
task.spawn(Start)

return {
    Start = Start,
    AutoGiftMail = AutoGiftMail,
    settings = settings,
}
