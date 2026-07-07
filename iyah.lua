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

local function categorizeItem(name)
    local lower = string.lower(name)
    if lower:find("seed") then
        return "Seeds"
    end
    if lower:find("watering") or lower:find("shovel") or lower:find("fertilizer") or lower:find("harvester") or lower:find("auto") or lower:find("can") then
        return "Gear"
    end
    if lower:find("dragon") or lower:find("raccoon") or lower:find("unicorn") or lower:find("slime") or lower:find("dog") or lower:find("cat") or lower:find("moon") or lower:find("fly") or lower:find("snake") then
        return "Pets"
    end
    return "Other"
end

local function createMailGui()
    if PlayerGui:FindFirstChild("MailGui") then
        return
    end

    local screen = Instance.new("ScreenGui")
    screen.Name = "MailGui"
    screen.ResetOnSpawn = false

    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(0, 340, 0, 380)
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
    usernameBox.Size = UDim2.new(0.9, 0, 0, 28)
    usernameBox.Position = UDim2.new(0.05, 0, 0, 40)
    usernameBox.BackgroundColor3 = Color3.fromRGB(50,50,55)
    usernameBox.TextColor3 = Color3.fromRGB(240,240,240)
    usernameBox.Text = tostring(settings.AutoMail.username)
    usernameBox.ClearTextOnFocus = false
    usernameBox.Parent = frame

    local quantityBox = Instance.new("TextBox")
    quantityBox.Name = "QuantityBox"
    quantityBox.PlaceholderText = "Jumlah item"
    quantityBox.Size = UDim2.new(0.9, 0, 0, 28)
    quantityBox.Position = UDim2.new(0.05, 0, 0, 76)
    quantityBox.BackgroundColor3 = Color3.fromRGB(50,50,55)
    quantityBox.TextColor3 = Color3.fromRGB(240,240,240)
    quantityBox.Text = tostring(settings.AutoMail.itemcount)
    quantityBox.ClearTextOnFocus = false
    quantityBox.Parent = frame

    local categoryLabel = Instance.new("TextLabel")
    categoryLabel.Name = "CategoryLabel"
    categoryLabel.Size = UDim2.new(0.9, 0, 0, 20)
    categoryLabel.Position = UDim2.new(0.05, 0, 0, 112)
    categoryLabel.BackgroundTransparency = 1
    categoryLabel.Text = "Filter kategori:"
    categoryLabel.TextColor3 = Color3.fromRGB(200,200,200)
    categoryLabel.Font = Enum.Font.Gotham
    categoryLabel.TextSize = 12
    categoryLabel.TextXAlignment = Enum.TextXAlignment.Left
    categoryLabel.Parent = frame

    local itemList = Instance.new("ScrollingFrame")
    itemList.Name = "ItemList"
    itemList.Size = UDim2.new(0.9, 0, 0, 170)
    itemList.Position = UDim2.new(0.05, 0, 0, 160)
    itemList.CanvasSize = UDim2.new(0, 0, 0, 0)
    itemList.ScrollBarThickness = 6
    itemList.BackgroundColor3 = Color3.fromRGB(40,40,40)
    itemList.Parent = frame

    local selectedLabel = Instance.new("TextLabel")
    selectedLabel.Name = "SelectedLabel"
    selectedLabel.Size = UDim2.new(0.9, 0, 0, 18)
    selectedLabel.Position = UDim2.new(0.05, 0, 0, 334)
    selectedLabel.BackgroundTransparency = 1
    selectedLabel.Text = "Selected items: 0 | Qty: 0"
    selectedLabel.TextColor3 = Color3.fromRGB(220,220,220)
    selectedLabel.Font = Enum.Font.Gotham
    selectedLabel.TextSize = 12
    selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
    selectedLabel.Parent = frame

    local uiLayout = Instance.new("UIListLayout")
    uiLayout.Parent = itemList
    uiLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiLayout.Padding = UDim.new(0, 6)

    local currentCategory = "All"
    local categories = {"All", "Seeds", "Gear", "Pets", "Other"}
    local function updateItemVisibility()
        for _, itemButton in ipairs(itemList:GetChildren()) do
            if itemButton:IsA("TextButton") then
                local category = itemButton:GetAttribute("Category") or "Other"
                itemButton.Visible = (currentCategory == "All") or (category == currentCategory)
            end
        end
    end

    local function formatItemLabel(label, quantity, category)
        local result = label or ""
        if quantity and tonumber(quantity) then
            result = result .. " x" .. tostring(quantity)
        end
        result = result .. " [" .. category .. "]"
        return result
    end

    local function addItem(name, label, quantity)
        local category = categorizeItem(name)
        local b = Instance.new("TextButton")
        b.Name = name
        b.Size = UDim2.new(1, -10, 0, 30)
        b.Text = formatItemLabel(label or name, quantity, category)
        b.AutoButtonColor = true
        b.BackgroundColor3 = Color3.fromRGB(60,60,60)
        b.TextColor3 = Color3.fromRGB(240,240,240)
        b.Parent = itemList
        b:SetAttribute("Selected", false)
        b:SetAttribute("Category", category)
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
            if selectedLabel then
                local selectedCount = 0
                local totalQty = 0
                for _, child in ipairs(itemList:GetChildren()) do
                    if child:IsA("TextButton") and child:GetAttribute("Selected") then
                        selectedCount = selectedCount + 1
                        local qty = tonumber(child:GetAttribute("Quantity")) or 1
                        totalQty = totalQty + qty
                    end
                end
                selectedLabel.Text = "Selected items: " .. tostring(selectedCount) .. " | Qty: " .. tostring(totalQty)
            end
        end)
        return b
    end

    local categoryButtons = {}
    for index, categoryName in ipairs(categories) do
        local catBtn = Instance.new("TextButton")
        catBtn.Name = categoryName .. "Button"
        catBtn.Size = UDim2.new(0, 60, 0, 24)
        catBtn.Position = UDim2.new(0, 10 + ((index - 1) * 66), 0, 34)
        catBtn.BackgroundColor3 = Color3.fromRGB(45,45,50)
        catBtn.TextColor3 = Color3.fromRGB(220,220,220)
        catBtn.Text = categoryName
        catBtn.Font = Enum.Font.Gotham
        catBtn.TextSize = 12
        catBtn.Parent = frame
        Instance.new("UICorner", catBtn).CornerRadius = UDim.new(0, 6)

        catBtn.Activated:Connect(function()
            currentCategory = categoryName
            updateItemVisibility()
            for _, otherBtn in ipairs(categoryButtons) do
                otherBtn.BackgroundColor3 = (otherBtn == catBtn) and Color3.fromRGB(78, 132, 173) or Color3.fromRGB(45,45,50)
            end
        end)
        table.insert(categoryButtons, catBtn)
    end

    categoryButtons[1].BackgroundColor3 = Color3.fromRGB(78,132,173)
    categoryButtons[1].TextColor3 = Color3.fromRGB(255,255,255)

    -- sample items for testing (will be replaced by SyncInventory)
    for i = 1, 6 do
        addItem("Item" .. i, "Item " .. i)
    end

    -- small control buttons
    local selectAll = Instance.new("TextButton")
    selectAll.Name = "SelectAll"
    selectAll.Size = UDim2.new(0.2, 0, 0, 28)
    selectAll.Position = UDim2.new(0.05, 0, 0.86, 0)
    selectAll.Text = "Select All"
    selectAll.Parent = frame

    local clearSel = Instance.new("TextButton")
    clearSel.Name = "ClearSelection"
    clearSel.Size = UDim2.new(0.2, 0, 0, 28)
    clearSel.Position = UDim2.new(0.27, 0, 0.86, 0)
    clearSel.Text = "Clear"
    clearSel.Parent = frame

    local autoBtn = Instance.new("TextButton")
    autoBtn.Name = "AutoGiftButton"
    autoBtn.Size = UDim2.new(0.2, 0, 0, 28)
    autoBtn.Position = UDim2.new(0.49, 0, 0.86, 0)
    autoBtn.Text = "Auto Gift"
    autoBtn.BackgroundColor3 = Color3.fromRGB(90, 135, 90)
    autoBtn.TextColor3 = Color3.fromRGB(240,240,240)
    autoBtn.Parent = frame

    local send = Instance.new("TextButton")
    send.Name = "SendButton"
    send.Size = UDim2.new(0.2, 0, 0, 28)
    send.Position = UDim2.new(0.71, 0, 0.86, 0)
    send.Text = "Send"
    send.Parent = frame

    local syncBtn = Instance.new("TextButton")
    syncBtn.Name = "SyncInventory"
    syncBtn.Size = UDim2.new(0.9, 0, 0, 28)
    syncBtn.Position = UDim2.new(0.05, 0, 0.93, 0)
    syncBtn.Text = "Sync Inventory"
    syncBtn.Parent = frame

    local mailButton = Instance.new("TextButton")
    mailButton.Name = "MailButton"
    mailButton.Size = UDim2.new(0, 80, 0, 30)
    mailButton.Position = UDim2.new(0, 8, 0, 8)
    mailButton.Text = "Mail"
    -- parent set at end to allow integration with existing hack GUI if present

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
        local selectedCount, totalQty = 0, 0
        for _, child in ipairs(itemList:GetChildren()) do
            if child:IsA("TextButton") then
                child:SetAttribute("Selected", true)
                child.BackgroundColor3 = Color3.fromRGB(80,140,80)
                selectedCount = selectedCount + 1
                totalQty = totalQty + (tonumber(child:GetAttribute("Quantity")) or 1)
            end
        end
        selectedLabel.Text = "Selected items: " .. tostring(selectedCount) .. " | Qty: " .. tostring(totalQty)
    end)

    clearSel.Activated:Connect(function()
        for _, child in ipairs(itemList:GetChildren()) do
            if child:IsA("TextButton") then
                child:SetAttribute("Selected", false)
                child.BackgroundColor3 = Color3.fromRGB(60,60,60)
            end
        end
        selectedLabel.Text = "Selected items: 0 | Qty: 0"
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
            updateItemVisibility()
            selectedLabel.Text = "Selected items: 0 | Qty: 0"
            PlayerStatus("Inventory synced: " .. tostring(added))
        end)
    end

    syncBtn.Activated:Connect(function()
        syncInventory()
    end)

    autoBtn.Activated:Connect(function()
        local recip = usernameBox.Text
        local targetCount = tonumber(quantityBox.Text) or 1
        if recip == "" then
            PlayerStatus("Masukkan username penerima terlebih dahulu")
            return
        end
        if targetCount <= 0 then
            PlayerStatus("Jumlah item harus lebih besar dari 0")
            return
        end

        local selectedCount = 0
        local totalQty = 0
        for _, child in ipairs(itemList:GetChildren()) do
            if child:IsA("TextButton") and child:GetAttribute("Selected") then
                selectedCount = selectedCount + 1
                totalQty = totalQty + (tonumber(child:GetAttribute("Quantity")) or 1)
            end
        end
        if selectedCount == 0 then
            PlayerStatus("Tidak ada item terpilih untuk auto gift")
            return
        end

        local sendCount = math.min(targetCount, totalQty)
        PlayerStatus("Auto Gift started: " .. tostring(recip) .. " | Selected: " .. tostring(selectedCount) .. " | Send Qty: " .. tostring(sendCount))
        AutoGiftMail(recip, sendCount)
    end)

    send.Activated:Connect(function()
        local recip = usernameBox.Text
        local selectedList = {}
        local totalQty = 0
        for _, child in ipairs(itemList:GetChildren()) do
            if child:IsA("TextButton") and child:GetAttribute("Selected") then
                local qty = tonumber(child:GetAttribute("Quantity")) or 1
                totalQty = totalQty + qty
                table.insert(selectedList, {name = child.Name, qty = qty})
            end
        end
        if #selectedList == 0 then
            PlayerStatus("No items selected")
            return
        end
        local summary = "Send to: " .. tostring(recip) .. "\nTotal Items: " .. tostring(#selectedList) .. "\nTotal Qty: " .. tostring(totalQty) .. "\nItems:\n"
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

    -- If a known external GUI exists (e.g. MainHackGUI), parent our mail UI there for integration
    local hackGui = PlayerGui:FindFirstChild("MainHackGUI") or PlayerGui:FindFirstChild("MainHack")
    if hackGui and hackGui:IsA("ScreenGui") then
        screen.Parent = hackGui
        -- try to attach the toggle button to the hack GUI's main frame if available
        local targetFrame = hackGui:FindFirstChild("MainFrame") or hackGui:FindFirstChildWhichIsA("Frame")
        if targetFrame then
            mailButton.Parent = targetFrame
            mailButton.Position = UDim2.new(0, 8, 0, 8)
        else
            mailButton.Parent = screen
        end
    else
        screen.Parent = PlayerGui
        mailButton.Parent = screen
    end
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
