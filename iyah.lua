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
        username = "Ceszganteng",
        itemcount = 20,
    },
    Settings = {
        MoveSpeed = 16,
    },
}

local uiPath = {
    MailButton = {"MailGui", "MailButton"},
    UsernameBox = {"MailGui", "MainFrame", "UsernameBox"},
    ItemList = {"MailGui", "MainFrame", "ItemList"},
    SendButton = {"MailGui", "MainFrame", "SendButton"},
}

local SEED_DATABASE = {
    "Tulip", "Tomato", "Apple", "Bamboo", "Corn", "Cactus", "Pineapple", "Mushroom",
    "Green Bean", "Banana", "Grape", "Coconut", "Mango", "Dragon Fruit", "Acorn",
    "Cherry", "Sunflower", "Venus Fly Trap", "Pomegranate", "Poison Apple",
    "Venom Spitter", "Moon Bloom", "Hypno Bloom", "Dragon's Breath"
}

local PET_DATABASE = {
    "Big Rainbow Raccoon", "Mega Rainbow Bee", "Mega Rainbow Robin", "Mega Rainbow Turtle",
    "Mega Rainbow Unicorn", "Mega Raccoon", "Mega Golden Dragonfly", "Mega Bear",
    "Mega Rainbow Frog", "Mega Unicorn", "Rainbow Bear", "Mega Rainbow Deer",
    "Mega Rainbow Bunny", "Big Rainbow Robin", "Rainbow Monkey", "Big Rainbow Bee",
    "Rainbow Raccoon", "Mega Black Dragon", "Big Rainbow Black Dragon", "Mega Rainbow Black Dragon",
    "Big Rainbow Turtle", "Rainbow Unicorn", "Mega Rainbow Ice Serpent", "Big Raccoon",
    "Mega Ice Serpent", "Big Rainbow Owl", "Rainbow Golden Dragonfly", "Big Rainbow Ice Serpent",
    "Big Bear", "Big Monkey", "Big Rainbow Deer"
}

local GEAR_DATABASE = {
    "Common Watering Can", "Common Sprinkler", "Sign", "Uncommon Sprinkler", "Trowel",
    "Rare Sprinkler", "Jump Mushroom", "Speed Mushroom", "Lantern", "Megaphone",
    "Shrink Mushroom", "Supersize Mushroom", "Gnome", "Flashbang", "Basic Pot",
    "Legendary Sprinkler", "Invisibility Mushroom", "Teleporter", "Wheelbarrow",
    "Strawberry Sniper", "Player Magnet", "Super Watering Can", "Super Sprinkler"
}

local function categorizeItem(name)
    local lower = string.lower(name)
    local seedTerms = {
        "seed", "sapling", "sprout", "plant", "berry", "bean", "melon", "pumpkin", "carrot",
        "potato", "corn", "wheat", "flower", "leaf", "grass", "tree", "root", "vine",
        "tulip", "tomato", "apple", "bamboo", "cactus", "pineapple", "mushroom", "banana",
        "grape", "coconut", "mango", "dragon fruit", "acorn", "cherry", "sunflower",
        "venus fly trap", "pomegranate", "poison apple", "poison", "venom spitter", "moon bloom",
        "hypno bloom", "dragon's breath"
    }
    local gearTerms = {
        "watering", "shovel", "fertilizer", "harvester", "auto", "can", "hoe", "bucket",
        "sprayer", "net", "glove", "scissors", "tractor", "cart", "hammer", "crate", "tool",
        "sprinkler", "sign", "trowel", "lantern", "megaphone", "mushroom", "pot", "teleporter",
        "wheelbarrow", "sniper", "magnet"
    }
    local petTerms = {
        "dragon", "raccoon", "unicorn", "slime", "dog", "cat", "owl", "fox", "bunny",
        "rabbit", "wolf", "bear", "panda", "phoenix", "griffin", "fairy", "horse", "snake",
        "turtle", "penguin", "koala", "dino", "kitty", "puppy", "blob", "critter", "bee",
        "robin", "frog", "monkey", "deer", "dragonfly"
    }

    for _, term in ipairs(seedTerms) do
        if lower:find(term, 1, true) then
            return "Seeds"
        end
    end

    for _, term in ipairs(gearTerms) do
        if lower:find(term, 1, true) then
            return "Gear"
        end
    end

    for _, term in ipairs(petTerms) do
        if lower:find(term, 1, true) then
            return "Pets"
        end
    end

    return "Other"
end

local syncInventoryFunction

local function createMailGui()
    if PlayerGui:FindFirstChild("MailGui") then
        return
    end

    local screen = Instance.new("ScreenGui")
    screen.Name = "MailGui"
    screen.ResetOnSpawn = false

    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(0, 420, 0, 300)
    frame.Position = UDim2.new(0.5, -210, 0.12, 0)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
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

    local categoryButtonsFrame = Instance.new("Frame")
    categoryButtonsFrame.Name = "CategoryButtonsFrame"
    categoryButtonsFrame.Size = UDim2.new(0.9, 0, 0, 32)
    categoryButtonsFrame.Position = UDim2.new(0.05, 0, 0.10, 0)
    categoryButtonsFrame.BackgroundTransparency = 1
    categoryButtonsFrame.Parent = frame

    local itemList = Instance.new("ScrollingFrame")
    itemList.Name = "ItemList"
    itemList.Size = UDim2.new(0.9, 0, 0, 120)
    itemList.Position = UDim2.new(0.05, 0, 0.18, 0)
    itemList.CanvasSize = UDim2.new(0, 0, 0, 0)
    itemList.ScrollBarThickness = 6
    itemList.BackgroundColor3 = Color3.fromRGB(40,40,40)
    itemList.Parent = frame

    local usernameBox = Instance.new("TextBox")
    usernameBox.Name = "UsernameBox"
    usernameBox.PlaceholderText = "Recipient Username"
    usernameBox.Size = UDim2.new(0.63, 0, 0, 28)
    usernameBox.Position = UDim2.new(0.05, 0, 0.62, 0)
    usernameBox.BackgroundColor3 = Color3.fromRGB(50,50,55)
    usernameBox.TextColor3 = Color3.fromRGB(240,240,240)
    usernameBox.Text = tostring(settings.AutoMail.username)
    usernameBox.ClearTextOnFocus = false
    usernameBox.Parent = frame

    local quantityBox = Instance.new("TextBox")
    quantityBox.Name = "QuantityBox"
    quantityBox.PlaceholderText = "Jumlah item"
    quantityBox.Size = UDim2.new(0.27, 0, 0, 28)
    quantityBox.Position = UDim2.new(0.70, 0, 0.62, 0)
    quantityBox.BackgroundColor3 = Color3.fromRGB(50,50,55)
    quantityBox.TextColor3 = Color3.fromRGB(240,240,240)
    quantityBox.Text = tostring(settings.AutoMail.itemcount)
    quantityBox.ClearTextOnFocus = false
    quantityBox.Parent = frame

    local selectedLabel = Instance.new("TextLabel")
    selectedLabel.Name = "SelectedLabel"
    selectedLabel.Size = UDim2.new(0.9, 0, 0, 18)
    selectedLabel.Position = UDim2.new(0.05, 0, 0.56, 0)
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

    local selectedCategory = "All"
    local categoryNames = {"All", "Seeds", "Gear", "Pets"}

    local function updateSelectedStats()
        local selectedCount, totalQty = 0, 0
        for _, child in ipairs(itemList:GetChildren()) do
            if child:IsA("TextButton") and child:GetAttribute("Selected") then
                selectedCount = selectedCount + 1
                totalQty = totalQty + (tonumber(child:GetAttribute("Quantity")) or 1)
            end
        end
        selectedLabel.Text = "Selected items: " .. tostring(selectedCount) .. " | Qty: " .. tostring(totalQty)
    end

    local function updateItemVisibility()
        for _, itemButton in ipairs(itemList:GetChildren()) do
            if itemButton:IsA("TextButton") then
                local category = itemButton:GetAttribute("Category") or "Other"
                itemButton.Visible = (selectedCategory == "All") or (category == selectedCategory)
            end
        end
    end

    local function formatItemLabel(label, quantity, category)
        local result = label or ""
        if quantity and tonumber(quantity) and tonumber(quantity) > 1 then
            result = result .. " (" .. tostring(quantity) .. ")"
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
        b.TextSize = 10
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
            updateSelectedStats()
        end)
        return b
    end

    local function selectCategoryItems(category, selected)
        for _, child in ipairs(itemList:GetChildren()) do
            if child:IsA("TextButton") then
                local cat = child:GetAttribute("Category") or "Other"
                if category == "All" or cat == category then
                    child:SetAttribute("Selected", selected)
                    child.BackgroundColor3 = selected and Color3.fromRGB(80,140,80) or Color3.fromRGB(60,60,60)
                end
            end
        end
        updateSelectedStats()
    end

    local categoryButtons = {}
    for index, categoryName in ipairs(categoryNames) do
        local catBtn = Instance.new("TextButton")
        catBtn.Name = categoryName .. "FilterBtn"
        catBtn.Size = UDim2.new(0, 58, 0, 24)
        catBtn.Position = UDim2.new(0.05 + ((index - 1) * 0.16), 0, 0, 0)
        catBtn.BackgroundColor3 = Color3.fromRGB(45,45,50)
        catBtn.TextColor3 = Color3.fromRGB(220,220,220)
        catBtn.Text = categoryName
        catBtn.Font = Enum.Font.Gotham
        catBtn.TextSize = 10
        catBtn.Parent = categoryButtonsFrame
        Instance.new("UICorner", catBtn).CornerRadius = UDim.new(0, 6)

        catBtn.Activated:Connect(function()
            selectedCategory = categoryName
            updateItemVisibility()
            for _, otherBtn in ipairs(categoryButtons) do
                otherBtn.BackgroundColor3 = (otherBtn == catBtn) and Color3.fromRGB(78,132,173) or Color3.fromRGB(45,45,50)
                otherBtn.TextColor3 = (otherBtn == catBtn) and Color3.fromRGB(255,255,255) or Color3.fromRGB(220,220,220)
            end
        end)
        table.insert(categoryButtons, catBtn)
    end

    categoryButtons[1].BackgroundColor3 = Color3.fromRGB(78,132,173)
    categoryButtons[1].TextColor3 = Color3.fromRGB(255,255,255)

    -- initial inventory will populate automatically from player containers

    -- small control buttons
    local selectAll = Instance.new("TextButton")
    selectAll.Name = "SelectAll"
    selectAll.Size = UDim2.new(0.28, 0, 0, 26)
    selectAll.Position = UDim2.new(0.05, 0, 0.66, 0)
    selectAll.Text = "Select All"
    selectAll.BackgroundColor3 = Color3.fromRGB(55,55,60)
    selectAll.TextColor3 = Color3.fromRGB(240,240,240)
    selectAll.Font = Enum.Font.Gotham
    selectAll.TextSize = 12
    selectAll.Parent = frame
    Instance.new("UICorner", selectAll).CornerRadius = UDim.new(0, 6)

    local clearSel = Instance.new("TextButton")
    clearSel.Name = "ClearSelection"
    clearSel.Size = UDim2.new(0.28, 0, 0, 26)
    clearSel.Position = UDim2.new(0.37, 0, 0.66, 0)
    clearSel.Text = "Clear"
    clearSel.BackgroundColor3 = Color3.fromRGB(55,55,60)
    clearSel.TextColor3 = Color3.fromRGB(240,240,240)
    clearSel.Font = Enum.Font.Gotham
    clearSel.TextSize = 12
    clearSel.Parent = frame
    Instance.new("UICorner", clearSel).CornerRadius = UDim.new(0, 6)

    local send = Instance.new("TextButton")
    send.Name = "SendButton"
    send.Size = UDim2.new(0.45, 0, 0, 26)
    send.Position = UDim2.new(0.05, 0, 0.76, 0)
    send.Text = "Send Gift"
    send.BackgroundColor3 = Color3.fromRGB(60,120,180)
    send.TextColor3 = Color3.fromRGB(240,240,240)
    send.Font = Enum.Font.Gotham
    send.TextSize = 12
    send.Parent = frame
    Instance.new("UICorner", send).CornerRadius = UDim.new(0, 6)

    local autoBtn = Instance.new("TextButton")
    autoBtn.Name = "AutoGiftButton"
    autoBtn.Size = UDim2.new(0.45, 0, 0, 26)
    autoBtn.Position = UDim2.new(0.5, 0, 0.76, 0)
    autoBtn.Text = "Auto Gift OFF"
    autoBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 80)
    autoBtn.TextColor3 = Color3.fromRGB(240,240,240)
    autoBtn.Font = Enum.Font.Gotham
    autoBtn.TextSize = 12
    autoBtn.Parent = frame
    Instance.new("UICorner", autoBtn).CornerRadius = UDim.new(0, 6)

    local mailButton = Instance.new("TextButton")
    mailButton.Name = "MailButton"
    mailButton.Size = UDim2.new(0, 80, 0, 30)
    mailButton.Position = UDim2.new(0, 8, 0, 8)
    mailButton.Text = "Mail"
    -- parent set at end to allow integration with existing hack GUI if present

    mailButton.Activated:Connect(function()
        frame.Visible = not frame.Visible
        if frame.Visible then
            syncInventory()
        end
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
        selectCategoryItems(selectedCategory, true)
    end)

    clearSel.Activated:Connect(function()
        selectCategoryItems("All", false)
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

        local inventoryMap = {}
        local function addInventoryItem(name, quantity)
            if not name or name == "" then return end
            local qty = tonumber(quantity) or 1
            inventoryMap[name] = (inventoryMap[name] or 0) + qty
        end

        local function getObjectName(v)
            if v:IsA("StringValue") then
                return v.Value or v.Name
            end
            if v:IsA("Folder") or v:IsA("Tool") or v:IsA("Model") then
                return v.Name
            end
            if v:IsA("TextLabel") or v:IsA("TextButton") then
                return v.Text
            end
            return v.Name
        end

        local function getObjectQuantity(v)
            if v.GetAttribute then
                local q = v:GetAttribute("Quantity") or v:GetAttribute("Amount") or v:GetAttribute("Count")
                if tonumber(q) then return tonumber(q) end
            end
            if v:FindFirstChild("Quantity") and v.Quantity:IsA("IntValue") then
                return v.Quantity.Value
            end
            if v:FindFirstChild("Amount") and v.Amount:IsA("IntValue") then
                return v.Amount.Value
            end
            if v:FindFirstChild("Count") and v.Count:IsA("IntValue") then
                return v.Count.Value
            end
            if v:IsA("IntValue") or v:IsA("NumberValue") then
                return v.Value
            end
            return 1
        end

        local added = 0

        local function scanContainer(container)
            if not container then return end
            for _, v in ipairs(container:GetDescendants()) do
                if v:IsA("Instance") then
                    local name = getObjectName(v)
                    local qty = getObjectQuantity(v)
                    addInventoryItem(name, qty)
                end
            end
        end

        -- 1) Backpack (tools)
        scanContainer(LocalPlayer:FindFirstChild("Backpack"))

        -- 2) Character (equipped tools)
        scanContainer(LocalPlayer.Character)

        -- 3) Common inventory containers on player
        scanContainer(LocalPlayer:FindFirstChild("Inventory") or LocalPlayer:FindFirstChild("_Inventory") or LocalPlayer:FindFirstChild("Items"))

        -- 4) ReplicatedStorage / Server storage variants
        scanContainer(game:GetService("ReplicatedStorage"):FindFirstChild("Inventory") or game:GetService("ReplicatedStorage"):FindFirstChild("Items") or game:GetService("ReplicatedStorage"):FindFirstChild("Shop"))

        -- 5) Workspace drops (optional)
        scanContainer(workspace:FindFirstChild("DroppedItems") or workspace:FindFirstChild("Drops"))

        -- 6) fallback sample
        if next(inventoryMap) == nil then
            inventoryMap["Item1"] = 1
            inventoryMap["Item2"] = 1
            inventoryMap["Item3"] = 1
        end

        for name, qty in pairs(inventoryMap) do
            addItem(name, name, qty)
            added = added + 1
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

    syncInventoryFunction = syncInventory

    local autoGiftEnabled = false
    local autoGiftRunning = false

    local function updateAutoButton()
        autoBtn.Text = autoGiftEnabled and "Auto Gift ON" or "Auto Gift OFF"
        autoBtn.BackgroundColor3 = autoGiftEnabled and Color3.fromRGB(90, 135, 90) or Color3.fromRGB(180, 80, 80)
    end

    local function getSelectedItems()
        local selectedItems = {}
        for _, child in ipairs(itemList:GetChildren()) do
            if child:IsA("TextButton") and child:GetAttribute("Selected") then
                table.insert(selectedItems, {
                    name = child.Name,
                    qty = tonumber(child:GetAttribute("Quantity")) or 1,
                    category = child:GetAttribute("Category") or "Other"
                })
            end
        end
        return selectedItems
    end

    local function autoGiftLoop()
        if autoGiftRunning then return end
        autoGiftRunning = true
        spawn(function()
            while autoGiftEnabled do
                local recip = usernameBox.Text
                local targetCount = tonumber(quantityBox.Text) or 1
                local selectedItems = getSelectedItems()
                local totalQty = 0
                for _, item in ipairs(selectedItems) do
                    totalQty = totalQty + item.qty
                end

                if recip == "" then
                    PlayerStatus("Auto Gift stopped: recipient username kosong")
                    autoGiftEnabled = false
                    updateAutoButton()
                    break
                end

                if totalQty <= 0 then
                    PlayerStatus("Auto Gift stopped: tidak ada item terpilih")
                    autoGiftEnabled = false
                    updateAutoButton()
                    break
                end

                local sendCount = math.min(targetCount, totalQty)
                PlayerStatus("Auto Gift loop sending " .. tostring(sendCount) .. " qty to " .. tostring(recip))
                if not AutoGiftMail(recip, sendCount) then
                    PlayerStatus("Auto Gift gagal")
                    autoGiftEnabled = false
                    updateAutoButton()
                    break
                end

                wait(3)
            end
            autoGiftRunning = false
        end)
    end

    autoBtn.Activated:Connect(function()
        autoGiftEnabled = not autoGiftEnabled
        updateAutoButton()
        if autoGiftEnabled then
            autoGiftLoop()
        end
    end)

    send.Activated:Connect(function()
        local recip = usernameBox.Text
        if recip == "" then
            PlayerStatus("Masukkan username penerima terlebih dahulu")
            return
        end
        local selectedList = getSelectedItems()
        local totalQty = 0
        for _, it in ipairs(selectedList) do
            totalQty = totalQty + it.qty
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
        local totalQty = 0
        for _, child in ipairs(itemList:GetChildren()) do
            if child:IsA("TextButton") and child:GetAttribute("Selected") then
                totalQty = totalQty + (tonumber(child:GetAttribute("Quantity")) or 1)
            end
        end
        PlayerStatus("Confirmed send: " .. tostring(recip) .. " qty=" .. tostring(totalQty))
        AutoGiftMail(recip, totalQty)
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

    -- load current inventory automatically
    syncInventory()
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

local function clearSelectedItems()
    local container = findGui(uiPath.ItemList)
    if not container then
        return
    end
    for _, child in ipairs(container:GetDescendants()) do
        if child:IsA("TextButton") and child:GetAttribute("Selected") then
            child:SetAttribute("Selected", false)
            child.BackgroundColor3 = Color3.fromRGB(60,60,60)
        end
    end
end

local function selectMailItems(itemCount)
    local container = findGui(uiPath.ItemList)
    if not container then
        return itemCount, false
    end

    local selected = {}
    for _, child in ipairs(container:GetDescendants()) do
        if child:IsA("TextButton") and child:GetAttribute("Selected") then
            table.insert(selected, child)
        end
    end

    if #selected == 0 then
        return itemCount, false
    end

    local used = false
    for _, button in ipairs(selected) do
        if itemCount <= 0 then break end
        local qty = tonumber(button:GetAttribute("Quantity")) or 1
        if activateButton(button) then
            itemCount = itemCount - qty
            used = true
            sleep(0.05)
        end
    end

    return math.max(itemCount, 0), used
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
        local remaining, used = selectMailItems(itemCount)
        if not used then
            PlayerStatus("No mail items selected")
            return false
        end

        itemCount = remaining
        if not clickSendMail() then
            PlayerStatus("Send button not found")
            return false
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

local function SyncInventory()
    EnsureUI()
    if syncInventoryFunction then
        syncInventoryFunction()
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
