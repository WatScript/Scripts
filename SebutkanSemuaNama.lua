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
    ["watashid_official"] = true,
}

local OWNER_USER_IDS = {
    -- [123456789] = true,
}

-- 10 Key random susah ditebak (1 Key = Lock 1 username)
local GENERATED_VIP_KEYS = {
 --   "",
    "WVIP-3T8N-R5V9-42HZ",
    "WVIP-7B2C-M6Y4-91DF",
    "WVIP-5K9L-X3W8-64JR",
    "WVIP-8P4G-Q2H7-19VB",
    "WVIP-2Z6D-N9J5-73TM",
    "WVIP-6F3S-V8C4-57KW",
    "WVIP-4R7Y-B2L9-85GX",
    "WVIP-9H5J-T4K6-31NP",
    "WVIP-1W8M-G7Z3-60LQ",
}

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

local function is_valid_generated_key(k)
    for _, valid_k in ipairs(GENERATED_VIP_KEYS) do
        if k == valid_k then
            return true
        end
    end
    return false
end

load_lock_data()

local function check_initial_vip_access()
    if is_owner_player() then
        return true, "OWNER"
    end
    local uname = string.lower(get_player_username())
    local bound_key = MemoryLockStore.unlocked_users[uname]
    if bound_key and is_valid_generated_key(bound_key) and MemoryLockStore.bindings[bound_key] == uname then
        return true, bound_key
    end
    return false, nil
end

local function activate_vip_key_for_current_user(input_key)
    load_lock_data()
    local uname = string.lower(get_player_username())
    local clean_key = string.upper(string.match(input_key or "", "^%s*(.-)%s*$") or "")

    if clean_key == "" or not is_valid_generated_key(clean_key) then
        return false, "Key tidak valid! Gunakan Key WatVIP resmi."
    end

    local locked_owner = MemoryLockStore.bindings[clean_key]
    if locked_owner and locked_owner ~= uname then
        return false, "1 Key 1 akun sahaja!"
    end

    MemoryLockStore.bindings[clean_key] = uname
    MemoryLockStore.unlocked_users[uname] = clean_key
    save_lock_data()
    return true, "Key WatVIP aktif & dikunci ke @" .. get_player_username()
end

-- ==========================================
-- WORDBANK (TERMASUK KATEGORI BARU DARI GAMBAR & VIDEO)
-- ==========================================
local WordBank = {
    ["Makhluk Fiksi"] = {"Naga Api", "Phoenix", "Unicorn", "Grifin", "Pegasus", "Minotaur", "Kraken", "Leviathan", "Hydra", "Cerberus", "Basilisk Fiksi", "Vampir", "Werewolf", "Gorgon", "Medusa", "Centaur", "Banshee", "Golem", "Elf", "Kurcaci Fiksi", "Putri Duyung", "Peri", "Genie", "Yeti", "Bigfoot"},
    ["Hal-hal di Laut"] = {"Terumbu Karang", "Palung Laut", "Kapal Selam", "Kapal Pesiar", "Kapal Kargo", "Kapal Nelayan", "Mercusuar", "Bintang Laut", "Kuda Laut", "Ubur-Ubur", "Gurita", "Ikan Paus", "Ikan Hiu", "Ikan Pari", "Lumba-Lumba", "Penyu Laut", "Rumput Laut", "Kerang", "Kepiting", "Lobster", "Ombak", "Arus Laut", "Pelampung", "Jangkar"},
    ["Hal-hal di Mal"] = {"Eskalator", "Lift", "Food Court", "Bioskop", "Toko Baju", "Toko Sepatu", "Area Parkir", "ATM", "Kasir", "Lampu Gantung", "Papan Petunjuk", "Toilet Umum", "Tangga Darurat", "Promosi Diskon", "Kartu Member", "Tas Belanja", "Manekin", "Kios", "Kursi Tunggu", "Keamanan Mal"},
    ["Hal-hal di Peternakan"] = {"Kandang Sapi", "Kandang Ayam", "Padang Rumput", "Jerami", "Traktor", "Ember Susu", "Pagar Kayu", "Lumbung Padi", "Sapi Perah", "Kuda", "Kambing", "Domba", "Ayam", "Bebek", "Babi", "Petani", "Sekop", "Kereta Dorong", "Palung Air", "Pakan Ternak"},
    ["Hal-hal di Rumah"] = {"Ruang Tamu", "Kamar Tidur", "Dapur", "Kamar Mandi", "Sofa", "Kasur", "Lemari", "Meja Makan", "Kursi", "Televisi", "Kulkas", "Lampu", "Jendela", "Pintu", "Atap", "Halaman Rumah", "Garasi", "Keset", "Gorden", "Jam Dinding", "Sapu", "Pel Lantai"},
    ["Hal-hal di Rumah Sakit"] = {"Ambulans", "Ruang IGD", "Ruang Rawat Inap", "Ruang Operasi", "Apotek", "Stetoskop", "Jarum Suntik", "Infus", "Kursi Roda", "Brankar", "Masker Medis", "Sarung Tangan Medis", "Termometer", "Dokter", "Perawat", "Pasien", "Resep Obat", "Meja Periksa", "Lampu Operasi", "Papan Antrean"},
    ["Makanan"] = {"Nasi Goreng", "Mie Goreng", "Sate Ayam", "Bakso", "Soto Ayam", "Rendang", "Gado-Gado", "Nasi Padang", "Ayam Goreng", "Ayam Bakar", "Pecel Lele", "Capcay", "Nasi Uduk", "Bubur Ayam", "Lontong Sayur", "Tahu Tempe", "Rawon", "Gudeg", "Pempek", "Martabak", "Nasi Kuning", "Ikan Bakar", "Sup Ayam", "Semur"},
    ["Hal-hal di Luar Angkasa"] = {"Lubang Hitam", "Stasiun Luar Angkasa", "Pesawat Ulang-Alik", "Sabuk Asteroid", "Teleskop Luar Angkasa", "Wahana Antariksa", "Cincin Saturnus", "Bima Sakti", "Supernova", "Nebula", "Asteroid", "Komet", "Meteor", "Meteoroid", "Astronot", "Satelit", "Tata Surya", "Planet", "Galaksi", "Bintang", "Bulan", "Matahari", "Roket", "Mars", "Jupiter", "Saturnus", "Venus", "Merkurius", "Uranus", "Neptunus", "Gerhana", "Aurora", "Kawah Bulan", "Debu Kosmik"},
    ["Kekuatan Super"] = {"Membatu", "Regenerasi", "Mengendalikan Darah", "Mengendalikan Tulang", "Kekuatan Kristal", "Kekuatan Lendir", "Ledakan Energi", "Perisai Pikiran", "Penglihatan Termal", "Ledakan Psikis", "Mengendalikan Gravitasi", "Kelincahan Super", "Tak Terlihat", "Kulit Logam", "Abadi", "Berubah Wujud", "Perjalanan Waktu", "Penglihatan Laser", "Penglihatan X-Ray", "Pendengaran Super", "Portal Dimensi", "Kekuatan Angin", "Telekinesis", "Telepati", "Terbang", "Menghilang", "Kekuatan Super", "Kecepatan Super", "Menembakkan Api", "Membekukan", "Menembakkan Es", "Mengendalikan Air", "Mengendalikan Tanah", "Kekebalan Tubuh", "Membaca Pikiran", "Menggerakkan Benda", "Memperbesar Tubuh", "Mengecilkan Tubuh", "Menembakkan Petir", "Lompatan Super", "Ilusi"},
    ["Reptil"] = {"Star tortoise", "Five-lined skink", "Knight anole", "Eyelash viper", "Titanosaurus", "Kentrosaurus", "Tokek", "Kobra Penyembur", "Ular Rumput", "Anakonda", "Basilisk", "Chameleon", "Gharial", "Tuatara", "Kura-kura Darat", "Kura-kura Air", "Kadal Gurun", "Ular Sanca", "Ular Kobra", "Ular Piton", "Ular Welang", "Ular Tedung", "Kadal Pohon", "Buaya Muara", "Bunglon", "Aligator", "Buaya", "Komodo", "Ular", "Kadal", "Kura-kura", "Penyu", "Iguana", "Tokek Rumah", "Cicak", "Cicak Rumah", "Biawak", "Ular Laut"},
    ["Hal-hal di Pesta"] = {"Terompet Pesta", "Kembang Api", "Pita Dekorasi", "Foto Booth", "Lampu Warna-Warni", "Pesta Kostum", "Piring Kertas", "Gelas Plastik", "Balon", "Topi Pesta", "Kue Ulang Tahun", "Lilin", "Konfeti", "Banner", "Hadiah", "Kado", "Musik", "DJ", "Minuman", "Camilan", "Undangan", "Tamu", "MC", "Panggung", "Tepuk Tangan", "Kue Tart", "Pinata", "Soda"},
    ["Alat Musik"] = {"Harmonika", "Saksofon", "Kolintang", "Sasando", "Akordeon", "Kontrabas", "Mandolin", "Xylophone", "Klarinet", "Ukulele", "Gitar", "Piano", "Biola", "Drum", "Suling", "Terompet", "Rebana", "Kecapi", "Gendang", "Harpa", "Keyboard", "Bass", "Cello", "Flute", "Gong", "Tifa", "Marakas", "Tamborin", "Banjo", "Sitar", "Gambus"},
    ["Aplikasi"] = {"Pinterest", "LinkedIn", "Snapchat", "Duolingo", "Messenger", "Telegram", "Discord", "Spotify", "Netflix", "CapCut", "Canva", "WhatsApp", "Instagram", "TikTok", "Facebook", "Roblox", "YouTube", "Shopee", "Tokopedia", "Gojek", "Grab", "Google", "Chrome", "Zoom", "Gmail", "Maps", "Twitch", "Reddit", "Twitter", "X", "Waze", "Lazada"},
    ["Bagian Tubuh"] = {"Pergelangan Tangan", "Telapak Tangan", "Telapak Kaki", "Jari Kaki", "Bulu Mata", "Pinggang", "Pinggul", "Betis", "Paha", "Dagu", "Dahi", "Kepala", "Mata", "Hidung", "Telinga", "Mulut", "Bibir", "Gigi", "Lidah", "Leher", "Bahu", "Lengan", "Siku", "Tangan", "Jari", "Dada", "Perut", "Punggung", "Kaki", "Lutut", "Tumit", "Alis", "Pipi"},
    ["Bahasa"] = {"Minangkabau", "Yunani", "Swedia", "Norwegia", "Polandia", "Tagalog", "Bugis", "Madura", "Tamil", "Portugis", "Belanda", "Turki", "Indonesia", "Melayu", "Inggris", "Jepang", "Korea", "Mandarin", "Arab", "Spanyol", "Prancis", "Jerman", "Rusia", "Hindi", "Thailand", "Vietnam", "Italia", "Sunda", "Jawa", "Bali", "Aceh", "Batak"},
    ["Barang di Dapur"] = {"Pembuka Kaleng", "Gelas Ukur", "Sendok Sayur", "Penanak Nasi", "Pisau Dapur", "Talenan", "Spatula", "Sutil", "Ayakan", "Saringan", "Parutan", "Loyang", "Kukusan", "Panci", "Wajan", "Kompor", "Sendok", "Garpu", "Mangkuk", "Piring", "Gelas", "Kulkas", "Blender", "Ketel", "Teko", "Cangkir", "Sumpit", "Mixer", "Oven", "Microwave", "Nampan", "Botol Minyak"},
    ["Barang di Kamar Mandi"] = {"Spons Mandi", "Bathub", "Tisu Toilet", "Sabun Cuci Muka", "Gelas Kumur", "Pewangi Ruangan", "Sikat Punggung", "Sabun Cair", "Tempat Sabun", "Rak Handuk", "Sabun", "Shampo", "Sikat Gigi", "Pasta Gigi", "Handuk", "Gayung", "Ember", "Cermin", "Shower", "Sikat WC", "Keset", "Deodoran", "Lulur", "Wastafel", "Kran Air", "Sandal Jepit", "Pembersih Lantai", "Baskom", "Sikat Lantai"},
    ["Barang Elektronik"] = {"Proyektor", "Smartwatch", "Vacuum Cleaner", "Hair Dryer", "Router", "Powerbank", "Dispenser", "Harddisk", "Flashdisk", "Televisi", "Kulkas", "Mesin Cuci", "Laptop", "Smartphone", "Kipas Angin", "AC", "Setrika", "Microwave", "Speaker", "Kamera", "Printer", "Tablet", "Headset", "Earphone", "Lampu LED", "Monitor", "Keyboard", "Mouse", "Charger", "Radio"},
    ["Barang Mahal"] = {"Jet pribadi", "Pulau pribadi", "Berlian", "Mobil sport", "Yacht", "Penthouse", "Kapal pesiar", "Istana", "Rumah mewah", "Emas batangan", "Jam tangan mewah", "Helikopter pribadi", "Lukisan langka", "Batu zamrud", "Mutiara asli", "Jam saku emas", "Perhiasan emas", "Kalung berlian", "Cincin emas", "Mobil klasik", "Gelang emas", "Anting berlian", "Batu safir", "Batu ruby"},
    ["Benda Tajam"] = {"Jarum Suntik", "Kail Pancing", "Rencong", "Celurit", "Pisau Lipat", "Pisau Dapur", "Gergaji Besi", "Tombak Besi", "Belati", "Cutter", "Keris", "Sabit", "Pisau", "Gunting", "Pedang", "Golok", "Parang", "Silet", "Jarum", "Paku", "Kapak", "Tombak", "Gergaji", "Badik", "Pahat", "Taji"},
    ["Benda yang Berputar"] = {"Kompas Jarum", "Piringan Hitam", "Baling Helikopter", "Gasing Kayu", "Kincir Angin", "Komidi Putar", "Rol Kabel", "Katrol", "Turbin", "Gear", "Roda", "Kipas Angin", "Baling-Baling", "Gasing", "Bor Listrik", "Blender", "Bianglala", "Setir Mobil", "Mesin Cuci", "Kaset", "CD", "DVD", "Roda Sepeda", "Roda Mobil", "Mixer"},
    ["Benda yang Bulat"] = {"Jam Dinding", "Lampu Bohlam", "Bola Pingpong", "Tutup Botol", "Kancing Baju", "Kelengkeng", "Kelereng", "Koin", "Donat", "Semangka", "Jeruk", "Piring", "Ban Mobil", "Globe", "Cincin", "Gelang", "Apel", "Bola", "Bola Basket", "Bola Sepak", "Bola Tenis", "Kue Tar", "Roda Sepeda", "Bakso", "Tomat", "Anggur"},
    ["Buah dan Sayuran"] = {"Kacang Panjang", "Bawang Merah", "Bawang Putih", "Kelengkeng", "Seledri", "Brokoli", "Terong", "Mentimun", "Alpukat", "Melon", "Rambutan", "Apel", "Pisang", "Jeruk", "Mangga", "Semangka", "Anggur", "Stroberi", "Wortel", "Bayam", "Tomat", "Kubis", "Labu", "Nanas", "Pepaya", "Salak", "Durian", "Kelapa", "Kangkung", "Sawi", "Buncis", "Jagung", "Kentang", "Cabai", "Pir", "Nangka", "Leci"},
    ["Bunga dan Tanaman"] = {"Raflesia", "Edelweis", "Kenanga", "Cempaka", "Bugenvil", "Adenium", "Pohon Beringin", "Pohon Bambu", "Lidah Buaya", "Bonsai", "Lavender", "Kamboja", "Sakura", "Mawar", "Melati", "Anggrek", "Matahari", "Tulip", "Kaktus", "Pakis", "Aster", "Dahlia", "Krisan", "Teratai", "Pohon Kelapa", "Rumput", "Pohon Mangga", "Pohon Pisang"},
    ["Burung"] = {"Cendrawasih", "Kasuari", "Albatros", "Raja Udang", "Flamingo", "Penguin", "Kakatua", "Pelikan", "Burung Hantu", "Kenari", "Lovebird", "Perkutut", "Kutilang", "Elang", "Merpati", "Garuda", "Beo", "Pipit", "Nuri", "Merak", "Bangau", "Gagak", "Puyuh", "Ayam", "Bebek", "Angsa", "Kalkun", "Jalak", "Cerek", "Camar"},
    ["Camilan"] = {"Keripik Singkong", "Keripik Kentang", "Martabak Manis", "Kue Cubit", "Kue Nastar", "Kue Kastengel", "Makaroni Goreng", "Churros", "Basreng", "Biskuit", "Wafer", "Kacang Goreng", "Popcorn", "Cokelat", "Permen", "Gorengan", "Puding", "Bakwan", "Tahu Isi", "Pisang Goreng", "Cireng", "Cilok", "Kerupuk", "Kue Bolu", "Kue Lapis", "Risol", "Pastel", "Donat"},
    ["Cuaca dan Bencana"] = {"Puting Beliung", "Banjir Bandang", "Badai Salju", "Gelombang Panas", "Kebakaran Hutan", "Badai Pasir", "Hujan Es", "Angin Topan", "Gunung Meletus", "Tanah Longsor", "Kekeringan", "Tsunami", "Gempa Bumi", "Hujan", "Badai", "Panas Terik", "Berawan", "Banjir", "Kabut", "Petir", "Kilat", "Gerimis", "Angin Kencang", "Cerah", "Mendung", "Angin Ribut"},
    ["Emosi"] = {"Nostalgia", "Antusias", "Tersinggung", "Khawatir", "Jengkel", "Kecewa", "Bangga", "Terkejut", "Semangat", "Senang", "Sedih", "Marah", "Takut", "Cemas", "Malu", "Cinta", "Benci", "Bosan", "Kesal", "Iri", "Santai", "Gembira", "Bahagia", "Rindu", "Panik", "Lega", "Puas", "Hiba"},
    ["Game Roblox"] = {"Bee Swarm Simulator", "Natural Disaster Survival", "Build A Boat For Treasure", "Murder Mystery 2", "Pet Simulator 99", "Anime Defenders", "Dress to Impress", "Work at a Pizza Place", "Survive the Killer", "Blox Fruits", "Brookhaven", "Adopt Me", "Tower of Hell", "BedWars", "Doors", "Arsenal", "Evade", "Piggy", "Royale High", "MeepCity", "Jailbreak", "Fisch", "Rivals", "Blade Ball", "King Legacy", "Mic Up"},
    ["Gaya Rambut"] = {"Dreadlocks", "Comma Hair", "Undercut", "Wolfcut", "Buzz Cut", "Crew Cut", "Belah Tengah", "Belah Pinggir", "Poni Depan", "Poni Samping", "Mohawk", "Mullet", "Kuncir Kuda", "Ponytail", "Pendek", "Panjang", "Botak", "Bob", "Keriting", "Lurus", "Kepang", "Fade", "Cepol", "Pixie", "Afro", "Ikal", "Sanggul", "Layer"},
    ["Hal yang Bisa Menyala"] = {"Lampu Lalu Lintas", "Lampu Emergency", "Lampu Sorot", "Kembang Api", "Mercusuar", "Lampu Disko", "Lentera", "Api Unggun", "Layar HP", "Bintang Jatuh", "Lampu Tidur", "Lampu Jalan", "Korek Gas", "Lampu LED", "Lampu", "Lilin", "Api", "Senter", "Korek Api", "Obor", "Neon", "Bara Api", "Lampu Kilat", "Bara"},
    ["Hal yang Bisa Terbang"] = {"Paralayang", "Gantole", "Pesawat Tempur", "Burung Hantu", "Capung Jarum", "Kelelawar", "Balon Gas", "Kertas Pesawat", "Tupai Terbang", "Pesawat Jet", "Balon Udara", "Layang-Layang", "Helikopter", "Capung", "Lebah", "Kupu-Kupu", "Drone", "Roket", "Kumbang", "Lalat", "Nyamuk", "Burung", "Pesawat", "Elang", "Merpati", "Camar", "Bangau"},
    ["Hal yang Dingin"] = {"Kutub Utara", "Kutub Selatan", "Daun Mint", "Gunung Es", "Angin Gunung", "Ruang Ber-AC", "Hujan Es", "Es Serut", "Es Loli", "Es Campur", "Es Batu", "Es Krim", "Salju", "Air Dingin", "Kulkas", "Freezer", "Antartika", "Mint", "Air Es", "Angin Malam", "Air Mineral Dingin", "Batu Es", "Es Teh", "Es Jeruk"},
    ["Hal yang Panas"] = {"Air Mendidih", "Knalpot Motor", "Gurun Pasir", "Uap Panas", "Wajan Panas", "Sinar Matahari", "Kopi Panas", "Teh Panas", "Sup Panas", "Api Unggun", "Mesin Mobil", "Besi Panas", "Solder", "Lava", "Magma", "Kawah", "Api", "Matahari", "Setrika", "Kompor", "Oven", "Bara", "Air Panas", "Susu Panas"},
    ["Hal-hal Berwarna Biru"] = {"Batu Safir", "Air Laut", "Kolam Renang", "Awan Biru", "Kemeja Biru", "Sepatu Biru", "Pita Biru", "Topi Biru", "Payung Biru", "Tas Biru", "Botol Biru", "Cangkir Biru", "Bunga Biru", "Langit", "Laut", "Safir", "Jeans", "Kaos Biru", "Bola Biru", "Cat Biru", "Kertas Biru", "Pintu Biru", "Buku Biru", "Lampu Biru"},
    ["Hal-hal Berwarna Hijau"] = {"Batu Zamrud", "Jeruk Nipis", "Sawi Hijau", "Apel Hijau", "Daun Teh", "Alpukat", "Brokoli", "Matcha", "Kiwi", "Daun", "Rumput", "Zamrud", "Lumut", "Hutan", "Kaktus", "Bayam", "Timun", "Pohon", "Semak", "Kaos Hijau", "Bola Hijau", "Kertas Hijau", "Padi", "Topi Hijau", "Tas Hijau", "Sepatu Hijau"},
    ["Hal-hal Berwarna Merah"] = {"Batu Ruby", "Cabai Rawit", "Cabai Merah", "Apel Merah", "Mawar Merah", "Tomat Merah", "Lampu Rem", "Batu Bata", "Bendera Merah", "Lipstik Merah", "Darah", "Ruby", "Semangka", "Stroberi", "Baju Merah", "Topi Merah", "Tas Merah", "Lampu Merah", "Ceri", "Delima", "Kaos Merah", "Cat Merah", "Bola Merah", "Sepatu Merah"},
    ["Hal-hal di Bandara"] = {"Menara Kontrol", "Boarding Pass", "Antrean Check-In", "Label Bagasi", "Peta Bandara", "Pesawat Komersial", "Landasan Pacu", "Bea Cukai", "Imigrasi", "Garbarata", "Troli Barang", "Papan Jadwal", "Pesawat", "Terminal", "Koper", "X-Ray", "Gate", "Paspor", "Bagasi", "Tiket Pesawat", "Petugas Keamanan", "Ruang Tunggu", "Pilot", "Pramugari", "Bandara", "Lounge"},
    ["Hal-hal di Pantai"] = {"Terumbu Karang", "Krim Tabir Surya", "Bintang Laut", "Payung Pantai", "Burung Camar", "Kapal Nelayan", "Tikar Pantai", "Sandal Pantai", "Bibir Pantai", "Batu Karang", "Mercusuar", "Pasir", "Ombak", "Kerang", "Pohon Kelapa", "Karang", "Kacamata Hitam", "Bola Pantai", "Kepiting", "Handuk", "Perahu", "Pelampung", "Air Laut", "Pantai"},
    ["Hal-hal di Restoran"] = {"Struk Pembayaran", "Lada dan Garam", "Peralatan Makan", "Botol Saus", "Tusuk Gigi", "Buku Menu", "Meja Kasir", "Ruang Makan", "Menu", "Pelayan", "Meja Makan", "Kursi", "Kasir", "Gelas", "Piring", "Sendok", "Garpu", "Serbet", "Dapur", "Koki", "Makanan", "Minuman", "Nampan", "Antrean", "Pesanan", "Cangkir"},
    ["Hari Raya dan Perayaan"] = {"Tahun Baru Islam", "Festival Lentera", "Cap Go Meh", "Kemerdekaan", "Halloween", "Valentine", "Idulfitri", "Iduladha", "Natal", "Tahun Baru", "Imlek", "Waisak", "Nyepi", "Ramadan", "Paskah", "Wisuda", "Ulang Tahun", "Pernikahan", "Hari Ibu", "Hari Ayah", "Hari Guru", "Hari Anak", "Syukuran", "Kenduri"},
    ["Hewan"] = {"Cendrawasih", "Orangutan", "Kasuari", "Landak", "Tupai", "Komodo", "Citah", "Kuda Nil", "Kura-Kura", "Kucing", "Anjing", "Sapi", "Kerbau", "Kambing", "Domba", "Kuda", "Gajah", "Singa", "Harimau", "Macan", "Beruang", "Panda", "Serigala", "Rubah", "Zebra", "Jerapah", "Badak", "Rusa", "Kanguru", "Koala", "Monyet", "Gorila", "Kelinci", "Buaya", "Katak", "Ikan", "Burung", "Ular", "Unta"},
    ["Ibu Kota Negara"] = {"Washington DC", "Kuala Lumpur", "New Delhi", "Abu Dhabi", "Wellington", "Stockholm", "Lisbon", "Vienna", "Athena", "Jakarta", "Tokyo", "Seoul", "Beijing", "Bangkok", "Singapura", "London", "Paris", "Berlin", "Roma", "Canberra", "Madrid", "Ottawa", "Moskow", "Kairo", "Riyadh", "Doha", "Hanoi", "Manila", "Oslo", "Bern"},
    ["Isi Tas Ransel"] = {"Buku Catatan", "Correction Tape", "Hand Sanitizer", "Buku Pelajaran", "Payung Lipat", "Kotak Makan", "Jaket Lipat", "Baju Ganti", "Buku Tulis", "Pensil", "Pulpen", "Penghapus", "Penggaris", "Laptop", "Charger", "Botol Minum", "Dompet", "Notebook", "Kunci", "Earphone", "Powerbank", "Spidol", "Tisu", "Kacamata", "Kalkulator", "Map", "Rautan", "Headset", "Amplop", "Binder"},
    ["Item Minecraft"] = {"Enchanted Golden Apple", "Crafting Table", "Ender Pearl", "Creeper Egg", "Water Bucket", "Lava Bucket", "Gold Ingot", "Iron Ingot", "Netherite", "Redstone", "Obsidian", "Emerald", "Diamond", "Pickaxe", "Sword", "Torch", "Bow", "Shield", "Axe", "Shovel", "Hoe", "Chest", "Furnace", "Bed", "Bucket", "Compass", "Clock", "Anvil"},
    ["Jenis Ikan"] = {"Cakalang", "Baronang", "Tenggiri", "Arwana", "Gurame", "Bandeng", "Kembung", "Mujair", "Louhan", "Kerapu", "Lele", "Nila", "Mas", "Tuna", "Salmon", "Hiu", "Pari", "Cupang", "Koi", "Sarden", "Kakap", "Bawal", "Patin", "Tongkol", "Guppy", "Belut", "Betta", "Oscar"},
    ["Jenis Pakaian"] = {"Celana Training", "Celana Panjang", "Celana Pendek", "Baju Tidur", "Polo Shirt", "Kaus Kaki", "Cardigan", "Baju Koko", "Tank Top", "Kaos Dalam", "Kaos", "Kemeja", "Rok", "Jaket", "Hoodie", "Sweater", "Gaun", "Jas", "Rompi", "Blouse", "Dasi", "Sabuk", "Seragam", "Gamis", "Celana Jeans", "Sarung", "Blazer", "Mantel"},
    ["Karakter Anime"] = {"Natsuki Subaru", "Rudeus Greyrat", "Killua Zoldyck", "Gon Freecss", "Edward Elric", "Megumi Fushiguro", "Itadori Yuji", "Tanjiro Kamado", "Levi Ackerman", "Gojo Satoru", "Naruto Uzumaki", "Monkey D. Luffy", "Son Goku", "Eren Yeager", "Light Yagami", "Sukuna", "Guts", "Sasuke Uchiha", "Kakashi Hatake", "Roronoa Zoro", "Vegeta", "Mikasa Ackerman", "Nezuko Kamado", "L Lawliet", "Rem", "Emilia", "Elaina", "Saitama"},
    ["Karakter Kartun"] = {"Squidward Tentacles", "Sandy Cheeks", "SpongeBob SquarePants", "Patrick Star", "Donald Duck", "Bugs Bunny", "Scooby-Doo", "Mr. Krabs", "Plankton", "Boboiboy", "Doraemon", "Shin-chan", "Tom", "Jerry", "Upin", "Ipin", "Mickey Mouse", "Minnie Mouse", "Nobita", "Shizuka", "Giant", "Suneo", "Popeye", "Garfield", "Dexter", "Tom Cat", "Gopal", "Yaya", "Ying"},
    ["Karakter Video Game"] = {"Arthur Morgan", "Master Chief", "Cloud Strife", "Sephiroth", "Solid Snake", "Jill Valentine", "Leon Kennedy", "Lara Croft", "Sub-Zero", "Scorpion", "Mega Man", "Mario", "Sonic", "Steve", "Link", "Kratos", "Pikachu", "CJ", "Luigi", "Princess Peach", "Bowser", "Tails", "Knuckles", "Pac-Man", "Kirby", "Yoshi", "Samus", "Ryu"},
    ["Kartun dan Acara TV"] = {"Avatar The Last Airbender", "Oggy and the Cockroaches", "Adventure Time", "Regular Show", "Rick and Morty", "Shaun the Sheep", "Powerpuff Girls", "We Bare Bears", "SpongeBob SquarePants", "Upin & Ipin", "Doraemon", "Boboiboy", "Tom and Jerry", "Larva", "Shin-chan", "Scooby-Doo", "Ben 10", "Pingu", "Peppa Pig", "Pororo", "Gumball", "Crayon Shin-chan", "Tom & Jerry", "Kiko"},
    ["Kegiatan di Dalam Ruangan"] = {"Beres-Beres Kamar", "Mendengarkan Musik", "Mengerjakan PR", "Merapikan Meja", "Menyapu Lantai", "Mengepel Lantai", "Mencuci Piring", "Bermain Catur", "Bermain Piano", "Bermain Gitar", "Menonton Anime", "Membaca Buku", "Menonton Film", "Bermain Game", "Memasak", "Belajar", "Menulis", "Melukis", "Tidur", "Menonton TV", "Menggambar", "Menjahit", "Berbincang", "Menyanyi", "Meditasi", "Menata Buku"},
    ["Kegiatan di Luar Ruangan"] = {"Bermain Layang-Layang", "Bermain Bulu Tangkis", "Menjelajah Alam", "Berenang di Pantai", "Bermain Skateboard", "Berkeliling Kota", "Mendaki Gunung", "Mendaki Bukit", "Menyiram Tanaman", "Bersepeda", "Berlari", "Piknik", "Berkemah", "Memancing", "Bermain Bola", "Berenang", "Berkebun", "Jalan Santai", "Jogging", "Bermain Basket", "Bermain Voli", "Berfoto", "Bermain Sepak Bola", "Berjemur", "Bersepeda Santai", "Lari Pagi"},
    ["Kendaraan"] = {"Kapal Selam", "Kereta Cepat", "Truk Gandeng", "Mobil Pick-Up", "Mobil Pemadam", "Mobil Sedan", "Mobil SUV", "Sepeda Motor", "Pesawat Jet", "Mobil", "Motor", "Sepeda", "Bus", "Truk", "Kereta Api", "Pesawat", "Helikopter", "Kapal Laut", "Perahu", "Taksi", "MRT", "LRT", "Feri", "Skuter", "Becak", "Ambulans", "Traktor", "Sampan"},
    ["Makanan Penutup"] = {"Puding Cokelat", "Puding Mangga", "Es Krim Vanila", "Es Krim Stroberi", "Dadar Gulung", "Puding Buah", "Tiramisu", "Brownies", "Macaron", "Kue Keju", "Es Campur", "Klepon", "Es Krim", "Puding", "Kue Cokelat", "Donat", "Wafel", "Pancake", "Kue Bolu", "Es Serut", "Kue Sus", "Pai Apel", "Kue Tart", "Mochi", "Kue Cubit", "Kue Putu"},
    ["Makhluk Laut"] = {"Anemon Laut", "Landak Laut", "Ikan Kerapu", "Kuda Laut", "Bintang Laut", "Ikan Badut", "Ikan Lele Laut", "Siput Laut", "Belut Laut", "Teripang", "Lumba-Lumba", "Gurita", "Ubur-Ubur", "Kepiting", "Lobster", "Udang", "Penyu", "Cumi-Cumi", "Ikan Paus", "Ikan Hiu", "Ikan Pari", "Kerang", "Sotong", "Dugong", "Ikan Tuna", "Ikan Salmon"},
    ["Mamalia"] = {"Orangutan", "Kuda Nil", "Kanguru", "Alpaka", "Landak", "Tupai", "Kelelawar", "Lumba-Lumba", "Jerapah", "Zebra", "Kucing", "Anjing", "Sapi", "Kuda", "Gajah", "Singa", "Harimau", "Paus", "Monyet", "Beruang", "Rusa", "Badak", "Gorila", "Kelinci", "Unta", "Kambing", "Domba", "Kerbau", "Serigala", "Rubah"},
    ["Merek"] = {"Louis Vuitton", "PlayStation", "Nintendo", "McDonald's", "Starbucks", "Uniqlo", "Gucci", "Rolex", "Nike", "Adidas", "Apple", "Samsung", "Sony", "Toyota", "Honda", "Coca-Cola", "Puma", "Canon", "LG", "Asus", "Lenovo", "Dell", "HP", "Xiaomi", "Oppo", "Vivo", "Pepsi", "KFC", "Zara", "H&M"},
    ["Merek Mobil"] = {"Aston Martin", "Rolls-Royce", "Lamborghini", "Mercedes-Benz", "Land Rover", "Volkswagen", "Chevrolet", "Mitsubishi", "Daihatsu", "Wuling", "Datsun", "Toyota", "Honda", "BMW", "Audi", "Ford", "Hyundai", "Kia", "Nissan", "Porsche", "Ferrari", "Tesla", "Mazda", "Suzuki", "Lexus", "Subaru", "Jeep", "Jaguar"},
    ["Minuman"] = {"Matcha Latte", "Es Teh Manis", "Es Kelapa Muda", "Cokelat Hangat", "Kopi Susu", "Teh Hijau", "Lemon Tea", "Cappuccino", "Teh Tarik", "Air Kelapa", "Smoothie", "Air Putih", "Teh", "Kopi", "Susu", "Jus Jeruk", "Jus Mangga", "Soda", "Jus Apel", "Jus Alpukat", "Susu Cokelat", "Susu Stroberi", "Es Jeruk", "Air Mineral", "Milkshake", "Kopi Hitam", "Jus Semangka", "Es Kopi"},
    ["Nama Anak Laki-laki"] = {"Naufal", "Satria", "Taufik", "Ardian", "Gilang", "Hakim", "Iqbal", "Rizky", "Arief", "Dimas", "Fajar", "Bagas", "Ilham", "Hafiz", "Farhan", "Danu", "Bima", "Reza", "Kevin", "Adrian", "Zaki", "Aldi", "Rafi", "Raka", "Bayu", "Yoga", "Daffa", "Fikri", "Hendra", "Rian"},
    ["Nama Anak Perempuan"] = {"Clarissa", "Jasmine", "Kirana", "Aisyah", "Nabila", "Laras", "Tasya", "Aulia", "Zahra", "Ayu", "Putri", "Siti", "Nadia", "Dina", "Rina", "Salsa", "Maya", "Citra", "Nisa", "Bella", "Dewi", "Fitri", "Hana", "Intan", "Laila", "Salma", "Anisa", "Dian", "Elsa", "Ratna"},
    ["Negara"] = {"Selandia Baru", "Amerika Serikat", "Korea Selatan", "Arab Saudi", "Argentina", "Meksiko", "Swiss", "Swedia", "Norwegia", "Yunani", "Indonesia", "Malaysia", "Jepang", "Inggris", "Prancis", "Jerman", "Brasil", "Australia", "Kanada", "India", "Thailand", "Mesir", "Singapura", "Filipina", "Vietnam", "Italia", "Spanyol", "Belanda", "Rusia", "Turki"},
    ["Olahraga"] = {"Bulu Tangkis", "Tenis Meja", "Lompat Jauh", "Lari Estafet", "Angkat Besi", "Polo Air", "Sepak Bola", "Basket", "Voli", "Tenis", "Berenang", "Lari", "Tinju", "Catur", "Biliar", "Golf", "Panahan", "Senam", "Bersepeda", "Selancar", "Ski", "Hoki", "Rugby", "Karate", "Taekwondo", "Judo", "Futsal", "Dayung", "Kano", "Bola Tangan"},
    ["Pahlawan Super dan Penjahat"] = {"Captain America", "Wonder Woman", "Green Goblin", "Scarlet Witch", "Harley Quinn", "Lex Luthor", "Black Widow", "Doctor Strange", "Spider-Man", "Batman", "Superman", "Iron Man", "Thor", "Joker", "Thanos", "Loki", "Magneto", "Hulk", "Flash", "Aquaman", "Catwoman", "Venom", "Darkseid", "Ultron", "Wolverine", "Ant-Man", "Hawkeye", "Vision", "Penguin", "Riddler"},
    ["Pekerjaan"] = {"Pemadam Kebakaran", "Fotografer", "Apoteker", "Dokter Gigi", "Akuntan", "Pengacara", "Wartawan", "Arsitek", "Insinyur", "Programmer", "Dokter", "Perawat", "Guru", "Pilot", "Koki", "Polisi", "Petani", "Nelayan", "Hakim", "Desainer", "Masinis", "Nahkoda", "Penjahit", "Tukang Kayu", "Kasir", "Satpam", "Sopir", "Pramugari", "Tentara", "Dosen"},
    ["Peralatan Olahraga"] = {"Raket Bulu Tangkis", "Shuttlecock", "Skipping Rope", "Pelindung Lutut", "Papan Seluncur", "Kacamata Renang", "Topi Renang", "Bola Pingpong", "Tongkat Golf", "Matras Yoga", "Bola Sepak", "Bola Basket", "Bola Voli", "Sarung Tinju", "Papan Catur", "Sepatu Lari", "Bola Tenis", "Raket Tenis", "Bola Kasti", "Bola Bowling", "Busur Panah", "Anak Panah", "Dumbbell", "Barbel", "Gawang", "Net Voli", "Bola Rugby", "Sepatu Roda"},
    ["Perlengkapan Sekolah"] = {"Correction Tape", "Tempat Pensil", "Pensil Warna", "Gunting Kertas", "Buku Gambar", "Isi Stapler", "Map Dokumen", "Buku Catatan", "Buku Tulis", "Pensil", "Pulpen", "Penghapus", "Penggaris", "Rautan", "Tas Sekolah", "Spidol", "Kertas HVS", "Stapler", "Stabilo", "Papan Tulis", "Kapur Tulis", "Crayon", "Lem Kertas", "Selotip", "Jangka", "Kalkulator", "Amplop", "Binder"},
    ["Permata, Batu, dan Logam"] = {"Batu Kecubung", "Batu Kapur", "Batu Apung", "Batu Pasir", "Batu Pirus", "Aluminium", "Batu Akik", "Batu Opal", "Kuningan", "Perunggu", "Berlian", "Emas", "Perak", "Tembaga", "Besi", "Platina", "Safir", "Ruby", "Zamrud", "Giok", "Marmer", "Mutiara", "Granit", "Timah", "Seng", "Nikel", "Titanium", "Baja"},
    ["Restoran Cepat Saji"] = {"Hoka Hoka Bento", "Richeese Factory", "Domino's Pizza", "Burger King", "Pizza Hut", "Texas Chicken", "Marugame Udon", "Pepper Lunch", "Carl's Jr.", "Shake Shack", "Five Guys", "McDonald's", "KFC", "Subway", "A&W", "Wendy's", "Popeyes", "Jollibee", "Taco Bell", "Wingstop", "Dairy Queen", "Hardee's", "Church's Chicken", "Panda Express", "Yoshinoya", "Solaria"},
    ["Rutinitas Pagi"] = {"Merapikan Tempat Tidur", "Regangkan Badan", "Minum Air Putih", "Berangkat Kerja", "Berangkat Sekolah", "Menyiapkan Sarapan", "Menyiapkan Tas", "Memakai Seragam", "Membaca Berita", "Bangun Tidur", "Cuci Muka", "Sikat Gigi", "Mandi", "Sarapan", "Minum Kopi", "Cek Jadwal", "Buka Jendela", "Cek HP", "Minum Teh", "Berpamitan", "Menyalakan Lampu", "Merapikan Rambut", "Memakai Sepatu", "Cek Cuaca", "Berdoa Pagi", "Pemanasan"},
    ["Senjata"] = {"Kapak Perang", "Senapan Angin", "Pedang Panjang", "Tombak Pendek", "Belati Kecil", "Pistol Mainan", "Pistol Air", "Panah Busur", "Nunchaku", "Bumerang", "Pedang", "Tombak", "Busur Panah", "Belati", "Pistol", "Senapan", "Granat", "Katana", "Tameng", "Keris", "Golok", "Parang", "Panah", "Anak Panah", "Pedang Kayu", "Kapak", "Cambuk", "Ranjau"},
    ["Serangga"] = {"Belalang Sembah", "Capung Jarum", "Kumbang Badak", "Kumbang Kotoran", "Semut Rangrang", "Semut Merah", "Semut Hitam", "Lebah Madu", "Kutu Busuk", "Ulat Bulu", "Kupu-Kupu", "Jangkrik", "Kutu Daun", "Semut", "Lebah", "Nyamuk", "Lalat", "Kecoa", "Belalang", "Capung", "Kumbang", "Ulat", "Rayap", "Tawon", "Kutu", "Ngengat", "Kepik", "Laron"},
    ["Tempat di Alam"] = {"Padang Savana", "Padang Ilalang", "Padang Rumput", "Padang Salju", "Hutan Hujan", "Hutan Bakau", "Air Terjun", "Air Terjun Kecil", "Kawah Gunung", "Gurun Pasir", "Hutan", "Gunung", "Pantai", "Sungai", "Danau", "Gurun", "Lembah", "Gua", "Pulau", "Rawa", "Bukit", "Laut", "Samudra", "Tebing", "Ngarai", "Muara", "Teluk", "Selat"},
    ["Video Game"] = {"Grand Theft Auto V", "Counter-Strike 2", "Red Dead Redemption 2", "Honkai Star Rail", "Genshin Impact", "The Witcher 3", "The Legend of Zelda", "Super Mario Bros", "Subway Surfers", "Stardew Valley", "Apex Legends", "Overwatch 2", "Cyberpunk 2077", "Clash Royale", "Minecraft", "Valorant", "Elden Ring", "Mobile Legends", "PUBG", "Fortnite", "Roblox", "Free Fire", "God of War", "Call of Duty", "EA Sports FC", "Terraria", "Among Us", "Temple Run"},
    ["Warna"] = {"Hijau Toska", "Biru Langit", "Kuning Cerah", "Abu-Abu Tua", "Putih Tulang", "Merah Muda", "Biru Muda", "Biru Tua", "Hijau Muda", "Hijau Tua", "Merah Tua", "Merah", "Biru", "Kuning", "Hijau", "Hitam", "Putih", "Oranye", "Ungu", "Cokelat", "Abu-Abu", "Emas", "Perak", "Krem", "Toska", "Magenta", "Cyan", "Violet", "Indigo", "Marun"},
    -- ["Tambah Kategori Baru Di Sini"] = {"Jawapan 1", "Jawapan 2", "Jawapan 3"},
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
