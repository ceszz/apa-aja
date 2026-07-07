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
        username = "Player1",
        itemcount = 20,
    },
    Settings = {
        MoveSpeed = 16,
    },
}

local uiPath = {
    MailButton = {"MailGui", "MainFrame"},
    UsernameBox = {"MailGui", "MainFrame", "UsernameBox"},
    ItemList = {"MailGui", "MainFrame", "ItemList"},
    SendButton = {"MailGui", "MainFrame", "SendButton"},
}

local function createMailGui()
    if PlayerGui:FindFirstChild("MailGui") then
        return
    end

    local screen = Instance.new("ScreenGui")
    screen.Name = "MailGui"
    screen.ResetOnSpawn = false

    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(0, 340, 0, 300)
    frame.Position = UDim2.new(0.5, -170, 0.12, 0)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = screen

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Mail"
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 20
    title.Parent = frame

    local usernameBox = Instance.new("TextBox")
    usernameBox.Name = "UsernameBox"
    usernameBox.PlaceholderText = "Recipient Username"
    usernameBox.Size = UDim2.new(0.9, 0, 0, 30)
    usernameBox.Position = UDim2.new(0.05, 0, 0, 40)
    usernameBox.Parent = frame

    local itemList = Instance.new("ScrollingFrame")
    itemList.Name = "ItemList"
    itemList.Size = UDim2.new(0.9, 0, 0, 160)
    itemList.Position = UDim2.new(0.05, 0, 0, 80)
    itemList.CanvasSize = UDim2.new(0, 0, 0, 0)
    itemList.ScrollBarThickness = 6
    itemList.BackgroundColor3 = Color3.fromRGB(40,40,40)
    itemList.Parent = frame

    local uiLayout = Instance.new("UIListLayout")
    uiLayout.Parent = itemList
    uiLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiLayout.Padding = UDim.new(0, 6)

    -- helper: add an item button (name, label)
    local function addItem(name, label, quantity)
        local b = Instance.new("TextButton")
        b.Name = name
        b.Size = UDim2.new(1, -10, 0, 30)
        if quantity and tonumber(quantity) then
            b.Text = (label or name) .. " x" .. tostring(quantity)
        else
            b.Text = label or name
        end
        b.AutoButtonColor = true
        b.BackgroundColor3 = Color3.fromRGB(60,60,60)
        b.TextColor3 = Color3.fromRGB(240,240,240)
        b.Parent = itemList
        b:SetAttribute("Selected", false)
        if quantity then
            b:SetAttribute("Quantity", quantity)
        end

        b.Activated:Connect(function()
            local sel = not b:GetAttribute("Selected")
            b:SetAttribute("Selected", sel)
            if sel then
                b.BackgroundColor3 = Color3.fromRGB(80,140,80)
            else
                b.BackgroundColor3 = Color3.fromRGB(60,60,60)
            end
        end)
        return b
    end

    -- sample items for testing (will be replaced by SyncInventory)
    for i = 1, 6 do
        addItem("Item" .. i, "Item " .. i)
    end

    -- small control buttons
    local selectAll = Instance.new("TextButton")
    selectAll.Name = "SelectAll"
    selectAll.Size = UDim2.new(0.2, 0, 0, 28)
    selectAll.Position = UDim2.new(0.05, 0, 1, -42)
    selectAll.Text = "Select All"
    selectAll.Parent = frame

    local clearSel = Instance.new("TextButton")
    clearSel.Name = "ClearSelection"
    clearSel.Size = UDim2.new(0.2, 0, 0, 28)
    clearSel.Position = UDim2.new(0.27, 0, 1, -42)
    clearSel.Text = "Clear"
    clearSel.Parent = frame

    local send = Instance.new("TextButton")
    send.Name = "SendButton"
    send.Size = UDim2.new(0.2, 0, 0, 28)
    send.Position = UDim2.new(0.49, 0, 1, -42)
    send.Text = "Send"
    send.Parent = frame

    local syncBtn = Instance.new("TextButton")
    syncBtn.Name = "SyncInventory"
    syncBtn.Size = UDim2.new(0.2, 0, 0, 28)
    syncBtn.Position = UDim2.new(0.71, 0, 1, -42)
    syncBtn.Text = "Sync"
    syncBtn.Parent = frame

    local mailButton = Instance.new("TextButton")
    mailButton.Name = "MailButton"
    mailButton.Size = UDim2.new(0, 80, 0, 30)
    mailButton.Position = UDim2.new(0, 8, 0, 8)
    mailButton.Text = "Mail"
    mailButton.Parent = screen

    mailButton.Activated:Connect(function()
        frame.Visible = not frame.Visible
    end)

    -- confirmation modal
    local confirmFrame = Instance.new("Frame")
    confirmFrame.Name = "ConfirmFrame"
    confirmFrame.Size = UDim2.new(0, 320, 0, 180)
    confirmFrame.Position = UDim2.new(0.5, -160, 0.5, -90)
    confirmFrame.BackgroundColor3 = Color3.fromRGB(18,18,18)
    confirmFrame.Visible = false
    confirmFrame.BorderSizePixel = 0
    confirmFrame.Parent = screen

    local confirmLabel = Instance.new("TextLabel")
    confirmLabel.Name = "ConfirmLabel"
    confirmLabel.Size = UDim2.new(1, -20, 1, -60)
    confirmLabel.Position = UDim2.new(0, 10, 0, 10)
    confirmLabel.BackgroundTransparency = 1
    confirmLabel.TextWrapped = true
    confirmLabel.Text = ""
    confirmLabel.TextColor3 = Color3.fromRGB(240,240,240)
    confirmLabel.TextXAlignment = Enum.TextXAlignment.Left
    confirmLabel.TextYAlignment = Enum.TextYAlignment.Top
    confirmLabel.Parent = confirmFrame

    local confirmBtn = Instance.new("TextButton")
    confirmBtn.Name = "ConfirmBtn"
    confirmBtn.Size = UDim2.new(0.4, 0, 0, 32)
    confirmBtn.Position = UDim2.new(0.1, 0, 1, -40)
    confirmBtn.Text = "Confirm"
    confirmBtn.Parent = confirmFrame

    local cancelBtn = Instance.new("TextButton")
    cancelBtn.Name = "CancelBtn"
    cancelBtn.Size = UDim2.new(0.4, 0, 0, 32)
    cancelBtn.Position = UDim2.new(0.5, 0, 1, -40)
    cancelBtn.Text = "Cancel"
    cancelBtn.Parent = confirmFrame

    selectAll.Activated:Connect(function()
        for _, child in ipairs(itemList:GetChildren()) do
            if child:IsA("TextButton") then
                child:SetAttribute("Selected", true)
                child.BackgroundColor3 = Color3.fromRGB(80,140,80)
            end
        end
    end)

    clearSel.Activated:Connect(function()
        for _, child in ipairs(itemList:GetChildren()) do
            if child:IsA("TextButton") then
                child:SetAttribute("Selected", false)
                child.BackgroundColor3 = Color3.fromRGB(60,60,60)
            end
        end
    end)

    -- sync inventory: try common locations (Backpack, Character, Inventory, ReplicatedStorage)
    local function syncInventory()
        PlayerStatus("Syncing inventory...")
        -- remove existing dynamic items
        for _, child in ipairs(itemList:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        local seen = {}
        local added = 0

        local function safeAdd(name, quantity)
            if not name or seen[name] then return false end
            seen[name] = true
            addItem(name, name, quantity)
            added = added + 1
            return true
        end

        -- 1) Backpack (tools)
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            for _, v in ipairs(backpack:GetChildren()) do
                local qty = nil
                if v.GetAttribute and v:GetAttribute("Quantity") then qty = v:GetAttribute("Quantity") end
                if not qty and v:FindFirstChild("Quantity") and v.Quantity:IsA("IntValue") then qty = v.Quantity.Value end
                safeAdd(v.Name, qty)
            end
        end

        -- 2) Character (equipped tools)
        local char = LocalPlayer.Character
        if char then
            for _, v in ipairs(char:GetChildren()) do
                if v:IsA("Tool") then
                    local qty = nil
                    if v.GetAttribute and v:GetAttribute("Quantity") then qty = v:GetAttribute("Quantity") end
                    safeAdd(v.Name, qty)
                end
            end
        end

        -- 3) Common inventory containers on player
        local inv = LocalPlayer:FindFirstChild("Inventory") or LocalPlayer:FindFirstChild("_Inventory") or LocalPlayer:FindFirstChild("Items")
        if inv then
            for _, v in ipairs(inv:GetChildren()) do
                local qty = nil
                if v.GetAttribute and v:GetAttribute("Quantity") then qty = v:GetAttribute("Quantity") end
                if not qty and v:FindFirstChild("Amount") and v.Amount:IsA("IntValue") then qty = v.Amount.Value end
                if not qty and v:FindFirstChild("Quantity") and v.Quantity:IsA("IntValue") then qty = v.Quantity.Value end
                safeAdd(v.Name, qty)
            end
        end

        -- 4) ReplicatedStorage / Server storage variants
        local rs = game:GetService("ReplicatedStorage")
        local rInv = rs:FindFirstChild("Inventory") or rs:FindFirstChild("Items") or rs:FindFirstChild("Shop")
        if rInv then
            for _, v in ipairs(rInv:GetChildren()) do
                local qty = nil
                if v.GetAttribute and v:GetAttribute("Quantity") then qty = v:GetAttribute("Quantity") end
                if not qty and v:FindFirstChild("Amount") and v.Amount:IsA("IntValue") then qty = v.Amount.Value end
                safeAdd(v.Name, qty)
            end
        end

        -- 5) Workspace drops (optional)
        local drops = workspace:FindFirstChild("DroppedItems") or workspace:FindFirstChild("Drops")
        if drops then
            for _, v in ipairs(drops:GetChildren()) do
                local qty = nil
                if v.GetAttribute and v:GetAttribute("Quantity") then qty = v:GetAttribute("Quantity") end
                safeAdd(v.Name, qty)
            end
        end

        -- 6) fallback sample
        if added == 0 then
            for i = 1, 6 do
                safeAdd("Item" .. i, 1)
            end
        end

        -- resize canvas after UI update
        spawn(function()
            wait()
            itemList.CanvasSize = UDim2.new(0, 0, 0, uiLayout.AbsoluteContentSize.Y)
            PlayerStatus("Inventory synced: " .. tostring(added))
        end)
    end

    syncBtn.Activated:Connect(function()
        syncInventory()
    end)

    send.Activated:Connect(function()
        local recip = usernameBox.Text
        local selectedList = {}
        for _, child in ipairs(itemList:GetChildren()) do
            if child:IsA("TextButton") and child:GetAttribute("Selected") then
                table.insert(selectedList, {name = child.Name, qty = child:GetAttribute("Quantity")})
            end
        end
        if #selectedList == 0 then
            PlayerStatus("No items selected")
            return
        end
        local summary = "Send to: " .. tostring(recip) .. "\nItems:\n"
        for _, it in ipairs(selectedList) do
            summary = summary .. "- " .. tostring(it.name)
            if it.qty then summary = summary .. " x" .. tostring(it.qty) end
            summary = summary .. "\n"
        end
        confirmLabel.Text = summary
        confirmFrame.Visible = true
    end)

    confirmBtn.Activated:Connect(function()
        confirmFrame.Visible = false
        local recip = usernameBox.Text
        local count = 0
        for _, child in ipairs(itemList:GetChildren()) do
            if child:IsA("TextButton") and child:GetAttribute("Selected") then
                count = count + 1
            end
        end
        PlayerStatus("Confirmed send: " .. tostring(recip) .. " items=" .. tostring(count))
        AutoGiftMail(recip, count)
    end)

    cancelBtn.Activated:Connect(function()
        confirmFrame.Visible = false
    end)

    -- finalize
    spawn(function()
        wait()
        itemList.CanvasSize = UDim2.new(0, 0, 0, uiLayout.AbsoluteContentSize.Y)
    end)

    screen.Parent = PlayerGui
end
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
    local container = findGui(uiPath.ItemList)
    if not container then
        return itemCount
    end

    local selected = {}
    for _, child in ipairs(container:GetDescendants()) do
        if child:IsA("TextButton") and child.GetAttribute and child:GetAttribute("Selected") then
            table.insert(selected, child)
        end
    end

    if #selected == 0 then
        return itemCount
    end

    for _, button in ipairs(selected) do
        if itemCount <= 0 then break end
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
        PlayerStatus("Mail menu open failed")
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

-- ensure UI exists when starting
local function EnsureUI()
    pcall(createMailGui)
end

EnsureUI()

-- Expose a top-level SyncInventory function that triggers UI sync
local function SyncInventory()
    EnsureUI()
    local screen = PlayerGui:FindFirstChild("MailGui")
    if not screen then return false end
    local syncBtn = screen:FindFirstChild("MainFrame") and screen.MainFrame:FindFirstChild("SyncInventory")
    if syncBtn and syncBtn.Activated then
        pcall(function() syncBtn:Activate() end)
        return true
    end
    return false
end

return {
    Start = Start,
    AutoGiftMail = AutoGiftMail,
    SyncInventory = SyncInventory,
    settings = settings,
}
