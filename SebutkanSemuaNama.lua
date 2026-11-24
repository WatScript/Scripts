-- Language: Luau | File: WatHUB_AutoAnswer.lua | Target: Roblox Client (Luau)
-- FULL LUA: 10 Random VIP Keys, 1 Key = 1 Account Lock + Notice, Persistent Save Across Re-Execute, Owner Auto-VIP, Tab Colors & Compact Info Layout

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local parent_gui = (type(gethui) == "function" and gethui()) or (LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")) or CoreGui

local old_gui = parent_gui:FindFirstChild("WatHUB_Rebuild_UI")
if old_gui then old_gui:Destroy() end

-- ==========================================
-- KONFIGURASI OWNER, LINK DISCORD & 10 KEY RANDOM
-- ==========================================
local DISCORD_INVITE_LINK = "https://discord.gg/2KcdMhwy2"
local WATFREE_MAX_WORDS = 10
local KEY_SAVE_FILE = "WatHUB_VIP_LockData.json"

-- Masukkan username atau UserId Owner di sini agar otomatis akses WatVIP tanpa Key
local OWNER_USERNAMES = {
   -- [""] = true,
}

local OWNER_USER_IDS = {
     [7409549979] = true,
}

-- ==========================================
-- KONFIGURASI KEY
-- ==========================================
local JSONBIN_BIN_ID = "6b0569f2ac6210605aa038d7"
local JSONBIN_ACCESS_KEY = "$2a$10$gcwVGT55vVX6ORY8uptCo.DEUGi4wEOgmPPv9c.1PBVc2mBeXv1wC"

local cached_keys = nil

local function get_executor_request()
    if type(request) == "function" then return request end
    if type(http) == "table" and type(http.request) == "function" then return http.request end
    if type(syn) == "table" and type(syn.request) == "function" then return syn.request end
    if type(http_request) == "function" then return http_request end
    return nil
end

local function fetch_vip_keys(force_refresh)
    if cached_keys and not force_refresh then return cached_keys end

    local url = "https://api.jsonbin.io/v3/b/" .. JSONBIN_BIN_ID .. "/latest"
    local headers = {["X-Access-Key"] = JSONBIN_ACCESS_KEY}
    local raw_body = nil
    local req_fn = get_executor_request()

    if req_fn then
        local ok_req, resp = pcall(function()
            return req_fn({
                Url = url,
                Method = "GET",
                Headers = headers
            })
        end)
        if ok_req and type(resp) == "table" then
            raw_body = resp.Body or resp.body
        end
    end

    if not raw_body then
        local ok_get, result = pcall(function()
            return HttpService:GetAsync(url, true, headers)
        end)
        if ok_get and type(result) == "string" then
            raw_body = result
        end
    end

    if type(raw_body) == "string" and raw_body ~= "" then
        local ok_dec, decoded = pcall(function()
            return HttpService:JSONDecode(raw_body)
        end)
        if ok_dec and type(decoded) == "table" and type(decoded.record) == "table" and type(decoded.record.keys) == "table" then
            cached_keys = decoded.record.keys
            return cached_keys
        end
    end

    return nil
end

local USER_ICON_ASSET = "rbxassetid://117209290368597"
local CROWN_ICON_ASSET = "rbxassetid://6031075938"
local INFO_TAB_ICON = "rbxassetid://6026568198"
local CHECK_ICON_ASSET = "rbxassetid://6031094667"

local function get_current_game_name()
    local fallback = (game.Name and game.Name ~= "") and game.Name or "Roblox Game"
    local ok, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    if ok and info and type(info.Name) == "string" and info.Name ~= "" then
        return info.Name
    end
    return fallback
end

local CURRENT_GAME_NAME = get_current_game_name()

local function get_player_username()
    if LocalPlayer and type(LocalPlayer.Name) == "string" and LocalPlayer.Name ~= "" then
        return LocalPlayer.Name
    end
    return "GuestPlayer"
end

local function is_owner_player()
    local uname = string.lower(get_player_username())
    if OWNER_USERNAMES[uname] then
        return true
    end
    if LocalPlayer and OWNER_USER_IDS[LocalPlayer.UserId] then
        return true
    end
    return false
end

-- ==========================================
-- PENYIMPANAN DATA LOCK KEY (PERSISTENT ACROSS RE-EXECUTE)
-- ==========================================
local MemoryLockStore = _G.__WatHUB_VIP_LockStore or {
    bindings = {}, -- [KEY] = "UsernameLower"
    unlocked_users = {}, -- ["UsernameLower"] = KEY
}
_G.__WatHUB_VIP_LockStore = MemoryLockStore

local function sanitize_lock_table(raw_tbl)
    local clean = {
        bindings = {},
        unlocked_users = {},
    }
    if type(raw_tbl) == "table" then
        if type(raw_tbl.bindings) == "table" then
            for k, v in pairs(raw_tbl.bindings) do
                if type(k) == "string" and type(v) == "string" then
                    clean.bindings[string.upper(k)] = string.lower(v)
                end
            end
        end
        if type(raw_tbl.unlocked_users) == "table" then
            for u, k in pairs(raw_tbl.unlocked_users) do
                if type(u) == "string" and type(k) == "string" then
                    clean.unlocked_users[string.lower(u)] = string.upper(k)
                end
            end
        end
    end
    return clean
end

local function load_lock_data()
    local loaded = nil
    pcall(function()
        if type(isfile) == "function" and type(readfile) == "function" then
            if isfile(KEY_SAVE_FILE) then
                local content = readfile(KEY_SAVE_FILE)
                if type(content) == "string" and content ~= "" then
                    loaded = HttpService:JSONDecode(content)
                end
            end
        end
    end)
    if type(loaded) == "table" then
        MemoryLockStore = sanitize_lock_table(loaded)
        _G.__WatHUB_VIP_LockStore = MemoryLockStore
    else
        MemoryLockStore = sanitize_lock_table(MemoryLockStore)
        _G.__WatHUB_VIP_LockStore = MemoryLockStore
    end
    return MemoryLockStore
end

local function save_lock_data()
    _G.__WatHUB_VIP_LockStore = MemoryLockStore
    pcall(function()
        if type(writefile) == "function" then
            writefile(KEY_SAVE_FILE, HttpService:JSONEncode(MemoryLockStore))
        end
    end)
end

local function is_valid_generated_key(k, force_refresh)
    local clean_input = string.upper(string.match(tostring(k or ""), "^%s*(.-)%s*$") or "")
    if clean_input == "" then return false end

    local keys = fetch_vip_keys(force_refresh == true)
    if not keys then return false end
    for _, valid_k in ipairs(keys) do
        local clean_valid = string.upper(string.match(tostring(valid_k or ""), "^%s*(.-)%s*$") or "")
        if clean_input == clean_valid then
            return true
        end
    end
    return false
end

load_lock_data()

-- ==========================================
-- KONFIGURASI SUPABASE (1 KEY = 1 AKUN GLOBAL)
-- ==========================================
local SUPABASE_API_URL = "https://ppzwnjacebxinjiftjwj.supabase.co/rest/v1"
local SUPABASE_PUBLISHABLE_KEY = "sb_publishable_2KZ-PPJ1uEaJPPQvc_ohuA_FoJ1Ksw4"
local SUPABASE_TABLE = "wathub_vip_locks"

local function url_encode(str)
    if type(str) ~= "string" then return "" end
    return string.gsub(str, "([^%w%-_%.~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
end

local function supabase_request(method, endpoint, body_tbl, prefer_header)
    local base_url = string.gsub(SUPABASE_API_URL, "/+$", "")
    local full_url = base_url .. "/" .. string.gsub(endpoint, "^/+", "")
    local headers = {
        ["apikey"] = SUPABASE_PUBLISHABLE_KEY,
        ["Authorization"] = "Bearer " .. SUPABASE_PUBLISHABLE_KEY,
        ["Content-Type"] = "application/json",
        ["Accept"] = "application/json",
    }
    if prefer_header and prefer_header ~= "" then
        headers["Prefer"] = prefer_header
    end

    local encoded_body = nil
    if body_tbl ~= nil then
        local ok_enc, enc = pcall(function()
            return HttpService:JSONEncode(body_tbl)
        end)
        if ok_enc then
            encoded_body = enc
        end
    end

    local req_fn = get_executor_request()
    if req_fn then
        local ok_req, resp = pcall(function()
            local opts = {
                Url = full_url,
                Method = method,
                Headers = headers,
            }
            if encoded_body ~= nil then
                opts.Body = encoded_body
            end
            return req_fn(opts)
        end)
        if ok_req and type(resp) == "table" then
            local status_code = tonumber(resp.StatusCode or resp.status_code or resp.Status or resp.status) or 200
            local raw_resp = resp.Body or resp.body or ""
            local decoded = nil
            if type(raw_resp) == "string" and raw_resp ~= "" then
                pcall(function()
                    decoded = HttpService:JSONDecode(raw_resp)
                end)
            end
            return true, status_code, decoded, raw_resp
        end
    end

    if method == "GET" then
        local ok_get, res = pcall(function()
            return HttpService:GetAsync(full_url, true, headers)
        end)
        if ok_get and type(res) == "string" then
            local decoded = nil
            if res ~= "" then
                pcall(function()
                    decoded = HttpService:JSONDecode(res)
                end)
            end
            return true, 200, decoded, res
        end
    end

    return false, 0, nil, ""
end

local function supabase_get_lock_by_key(clean_key)
    local endpoint = SUPABASE_TABLE .. "?vip_key=eq." .. url_encode(clean_key) .. "&select=vip_key,roblox_username,user_id"
    local ok, status_code, decoded = supabase_request("GET", endpoint, nil, nil)
    if ok and status_code >= 200 and status_code < 300 and type(decoded) == "table" then
        if #decoded > 0 and type(decoded[1]) == "table" then
            return true, decoded[1]
        end
        return true, nil
    end
    return false, nil
end

local function supabase_claim_key(clean_key, username, user_id)
    local numeric_uid = tonumber(user_id)
    if not numeric_uid or numeric_uid <= 0 then
        numeric_uid = (LocalPlayer and tonumber(LocalPlayer.UserId)) or 0
    end

    local payload = {
        vip_key = tostring(clean_key),
        roblox_username = tostring(username),
        user_id = numeric_uid,
    }

    print("[WatHUB Debug] POST wathub_vip_locks payload:", payload.vip_key, payload.roblox_username, payload.user_id)

    local ok, status_code, decoded, raw_resp = supabase_request("POST", SUPABASE_TABLE, payload, "return=representation")
    print("[WatHUB Debug] POST StatusCode:", tostring(status_code), "OK:", tostring(ok))
    if raw_resp and raw_resp ~= "" then
        print("[WatHUB Debug] POST Response:", tostring(raw_resp))
    end

    if ok and status_code >= 200 and status_code < 300 then
        if type(decoded) == "table" then
            if #decoded > 0 and type(decoded[1]) == "table" then
                return true, decoded[1], status_code, raw_resp
            elseif decoded.vip_key then
                return true, decoded, status_code, raw_resp
            end
        end
        return true, payload, status_code, raw_resp
    end

    local low_err = string.lower(tostring(raw_resp or ""))
    if status_code == 409 or string.find(low_err, "duplicate", 1, true) or string.find(low_err, "unique", 1, true) then
        local check_ok, existing = supabase_get_lock_by_key(clean_key)
        if check_ok and existing then
            return false, existing, status_code, raw_resp
        end
    end

    return false, nil, status_code, raw_resp
end

local function get_player_user_id()
    if LocalPlayer and tonumber(LocalPlayer.UserId) then
        return tonumber(LocalPlayer.UserId)
    end
    return 0
end

local function check_initial_vip_access()
    if is_owner_player() then
        return true, "OWNER"
    end
    local uname = string.lower(get_player_username())
    local uid = get_player_user_id()
    local bound_key = MemoryLockStore.unlocked_users[uname]

    if bound_key and bound_key ~= "" then
        local clean_bound = string.upper(string.match(bound_key, "^%s*(.-)%s*$") or "")
        if clean_bound ~= "" and is_valid_generated_key(clean_bound, true) then
            local sb_ok, lock_row = supabase_get_lock_by_key(clean_bound)
            if sb_ok and type(lock_row) == "table" then
                local owner_name = string.lower(tostring(lock_row.roblox_username or ""))
                local owner_id = tonumber(lock_row.user_id) or 0
                local matches_user = (owner_name == uname) or (uid > 0 and owner_id == uid)
                if matches_user then
                    MemoryLockStore.bindings[clean_bound] = uname
                    MemoryLockStore.unlocked_users[uname] = clean_bound
                    save_lock_data()
                    return true, clean_bound
                else
                    MemoryLockStore.unlocked_users[uname] = nil
                    save_lock_data()
                    return false, nil
                end
            elseif sb_ok and lock_row == nil then
                local claimed_ok = supabase_claim_key(clean_bound, get_player_username(), uid)
                if claimed_ok then
                    MemoryLockStore.bindings[clean_bound] = uname
                    MemoryLockStore.unlocked_users[uname] = clean_bound
                    save_lock_data()
                    return true, clean_bound
                end
            end
        end
    end

    return false, nil
end

local function activate_vip_key_for_current_user(input_key)
    load_lock_data()
    local exact_name = get_player_username()
    local uname = string.lower(exact_name)
    local uid = get_player_user_id()
    local clean_key = string.upper(string.match(input_key or "", "^%s*(.-)%s*$") or "")

    if clean_key == "" or not is_valid_generated_key(clean_key, true) then
        return false, "Key tidak valid! Gunakan Key WatVIP resmi."
    end

    local sb_ok, existing_lock = supabase_get_lock_by_key(clean_key)
    if not sb_ok then
        return false, "Gagal menyambung ke server Supabase! Coba lagi."
    end

    if type(existing_lock) == "table" then
        local locked_name = string.lower(tostring(existing_lock.roblox_username or ""))
        local locked_id = tonumber(existing_lock.user_id) or 0
        local same_account = (locked_name == uname) or (uid > 0 and locked_id == uid)

        if not same_account then
            return false, "1 Key 1 akun sahaja!"
        end

        MemoryLockStore.bindings[clean_key] = uname
        MemoryLockStore.unlocked_users[uname] = clean_key
        save_lock_data()
        return true, "Key WatVIP aktif & dikunci ke @" .. exact_name
    end

    local claim_ok, claimed_row, claim_status, claim_raw = supabase_claim_key(clean_key, exact_name, uid)
    if not claim_ok then
        if type(claimed_row) == "table" then
            local locked_name = string.lower(tostring(claimed_row.roblox_username or ""))
            local locked_id = tonumber(claimed_row.user_id) or 0
            if locked_name ~= uname and not (uid > 0 and locked_id == uid) then
                return false, "1 Key 1 akun sahaja!"
            end
        end
        local err_detail = ""
        if type(claim_raw) == "string" and claim_raw ~= "" then
            local ok_e, dec_e = pcall(function() return HttpService:JSONDecode(claim_raw) end)
            if ok_e and type(dec_e) == "table" and (dec_e.message or dec_e.code) then
                err_detail = " (" .. tostring(claim_status) .. ": " .. tostring(dec_e.message or dec_e.code) .. ")"
            else
                err_detail = " (HTTP " .. tostring(claim_status) .. ")"
            end
        elseif claim_status then
            err_detail = " (HTTP " .. tostring(claim_status) .. ")"
        end
        return false, "Gagal mengunci key ke Supabase!" .. err_detail
    end

    MemoryLockStore.bindings[clean_key] = uname
    MemoryLockStore.unlocked_users[uname] = clean_key
    save_lock_data()
    return true, "Key WatVIP aktif & dikunci ke @" .. exact_name
end

-- ==========================================
-- WORDBANK (KATEGORI DAN JAWAPAN TERBAIK)
-- ==========================================
local WordBank = {
    ["Makhluk Fiksi"] = {"Naga", "Phoenix", "Unicorn", "Griffin", "Pegasus", "Minotaur", "Kraken", "Leviathan", "Hydra", "Cerberus", "Basilisk", "Vampir", "Werewolf", "Medusa", "Centaur", "Banshee", "Golem", "Elf", "Kurcaci", "Putri Duyung", "Peri", "Genie", "Yeti", "Bigfoot", "Drakula", "Zombie", "Momok", "Hantu", "Siluman", "Troll", "Goblin", "Ogre", "Manticore", "Chimera", "Sphinx", "Cyclops", "Titan", "Nymph", "Satyr", "Fenrir", "Jinn", "Ifrit", "Ghoul", "Lich", "Siren", "Harpy", "Kelpie", "Wyvern", "Drake", "Lamia"},
    ["Hal-hal di Laut"] = {"Terumbu Karang", "Palung Laut", "Kapal Selam", "Kapal Pesiar", "Kapal Kargo", "Kapal Nelayan", "Mercusuar", "Bintang Laut", "Kuda Laut", "Ubur-Ubur", "Gurita", "Ikan Paus", "Ikan Hiu", "Ikan Pari", "Lumba-Lumba", "Penyu", "Rumput Laut", "Kerang", "Kepiting", "Lobster", "Ombak", "Arus Laut", "Pelampung", "Jangkar", "Pasir Bawah Laut", "Karang", "Plankton", "Alga", "Batu Karang", "Perahu Layar", "Kapal Tanker", "Dermaga", "Pelabuhan", "Ikan Tuna", "Ikan Salmon", "Cumi-Cumi", "Sotong", "Udang", "Tiram", "Keong", "Anemon Laut", "Teripang", "Belut Laut", "Paus Biru", "Hiu Putih", "Ikan Badut", "Dugong", "Singa Laut", "Anjing Laut"},
    ["Hal-hal di Mal"] = {"Eskalator", "Lift", "Food Court", "Bioskop", "Toko Baju", "Toko Sepatu", "Area Parkir", "ATM", "Kasir", "Lampu Gantung", "Papan Petunjuk", "Toilet Umum", "Tangga Darurat", "Promosi Diskon", "Kartu Member", "Tas Belanja", "Manekin", "Kios", "Kursi Tunggu", "Petugas Keamanan", "Toko Elektronik", "Toko Buku", "Apotek", "Minimarket", "Toko Mainan", "Playground Anak", "Mushola", "Ruang Laktasi", "Information Center", "Parkir Motor", "Toko Jam", "Toko Perhiasan", "Salon", "Barbershop", "Toko Optik", "Pet Shop", "Supermarket", "Foodcourt", "Bioskop XXI", "Toko Olahraga", "Peta Mal", "Toko Kosmetik", "Fotokopi", "Money Changer"},
    ["Hal-hal di Peternakan"] = {"Kandang Sapi", "Kandang Ayam", "Padang Rumput", "Jerami", "Traktor", "Ember Susu", "Pagar Kayu", "Lumbung", "Sapi Perah", "Kuda", "Kambing", "Domba", "Ayam", "Bebek", "Babi", "Petani", "Sekop", "Gerobak", "Palung Air", "Pakan Ternak", "Ladang", "Kolam Ikan", "Kandang Babi", "Kandang Kuda", "Pagar Kawat", "Mesin Pemerah Susu", "Telur Ayam", "Pupuk Kandang", "Sumur", "Pompa Air", "Anjing Penjaga", "Kucing Liar", "Sapi Jantan", "Kambing Jantan", "Ayam Jago", "Itik", "Angsa", "Kalkun", "Kelinci", "Merpati"},
    ["Hal-hal di Rumah"] = {"Ruang Tamu", "Kamar Tidur", "Dapur", "Kamar Mandi", "Sofa", "Kasur", "Lemari", "Meja Makan", "Kursi", "Televisi", "Kulkas", "Lampu", "Jendela", "Pintu", "Atap", "Halaman Rumah", "Garasi", "Keset", "Gorden", "Jam Dinding", "Sapu", "Pel Lantai", "Taman", "Pagar Rumah", "Tangga", "Ruang Keluarga", "Ruang Makan", "Gudang", "Teras", "Balkon", "Sumur", "Bak Mandi", "Wastafel", "Kompor", "Meja Belajar", "Rak Buku", "Cermin", "Karpet", "Lukisan Dinding", "Bantal", "Selimut", "Kipas Angin", "AC", "Mesin Cuci", "Setrika", "Vacuum Cleaner", "Dispenser", "Kulkas", "Microwave", "Oven"},
    ["Hal-hal di Rumah Sakit"] = {"Ambulans", "Ruang IGD", "Ruang Rawat Inap", "Ruang Operasi", "Apotek", "Stetoskop", "Jarum Suntik", "Infus", "Kursi Roda", "Brankar", "Masker Medis", "Sarung Tangan Medis", "Termometer", "Dokter", "Perawat", "Pasien", "Resep Obat", "Meja Periksa", "Lampu Operasi", "Papan Antrean", "Tensimeter", "Timbangan", "Rontgen", "Laboratorium", "USG", "MRI", "CT Scan", "Defibrillator", "Tabung Oksigen", "Masker Oksigen", "Plester", "Perban", "Obat", "Vitamin", "Kapsul", "Tablet", "Sirup Obat", "Salep", "Tetes Mata", "Ruang Tunggu", "Resepsionis", "Kartu Pasien", "Rekam Medis", "Ruang Radiologi", "ICU", "NICU", "Ruang Bersalin", "Inkubator Bayi", "Tandu"},
    ["Makanan"] = {"Nasi Goreng", "Mie Goreng", "Sate Ayam", "Bakso", "Soto Ayam", "Rendang", "Gado-Gado", "Nasi Padang", "Ayam Goreng", "Ayam Bakar", "Pecel Lele", "Capcay", "Nasi Uduk", "Bubur Ayam", "Lontong Sayur", "Tahu Tempe", "Rawon", "Gudeg", "Pempek", "Martabak", "Nasi Kuning", "Ikan Bakar", "Sup Ayam", "Semur", "Opor Ayam", "Sop Buntut", "Mie Ayam", "Ketoprak", "Lotek", "Pecel", "Nasi Lemak", "Mie Rebus", "Nasi Tim", "Bubur Kacang Hijau", "Batagor", "Siomay", "Cilok", "Cireng", "Fried Chicken", "Pizza", "Burger", "Sandwich", "Pasta", "Lasagna", "Steak", "Sushi", "Ramen", "Dim Sum", "Tom Yam", "Nasi Bakar", "Nasi Liwet", "Ketupat", "Lontong", "Mie Kuah", "Soto Betawi", "Sop Iga"},
    ["Hal-hal di Luar Angkasa"] = {"Lubang Hitam", "Stasiun Luar Angkasa", "Pesawat Ulang-Alik", "Sabuk Asteroid", "Teleskop", "Wahana Antariksa", "Cincin Saturnus", "Bima Sakti", "Supernova", "Nebula", "Asteroid", "Komet", "Meteor", "Meteoroid", "Astronot", "Satelit", "Tata Surya", "Planet", "Galaksi", "Bintang", "Bulan", "Matahari", "Roket", "Mars", "Jupiter", "Saturnus", "Venus", "Merkurius", "Uranus", "Neptunus", "Gerhana", "Aurora", "Kawah Bulan", "Debu Kosmik", "Gravitasi", "Orbit", "Atmosfer", "Magnetosfer", "Bintang Neutron", "Pulsar", "Quasar", "Materi Gelap", "Energi Gelap", "Big Bang", "ISS", "NASA", "SpaceX", "Roket Falcon", "Bulan Saturnus", "Europa", "Titan"},
    ["Kekuatan Super"] = {"Telekinesis", "Telepati", "Terbang", "Invisibilitas", "Regenerasi", "Kecepatan Super", "Kekuatan Super", "Perjalanan Waktu", "Penglihatan Laser", "Penglihatan X-Ray", "Pendengaran Super", "Portal Dimensi", "Mengendalikan Api", "Mengendalikan Air", "Mengendalikan Tanah", "Mengendalikan Angin", "Mengendalikan Petir", "Mengendalikan Es", "Mengendalikan Gravitasi", "Berubah Wujud", "Kloning Diri", "Kekebalan Tubuh", "Membaca Pikiran", "Memanipulasi Waktu", "Memanipulasi Realita", "Lompatan Super", "Ilusi", "Menyerap Kekuatan", "Manipulasi Cahaya", "Manipulasi Bayangan", "Penyembuhan Super", "Precognition", "Teleportasi", "Mengecilkan Tubuh", "Memperbesar Tubuh", "Menghidupkan Benda", "Berbicara dengan Hewan", "Napas Api", "Kulit Baja", "Abadi"},
    ["Reptil"] = {"Komodo", "Buaya", "Aligator", "Iguana", "Biawak", "Tokek", "Cicak", "Bunglon", "Chameleon", "Kura-kura", "Penyu", "Ular Kobra", "Ular Piton", "Ular Sanca", "Ular Welang", "Anakonda", "Ular Laut", "Ular Pohon", "Kadal", "Kadal Gurun", "Kadal Pohon", "Gecko", "Skink", "Tuatara", "Gharial", "Buaya Muara", "Buaya Nil", "Kura-kura Darat", "Kura-kura Air", "Penyu Hijau", "Penyu Lekang", "Ular Hijau", "Ular Merah", "Ular Hitam", "Boa Constrictor", "King Cobra", "Mamba Hitam", "Rattlesnake", "Viper", "Gecko Leopard", "Bearded Dragon", "Blue-tongued Skink"},
    ["Hal-hal di Pesta"] = {"Balon", "Kue Ulang Tahun", "Lilin", "Konfeti", "Topi Pesta", "Terompet Pesta", "Kembang Api", "Dekorasi", "Foto Booth", "Lampu Kelap-Kelip", "Musik", "DJ", "Undangan", "Hadiah", "Kado", "Pita", "Banner", "Panggung", "MC", "Makanan", "Minuman", "Soda", "Kue Tart", "Pinata", "Piring Kertas", "Gelas Plastik", "Sedotan", "Balon Foil", "Balon Helium", "Tiup Lilin", "Lagu Ulang Tahun", "Kipas Kertas", "Kartu Ucapan", "Bingkisan", "Angpao", "Dekorasi Meja", "Taplak Meja Pesta", "Balon Angka", "Streamer", "Lampu Disko", "Photo Props", "Backdrop Foto", "Es Krim", "Popcorn", "Permen", "Cokelat"},
    ["Alat Musik"] = {"Gitar", "Piano", "Biola", "Drum", "Suling", "Terompet", "Harmonika", "Saksofon", "Kolintang", "Sasando", "Akordeon", "Kontrabas", "Mandolin", "Xylophone", "Klarinet", "Ukulele", "Rebana", "Kecapi", "Gendang", "Harpa", "Keyboard", "Bass Gitar", "Cello", "Flute", "Gong", "Tifa", "Marakas", "Tamborin", "Banjo", "Sitar", "Gambus", "Angklung", "Gamelan", "Kendang", "Serunai", "Trombon", "Obo", "Bassoon", "Piccolo", "Timpani", "Simbal", "Triangle", "Kastanyet", "Kalimba", "Didgeridoo", "Bagpipe", "Sitar", "Tabla", "Erhu", "Koto"},
    ["Aplikasi"] = {"WhatsApp", "Instagram", "TikTok", "Facebook", "YouTube", "Shopee", "Tokopedia", "Gojek", "Grab", "Google", "Chrome", "Gmail", "Maps", "Spotify", "Netflix", "Discord", "Telegram", "Zoom", "Pinterest", "LinkedIn", "Snapchat", "Duolingo", "Messenger", "CapCut", "Canva", "Roblox", "Twitch", "Reddit", "Twitter", "X", "Waze", "Lazada", "Traveloka", "Tiket", "OVO", "GoPay", "Dana", "LinkAja", "BCA Mobile", "Mandiri Online", "Flip", "Zoom", "Google Meet", "Microsoft Teams", "Notion", "Trello", "Slack", "Figma", "Photoshop", "Lightroom", "Shazam", "Soundcloud"},
    ["Bagian Tubuh"] = {"Kepala", "Rambut", "Dahi", "Alis", "Mata", "Hidung", "Telinga", "Pipi", "Bibir", "Mulut", "Gigi", "Lidah", "Dagu", "Leher", "Bahu", "Dada", "Perut", "Pinggang", "Pinggul", "Punggung", "Lengan", "Siku", "Pergelangan Tangan", "Tangan", "Telapak Tangan", "Jari Tangan", "Kuku Tangan", "Paha", "Lutut", "Betis", "Pergelangan Kaki", "Kaki", "Telapak Kaki", "Jari Kaki", "Kuku Kaki", "Tumit", "Bulu Mata", "Bulu Hidung", "Jakun", "Rusuk", "Tulang Belakang", "Pantat", "Ketiak", "Siku", "Nadi", "Pembuluh Darah", "Kulit", "Otot", "Tulang", "Sendi"},
    ["Bahasa"] = {"Indonesia", "Melayu", "Inggris", "Jepang", "Korea", "Mandarin", "Arab", "Spanyol", "Prancis", "Jerman", "Rusia", "Hindi", "Thailand", "Vietnam", "Italia", "Portugis", "Belanda", "Turki", "Yunani", "Swedia", "Norwegia", "Polandia", "Tagalog", "Bugis", "Madura", "Tamil", "Sunda", "Jawa", "Bali", "Aceh", "Batak", "Minangkabau", "Betawi", "Madura", "Dayak", "Toraja", "Ambon", "Papua", "Ukraina", "Rumania", "Ceko", "Hungaria", "Finlandia", "Denmark", "Ibrani", "Persia", "Swahili", "Zulu", "Hausa", "Bengali", "Urdu"},
    ["Barang di Dapur"] = {"Kompor", "Panci", "Wajan", "Spatula", "Sendok", "Garpu", "Pisau Dapur", "Talenan", "Mangkuk", "Piring", "Gelas", "Kulkas", "Blender", "Mixer", "Oven", "Microwave", "Penanak Nasi", "Pembuka Kaleng", "Gelas Ukur", "Sendok Sayur", "Sutil", "Ayakan", "Saringan", "Parutan", "Loyang", "Kukusan", "Ketel", "Teko", "Cangkir", "Sumpit", "Nampan", "Botol Minyak", "Toples", "Cobek", "Ulekan", "Wajan Anti Lengket", "Panci Presto", "Steamer", "Air Fryer", "Rice Cooker", "Slow Cooker", "Food Processor", "Juicer", "Toaster", "Waffle Maker", "Cetakan Kue", "Rolling Pin", "Whisker", "Spatula Karet", "Termometer Masak"},
    ["Barang di Kamar Mandi"] = {"Sabun", "Shampo", "Kondisioner", "Sikat Gigi", "Pasta Gigi", "Handuk", "Gayung", "Ember", "Cermin", "Shower", "Sikat WC", "Keset", "Deodoran", "Lulur", "Wastafel", "Kran Air", "Sandal Jepit", "Pembersih Lantai", "Baskom", "Sikat Lantai", "Bathub", "Tisu Toilet", "Sabun Cuci Muka", "Gelas Kumur", "Pewangi Ruangan", "Sikat Punggung", "Sabun Cair", "Tempat Sabun", "Rak Handuk", "Spons Mandi", "Obat Kumur", "Kapas", "Cotton Bud", "Silet Cukur", "Krim Cukur", "Pomade", "Hair Dryer", "Sisir", "Sikat Rambut", "Jepit Rambut", "Timbangan Badan", "Lampu Kamar Mandi", "Tirai Shower", "Shower Head", "Sabun Bayi", "Bedak", "Lotion", "Toner"},
    ["Barang Elektronik"] = {"Televisi", "Laptop", "Smartphone", "Tablet", "Kulkas", "Mesin Cuci", "AC", "Kipas Angin", "Setrika", "Microwave", "Speaker", "Kamera", "Printer", "Proyektor", "Smartwatch", "Vacuum Cleaner", "Hair Dryer", "Router", "Powerbank", "Dispenser", "Harddisk", "Flashdisk", "Headset", "Earphone", "Lampu LED", "Monitor", "Keyboard", "Mouse", "Charger", "Radio", "DVD Player", "CCTV", "Drone", "Action Camera", "Smart TV", "Gaming Console", "PS5", "Xbox", "Nintendo Switch", "Smart Speaker", "Earbuds", "Webcam", "Scanner", "Modem", "Smart Bulb", "Robot Vacuum", "Air Purifier", "Humidifier", "Rice Cooker", "Blender"},
    ["Barang Mahal"] = {"Berlian", "Emas Batangan", "Jam Tangan Mewah", "Mobil Sport", "Yacht", "Jet Pribadi", "Helikopter", "Pulau Pribadi", "Penthouse", "Villa Mewah", "Lukisan Langka", "Mutiara", "Safir", "Ruby", "Zamrud", "Jam Rolex", "Tas Hermes", "Tas Louis Vuitton", "Sepatu Mewah", "Perhiasan Emas", "Kalung Berlian", "Cincin Berlian", "Gelang Berlian", "Mobil Lamborghini", "Mobil Ferrari", "Mobil Bugatti", "Rolls-Royce", "Kapal Pesiar", "Istana", "Rumah Mewah", "Koleksi Seni", "Anggur Langka", "Kaviar", "Truffle", "Karpet Persia", "Piano Grand", "Kristal Baccarat", "Porselen Langka", "Batu Meteorit", "Parfum Mewah"},
    ["Benda Tajam"] = {"Pisau", "Gunting", "Silet", "Jarum", "Paku", "Pedang", "Golok", "Parang", "Kapak", "Tombak", "Gergaji", "Keris", "Sabit", "Belati", "Cutter", "Celurit", "Rencong", "Badik", "Kail Pancing", "Jarum Suntik", "Kawat Berduri", "Pisau Lipat", "Pisau Dapur", "Pisau Roti", "Pisau Fillet", "Gergaji Besi", "Pahat", "Obeng Minus", "Mata Bor", "Pecahan Kaca", "Duri Ikan", "Duri Tanaman", "Paku Payung", "Staples", "Mata Panah", "Ujung Pensil", "Tusuk Gigi", "Tusuk Sate", "Garpu", "Pecahan Keramik"},
    ["Benda yang Berputar"] = {"Roda", "Kipas Angin", "Baling-Baling", "Gasing", "Bor Listrik", "Blender", "Bianglala", "Setir Mobil", "Mesin Cuci", "CD", "DVD", "Roda Sepeda", "Roda Mobil", "Mixer", "Kincir Angin", "Komidi Putar", "Turbin", "Gear", "Katrol", "Piringan Hitam", "Gasing Kayu", "Baling Helikopter", "Rol Kabel", "Kompas Jarum", "Kaset", "Propeler Kapal", "Roda Hamster", "Yoyo", "Spinning Top", "Roda Pottery", "Roda Ferris", "Gilingan Angin", "Turbin Angin", "Generator Listrik", "Motor Listrik", "Mesin Jahit", "Reel Pancing", "Gulungan Benang", "Roda Pemintal", "Jam Mekanik"},
    ["Benda yang Bulat"] = {"Bola", "Kelereng", "Koin", "Piring", "Globe", "Semangka", "Jeruk", "Apel", "Tomat", "Bakso", "Donat", "Telur", "Bola Basket", "Bola Sepak", "Bola Tenis", "Bola Pingpong", "Bola Golf", "Ban Mobil", "Roda", "Cincin", "Gelang", "Jam Dinding Bulat", "Lampu Bohlam", "Tutup Botol", "Kancing Baju", "Kelengkeng", "Anggur", "Kue Tar", "Rambutan", "Duku", "Leci", "Blueberry", "Ceri", "Buah Markisa", "Buah Naga", "Melon", "Semangka Mini", "Bola Biliar", "Bola Bowling", "Planet"},
    ["Buah dan Sayuran"] = {"Apel", "Pisang", "Jeruk", "Mangga", "Semangka", "Anggur", "Stroberi", "Wortel", "Bayam", "Tomat", "Brokoli", "Terong", "Mentimun", "Alpukat", "Melon", "Rambutan", "Kacang Panjang", "Bawang Merah", "Bawang Putih", "Kelengkeng", "Seledri", "Kubis", "Labu", "Nanas", "Pepaya", "Salak", "Durian", "Kelapa", "Kangkung", "Sawi", "Buncis", "Jagung", "Kentang", "Cabai", "Pir", "Nangka", "Leci", "Sirsak", "Belimbing", "Jambu Biji", "Jambu Air", "Kiwi", "Lemon", "Jeruk Nipis", "Markisa", "Buah Naga", "Manggis", "Duku", "Kesemek", "Ceri", "Blueberry", "Raspberry", "Blackberry", "Persik", "Plum", "Aprikot", "Zaitun", "Tin", "Kurma"},
    ["Bunga dan Tanaman"] = {"Mawar", "Melati", "Anggrek", "Bunga Matahari", "Tulip", "Kaktus", "Raflesia", "Edelweis", "Lavender", "Sakura", "Kamboja", "Kenanga", "Teratai", "Dahlia", "Krisan", "Aster", "Pakis", "Lidah Buaya", "Bonsai", "Bugenvil", "Adenium", "Pohon Beringin", "Pohon Bambu", "Rumput", "Pohon Kelapa", "Pohon Mangga", "Pohon Pisang", "Pohon Cemara", "Pohon Pinus", "Pohon Oak", "Bambu", "Pohon Willow", "Pohon Cherry", "Bunga Lili", "Bunga Iris", "Bunga Peoni", "Bunga Poppy", "Carnation", "Bunga Gardenia", "Bunga Jasmine", "Tanaman Sirih", "Tanaman Pandan", "Tanaman Jahe", "Tanaman Kunyit", "Tanaman Serai", "Pohon Jambu", "Pohon Rambutan", "Pohon Durian", "Pohon Nangka", "Pohon Papaya"},
    ["Burung"] = {"Elang", "Merpati", "Merak", "Flamingo", "Penguin", "Kakatua", "Cendrawasih", "Kasuari", "Bangau", "Gagak", "Burung Hantu", "Kenari", "Lovebird", "Nuri", "Beo", "Jalak", "Perkutut", "Kutilang", "Pipit", "Puyuh", "Ayam", "Bebek", "Angsa", "Kalkun", "Camar", "Albatros", "Raja Udang", "Pelikan", "Kolibri", "Pelatuk", "Robin", "Swallow", "Murai", "Cucak Rawa", "Kacer", "Pleci", "Prenjak", "Ciblek", "Anis Merah", "Trucukan", "Garuda", "Rajawali", "Kondor", "Elang Laut", "Elang Jawa", "Burung Surga", "Toucan", "Macaw", "Cockatoo", "Kookaburra"},
    ["Camilan"] = {"Keripik Kentang", "Keripik Singkong", "Popcorn", "Cokelat", "Permen", "Biskuit", "Wafer", "Kacang Goreng", "Gorengan", "Pisang Goreng", "Tahu Isi", "Bakwan", "Martabak Manis", "Kue Cubit", "Kue Nastar", "Kue Kastengel", "Makaroni Goreng", "Churros", "Basreng", "Cilok", "Cireng", "Kerupuk", "Kue Bolu", "Kue Lapis", "Risol", "Pastel", "Donat", "Es Krim", "Puding", "Jelly", "Agar-Agar", "Chiki", "Oreo", "Ritz", "Pringles", "Snickers", "KitKat", "M&M", "Gummy Bear", "Marshmallow", "Pretzel", "Nachos", "Tortilla Chips", "Kacang Almond", "Kacang Mete", "Granola Bar", "Mochi", "Daifuku", "Takoyaki"},
    ["Cuaca dan Bencana"] = {"Hujan", "Badai", "Petir", "Kilat", "Mendung", "Cerah", "Kabut", "Angin Kencang", "Gerimis", "Panas Terik", "Berawan", "Puting Beliung", "Tornado", "Badai Salju", "Hujan Es", "Angin Topan", "Topan", "Siklon", "Badai Pasir", "Gelombang Panas", "Kebakaran Hutan", "Banjir", "Banjir Bandang", "Tanah Longsor", "Tsunami", "Gempa Bumi", "Gunung Meletus", "Kekeringan", "Angin Ribut", "El Nino", "La Nina", "Pelangi", "Embun", "Salju", "Es", "Frost", "Heatwave", "Blizzard", "Hujan Meteor", "Gerhana Matahari", "Gerhana Bulan", "Aurora", "Kabut Tebal", "Polusi Udara", "Asap Kebakaran"},
    ["Emosi"] = {"Senang", "Sedih", "Marah", "Takut", "Cemas", "Malu", "Cinta", "Benci", "Bosan", "Kesal", "Iri", "Santai", "Gembira", "Bahagia", "Rindu", "Panik", "Lega", "Puas", "Bangga", "Terkejut", "Semangat", "Kecewa", "Jengkel", "Khawatir", "Tersinggung", "Antusias", "Nostalgia", "Kesepian", "Frustasi", "Gugup", "Malu-Malu", "Percaya Diri", "Optimis", "Pesimis", "Bersyukur", "Heran", "Kagum", "Jijik", "Kasihan", "Empati", "Simpati", "Penasaran", "Bingung", "Canggung", "Kaget", "Terharu", "Haru", "Galau", "Overthinking", "Excited"},
    ["Game Roblox"] = {"Blox Fruits", "Brookhaven", "Adopt Me", "Tower of Hell", "Jailbreak", "Doors", "Arsenal", "Piggy", "Royale High", "MeepCity", "Murder Mystery 2", "Bee Swarm Simulator", "Natural Disaster Survival", "Build A Boat For Treasure", "Pet Simulator 99", "Anime Defenders", "Dress to Impress", "Work at a Pizza Place", "Survive the Killer", "BedWars", "Evade", "Fisch", "Rivals", "Blade Ball", "King Legacy", "Mic Up", "Obby Creator", "Escape Room", "Tycoon", "Simulator", "DeepWoken", "Arcane Odyssey", "Fruit Battlegrounds", "Anime Champions", "Super Evolution", "Sol's RNG", "Funky Friday", "Friday Night Bloxxin", "Islands", "Lumber Tycoon 2", "Mining Simulator", "Weight Lifting Simulator", "Ninja Legends", "Ghost Simulator"},
    ["Gaya Rambut"] = {"Pendek", "Panjang", "Botak", "Bob", "Keriting", "Lurus", "Ikal", "Kepang", "Sanggul", "Ponytail", "Kuncir Kuda", "Dreadlocks", "Mohawk", "Undercut", "Fade", "Buzz Cut", "Crew Cut", "Pixie", "Afro", "Layer", "Wolfcut", "Comma Hair", "Belah Tengah", "Belah Pinggir", "Poni Depan", "Poni Samping", "Mullet", "Cepol", "Bun", "Half Up Half Down", "Space Buns", "French Braid", "Dutch Braid", "Fishtail Braid", "Cornrows", "Locs", "Twist", "Updo", "Messy Bun", "Low Bun", "High Bun", "Slicked Back", "Quiff", "Pompadour", "Side Part", "Caesar Cut"},
    ["Hal yang Bisa Menyala"] = {"Lampu", "Lilin", "Api", "Senter", "Korek Api", "Obor", "Lentera", "Lampu LED", "Lampu Jalan", "Lampu Tidur", "Kembang Api", "Neon", "Lampu Disko", "Mercusuar", "Api Unggun", "Layar HP", "Lampu Lalu Lintas", "Lampu Emergency", "Lampu Sorot", "Bintang Jatuh", "Korek Gas", "Bara Api", "Lampu Kilat", "Lampu Natal", "Bioluminesensi", "Kunang-Kunang", "Lava", "Meteor", "Bintang", "Matahari", "Petir", "Lava", "Fosfor", "Lampu Neon", "Lampu Halogen", "Lampu Pijar", "Lampu Fluorescent", "Laser", "Suar", "Flare"},
    ["Hal yang Bisa Terbang"] = {"Pesawat", "Helikopter", "Drone", "Layang-Layang", "Balon Udara", "Roket", "Burung", "Kupu-Kupu", "Lebah", "Capung", "Nyamuk", "Lalat", "Kumbang", "Elang", "Merpati", "Camar", "Bangau", "Kelelawar", "Tupai Terbang", "Paralayang", "Gantole", "Pesawat Tempur", "Balon Gas", "Kertas Pesawat", "Pesawat Jet", "Capung Jarum", "Burung Hantu", "Belalang", "Tawon", "Ngengat", "Laron", "Semut Bersayap", "Biji Maple", "Biji Dandelion", "Parasut", "Jet Pack", "Hovercraft", "Flying Car", "Space Shuttle", "Satelit"},
    ["Hal yang Dingin"] = {"Es Batu", "Salju", "Es Krim", "Kulkas", "Freezer", "Air Dingin", "Antartika", "Kutub Utara", "Kutub Selatan", "Air Es", "Es Teh", "Es Jeruk", "Es Campur", "Es Serut", "Es Loli", "Es Kelapa", "Es Buah", "Air Mineral Dingin", "Angin Malam", "Angin Gunung", "Ruang Ber-AC", "Daun Mint", "Permen Mint", "Mentol", "Gunung Es", "Iceberg", "Gletser", "Permafrost", "Tundra", "Blizzard", "Frost", "Embun Beku", "Nitrogen Cair", "Dry Ice", "Ruang Pendingin", "Cold Storage", "Es Batu Kering", "Colosseum Beku", "Danau Beku", "Sungai Beku"},
    ["Hal yang Panas"] = {"Api", "Matahari", "Lava", "Magma", "Kompor", "Setrika", "Oven", "Bara", "Air Panas", "Air Mendidih", "Sinar Matahari", "Gurun Pasir", "Kawah", "Knalpot Motor", "Mesin Mobil", "Uap Panas", "Wajan Panas", "Kopi Panas", "Teh Panas", "Sup Panas", "Susu Panas", "Api Unggun", "Besi Panas", "Solder", "Las", "Lilin Menyala", "Pemanas Ruangan", "Sauna", "Hot Spring", "Geyser", "Aspal Panas", "Pasir Pantai Siang", "Atap Seng Siang", "Mesin Jet", "Reaktor Nuklir", "Bintang", "Kilat", "Plasma", "Tungku", "Perapian"},
    ["Hal-hal Berwarna Biru"] = {"Langit", "Laut", "Safir", "Jeans", "Bola Biru", "Lampu Biru", "Bunga Lavender", "Bunga Iris", "Blueberry", "Plum", "Anggur Biru", "Kupu-Kupu Biru", "Kolam Renang", "Air Laut", "Batu Safir", "Topaz Biru", "Tinta Biru", "Cat Biru", "Pena Biru", "Buku Biru", "Tas Biru", "Sepatu Biru", "Kaos Biru", "Kemeja Biru", "Celana Jeans", "Awan Biru", "Payung Biru", "Topi Biru", "Pita Biru", "Botol Biru", "Cangkir Biru", "Kertas Biru", "Pintu Biru", "Dinding Biru", "Bendera Biru", "Mobil Biru", "Motor Biru", "Sepeda Biru", "Superman Cape", "Police Uniform"},
    ["Hal-hal Berwarna Hijau"] = {"Daun", "Rumput", "Pohon", "Kaktus", "Bayam", "Brokoli", "Timun", "Alpukat", "Kiwi", "Apel Hijau", "Anggur Hijau", "Semak", "Lumut", "Hutan", "Padi", "Zamrud", "Matcha", "Daun Teh", "Sawi Hijau", "Jeruk Nipis", "Batu Zamrud", "Cat Hijau", "Tinta Hijau", "Kaos Hijau", "Tas Hijau", "Sepatu Hijau", "Topi Hijau", "Bola Hijau", "Kertas Hijau", "Lampu Hijau", "Papan Tulis", "Trampolin", "Lapangan Bola", "Lapangan Golf", "Hutan Pinus", "Kebun Teh", "Sawah", "Daun Pisang", "Daun Pandan", "Selada"},
    ["Hal-hal Berwarna Merah"] = {"Apel Merah", "Tomat", "Stroberi", "Cabai", "Mawar Merah", "Darah", "Lipstik Merah", "Bata Merah", "Lampu Merah", "Bendera Merah", "Ceri", "Delima", "Ruby", "Batu Ruby", "Cabai Rawit", "Semangka", "Kaos Merah", "Baju Merah", "Topi Merah", "Tas Merah", "Sepatu Merah", "Cat Merah", "Bola Merah", "Lampu Rem", "Lampu Stop", "Mobil Merah", "Ferrari Merah", "Kardinal", "Robin", "Bunga Poppy", "Tulip Merah", "Cranberry", "Raspberry", "Tomat Cherry", "Lobster", "Kepiting", "Udang Merah", "Kecap", "Sambal", "Saus Tomat"},
    ["Hal-hal di Bandara"] = {"Pesawat", "Terminal", "Koper", "Paspor", "Tiket", "Boarding Pass", "Gate", "Bagasi", "X-Ray", "Imigrasi", "Bea Cukai", "Landasan Pacu", "Menara Kontrol", "Pilot", "Pramugari", "Ruang Tunggu", "Lounge", "Petugas Keamanan", "Troli Barang", "Papan Jadwal", "Garbarata", "Label Bagasi", "Peta Bandara", "Antrean Check-In", "Konter Check-In", "Duty Free", "Restoran Bandara", "Kafe Bandara", "ATM Bandara", "Money Changer", "Toilet Bandara", "Mushola Bandara", "Ruang VIP", "Baggage Claim", "Conveyor Belt", "Bus Bandara", "Taksi Bandara", "Parkir Bandara", "Hotel Bandara", "Ambulans Bandara", "Fire Truck Bandara"},
    ["Hal-hal di Pantai"] = {"Pasir", "Ombak", "Laut", "Matahari", "Payung Pantai", "Kursi Pantai", "Handuk Pantai", "Kacamata Hitam", "Tabir Surya", "Bola Pantai", "Kerang", "Batu Karang", "Pohon Kelapa", "Kepiting", "Bintang Laut", "Ubur-Ubur", "Ikan", "Terumbu Karang", "Kapal Nelayan", "Perahu", "Pelampung", "Tikar Pantai", "Sandal Pantai", "Topi Pantai", "Baju Renang", "Snorkel", "Fin Renang", "Papan Selancar", "Jet Ski", "Banana Boat", "Mercusuar", "Dermaga", "Warung Pantai", "Es Kelapa", "Air Kelapa", "Ikan Bakar", "Kapal Pesiar", "Burung Camar", "Penyu", "Lumba-Lumba"},
    ["Hal-hal di Restoran"] = {"Menu", "Pelayan", "Meja Makan", "Kursi", "Piring", "Sendok", "Garpu", "Gelas", "Serbet", "Kasir", "Dapur", "Koki", "Makanan", "Minuman", "Nampan", "Struk", "Botol Saus", "Lada", "Garam", "Tusuk Gigi", "Buku Menu", "Ruang Makan", "Antrean", "Pesanan", "Cangkir", "Peralatan Makan", "Meja Kasir", "Lampu Restoran", "Dekorasi Restoran", "Musik Restoran", "Waiter", "Waitress", "Chef", "Sous Chef", "Manajer Restoran", "Reservasi", "Meja Reservasi", "Bill", "Tip", "Doggy Bag", "Take Away", "Delivery", "Drive Through"},
    ["Hari Raya dan Perayaan"] = {"Idulfitri", "Iduladha", "Natal", "Tahun Baru", "Imlek", "Waisak", "Nyepi", "Ramadan", "Paskah", "Halloween", "Valentine", "Ulang Tahun", "Pernikahan", "Wisuda", "Hari Ibu", "Hari Ayah", "Hari Guru", "Hari Anak", "Kemerdekaan", "Tahun Baru Islam", "Cap Go Meh", "Festival Lentera", "Diwali", "Hanukkah", "Thanksgiving", "St. Patrick's Day", "Hari Kartini", "Hari Sumpah Pemuda", "Hari Pahlawan", "Hari Pendidikan", "Hari Buruh", "Hari Lingkungan Hidup", "Hari Bumi", "Hari Jadi Kota", "Kenduri", "Syukuran", "Akikah", "Khitanan", "Perayaan Panen"},
    ["Hewan"] = {"Kucing", "Anjing", "Sapi", "Kerbau", "Kambing", "Domba", "Kuda", "Gajah", "Singa", "Harimau", "Macan", "Beruang", "Panda", "Serigala", "Rubah", "Zebra", "Jerapah", "Badak", "Rusa", "Kanguru", "Koala", "Monyet", "Gorila", "Orangutan", "Kelinci", "Buaya", "Katak", "Ular", "Unta", "Cendrawasih", "Kasuari", "Landak", "Tupai", "Komodo", "Citah", "Kuda Nil", "Babi", "Ayam", "Bebek", "Angsa", "Kura-Kura", "Penyu", "Lumba-Lumba", "Paus", "Hiu", "Pari", "Gurita", "Ubur-Ubur", "Kelelawar", "Musang"},
    ["Ibu Kota Negara"] = {"Jakarta", "Tokyo", "Seoul", "Beijing", "Bangkok", "Singapura", "Kuala Lumpur", "Manila", "Hanoi", "Phnom Penh", "Vientiane", "Naypyidaw", "Dhaka", "New Delhi", "Islamabad", "Kabul", "Kathmandu", "Colombo", "Thimphu", "Male", "London", "Paris", "Berlin", "Roma", "Madrid", "Lisbon", "Amsterdam", "Brussels", "Vienna", "Bern", "Stockholm", "Oslo", "Copenhagen", "Helsinki", "Athena", "Ankara", "Moskow", "Kyiv", "Warsaw", "Praha", "Budapest", "Bucharest", "Washington DC", "Ottawa", "Mexico City", "Brasilia", "Buenos Aires", "Lima", "Bogota", "Santiago", "Canberra", "Wellington", "Kairo", "Pretoria", "Nairobi", "Lagos", "Addis Ababa", "Riyadh", "Doha", "Abu Dhabi", "Teheran", "Baghdad", "Amman"},
    ["Isi Tas Ransel"] = {"Buku Tulis", "Pensil", "Pulpen", "Penghapus", "Penggaris", "Laptop", "Charger", "Botol Minum", "Dompet", "Kunci", "Earphone", "Powerbank", "Spidol", "Tisu", "Kacamata", "Kalkulator", "Rautan", "Headset", "Binder", "Buku Catatan", "Correction Tape", "Hand Sanitizer", "Buku Pelajaran", "Payung Lipat", "Kotak Makan", "Jaket Lipat", "Baju Ganti", "Map Dokumen", "Isi Stapler", "Buku Gambar", "Gunting Kertas", "Stabilo", "Flashdisk", "Mouse", "Obat", "Plester", "Pembalut", "Permen", "Snack", "Dompet Koin", "Kartu", "KTP", "SIM", "ATM", "Foto", "Buku Agenda", "Sticky Notes"},
    ["Item Minecraft"] = {"Diamond", "Emerald", "Gold Ingot", "Iron Ingot", "Netherite", "Redstone", "Obsidian", "Crafting Table", "Furnace", "Chest", "Bed", "Torch", "Sword", "Pickaxe", "Axe", "Shovel", "Hoe", "Bow", "Arrow", "Shield", "Armor", "Helmet", "Bucket", "Water Bucket", "Lava Bucket", "Ender Pearl", "Eye of Ender", "Blaze Rod", "Nether Star", "Beacon", "Enchanted Golden Apple", "Golden Apple", "Compass", "Clock", "Anvil", "Brewing Stand", "Potion", "Book", "Enchanting Table", "TNT", "Piston", "Sticky Piston", "Lever", "Button", "Pressure Plate", "Repeater", "Comparator", "Hopper", "Dropper", "Dispenser", "Saddle", "Lead", "Name Tag"},
    ["Jenis Ikan"] = {"Lele", "Nila", "Mas", "Gurame", "Tuna", "Salmon", "Hiu", "Pari", "Cupang", "Koi", "Sarden", "Kakap", "Bawal", "Patin", "Tongkol", "Guppy", "Belut", "Betta", "Oscar", "Cakalang", "Baronang", "Tenggiri", "Arwana", "Bandeng", "Kembung", "Mujair", "Louhan", "Kerapu", "Ikan Badut", "Ikan Mas Koki", "Discus", "Flowerhorn", "Piranha", "Arapaima", "Ikan Paus", "Ikan Pedang", "Ikan Layaran", "Ikan Terbang", "Ikan Lantern", "Ikan Nemo", "Ikan Dori", "Ikan Puffer", "Ikan Balon", "Ikan Sidat", "Ikan Gabus", "Ikan Sepat", "Ikan Mujair", "Ikan Trout", "Ikan Cod", "Ikan Makarel"},
    ["Jenis Pakaian"] = {"Kaos", "Kemeja", "Rok", "Jaket", "Hoodie", "Sweater", "Gaun", "Jas", "Rompi", "Blouse", "Dasi", "Sabuk", "Seragam", "Gamis", "Celana Jeans", "Sarung", "Blazer", "Mantel", "Celana Panjang", "Celana Pendek", "Celana Training", "Baju Tidur", "Polo Shirt", "Kaus Kaki", "Cardigan", "Baju Koko", "Tank Top", "Kaos Dalam", "Rok Mini", "Rok Maxi", "Dress", "Jumpsuit", "Overall", "Tunik", "Kaftan", "Abaya", "Kimono", "Hanbok", "Cheongsam", "Sari", "Toga", "Jas Hujan", "Pakaian Renang", "Baju Olahraga", "Seragam Sekolah", "Seragam Kerja", "Pakaian Adat", "Baju Kebaya"},
    ["Karakter Anime"] = {"Naruto Uzumaki", "Monkey D. Luffy", "Son Goku", "Sasuke Uchiha", "Eren Yeager", "Light Yagami", "Gojo Satoru", "Tanjiro Kamado", "Levi Ackerman", "Itadori Yuji", "Killua Zoldyck", "Gon Freecss", "Edward Elric", "Megumi Fushiguro", "Natsuki Subaru", "Rudeus Greyrat", "Kakashi Hatake", "Roronoa Zoro", "Vegeta", "Mikasa Ackerman", "Nezuko Kamado", "L Lawliet", "Rem", "Emilia", "Saitama", "Sukuna", "Guts", "Elaina", "Ichigo Kurosaki", "Rukia Kuchiki", "Natsu Dragneel", "Erza Scarlet", "Gray Fullbuster", "Lucy Heartfilia", "Kirito", "Asuna", "Lelouch", "Spike Spiegel", "Edward Elric", "Roy Mustang", "Izuku Midoriya", "Katsuki Bakugo", "Shouto Todoroki", "All Might", "Rimuru Tempest", "Ainz Ooal Gown", "Kazuto Kirigaya", "Shirogane", "Ryomen Sukuna"},
    ["Karakter Kartun"] = {"SpongeBob SquarePants", "Patrick Star", "Squidward Tentacles", "Sandy Cheeks", "Mr. Krabs", "Plankton", "Doraemon", "Nobita", "Shizuka", "Giant", "Suneo", "Tom", "Jerry", "Upin", "Ipin", "Boboiboy", "Mickey Mouse", "Minnie Mouse", "Donald Duck", "Daisy Duck", "Goofy", "Pluto", "Bugs Bunny", "Daffy Duck", "Tweety", "Sylvester", "Scooby-Doo", "Shaggy", "Shin-chan", "Popeye", "Garfield", "Dexter", "Gopal", "Yaya", "Ying", "Fang", "Adu Du", "Probe", "Phineas", "Ferb", "Perry", "Finn", "Jake", "Ice King", "Mordecai", "Rigby", "Benson", "Pops"},
    ["Karakter Video Game"] = {"Mario", "Luigi", "Princess Peach", "Bowser", "Link", "Zelda", "Ganondorf", "Sonic", "Tails", "Knuckles", "Pikachu", "Ash", "Kratos", "Master Chief", "CJ", "Trevor", "Michael", "Franklin", "Arthur Morgan", "John Marston", "Cloud Strife", "Sephiroth", "Tifa Lockhart", "Aerith", "Solid Snake", "Lara Croft", "Jill Valentine", "Leon Kennedy", "Chris Redfield", "Sub-Zero", "Scorpion", "Ryu", "Ken", "Chun-Li", "Mega Man", "Pac-Man", "Kirby", "Yoshi", "Samus", "Steve", "Creeper", "Herobrine", "Geralt", "Ezio", "Altair", "Nathan Drake", "Joel", "Ellie", "Aloy", "Jin Sakai"},
    ["Kartun dan Acara TV"] = {"SpongeBob SquarePants", "Doraemon", "Tom and Jerry", "Upin dan Ipin", "Boboiboy", "Naruto", "Dragon Ball Z", "One Piece", "Avatar The Last Airbender", "Adventure Time", "Regular Show", "Gravity Falls", "Steven Universe", "The Amazing World of Gumball", "Teen Titans", "Ben 10", "Powerpuff Girls", "Dexter's Laboratory", "Phineas and Ferb", "Kim Possible", "We Bare Bears", "Clarence", "Uncle Grandpa", "OK K.O.", "Rick and Morty", "Shaun the Sheep", "Peppa Pig", "Dora the Explorer", "Bluey", "Paw Patrol", "Frozen", "Toy Story", "Cars", "Finding Nemo", "The Lion King", "Larva", "Pororo", "Pingu", "Kiko", "Oggy and the Cockroaches", "Scooby-Doo", "Shin-chan", "Ninja Hattori"},
    ["Kegiatan di Dalam Ruangan"] = {"Membaca Buku", "Menonton Film", "Bermain Game", "Memasak", "Belajar", "Menulis", "Melukis", "Tidur", "Menonton TV", "Menggambar", "Menjahit", "Menyanyi", "Meditasi", "Menata Buku", "Beres-Beres Kamar", "Mendengarkan Musik", "Mengerjakan PR", "Merapikan Meja", "Menyapu Lantai", "Mengepel Lantai", "Mencuci Piring", "Bermain Catur", "Bermain Piano", "Bermain Gitar", "Menonton Anime", "Berbincang", "Olahraga Indoor", "Yoga", "Push Up", "Sit Up", "Main Kartu", "Main Monopoli", "Puzzle", "Origami", "Merajut", "Menyulam", "Fotografi Indoor", "Makeup", "Skincare", "Mandi", "Masak Kue", "Dekorasi Rumah", "Berkebun Indoor"},
    ["Kegiatan di Luar Ruangan"] = {"Bersepeda", "Berlari", "Piknik", "Berkemah", "Memancing", "Bermain Bola", "Berenang", "Berkebun", "Jalan Santai", "Jogging", "Bermain Basket", "Bermain Voli", "Berfoto", "Bermain Sepak Bola", "Berjemur", "Lari Pagi", "Bermain Layang-Layang", "Bermain Bulu Tangkis", "Menjelajah Alam", "Berenang di Pantai", "Bermain Skateboard", "Berkeliling Kota", "Mendaki Gunung", "Mendaki Bukit", "Menyiram Tanaman", "BBQ", "Piknik", "Rafting", "Panjat Tebing", "Paralayang", "Bungee Jumping", "Ski", "Snowboard", "Surfing", "Diving", "Snorkeling", "Kayaking", "Hiking", "Trekking", "Berkuda", "Memanah"},
    ["Kendaraan"] = {"Mobil", "Motor", "Sepeda", "Bus", "Truk", "Kereta Api", "Pesawat", "Helikopter", "Kapal Laut", "Perahu", "Taksi", "MRT", "LRT", "Feri", "Skuter", "Becak", "Ambulans", "Traktor", "Sampan", "Kapal Selam", "Kereta Cepat", "Truk Gandeng", "Mobil Pick-Up", "Mobil Pemadam", "Mobil Sedan", "Mobil SUV", "Sepeda Motor", "Pesawat Jet", "Monorail", "Tram", "Cable Car", "Gondola", "Hovercraft", "Jet Ski", "Speedboat", "Kapal Tanker", "Kapal Kargo", "Kapal Perang", "Kapal Induk", "Roket", "Shuttle", "Drone", "ATV", "Forklift", "Crane", "Excavator", "Bulldozer", "Bajaj", "Angkot", "Ojek"},
    ["Makanan Penutup"] = {"Es Krim", "Puding", "Kue Cokelat", "Donat", "Wafel", "Pancake", "Kue Bolu", "Es Serut", "Kue Sus", "Kue Tart", "Mochi", "Kue Cubit", "Kue Putu", "Puding Cokelat", "Puding Mangga", "Es Krim Vanila", "Es Krim Stroberi", "Dadar Gulung", "Tiramisu", "Brownies", "Macaron", "Kue Keju", "Es Campur", "Klepon", "Pai Apel", "Crepe", "Churros", "Profiterole", "Creme Brulee", "Panna Cotta", "Cheesecake", "Red Velvet", "Lava Cake", "Souffle", "Mousse Cokelat", "Gelato", "Sorbet", "Frozen Yogurt", "Bubble Tea", "Boba", "Kue Lapis", "Bika Ambon", "Serabi", "Onde-Onde", "Lupis", "Cenil", "Getuk"},
    ["Makhluk Laut"] = {"Ikan Paus", "Lumba-Lumba", "Hiu", "Pari", "Gurita", "Ubur-Ubur", "Kepiting", "Lobster", "Udang", "Penyu", "Cumi-Cumi", "Kerang", "Sotong", "Bintang Laut", "Kuda Laut", "Anemon Laut", "Ikan Badut", "Ikan Kerapu", "Ikan Tuna", "Ikan Salmon", "Belut Laut", "Siput Laut", "Teripang", "Landak Laut", "Dugong", "Singa Laut", "Anjing Laut", "Orca", "Paus Biru", "Hiu Putih", "Hiu Paus", "Manta Ray", "Ikan Lele Laut", "Ikan Puffer", "Ikan Balon", "Lionfish", "Seahorse", "Clownfish", "Mooray Eel", "Barracuda", "Swordfish", "Marlin", "Tarpon", "Tiram", "Remis", "Keong", "Kepiting Tapal Kuda", "Plankton", "Krill"},
    ["Mamalia"] = {"Kucing", "Anjing", "Sapi", "Kuda", "Gajah", "Singa", "Harimau", "Paus", "Monyet", "Beruang", "Rusa", "Badak", "Gorila", "Kelinci", "Unta", "Kambing", "Domba", "Kerbau", "Serigala", "Rubah", "Orangutan", "Kuda Nil", "Kanguru", "Alpaka", "Landak", "Tupai", "Kelelawar", "Lumba-Lumba", "Jerapah", "Zebra", "Panda", "Citah", "Cheetah", "Leopard", "Jaguar", "Macan Tutul", "Beruang Kutub", "Beruang Grizzly", "Serigala Abu", "Coyote", "Raksoon", "Musang", "Berang-Berang", "Otter", "Walrus", "Anjing Laut", "Singa Laut", "Lumba-Lumba Hidung Botol", "Narwhal", "Beluga"},
    ["Merek"] = {"Nike", "Adidas", "Apple", "Samsung", "Sony", "Toyota", "Honda", "Coca-Cola", "McDonald's", "Google", "Microsoft", "Amazon", "Tesla", "Louis Vuitton", "Gucci", "Rolex", "Puma", "Reebok", "New Balance", "Vans", "Converse", "H&M", "Zara", "Uniqlo", "Starbucks", "KFC", "Pepsi", "Canon", "Nikon", "LG", "Asus", "Lenovo", "Dell", "HP", "Xiaomi", "Oppo", "Vivo", "Realme", "OnePlus", "Huawei", "PlayStation", "Nintendo", "IKEA", "Nestle", "Unilever", "P&G", "BMW", "Mercedes-Benz", "Audi", "Volkswagen"},
    ["Merek Mobil"] = {"Toyota", "Honda", "BMW", "Mercedes-Benz", "Audi", "Ford", "Hyundai", "Kia", "Nissan", "Porsche", "Ferrari", "Tesla", "Mazda", "Suzuki", "Lexus", "Subaru", "Jeep", "Jaguar", "Lamborghini", "Rolls-Royce", "Aston Martin", "Bugatti", "Bentley", "Maserati", "Alfa Romeo", "Volvo", "Land Rover", "Mitsubishi", "Daihatsu", "Chevrolet", "Dodge", "Chrysler", "Cadillac", "Lincoln", "Infiniti", "Acura", "Genesis", "Peugeot", "Renault", "Citroen", "Fiat", "Seat", "Skoda", "Wuling", "Chery", "Geely", "BYD", "NIO", "Great Wall", "MG"},
    ["Minuman"] = {"Air Putih", "Teh", "Kopi", "Susu", "Jus Jeruk", "Jus Mangga", "Soda", "Es Teh Manis", "Kopi Susu", "Teh Hijau", "Cappuccino", "Latte", "Americano", "Espresso", "Matcha Latte", "Lemon Tea", "Teh Tarik", "Air Kelapa", "Smoothie", "Jus Apel", "Jus Alpukat", "Susu Cokelat", "Susu Stroberi", "Es Jeruk", "Air Mineral", "Milkshake", "Kopi Hitam", "Jus Semangka", "Es Kopi", "Cokelat Hangat", "Milo", "Ovaltine", "Yakult", "Pocari Sweat", "Mizone", "Sprite", "Fanta", "Cola", "Root Beer", "Ginger Ale", "Teh Botol", "Kopi Instan", "Boba", "Bubble Tea", "Teh Susu", "Es Campur", "Es Buah", "Jus Jambu", "Jus Tomat", "Jus Wortel"},
    ["Nama Anak Laki-laki"] = {"Muhammad", "Ahmad", "Rizky", "Farhan", "Daffa", "Rafi", "Bagas", "Ilham", "Hafiz", "Naufal", "Satria", "Taufik", "Ardian", "Gilang", "Hakim", "Iqbal", "Arief", "Dimas", "Fajar", "Danu", "Bima", "Reza", "Kevin", "Adrian", "Zaki", "Aldi", "Raka", "Bayu", "Yoga", "Fikri", "Hendra", "Rian", "Dani", "Eko", "Fauzi", "Hadi", "Ivan", "Joko", "Lukman", "Muhamad", "Nanda", "Omar", "Putra", "Qodir", "Raihan", "Sandi", "Teguh", "Umar", "Vino", "Wahyu", "Yusuf", "Zainal", "Alif", "Bilal", "Chalid"},
    ["Nama Anak Perempuan"] = {"Siti", "Aisyah", "Fatimah", "Zahra", "Nabila", "Aulia", "Kirana", "Jasmine", "Clarissa", "Laras", "Tasya", "Ayu", "Putri", "Nadia", "Dina", "Rina", "Salsa", "Maya", "Citra", "Nisa", "Bella", "Dewi", "Fitri", "Hana", "Intan", "Laila", "Salma", "Anisa", "Dian", "Elsa", "Ratna", "Aliya", "Bunga", "Cantika", "Dinda", "Elina", "Fara", "Ghina", "Hesty", "Indah", "Julia", "Kayla", "Lina", "Mira", "Naila", "Olivia", "Priska", "Queen", "Riana", "Sarah", "Tiara", "Ulfa", "Vina", "Wulan", "Yasmin"},
    ["Negara"] = {"Indonesia", "Malaysia", "Jepang", "Korea Selatan", "China", "India", "Thailand", "Singapura", "Filipina", "Vietnam", "Amerika Serikat", "Inggris", "Prancis", "Jerman", "Italia", "Spanyol", "Brasil", "Australia", "Kanada", "Rusia", "Turki", "Mesir", "Arab Saudi", "Uni Emirat Arab", "Pakistan", "Bangladesh", "Myanmar", "Kamboja", "Laos", "Brunei", "Timor Leste", "Papua Nugini", "Selandia Baru", "Meksiko", "Argentina", "Kolombia", "Peru", "Chile", "Swiss", "Swedia", "Norwegia", "Denmark", "Finlandia", "Belanda", "Belgia", "Austria", "Polandia", "Yunani", "Portugal", "Ukraina", "Iran", "Irak", "Afghanistan", "Israel", "Yordania", "Lebanon", "Suriah", "Kenya", "Nigeria", "Afrika Selatan", "Ethiopia", "Ghana"},
    ["Olahraga"] = {"Sepak Bola", "Basket", "Voli", "Bulu Tangkis", "Tenis", "Renang", "Lari", "Tinju", "Catur", "Golf", "Panahan", "Senam", "Bersepeda", "Ski", "Hoki", "Rugby", "Karate", "Taekwondo", "Judo", "Futsal", "Dayung", "Tenis Meja", "Lompat Jauh", "Lari Estafet", "Angkat Besi", "Polo Air", "Biliar", "Selancar", "Kano", "Bola Tangan", "Triathlon", "Maraton", "Sprint", "Loncat Tinggi", "Lempar Lembing", "Lempar Cakram", "Tolak Peluru", "Panjat Tebing", "BMX", "Skateboard", "Surfing", "Diving", "Equestrian", "Fencing", "Gulat", "Anggar", "Silat", "Kickboxing", "MMA", "Squash"},
    ["Pahlawan Super dan Penjahat"] = {"Spider-Man", "Batman", "Superman", "Iron Man", "Thor", "Captain America", "Wonder Woman", "Hulk", "Black Widow", "Doctor Strange", "Joker", "Thanos", "Loki", "Magneto", "Venom", "Green Goblin", "Scarlet Witch", "Harley Quinn", "Lex Luthor", "Darkseid", "Ultron", "Wolverine", "Ant-Man", "Hawkeye", "Vision", "Penguin", "Riddler", "Flash", "Aquaman", "Catwoman", "Black Panther", "Captain Marvel", "Shazam", "Green Lantern", "Green Arrow", "Nightwing", "Robin", "Deadpool", "Daredevil", "Punisher", "Ghost Rider", "Silver Surfer", "Galactus", "Doom", "Carnage", "Electro", "Vulture", "Mysterio", "Sandman", "Doctor Octopus"},
    ["Pekerjaan"] = {"Dokter", "Perawat", "Guru", "Pilot", "Koki", "Polisi", "Petani", "Nelayan", "Hakim", "Desainer", "Pemadam Kebakaran", "Fotografer", "Apoteker", "Dokter Gigi", "Akuntan", "Pengacara", "Wartawan", "Arsitek", "Insinyur", "Programmer", "Masinis", "Nahkoda", "Penjahit", "Tukang Kayu", "Kasir", "Satpam", "Sopir", "Pramugari", "Tentara", "Dosen", "Psikolog", "Bidan", "Veteriner", "Ahli Gizi", "Fisioterapis", "Radiologis", "Analis Lab", "Ahli Bedah", "Kardiolog", "Neurolog", "Peneliti", "Ilmuwan", "Astronot", "Atlet", "Pelatih", "Musisi", "Aktor", "Sutradara", "Penulis", "Jurnalis"},
    ["Peralatan Olahraga"] = {"Bola Sepak", "Bola Basket", "Bola Voli", "Sarung Tinju", "Raket Bulu Tangkis", "Shuttlecock", "Raket Tenis", "Bola Tenis", "Tongkat Golf", "Bola Golf", "Matras Yoga", "Dumbbell", "Barbel", "Treadmill", "Sepatu Lari", "Sepatu Futsal", "Sepatu Basket", "Helm Sepeda", "Sepeda", "Skipping Rope", "Kacamata Renang", "Topi Renang", "Baju Renang", "Pelampung Renang", "Papan Renang", "Fin", "Papan Seluncur", "Skateboard", "Papan Catur", "Bola Pingpong", "Meja Pingpong", "Net Voli", "Gawang", "Bola Rugby", "Sepatu Roda", "Busur Panah", "Anak Panah", "Bola Bowling", "Pelindung Lutut", "Pelindung Siku", "Sarung Tangan Golf"},
    ["Perlengkapan Sekolah"] = {"Pensil", "Pulpen", "Penghapus", "Penggaris", "Rautan", "Spidol", "Buku Tulis", "Buku Catatan", "Tas Sekolah", "Kertas HVS", "Stapler", "Stabilo", "Papan Tulis", "Kapur Tulis", "Crayon", "Lem Kertas", "Selotip", "Jangka", "Kalkulator", "Correction Tape", "Tempat Pensil", "Pensil Warna", "Gunting Kertas", "Buku Gambar", "Isi Stapler", "Map Dokumen", "Binder", "Amplop", "Kertas Karton", "Cat Air", "Kuas", "Penggaris Segitiga", "Busur Derajat", "Mistar", "Pita Ukur", "Globe", "Peta", "Atlas", "Kamus", "Ensiklopedia", "Papan Clipboard", "Whiteboard", "Spidol Whiteboard", "Penghapus Whiteboard"},
    ["Permata, Batu, dan Logam"] = {"Berlian", "Emas", "Perak", "Tembaga", "Besi", "Platina", "Safir", "Ruby", "Zamrud", "Giok", "Mutiara", "Batu Akik", "Batu Opal", "Kuningan", "Perunggu", "Aluminium", "Batu Kecubung", "Batu Pirus", "Marmer", "Granit", "Timah", "Seng", "Nikel", "Titanium", "Baja", "Batu Kapur", "Batu Apung", "Batu Pasir", "Batu Obsidian", "Batu Basalt", "Batu Granit", "Batu Marmer", "Batu Onyx", "Batu Jasper", "Batu Topaz", "Batu Zircon", "Batu Moonstone", "Batu Labradorite", "Batu Malachite", "Batu Lapis Lazuli", "Merkuri", "Lithium", "Kobalt", "Mangan", "Kromium", "Wolfram", "Molibdenum", "Vanadium", "Germanium"},
    ["Restoran Cepat Saji"] = {"McDonald's", "KFC", "Burger King", "Pizza Hut", "Domino's Pizza", "Subway", "A&W", "Wendy's", "Popeyes", "Jollibee", "Taco Bell", "Wingstop", "Dairy Queen", "Texas Chicken", "Hoka Hoka Bento", "Richeese Factory", "Marugame Udon", "Pepper Lunch", "Carl's Jr.", "Shake Shack", "Five Guys", "Hardee's", "Church's Chicken", "Panda Express", "Yoshinoya", "Solaria", "Es Teler 77", "Bakmi GM", "CFC", "D'Cost", "Mie Gacoan", "Geprek Bensu", "Kopi Kenangan", "Fore Coffee", "Janji Jiwa", "Kopi Janji Jiwa", "Starbucks", "J.Co", "Chatime", "Gong Cha", "Tiger Sugar", "Xing Fu Tang", "Mie Ayam", "Warteg"},
    ["Rutinitas Pagi"] = {"Bangun Tidur", "Cuci Muka", "Sikat Gigi", "Mandi", "Sarapan", "Minum Kopi", "Minum Teh", "Minum Air Putih", "Merapikan Tempat Tidur", "Berpakaian", "Memakai Sepatu", "Berdoa", "Pemanasan", "Olahraga Pagi", "Jogging", "Cek HP", "Cek Berita", "Cek Cuaca", "Menyiapkan Tas", "Berangkat Kerja", "Berangkat Sekolah", "Menyiapkan Sarapan", "Memakai Seragam", "Merapikan Rambut", "Buka Jendela", "Berpamitan", "Menyalakan Lampu", "Regangkan Badan", "Memasak", "Mencuci Piring", "Menyapu", "Mengepel", "Menyiram Tanaman", "Memberi Makan Hewan", "Mengambil Koran", "Memanaskan Motor", "Isi BBM", "Naik Angkot", "Naik Bus"},
    ["Senjata"] = {"Pedang", "Tombak", "Busur Panah", "Belati", "Pistol", "Senapan", "Kapak", "Panah", "Keris", "Golok", "Parang", "Katana", "Tameng", "Ranjau", "Granat", "Bumerang", "Nunchaku", "Kapak Perang", "Cambuk", "Pedang Kayu", "Anak Panah", "Senapan Mesin", "Senjata Nuklir", "Bom", "Rudal", "Torpedo", "Meriam", "Artileri", "Bazoka", "Sniper", "Shotgun", "Pistol Air", "Panah Busur", "Tombak Pendek", "Pedang Panjang", "Belati Kecil", "Rencong", "Celurit", "Badik", "Klewang", "Mandau", "Sumpit", "Trisula", "Gada", "Flail", "Mace", "Halberd", "Pike", "Crossbow", "Slingshot"},
    ["Serangga"] = {"Kupu-Kupu", "Lebah", "Semut", "Nyamuk", "Lalat", "Kecoa", "Belalang", "Capung", "Kumbang", "Ulat", "Rayap", "Tawon", "Kutu", "Ngengat", "Kepik", "Laron", "Belalang Sembah", "Capung Jarum", "Kumbang Badak", "Semut Rangrang", "Semut Merah", "Semut Hitam", "Lebah Madu", "Lebah Bumble", "Kutu Busuk", "Ulat Bulu", "Jangkrik", "Kutu Daun", "Kumbang Kotoran", "Walang Sangit", "Tonggeret", "Kutu Rambut", "Pinjal", "Tungau", "Wereng", "Penggerek", "Kumbang Kelapa", "Lalat Buah", "Nyamuk Aedes", "Nyamuk Malaria", "Kupu-Kupu Monark", "Kupu-Kupu Raja", "Firefly", "Kunang-Kunang", "Stick Insect"},
    ["Tempat di Alam"] = {"Hutan", "Gunung", "Pantai", "Sungai", "Danau", "Gurun", "Lembah", "Gua", "Pulau", "Rawa", "Bukit", "Laut", "Samudra", "Tebing", "Ngarai", "Muara", "Teluk", "Selat", "Padang Savana", "Padang Rumput", "Hutan Hujan", "Hutan Bakau", "Air Terjun", "Kawah Gunung", "Gurun Pasir", "Padang Salju", "Kutub", "Tundra", "Taiga", "Stepa", "Fjord", "Delta", "Laguna", "Atol", "Terumbu Karang", "Palung Laut", "Kepulauan", "Semenanjung", "Dataran Tinggi", "Dataran Rendah", "Perbukitan", "Pegunungan", "Lembah Rift", "Oasis", "Hutan Mangrove", "Rawa Gambut"},
    ["Video Game"] = {"Minecraft", "Roblox", "Fortnite", "PUBG", "Free Fire", "Mobile Legends", "Valorant", "Among Us", "Genshin Impact", "Honkai Star Rail", "Grand Theft Auto V", "Red Dead Redemption 2", "God of War", "The Last of Us", "Elden Ring", "Cyberpunk 2077", "The Witcher 3", "Apex Legends", "Overwatch 2", "Counter-Strike 2", "Clash Royale", "Clash of Clans", "Call of Duty", "EA Sports FC", "Super Mario Bros", "The Legend of Zelda", "Pokemon", "Stardew Valley", "Terraria", "Hollow Knight", "Celeste", "Undertale", "Cuphead", "Hades", "Dead Cells", "Sekiro", "Dark Souls", "Resident Evil", "Devil May Cry", "Street Fighter", "Mortal Kombat", "Tekken", "FIFA", "NBA 2K", "WWE", "Subway Surfers", "Temple Run", "Candy Crush", "Angry Birds"},
    ["Warna"] = {"Merah", "Biru", "Kuning", "Hijau", "Hitam", "Putih", "Oranye", "Ungu", "Cokelat", "Abu-Abu", "Emas", "Perak", "Merah Muda", "Biru Muda", "Biru Tua", "Hijau Muda", "Hijau Tua", "Merah Tua", "Kuning Cerah", "Abu-Abu Tua", "Putih Tulang", "Hijau Toska", "Biru Langit", "Toska", "Magenta", "Cyan", "Violet", "Indigo", "Marun", "Krem", "Lavender", "Salmon", "Coral", "Turquoise", "Aqua", "Lime", "Olive", "Teal", "Navy", "Burgundy", "Maroon", "Beige", "Khaki", "Ivory", "Charcoal", "Slate", "Mustard", "Amber", "Scarlet", "Crimson"},
}

local Theme = {
    Bg = Color3.fromRGB(14, 17, 26),
    Card = Color3.fromRGB(22, 27, 40),
    Row = Color3.fromRGB(32, 39, 58),
    Accent = Color3.fromRGB(64, 196, 255),
    Orange = Color3.fromRGB(255, 140, 36),
    Gold = Color3.fromRGB(245, 196, 48),
    Green = Color3.fromRGB(46, 196, 112),
    Red = Color3.fromRGB(235, 92, 92),
    Text = Color3.fromRGB(255, 255, 255),
    Muted = Color3.fromRGB(156, 168, 190),
}

local rainbow_sequence = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 75, 110)),
    ColorSequenceKeypoint.new(0.20, Color3.fromRGB(255, 195, 50)),
    ColorSequenceKeypoint.new(0.40, Color3.fromRGB(65, 225, 130)),
    ColorSequenceKeypoint.new(0.60, Color3.fromRGB(64, 196, 255)),
    ColorSequenceKeypoint.new(0.80, Color3.fromRGB(165, 105, 255)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 75, 110)),
})

local rainbow_gradients = {}

local function attach_moving_rainbow_outline(target_inst, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = thickness or 1.8
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Parent = target_inst

    local grad = Instance.new("UIGradient")
    grad.Color = rainbow_sequence
    grad.Rotation = 0
    grad.Parent = stroke

    table.insert(rainbow_gradients, grad)
    return stroke, grad
end

RunService.RenderStepped:Connect(function(dt)
    for _, grad in ipairs(rainbow_gradients) do
        if grad and grad.Parent then
            grad.Rotation = (grad.Rotation + (dt * 120)) % 360
        end
    end
end)

local is_running = true
local is_vip_unlocked = check_initial_vip_access()
local active_tab = "vip"

-- State WatVIP
local vip_auto_check = true
local vip_auto_answer = true
local vip_current_cat = nil
local vip_candidate_cat = nil
local vip_stable_ticks = 0
local vip_switch_ticks = 0
local vip_used_words = {}
local vip_word_index = {}
local vip_finished_cats = {}

-- State WatFREE (Auto Cat + Max 10 Kata + Next Kata Tulis & Kirim Manual)
local free_auto_check = true
local free_current_cat = nil
local free_candidate_cat = nil
local free_stable_ticks = 0
local free_switch_ticks = 0
local free_copied_words = {}
local free_word_index = {}
local free_copied_count = {}

local SETTLE_TICKS_REQUIRED = 1
local SWITCH_TICKS_REQUIRED = 1

local function add_corner(inst, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = inst
end

local function copy_to_clipboard(text)
    local ok = pcall(function()
        if type(setclipboard) == "function" then
            setclipboard(text)
        elseif type(toclipboard) == "function" then
            toclipboard(text)
        elseif type(set_clipboard) == "function" then
            set_clipboard(text)
        elseif UserInputService then
            UserInputService:SetClipboard(text)
        end
    end)
    return ok
end

local gui = Instance.new("ScreenGui")
gui.Name = "WatHUB_Rebuild_UI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = parent_gui

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(308, 304)
main.Position = UDim2.new(0.5, -154, 0.11, 0)
main.BackgroundColor3 = Theme.Bg
main.Active = true
main.Parent = gui
add_corner(main, 10)
attach_moving_rainbow_outline(main, 1.8)

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 32)
header.BackgroundColor3 = Theme.Card
header.Parent = main
add_corner(header, 10)

local user_icon_holder = Instance.new("Frame")
user_icon_holder.Size = UDim2.fromOffset(22, 22)
user_icon_holder.Position = UDim2.fromOffset(7, 5)
user_icon_holder.BackgroundColor3 = Theme.Row
user_icon_holder.Parent = header
add_corner(user_icon_holder, 999)
attach_moving_rainbow_outline(user_icon_holder, 1.6)

local header_user_icon = Instance.new("ImageLabel")
header_user_icon.Size = UDim2.fromScale(1, 1)
header_user_icon.BackgroundTransparency = 1
header_user_icon.Image = USER_ICON_ASSET
header_user_icon.ScaleType = Enum.ScaleType.Crop
header_user_icon.Parent = user_icon_holder
add_corner(header_user_icon, 999)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -86, 1, 0)
title.Position = UDim2.fromOffset(35, 0)
title.BackgroundTransparency = 1
title.RichText = true
title.Text = '<font color="#2EC470">W</font><font color="#FFFFFF">atHUB | </font><font color="#F5C430">' .. CURRENT_GAME_NAME .. '</font>'
title.TextColor3 = Theme.Text
title.Font = Enum.Font.GothamBold
title.TextSize = 10
title.TextTruncate = Enum.TextTruncate.AtEnd
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local min_btn = Instance.new("TextButton")
min_btn.Size = UDim2.fromOffset(22, 18)
min_btn.Position = UDim2.new(1, -48, 0.5, -9)
min_btn.BackgroundColor3 = Theme.Row
min_btn.Text = "-"
min_btn.TextColor3 = Theme.Text
min_btn.Font = Enum.Font.GothamBold
min_btn.TextSize = 11
min_btn.Parent = header
add_corner(min_btn, 4)

local close_btn = Instance.new("TextButton")
close_btn.Size = UDim2.fromOffset(22, 18)
close_btn.Position = UDim2.new(1, -24, 0.5, -9)
close_btn.BackgroundColor3 = Theme.Row
close_btn.Text = "X"
close_btn.TextColor3 = Theme.Red
close_btn.Font = Enum.Font.GothamBold
close_btn.TextSize = 10
close_btn.Parent = header
add_corner(close_btn, 4)

-- Tab Bar: 👑WatVIP | 🎖️WatFREE | ℹ️WatINFO
local tab_bar = Instance.new("Frame")
tab_bar.Size = UDim2.new(1, -16, 0, 28)
tab_bar.Position = UDim2.fromOffset(8, 37)
tab_bar.BackgroundColor3 = Theme.Card
tab_bar.Parent = main
add_corner(tab_bar, 7)

local function create_tab_button(index, total, icon_id, text_val, use_rich)
    local btn = Instance.new("TextButton")
    local width_scale = 1 / total
    btn.Size = UDim2.new(width_scale, -3, 1, -4)
    btn.Position = UDim2.new(width_scale * (index - 1), 2, 0, 2)
    btn.BackgroundColor3 = Theme.Card
    btn.Text = ""
    btn.Parent = tab_bar
    add_corner(btn, 5)

    local text_x = 7
    if icon_id then
        local ic = Instance.new("ImageLabel")
        ic.Size = UDim2.fromOffset(12, 12)
        ic.Position = UDim2.new(0, 6, 0.5, -6)
        ic.BackgroundTransparency = 1
        ic.Image = icon_id
        ic.Parent = btn
        text_x = 20
    end

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -(text_x + 3), 1, 0)
    lbl.Position = UDim2.fromOffset(text_x, 0)
    lbl.BackgroundTransparency = 1
    lbl.RichText = use_rich == true
    lbl.Text = text_val
    lbl.TextColor3 = Theme.Muted
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 8
    lbl.TextTruncate = Enum.TextTruncate.AtEnd
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = btn

    return btn, lbl
end

local vip_tab_btn, vip_tab_label = create_tab_button(
    1,
    3,
    nil,
    '👑<font color="#2EC470">W</font><font color="#FFFFFF">at</font><font color="#F5C430">VIP</font>',
    true
)

local free_tab_btn, free_tab_label = create_tab_button(
    2,
    3,
    nil,
    '⚡<font color="#2EC470">W</font><font color="#FFFFFF">at</font><font color="#FF8C24">FREE</font>',
    true
)

local info_tab_btn, info_tab_label = create_tab_button(
    3,
    3,
    nil,
    'ℹ️<font color="#2EC470">W</font><font color="#FFFFFF">at</font><font color="#40C4FF">INFO</font>',
    true
)

-- ==========================================
-- PAGE 1: TAB 👑WatVIP + KEY GATE & BLUR OVERLAY
-- ==========================================
local vip_page = Instance.new("Frame")
vip_page.Size = UDim2.new(1, -16, 1, -74)
vip_page.Position = UDim2.fromOffset(8, 70)
vip_page.BackgroundTransparency = 1
vip_page.Visible = true
vip_page.Parent = main

local vip_cat_card = Instance.new("Frame")
vip_cat_card.Size = UDim2.new(1, 0, 0, 50)
vip_cat_card.Position = UDim2.fromOffset(0, 0)
vip_cat_card.BackgroundColor3 = Theme.Card
vip_cat_card.Parent = vip_page
add_corner(vip_cat_card, 8)

local vip_cat_caption = Instance.new("TextLabel")
vip_cat_caption.Size = UDim2.new(1, -12, 0, 14)
vip_cat_caption.Position = UDim2.fromOffset(6, 4)
vip_cat_caption.BackgroundTransparency = 1
vip_cat_caption.Text = "KATEGORI TERKUNCI (👑WATVIP)"
vip_cat_caption.TextColor3 = Theme.Gold
vip_cat_caption.Font = Enum.Font.GothamBold
vip_cat_caption.TextSize = 8
vip_cat_caption.TextXAlignment = Enum.TextXAlignment.Left
vip_cat_caption.Parent = vip_cat_card

local vip_cat_value = Instance.new("TextLabel")
vip_cat_value.Size = UDim2.new(1, -12, 0, 22)
vip_cat_value.Position = UDim2.fromOffset(6, 20)
vip_cat_value.BackgroundTransparency = 1
vip_cat_value.Text = "Menunggu..."
vip_cat_value.TextColor3 = Theme.Gold
vip_cat_value.Font = Enum.Font.GothamBold
vip_cat_value.TextSize = 12
vip_cat_value.TextTruncate = Enum.TextTruncate.AtEnd
vip_cat_value.TextXAlignment = Enum.TextXAlignment.Left
vip_cat_value.Parent = vip_cat_card

local vip_ans_btn = Instance.new("TextButton")
vip_ans_btn.Size = UDim2.new(1, 0, 0, 30)
vip_ans_btn.Position = UDim2.fromOffset(0, 58)
vip_ans_btn.BackgroundColor3 = Theme.Green
vip_ans_btn.Text = "Auto Isi & Kirim: ON"
vip_ans_btn.TextColor3 = Theme.Text
vip_ans_btn.Font = Enum.Font.GothamBold
vip_ans_btn.TextSize = 10
vip_ans_btn.Parent = vip_page
add_corner(vip_ans_btn, 7)

local vip_cat_btn = Instance.new("TextButton")
vip_cat_btn.Size = UDim2.new(1, 0, 0, 28)
vip_cat_btn.Position = UDim2.fromOffset(0, 96)
vip_cat_btn.BackgroundColor3 = Theme.Row
vip_cat_btn.Text = "Auto Check Category: ON"
vip_cat_btn.TextColor3 = Theme.Accent
vip_cat_btn.Font = Enum.Font.GothamBold
vip_cat_btn.TextSize = 9
vip_cat_btn.Parent = vip_page
add_corner(vip_cat_btn, 6)

local vip_status_bar = Instance.new("TextLabel")
vip_status_bar.Size = UDim2.new(1, 0, 0, 28)
vip_status_bar.Position = UDim2.fromOffset(0, 194)
vip_status_bar.BackgroundColor3 = Theme.Row
vip_status_bar.Text = "Status: Terkunci (Butuh Key WatVIP)"
vip_status_bar.TextColor3 = Theme.Muted
vip_status_bar.Font = Enum.Font.Gotham
vip_status_bar.TextSize = 9
vip_status_bar.TextTruncate = Enum.TextTruncate.AtEnd
vip_status_bar.Parent = vip_page
add_corner(vip_status_bar, 6)

-- Overlay kabur/gelap + form input Key bila status belum WatVIP
local vip_blur_overlay = Instance.new("Frame")
vip_blur_overlay.Size = UDim2.fromScale(1, 1)
vip_blur_overlay.BackgroundColor3 = Color3.fromRGB(9, 12, 20)
vip_blur_overlay.BackgroundTransparency = 0.22
vip_blur_overlay.ZIndex = 10
vip_blur_overlay.Visible = true
vip_blur_overlay.Parent = vip_page
add_corner(vip_blur_overlay, 8)

local key_box_card = Instance.new("Frame")
key_box_card.Size = UDim2.new(1, -16, 0, 126)
key_box_card.Position = UDim2.new(0, 8, 0.5, -63)
key_box_card.BackgroundColor3 = Theme.Card
key_box_card.ZIndex = 12
key_box_card.Parent = vip_blur_overlay
add_corner(key_box_card, 8)
attach_moving_rainbow_outline(key_box_card, 1.4)

local key_title_lbl = Instance.new("TextLabel")
key_title_lbl.Size = UDim2.new(1, -12, 0, 15)
key_title_lbl.Position = UDim2.fromOffset(6, 5)
key_title_lbl.BackgroundTransparency = 1
key_title_lbl.Text = "AKSES WATVIP • INPUT KEY (1 KEY = 1 AKUN)"
key_title_lbl.TextColor3 = Theme.Gold
key_title_lbl.Font = Enum.Font.GothamBold
key_title_lbl.TextSize = 8
key_title_lbl.ZIndex = 13
key_title_lbl.TextXAlignment = Enum.TextXAlignment.Left
key_title_lbl.Parent = key_box_card

local key_feedback_lbl = Instance.new("TextLabel")
key_feedback_lbl.Size = UDim2.new(1, -12, 0, 24)
key_feedback_lbl.Position = UDim2.fromOffset(6, 20)
key_feedback_lbl.BackgroundTransparency = 1
key_feedback_lbl.Text = "Masukkan Key WatVIP. Ingin beli? Join Discord di tab WatINFO."
key_feedback_lbl.TextColor3 = Theme.Muted
key_feedback_lbl.Font = Enum.Font.Gotham
key_feedback_lbl.TextSize = 8
key_feedback_lbl.LineHeight = 0.95
key_feedback_lbl.TextWrapped = true
key_feedback_lbl.ZIndex = 13
key_feedback_lbl.TextXAlignment = Enum.TextXAlignment.Left
key_feedback_lbl.Parent = key_box_card

local key_input = Instance.new("TextBox")
key_input.Size = UDim2.new(1, -12, 0, 26)
key_input.Position = UDim2.fromOffset(6, 48)
key_input.BackgroundColor3 = Theme.Row
key_input.Text = ""
key_input.PlaceholderText = "Contoh: WVIP-9X4M-K7Q2-88PL"
key_input.PlaceholderColor3 = Theme.Muted
key_input.TextColor3 = Theme.Text
key_input.Font = Enum.Font.GothamBold
key_input.TextSize = 9
key_input.ClearTextOnFocus = false
key_input.ZIndex = 13
key_input.Parent = key_box_card
add_corner(key_input, 6)

local unlock_key_btn = Instance.new("TextButton")
unlock_key_btn.Size = UDim2.new(1, -12, 0, 28)
unlock_key_btn.Position = UDim2.fromOffset(6, 82)
unlock_key_btn.BackgroundColor3 = Theme.Green
unlock_key_btn.Text = "Aktifkan Key WatVIP"
unlock_key_btn.TextColor3 = Theme.Text
unlock_key_btn.Font = Enum.Font.GothamBold
unlock_key_btn.TextSize = 9
unlock_key_btn.ZIndex = 13
unlock_key_btn.Parent = key_box_card
add_corner(unlock_key_btn, 6)

local function set_vip_status(msg, color)
    vip_status_bar.Text = "Status: " .. msg
    vip_status_bar.TextColor3 = color or Theme.Muted
end

-- ==========================================
-- PAGE 2: TAB 🎖️WatFREE (Next Kata 0/10 • Tulis dan Kirim Manual)
-- ==========================================
local free_page = Instance.new("Frame")
free_page.Size = UDim2.new(1, -16, 1, -74)
free_page.Position = UDim2.fromOffset(8, 70)
free_page.BackgroundTransparency = 1
free_page.Visible = false
free_page.Parent = main

local free_cat_card = Instance.new("Frame")
free_cat_card.Size = UDim2.new(1, 0, 0, 50)
free_cat_card.Position = UDim2.fromOffset(0, 0)
free_cat_card.BackgroundColor3 = Theme.Card
free_cat_card.Parent = free_page
add_corner(free_cat_card, 8)

local free_cat_caption = Instance.new("TextLabel")
free_cat_caption.Size = UDim2.new(1, -12, 0, 14)
free_cat_caption.Position = UDim2.fromOffset(6, 4)
free_cat_caption.BackgroundTransparency = 1
free_cat_caption.Text = "KATEGORI TERKUNCI (🎖️WATFREE • MAKS 10 KATA)"
free_cat_caption.TextColor3 = Theme.Orange
free_cat_caption.Font = Enum.Font.GothamBold
free_cat_caption.TextSize = 8
free_cat_caption.TextXAlignment = Enum.TextXAlignment.Left
free_cat_caption.Parent = free_cat_card

local free_cat_value = Instance.new("TextLabel")
free_cat_value.Size = UDim2.new(1, -12, 0, 22)
free_cat_value.Position = UDim2.fromOffset(6, 20)
free_cat_value.BackgroundTransparency = 1
free_cat_value.Text = "Menunggu..."
free_cat_value.TextColor3 = Theme.Gold
free_cat_value.Font = Enum.Font.GothamBold
free_cat_value.TextSize = 12
free_cat_value.TextTruncate = Enum.TextTruncate.AtEnd
free_cat_value.TextXAlignment = Enum.TextXAlignment.Left
free_cat_value.Parent = free_cat_card

local free_preview_card = Instance.new("Frame")
free_preview_card.Size = UDim2.new(1, 0, 0, 42)
free_preview_card.Position = UDim2.fromOffset(0, 55)
free_preview_card.BackgroundColor3 = Theme.Card
free_preview_card.Parent = free_page
add_corner(free_preview_card, 8)

local free_preview_label = Instance.new("TextLabel")
free_preview_label.Size = UDim2.new(1, -12, 1, 0)
free_preview_label.Position = UDim2.fromOffset(6, 0)
free_preview_label.BackgroundTransparency = 1
free_preview_label.Text = "Kata Berikutnya: -"
free_preview_label.TextColor3 = Theme.Text
free_preview_label.Font = Enum.Font.GothamBold
free_preview_label.TextSize = 10
free_preview_label.TextTruncate = Enum.TextTruncate.AtEnd
free_preview_label.TextXAlignment = Enum.TextXAlignment.Left
free_preview_label.Parent = free_preview_card

local free_next_btn = Instance.new("TextButton")
free_next_btn.Size = UDim2.new(1, 0, 0, 30)
free_next_btn.Position = UDim2.fromOffset(0, 102)
free_next_btn.BackgroundColor3 = Theme.Orange
free_next_btn.Text = "Next Kata (0/10) • Tulis dan Kirim Manual"
free_next_btn.TextColor3 = Theme.Text
free_next_btn.Font = Enum.Font.GothamBold
free_next_btn.TextSize = 8
free_next_btn.Parent = free_page
add_corner(free_next_btn, 7)

local free_cat_btn = Instance.new("TextButton")
free_cat_btn.Size = UDim2.new(1, 0, 0, 26)
free_cat_btn.Position = UDim2.fromOffset(0, 137)
free_cat_btn.BackgroundColor3 = Theme.Row
free_cat_btn.Text = "Auto Check Category: ON"
free_cat_btn.TextColor3 = Theme.Accent
free_cat_btn.Font = Enum.Font.GothamBold
free_cat_btn.TextSize = 9
free_cat_btn.Parent = free_page
add_corner(free_cat_btn, 6)

local free_status_bar = Instance.new("TextLabel")
free_status_bar.Size = UDim2.new(1, 0, 0, 28)
free_status_bar.Position = UDim2.fromOffset(0, 194)
free_status_bar.BackgroundColor3 = Theme.Row
free_status_bar.Text = "Status: Klik Next Kata lalu tulis & kirim manual"
free_status_bar.TextColor3 = Theme.Muted
free_status_bar.Font = Enum.Font.Gotham
free_status_bar.TextSize = 8
free_status_bar.TextTruncate = Enum.TextTruncate.AtEnd
free_status_bar.Parent = free_page
add_corner(free_status_bar, 6)

local function set_free_status(msg, color)
    free_status_bar.Text = "Status: " .. msg
    free_status_bar.TextColor3 = color or Theme.Muted
end

-- ==========================================
-- PAGE 3: TAB ℹ️WatINFO (STATUS Warna Sesuai Tab + Layout Rapat + Centang Biru)
-- ==========================================
local info_page = Instance.new("ScrollingFrame")
info_page.Size = UDim2.new(1, -16, 1, -74)
info_page.Position = UDim2.fromOffset(8, 70)
info_page.BackgroundTransparency = 1
info_page.ScrollBarThickness = 2
info_page.CanvasSize = UDim2.fromOffset(0, 246)
info_page.Visible = false
info_page.Parent = main

local profile_card = Instance.new("Frame")
profile_card.Size = UDim2.new(1, 0, 0, 50)
profile_card.Position = UDim2.fromOffset(0, 0)
profile_card.BackgroundColor3 = Theme.Card
profile_card.Parent = info_page
add_corner(profile_card, 8)

local avatar_frame = Instance.new("Frame")
avatar_frame.Size = UDim2.fromOffset(38, 38)
avatar_frame.Position = UDim2.fromOffset(6, 6)
avatar_frame.BackgroundColor3 = Theme.Row
avatar_frame.Parent = profile_card
add_corner(avatar_frame, 999)
attach_moving_rainbow_outline(avatar_frame, 2)

local avatar_img = Instance.new("ImageLabel")
avatar_img.Size = UDim2.fromScale(1, 1)
avatar_img.BackgroundTransparency = 1
avatar_img.Image = USER_ICON_ASSET
avatar_img.ScaleType = Enum.ScaleType.Crop
avatar_img.Parent = avatar_frame
add_corner(avatar_img, 999)

local status_header_lbl = Instance.new("TextLabel")
status_header_lbl.Size = UDim2.new(1, -52, 0, 16)
status_header_lbl.Position = UDim2.fromOffset(50, 6)
status_header_lbl.BackgroundTransparency = 1
status_header_lbl.RichText = true
status_header_lbl.Text = 'STATUS : 🎖️<font color="#2EC470">W</font><font color="#FFFFFF">at</font><font color="#FF8C24">FREE</font>'
status_header_lbl.TextColor3 = Theme.Text
status_header_lbl.Font = Enum.Font.GothamBold
status_header_lbl.TextSize = 10
status_header_lbl.TextXAlignment = Enum.TextXAlignment.Left
status_header_lbl.Parent = profile_card

local player_sub_lbl = Instance.new("TextLabel")
player_sub_lbl.Size = UDim2.new(1, -52, 0, 16)
player_sub_lbl.Position = UDim2.fromOffset(50, 24)
player_sub_lbl.BackgroundTransparency = 1
player_sub_lbl.Text = "@" .. get_player_username()
player_sub_lbl.TextColor3 = Theme.Muted
player_sub_lbl.Font = Enum.Font.Gotham
player_sub_lbl.TextSize = 9
player_sub_lbl.TextTruncate = Enum.TextTruncate.AtEnd
player_sub_lbl.TextXAlignment = Enum.TextXAlignment.Left
player_sub_lbl.Parent = profile_card

if LocalPlayer then
    task.spawn(function()
        local ok, content = pcall(function()
            return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
        end)
        if ok and content and avatar_img and avatar_img.Parent then
            avatar_img.Image = content
        end
    end)
end

local info_card = Instance.new("Frame")
info_card.Size = UDim2.new(1, 0, 0, 108)
info_card.Position = UDim2.fromOffset(0, 54)
info_card.BackgroundColor3 = Theme.Card
info_card.Parent = info_page
add_corner(info_card, 8)

local info_body = Instance.new("TextLabel")
info_body.Size = UDim2.new(1, -12, 1, -8)
info_body.Position = UDim2.fromOffset(6, 4)
info_body.BackgroundTransparency = 1
info_body.Text = "WatFREE: Auto cek kategori, batas 10 kata, tulis & kirim manual.\nJika tidak ingin menunggu antrean atau mengetik manual satu per satu, maka belilah WatVIP!\nManfaat WatVIP: Auto isi & kirim otomatis tanpa batas 10 kata, respon cepat & semua kategori."
info_body.TextColor3 = Theme.Text
info_body.Font = Enum.Font.Gotham
info_body.TextSize = 8
info_body.LineHeight = 0.94
info_body.TextWrapped = true
info_body.TextXAlignment = Enum.TextXAlignment.Left
info_body.TextYAlignment = Enum.TextYAlignment.Top
info_body.Parent = info_card

local discord_card = Instance.new("Frame")
discord_card.Size = UDim2.new(1, 0, 0, 74)
discord_card.Position = UDim2.fromOffset(0, 166)
discord_card.BackgroundColor3 = Theme.Card
discord_card.Parent = info_page
add_corner(discord_card, 8)

local check_icon = Instance.new("ImageLabel")
check_icon.Size = UDim2.fromOffset(13, 13)
check_icon.Position = UDim2.fromOffset(6, 7)
check_icon.BackgroundTransparency = 1
check_icon.Image = CHECK_ICON_ASSET
check_icon.ImageColor3 = Theme.Accent
check_icon.Parent = discord_card

local dc_text = Instance.new("TextLabel")
dc_text.Size = UDim2.new(1, -28, 0, 34)
dc_text.Position = UDim2.fromOffset(22, 5)
dc_text.BackgroundTransparency = 1
dc_text.Text = "Beli/akses WatVIP, lapor bug, atau saran kategori? Join Discord:"
dc_text.TextColor3 = Theme.Text
dc_text.Font = Enum.Font.Gotham
dc_text.TextSize = 8
dc_text.LineHeight = 0.95
dc_text.TextWrapped = true
dc_text.TextXAlignment = Enum.TextXAlignment.Left
dc_text.TextYAlignment = Enum.TextYAlignment.Top
dc_text.Parent = discord_card

local copy_dc_btn = Instance.new("TextButton")
copy_dc_btn.Size = UDim2.new(1, -12, 0, 25)
copy_dc_btn.Position = UDim2.fromOffset(6, 43)
copy_dc_btn.BackgroundColor3 = Theme.Accent
copy_dc_btn.Text = "Copy Link Discord"
copy_dc_btn.TextColor3 = Theme.Bg
copy_dc_btn.Font = Enum.Font.GothamBold
copy_dc_btn.TextSize = 9
copy_dc_btn.Parent = discord_card
add_corner(copy_dc_btn, 6)

-- ==========================================
-- TAB SWITCHER, KEY UNLOCK & RESTORE BUTTON
-- ==========================================
local function refresh_vip_lock_state()
    vip_blur_overlay.Visible = not is_vip_unlocked
    vip_ans_btn.Active = is_vip_unlocked
    vip_cat_btn.Active = is_vip_unlocked

    if is_vip_unlocked then
        status_header_lbl.Text = 'STATUS : 👑<font color="#2EC470">W</font><font color="#FFFFFF">at</font><font color="#F5C430">VIP</font>'
        set_vip_status(vip_current_cat and ("Kategori terkunci: " .. vip_current_cat) or "Menunggu kategori...", Theme.Green)
    else
        status_header_lbl.Text = 'STATUS : 🎖️<font color="#2EC470">W</font><font color="#FFFFFF">at</font><font color="#FF8C24">FREE</font>'
        set_vip_status("Terkunci (Butuh Key WatVIP)", Theme.Muted)
    end
end

local function switch_tab(tab_name)
    active_tab = tab_name
    vip_page.Visible = (tab_name == "vip")
    free_page.Visible = (tab_name == "free")
    info_page.Visible = (tab_name == "info")

    vip_tab_btn.BackgroundColor3 = (tab_name == "vip") and Theme.Row or Theme.Card
    vip_tab_label.TextColor3 = (tab_name == "vip") and Theme.Text or Theme.Muted

    free_tab_btn.BackgroundColor3 = (tab_name == "free") and Theme.Row or Theme.Card
    free_tab_label.TextColor3 = (tab_name == "free") and Theme.Text or Theme.Muted

    info_tab_btn.BackgroundColor3 = (tab_name == "info") and Theme.Row or Theme.Card
    info_tab_label.TextColor3 = (tab_name == "info") and Theme.Text or Theme.Muted

    if tab_name == "vip" then
        refresh_vip_lock_state()
    end
end

unlock_key_btn.Activated:Connect(function()
    local ok, msg = activate_vip_key_for_current_user(key_input.Text)
    if ok then
        is_vip_unlocked = true
        refresh_vip_lock_state()
        key_feedback_lbl.Text = msg
        key_feedback_lbl.TextColor3 = Theme.Green
        unlock_key_btn.Text = "WatVIP Aktif!"
        unlock_key_btn.BackgroundColor3 = Theme.Green
    else
        is_vip_unlocked = false
        refresh_vip_lock_state()
        key_feedback_lbl.Text = msg
        key_feedback_lbl.TextColor3 = Theme.Red
        unlock_key_btn.Text = "Coba Key Lain"
        unlock_key_btn.BackgroundColor3 = Theme.Red
        task.delay(1.5, function()
            if unlock_key_btn and unlock_key_btn.Parent and not is_vip_unlocked then
                unlock_key_btn.Text = "Aktifkan Key WatVIP"
                unlock_key_btn.BackgroundColor3 = Theme.Green
            end
        end)
    end
end)

vip_tab_btn.Activated:Connect(function() switch_tab("vip") end)
free_tab_btn.Activated:Connect(function() switch_tab("free") end)
info_tab_btn.Activated:Connect(function() switch_tab("info") end)

copy_dc_btn.Activated:Connect(function()
    local copied = copy_to_clipboard(DISCORD_INVITE_LINK)
    if copied then
        copy_dc_btn.Text = "Link Discord Disalin!"
        copy_dc_btn.BackgroundColor3 = Theme.Green
        copy_dc_btn.TextColor3 = Theme.Text
    else
        copy_dc_btn.Text = "Salin Gagal (Cek Executor)"
        copy_dc_btn.BackgroundColor3 = Theme.Red
        copy_dc_btn.TextColor3 = Theme.Text
    end
    task.delay(1.5, function()
        if copy_dc_btn and copy_dc_btn.Parent then
            copy_dc_btn.Text = "Copy Link Discord"
            copy_dc_btn.BackgroundColor3 = Theme.Accent
            copy_dc_btn.TextColor3 = Theme.Bg
        end
    end)
end)

local restore_btn = Instance.new("ImageButton")
restore_btn.Size = UDim2.fromOffset(48, 48)
restore_btn.Position = UDim2.new(0, 16, 0.25, 0)
restore_btn.BackgroundColor3 = Theme.Card
restore_btn.Image = USER_ICON_ASSET
restore_btn.ScaleType = Enum.ScaleType.Crop
restore_btn.Visible = false
restore_btn.Parent = gui
add_corner(restore_btn, 999)
attach_moving_rainbow_outline(restore_btn, 2.2)

local function make_draggable(frame_to_drag, handle)
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame_to_drag.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame_to_drag.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

make_draggable(main, header)
make_draggable(restore_btn, restore_btn)

min_btn.Activated:Connect(function()
    main.Visible = false
    restore_btn.Visible = true
end)

restore_btn.Activated:Connect(function()
    main.Visible = true
    restore_btn.Visible = false
end)

close_btn.Activated:Connect(function()
    is_running = false
    gui:Destroy()
end)

-- ==========================================
-- GAME UI SCANNER & HELPER FUNCTIONS
-- ==========================================
local function clean_text(str)
    if not str then return "" end
    local s = string.gsub(str, "<[^>]+>", "")
    s = string.gsub(s, "%s+", " ")
    return string.lower(string.match(s, "^%s*(.-)%s*$") or "")
end

local function is_actually_visible(obj)
    local cur = obj
    while cur do
        if cur:IsA("ScreenGui") and not cur.Enabled then
            return false
        end
        if cur:IsA("GuiObject") and not cur.Visible then
            return false
        end
        cur = cur.Parent
    end
    return true
end

local function get_game_ui_roots()
    local roots = {}
    if LocalPlayer then
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pg then table.insert(roots, pg) end
    end
    if type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and hui then table.insert(roots, hui) end
    end
    return roots
end

local function score_roll_or_banner(obj, cat_label)
    local pos = obj.AbsolutePosition
    local size = obj.AbsoluteSize
    local cam = workspace.CurrentCamera
    local vp_x = (cam and cam.ViewportSize.X) or 800

    if size.X < 40 or size.Y < 12 then
        return -999
    end

    if obj:FindFirstAncestorWhichIsA("ScrollingFrame") or obj:FindFirstAncestorWhichIsA("BillboardGui") or obj:FindFirstAncestorWhichIsA("SurfaceGui") then
        return -999
    end

    local score = 0
    local cleaned = clean_text(obj.Text)
    local low_cat = string.lower(cat_label)

    if cleaned == low_cat then
        score += 100
    elseif string.find(cleaned, low_cat, 1, true) then
        score += 35
    else
        return -999
    end

    if pos.Y >= 0 and pos.Y <= 140 then
        score += 90
    elseif pos.Y > 140 and pos.Y <= 265 then
        score += 55
    else
        score -= 120
    end

    local center_x = pos.X + (size.X * 0.5)
    local dist_center = math.abs(center_x - (vp_x * 0.5))
    if dist_center <= (vp_x * 0.35) then
        score += 60
    elseif dist_center > (vp_x * 0.48) then
        score -= 90
    end

    if size.X >= 100 then
        score += 25
    end

    return score
end

local function scan_raw_category()
    local best_cat = nil
    local best_score = 100

    for _, root in ipairs(get_game_ui_roots()) do
        for _, v in ipairs(root:GetDescendants()) do
            if not v:IsDescendantOf(gui) and v:IsA("TextLabel") and is_actually_visible(v) then
                local path = v:GetFullName()
                if not string.find(path, "CoreGui") and not string.find(path, "Console") then
                    local txt = clean_text(v.Text)
                    if txt ~= "" and #txt <= 60 then
                        for cat, _ in pairs(WordBank) do
                            local low_cat = string.lower(cat)
                            if txt == low_cat or string.find(txt, low_cat, 1, true) then
                                local s = score_roll_or_banner(v, cat)
                                if s > best_score then
                                    best_score = s
                                    best_cat = cat
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return best_cat
end

local function score_answer_textbox(tb)
    local sz = tb.AbsoluteSize
    if sz.X < 50 or sz.Y < 12 then
        return -999
    end

    local score = 20
    local ph = clean_text(tb.PlaceholderText)
    local nm = clean_text(tb.Name)
    local tx = clean_text(tb.Text)

    if string.find(ph, "jawab", 1, true) or string.find(nm, "jawab", 1, true) or string.find(tx, "jawab", 1, true) then
        score += 90
    end
    if string.find(nm, "input", 1, true) or string.find(nm, "answer", 1, true) or string.find(nm, "box", 1, true) then
        score += 40
    end
    if tb.TextEditable then
        score += 15
    end
    if sz.X >= 120 then
        score += 20
    end

    return score
end

local function find_answer_textbox()
    local best_box = nil
    local best_score = 0

    for _, root in ipairs(get_game_ui_roots()) do
        for _, v in ipairs(root:GetDescendants()) do
            if not v:IsDescendantOf(gui) and v:IsA("TextBox") and is_actually_visible(v) then
                local path = v:GetFullName()
                if not string.find(path, "CoreGui") and not string.find(path, "Console") then
                    local s = score_answer_textbox(v) + 25
                    if s > best_score then
                        best_score = s
                        best_box = v
                    end
                end
            end
        end
    end

    return best_box
end

local function find_masukkan_target()
    local keywords = {"masukkan", "kirim", "submit", "enter", "send", "jawab"}
    local best_obj = nil
    local best_score = 0

    for _, root in ipairs(get_game_ui_roots()) do
        for _, v in ipairs(root:GetDescendants()) do
            if not v:IsDescendantOf(gui) and v:IsA("GuiObject") and is_actually_visible(v) then
                local bag = clean_text(v:IsA("TextLabel") and v.Text or (v:IsA("TextButton") and v.Text or "")) .. " " .. clean_text(v.Name)
                for _, d in ipairs(v:GetDescendants()) do
                    if d:IsA("TextLabel") or d:IsA("TextButton") then
                        bag = bag .. " " .. clean_text(d.Text)
                    end
                end

                local matched = false
                for _, kw in ipairs(keywords) do
                    if string.find(bag, kw, 1, true) then
                        matched = true
                        break
                    end
                end

                if matched and v.AbsoluteSize.X >= 24 and v.AbsoluteSize.Y >= 16 then
                    local score = 50
                    if v:IsA("TextButton") or v:IsA("ImageButton") then
                        score += 55
                    end
                    if string.find(bag, "masukkan", 1, true) then
                        score += 50
                    end
                    if score > best_score then
                        best_score = score
                        best_obj = v
                    end
                end
            end
        end
    end

    return best_obj
end

local function tap_screen_point(x, y)
    pcall(function()
        VirtualInputManager:SendTouchEvent(1, Enum.UserInputState.Begin.Value, x, y)
        task.wait(0.05)
        VirtualInputManager:SendTouchEvent(1, Enum.UserInputState.End.Value, x, y)
    end)
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
    end)
end

local function trigger_masukkan()
    local target = find_masukkan_target()
    local fired = false

    if target and target.Parent then
        local absPos = target.AbsolutePosition
        local absSize = target.AbsoluteSize
        local inset = GuiService:GetGuiInset()
        local x = absPos.X + (absSize.X * 0.5) + inset.X
        local y = absPos.Y + (absSize.Y * 0.5) + inset.Y

        pcall(function()
            if type(firesignal) == "function" then
                if target:IsA("TextButton") or target:IsA("ImageButton") then
                    firesignal(target.Activated)
                    firesignal(target.MouseButton1Click)
                    fired = true
                end
            end
        end)

        tap_screen_point(x, y)
        return true
    end

    local cam = workspace.CurrentCamera
    if cam then
        local vp = cam.ViewportSize
        tap_screen_point(vp.X * 0.84, vp.Y * 0.915)
        return true
    end
    return fired
end

local function sync_board_used_words(cat, target_set)
    if not cat or not target_set then return end
    local cam = workspace.CurrentCamera
    local vp_x = (cam and cam.ViewportSize.X) or 800
    local vp_y = (cam and cam.ViewportSize.Y) or 600

    for _, root in ipairs(get_game_ui_roots()) do
        for _, v in ipairs(root:GetDescendants()) do
            if not v:IsDescendantOf(gui) and v:IsA("TextLabel") and is_actually_visible(v) then
                local pos = v.AbsolutePosition
                local sz = v.AbsoluteSize
                if pos.X > vp_x * 0.25 and pos.X < vp_x * 0.72 and pos.Y > vp_y * 0.16 and pos.Y < vp_y * 0.82 and sz.X >= 40 and sz.Y >= 12 then
                    local cleaned = clean_text(v.Text)
                    if cleaned ~= "" and not string.find(cleaned, "^%+%d+$") then
                        target_set[cleaned] = true
                    end
                end
            end
        end
    end
end

-- ==========================================
-- LOGIKA WatVIP (Hanya aktif bila is_vip_unlocked == true)
-- ==========================================
local function vip_pick_next_word(cat)
    local pool = WordBank[cat]
    if not pool or #pool == 0 then
        vip_finished_cats[cat] = true
        return nil
    end

    vip_used_words[cat] = vip_used_words[cat] or {}
    sync_board_used_words(cat, vip_used_words[cat])

    local start_idx = (vip_word_index[cat] or 0) + 1
    for offset = 0, #pool - 1 do
        local idx = ((start_idx + offset - 1) % #pool) + 1
        local candidate = pool[idx]
        local low_c = clean_text(candidate)
        if not vip_used_words[cat][low_c] then
            vip_word_index[cat] = idx
            vip_used_words[cat][low_c] = true
            return candidate
        end
    end

    vip_finished_cats[cat] = true
    return nil
end

local vip_submitting = false

local function vip_submit_answer(word)
    if not is_vip_unlocked or vip_submitting then return false end

    local box = find_answer_textbox()
    if not box or not box.Parent then
        set_vip_status("Menunggu fasa isi jawaban...", Theme.Muted)
        return false
    end

    vip_submitting = true
    pcall(function()
        box:CaptureFocus()
        box.Text = ""
        box.Text = word
    end)
    task.wait(0.08)

    trigger_masukkan()
    set_vip_status("Kirim: " .. word, Theme.Green)

    task.delay(0.7, function()
        vip_submitting = false
    end)
    return true
end

local function on_vip_category_settled(cat)
    local is_new = (vip_current_cat ~= cat)
    vip_current_cat = cat
    if is_new then
        vip_used_words[vip_current_cat] = {}
        vip_word_index[vip_current_cat] = 0
        vip_finished_cats[vip_current_cat] = nil
        sync_board_used_words(vip_current_cat, vip_used_words[vip_current_cat])
    end
    vip_switch_ticks = 0
    vip_cat_value.Text = vip_current_cat
    vip_cat_value.TextColor3 = Theme.Green
    if is_vip_unlocked then
        set_vip_status("Kategori terkunci: " .. vip_current_cat, Theme.Green)
    end
end

vip_ans_btn.Activated:Connect(function()
    if not is_vip_unlocked then return end
    vip_auto_answer = not vip_auto_answer
    if vip_auto_answer then
        vip_ans_btn.BackgroundColor3 = Theme.Green
        vip_ans_btn.Text = "Auto Isi & Kirim: ON"
        if vip_current_cat and vip_finished_cats[vip_current_cat] then
            set_vip_status("Selesai: Kata kategori habis", Theme.Muted)
        else
            set_vip_status("Auto isi & kirim aktif", Theme.Green)
        end
    else
        vip_ans_btn.BackgroundColor3 = Theme.Red
        vip_ans_btn.Text = "Auto Isi & Kirim: OFF"
        set_vip_status("Auto isi & kirim OFF", Theme.Muted)
    end
end)

vip_cat_btn.Activated:Connect(function()
    if not is_vip_unlocked then return end
    vip_auto_check = not vip_auto_check
    vip_stable_ticks = 0
    vip_switch_ticks = 0
    vip_candidate_cat = nil
    if vip_auto_check then
        vip_cat_btn.Text = "Auto Check Category: ON"
        vip_cat_btn.TextColor3 = Theme.Accent
    else
        vip_cat_btn.Text = "Auto Check Category: OFF"
        vip_cat_btn.TextColor3 = Theme.Muted
    end
end)

-- ==========================================
-- LOGIKA WatFREE (Auto Cat + Max 10 Kata + Next Kata Tulis & Kirim Manual)
-- ==========================================
local function refresh_free_ui()
    if not free_current_cat then
        free_cat_value.Text = "Menunggu..."
        free_cat_value.TextColor3 = Theme.Gold
        free_preview_label.Text = "Kata Berikutnya: -"
        free_next_btn.Text = "Next Kata (0/" .. WATFREE_MAX_WORDS .. ") • Tulis dan Kirim Manual"
        return
    end

    free_cat_value.Text = free_current_cat
    free_cat_value.TextColor3 = Theme.Orange

    local count = free_copied_count[free_current_cat] or 0
    free_next_btn.Text = "Next Kata (" .. count .. "/" .. WATFREE_MAX_WORDS .. ") • Tulis dan Kirim Manual"

    if count >= WATFREE_MAX_WORDS then
        free_preview_label.Text = "Limit 10 kata tercapai (Upgrade WatVIP)"
        free_preview_label.TextColor3 = Theme.Gold
        set_free_status("Batas 10 kata WatFREE tercapai", Theme.Gold)
        return
    end

    local pool = WordBank[free_current_cat]
    free_copied_words[free_current_cat] = free_copied_words[free_current_cat] or {}
    local start_idx = (free_word_index[free_current_cat] or 0) + 1
    local preview_word = nil

    if pool and #pool > 0 then
        for offset = 0, #pool - 1 do
            local idx = ((start_idx + offset - 1) % #pool) + 1
            local cand = pool[idx]
            if not free_copied_words[free_current_cat][clean_text(cand)] then
                preview_word = cand
                break
            end
        end
    end

    if preview_word then
        free_preview_label.Text = "Kata Berikutnya: " .. preview_word
        free_preview_label.TextColor3 = Theme.Text
    else
        free_preview_label.Text = "Kata kategori habis"
        free_preview_label.TextColor3 = Theme.Muted
    end
end

local function on_free_category_settled(cat)
    local is_new = (free_current_cat ~= cat)
    free_current_cat = cat
    if is_new then
        free_copied_words[free_current_cat] = {}
        free_word_index[free_current_cat] = 0
        free_copied_count[free_current_cat] = 0
    end
    free_switch_ticks = 0
    refresh_free_ui()
    set_free_status("Kategori terkunci: " .. free_current_cat, Theme.Green)
end

free_cat_btn.Activated:Connect(function()
    free_auto_check = not free_auto_check
    free_stable_ticks = 0
    free_switch_ticks = 0
    free_candidate_cat = nil
    if free_auto_check then
        free_cat_btn.Text = "Auto Check Category: ON"
        free_cat_btn.TextColor3 = Theme.Accent
    else
        free_cat_btn.Text = "Auto Check Category: OFF"
        free_cat_btn.TextColor3 = Theme.Muted
    end
end)

free_next_btn.Activated:Connect(function()
    if not free_current_cat then
        set_free_status("Menunggu kategori terdeteksi...", Theme.Gold)
        return
    end

    local count = free_copied_count[free_current_cat] or 0
    if count >= WATFREE_MAX_WORDS then
        set_free_status("Maksimal 10 kata/kategori untuk WatFREE", Theme.Gold)
        return
    end

    local pool = WordBank[free_current_cat]
    if not pool or #pool == 0 then
        set_free_status("Kata kategori tidak tersedia", Theme.Muted)
        return
    end

    free_copied_words[free_current_cat] = free_copied_words[free_current_cat] or {}
    local start_idx = (free_word_index[free_current_cat] or 0) + 1
    local picked_word = nil
    local picked_idx = nil

    for offset = 0, #pool - 1 do
        local idx = ((start_idx + offset - 1) % #pool) + 1
        local cand = pool[idx]
        if not free_copied_words[free_current_cat][clean_text(cand)] then
            picked_word = cand
            picked_idx = idx
            break
        end
    end

    if not picked_word then
        set_free_status("Semua kata kategori sudah dipakai", Theme.Muted)
        return
    end

    free_word_index[free_current_cat] = picked_idx
    free_copied_words[free_current_cat][clean_text(picked_word)] = true
    free_copied_count[free_current_cat] = count + 1
    free_preview_label.Text = "Kata Dipilih: " .. picked_word
    set_free_status("Kata: " .. picked_word .. " (Tulis & kirim manual)", Theme.Green)
    free_next_btn.Text = "Next Kata (" .. free_copied_count[free_current_cat] .. "/" .. WATFREE_MAX_WORDS .. ") • Tulis dan Kirim Manual"
end)

-- ==========================================
-- BACKGROUND LOOPS
-- ==========================================
task.spawn(function()
    while is_running do
        task.wait(0.15)
        local raw = scan_raw_category()

        if vip_auto_check then
            if raw then
                if not vip_current_cat then
                    if raw == vip_candidate_cat then
                        vip_stable_ticks += 1
                    else
                        vip_candidate_cat = raw
                        vip_stable_ticks = 1
                    end
                    if vip_stable_ticks >= SETTLE_TICKS_REQUIRED then
                        on_vip_category_settled(vip_candidate_cat)
                    elseif active_tab == "vip" and is_vip_unlocked then
                        vip_cat_value.Text = vip_candidate_cat
                        vip_cat_value.TextColor3 = Theme.Gold
                        set_vip_status("Mengacak: " .. vip_candidate_cat, Theme.Gold)
                    end
                elseif raw == vip_current_cat then
                    vip_switch_ticks = 0
                    vip_candidate_cat = raw
                    vip_cat_value.Text = vip_current_cat
                    vip_cat_value.TextColor3 = Theme.Green
                else
                    if raw == vip_candidate_cat then
                        vip_switch_ticks += 1
                    else
                        vip_candidate_cat = raw
                        vip_switch_ticks = 1
                    end
                    if vip_switch_ticks >= SWITCH_TICKS_REQUIRED then
                        on_vip_category_settled(vip_candidate_cat)
                    end
                end
            else
                if not vip_current_cat then
                    vip_stable_ticks = 0
                    vip_candidate_cat = nil
                end
                vip_switch_ticks = 0
            end
        end

        if free_auto_check then
            if raw then
                if not free_current_cat then
                    if raw == free_candidate_cat then
                        free_stable_ticks += 1
                    else
                        free_candidate_cat = raw
                        free_stable_ticks = 1
                    end
                    if free_stable_ticks >= SETTLE_TICKS_REQUIRED then
                        on_free_category_settled(free_candidate_cat)
                    elseif active_tab == "free" then
                        free_cat_value.Text = free_candidate_cat
                        free_cat_value.TextColor3 = Theme.Gold
                        set_free_status("Mengacak: " .. free_candidate_cat, Theme.Gold)
                    end
                elseif raw == free_current_cat then
                    free_switch_ticks = 0
                    free_candidate_cat = raw
                    refresh_free_ui()
                else
                    if raw == free_candidate_cat then
                        free_switch_ticks += 1
                    else
                        free_candidate_cat = raw
                        free_switch_ticks = 1
                    end
                    if free_switch_ticks >= SWITCH_TICKS_REQUIRED then
                        on_free_category_settled(free_candidate_cat)
                    end
                end
            else
                if not free_current_cat then
                    free_stable_ticks = 0
                    free_candidate_cat = nil
                end
                free_switch_ticks = 0
            end
        end
    end
end)

task.spawn(function()
    while is_running do
        task.wait(1.0)
        if is_vip_unlocked and vip_auto_answer and not vip_submitting then
            if vip_auto_check then
                local immediate_cat = scan_raw_category()
                if immediate_cat and immediate_cat ~= vip_current_cat then
                    on_vip_category_settled(immediate_cat)
                end
            end

            if vip_current_cat then
                if vip_finished_cats[vip_current_cat] then
                    set_vip_status("Selesai: Kata kategori habis", Theme.Muted)
                else
                    local word = vip_pick_next_word(vip_current_cat)
                    if word then
                        vip_submit_answer(word)
                    else
                        set_vip_status("Selesai: Kata kategori habis", Theme.Muted)
                    end
                end
            end
        end
    end
end)

refresh_vip_lock_state()