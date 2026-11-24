-- WatHUB Chapter 2 Script (MalamSamaRembo2.lua) — PlaceId: 72594159905471
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local MarketplaceService = game:GetService("MarketplaceService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local CHAPTER_2_PLACE_ID = 72594159905471
local IS_CHAPTER_2_MAP = (game.PlaceId == CHAPTER_2_PLACE_ID)

local LocalPlayer = Players.LocalPlayer
local game_name = "Malam Sama Ayam - Chapter 2"
pcall(function()
    local info = MarketplaceService:GetProductInfo(game.PlaceId)
    if info and info.Name and info.Name ~= "" then
        game_name = info.Name
    end
end)

local DISCORD_INVITE_URL = "https://discord.gg/dcXzTxqmD"

local CUSTOM_LOGO_ASSET_ID = 117209290368597 -- Versi 2: Logo custom
local ACTIVE_ICON_VERSION = 2 -- 1 = Teks 'W' hijau, 2 = Logo custom (default)
local SPEED_VALUE = 27 -- Kelajuan lari bila Speed aktif (boleh laras, contoh 30-38)
local ICON_DRAG_THRESHOLD = 12 -- Jarak minimum (px) sebelum ikon terapung dianggap digeser

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

-- Titik penyesuaian khusus Chapter 2 (boleh tambah kata kunci / label / mekanik baharu di sini)
local CHAPTER_2_CONFIG = {
    EnemyKeywords = { "rembo", "rambo", "monster" },
    KeyKeywords = { "key", "kunci" },
    CodeKeywords = { "code", "paper", "kertas", "note", "clue" },
    ItemKeywords = { "bike", "sepeda", "ban_depan", "bandepan", "photo", "foto", "pusaka", "egg", "telur", "item", "loot" },
    SafeZoneKeywords = { "safe", "safezone", "shelter", "zone", "camp" },
}

local function create_feature_controllers(state, track)
    local esp_folder = Instance.new("Folder")
    esp_folder.Name = "WatHUB_ESP_Folder"
    esp_folder.Parent = workspace

    local opened_drawer_timestamps = {}
    local item_cooldowns = {}
    local item_entries = {}
    local drawer_entries = {}
    local entry_by_inst = {}
    local cache_initialized = false

    local function is_active_session()
        return (not state.closed) and (state.session_id == state.active_session_id)
    end

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

    local function has_any_keyword(low_str, keywords)
        if type(low_str) ~= "string" or low_str == "" or type(keywords) ~= "table" then
            return false
        end
        for _, kw in ipairs(keywords) do
            if string.find(low_str, kw, 1, true) then
                return true
            end
        end
        return false
    end

    local function is_excluded_for_tag(obj, tag)
        local low = string.lower(obj.Name)
        if tag == "rembo" then
            if has_any_keyword(low, { "keypad", "code", "safe", "zone", "door", "pintu", "lamp", "lampu", "light", "spawn" }) then
                return true
            end
        elseif tag == "key" then
            if has_any_keyword(low, { "keypad", "code", "paper", "kertas", "door", "pintu", "safe", "gembok", "lock" }) then
                return true
            end
        elseif tag == "other_items" then
            if has_any_keyword(low, { "bengkel", "board", "papan", "rack", "rak", "slot", "display", "table", "meja", "wall", "dinding", "stand", "holder" }) then
                return true
            end
        end
        return false
    end

    local function boost_bright_color(c3, fallback_color)
        if typeof(c3) ~= "Color3" then
            return fallback_color
        end
        local max_v = math.max(c3.R, c3.G, c3.B)
        local min_v = math.min(c3.R, c3.G, c3.B)
        local sat = (max_v > 0) and ((max_v - min_v) / max_v) or 0
        if max_v < 0.14 or sat < 0.18 then
            return fallback_color
        end
        local scale = 1 / max_v
        return Color3.new(
            math.clamp(c3.R * scale, 0.25, 1),
            math.clamp(c3.G * scale, 0.25, 1),
            math.clamp(c3.B * scale, 0.25, 1)
        )
    end

    local function detect_target_color(target, fallback_color)
        local chosen = nil
        local function check_part(p)
            if chosen then
                return
            end
            if p:IsA("BasePart") then
                local boosted = boost_bright_color(p.Color, nil)
                if boosted then
                    chosen = boosted
                end
            end
        end

        if target:IsA("BasePart") then
            check_part(target)
        elseif target:IsA("Model") then
            if target.PrimaryPart then
                check_part(target.PrimaryPart)
            end
            for _, desc in ipairs(target:GetDescendants()) do
                if chosen then
                    break
                end
                check_part(desc)
            end
        end

        return chosen or fallback_color
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

    local function resolve_item_label(target, tag, default_label)
        if tag == "other_items" and target then
            local low = string.lower(tostring(target.Name or ""))

            if has_any_keyword(low, { "telur", "egg" }) then
                return "Telur Emas"
            end
            if has_any_keyword(low, { "foto", "photo" }) then
                return "Foto"
            end
            if has_any_keyword(low, { "ban_depan", "bandepan", "front_wheel", "frontwheel", "ban" }) then
                return "BikeBan"
            end
            if has_any_keyword(low, { "bike", "sepeda" }) then
                return "Item"
            end

            return default_label or "Item"
        end
        return default_label
    end

    local function attach_esp_to_target(target, tag, default_color, label_text, opts)
        if not is_active_session() or not target or not target.Parent or not esp_folder.Parent then
            return
        end
        local adornee = resolve_adornee(target)
        if not adornee then
            return
        end

        local final_color = (tag == "key") and detect_target_color(target, default_color) or default_color
        local is_big = opts and opts.big_label == true
        local no_label = (opts and opts.no_label == true) or (tag == "rembo") or (not label_text) or (label_text == "")
        local stud_y = (opts and opts.studs_y) or 2.5
        local final_label = resolve_item_label(target, tag, label_text)

        local hl = Instance.new("Highlight")
        hl.FillColor = final_color
        hl.OutlineColor = final_color
        hl.FillTransparency = 0.42
        hl.OutlineTransparency = 0.05
        hl.Adornee = target:IsA("Model") and target or adornee
        hl.Parent = esp_folder
        hl:SetAttribute("WatTag", tag)

        if not no_label and final_label and final_label ~= "" then
            local bb = Instance.new("BillboardGui")
            bb.Size = is_big and UDim2.fromOffset(180, 32) or UDim2.fromOffset(150, 22)
            bb.StudsOffset = Vector3.new(0, stud_y, 0)
            bb.AlwaysOnTop = true
            bb.Parent = esp_folder
            bb.Adornee = adornee
            bb:SetAttribute("WatTag", tag)

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.fromScale(1, 1)
            lbl.BackgroundTransparency = 1
            lbl.Text = final_label
            lbl.TextColor3 = final_color
            lbl.TextStrokeColor3 = Color3.fromRGB(10, 12, 16)
            lbl.TextStrokeTransparency = 0.15
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = is_big and 18 or 12
            lbl.Parent = bb
        end
    end

    local function scan_and_tag(tag, color, keywords, display_label, single_top_only, extra_opts)
        clear_esp_group(tag)
        if not is_active_session() then
            return
        end

        local tagged_roots = {}
        local function is_inside_tagged_root(inst)
            local curr = inst.Parent
            while curr and curr ~= workspace do
                if tagged_roots[curr] then
                    return true
                end
                curr = curr.Parent
            end
            return false
        end

        local best_target = nil
        local best_y = -math.huge

        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj == esp_folder or obj:IsDescendantOf(esp_folder) then
                continue
            end
            if not is_active_session() then
                clear_esp_group(tag)
                return
            end
            if (obj:IsA("BasePart") or obj:IsA("Model")) and not is_inside_tagged_root(obj) and not is_excluded_for_tag(obj, tag) then
                local low = string.lower(obj.Name)
                if has_any_keyword(low, keywords) then
                    tagged_roots[obj] = true
                    if single_top_only then
                        local ad = resolve_adornee(obj)
                        if ad and ad.Position.Y > best_y then
                            best_y = ad.Position.Y
                            best_target = obj
                        end
                    else
                        attach_esp_to_target(obj, tag, color, display_label, extra_opts)
                    end
                end
            end
        end

        if single_top_only and best_target then
            local merged = {
                big_label = true,
                studs_y = 4.2,
            }
            if extra_opts then
                for k, v in pairs(extra_opts) do
                    merged[k] = v
                end
            end
            attach_esp_to_target(best_target, tag, color, display_label, merged)
        end
    end

    local function refresh_active_esp()
        if not is_active_session() then
            clear_esp_group(nil)
            return
        end

        if state.esp_rembo then
            scan_and_tag("rembo", Color3.fromRGB(255, 75, 75), CHAPTER_2_CONFIG.EnemyKeywords, nil, false, { no_label = true })
        else
            clear_esp_group("rembo")
        end

        if state.esp_key then
            scan_and_tag("key", Color3.fromRGB(255, 230, 75), CHAPTER_2_CONFIG.KeyKeywords, "Kunci", false)
        else
            clear_esp_group("key")
        end

        if state.esp_code_paper then
            scan_and_tag("code_paper", Color3.fromRGB(60, 215, 255), CHAPTER_2_CONFIG.CodeKeywords, "Kode", false)
        else
            clear_esp_group("code_paper")
        end

        if state.esp_other_items then
            scan_and_tag(
                "other_items",
                Color3.fromRGB(115, 255, 115),
                CHAPTER_2_CONFIG.ItemKeywords,
                "Item",
                false
            )
        else
            clear_esp_group("other_items")
        end

        if state.esp_safe_zone then
            scan_and_tag("safe_zone", Color3.fromRGB(80, 255, 185), CHAPTER_2_CONFIG.SafeZoneKeywords, "Safe Zone", true)
        else
            clear_esp_group("safe_zone")
        end
    end

    local esp_loop_running = false
    local function ensure_esp_loop()
        if esp_loop_running or not is_active_session() then
            return
        end
        esp_loop_running = true
        local my_sid = state.session_id
        task.spawn(function()
            while not state.closed and state.session_id == my_sid do
                task.wait(1.8)
                if state.closed or state.session_id ~= my_sid then
                    break
                end
                if state.esp_rembo or state.esp_key or state.esp_code_paper or state.esp_other_items or state.esp_safe_zone then
                    pcall(refresh_active_esp)
                end
            end
            esp_loop_running = false
        end)
    end

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

    local HIDING_CABINET_KEYWORDS = {
        "almari",
        "wardrobe",
        "closet",
        "locker",
        "hide",
        "hiding",
        "sembunyi",
        "lemarisembunyi",
        "cabinet_hide",
    }

    local DRAWER_KEYWORDS = {
        "laci",
        "drawer",
        "cabinet",
        "lemari",
        "cupboard",
    }

    local CLOSE_ACTION_KEYWORDS = {
        "tutup",
        "close",
        "shut",
    }

    local function text_matches_keywords(str, keywords)
        if type(str) ~= "string" or str == "" then
            return false
        end
        local low = string.lower(str)
        for _, kw in ipairs(keywords) do
            if string.find(low, kw, 1, true) then
                return true
            end
        end
        return false
    end

    local function text_matches_hiding_cabinet(str)
        return text_matches_keywords(str, HIDING_CABINET_KEYWORDS)
    end

    local function is_hiding_cabinet_prompt(prompt)
        if not prompt then
            return false
        end
        if text_matches_hiding_cabinet(prompt.Name)
            or text_matches_hiding_cabinet(prompt.ActionText)
            or text_matches_hiding_cabinet(prompt.ObjectText)
        then
            return true
        end

        local curr = prompt.Parent
        local depth = 0
        while curr and curr ~= workspace and depth < 6 do
            if text_matches_hiding_cabinet(curr.Name) then
                return true
            end
            curr = curr.Parent
            depth += 1
        end
        return false
    end

    local function is_drawer_interaction(inst)
        if not inst then
            return false
        end
        if inst:IsA("ProximityPrompt") then
            if text_matches_keywords(inst.ActionText, CLOSE_ACTION_KEYWORDS) then
                return "close_action"
            end
            if text_matches_keywords(inst.Name, DRAWER_KEYWORDS)
                or text_matches_keywords(inst.ActionText, DRAWER_KEYWORDS)
                or text_matches_keywords(inst.ObjectText, DRAWER_KEYWORDS)
            then
                return "open_drawer"
            end
        end

        local curr = inst.Parent
        local depth = 0
        while curr and curr ~= workspace and depth < 5 do
            if text_matches_keywords(curr.Name, DRAWER_KEYWORDS) then
                return "open_drawer"
            end
            curr = curr.Parent
            depth += 1
        end
        return false
    end

    local function resolve_owner_part(inst)
        if not inst then
            return nil
        end
        if inst:IsA("BasePart") then
            return inst
        end
        if inst:IsA("Attachment") then
            return inst.Parent and inst.Parent:IsA("BasePart") and inst.Parent or inst:FindFirstAncestorWhichIsA("BasePart")
        end
        if inst:IsA("Model") then
            return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
        end
        return inst:FindFirstChildWhichIsA("BasePart", true)
    end

    local function resolve_world_position(inst)
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
            local part = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
            return part and part.Position or nil
        end
        local part = inst:FindFirstChildWhichIsA("BasePart", true)
        return part and part.Position or nil
    end

    local function remove_entry_from_list(list, entry)
        for i = #list, 1, -1 do
            if list[i] == entry then
                table.remove(list, i)
                break
            end
        end
    end

    local function unregister_interactable(desc)
        local entry = entry_by_inst[desc]
        if not entry then
            return
        end
        entry_by_inst[desc] = nil
        item_cooldowns[desc] = nil
        opened_drawer_timestamps[desc] = nil
        if entry.bucket == "drawer" then
            remove_entry_from_list(drawer_entries, entry)
        else
            remove_entry_from_list(item_entries, entry)
        end
    end

    local function register_interactable(desc)
        if entry_by_inst[desc] then
            return
        end
        if not (desc:IsA("ProximityPrompt") or desc:IsA("ClickDetector")) then
            return
        end
        if desc == esp_folder or desc:IsDescendantOf(esp_folder) then
            return
        end
        local char = LocalPlayer and LocalPlayer.Character
        if char and desc:IsDescendantOf(char) then
            return
        end
        if is_hiding_cabinet_prompt(desc) then
            return
        end
        local drawer_kind = is_drawer_interaction(desc)
        if drawer_kind == "close_action" then
            return
        end
        local pos_owner = (desc:IsA("ProximityPrompt") and (resolve_owner_part(desc.Parent) or desc:FindFirstAncestorWhichIsA("Model"))) or desc.Parent
        local bucket = (drawer_kind == "open_drawer") and "drawer" or "item"
        local entry = {
            inst = desc,
            kind = desc.ClassName,
            owner = pos_owner,
            bucket = bucket,
        }
        entry_by_inst[desc] = entry
        if bucket == "drawer" then
            table.insert(drawer_entries, entry)
        else
            table.insert(item_entries, entry)
        end
    end

    local function ensure_interactable_watchers()
        if cache_initialized then
            return
        end
        cache_initialized = true

        track(workspace.DescendantAdded:Connect(function(desc)
            if desc:IsA("ProximityPrompt") or desc:IsA("ClickDetector") then
                register_interactable(desc)
            end
        end))

        track(workspace.DescendantRemoving:Connect(function(desc)
            if entry_by_inst[desc] then
                unregister_interactable(desc)
            end
        end))

        task.spawn(function()
            local step_counter = 0
            for _, desc in ipairs(workspace:GetDescendants()) do
                if state.closed then
                    break
                end
                if desc:IsA("ProximityPrompt") or desc:IsA("ClickDetector") then
                    register_interactable(desc)
                end
                step_counter += 1
                if (step_counter % 250) == 0 then
                    task.wait()
                end
            end
        end)
    end

    local function fire_single_interaction(entry, now, radius_boost, min_cd)
        local desc = entry.inst
        if not desc or not desc.Parent then
            unregister_interactable(desc)
            return false
        end
        local cd = min_cd or 0.06
        if entry.kind == "ProximityPrompt" then
            if not desc.Enabled then
                return false
            end
            local last_i = item_cooldowns[desc]
            if last_i and (now - last_i) < cd then
                return false
            end
            item_cooldowns[desc] = now
            if desc.HoldDuration ~= 0 then
                if desc:GetAttribute("OrigHold") == nil then
                    desc:SetAttribute("OrigHold", desc.HoldDuration)
                end
                desc.HoldDuration = 0
            end
            if desc.MaxActivationDistance < radius_boost then
                desc.MaxActivationDistance = radius_boost
            end
            if type(fireproximityprompt) == "function" then
                fireproximityprompt(desc)
                return true
            elseif type(inputholdbegin) == "function" and type(inputholdend) == "function" then
                inputholdbegin(desc)
                inputholdend(desc)
                return true
            end
        elseif entry.kind == "ClickDetector" then
            local last_i = item_cooldowns[desc]
            if last_i and (now - last_i) < cd then
                return false
            end
            item_cooldowns[desc] = now
            if type(fireclickdetector) == "function" then
                fireclickdetector(desc)
                return true
            end
        end
        return false
    end

    local function trigger_fast_nearby_items(hrp, pickup_radius)
        local now = os.clock()
        local hrp_pos = hrp.Position
        local max_dist_sq = pickup_radius * pickup_radius
        local boost_dist = pickup_radius + 8
        local fired_count = 0

        for i = #item_entries, 1, -1 do
            if fired_count >= 8 then
                break
            end
            local entry = item_entries[i]
            if not entry or not entry.inst or not entry.inst.Parent then
                if entry and entry.inst then
                    unregister_interactable(entry.inst)
                end
            else
                local owner = entry.owner
                if not owner or not owner.Parent then
                    owner = (entry.kind == "ProximityPrompt" and (resolve_owner_part(entry.inst.Parent) or entry.inst:FindFirstAncestorWhichIsA("Model"))) or entry.inst.Parent
                    entry.owner = owner
                end
                local pos = resolve_world_position(owner)
                if pos then
                    local dx = pos.X - hrp_pos.X
                    local dy = pos.Y - hrp_pos.Y
                    local dz = pos.Z - hrp_pos.Z
                    if (dx * dx + dy * dy + dz * dz) <= max_dist_sq then
                        if fire_single_interaction(entry, now, boost_dist, 0.06) then
                            fired_count += 1
                        end
                    end
                end
            end
        end
    end

    local function trigger_nearby_drawers(hrp, drawer_radius)
        local now = os.clock()
        local hrp_pos = hrp.Position
        local max_dist_sq = drawer_radius * drawer_radius
        local boost_dist = drawer_radius + 8
        local fired_count = 0

        for i = #drawer_entries, 1, -1 do
            if fired_count >= 4 then
                break
            end
            local entry = drawer_entries[i]
            if not entry or not entry.inst or not entry.inst.Parent then
                if entry and entry.inst then
                    unregister_interactable(entry.inst)
                end
            else
                local desc = entry.inst
                local is_ready = (entry.kind == "ProximityPrompt" and desc.Enabled) or (entry.kind == "ClickDetector")
                if is_ready then
                    local last_t = opened_drawer_timestamps[desc]
                    if not last_t or (now - last_t) >= 1.8 then
                        local owner = entry.owner
                        if not owner or not owner.Parent then
                            owner = (entry.kind == "ProximityPrompt" and (resolve_owner_part(desc.Parent) or desc:FindFirstAncestorWhichIsA("Model"))) or desc.Parent
                            entry.owner = owner
                        end
                        local pos = resolve_world_position(owner)
                        if pos then
                            local dx = pos.X - hrp_pos.X
                            local dy = pos.Y - hrp_pos.Y
                            local dz = pos.Z - hrp_pos.Z
                            if (dx * dx + dy * dy + dz * dz) <= max_dist_sq then
                                opened_drawer_timestamps[desc] = now
                                if fire_single_interaction(entry, now, boost_dist, 0.25) then
                                    fired_count += 1
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local drawer_running = false
    local function set_auto_drawer_loot(enabled)
        local active = (enabled == true) and is_active_session()
        state.auto_drawer_loot = active
        if active then
            ensure_interactable_watchers()
        end
        if not active or drawer_running then
            return
        end
        drawer_running = true
        local my_sid = state.session_id

        task.spawn(function()
            local tick_idx = 0
            while state.auto_drawer_loot and not state.closed and state.session_id == my_sid do
                task.wait(0.08)
                if not state.auto_drawer_loot or state.closed or state.session_id ~= my_sid then
                    break
                end
                tick_idx += 1
                local char = LocalPlayer and LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    trigger_fast_nearby_items(hrp, 15)
                    if (tick_idx % 2) == 0 then
                        trigger_nearby_drawers(hrp, 22)
                    end
                end
            end
            drawer_running = false
        end)
    end

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
    local function apply_walkspeed_now(force_target)
        pcall(function()
            local char = LocalPlayer and LocalPlayer.Character
            local hum = char and char:FindFirstChildWhichIsA("Humanoid")
            if hum then
                local active_spd = is_active_session() and state.speed
                if active_spd then
                    if force_target or hum.WalkSpeed < SPEED_VALUE then
                        hum.WalkSpeed = SPEED_VALUE
                    end
                else
                    if hum.WalkSpeed == SPEED_VALUE then
                        hum.WalkSpeed = 16
                    end
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
                if is_active_session() and state.speed and hum.WalkSpeed < SPEED_VALUE then
                    hum.WalkSpeed = SPEED_VALUE
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
            local char = LocalPlayer and LocalPlayer.Character
            local hum = char and char:FindFirstChildWhichIsA("Humanoid")
            if hum then
                hook_humanoid_speed(hum)
            end
            speed_conn = track(RunService.Heartbeat:Connect(function()
                if is_active_session() and state.speed then
                    local c = LocalPlayer and LocalPlayer.Character
                    local h = c and c:FindFirstChildWhichIsA("Humanoid")
                    if h and h.WalkSpeed < SPEED_VALUE then
                        h.WalkSpeed = SPEED_VALUE
                    end
                end
            end))
        end
    end

    local function set_rembo_esp(v)
        state.esp_rembo = (v == true) and is_active_session()
        refresh_active_esp()
        if state.esp_rembo then ensure_esp_loop() end
    end

    local function set_key_esp(v)
        state.esp_key = (v == true) and is_active_session()
        refresh_active_esp()
        if state.esp_key then ensure_esp_loop() end
    end

    local function set_code_paper_esp(v)
        state.esp_code_paper = (v == true) and is_active_session()
        refresh_active_esp()
        if state.esp_code_paper then ensure_esp_loop() end
    end

    local function set_other_items_esp(v)
        state.esp_other_items = (v == true) and is_active_session()
        refresh_active_esp()
        if state.esp_other_items then ensure_esp_loop() end
    end

    local function set_safe_zone_esp(v)
        state.esp_safe_zone = (v == true) and is_active_session()
        refresh_active_esp()
        if state.esp_safe_zone then ensure_esp_loop() end
        return true
    end

    local function set_win_only_bundle(enabled, set_toggle_state)
        local active = (enabled == true) and is_active_session()
        state.win_only = active

        set_rembo_esp(active)
        set_key_esp(active)
        set_code_paper_esp(active)
        set_safe_zone_esp(active)
        set_noclip(active)
        set_speed(active)
        set_normal_brightness(active)
        set_auto_drawer_loot(active)

        local targets = {
            "esp_rembo",
            "esp_key",
            "esp_code_paper",
            "esp_safe_zone",
            "noclip",
            "speed",
            "brightness",
            "auto_drawer_loot",
        }
        for _, key_name in ipairs(targets) do
            set_toggle_state(key_name, active, true, true)
        end
    end

    local function kill_all_features()
        state.closed = true
        state.active_session_id = -1
        state.win_only = false
        state.esp_rembo = false
        state.esp_key = false
        state.esp_code_paper = false
        state.esp_other_items = false
        state.esp_safe_zone = false
        state.noclip = false
        state.speed = false
        state.brightness = false
        state.low_graphics = false
        state.instant_hold = false
        state.auto_drawer_loot = false
        esp_loop_running = false
        drawer_running = false
        table.clear(item_entries)
        table.clear(drawer_entries)
        table.clear(entry_by_inst)

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
    end

    ensure_interactable_watchers()

    return {
        esp_folder = esp_folder,
        set_rembo_esp = set_rembo_esp,
        set_key_esp = set_key_esp,
        set_code_paper_esp = set_code_paper_esp,
        set_other_items_esp = set_other_items_esp,
        set_safe_zone_esp = set_safe_zone_esp,
        set_normal_brightness = set_normal_brightness,
        set_low_graphics = set_low_graphics,
        set_instant_hold = set_instant_hold,
        set_auto_drawer_loot = set_auto_drawer_loot,
        set_noclip = set_noclip,
        set_speed = set_speed,
        set_win_only_bundle = set_win_only_bundle,
        kill_all_features = kill_all_features,
    }
end

local function build_wathub()
    local parent_gui = (type(gethui) == "function" and gethui()) or (LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui"))
    if not parent_gui then
        return
    end

    local old_gui = parent_gui:FindFirstChild("WatHUB_UI")
    if old_gui then
        old_gui:Destroy()
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
        auto_drawer_loot = false,
        esp_rembo = false,
        esp_key = false,
        esp_code_paper = false,
        esp_other_items = false,
        esp_safe_zone = false,
        noclip = false,
        speed = false,
        win_only = false,
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

    local ctrl = create_feature_controllers(state, track)

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

    local minimized = false
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
            minimized = false
            restore_icon.Visible = false
            main.Visible = true
        end,
    })

    track(min_btn.Activated:Connect(function()
        if state.closed then
            return
        end
        minimized = true
        main.Visible = false
        restore_icon.Visible = true
    end))

    track(restore_icon.Activated:Connect(function()
        if state.closed then
            return
        end
        minimized = false
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

    local toggle_controllers = {}
    local function set_toggle_state(key_name, enabled, silent, skip_callback)
        local fn = toggle_controllers[key_name]
        if fn then
            fn(enabled, silent, skip_callback)
        end
    end

    local function add_toggle(page, label_txt, default_val, order, on_changed, key_name)
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

        local function apply_val(new_val, _silent, skip_cb)
            if state.closed then
                return
            end
            current = new_val == true
            paint(current)
            if not skip_cb and on_changed then
                on_changed(current)
            end
        end

        if key_name then
            toggle_controllers[key_name] = apply_val
        end

        track(pill.Activated:Connect(function()
            apply_val(not current, false, false)
        end))

        return row
    end

    -- Tab Home
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
            "Gunakan tab Simple untuk Win Only, Main untuk laci & cahaya, ESP untuk penanda objek, dan Player untuk gerakan. Tekan X untuk tutup serta bersihkan semua fitur.",
            step(),
            64,
            false,
            false
        )

        add_header(page, "Saran, Update & Komuniti", step())
        add_discord_card(page, step())
    end)

    -- Tab Simple
    create_tab("Simple", function(page)
        add_header(page, "Mod Pantas Win Only", 1)
        add_toggle(page, "Auto On Fitur Win Only", false, 2, function(enabled)
            ctrl.set_win_only_bundle(enabled, set_toggle_state)
            push_toast(
                "Win Only",
                enabled and "ESP Rembo, Key, Kertas Kode, Noclip, Speed, Brightness & Auto Laci aktif" or "Fitur Win Only dimatikan"
            )
        end, "win_only")
    end)

    -- Tab Main
    create_tab("Main", function(page)
        local n = 0
        local function step()
            n += 1
            return n
        end

        add_header(page, "Pencahayaan", step())
        add_toggle(page, "Brightness", false, step(), function(enabled)
            ctrl.set_normal_brightness(enabled)
            push_toast("Brightness", enabled and "Pencahayaan terang aktif" or "Pencahayaan dipulihkan")
        end, "brightness")

        add_header(page, "Interaksi & Laci", step())
        add_toggle(page, "Instant Hold", true, step(), function(enabled)
            ctrl.set_instant_hold(enabled)
            push_toast("Instant Hold", enabled and "Tekan 1x tanpa hold aktif" or "Hold normal dipulihkan")
        end, "instant_hold")

        add_toggle(page, "Auto Buka Laci + Ambik Item", false, step(), function(enabled)
            ctrl.set_auto_drawer_loot(enabled)
            push_toast("Laci + Item", enabled and "Auto buka laci & ambik item aktif" or "Auto laci mati")
        end, "auto_drawer_loot")
    end)

    -- Tab ESP
    create_tab("ESP", function(page)
        local n = 0
        local function step()
            n += 1
            return n
        end

        add_header(page, "Lokasi Rembo", step())
        add_toggle(page, "ESP Rembo", false, step(), function(enabled)
            ctrl.set_rembo_esp(enabled)
            push_toast("ESP Rembo", enabled and "Highlight merah aktif" or "Highlight merah mati")
        end, "esp_rembo")

        add_header(page, "Lokasi Kunci", step())
        add_toggle(page, "ESP Key", false, step(), function(enabled)
            ctrl.set_key_esp(enabled)
            push_toast("ESP Key", enabled and "ESP kunci aktif" or "ESP kunci mati")
        end, "esp_key")

        add_header(page, "Lokasi Kertas Kode", step())
        add_toggle(page, "ESP Kertas Kode", false, step(), function(enabled)
            ctrl.set_code_paper_esp(enabled)
            push_toast("ESP Kertas Kode", enabled and "ESP kertas kode aktif" or "ESP kertas kode mati")
        end, "esp_code_paper")

        add_header(page, "Item Lain", step())
        add_toggle(page, "ESP Item Lain", false, step(), function(enabled)
            ctrl.set_other_items_esp(enabled)
            push_toast("ESP Item Lain", enabled and "ESP item lain aktif" or "ESP item lain mati")
        end, "esp_other_items")

        add_header(page, "Lokasi Safe Zone", step())
        add_toggle(page, "ESP Safe Zone", false, step(), function(enabled)
            ctrl.set_safe_zone_esp(enabled)
            push_toast("ESP Safe Zone", enabled and "Penanda safe zone aktif" or "Penanda safe zone dimatikan")
        end, "esp_safe_zone")
    end)

    -- Tab Player
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
        end, "noclip")

        add_toggle(page, "Speed", false, step(), function(enabled)
            ctrl.set_speed(enabled)
            push_toast("Speed", enabled and ("Speed (" .. tostring(SPEED_VALUE) .. ") aktif") or "Speed mati")
        end, "speed")
    end)

    -- Tab Settings
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
        end, "toast_enabled")

        add_header(page, "Performa Grafik", step())
        add_toggle(page, "Low Grafik", false, step(), function(enabled)
            ctrl.set_low_graphics(enabled)
            push_toast("Low Grafik", enabled and "Mod low grafik diaktifkan" or "Grafik dikembalikan")
        end, "low_graphics")

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
