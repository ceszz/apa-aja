-- Roblox exploit-friendly Auto Gift Mail script for Grow A Garden 2
-- Script dioptimalkan untuk deteksi inventory dan mail UI.

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

local function normalizeText(value)
    local text = tostring(value or "")
    text = text:gsub("%c", " ")
    text = text:gsub("%s+", " ")
    text = text:gsub("^%s*(.-)%s*$", "%1")
    return text
end

local function parseItemText(text)
    text = normalizeText(text)
    local name, qty = text:match("^(.-)%s*[xX]%s*(%d+)$")
    if not name then
        name, qty = text:match("^(.-)%s*%((%d+)%)$")
    end
    if not name or name == "" then
        name = text
    end
    return normalizeText(name), tonumber(qty) or 1
end

local function findKnownItemName(label)
    local lower = label:lower()
    for _, item in ipairs(SEED_DATABASE) do
        if lower:find(item:lower(), 1, true) then
            return item
        end
    end
    for _, item in ipairs(PET_DATABASE) do
        if lower:find(item:lower(), 1, true) then
            return item
        end
    end
    for _, item in ipairs(GEAR_DATABASE) do
        if lower:find(item:lower(), 1, true) then
            return item
        end
    end
    return label
end

local function categorizeItem(name)
    local lower = name:lower()
    local seedTerms = {
        "seed", "sapling", "sprout", "plant", "berry", "bean", "melon", "pumpkin", "carrot",
        "potato", "corn", "wheat", "flower", "leaf", "grass", "tree", "root", "vine",
        "tulip", "tomato", "apple", "bamboo", "cactus", "pineapple", "mushroom", "banana",
        "grape", "coconut", "mango", "dragon fruit", "acorn", "cherry", "sunflower",
        "venus fly trap", "pomegranate", "poison apple", "venom spitter", "moon bloom",
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

local function safeGetAttribute(instance, key)
    if not instance or not instance.GetAttribute then
        return nil
    end
    local ok, value = pcall(function()
        return instance:GetAttribute(key)
    end)
    if ok then
        return value
    end
    return nil
end

local function extractQuantity(instance)
    if not instance then
        return 1
    end
    local keys = {"Quantity", "Amount", "Count", "Stack", "StackSize", "Qty"}
    for _, key in ipairs(keys) do
        local attr = safeGetAttribute(instance, key)
        if tonumber(attr) then
            return tonumber(attr)
        end
        local child = instance:FindFirstChild(key)
        if child and (child:IsA("IntValue") or child:IsA("NumberValue")) then
            return child.Value
        end
    end
    if instance:IsA("IntValue") or instance:IsA("NumberValue") then
        return instance.Value
    end
    if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
        local _, qty = parseItemText(instance.Text)
        return qty
    end
    return 1
end

local function extractName(instance)
    if not instance then
        return ""
    end
    if instance:IsA("StringValue") then
        return normalizeText(instance.Value)
    end
    if instance:IsA("ObjectValue") then
        return normalizeText(instance.Name)
    end
    if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
        local txt = normalizeText(instance.Text)
        if txt ~= "" then
            local name, _ = parseItemText(txt)
            return normalizeText(name)
        end
    end
    local attr = safeGetAttribute(instance, "DisplayName") or safeGetAttribute(instance, "ItemName") or safeGetAttribute(instance, "Name")
    if attr and attr ~= "" then
        return normalizeText(attr)
    end
    return normalizeText(instance.Name)
end

local function isOwnGui(instance)
    local mailGui = PlayerGui:FindFirstChild("MailGui")
    return mailGui and instance and instance:IsDescendantOf(mailGui)
end

local function collectInventoryItems(outMap)
    local seen = {}
    local function add(name, qty)
        name = normalizeText(name)
        if name == "" then
            return
        end
        name = findKnownItemName(name)
        outMap[name] = (outMap[name] or 0) + (tonumber(qty) or 1)
    end
    local function scan(obj)
        if not obj or seen[obj] or isOwnGui(obj) then
            return
        end
        seen[obj] = true
        local name = extractName(obj)
        local qty = extractQuantity(obj)
        if name ~= "" and name:len() > 1 then
            add(name, qty)
        end
        for _, child in ipairs(obj:GetChildren()) do
            scan(child)
        end
    end
    local roots = {
        LocalPlayer:FindFirstChild("Backpack"),
        LocalPlayer:FindFirstChild("Inventory"),
        LocalPlayer:FindFirstChild("_Inventory"),
        LocalPlayer:FindFirstChild("StarterPack"),
        LocalPlayer:FindFirstChild("StarterGear"),
        LocalPlayer:FindFirstChild("Character"),
        game:GetService("ReplicatedStorage"),
        game:GetService("ServerStorage"),
    }
    local function isInventoryRoot(obj)
        if not obj or not obj.Name then
            return false
        end
        local lower = obj.Name:lower()
        local hints = {"backpack", "inventory", "items", "storage", "bag", "chest", "data", "box", "container", "holder"}
        for _, hint in ipairs(hints) do
            if lower:find(hint, 1, true) then
                return true
            end
        end
        return false
    end
    for _, root in ipairs(roots) do
        if root then
            if isInventoryRoot(root) then
                scan(root)
            end
            for _, child in ipairs(root:GetChildren()) do
                if isInventoryRoot(child) then
                    scan(child)
                end
            end
        end
    end
end

local function createMailGui()
    if PlayerGui:FindFirstChild("MailGui") then
        return
    end
    local screen = Instance.new("ScreenGui")
    screen.Name = "MailGui"
    screen.ResetOnSpawn = false
    screen.Parent = PlayerGui
    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(0, 460, 0, 340)
    frame.Position = UDim2.new(0.5, -230, 0.08, 0)
    frame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = screen
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 34)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Grow A Garden 2 - Mail Exploiter"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextColor3 = Color3.fromRGB(235, 235, 235)
    title.Parent = frame
    local categoryFrame = Instance.new("Frame")
    categoryFrame.Name = "CategoryFrame"
    categoryFrame.Size = UDim2.new(1, -16, 0, 34)
    categoryFrame.Position = UDim2.new(0, 8, 0, 44)
    categoryFrame.BackgroundTransparency = 1
    categoryFrame.Parent = frame
    local categoryNames = {"Seeds", "Gear", "Pets"}
    local selectedCategory = "Seeds"
    local categoryButtons = {}
    local function updateCategoryButtons()
        for _, btn in ipairs(categoryButtons) do
            local active = btn.Name == selectedCategory
            btn.BackgroundColor3 = active and Color3.fromRGB(88, 136, 186) or Color3.fromRGB(42, 42, 48)
            btn.TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(220, 220, 220)
        end
    end
    for index, name in ipairs(categoryNames) do
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(0, 82, 0, 30)
        btn.Position = UDim2.new(0, (index - 1) * 86, 0, 0)
        btn.BackgroundColor3 = Color3.fromRGB(42, 42, 48)
        btn.TextColor3 = Color3.fromRGB(220, 220, 220)
        btn.Text = name
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 12
        btn.AutoButtonColor = true
        btn.Parent = categoryFrame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        btn.Activated:Connect(function()
            selectedCategory = name
            updateCategoryButtons()
            for _, child in ipairs(frame.ItemList:GetChildren()) do
                if child:IsA("TextButton") then
                    local category = child:GetAttribute("Category") or "Other"
                    child.Visible = category == selectedCategory
                end
            end
        end)
        table.insert(categoryButtons, btn)
    end
    updateCategoryButtons()
    local itemList = Instance.new("ScrollingFrame")
    itemList.Name = "ItemList"
    itemList.Size = UDim2.new(1, -16, 0, 170)
    itemList.Position = UDim2.new(0, 8, 0, 84)
    itemList.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
    itemList.BorderSizePixel = 0
    itemList.ScrollBarThickness = 6
    itemList.CanvasSize = UDim2.new(0, 0, 0, 0)
    itemList.Parent = frame
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = itemList
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 6)
    local usernameBox = Instance.new("TextBox")
    usernameBox.Name = "UsernameBox"
    usernameBox.PlaceholderText = "Recipient Username"
    usernameBox.Size = UDim2.new(0.6, 0, 0, 32)
    usernameBox.Position = UDim2.new(0, 8, 0, 266)
    usernameBox.BackgroundColor3 = Color3.fromRGB(52, 52, 58)
    usernameBox.TextColor3 = Color3.fromRGB(240, 240, 240)
    usernameBox.Text = settings.AutoMail.username
    usernameBox.ClearTextOnFocus = false
    usernameBox.Parent = frame
    local quantityBox = Instance.new("TextBox")
    quantityBox.Name = "QuantityBox"
    quantityBox.PlaceholderText = "Qty to send"
    quantityBox.Size = UDim2.new(0.28, 0, 0, 32)
    quantityBox.Position = UDim2.new(0.62, 0, 0, 266)
    quantityBox.BackgroundColor3 = Color3.fromRGB(52, 52, 58)
    quantityBox.TextColor3 = Color3.fromRGB(240, 240, 240)
    quantityBox.Text = tostring(settings.AutoMail.itemcount)
    quantityBox.ClearTextOnFocus = false
    quantityBox.Parent = frame
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, -16, 0, 22)
    statusLabel.Position = UDim2.new(0, 8, 0, 306)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Ready"
    statusLabel.TextColor3 = Color3.fromRGB(215, 215, 215)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 12
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = frame
    local function setStatus(text)
        statusLabel.Text = tostring(text)
        print("[GrowAGarden2 Mail] " .. tostring(text))
    end
    local function updateCanvas()
        itemList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end
    local function formatLabel(itemName, qty, category)
        local label = itemName
        if qty and qty > 1 then
            label = label .. " (" .. tostring(qty) .. ")"
        end
        label = label .. " [" .. tostring(category) .. "]"
        return label
    end
    local function addItemButton(itemName, qty)
        local category = categorizeItem(itemName)
        local btn = Instance.new("TextButton")
        btn.Name = itemName:gsub("%s+", "_")
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        btn.TextColor3 = Color3.fromRGB(235, 235, 235)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 12
        btn.AutoButtonColor = true
        btn.Text = formatLabel(itemName, qty, category)
        btn.Parent = itemList
        btn:SetAttribute("Selected", false)
        btn:SetAttribute("Category", category)
        btn:SetAttribute("Quantity", qty)
        btn.Activated:Connect(function()
            local selected = not btn:GetAttribute("Selected")
            btn:SetAttribute("Selected", selected)
            btn.BackgroundColor3 = selected and Color3.fromRGB(90, 150, 90) or Color3.fromRGB(60, 60, 60)
        end)
    end
    local function refreshInventory()
        for _, child in ipairs(itemList:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        local inventoryMap = {}
        collectInventoryItems(inventoryMap)
        local total = 0
        for itemName, qty in pairs(inventoryMap) do
            local category = categorizeItem(itemName)
            if category ~= "Other" then
                addItemButton(itemName, qty)
                total = total + 1
            end
        end
        updateCanvas()
        if total == 0 then
            setStatus("Inventory tidak terdeteksi. Tekan Sync Inventory setelah buka inventory.")
        else
            setStatus("Inventory terdeteksi: " .. tostring(total) .. " item")
        end
    end
    local function selectVisibleItems(select)
        for _, child in ipairs(itemList:GetChildren()) do
            if child:IsA("TextButton") then
                local category = child:GetAttribute("Category") or "Other"
                if category == selectedCategory then
                    child:SetAttribute("Selected", select)
                    child.BackgroundColor3 = select and Color3.fromRGB(90, 150, 90) or Color3.fromRGB(60, 60, 60)
                end
            end
        end
    end
    local function getSelectedItems()
        local selected = {}
        for _, child in ipairs(itemList:GetChildren()) do
            if child:IsA("TextButton") and child:GetAttribute("Selected") then
                table.insert(selected, {
                    name = extractName(child),
                    qty = tonumber(child:GetAttribute("Quantity")) or 1,
                })
            end
        end
        return selected
    end
    local function findButtonByHints(root, hints)
        for _, obj in ipairs(root:GetDescendants()) do
            if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                local label = normalizeText(obj.Text):lower()
                local name = obj.Name:lower()
                for _, hint in ipairs(hints) do
                    if label:find(hint, 1, true) or name:find(hint, 1, true) then
                        return obj
                    end
                end
            end
        end
        return nil
    end
    local function findTextBoxByHints(root, hints)
        for _, obj in ipairs(root:GetDescendants()) do
            if obj:IsA("TextBox") then
                local searchText = normalizeText((obj.PlaceholderText or "") .. " " .. obj.Name .. " " .. (obj.Text or "")):lower()
                for _, hint in ipairs(hints) do
                    if searchText:find(hint, 1, true) then
                        return obj
                    end
                end
            end
        end
        return nil
    end
    local function getMailSearchRoots()
        return {
            PlayerGui,
            game:GetService("CoreGui"),
            workspace,
            game:GetService("ReplicatedStorage"),
            game:GetService("ServerStorage"),
        }
    end
    local function findMailRoot()
        local hints = {"mail", "surat", "gift", "post", "parcel", "kirim"}
        for _, root in ipairs(getMailSearchRoots()) do
            if root then
                for _, obj in ipairs(root:GetDescendants()) do
                    if (obj:IsA("Frame") or obj:IsA("ScrollingFrame") or obj:IsA("ScreenGui")) and obj.Name:lower() ~= "mailgui" then
                        local name = obj.Name:lower()
                        for _, hint in ipairs(hints) do
                            if name:find(hint, 1, true) then
                                local btn = findButtonByHints(obj, {"send", "kirim", "post", "confirm", "ok", "submit"})
                                if btn then
                                    return obj
                                end
                            end
                        end
                    end
                end
            end
        end
        return nil
    end
    local function clickButton(button)
        if not button then
            return false
        end
        if button:IsA("TextButton") or button:IsA("ImageButton") then
            pcall(function()
                button:Activate()
            end)
            return true
        end
        return false
    end
    local function openMailMenu()
        local hints = {"mail", "surat", "post", "gift", "kirim hadiah", "open mail"}
        for _, root in ipairs(getMailSearchRoots()) do
            if root then
                local openBtn = findButtonByHints(root, hints)
                if openBtn then
                    return clickButton(openBtn)
                end
            end
        end
        return false
    end
    local function typeMailUsername(value)
        local root = findMailRoot() or PlayerGui
        local box = findTextBoxByHints(root, {"username", "recipient", "player", "to", "penerima", "nama"})
        if not box then
            return false
        end
        box.Text = tostring(value)
        pcall(function()
            box:ReleaseFocus()
        end)
        return true
    end
    local function clickMailItem(itemName)
        local root = findMailRoot() or PlayerGui
        local lowerName = itemName:lower()
        for _, obj in ipairs(root:GetDescendants()) do
            if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                local label = normalizeText(obj.Text ~= "" and obj.Text or obj.Name):lower()
                if label:find(lowerName, 1, true) then
                    if clickButton(obj) then
                        return true
                    end
                end
            end
        end
        return false
    end
    local function clickSendMailButton()
        local root = findMailRoot() or PlayerGui
        local btn = findButtonByHints(root, {"send", "kirim", "post", "submit", "ok", "confirm"})
        if btn then
            return clickButton(btn)
        end
        return false
    end
    local function sendByMail(recipient, maxQty)
        setStatus("Mencari menu mail...")
        if not openMailMenu() then
            setStatus("Tidak menemukan tombol mail")
            return false
        end
        task.wait(0.4)
        if not typeMailUsername(recipient) then
            setStatus("Kotak username mail tidak ditemukan")
            return false
        end
        task.wait(0.2)
        local selectedItems = getSelectedItems()
        if #selectedItems == 0 then
            setStatus("Tidak ada item terpilih")
            return false
        end
        local sent = 0
        for _, item in ipairs(selectedItems) do
            for i = 1, item.qty do
                if sent >= maxQty then
                    break
                end
                if clickMailItem(item.name) then
                    sent = sent + 1
                    task.wait(0.12)
                else
                    break
                end
            end
            if sent >= maxQty then
                break
            end
        end
        if sent == 0 then
            setStatus("Item tidak berhasil dipilih di mail")
            return false
        end
        if not clickSendMailButton() then
            setStatus("Tombol kirim mail tidak ditemukan")
            return false
        end
        setStatus("Mengirim " .. tostring(sent) .. " item ke " .. tostring(recipient))
        return true
    end
    local syncButton = Instance.new("TextButton")
    syncButton.Name = "SyncButton"
    syncButton.Size = UDim2.new(0.3, 0, 0, 32)
    syncButton.Position = UDim2.new(0, 8, 0, 266)
    syncButton.Text = "Sync Inventory"
    syncButton.BackgroundColor3 = Color3.fromRGB(78, 78, 88)
    syncButton.TextColor3 = Color3.fromRGB(245, 245, 245)
    syncButton.Font = Enum.Font.Gotham
    syncButton.TextSize = 12
    syncButton.Parent = frame
    Instance.new("UICorner", syncButton).CornerRadius = UDim.new(0, 6)
    local sendButton = Instance.new("TextButton")
    sendButton.Name = "SendButton"
    sendButton.Size = UDim2.new(0.3, 0, 0, 32)
    sendButton.Position = UDim2.new(0.34, 0, 0, 266)
    sendButton.Text = "Send Mail"
    sendButton.BackgroundColor3 = Color3.fromRGB(75, 125, 180)
    sendButton.TextColor3 = Color3.fromRGB(245, 245, 245)
    sendButton.Font = Enum.Font.Gotham
    sendButton.TextSize = 12
    sendButton.Parent = frame
    Instance.new("UICorner", sendButton).CornerRadius = UDim.new(0, 6)
    local autoButton = Instance.new("TextButton")
    autoButton.Name = "AutoGiftButton"
    autoButton.Size = UDim2.new(0.3, 0, 0, 32)
    autoButton.Position = UDim2.new(0.68, 0, 0, 266)
    autoButton.Text = "Auto Gift OFF"
    autoButton.BackgroundColor3 = Color3.fromRGB(175, 80, 80)
    autoButton.TextColor3 = Color3.fromRGB(245, 245, 245)
    autoButton.Font = Enum.Font.Gotham
    autoButton.TextSize = 12
    autoButton.Parent = frame
    Instance.new("UICorner", autoButton).CornerRadius = UDim.new(0, 6)
    local selectAllButton = Instance.new("TextButton")
    selectAllButton.Name = "SelectAll"
    selectAllButton.Size = UDim2.new(0.22, 0, 0, 28)
    selectAllButton.Position = UDim2.new(0, 8, 0, 228)
    selectAllButton.Text = "Select All"
    selectAllButton.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
    selectAllButton.TextColor3 = Color3.fromRGB(245, 245, 245)
    selectAllButton.Font = Enum.Font.Gotham
    selectAllButton.TextSize = 12
    selectAllButton.Parent = frame
    Instance.new("UICorner", selectAllButton).CornerRadius = UDim.new(0, 6)
    local clearButton = Instance.new("TextButton")
    clearButton.Name = "ClearSelection"
    clearButton.Size = UDim2.new(0.22, 0, 0, 28)
    clearButton.Position = UDim2.new(0.24, 0, 0, 228)
    clearButton.Text = "Clear"
    clearButton.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
    clearButton.TextColor3 = Color3.fromRGB(245, 245, 245)
    clearButton.Font = Enum.Font.Gotham
    clearButton.TextSize = 12
    clearButton.Parent = frame
    Instance.new("UICorner", clearButton).CornerRadius = UDim.new(0, 6)
    local autoEnabled = false
    local autoRunning = false
    local function updateAutoButton()
        autoButton.Text = autoEnabled and "Auto Gift ON" or "Auto Gift OFF"
        autoButton.BackgroundColor3 = autoEnabled and Color3.fromRGB(90, 150, 90) or Color3.fromRGB(175, 80, 80)
    end
    local function getSelectedSummary()
        local items = getSelectedItems()
        local total = 0
        for _, item in ipairs(items) do
            total = total + (item.qty or 1)
        end
        return items, total
    end
    local function autoGiftLoop()
        if autoRunning then
            return
        end
        autoRunning = true
        spawn(function()
            while autoEnabled do
                local recipient = usernameBox.Text
                local targetQty = tonumber(quantityBox.Text) or 1
                local items, totalQty = getSelectedSummary()
                if recipient == "" then
                    setStatus("Auto Gift berhenti: username kosong")
                    autoEnabled = false
                    updateAutoButton()
                    break
                end
                if totalQty <= 0 then
                    setStatus("Auto Gift berhenti: tidak ada item terpilih")
                    autoEnabled = false
                    updateAutoButton()
                    break
                end
                local sendQty = math.min(targetQty, totalQty)
                setStatus("Auto Gift kirim " .. tostring(sendQty) .. " item ke " .. recipient)
                if not sendByMail(recipient, sendQty) then
                    setStatus("Auto Gift gagal")
                    autoEnabled = false
                    updateAutoButton()
                    break
                end
                task.wait(3)
            end
            autoRunning = false
        end)
    end
    syncButton.Activated:Connect(refreshInventory)
    sendButton.Activated:Connect(function()
        local recipient = usernameBox.Text
        if recipient == "" then
            setStatus("Masukkan username penerima terlebih dahulu")
            return
        end
        local qty = tonumber(quantityBox.Text) or 1
        sendByMail(recipient, qty)
    end)
    selectAllButton.Activated:Connect(function()
        selectVisibleItems(true)
    end)
    clearButton.Activated:Connect(function()
        selectVisibleItems(false)
    end)
    autoButton.Activated:Connect(function()
        autoEnabled = not autoEnabled
        updateAutoButton()
        if autoEnabled then
            autoGiftLoop()
        end
    end)
    refreshInventory()
    updateCanvas()
    syncInventoryFunction = refreshInventory
end

local function EnsureUI()
    pcall(createMailGui)
end

local function SyncInventory()
    EnsureUI()
    if syncInventoryFunction then
        syncInventoryFunction()
        return true
    end
    return false
end

local function Start()
    EnsureUI()
    local username = settings.AutoMail.username
    local count = tonumber(settings.AutoMail.itemcount) or 20
    if username == "" then
        print("[GrowAGarden2 Mail] Username kosong")
        return
    end
    SyncInventory()
end

EnsureUI()

return {
    Start = Start,
    SyncInventory = SyncInventory,
    settings = settings,
}
