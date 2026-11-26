-- WatHUB Script (MalamSamaNenek.lua)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local MarketplaceService = game:GetService("MarketplaceService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local LocalPlayer = Players.LocalPlayer
local game_name = "Malam Sama Nenek"
pcall(function()
    local info = MarketplaceService:GetProductInfo(game.PlaceId)
    if info and info.Name and info.Name ~= "" then
        game_name = info.Name
    end
end)

local DISCORD_INVITE_URL = "https://discord.gg/nb8Jq8EKDG"

local CUSTOM_LOGO_ASSET_ID = 117209290368597 -- Versi 2: Logo custom
local ACTIVE_ICON_VERSION = 2 -- 1 = Teks 'W' hijau, 2 = Logo custom (default)
local DEFAULT_SPEED_VALUE = 25 -- Kelajuan default (boleh digeser 0-100)
local ICON_DRAG_THRESHOLD = 12 -- Jarak minimum (px) sebelum ikon terapung dianggap digeser

local COLOR_OPAH = Color3.fromRGB(255, 75, 75)
local COLOR_KEY_FALLBACK = Color3.fromRGB(255, 230, 75)
local COLOR_NOTE = Color3.fromRGB(60, 215, 255)
local COLOR_FLIPFLOP = Color3.fromRGB(165, 115, 255)

local KEY_COLORS = {
    Red = Color3.fromRGB(255, 75, 75),
    Blue = Color3.fromRGB(80, 140, 255),
    Green = Color3.fromRGB(75, 220, 115),
    Yellow = Color3.fromRGB(255, 210, 60),
    Purple = Color3.fromRGB(185, 105, 255),
}

local function copy_to_clipboard(txt)
    local str = tostring(txt or "")
    if str == "" then
        return false
    end
    local clip_fn = (type(setclipboard) == "function" and setclipboard)
        or (type(toclipboard) == "function" and toclipboard)
        or (type(set_clipboard) == "function" and set_clipboard)
    if clip_fn then
        local ok = pcall(clip_fn, str)
        if ok then
            return true
        end
    end
    if type(syn) == "table" and type(syn.write_clipboard) == "function" then
        local ok = pcall(syn.write_clipboard, str)
        if ok then
            return true
        end
    end
    return false
end

local function safe_player_name()
    return LocalPlayer and LocalPlayer.Name or "Player"
end

local function safe_display_name()
    return LocalPlayer and LocalPlayer.DisplayName or safe_player_name()
end

local Theme = {
    BgMain = Color3.fromRGB(16, 18, 24),
    BgHeader = Color3.fromRGB(22, 25, 34),
    BgSidebar = Color3.fromRGB(19, 22, 30),
    BgCard = Color3.fromRGB(26, 30, 41),
    BgRow = Color3.fromRGB(32, 37, 50),
    OutlineGold = Color3.fromRGB(245, 196, 48),
    TabActiveBg = Color3.fromRGB(45, 52, 70),
    ToggleOnGreen = Color3.fromRGB(46, 196, 112),
    ToggleOffBg = Color3.fromRGB(58, 65, 84),
    TextPrimary = Color3.fromRGB(242, 245, 250),
    TextSecondary = Color3.fromRGB(156, 166, 188),
    CornerSm = 6,
    CornerMd = 10,
    CornerLg = 14,
}

local function to_rich_hex(c3)
    local r = math.clamp(math.floor(c3.R * 255 + 0.5), 0, 255)
    local g = math.clamp(math.floor(c3.G * 255 + 0.5), 0, 255)
    local b = math.clamp(math.floor(c3.B * 255 + 0.5), 0, 255)
    return string.format("#%02X%02X%02X", r, g, b)
end

local function escape_rich_text(str)
    local s = tostring(str or "")
    s = string.gsub(s, "&", "&amp;")
    s = string.gsub(s, "<", "&lt;")
    s = string.gsub(s, ">", "&gt;")
    s = string.gsub(s, '"', "&quot;")
    return s
end

local function add_corner(inst, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or Theme.CornerMd)
    c.Parent = inst
    return c
end

local function add_stroke(inst, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.OutlineGold
    s.Thickness = thickness or 1.4
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = inst
    return s
end

local function attach_moving_rgb_outline(stroke, state)
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 1.8

    local grad = Instance.new("UIGradient")
    grad.Name = "MovingRGBGradient"
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 65, 95)),
        ColorSequenceKeypoint.new(0.20, Color3.fromRGB(255, 205, 55)),
        ColorSequenceKeypoint.new(0.40, Color3.fromRGB(65, 245, 130)),
        ColorSequenceKeypoint.new(0.60, Color3.fromRGB(55, 210, 255)),
        ColorSequenceKeypoint.new(0.80, Color3.fromRGB(165, 85, 255)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 65, 95)),
    })
    grad.Rotation = 0
    grad.Parent = stroke

    local my_sid = state and state.session_id or 1
    task.spawn(function()
        local angle = 0
        while grad and grad.Parent and stroke and stroke.Parent do
            if state and (state.closed or state.session_id ~= my_sid) then
                break
            end
            angle = (angle + 4) % 360
            grad.Rotation = angle
            task.wait(0.03)
        end
    end)

    return grad
end

local function build_sidebar_account_card(sidebar, order_idx, theme, themed_cards, state)
    local card = Instance.new("Frame")
    card.Name = "SidebarAccountCard"
    card.LayoutOrder = order_idx or 1
    card.Size = UDim2.new(1, 0, 0, 56)
    card.BackgroundColor3 = theme.BgCard
    card.BorderSizePixel = 0
    card.ZIndex = 4
    card.Parent = sidebar
    add_corner(card, theme.CornerMd)
    local stroke = add_stroke(card, theme.OutlineGold, 1.8)
    attach_moving_rgb_outline(stroke, state)
    if themed_cards then
        table.insert(themed_cards, card)
    end

    local avatar = Instance.new("ImageLabel")
    avatar.Size = UDim2.fromOffset(36, 36)
    avatar.Position = UDim2.fromOffset(8, 10)
    avatar.BackgroundColor3 = theme.BgRow
    avatar.BorderSizePixel = 0
    avatar.ZIndex = 5
    avatar.Parent = card
    add_corner(avatar, 999)

    if LocalPlayer then
        task.spawn(function()
            local ok, content = pcall(function()
                return Players:GetUserThumbnailAsync(
                    LocalPlayer.UserId,
                    Enum.ThumbnailType.HeadShot,
                    Enum.ThumbnailSize.Size48x48
                )
            end)
            if ok and content and avatar and avatar.Parent then
                avatar.Image = content
            end
        end)
    end

    local name_lbl = Instance.new("TextLabel")
    name_lbl.Size = UDim2.new(1, -52, 0, 18)
    name_lbl.Position = UDim2.fromOffset(50, 9)
    name_lbl.BackgroundTransparency = 1
    name_lbl.Text = safe_display_name()
    name_lbl.TextColor3 = theme.TextPrimary
    name_lbl.Font = Enum.Font.GothamBold
    name_lbl.TextSize = 12
    name_lbl.TextXAlignment = Enum.TextXAlignment.Left
    name_lbl.TextTruncate = Enum.TextTruncate.AtEnd
    name_lbl.ZIndex = 5
    name_lbl.Parent = card

    local sub_lbl = Instance.new("TextLabel")
    sub_lbl.Size = UDim2.new(1, -52, 0, 16)
    sub_lbl.Position = UDim2.fromOffset(50, 28)
    sub_lbl.BackgroundTransparency = 1
    sub_lbl.Text = "@" .. safe_player_name()
    sub_lbl.TextColor3 = theme.TextSecondary
    sub_lbl.Font = Enum.Font.Gotham
    sub_lbl.TextSize = 10
    sub_lbl.TextXAlignment = Enum.TextXAlignment.Left
    sub_lbl.TextTruncate = Enum.TextTruncate.AtEnd
    sub_lbl.ZIndex = 5
    sub_lbl.Parent = card

    return card
end

local function create_feature_controllers(state, track, parent_gui)
    local esp_folder = Instance.new("Folder")
    esp_folder.Name = "WatHUB_ESP_Folder"
    esp_folder.Parent = workspace

    local loot_blacklist = {}
    local world_cache = {
        drawers = {},
        flipflops = {},
        wardrobes = {},
        keys = {},
        locks = {},
        note = nil,
        opahs = {},
        door = nil,
        code = nil,
    }
    local safe_zone_cooldown = 0
    local nearby_interact_busy = false

    local function is_active_session()
        return (not state.closed) and (state.session_id == state.active_session_id)
    end

    local function get_root()
        local char = LocalPlayer and LocalPlayer.Character
        return char and char:FindFirstChild("HumanoidRootPart")
    end

    local function get_humanoid()
        local char = LocalPlayer and LocalPlayer.Character
        return char and char:FindFirstChildOfClass("Humanoid")
    end

    local function is_alive()
        local root = get_root()
        local hum = get_humanoid()
        if not root or not hum then
            return false
        end
        if hum.Health <= 0 then
            return false
        end
        if LocalPlayer:GetAttribute("Out") == true then
            return false
        end
        return true
    end

    local function instance_position(inst)
        if not inst then
            return nil
        end
        if inst:IsA("BasePart") then
            return inst.Position
        end
        if inst:IsA("Attachment") then
            return inst.WorldPosition
        end
        if inst:IsA("Model") then
            local ok, pivot = pcall(function()
                return inst:GetPivot()
            end)
            if ok and pivot then
                return pivot.Position
            end
            local part = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
            return part and part.Position or nil
        end
        local part = inst:FindFirstChildWhichIsA("BasePart", true)
        return part and part.Position or nil
    end

    local function prompt_position(prompt)
        if not prompt then
            return nil
        end
        return instance_position(prompt.Parent)
    end

    local function distance_between(a, b)
        if not a or not b then
            return math.huge
        end
        return (a - b).Magnitude
    end

    local function resolve_adornee(target)
        if not target or not target.Parent then
            return nil
        end
        if target:IsA("Model") then
            return target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart", true)
        elseif target:IsA("BasePart") then
            return target
        end
        return nil
    end

    local function read_passcode_label(note)
        if not note then
            return nil
        end
        local label = note:FindFirstChild("Code", true)
        if label and label:IsA("TextLabel") then
            local text = label.Text
            if type(text) == "string" and text:gsub("%s", "") ~= "" then
                return text
            end
        end
        return nil
    end

    local function get_key_color(key_model)
        local name = key_model and key_model:GetAttribute("KeyColor")
        return KEY_COLORS[name] or COLOR_KEY_FALLBACK, name
    end

    local function find_pickup_prompt(model)
        if not model then
            return nil
        end
        for _, desc in ipairs(model:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and desc.ActionText == "Pick up" then
                return desc
            end
        end
        return nil
    end

    local function wardrobe_model_from_prompt(prompt)
        local curr = prompt and prompt.Parent
        while curr and not curr:IsA("Model") do
            curr = curr.Parent
        end
        return curr
    end

    local function is_hiding_or_keypad_prompt(prompt)
        if not prompt then
            return true
        end
        local action = string.lower(tostring(prompt.ActionText or ""))
        local obj_name = string.lower(tostring(prompt.ObjectText or ""))
        local p_name = string.lower(tostring(prompt.Name or ""))
        if action:find("hide") or obj_name:find("wardrobe") or obj_name:find("almari") or obj_name:find("keypad") or action:find("keypad") or p_name:find("keypad") then
            return true
        end
        local curr = prompt.Parent
        local hops = 0
        while curr and curr ~= workspace and hops < 8 do
            local cname = string.lower(tostring(curr.Name or ""))
            if cname:find("hidingwardrobe") or cname:find("wardrobe") or cname:find("keypad") or cname:find("codepad") then
                return true
            end
            curr = curr.Parent
            hops += 1
        end
        return false
    end

    local function collect_opah_models()
        local list = {}
        local seen = {}
        local function add_opah(inst)
            if inst and inst.Parent and not seen[inst] then
                seen[inst] = true
                table.insert(list, inst)
            end
        end

        local direct_opah = workspace:FindFirstChild("Opah")
        if direct_opah then
            add_opah(direct_opah)
        end

        for _, child in ipairs(workspace:GetChildren()) do
            if child ~= direct_opah and (child.Name == "Opah" or string.sub(child.Name, 1, 4) == "Opah") then
                add_opah(child)
            end
        end

        return list
    end

    local drawer_opened_cooldown = {}

    local function is_shop_or_emergency_prompt(prompt)
        if not prompt then
            return true
        end
        local action = string.lower(tostring(prompt.ActionText or ""))
        local obj = string.lower(tostring(prompt.ObjectText or ""))
        local pname = string.lower(tostring(prompt.Name or ""))

        if action:find("shop", 1, true) or action:find("toko", 1, true) or action:find("emergency", 1, true) or action:find("buy", 1, true) or action:find("beli", 1, true)
            or obj:find("shop", 1, true) or obj:find("toko", 1, true) or obj:find("emergency", 1, true)
            or pname:find("shop", 1, true) or pname:find("toko", 1, true) or pname:find("emergency", 1, true) then
            return true
        end

        local curr = prompt.Parent
        local hops = 0
        while curr and curr ~= workspace and hops < 8 do
            local cname = string.lower(tostring(curr.Name or ""))
            if cname:find("shop", 1, true) or cname:find("toko", 1, true) or cname:find("emergency", 1, true) or cname:find("store", 1, true) then
                return true
            end
            curr = curr.Parent
            hops += 1
        end

        return false
    end

    local function is_drawer_already_open(prompt)
        if not prompt then
            return true
        end
        local exp = drawer_opened_cooldown[prompt]
        if exp and exp > os.clock() then
            return true
        end

        local action = string.lower(tostring(prompt.ActionText or ""))
        if action:find("close", 1, true) or action:find("tutup", 1, true) then
            return true
        end

        local curr = prompt.Parent
        local hops = 0
        while curr and curr ~= workspace and hops < 6 do
            if curr:GetAttribute("IsOpen") == true or curr:GetAttribute("Opened") == true or curr:GetAttribute("Open") == true then
                return true
            end
            if curr:GetAttribute("IsOpen") == false or curr:GetAttribute("Opened") == false or curr:GetAttribute("Open") == false then
                return false
            end
            local open_val = curr:FindFirstChild("IsOpen") or curr:FindFirstChild("Opened") or curr:FindFirstChild("Open")
            if open_val and (open_val:IsA("BoolValue") or open_val:IsA("IntValue") or open_val:IsA("NumberValue")) then
                if open_val:IsA("BoolValue") and open_val.Value == true then
                    return true
                elseif (open_val:IsA("IntValue") or open_val:IsA("NumberValue")) and open_val.Value ~= 0 then
                    return true
                end
            end
            curr = curr.Parent
            hops += 1
        end

        return false
    end

    local function is_collectible_or_drawer_prompt(prompt)
        if not prompt or not prompt:IsA("ProximityPrompt") or is_hiding_or_keypad_prompt(prompt) or is_shop_or_emergency_prompt(prompt) then
            return false
        end
        local action = string.lower(tostring(prompt.ActionText or ""))
        local obj = string.lower(tostring(prompt.ObjectText or ""))
        local pname = string.lower(tostring(prompt.Name or ""))

        if action == "open" or action == "buka" or action:find("open drawer", 1, true) or action:find("buka laci", 1, true) then
            if obj:find("keypad", 1, true) or pname:find("keypad", 1, true) or obj:find("wardrobe", 1, true) or obj:find("almari", 1, true) then
                return false
            end
            return true
        end

        if action:find("pick", 1, true) or action:find("collect", 1, true) or action:find("take", 1, true) or action:find("ambil", 1, true) or action:find("grab", 1, true) then
            return true
        end

        local curr = prompt.Parent
        local hops = 0
        while curr and curr ~= workspace and hops < 5 do
            local cname = string.lower(tostring(curr.Name or ""))
            if cname:find("flipflop", 1, true) or cname:find("selipar", 1, true)
                or cname:find("puzzleitem", 1, true) or cname:find("key", 1, true) or cname:find("note", 1, true) or cname:find("code", 1, true) then
                return true
            end
            curr = curr.Parent
            hops += 1
        end

        return false
    end

    local function scan_world()
        local w = {
            drawers = {},
            flipflops = {},
            wardrobes = {},
            keys = {},
            locks = {},
            collectibles = {},
            note = nil,
            opahs = collect_opah_models(),
            door = workspace:FindFirstChild("FrontDoor"),
            code = nil,
        }

        local seen_prompt = {}
        local function add_prompt(tbl, p)
            if p and p:IsA("ProximityPrompt") and not seen_prompt[p] then
                seen_prompt[p] = true
                table.insert(tbl, p)
            end
        end

        local chests = workspace:FindFirstChild("PuzzleChests")
        if chests then
            for _, inst in ipairs(chests:GetDescendants()) do
                if inst:IsA("ProximityPrompt") and not is_hiding_or_keypad_prompt(inst) then
                    add_prompt(w.drawers, inst)
                end
            end
        end

        local flipflops = workspace:FindFirstChild("FlipFlops")
        if flipflops then
            for _, inst in ipairs(flipflops:GetDescendants()) do
                if inst:IsA("ProximityPrompt") and not is_hiding_or_keypad_prompt(inst) then
                    add_prompt(w.flipflops, inst)
                    add_prompt(w.collectibles, inst)
                end
            end
        end

        local wardrobes = workspace:FindFirstChild("HidingWardrobes")
        if wardrobes then
            for _, inst in ipairs(wardrobes:GetDescendants()) do
                if inst:IsA("ProximityPrompt") and inst.ActionText == "Hide" then
                    table.insert(w.wardrobes, inst)
                end
            end
        end

        local items = workspace:FindFirstChild("PuzzleItems")
        if items then
            for _, child in ipairs(items:GetChildren()) do
                local item_type = child:GetAttribute("ItemType")
                if item_type == "Key" then
                    table.insert(w.keys, child)
                elseif item_type == "Passcode" then
                    w.note = child
                    w.code = read_passcode_label(child)
                end
                for _, desc in ipairs(child:GetDescendants()) do
                    if desc:IsA("ProximityPrompt") and not is_hiding_or_keypad_prompt(desc) then
                        add_prompt(w.collectibles, desc)
                    end
                end
            end
        end

        if w.door then
            local locks = w.door:FindFirstChild("PuzzleLocks")
            if locks then
                for _, lock in ipairs(locks:GetChildren()) do
                    for _, desc in ipairs(lock:GetDescendants()) do
                        if desc:IsA("ProximityPrompt") and not is_hiding_or_keypad_prompt(desc) then
                            add_prompt(w.locks, desc)
                        end
                    end
                end
            end
        end

        -- Imbasan tambahan untuk laci & item lain dalam workspace (tidak termasuk almari & keypad)
        local scanned = 0
        for _, desc in ipairs(workspace:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and is_collectible_or_drawer_prompt(desc) then
                local act = string.lower(tostring(desc.ActionText or ""))
                if act:find("open", 1, true) or act:find("buka", 1, true) then
                    add_prompt(w.drawers, desc)
                else
                    add_prompt(w.collectibles, desc)
                end
            end
            scanned += 1
            if (scanned % 600) == 0 then
                task.wait()
            end
        end

        if w.code then
            state.detected_code = w.code
        end

        world_cache = w

        for prompt in pairs(loot_blacklist) do
            if not prompt or prompt.Parent == nil then
                loot_blacklist[prompt] = nil
            end
        end
    end

    local function opah_summary()
        local opahs = world_cache.opahs
        if not opahs or #opahs == 0 then
            local fallback_opah = workspace:FindFirstChild("Opah")
            if fallback_opah then
                opahs = { fallback_opah }
            else
                return nil
            end
        end
        local root = get_root()
        local cam = workspace.CurrentCamera
        local origin = (root and root.Position) or (cam and cam.CFrame.Position)

        local chosen = nil
        local best_d = math.huge
        for _, inst in ipairs(opahs) do
            if inst and inst.Parent then
                if inst:GetAttribute("Chasing") == true then
                    chosen = inst
                    break
                end
                local pos = instance_position(inst)
                local d = (pos and origin) and distance_between(pos, origin) or math.huge
                if d < best_d then
                    best_d = d
                    chosen = inst
                end
            end
        end
        if not chosen then
            chosen = workspace:FindFirstChild("Opah")
        end

        if not chosen then
            return nil
        end

        return {
            state = tostring(chosen:GetAttribute("State") or "Normal"),
            mode = tostring(chosen:GetAttribute("Mode") or ""),
            chasing = chosen:GetAttribute("Chasing") == true,
            targetUserId = chosen:GetAttribute("TargetUserId"),
            lair = tostring(chosen:GetAttribute("Lair") or ""),
            distance = (best_d < math.huge) and best_d or 0,
            count = #opahs,
        }
    end

    local function format_opah_status_label(opah)
        if not opah then
            return "Opah Hilang!?"
        end
        if opah.chasing then
            if opah.mode ~= "" and opah.mode ~= "nil" then
                return "Mengejar (" .. opah.mode .. ")"
            end
            return "Mengejar"
        end
        local raw_state = opah.state
        if raw_state == "ChilingRoam" then
            return "Opah Mode Spiderman"
        end
        if raw_state == "Roam" or raw_state == "" or raw_state == "nil" then
            return "Opah Mode Sakit Pinggang"
        end
        return raw_state
    end

    --== ESP (Gaya WatHUB: Highlight + Label ringkas, ESP Opah highlight semua opah termasuk mode extreme) ==
    local function clear_esp_group(tag)
        if not esp_folder then
            return
        end
        for _, child in ipairs(esp_folder:GetChildren()) do
            if not tag or child:GetAttribute("WatTag") == tag then
                pcall(function() child:Destroy() end)
            end
        end
    end

    local function attach_esp_to_target(target, tag, color, label_text, opts)
        if not is_active_session() or not target or not target.Parent or not esp_folder.Parent then
            return
        end
        local adornee = resolve_adornee(target)
        if not adornee then
            return
        end

        local no_label = (opts and opts.no_label == true) or (tag == "opah") or (tag == "flipflop") or (not label_text) or (label_text == "")
        local stud_y = (opts and opts.studs_y) or 2.4

        local hl = Instance.new("Highlight")
        hl.FillColor = color
        hl.OutlineColor = color
        hl.FillTransparency = 0.45
        hl.OutlineTransparency = 0.05
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Adornee = target:IsA("Model") and target or adornee
        hl.Parent = esp_folder
        hl:SetAttribute("WatTag", tag)

        if not no_label then
            local bb = Instance.new("BillboardGui")
            bb.Size = UDim2.fromOffset(150, 22)
            bb.StudsOffset = Vector3.new(0, stud_y, 0)
            bb.AlwaysOnTop = true
            bb.Parent = esp_folder
            bb.Adornee = adornee
            bb:SetAttribute("WatTag", tag)

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.fromScale(1, 1)
            lbl.BackgroundTransparency = 1
            lbl.Text = label_text
            lbl.TextColor3 = color
            lbl.TextStrokeColor3 = Color3.fromRGB(10, 12, 16)
            lbl.TextStrokeTransparency = 0.15
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 12
            lbl.Parent = bb
        end
    end

    local function refresh_active_esp()
        if not is_active_session() then
            clear_esp_group(nil)
            return
        end

        -- ESP Opah: Kembalikan kepada highlight Opah asal tanpa teks
        clear_esp_group("opah")
        if state.esp_opah then
            local primary_opah = workspace:FindFirstChild("Opah") or (world_cache.opahs and world_cache.opahs[1])
            if primary_opah and primary_opah.Parent then
                attach_esp_to_target(primary_opah, "opah", COLOR_OPAH, nil, { no_label = true })
            end
        end

        -- ESP Key: Warna highlight ikut warna key + nama teks cukup "Key"
        clear_esp_group("key")
        if state.esp_key then
            for _, key in ipairs(world_cache.keys) do
                if key and key.Parent then
                    local k_color = get_key_color(key)
                    attach_esp_to_target(key, "key", k_color, "Key")
                end
            end
        end

        -- ESP Kertas Kode (Passcode Note)
        clear_esp_group("code_paper")
        if state.esp_code_paper and world_cache.note and world_cache.note.Parent then
            attach_esp_to_target(world_cache.note, "code_paper", COLOR_NOTE, "Kertas Kode")
        end

        -- Highlight Selipar sahaja (tiada teks label)
        clear_esp_group("flipflop")
        if state.esp_flipflop then
            for _, prompt in ipairs(world_cache.flipflops) do
                local item = wardrobe_model_from_prompt(prompt) or (prompt and prompt.Parent)
                if item and item.Parent then
                    attach_esp_to_target(item, "flipflop", COLOR_FLIPFLOP, nil, { no_label = true })
                end
            end
        end
    end

    --== Paparan Opah Mode (Opah Mode: / Status : (Mode)) & Kertas Kode ==
    local radar_gui = Instance.new("ScreenGui")
    radar_gui.Name = "WatHUB_OpahMode"
    radar_gui.ResetOnSpawn = false
    radar_gui.IgnoreGuiInset = true
    radar_gui.DisplayOrder = 20
    radar_gui.Parent = parent_gui

    local radar_frame = Instance.new("Frame")
    radar_frame.Size = UDim2.fromOffset(212, 46)
    radar_frame.Position = UDim2.fromOffset(14, 96)
    radar_frame.BackgroundColor3 = Theme.BgMain
    radar_frame.BackgroundTransparency = 0.08
    radar_frame.BorderSizePixel = 0
    radar_frame.Visible = false
    radar_frame.Parent = radar_gui
    add_corner(radar_frame, Theme.CornerMd)
    local radar_stroke = add_stroke(radar_frame, Theme.OutlineGold, 1.3)

    local radar_title_lbl = Instance.new("TextLabel")
    radar_title_lbl.Size = UDim2.new(1, -16, 0, 16)
    radar_title_lbl.Position = UDim2.fromOffset(8, 5)
    radar_title_lbl.BackgroundTransparency = 1
    radar_title_lbl.Font = Enum.Font.GothamBold
    radar_title_lbl.TextSize = 11
    radar_title_lbl.TextColor3 = Theme.OutlineGold
    radar_title_lbl.TextXAlignment = Enum.TextXAlignment.Left
    radar_title_lbl.TextTruncate = Enum.TextTruncate.AtEnd
    radar_title_lbl.Text = "Opah Mode:"
    radar_title_lbl.Parent = radar_frame

    local radar_state_lbl = Instance.new("TextLabel")
    radar_state_lbl.Size = UDim2.new(1, -16, 0, 18)
    radar_state_lbl.Position = UDim2.fromOffset(8, 22)
    radar_state_lbl.BackgroundTransparency = 1
    radar_state_lbl.Font = Enum.Font.GothamBold
    radar_state_lbl.TextSize = 12
    radar_state_lbl.TextColor3 = Theme.TextPrimary
    radar_state_lbl.TextXAlignment = Enum.TextXAlignment.Left
    radar_state_lbl.TextTruncate = Enum.TextTruncate.AtEnd
    radar_state_lbl.Text = "Status : Opah Hilang!?"
    radar_state_lbl.Parent = radar_frame

    local pass_gui = Instance.new("ScreenGui")
    pass_gui.Name = "WatHUB_PasscodeOverlay"
    pass_gui.ResetOnSpawn = false
    pass_gui.IgnoreGuiInset = true
    pass_gui.DisplayOrder = 20
    pass_gui.Parent = parent_gui

    local pass_frame = Instance.new("Frame")
    pass_frame.AnchorPoint = Vector2.new(0.5, 0)
    pass_frame.Position = UDim2.new(0.5, 0, 0, 14)
    pass_frame.Size = UDim2.fromOffset(250, 52)
    pass_frame.BackgroundColor3 = Theme.BgMain
    pass_frame.BackgroundTransparency = 0.08
    pass_frame.BorderSizePixel = 0
    pass_frame.Visible = false
    pass_frame.Parent = pass_gui
    add_corner(pass_frame, Theme.CornerMd)
    add_stroke(pass_frame, Theme.OutlineGold, 1.3)

    local pass_caption = Instance.new("TextLabel")
    pass_caption.Size = UDim2.new(1, -16, 0, 14)
    pass_caption.Position = UDim2.fromOffset(10, 5)
    pass_caption.BackgroundTransparency = 1
    pass_caption.Text = "KERTAS KODE"
    pass_caption.TextColor3 = Theme.OutlineGold
    pass_caption.Font = Enum.Font.GothamBold
    pass_caption.TextSize = 10
    pass_caption.TextXAlignment = Enum.TextXAlignment.Left
    pass_caption.Parent = pass_frame

    local pass_val_lbl = Instance.new("TextLabel")
    pass_val_lbl.Size = UDim2.new(1, -72, 0, 24)
    pass_val_lbl.Position = UDim2.fromOffset(10, 21)
    pass_val_lbl.BackgroundTransparency = 1
    pass_val_lbl.Text = "- - - -"
    pass_val_lbl.TextColor3 = Theme.TextPrimary
    pass_val_lbl.Font = Enum.Font.GothamBold
    pass_val_lbl.TextSize = 20
    pass_val_lbl.TextXAlignment = Enum.TextXAlignment.Left
    pass_val_lbl.Parent = pass_frame

    local pass_copy_btn = Instance.new("TextButton")
    pass_copy_btn.AnchorPoint = Vector2.new(1, 0.5)
    pass_copy_btn.Position = UDim2.new(1, -8, 0.5, 0)
    pass_copy_btn.Size = UDim2.fromOffset(54, 24)
    pass_copy_btn.BackgroundColor3 = Theme.TabActiveBg
    pass_copy_btn.Text = "Salin"
    pass_copy_btn.TextColor3 = Theme.OutlineGold
    pass_copy_btn.Font = Enum.Font.GothamBold
    pass_copy_btn.TextSize = 10
    pass_copy_btn.BorderSizePixel = 0
    pass_copy_btn.Parent = pass_frame
    add_corner(pass_copy_btn, Theme.CornerSm)
    add_stroke(pass_copy_btn, Theme.OutlineGold, 1)

    track(pass_copy_btn.Activated:Connect(function()
        if state.closed then
            return
        end
        local code = state.detected_code
        if code then
            local digits = tostring(code):gsub("%s", "")
            if copy_to_clipboard(digits) then
                pass_copy_btn.Text = "Disalin"
                task.delay(1.2, function()
                    if pass_copy_btn and pass_copy_btn.Parent then
                        pass_copy_btn.Text = "Salin"
                    end
                end)
            end
        end
    end))

    local function update_overlays()
        if not is_active_session() then
            radar_frame.Visible = false
            pass_frame.Visible = false
            return
        end

        radar_frame.Visible = (state.opah_mode == true)
        if radar_frame.Visible then
            local opah = opah_summary()
            local status_txt = format_opah_status_label(opah)
            radar_title_lbl.Text = "Opah Mode:"
            radar_state_lbl.Text = "Status : " .. status_txt
            if not opah then
                radar_state_lbl.TextColor3 = Theme.TextSecondary
                radar_stroke.Color = Theme.OutlineGold
            elseif opah.chasing then
                local is_mine = (LocalPlayer and opah.targetUserId == LocalPlayer.UserId)
                radar_state_lbl.TextColor3 = is_mine and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 185, 65)
                radar_stroke.Color = is_mine and Color3.fromRGB(255, 65, 65) or Color3.fromRGB(255, 175, 50)
            else
                radar_state_lbl.TextColor3 = Theme.ToggleOnGreen
                radar_stroke.Color = Theme.OutlineGold
            end
        end

        pass_frame.Visible = (state.passcode_overlay == true)
        if pass_frame.Visible then
            pass_val_lbl.Text = state.detected_code or "- - - -"
        end
    end

    --== Interaksi, Teleport Safe Zone (Spawn), Auto Loot, Auto Safe Zone & Auto Open And Collect Item ==
    local function trigger_prompt(prompt)
        if not prompt or not prompt.Parent or not prompt.Enabled
            or is_hiding_or_keypad_prompt(prompt) or is_shop_or_emergency_prompt(prompt) then
            return false
        end
        local fired = false
        if type(fireproximityprompt) == "function" then
            local ok = pcall(fireproximityprompt, prompt)
            if ok then
                fired = true
            end
        end
        if not fired then
            local ok_hold = pcall(function()
                prompt:InputHoldBegin()
                task.wait(0.05)
                prompt:InputHoldEnd()
            end)
            return ok_hold
        end
        return fired
    end

    local function teleport_near(position)
        local root = get_root()
        if not root or not position then
            return false
        end
        local from = root.Position
        local dir = Vector3.new(from.X - position.X, 0, from.Z - position.Z)
        if dir.Magnitude < 1 then
            dir = Vector3.new(0, 0, 1)
        end
        local stand_point = position + dir.Unit * 3 + Vector3.new(0, 2.5, 0)
        return pcall(function()
            root.CFrame = CFrame.lookAt(stand_point, Vector3.new(position.X, stand_point.Y, position.Z))
            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end)
    end

    local function get_safe_zone_position()
        local spawn = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
        if spawn then
            return instance_position(spawn)
        end
        local safe_part = workspace:FindFirstChild("SafeZone", true) or workspace:FindFirstChild("Spawn", true)
        return instance_position(safe_part)
    end

    local function teleport_to_safe_zone()
        local pos = get_safe_zone_position()
        if not pos then
            return false
        end
        return teleport_near(pos)
    end

    local function walk_to(position, radius, timeout)
        local root = get_root()
        local hum = get_humanoid()
        if not root or not hum or not position then
            return false
        end
        local deadline = os.clock() + (timeout or 6)
        hum:MoveTo(position)
        while os.clock() < deadline and is_active_session() do
            if not root.Parent then
                return false
            end
            local cur = root.Position
            if distance_between(cur, position) <= radius then
                hum:MoveTo(cur)
                return true
            end
            task.wait(0.08)
        end
        hum:MoveTo(root.Position)
        return distance_between(root.Position, position) <= (radius + 4)
    end

    local function nearest_key(origin)
        local best, best_d = nil, math.huge
        for _, key in ipairs(world_cache.keys) do
            local pos = instance_position(key)
            if pos then
                local d = distance_between(pos, origin)
                if d < best_d then
                    best, best_d = key, d
                end
            end
        end
        return best
    end

    local function teleport_to_marker(kind)
        local root = get_root()
        local cam = workspace.CurrentCamera
        local origin = (root and root.Position) or (cam and cam.CFrame.Position)
        if not origin then
            return false
        end

        local pos = nil
        if kind == "Safe Zone" then
            pos = get_safe_zone_position()
        elseif kind == "Kertas Kode" then
            pos = instance_position(world_cache.note)
        elseif kind == "Key Terdekat" then
            pos = instance_position(nearest_key(origin))
        end

        if not pos then
            return false
        end
        return teleport_near(pos)
    end

    local function find_loot_target(origin)
        local best, best_d = nil, math.huge
        local max_range = 260

        local function consider(prompt, pos)
            if not prompt or not prompt.Enabled or not pos or is_hiding_or_keypad_prompt(prompt) then
                return
            end
            local exp = loot_blacklist[prompt]
            if exp and exp > os.clock() then
                return
            end
            local d = distance_between(pos, origin)
            if d <= max_range and d < best_d then
                best_d = d
                best = { prompt = prompt, position = pos }
            end
        end

        if state.loot_drawers then
            for _, prompt in ipairs(world_cache.drawers) do
                consider(prompt, prompt_position(prompt))
            end
        end

        if state.loot_keys then
            for _, key in ipairs(world_cache.keys) do
                consider(find_pickup_prompt(key), instance_position(key))
            end
        end

        if state.loot_note and world_cache.note then
            consider(find_pickup_prompt(world_cache.note), instance_position(world_cache.note))
        end

        if state.loot_flipflops then
            for _, prompt in ipairs(world_cache.flipflops) do
                consider(prompt, prompt_position(prompt))
            end
        end

        return best
    end

    local function loot_step()
        if not is_active_session() or not state.auto_loot or not is_alive() then
            return
        end

        local root = get_root()
        if not root then
            return
        end

        if state.stop_loot_on_chase then
            local opah = opah_summary()
            if opah and opah.chasing then
                return
            end
        end

        local target = find_loot_target(root.Position)
        if not target then
            return
        end

        -- Mode Loot: OFF = Teleport / ON = Walk
        if state.loot_walk_mode then
            local reached = walk_to(target.position, 7, 6)
            if not reached then
                loot_blacklist[target.prompt] = os.clock() + 12
                return
            end
        else
            teleport_near(target.position)
            task.wait(0.15)
        end

        if trigger_prompt(target.prompt) then
            loot_blacklist[target.prompt] = os.clock() + 8
        else
            loot_blacklist[target.prompt] = os.clock() + 3
        end
        task.wait(0.18)
    end

    local function auto_safe_zone_step()
        if not is_active_session() or not state.auto_safe_zone or not is_alive() then
            return
        end
        local opah = opah_summary()
        if not opah or not opah.chasing then
            return
        end
        local now = os.clock()
        if (now - safe_zone_cooldown) < 1.2 then
            return
        end
        if teleport_to_safe_zone() then
            safe_zone_cooldown = now
        end
    end

    local function is_papan_lepaskan_prompt(prompt)
        if not prompt or not prompt:IsA("ProximityPrompt") then
            return false
        end
        local act = string.lower(tostring(prompt.ActionText or ""))
        local obj = string.lower(tostring(prompt.ObjectText or ""))
        local pname = string.lower(tostring(prompt.Name or ""))
        if act:find("lepaskan", 1, true) or act:find("release", 1, true) or act:find("drop", 1, true) or act:find("lepas", 1, true) then
            return true
        end
        if obj:find("papan", 1, true) or obj:find("plank", 1, true) or pname:find("papan", 1, true) or pname:find("plank", 1, true) then
            return true
        end
        local curr = prompt.Parent
        local hops = 0
        while curr and curr ~= workspace and hops < 6 do
            local cname = string.lower(tostring(curr.Name or ""))
            if cname:find("papan", 1, true) or cname:find("plank", 1, true) or cname:find("board", 1, true) then
                return true
            end
            curr = curr.Parent
            hops += 1
        end
        return false
    end

    local function trigger_papan_prompt(prompt)
        if not prompt or not prompt.Parent or not prompt.Enabled then
            return false
        end
        local fired = false
        if type(fireproximityprompt) == "function" then
            local ok = pcall(fireproximityprompt, prompt)
            if ok then
                fired = true
            end
        end
        if not fired then
            local ok_hold = pcall(function()
                prompt:InputHoldBegin()
                task.wait(0.04)
                prompt:InputHoldEnd()
            end)
            return ok_hold
        end
        return fired
    end

    --== Auto Open Laci Tertutup & Ambil Item Berdekatan (Tanpa Emergency Shop, Almari & Keypad) ==
    local function auto_open_and_collect_step()
        if not is_active_session() or not state.auto_open_collect or nearby_interact_busy or not is_alive() then
            return
        end
        local root = get_root()
        if not root then
            return
        end

        nearby_interact_busy = true
        local ok_run, err_run = pcall(function()
            -- 0. Auto Lepaskan Papan jika sedang memegang Papan / prompt "Lepaskan" aktif
            for _, desc in ipairs(workspace:GetDescendants()) do
                if not is_active_session() or not state.auto_open_collect then
                    break
                end
                if is_papan_lepaskan_prompt(desc) and desc.Enabled then
                    trigger_papan_prompt(desc)
                    task.wait(0.06)
                end
            end
            if LocalPlayer then
                local char = LocalPlayer.Character
                local containers = { LocalPlayer:FindFirstChildOfClass("Backpack"), char }
                for _, container in ipairs(containers) do
                    if container then
                        for _, tool in ipairs(container:GetChildren()) do
                            if tool:IsA("Tool") then
                                local tname = string.lower(tostring(tool.Name or ""))
                                if tname:find("papan", 1, true) or tname:find("plank", 1, true) then
                                    pcall(function()
                                        for _, desc in ipairs(tool:GetDescendants()) do
                                            if desc:IsA("ProximityPrompt") and desc.Enabled then
                                                trigger_papan_prompt(desc)
                                            end
                                        end
                                    end)
                                end
                            end
                        end
                    end
                end
            end

            local origin = root.Position
            local max_dist = 24
            local seen_cand = {}
            local closed_drawers = {}
            local item_prompts = {}

            local function try_add_item(p, pos)
                if not p or not p.Parent or not p.Enabled or seen_cand[p] then
                    return
                end
                if is_hiding_or_keypad_prompt(p) or is_shop_or_emergency_prompt(p) then
                    return
                end
                local target_pos = pos or prompt_position(p)
                local dist = target_pos and distance_between(target_pos, origin) or math.huge
                local reach = math.max(max_dist, (tonumber(p.MaxActivationDistance) or 12) + 6)
                if dist <= reach then
                    seen_cand[p] = true
                    table.insert(item_prompts, p)
                end
            end

            local function try_add_closed_drawer(p, pos)
                if not p or not p.Parent or not p.Enabled or seen_cand[p] then
                    return
                end
                if is_hiding_or_keypad_prompt(p) or is_shop_or_emergency_prompt(p) then
                    return
                end
                if is_drawer_already_open(p) then
                    return
                end
                local target_pos = pos or prompt_position(p)
                local dist = target_pos and distance_between(target_pos, origin) or math.huge
                local reach = math.max(max_dist, (tonumber(p.MaxActivationDistance) or 12) + 4)
                if dist <= reach then
                    seen_cand[p] = true
                    table.insert(closed_drawers, p)
                end
            end

            -- 1. Prioriti ambil item yang sudah kelihatan/boleh diambil dahulu supaya tidak terlepas bila laci bergerak
            for _, p in ipairs(world_cache.collectibles or {}) do
                try_add_item(p, prompt_position(p))
            end

            for _, key in ipairs(world_cache.keys) do
                try_add_item(find_pickup_prompt(key), instance_position(key))
            end

            if world_cache.note then
                try_add_item(find_pickup_prompt(world_cache.note), instance_position(world_cache.note))
            end

            for _, prompt in ipairs(world_cache.flipflops) do
                try_add_item(prompt, prompt_position(prompt))
            end

            for _, p in ipairs(item_prompts) do
                if not is_active_session() or not state.auto_open_collect then
                    break
                end
                trigger_prompt(p)
                task.wait(0.08)
            end

            -- 2. Buka laci yang tertutup sahaja (tidak trigger semula laci yang sudah terbuka)
            for _, prompt in ipairs(world_cache.drawers) do
                try_add_closed_drawer(prompt, prompt_position(prompt))
            end

            for _, p in ipairs(closed_drawers) do
                if not is_active_session() or not state.auto_open_collect then
                    break
                end
                if not is_drawer_already_open(p) then
                    if trigger_prompt(p) then
                        drawer_opened_cooldown[p] = os.clock() + 18
                        task.wait(0.22)
                    end
                end
            end
        end)
        nearby_interact_busy = false
        if not ok_run and err_run then
            warn("[WatHUB] Auto Open And Collect Item:", err_run)
        end
    end

    --== Pencahayaan, Low Grafik & Instant Hold ==
    local orig_lighting = {
        Brightness = Lighting.Brightness,
        GlobalShadows = Lighting.GlobalShadows,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        ExposureCompensation = Lighting.ExposureCompensation,
        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
    }
    local saved_post_effects = {}

    local function set_normal_brightness(enabled)
        local active = (enabled == true) and is_active_session()
        state.brightness = active
        pcall(function()
            if active then
                for _, child in ipairs(Lighting:GetChildren()) do
                    if child:IsA("ColorCorrectionEffect") or child:IsA("Atmosphere") then
                        if saved_post_effects[child] == nil then
                            if child:IsA("ColorCorrectionEffect") then
                                saved_post_effects[child] = child.Enabled
                                child.Enabled = false
                            elseif child:IsA("Atmosphere") then
                                saved_post_effects[child] = child.Density
                                child.Density = 0
                            end
                        end
                    end
                end
                Lighting.Brightness = 4.5
                Lighting.GlobalShadows = false
                Lighting.Ambient = Color3.fromRGB(235, 235, 235)
                Lighting.OutdoorAmbient = Color3.fromRGB(235, 235, 235)
                Lighting.ExposureCompensation = 0.85
                Lighting.EnvironmentSpecularScale = 1
                Lighting.EnvironmentDiffuseScale = 1
            else
                Lighting.Brightness = orig_lighting.Brightness
                Lighting.GlobalShadows = orig_lighting.GlobalShadows
                Lighting.Ambient = orig_lighting.Ambient
                Lighting.OutdoorAmbient = orig_lighting.OutdoorAmbient
                Lighting.ExposureCompensation = orig_lighting.ExposureCompensation
                Lighting.EnvironmentSpecularScale = orig_lighting.EnvironmentSpecularScale
                Lighting.EnvironmentDiffuseScale = orig_lighting.EnvironmentDiffuseScale
                for inst, prev_val in pairs(saved_post_effects) do
                    if inst and inst.Parent then
                        if inst:IsA("ColorCorrectionEffect") then
                            inst.Enabled = prev_val
                        elseif inst:IsA("Atmosphere") then
                            inst.Density = prev_val
                        end
                    end
                end
                table.clear(saved_post_effects)
            end
        end)
    end

    local saved_gfx_effects = {}
    local saved_gfx_parts = {}
    local function set_low_graphics(enabled)
        local active = (enabled == true) and is_active_session()
        state.low_graphics = active
        pcall(function()
            if active then
                Lighting.GlobalShadows = false
                for _, inst in ipairs(workspace:GetDescendants()) do
                    if inst:IsA("BloomEffect") or inst:IsA("SunRaysEffect") or inst:IsA("DepthOfFieldEffect") then
                        if saved_gfx_effects[inst] == nil then
                            saved_gfx_effects[inst] = inst.Enabled
                            inst.Enabled = false
                        end
                    elseif inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Smoke") or inst:IsA("Fire") then
                        if saved_gfx_effects[inst] == nil then
                            saved_gfx_effects[inst] = inst.Enabled
                            inst.Enabled = false
                        end
                    elseif inst:IsA("BasePart") then
                        if inst.Material ~= Enum.Material.SmoothPlastic and inst.Material ~= Enum.Material.Neon then
                            if saved_gfx_parts[inst] == nil then
                                saved_gfx_parts[inst] = {
                                    Material = inst.Material,
                                    CastShadow = inst.CastShadow,
                                }
                            end
                            inst.Material = Enum.Material.SmoothPlastic
                        end
                        inst.CastShadow = false
                    end
                end
            else
                if not state.brightness then
                    Lighting.GlobalShadows = orig_lighting.GlobalShadows
                end
                for inst, prev_enabled in pairs(saved_gfx_effects) do
                    if inst and inst.Parent then
                        inst.Enabled = prev_enabled
                    end
                end
                table.clear(saved_gfx_effects)

                for part, prev_data in pairs(saved_gfx_parts) do
                    if part and part.Parent and type(prev_data) == "table" then
                        if prev_data.Material then
                            part.Material = prev_data.Material
                        end
                        if type(prev_data.CastShadow) == "boolean" then
                            part.CastShadow = prev_data.CastShadow
                        end
                    end
                end
                table.clear(saved_gfx_parts)
            end
        end)
    end

    local instant_hold_conn = nil
    local function apply_instant_hold_to_prompt(prompt)
        if not prompt or not prompt:IsA("ProximityPrompt") then
            return
        end
        if prompt:GetAttribute("OrigHold") == nil then
            prompt:SetAttribute("OrigHold", prompt.HoldDuration)
        end
        if prompt.HoldDuration ~= 0 then
            prompt.HoldDuration = 0
        end
    end

    local function set_instant_hold(enabled)
        local active = (enabled == true) and is_active_session()
        state.instant_hold = active
        if instant_hold_conn then
            pcall(function() instant_hold_conn:Disconnect() end)
            instant_hold_conn = nil
        end
        if active then
            instant_hold_conn = track(ProximityPromptService.PromptShown:Connect(function(prompt)
                if is_active_session() and state.instant_hold and prompt then
                    apply_instant_hold_to_prompt(prompt)
                end
            end))
            task.spawn(function()
                local count = 0
                for _, p in ipairs(workspace:GetDescendants()) do
                    if not is_active_session() or not state.instant_hold then
                        break
                    end
                    if p:IsA("ProximityPrompt") then
                        apply_instant_hold_to_prompt(p)
                        count += 1
                        if (count % 200) == 0 then
                            task.wait()
                        end
                    end
                end
            end)
        else
            pcall(function()
                for _, p in ipairs(workspace:GetDescendants()) do
                    if p:IsA("ProximityPrompt") then
                        local old_h = p:GetAttribute("OrigHold")
                        if type(old_h) == "number" then
                            p.HoldDuration = old_h
                        end
                    end
                end
            end)
        end
    end

    --== Noclip & Speed (Slider 0-100, Default 25) ==
    local noclip_conn = nil
    local function restore_character_collision()
        pcall(function()
            local char = LocalPlayer and LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        local orig_c = part:GetAttribute("WatOrigCanCollide")
                        if type(orig_c) == "boolean" then
                            part.CanCollide = orig_c
                        elseif part.Name == "HumanoidRootPart" then
                            part.CanCollide = false
                        else
                            part.CanCollide = true
                        end
                    end
                end
            end
        end)
    end

    local function set_noclip(enabled)
        local active = (enabled == true) and is_active_session()
        state.noclip = active
        if noclip_conn then
            pcall(function() noclip_conn:Disconnect() end)
            noclip_conn = nil
        end
        if active then
            noclip_conn = track(RunService.Stepped:Connect(function()
                if not is_active_session() or not state.noclip then
                    return
                end
                local char = LocalPlayer and LocalPlayer.Character
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            if part:GetAttribute("WatOrigCanCollide") == nil then
                                part:SetAttribute("WatOrigCanCollide", part.CanCollide)
                            end
                            part.CanCollide = false
                        end
                    end
                end
            end))
        else
            restore_character_collision()
        end
    end

    local speed_conn = nil
    local speed_prop_conn = nil
    local function get_target_speed()
        return math.clamp(tonumber(state.speed_value) or DEFAULT_SPEED_VALUE, 0, 100)
    end

    local function apply_walkspeed_now(force_target)
        pcall(function()
            local hum = get_humanoid()
            if hum then
                if is_active_session() and state.speed then
                    local spd = get_target_speed()
                    if force_target or hum.WalkSpeed ~= spd then
                        hum.WalkSpeed = spd
                    end
                else
                    hum.WalkSpeed = 16
                end
            end
        end)
    end

    local function hook_humanoid_speed(hum)
        if speed_prop_conn then
            pcall(function() speed_prop_conn:Disconnect() end)
            speed_prop_conn = nil
        end
        if hum and is_active_session() and state.speed then
            speed_prop_conn = track(hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                if is_active_session() and state.speed then
                    local spd = get_target_speed()
                    if hum.WalkSpeed ~= spd then
                        hum.WalkSpeed = spd
                    end
                end
            end))
        end
    end

    local function set_speed(enabled)
        local active = (enabled == true) and is_active_session()
        state.speed = active
        if speed_conn then
            pcall(function() speed_conn:Disconnect() end)
            speed_conn = nil
        end
        if speed_prop_conn then
            pcall(function() speed_prop_conn:Disconnect() end)
            speed_prop_conn = nil
        end
        apply_walkspeed_now(active)
        if active then
            local hum = get_humanoid()
            if hum then
                hook_humanoid_speed(hum)
            end
            speed_conn = track(RunService.Heartbeat:Connect(function()
                if is_active_session() and state.speed then
                    local h = get_humanoid()
                    local spd = get_target_speed()
                    if h and h.WalkSpeed ~= spd then
                        h.WalkSpeed = spd
                    end
                end
            end))
        end
    end

    local function set_speed_value(val)
        state.speed_value = math.clamp(math.floor((tonumber(val) or DEFAULT_SPEED_VALUE) + 0.5), 0, 100)
        if state.speed then
            apply_walkspeed_now(true)
        end
    end

    --== Gelung Latar ==
    local my_sid = state.session_id
    task.spawn(function()
        while not state.closed and state.session_id == my_sid do
            pcall(scan_world)
            task.wait(1.2)
        end
    end)

    task.spawn(function()
        while not state.closed and state.session_id == my_sid do
            pcall(refresh_active_esp)
            task.wait(0.75)
        end
    end)

    task.spawn(function()
        while not state.closed and state.session_id == my_sid do
            pcall(update_overlays)
            task.wait(0.25)
        end
    end)

    task.spawn(function()
        while not state.closed and state.session_id == my_sid do
            if state.auto_loot then
                pcall(loot_step)
            end
            task.wait(0.35)
        end
    end)

    task.spawn(function()
        while not state.closed and state.session_id == my_sid do
            if state.auto_safe_zone then
                pcall(auto_safe_zone_step)
            end
            task.wait(0.25)
        end
    end)

    task.spawn(function()
        while not state.closed and state.session_id == my_sid do
            if state.auto_open_collect then
                pcall(auto_open_and_collect_step)
            end
            task.wait(0.55)
        end
    end)

    local function kill_all_features()
        state.closed = true
        state.active_session_id = -1
        state.esp_opah = false
        state.esp_key = false
        state.esp_code_paper = false
        state.esp_flipflop = false
        state.opah_mode = false
        state.passcode_overlay = false
        state.auto_loot = false
        state.auto_safe_zone = false
        state.auto_open_collect = false
        state.noclip = false
        state.speed = false
        state.brightness = false
        state.low_graphics = false
        state.instant_hold = false

        if noclip_conn then
            pcall(function() noclip_conn:Disconnect() end)
            noclip_conn = nil
        end
        if speed_conn then
            pcall(function() speed_conn:Disconnect() end)
            speed_conn = nil
        end
        if speed_prop_conn then
            pcall(function() speed_prop_conn:Disconnect() end)
            speed_prop_conn = nil
        end
        if instant_hold_conn then
            pcall(function() instant_hold_conn:Disconnect() end)
            instant_hold_conn = nil
        end

        clear_esp_group(nil)
        set_low_graphics(false)
        set_normal_brightness(false)
        set_instant_hold(false)
        restore_character_collision()
        apply_walkspeed_now(false)

        if esp_folder and esp_folder.Parent then
            pcall(function() esp_folder:Destroy() end)
        end
        if radar_gui and radar_gui.Parent then
            pcall(function() radar_gui:Destroy() end)
        end
        if pass_gui and pass_gui.Parent then
            pcall(function() pass_gui:Destroy() end)
        end
    end

    pcall(scan_world)

    return {
        refresh_active_esp = refresh_active_esp,
        update_overlays = update_overlays,
        teleport_to_marker = teleport_to_marker,
        set_normal_brightness = set_normal_brightness,
        set_low_graphics = set_low_graphics,
        set_instant_hold = set_instant_hold,
        set_noclip = set_noclip,
        set_speed = set_speed,
        set_speed_value = set_speed_value,
        kill_all_features = kill_all_features,
    }
end

local function build_wathub()
    local parent_gui = (type(gethui) == "function" and gethui()) or (LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui"))
    if not parent_gui then
        return
    end

    for _, name in ipairs({ "WatHUB_UI", "WatHUB_OpahMode", "WatHUB_PasscodeOverlay" }) do
        local old = parent_gui:FindFirstChild(name)
        if old then
            old:Destroy()
        end
    end

    local connections = {}
    local function track(conn)
        table.insert(connections, conn)
        return conn
    end

    local state = {
        closed = false,
        session_id = 1,
        active_session_id = 1,
        brightness = false,
        low_graphics = false,
        instant_hold = true,
        -- ESP
        esp_opah = false,
        esp_key = false,
        esp_code_paper = false,
        esp_flipflop = false,
        -- Opah Mode & Overlay
        opah_mode = false,
        passcode_overlay = false,
        detected_code = nil,
        -- Auto Loot, Auto Safe Zone & Auto Open And Collect Item
        auto_loot = false,
        loot_drawers = true,
        loot_keys = true,
        loot_note = true,
        loot_flipflops = false,
        loot_walk_mode = false, -- OFF = Teleport / ON = Walk
        stop_loot_on_chase = true,
        auto_safe_zone = false,
        auto_open_collect = false,
        -- Player
        noclip = false,
        speed = false,
        speed_value = DEFAULT_SPEED_VALUE,
        -- Settings
        toast_enabled = true,
    }

    local themed_cards = {}
    local themed_outlines = {}

    local gui = Instance.new("ScreenGui")
    gui.Name = "WatHUB_UI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = parent_gui

    local toast_holder = Instance.new("Frame")
    toast_holder.Size = UDim2.new(0, 260, 1, -20)
    toast_holder.Position = UDim2.new(1, -270, 0, 10)
    toast_holder.BackgroundTransparency = 1
    toast_holder.ZIndex = 30
    toast_holder.Parent = gui

    local toast_layout = Instance.new("UIListLayout")
    toast_layout.Padding = UDim.new(0, 6)
    toast_layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    toast_layout.SortOrder = Enum.SortOrder.LayoutOrder
    toast_layout.Parent = toast_holder

    local function push_toast(title_txt, body_txt)
        if not state.toast_enabled or state.closed or state.session_id ~= state.active_session_id then
            return
        end
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 48)
        card.BackgroundColor3 = Theme.BgCard
        card.BorderSizePixel = 0
        card.ZIndex = 31
        card.Parent = toast_holder
        add_corner(card, Theme.CornerMd)
        add_stroke(card, Theme.OutlineGold, 1.2)

        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, -14, 0, 18)
        t.Position = UDim2.fromOffset(7, 4)
        t.BackgroundTransparency = 1
        t.Text = tostring(title_txt)
        t.TextColor3 = Theme.TextPrimary
        t.Font = Enum.Font.GothamBold
        t.TextSize = 11
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.ZIndex = 32
        t.Parent = card

        local b = Instance.new("TextLabel")
        b.Size = UDim2.new(1, -14, 0, 20)
        b.Position = UDim2.fromOffset(7, 22)
        b.BackgroundTransparency = 1
        b.Text = tostring(body_txt)
        b.TextColor3 = Theme.TextSecondary
        b.Font = Enum.Font.Gotham
        b.TextSize = 10
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.TextTruncate = Enum.TextTruncate.AtEnd
        b.ZIndex = 32
        b.Parent = card

        local my_sid = state.session_id
        task.delay(2.4, function()
            if state.closed or state.session_id ~= my_sid then
                if card then
                    pcall(function() card:Destroy() end)
                end
                return
            end
            if card and card.Parent then
                card:Destroy()
            end
        end)
    end

    local ctrl = create_feature_controllers(state, track, parent_gui)

    local DEFAULT_MAIN_POS = UDim2.new(0.5, -235, 0.5, -150)
    local DEFAULT_RESTORE_POS = UDim2.new(0, 18, 0.45, 0)

    local main = Instance.new("Frame")
    main.Name = "MainFrame"
    main.Size = UDim2.fromOffset(470, 300)
    main.Position = DEFAULT_MAIN_POS
    main.BackgroundColor3 = Theme.BgMain
    main.BorderSizePixel = 0
    main.ZIndex = 2
    main.Parent = gui
    add_corner(main, Theme.CornerLg)
    add_stroke(main, Theme.OutlineGold, 1.6)

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 38)
    header.BackgroundColor3 = Theme.BgHeader
    header.BorderSizePixel = 0
    header.ZIndex = 3
    header.Parent = main
    add_corner(header, Theme.CornerLg)

    local header_bottom_line = Instance.new("Frame")
    header_bottom_line.Name = "HeaderWToXOutline"
    header_bottom_line.Size = UDim2.new(1, -22, 0, 2)
    header_bottom_line.Position = UDim2.new(0, 14, 1, -2)
    header_bottom_line.BackgroundColor3 = Theme.OutlineGold
    header_bottom_line.BorderSizePixel = 0
    header_bottom_line.ZIndex = 5
    header_bottom_line.Parent = header
    add_corner(header_bottom_line, 999)
    table.insert(themed_cards, header_bottom_line)

    local green_hex = to_rich_hex(Theme.ToggleOnGreen)
    local gold_hex = to_rich_hex(Theme.OutlineGold)
    local white_hex = to_rich_hex(Theme.TextPrimary)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -90, 1, 0)
    title.Position = UDim2.fromOffset(14, 0)
    title.BackgroundTransparency = 1
    title.RichText = true
    title.Text = string.format(
        '<font color="%s">W</font><font color="%s">atHUB | </font><font color="%s">%s</font>',
        green_hex,
        white_hex,
        gold_hex,
        escape_rich_text(game_name)
    )
    title.TextColor3 = Theme.TextPrimary
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextTruncate = Enum.TextTruncate.AtEnd
    title.ZIndex = 4
    title.Parent = header

    local restore_icon = Instance.new("TextButton")
    restore_icon.Name = "FloatRestoreW"
    restore_icon.Size = UDim2.fromOffset(44, 44)
    restore_icon.Position = DEFAULT_RESTORE_POS
    restore_icon.BackgroundColor3 = Theme.BgCard
    restore_icon.Text = "W"
    restore_icon.TextColor3 = Theme.ToggleOnGreen
    restore_icon.Font = Enum.Font.GothamBold
    restore_icon.TextSize = 18
    restore_icon.BorderSizePixel = 0
    restore_icon.Visible = false
    restore_icon.ZIndex = 25
    restore_icon.Parent = gui
    add_corner(restore_icon, 999)
    local restore_icon_stroke = add_stroke(restore_icon, Theme.OutlineGold, 1.8)
    attach_moving_rgb_outline(restore_icon_stroke, state)

    local icon_img = Instance.new("ImageLabel")
    icon_img.Name = "CustomIconImage"
    icon_img.Size = UDim2.fromScale(1, 1)
    icon_img.BackgroundTransparency = 1
    icon_img.Image = ""
    icon_img.ScaleType = Enum.ScaleType.Fit
    icon_img.Visible = false
    icon_img.ZIndex = 26
    icon_img.Parent = restore_icon
    add_corner(icon_img, 999)

    local current_icon_ver = ACTIVE_ICON_VERSION
    local function apply_icon_version(ver)
        current_icon_ver = (ver == 1) and 1 or 2
        if current_icon_ver == 1 then
            icon_img.Image = ""
            icon_img.Visible = false
            restore_icon.Text = "W"
            restore_icon.TextColor3 = Theme.ToggleOnGreen
        else
            local num_id = tonumber(CUSTOM_LOGO_ASSET_ID)
            if num_id and num_id > 0 then
                local asset_str = "rbxassetid://" .. tostring(math.floor(num_id))
                icon_img.Image = asset_str
                icon_img.Visible = true
                restore_icon.Text = ""
                task.spawn(function()
                    pcall(function()
                        game:GetService("ContentProvider"):PreloadAsync({ icon_img })
                    end)
                    if icon_img and icon_img.Parent and icon_img.Image == asset_str then
                        icon_img.Visible = true
                        restore_icon.Text = ""
                    end
                end)
            else
                icon_img.Image = ""
                icon_img.Visible = false
                restore_icon.Text = "W"
                restore_icon.TextColor3 = Theme.ToggleOnGreen
            end
        end
    end

    apply_icon_version(ACTIVE_ICON_VERSION)

    local min_btn = Instance.new("TextButton")
    min_btn.Size = UDim2.fromOffset(26, 24)
    min_btn.Position = UDim2.new(1, -64, 0.5, -12)
    min_btn.BackgroundColor3 = Theme.BgRow
    min_btn.Text = "-"
    min_btn.TextColor3 = Theme.TextPrimary
    min_btn.Font = Enum.Font.GothamBold
    min_btn.TextSize = 14
    min_btn.BorderSizePixel = 0
    min_btn.ZIndex = 4
    min_btn.Parent = header
    add_corner(min_btn, Theme.CornerSm)

    local close_btn = Instance.new("TextButton")
    close_btn.Size = UDim2.fromOffset(26, 24)
    close_btn.Position = UDim2.new(1, -34, 0.5, -12)
    close_btn.BackgroundColor3 = Theme.BgRow
    close_btn.Text = "X"
    close_btn.TextColor3 = Theme.TextPrimary
    close_btn.Font = Enum.Font.GothamBold
    close_btn.TextSize = 11
    close_btn.BorderSizePixel = 0
    close_btn.ZIndex = 4
    close_btn.Parent = header
    add_corner(close_btn, Theme.CornerSm)

    local function make_draggable(drag_handle, target_frame, opts)
        local threshold = (opts and opts.threshold) or 0
        local allow_click_on_short_drag = (opts and opts.on_tap) ~= nil
        local dragging = false
        local drag_committed = false
        local drag_start, start_pos

        track(drag_handle.InputBegan:Connect(function(input)
            if state.closed then
                return
            end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                drag_committed = (threshold <= 0)
                drag_start = input.Position
                start_pos = target_frame.Position
            end
        end))

        track(UserInputService.InputChanged:Connect(function(input)
            if not dragging or state.closed then
                return
            end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                local delta = input.Position - drag_start
                if not drag_committed then
                    if delta.Magnitude >= threshold then
                        drag_committed = true
                    else
                        return
                    end
                end
                target_frame.Position = UDim2.new(
                    start_pos.X.Scale,
                    start_pos.X.Offset + delta.X,
                    start_pos.Y.Scale,
                    start_pos.Y.Offset + delta.Y
                )
            end
        end))

        track(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if dragging and allow_click_on_short_drag and not drag_committed then
                    opts.on_tap()
                end
                dragging = false
                drag_committed = false
            end
        end))
    end

    make_draggable(header, main)
    make_draggable(restore_icon, restore_icon, {
        threshold = ICON_DRAG_THRESHOLD,
        on_tap = function()
            if state.closed then
                return
            end
            restore_icon.Visible = false
            main.Visible = true
        end,
    })

    track(min_btn.Activated:Connect(function()
        if state.closed then
            return
        end
        main.Visible = false
        restore_icon.Visible = true
    end))

    track(restore_icon.Activated:Connect(function()
        if state.closed then
            return
        end
        restore_icon.Visible = false
        main.Visible = true
    end))

    track(close_btn.Activated:Connect(function()
        if state.closed then
            return
        end
        ctrl.kill_all_features()
        for _, c in ipairs(connections) do
            pcall(function() c:Disconnect() end)
        end
        table.clear(connections)
        if gui and gui.Parent then
            pcall(function() gui:Destroy() end)
        end
    end))

    local sidebar = Instance.new("ScrollingFrame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 134, 1, -46)
    sidebar.Position = UDim2.fromOffset(8, 42)
    sidebar.BackgroundColor3 = Theme.BgSidebar
    sidebar.BorderSizePixel = 0
    sidebar.ScrollBarThickness = 2
    sidebar.CanvasSize = UDim2.fromOffset(0, 0)
    sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sidebar.ZIndex = 3
    sidebar.Parent = main
    add_corner(sidebar, Theme.CornerMd)

    local side_layout = Instance.new("UIListLayout")
    side_layout.Padding = UDim.new(0, 5)
    side_layout.SortOrder = Enum.SortOrder.LayoutOrder
    side_layout.Parent = sidebar

    local side_pad = Instance.new("UIPadding")
    side_pad.PaddingTop = UDim.new(0, 6)
    side_pad.PaddingBottom = UDim.new(0, 6)
    side_pad.PaddingLeft = UDim.new(0, 6)
    side_pad.PaddingRight = UDim.new(0, 6)
    side_pad.Parent = sidebar

    build_sidebar_account_card(sidebar, 1, Theme, themed_cards, state)

    local content_area = Instance.new("Frame")
    content_area.Name = "ContentArea"
    content_area.Size = UDim2.new(1, -154, 1, -46)
    content_area.Position = UDim2.fromOffset(148, 42)
    content_area.BackgroundTransparency = 1
    content_area.ZIndex = 3
    content_area.Parent = main

    local tabs = {}
    local next_tab_order = 2

    local function select_tab(tab_obj)
        for _, t in ipairs(tabs) do
            t.Page.Visible = (t == tab_obj)
            t.Button.BackgroundColor3 = (t == tab_obj) and Theme.TabActiveBg or Theme.BgRow
            t.Button.TextColor3 = (t == tab_obj) and Theme.TextPrimary or Theme.TextSecondary
        end
    end

    local function create_tab(tab_name, builder_fn)
        local btn = Instance.new("TextButton")
        btn.Name = "Tab_" .. tab_name
        btn.LayoutOrder = next_tab_order
        next_tab_order += 1
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.BackgroundColor3 = Theme.BgRow
        btn.Text = tab_name
        btn.TextColor3 = Theme.TextSecondary
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.BorderSizePixel = 0
        btn.ZIndex = 4
        btn.Parent = sidebar
        add_corner(btn, Theme.CornerSm)
        local tab_stroke = add_stroke(btn, Theme.OutlineGold, 1.2)
        table.insert(themed_outlines, tab_stroke)

        local page = Instance.new("ScrollingFrame")
        page.Name = "Page_" .. tab_name
        page.Size = UDim2.fromScale(1, 1)
        page.BackgroundColor3 = Theme.BgCard
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 3
        page.CanvasSize = UDim2.fromOffset(0, 0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.Visible = false
        page.ZIndex = 3
        page.Parent = content_area
        add_corner(page, Theme.CornerMd)

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 6)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = page

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 8)
        pad.PaddingBottom = UDim.new(0, 8)
        pad.PaddingLeft = UDim.new(0, 8)
        pad.PaddingRight = UDim.new(0, 8)
        pad.Parent = page

        local tab_obj = { Name = tab_name, Button = btn, Page = page }
        table.insert(tabs, tab_obj)

        track(btn.Activated:Connect(function()
            if state.closed then
                return
            end
            select_tab(tab_obj)
        end))

        if builder_fn then
            builder_fn(page)
        end
        return tab_obj
    end

    local function add_header(page, text, order)
        local lbl = Instance.new("TextLabel")
        lbl.LayoutOrder = order
        lbl.Size = UDim2.new(1, 0, 0, 18)
        lbl.BackgroundTransparency = 1
        lbl.Text = string.upper(text)
        lbl.TextColor3 = Theme.OutlineGold
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 10
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        lbl.ZIndex = 4
        lbl.Parent = page
        return lbl
    end

    local function add_info_card(page, title_txt, desc_txt, order, height_px, use_rich, rich_title, desc_color)
        local card = Instance.new("Frame")
        card.LayoutOrder = order
        card.Size = UDim2.new(1, 0, 0, height_px or 46)
        card.BackgroundColor3 = Theme.BgRow
        card.BorderSizePixel = 0
        card.ZIndex = 4
        card.Parent = page
        add_corner(card, Theme.CornerSm)

        local t_lbl = Instance.new("TextLabel")
        t_lbl.Size = UDim2.new(1, -14, 0, 16)
        t_lbl.Position = UDim2.fromOffset(7, 5)
        t_lbl.BackgroundTransparency = 1
        t_lbl.RichText = rich_title == true
        t_lbl.Text = title_txt
        t_lbl.TextColor3 = Theme.TextPrimary
        t_lbl.Font = Enum.Font.GothamBold
        t_lbl.TextSize = 11
        t_lbl.TextXAlignment = Enum.TextXAlignment.Left
        t_lbl.TextTruncate = Enum.TextTruncate.AtEnd
        t_lbl.ZIndex = 5
        t_lbl.Parent = card

        local d_lbl = Instance.new("TextLabel")
        d_lbl.Size = UDim2.new(1, -14, 0, height_px and (height_px - 26) or 18)
        d_lbl.Position = UDim2.fromOffset(7, 22)
        d_lbl.BackgroundTransparency = 1
        d_lbl.RichText = use_rich == true
        d_lbl.Text = desc_txt
        d_lbl.TextColor3 = desc_color or Theme.TextSecondary
        d_lbl.Font = Enum.Font.Gotham
        d_lbl.TextSize = 10
        d_lbl.TextXAlignment = Enum.TextXAlignment.Left
        d_lbl.TextYAlignment = Enum.TextYAlignment.Top
        d_lbl.TextWrapped = true
        d_lbl.ZIndex = 5
        d_lbl.Parent = card

        return card, d_lbl
    end

    local function add_discord_card(page, order)
        local card = Instance.new("Frame")
        card.Name = "DiscordInviteCard"
        card.LayoutOrder = order
        card.Size = UDim2.new(1, 0, 0, 74)
        card.BackgroundColor3 = Theme.BgRow
        card.BorderSizePixel = 0
        card.ZIndex = 4
        card.Parent = page
        add_corner(card, Theme.CornerSm)
        add_stroke(card, Theme.OutlineGold, 1)

        local t_lbl = Instance.new("TextLabel")
        t_lbl.Size = UDim2.new(1, -82, 0, 16)
        t_lbl.Position = UDim2.fromOffset(7, 5)
        t_lbl.BackgroundTransparency = 1
        t_lbl.Text = "Komuniti Discord WatHUB"
        t_lbl.TextColor3 = Theme.TextPrimary
        t_lbl.Font = Enum.Font.GothamBold
        t_lbl.TextSize = 11
        t_lbl.TextXAlignment = Enum.TextXAlignment.Left
        t_lbl.TextTruncate = Enum.TextTruncate.AtEnd
        t_lbl.ZIndex = 5
        t_lbl.Parent = card

        local copy_btn = Instance.new("TextButton")
        copy_btn.Size = UDim2.fromOffset(64, 20)
        copy_btn.Position = UDim2.new(1, -71, 0, 4)
        copy_btn.BackgroundColor3 = Theme.TabActiveBg
        copy_btn.Text = "Copy Link"
        copy_btn.TextColor3 = Theme.OutlineGold
        copy_btn.Font = Enum.Font.GothamBold
        copy_btn.TextSize = 9
        copy_btn.BorderSizePixel = 0
        copy_btn.ZIndex = 6
        copy_btn.Parent = card
        add_corner(copy_btn, Theme.CornerSm)
        add_stroke(copy_btn, Theme.OutlineGold, 1)

        local d_lbl = Instance.new("TextLabel")
        d_lbl.Size = UDim2.new(1, -14, 0, 44)
        d_lbl.Position = UDim2.fromOffset(7, 23)
        d_lbl.BackgroundTransparency = 1
        d_lbl.RichText = true
        d_lbl.Text = string.format(
            'Untuk saran, info update, laporan bug, atau apa-apa sahaja, sila join server Discord: <font color="%s">%s</font>',
            gold_hex,
            escape_rich_text(DISCORD_INVITE_URL)
        )
        d_lbl.TextColor3 = Theme.TextSecondary
        d_lbl.Font = Enum.Font.Gotham
        d_lbl.TextSize = 10
        d_lbl.TextXAlignment = Enum.TextXAlignment.Left
        d_lbl.TextYAlignment = Enum.TextYAlignment.Top
        d_lbl.TextWrapped = true
        d_lbl.ZIndex = 5
        d_lbl.Parent = card

        track(copy_btn.Activated:Connect(function()
            if state.closed then
                return
            end
            local ok = copy_to_clipboard(DISCORD_INVITE_URL)
            if ok then
                copy_btn.Text = "Copied"
                push_toast("Discord", "Link jemputan Discord berjaya disalin")
                task.delay(1.4, function()
                    if copy_btn and copy_btn.Parent then
                        copy_btn.Text = "Copy Link"
                    end
                end)
            else
                push_toast("Discord", "Executor tidak menyokong clipboard")
            end
        end))

        return card
    end

    local function add_action_button(page, label_txt, btn_txt, order, on_click)
        local row = Instance.new("Frame")
        row.LayoutOrder = order
        row.Size = UDim2.new(1, 0, 0, 34)
        row.BackgroundColor3 = Theme.BgRow
        row.BorderSizePixel = 0
        row.ZIndex = 4
        row.Parent = page
        add_corner(row, Theme.CornerSm)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -112, 1, 0)
        lbl.Position = UDim2.fromOffset(10, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label_txt
        lbl.TextColor3 = Theme.TextPrimary
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        lbl.ZIndex = 5
        lbl.Parent = row

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromOffset(94, 22)
        btn.Position = UDim2.new(1, -102, 0.5, -11)
        btn.BackgroundColor3 = Theme.TabActiveBg
        btn.Text = btn_txt
        btn.TextColor3 = Theme.OutlineGold
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        btn.BorderSizePixel = 0
        btn.ZIndex = 5
        btn.Parent = row
        add_corner(btn, Theme.CornerSm)
        add_stroke(btn, Theme.OutlineGold, 1)

        track(btn.Activated:Connect(function()
            if state.closed then
                return
            end
            if on_click then
                on_click(btn)
            end
        end))

        return row, btn
    end

    local function add_toggle(page, label_txt, default_val, order, on_changed, opts)
        local row = Instance.new("Frame")
        row.LayoutOrder = order
        row.Size = UDim2.new(1, 0, 0, 34)
        row.BackgroundColor3 = Theme.BgRow
        row.BorderSizePixel = 0
        row.ZIndex = 4
        row.Parent = page
        add_corner(row, Theme.CornerSm)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -62, 1, 0)
        lbl.Position = UDim2.fromOffset(10, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label_txt
        lbl.TextColor3 = Theme.TextPrimary
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        lbl.ZIndex = 5
        lbl.Parent = row

        local pill = Instance.new("TextButton")
        pill.Size = UDim2.fromOffset(42, 20)
        pill.Position = UDim2.new(1, -50, 0.5, -10)
        pill.Text = ""
        pill.BorderSizePixel = 0
        pill.ZIndex = 5
        pill.Parent = row
        add_corner(pill, 999)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.fromOffset(16, 16)
        knob.BackgroundColor3 = Theme.TextPrimary
        knob.BorderSizePixel = 0
        knob.ZIndex = 6
        knob.Parent = pill
        add_corner(knob, 999)

        local current = default_val == true
        local function paint(val)
            pill.BackgroundColor3 = val and Theme.ToggleOnGreen or Theme.ToggleOffBg
            knob.Position = val and UDim2.fromOffset(24, 2) or UDim2.fromOffset(2, 2)
        end
        paint(current)

        track(pill.Activated:Connect(function()
            if state.closed then
                return
            end
            current = not current
            paint(current)
            if on_changed then
                on_changed(current)
            end
        end))

        return row
    end

    local function add_slider(page, label_txt, min_val, max_val, default_val, order, on_changed)
        local row = Instance.new("Frame")
        row.LayoutOrder = order
        row.Size = UDim2.new(1, 0, 0, 48)
        row.BackgroundColor3 = Theme.BgRow
        row.BorderSizePixel = 0
        row.ZIndex = 4
        row.Parent = page
        add_corner(row, Theme.CornerSm)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -60, 0, 18)
        lbl.Position = UDim2.fromOffset(10, 5)
        lbl.BackgroundTransparency = 1
        lbl.Text = label_txt
        lbl.TextColor3 = Theme.TextPrimary
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 5
        lbl.Parent = row

        local val_lbl = Instance.new("TextLabel")
        val_lbl.Size = UDim2.fromOffset(44, 18)
        val_lbl.Position = UDim2.new(1, -54, 0, 5)
        val_lbl.BackgroundTransparency = 1
        val_lbl.Text = tostring(default_val)
        val_lbl.TextColor3 = Theme.OutlineGold
        val_lbl.Font = Enum.Font.GothamBold
        val_lbl.TextSize = 11
        val_lbl.TextXAlignment = Enum.TextXAlignment.Right
        val_lbl.ZIndex = 5
        val_lbl.Parent = row

        local track_bar = Instance.new("TextButton")
        track_bar.Size = UDim2.new(1, -20, 0, 12)
        track_bar.Position = UDim2.fromOffset(10, 28)
        track_bar.BackgroundColor3 = Theme.ToggleOffBg
        track_bar.Text = ""
        track_bar.AutoButtonColor = false
        track_bar.BorderSizePixel = 0
        track_bar.ZIndex = 5
        track_bar.Parent = row
        add_corner(track_bar, 999)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(0, 0, 1, 0)
        fill.BackgroundColor3 = Theme.ToggleOnGreen
        fill.BorderSizePixel = 0
        fill.ZIndex = 6
        fill.Parent = track_bar
        add_corner(fill, 999)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.fromOffset(16, 16)
        knob.AnchorPoint = Vector2.new(0.5, 0.5)
        knob.Position = UDim2.new(0, 0, 0.5, 0)
        knob.BackgroundColor3 = Theme.TextPrimary
        knob.BorderSizePixel = 0
        knob.ZIndex = 7
        knob.Parent = track_bar
        add_corner(knob, 999)
        add_stroke(knob, Theme.OutlineGold, 1)

        local current_v = math.clamp(math.floor(default_val + 0.5), min_val, max_val)
        local function set_val_from_alpha(alpha)
            local a = math.clamp(alpha, 0, 1)
            local v = math.floor(min_val + (max_val - min_val) * a + 0.5)
            current_v = v
            local real_alpha = (v - min_val) / math.max(1, (max_val - min_val))
            fill.Size = UDim2.new(real_alpha, 0, 1, 0)
            knob.Position = UDim2.new(real_alpha, 0, 0.5, 0)
            val_lbl.Text = tostring(v)
            if on_changed then
                on_changed(v)
            end
        end

        set_val_from_alpha((current_v - min_val) / math.max(1, (max_val - min_val)))

        local sliding = false
        local function update_from_input(input)
            local abs_pos = track_bar.AbsolutePosition.X
            local abs_size = track_bar.AbsoluteSize.X
            if abs_size <= 0 then
                return
            end
            local alpha = (input.Position.X - abs_pos) / abs_size
            set_val_from_alpha(alpha)
        end

        track(track_bar.InputBegan:Connect(function(input)
            if state.closed then
                return
            end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                sliding = true
                update_from_input(input)
            end
        end))

        track(UserInputService.InputChanged:Connect(function(input)
            if not sliding or state.closed then
                return
            end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                update_from_input(input)
            end
        end))

        track(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                sliding = false
            end
        end))

        return row
    end

    --== TAB 1: Home ==
    local home_tab = create_tab("Home", function(page)
        local n = 0
        local function step()
            n += 1
            return n
        end

        add_header(page, "Maklumat Umum", step())
        add_info_card(
            page,
            "Terima kasih kerana memakai script WatHUB",
            string.format(
                'Pemain: <font color="%s">%s</font> (@%s) · Game: <font color="%s">%s</font>',
                green_hex,
                escape_rich_text(safe_display_name()),
                escape_rich_text(safe_player_name()),
                gold_hex,
                escape_rich_text(game_name)
            ),
            step(),
            52,
            true,
            false
        )

        add_info_card(
            page,
            "Panduan Ringkas & Nota",
            "Gunakan tab Main untuk auto loot, auto safe zone & auto open and collect item, ESP untuk penanda objek & opah mode, Teleport untuk bergerak pantas, dan Player untuk noclip & speed. Tekan X untuk tutup serta bersihkan semua fitur.",
            step(),
            64,
            false,
            false
        )

        add_header(page, "Saran, Update & Komuniti", step())
        add_discord_card(page, step())
    end)

    --== TAB 2: Main ==
    create_tab("Main", function(page)
        local n = 0
        local function step()
            n += 1
            return n
        end

        add_header(page, "Pencahayaan & Interaksi", step())
        add_toggle(page, "Brightness", false, step(), function(enabled)
            ctrl.set_normal_brightness(enabled)
            push_toast("Brightness", enabled and "Pencahayaan terang aktif" or "Pencahayaan dipulihkan")
        end)

        add_toggle(page, "Instant Hold", true, step(), function(enabled)
            ctrl.set_instant_hold(enabled)
            push_toast("Instant Hold", enabled and "Tekan 1x tanpa hold aktif" or "Hold normal dipulihkan")
        end)

        add_toggle(page, "Auto Open And Collect Item", false, step(), function(enabled)
            state.auto_open_collect = enabled
            push_toast("Auto Open And Collect Item", enabled and "Buka laci, ambil item & lepaskan papan aktif" or "Auto Open And Collect Item mati")
        end)

        add_header(page, "Auto Loot", step())
        -- Mode Loot : (OFF = Teleport / ON = Walk) di atas Auto Loot
        add_toggle(page, "Mode Loot : (OFF = Teleport / ON = Walk)", false, step(), function(enabled)
            state.loot_walk_mode = enabled
            push_toast("Mode Loot", enabled and "Mod Walk aktif" or "Mod Teleport aktif")
        end)

        add_toggle(page, "Auto Loot", false, step(), function(enabled)
            state.auto_loot = enabled
            push_toast("Auto Loot", enabled and "Auto loot diaktifkan" or "Auto loot dimatikan")
        end)

        add_toggle(page, "Loot Laci", true, step(), function(enabled)
            state.loot_drawers = enabled
        end)

        add_toggle(page, "Loot Key", true, step(), function(enabled)
            state.loot_keys = enabled
        end)

        add_toggle(page, "Loot Kertas Kode", true, step(), function(enabled)
            state.loot_note = enabled
        end)

        add_toggle(page, "Loot Selipar", false, step(), function(enabled)
            state.loot_flipflops = enabled
        end)

        add_toggle(page, "Berhenti Loot ketika Dikejar Opah", true, step(), function(enabled)
            state.stop_loot_on_chase = enabled
        end)

        add_header(page, "Keselamatan", step())
        add_toggle(page, "Auto teleport (saat dikejar opah)", false, step(), function(enabled)
            state.auto_safe_zone = enabled
            push_toast("Auto teleport (saat dikejar opah)", enabled and "Auto teleport ke Safe Zone bila dikejar aktif" or "Auto teleport (saat dikejar opah) mati")
        end)
    end)

    --== TAB 3: ESP ==
    create_tab("ESP", function(page)
        local n = 0
        local function step()
            n += 1
            return n
        end

        add_header(page, "Lokasi Opah & Status", step())
        add_toggle(page, "ESP Opah", false, step(), function(enabled)
            state.esp_opah = enabled
            ctrl.refresh_active_esp()
            push_toast("ESP Opah", enabled and "Highlight semua Opah aktif" or "Highlight Opah mati")
        end)

        add_toggle(page, "Opah Mode", false, step(), function(enabled)
            state.opah_mode = enabled
            ctrl.update_overlays()
            push_toast("Opah Mode", enabled and "Paparan status Opah aktif" or "Paparan status Opah mati")
        end)

        add_header(page, "Lokasi Kunci & Kode", step())
        add_toggle(page, "ESP Key", false, step(), function(enabled)
            state.esp_key = enabled
            ctrl.refresh_active_esp()
            push_toast("ESP Key", enabled and "ESP Key aktif" or "ESP Key mati")
        end)

        add_toggle(page, "ESP Kertas Kode", false, step(), function(enabled)
            state.esp_code_paper = enabled
            ctrl.refresh_active_esp()
            push_toast("ESP Kertas Kode", enabled and "ESP kertas kode aktif" or "ESP kertas kode mati")
        end)

        add_toggle(page, "Paparan Kertas Kode", false, step(), function(enabled)
            state.passcode_overlay = enabled
            ctrl.update_overlays()
            push_toast("Kertas Kode", enabled and "Paparan kod di skrin aktif" or "Paparan kod dimatikan")
        end)
    end)

    --== TAB 4: Teleport ==
    create_tab("Teleport", function(page)
        local n = 0
        local function step()
            n += 1
            return n
        end

        add_header(page, "Lokasi Utama", step())
        local markers = {
            { label = "Teleport ke Safe Zone", target = "Safe Zone" },
            { label = "Teleport ke Kertas Kode", target = "Kertas Kode" },
            { label = "Teleport ke Key Terdekat", target = "Key Terdekat" },
        }

        for _, m in ipairs(markers) do
            add_action_button(page, m.label, "Teleport", step(), function()
                if ctrl.teleport_to_marker(m.target) then
                    push_toast("Teleport", "Berjaya teleport ke " .. m.target)
                else
                    push_toast("Teleport", m.target .. " tidak dijumpai")
                end
            end)
        end
    end)

    --== TAB 5: Player (Noclip & Speed Slider 0-100 Default 25) ==
    create_tab("Player", function(page)
        local n = 0
        local function step()
            n += 1
            return n
        end

        add_header(page, "Movement", step())
        add_info_card(
            page,
            "Info Noclip",
            "Untuk noclip lebih lancar, lakukan lompatan sambil menembusi sesuatu.",
            step(),
            52,
            false,
            false
        )
        add_toggle(page, "Noclip", false, step(), function(enabled)
            ctrl.set_noclip(enabled)
            push_toast("Noclip", enabled and "Noclip lancar aktif" or "Noclip mati")
        end)

        add_toggle(page, "Speed", false, step(), function(enabled)
            ctrl.set_speed(enabled)
            push_toast("Speed", enabled and ("Speed (" .. tostring(state.speed_value) .. ") aktif") or "Speed mati")
        end)

        add_slider(page, "Kelajuan Speed (0 - 100)", 0, 100, DEFAULT_SPEED_VALUE, step(), function(val)
            ctrl.set_speed_value(val)
        end)
    end)

    --== TAB 6: Settings ==
    create_tab("Settings", function(page)
        local n = 0
        local function step()
            n += 1
            return n
        end

        add_header(page, "Antarmuka & Notifikasi", step())
        add_toggle(page, "Notifikasi Toast", true, step(), function(enabled)
            state.toast_enabled = enabled == true
            if state.toast_enabled then
                push_toast("Toast Aktif", "Notifikasi pop-up diaktifkan semula")
            end
        end)

        add_header(page, "Performa Grafik", step())
        add_toggle(page, "Low Grafik", false, step(), function(enabled)
            ctrl.set_low_graphics(enabled)
            push_toast("Low Grafik", enabled and "Mod low grafik diaktifkan" or "Grafik dikembalikan")
        end)

        add_header(page, "Ikon & Posisi", step())
        add_action_button(
            page,
            "Versi Ikon Bulat (Default V2)",
            "Versi " .. tostring(current_icon_ver),
            step(),
            function(btn)
                local next_ver = (current_icon_ver == 2) and 1 or 2
                apply_icon_version(next_ver)
                btn.Text = "Versi " .. tostring(current_icon_ver)
                push_toast("Ikon Bulat", "Tukar ke ikon versi " .. tostring(current_icon_ver))
            end
        )

        add_action_button(
            page,
            "Reset Posisi UI",
            "Reset Posisi",
            step(),
            function()
                main.Position = DEFAULT_MAIN_POS
                restore_icon.Position = DEFAULT_RESTORE_POS
                push_toast("Posisi UI", "Posisi menu dan ikon dikembalikan ke asal")
            end
        )
    end)

    ctrl.set_instant_hold(true)
    if home_tab then
        select_tab(home_tab)
    end
end

build_wathub()