-- Roblox exploit-friendly Auto Gift Mail script for Grow A Garden 2
-- Script dioptimalkan untuk deteksi inventory dan mail UI.

-- luacheck: globals game task wait
---@diagnostic disable: undefined-global

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local SharedModules = ReplicatedStorage:FindFirstChild("SharedModules")
local ClientModules = ReplicatedStorage:FindFirstChild("ClientModules")

local Networking
local PlayerStateClient
local MailboxItemCatalog

local function safeRequire(module)
    if not module then
        return nil
    end
    local ok, result = pcall(require, module)
    if ok then
        return result
    end
    return nil
end

local function findMailboxItemCatalogModule()
    local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
    local controllers = playerScripts and playerScripts:FindFirstChild("Controllers")
    local mailboxController = controllers and controllers:FindFirstChild("MailboxController")
    local officialModule = mailboxController and mailboxController:FindFirstChild("MailboxItemCatalog")

    if officialModule and officialModule:IsA("ModuleScript") then
        return officialModule
    end

    local replicatedFallback = ReplicatedStorage:FindFirstChild("MailboxItemCatalog", true)
    if replicatedFallback and replicatedFallback:IsA("ModuleScript") then
        return replicatedFallback
    end

    return nil
end

local function loadNetworkingModules()
    if SharedModules then
        Networking = safeRequire(SharedModules:FindFirstChild("Networking"))
    end
    if ClientModules then
        PlayerStateClient = safeRequire(ClientModules:FindFirstChild("PlayerStateClient"))
    end
    local catalogModule = findMailboxItemCatalogModule()
    if catalogModule then
        MailboxItemCatalog = safeRequire(catalogModule)
    end
end

local function normalizeUsername(value)
    local username = tostring(value or "")
    username = username:gsub("^%s*@?(.-)%s*$", "%1")
    return username
end

local function lookupRecipient(username)
    username = normalizeUsername(username)
    if username == "" then
        return nil
    end

    if Networking and Networking.Mailbox and Networking.Mailbox.LookupPlayer then
        local ok, result = pcall(function()
            return Networking.Mailbox.LookupPlayer:Fire(username)
        end)
        if ok and typeof(result) == "number" and result > 0 then
            return result
        end
    end

    local ok, userId = pcall(function()
        return Players:GetUserIdFromNameAsync(username)
    end)
    if ok and type(userId) == "number" and userId > 0 then
        return userId
    end

    return nil
end

local function getLocalInventory()
    if not PlayerStateClient or type(PlayerStateClient.GetLocalReplica) ~= "function" then
        return nil
    end
    local ok, replica = pcall(function()
        return PlayerStateClient:GetLocalReplica()
    end)
    if not ok or type(replica) ~= "table" then
        return nil
    end
    local data = replica.Data
    if type(data) ~= "table" or type(data.Inventory) ~= "table" then
        return nil
    end
    return data.Inventory
end

local function getEquippedPetIds()
    local equipped = {}
    if not Networking or not Networking.Pets or not Networking.Pets.GetEquippedPets then
        return equipped
    end
    local ok, result = pcall(function()
        return Networking.Pets.GetEquippedPets:Fire()
    end)
    if ok and type(result) == "table" then
        for _, pet in pairs(result) do
            if type(pet) == "table" and pet.Id ~= nil then
                equipped[tostring(pet.Id)] = true
            end
        end
    end
    return equipped
end

local GEAR_CATEGORIES = {
    Sprinklers = true,
    WateringCans = true,
    Mushrooms = true,
    Gnomes = true,
    Raccoons = true,
    Crates = true,
    Trowels = true,
    Props = true,
}

local function mapInventoryCategoryToUiCategory(category)
    local name = tostring(category or "")
    if name == "Pets" then
        return "Pets"
    end
    if name == "Seeds" or name == "SeedPacks" or name:lower():find("seed") then
        return "Seeds"
    end
    if GEAR_CATEGORIES[name] or name:lower():find("sprinkler") or name:lower():find("watering") or name:lower():find("mushroom") or name:lower():find("gnome") or name:lower():find("raccoon") or name:lower():find("crate") or name:lower():find("trowel") or name:lower():find("prop") then
        return "Gear"
    end
    return nil
end

local function resolveDisplayName(category, itemKey, entry)
    if MailboxItemCatalog and type(MailboxItemCatalog.Resolve) == "function" then
        local ok, displayName = pcall(MailboxItemCatalog.Resolve, category, itemKey, entry)
        if ok and type(displayName) == "string" and displayName ~= "" then
            return displayName
        end
    end
    if category == "Seeds" then
        local name = tostring(itemKey)
        local lower = name:lower()
        if lower:sub(-5) ~= " seed" and lower ~= "seed" then
            return name .. " Seed"
        end
        return name
    end
    if category == "Pets" then
        if type(entry) == "table" then
            return tostring(entry.Name or entry.PetName or entry.Species or itemKey)
        end
        return tostring(itemKey)
    end
    return tostring(itemKey)
end

local function isGiftableInventoryEntry(category, itemKey, value, equippedPetIds)
    if MailboxItemCatalog and type(MailboxItemCatalog.IsGiftable) == "function" then
        local ok, allowed = pcall(MailboxItemCatalog.IsGiftable, category)
        if not ok or allowed ~= true then
            return false
        end
    end
    if category == "Pets" then
        if type(value) ~= "table" or value.Id == nil then
            return false
        end
        if value.Equipped == true or equippedPetIds[tostring(value.Id)] or equippedPetIds[tostring(itemKey)] then
            return false
        end
        return true
    end
    return type(value) == "number" and value > 0
end

local function collectReplicaInventoryEntries()
    local inventory = getLocalInventory()
    if type(inventory) ~= "table" then
        return {}
    end
    local equippedPetIds = getEquippedPetIds()
    local entries = {}
    for invCategory, categoryInventory in pairs(inventory) do
        local uiCategory = mapInventoryCategoryToUiCategory(invCategory)
        if uiCategory and type(categoryInventory) == "table" then
            if invCategory == "Pets" then
                local grouped = {}
                for itemKey, value in pairs(categoryInventory) do
                    if isGiftableInventoryEntry(invCategory, itemKey, value, equippedPetIds) then
                        local displayName = resolveDisplayName(invCategory, itemKey, value)
                        local selectionKey = uiCategory .. ":GROUP:" .. displayName
                        local entry = grouped[selectionKey]
                        if not entry then
                            entry = {
                                InventoryCategory = invCategory,
                                Category = uiCategory,
                                ItemKey = itemKey,
                                DisplayName = displayName,
                                Owned = 0,
                                GroupedPets = true,
                                Members = {},
                                SelectionKey = selectionKey,
                            }
                            grouped[selectionKey] = entry
                        end
                        entry.Owned = entry.Owned + 1
                        table.insert(entry.Members, { ItemKey = itemKey, EntryValue = value })
                    end
                end
                for _, entry in pairs(grouped) do
                    table.sort(entry.Members, function(a, b)
                        return tostring(a.ItemKey) < tostring(b.ItemKey)
                    end)
                    table.insert(entries, entry)
                end
            else
                for itemKey, value in pairs(categoryInventory) do
                    if isGiftableInventoryEntry(invCategory, itemKey, value, equippedPetIds) then
                        local amount = math.max(1, math.floor(value))
                        local displayName = resolveDisplayName(invCategory, itemKey, value)
                        table.insert(entries, {
                            InventoryCategory = invCategory,
                            Category = uiCategory,
                            ItemKey = itemKey,
                            DisplayName = displayName,
                            Owned = amount,
                            GroupedPets = false,
                            Unique = false,
                            SelectionKey = uiCategory .. ":" .. tostring(itemKey),
                        })
                    end
                end
            end
        end
    end
    table.sort(entries, function(a, b)
        local aName = a.DisplayName:lower()
        local bName = b.DisplayName:lower()
        if aName ~= bName then
            return aName < bName
        end
        return tostring(a.ItemKey) < tostring(b.ItemKey)
    end)
    return entries
end

local function buildPayloadFromSelection(selectedItems, maxQty)
    local payload = {}
    local sent = 0
    for _, item in ipairs(selectedItems) do
        if sent >= maxQty then break end
        local count = math.min(item.qty or 1, maxQty - sent)
        local category = item.inventoryCategory or item.category
        local itemKey = item.key or item.name
        if category == "Pets" then
            for i = 1, count do
                if sent >= maxQty then break end
                table.insert(payload, { Category = category, ItemKey = itemKey, Count = 1 })
                sent = sent + 1
            end
        else
            table.insert(payload, { Category = category, ItemKey = itemKey, Count = count })
            sent = sent + count
        end
    end
    return payload, sent
end

local lastSendAt = 0
local function sendBatch(userId, payload, note)
    if not Networking or not Networking.Mailbox or not Networking.Mailbox.SendBatch then
        return false, "Networking.Mailbox.SendBatch not found"
    end

    local elapsed = os.clock() - lastSendAt
    if elapsed < 1.55 then
        task.wait(1.55 - elapsed)
    end
    lastSendAt = os.clock()

    local safeNote = tostring(note or "")
    local noteLength = utf8.len(safeNote)
    if noteLength and noteLength > 100 then
        local cut = utf8.offset(safeNote, 101)
        if cut then
            safeNote = string.sub(safeNote, 1, cut - 1)
        end
    end

    local ok, result, message = pcall(function()
        return Networking.Mailbox.SendBatch:Fire(userId, payload, safeNote)
    end)

    if not ok then
        return false, "Remote error: " .. tostring(result)
    end

    if result == true then
        local text = tostring(message or "")
        return true, text ~= "" and text or "Gift sent"
    end

    local text = tostring(message or "")
    return false, text ~= "" and text or "Server rejected the gift"
end

loadNetworkingModules()

local settings = {
    AutoMail = {
        username = "Ceszganteng",
        itemcount = 20,
        note = "",
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

local function extractItemKey(instance)
    if not instance then
        return ""
    end
    local key = safeGetAttribute(instance, "ItemKey") or safeGetAttribute(instance, "Key") or safeGetAttribute(instance, "Name")
    if key and key ~= "" then
        return normalizeText(key)
    end
    if instance:IsA("ObjectValue") and instance.Value then
        return normalizeText(instance.Value.Name)
    end
    return normalizeText(instance.Name)
end

local function isOwnGui(instance)
    local mailGui = PlayerGui:FindFirstChild("MailGui")
    return mailGui and instance and instance:IsDescendantOf(mailGui)
end

local function collectInventoryItems(outMap, keyMap)
    keyMap = keyMap or {}
    local seen = {}
    local function add(name, qty, key)
        name = normalizeText(name)
        if name == "" then
            return
        end
        name = findKnownItemName(name)
        outMap[name] = (outMap[name] or 0) + (tonumber(qty) or 1)
        if key and key ~= "" and not keyMap[name] then
            keyMap[name] = key
        end
    end
    local function scan(obj)
        if not obj or seen[obj] or isOwnGui(obj) then
            return
        end
        seen[obj] = true
        local name = extractName(obj)
        local qty = extractQuantity(obj)
        local key = extractItemKey(obj)
        if name ~= "" and name:len() > 1 then
            add(name, qty, key)
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
    usernameBox.Position = UDim2.new(0, 8, 0, 220)
    usernameBox.BackgroundColor3 = Color3.fromRGB(52, 52, 58)
    usernameBox.TextColor3 = Color3.fromRGB(240, 240, 240)
    usernameBox.Text = settings.AutoMail.username
    usernameBox.ClearTextOnFocus = false
    usernameBox.Parent = frame
    local quantityBox = Instance.new("TextBox")
    quantityBox.Name = "QuantityBox"
    quantityBox.PlaceholderText = "Qty to send"
    quantityBox.Size = UDim2.new(0.28, 0, 0, 32)
    quantityBox.Position = UDim2.new(0.62, 0, 0, 220)
    quantityBox.BackgroundColor3 = Color3.fromRGB(52, 52, 58)
    quantityBox.TextColor3 = Color3.fromRGB(240, 240, 240)
    quantityBox.Text = tostring(settings.AutoMail.itemcount)
    quantityBox.ClearTextOnFocus = false
    quantityBox.Parent = frame
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, -16, 0, 22)
    statusLabel.Position = UDim2.new(0, 8, 0, 260)
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
    local function addItemButton(itemName, qty, itemKey, inventoryCategory)
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
        btn:SetAttribute("InventoryCategory", inventoryCategory or category)
        btn:SetAttribute("ItemKey", itemKey or itemName)
        btn:SetAttribute("DisplayName", itemName)
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
        local total = 0
        local entries = collectReplicaInventoryEntries()
        if #entries > 0 then
            for _, entry in ipairs(entries) do
                addItemButton(entry.DisplayName, entry.Owned, entry.ItemKey, entry.InventoryCategory)
                total = total + 1
            end
        else
            local inventoryMap = {}
            local keyMap = {}
            collectInventoryItems(inventoryMap, keyMap)
            for itemName, qty in pairs(inventoryMap) do
                local category = categorizeItem(itemName)
                if category ~= "Other" then
                    addItemButton(itemName, qty, keyMap[itemName] or itemName)
                    total = total + 1
                end
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
                name = child:GetAttribute("DisplayName"),
                key = child:GetAttribute("ItemKey"),
                category = child:GetAttribute("Category"),
                inventoryCategory = child:GetAttribute("InventoryCategory"),
                qty = tonumber(child:GetAttribute("Quantity")) or 1
            })
        end
    end
    return selected
end

local function sendByMail(recipient, maxQty)
    local userId = lookupRecipient(recipient)
    if not userId then
        setStatus("Recipient tidak ditemukan")
        return
    end

    local items = getSelectedItems()
    local payload, sent = buildPayloadFromSelection(items, tonumber(maxQty) or 1)
    if sent == 0 then
        setStatus("Tidak ada item terpilih")
        return
    end

    local ok, msg = sendBatch(userId, payload, "")
    setStatus(ok and msg or ("Gagal: " .. msg))
end


    

        local userId = lookupRecipient(username)
        if not userId then
            setStatus("Recipient tidak ditemukan")
            return false
        end
        if userId == LocalPlayer.UserId then
            setStatus("Tidak bisa mengirim ke diri sendiri")
            return false
        end

        local payload, sentCount = buildPayloadFromSelection(selectedItems, maxQty or math.huge)
        if sentCount == 0 or #payload == 0 then
            setStatus("Tidak ada payload mail yang valid")
            return false
        end

        local ok, message = sendBatch(userId, payload, settings.AutoMail.note)
        if not ok then
            setStatus("Send batch gagal: " .. tostring(message))
            return false
        end

        setStatus("Terkirim " .. tostring(sentCount) .. " item ke " .. tostring(username))
        return true
    end
    local syncButton = Instance.new("TextButton")
    syncButton.Name = "SyncButton"
    syncButton.Size = UDim2.new(0.3, 0, 0, 28)
    syncButton.Position = UDim2.new(0.7, -8, 0, 300)
    syncButton.Text = "Sync Inventory"
    syncButton.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
    syncButton.TextColor3 = Color3.fromRGB(240, 240, 240)
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
    local claimPanel = Instance.new("Frame")
    claimPanel.Name = "Auto ClaimPanel"
    laimPanel.Size = UDim2.new(1, -16, 1, -50)
    claimPanel.Position = UDim2.new(0, 8, 0, 40)
    claimPanel.BackgroundTransparency = 1
    claimPanel.Visible = false
    claimPanel.Parent = frame

    local claimToggleButton = Instance.new("TextButton")
    claimToggleButton.Text = "Auto Claim: OFF"
    claimToggleButton.Size = UDim2.new(0.45, 0, 0, 28)
    claimToggleButton.Position = UDim2.new(0, 8, 0, 0)
    claimToggleButton.Parent = claimPanel
    claimToggleButton.Activated:Connect(function()
    toggleAutoClaim()
    claimToggleButton.Text = autoClaimEnabled and "Auto Claim: ON" or "Auto Claim: OFF"
    end)
    autoGiftButton.Activated:Connect(function()
    toggleAutoGift(usernameBox.Text, quantityBox.Text)
    autoGiftButton.Text = autoGiftEnabled and "Auto Gift: ON" or "Auto Gift: OFF"
    end)


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

local autoGiftEnabled = false
autoGiftButton.Activated:Connect(function()
    autoGiftEnabled = not autoGiftEnabled
    autoGiftButton.Text = autoGiftEnabled and "Auto Gift: ON" or "Auto Gift: OFF"
    if autoGiftEnabled then
        task.spawn(function()
            while autoGiftEnabled do
                sendByMail(usernameBox.Text, quantityBox.Text)
                task.wait(2)
            end
        end)
    end
end)



    -- Toggle Auto Buy ON/OFF
local autoBuyEnabled = false

local function toggleAutoBuy(itemName, qty)
    autoBuyEnabled = not autoBuyEnabled
    if autoBuyEnabled then
        task.spawn(function()
            while autoBuyEnabled do
                if Networking and Networking.Shop and Networking.Shop.BuyItem then
                    local ok, result = pcall(function()
                        return Networking.Shop.BuyItem:Fire(itemName, qty or 1)
                    end)
                    setStatus(ok and "Bought " .. itemName or "Buy failed")
                end
                task.wait(2) -- interval pembelian
            end
        end)
    end
end

-- Toggle Auto Claim Drop Seed ON/OFF
local autoClaimEnabled = false

local function toggleAutoClaim()
    autoClaimEnabled = not autoClaimEnabled
    if autoClaimEnabled then
        task.spawn(function()
            while autoClaimEnabled do
                if Networking and Networking.Drops and Networking.Drops.Claim then
                    local ok, result = pcall(function()
                        return Networking.Drops.Claim:Fire()
                    end)
                    setStatus(ok and "Drop claimed" or "Claim failed")
                end
                task.wait(5) -- interval klaim drop
            end
        end)
    end
end

-- Refresh Inventory (dipanggil dari tombol Clear)
local function refreshInventory()
    for _, child in ipairs(itemList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local entries = collectReplicaInventoryEntries()
    for _, entry in ipairs(entries) do
        addItemButton(entry.DisplayName, entry.Owned, entry.ItemKey, entry.InventoryCategory)
    end
    setStatus("Inventory refreshed")
end

-- Select All Items
local function selectAllItems()
    for _, child in ipairs(itemList:GetChildren()) do
        if child:IsA("TextButton") then
            child:SetAttribute("Selected", true)
            child.BackgroundColor3 = Color3.fromRGB(90, 150, 90)
        end
    end
end

-- Clear Items (sekalian refresh)
local function clearItems()
    refreshInventory()
end

   sendButton.Activated:Connect(function()
    sendByMail(usernameBox.Text, quantityBox.Text)
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
