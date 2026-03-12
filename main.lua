---@class ModReference
AscensionMod = RegisterMod("Ascension", 1)

---@class SaveManager
AscensionMod.SaveManager = include('save_manager')
AscensionMod.SaveManager.Init(AscensionMod)

local scheduler = {
    init = function (self)
        AscensionMod:AddCallback(ModCallbacks.MC_POST_UPDATE, function ()
            self:_on_update()
        end)
    end,
    clear = function (self)
        self._todo = {}
    end,
    once = function (self, fn, delay)
        if delay == 0 then
            fn()
            return
        end
        self:_add_todo(fn, self._t + delay)
    end,
    seq_n = function (self, fn, delay, n, immediate)
        if n <= 0 then
            return
        end
        local cnt = 0
        if (immediate) then
            fn()
            cnt = cnt + 1
        end
        local function next()
            self:once(function()
                fn()
                cnt = cnt + 1
                if cnt < n then
                    next()
                end
            end, delay)
        end
        if cnt < n then
            next()
        end
    end,
    seq_if = function (self, fn, delay, predicate, immediate)
        if immediate then
            if predicate() then
                fn()
            end
        end
        local function next()
            self:once(function()
                fn()
                if predicate() then
                    next()
                end
            end, delay)
        end
        if predicate() then
            next()
        end
    end,

    _t = 0,
    _todo = {},
    _add_todo = function (self, fn, t)
        if self._todo[t] == nil then
            self._todo[t] = {}
        end
        table.insert(self._todo[t], fn)
    end,
    _on_update = function (self)
        self._t = self._t + 1
        if self._todo[self._t] ~= nil then
            for _, fn in ipairs(self._todo[self._t]) do
                fn()
            end
            self._todo[self._t] = nil
        end
    end
}
scheduler:init()

local font = Font()
function AscensionMod:LoadFont()
    local _, err = pcall(require, "")
    local _, basePathStart = string.find(err, "no file '", 1)
    local _, modPathStart = string.find(err, "no file '", basePathStart)
    local modPathEnd, _ = string.find(err, "mods", modPathStart)
    local path = string.sub(err, modPathStart + 1, modPathEnd - 1)
    path = string.gsub(path, "\\", "/")
    path = string.gsub(path, "//", "/")
    path = string.gsub(path, ":/", ":\\")
    font:Load(path .. 'mods/Ascension/resources/font/eid9/eid9_9px.fnt')
end
AscensionMod:LoadFont()

AscensionMod.TextColor = {
    ['white'] = KColor(1, 1, 1, 1),
    ['gray'] = KColor(.5, .5, .5, 1),
}

local game = Game()

local ascensionDesc = {
    ['0'] = '对原版的平衡性调整',
}


function AscensionMod:Start(isContinued)
    if isContinued and AscensionMod.ConfirmedStartingOption then
        return
    end
    scheduler:clear()

    AscensionMod.playerStats = {
        rangeAdd = 0,
        rangeMul = 1,
    }
    local p0 = game:GetPlayer(0)
    p0:AddCacheFlags(CacheFlag.CACHE_ALL, true)

    AscensionMod:SpawnStartingAngelStatue()

    AscensionMod:DisablePlayerControls()
    AscensionMod:HidePlayer()

    AscensionMod.ascensionLevel = AscensionMod:GetAscensionLevelFromSave()

    AscensionMod.StartingOptions = {['A'] = '', ['B'] = '', ['C1'] = '', ['C2'] = '', ['D1'] = '', ['D2'] = ''}
    AscensionMod:GetStartingOptions()
    AscensionMod.SelectedStartingOption = 'A'
    AscensionMod.ConfirmedStartingOption = false
end
AscensionMod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, AscensionMod.Start)


AscensionMod.ConfirmedStartingOption = false
AscensionMod.SelectedStartingOption = 'A'
AscensionMod.NextStartingOption = {
    ['A'] = 'B',
    ['B'] = 'C',
    ['C'] = 'D',
    ['D'] = 'A',
}
AscensionMod.PrevStartingOption = {
    ['A'] = 'D',
    ['B'] = 'A',
    ['C'] = 'B',
    ['D'] = 'C',
}
AscensionMod.StartingOptions = {['A'] = '', ['B'] = '', ['C1'] = '', ['C2'] = '', ['D1'] = '', ['D2'] = ''}
function AscensionMod:RenderStartingOptions()
    if AscensionMod.ConfirmedStartingOption then
        return
    end

    local ascensionLevelDisplay = tostring(AscensionMod.ascensionLevel)
    if ascensionLevelDisplay == 'nil' then
        ascensionLevelDisplay = '0'
    end

    local pos = Isaac.WorldToScreen(Vector(320, 220))
    local x = pos.X
    local y = pos.Y
    local text = "至少……也要见到……第一坨大便吧……"
    local length = font:GetStringWidth(text)
    local scale = 1.7
    local color = AscensionMod.TextColor['white']
    font:DrawStringScaled(text,
        x - length * scale / 2, y,
        scale, scale,
        color)

    pos = Isaac.WorldToScreen(Vector(80, 360))
    x = pos.X
    y = pos.Y
    text = "进阶: "..ascensionLevelDisplay
    length = font:GetStringWidth(text)
    scale = 1
    color = AscensionMod.TextColor['white']
    font:DrawStringScaled(text,
        x, y,
        scale, scale,
        color)

    pos = Isaac.WorldToScreen(Vector(80, 380))
    x = pos.X
    y = pos.Y
    text = ascensionDesc[ascensionLevelDisplay]
    length = font:GetStringWidth(text)
    scale = 1
    color = AscensionMod.TextColor['white']
    font:DrawStringScaled(text,
        x, y,
        scale, scale,
        color)

    pos = Isaac.WorldToScreen(Vector(320, 260))
    x = pos.X
    y = pos.Y
    text = AscensionMod.StartingOptions['A']
    length = font:GetStringWidth(text)
    scale = 1
    if AscensionMod.SelectedStartingOption == 'A' then
        color = AscensionMod.TextColor['gray']
    else
        color = AscensionMod.TextColor['white']
    end
    font:DrawStringScaled(text,
        x - length * scale / 2, y,
        scale, scale,
        color)

    pos = Isaac.WorldToScreen(Vector(320, 280))
    x = pos.X
    y = pos.Y
    text = AscensionMod.StartingOptions['B']
    length = font:GetStringWidth(text)
    scale = 1
    if AscensionMod.SelectedStartingOption == 'B' then
        color = AscensionMod.TextColor['gray']
    else
        color = AscensionMod.TextColor['white']
    end
    font:DrawStringScaled(text,
        x - length * scale / 2, y,
        scale, scale,
        color)

    pos = Isaac.WorldToScreen(Vector(320, 300))
    x = pos.X
    y = pos.Y
    text = AscensionMod.StartingOptions['C1']..' 但是 '..AscensionMod.StartingOptions['C2']
    length = font:GetStringWidth(text)
    scale = 1
    if AscensionMod.SelectedStartingOption == 'C' then
        color = AscensionMod.TextColor['gray']
    else
        color = AscensionMod.TextColor['white']
    end
    font:DrawStringScaled(text,
        x - length * scale / 2, y,
        scale, scale,
        color)

    pos = Isaac.WorldToScreen(Vector(320, 320))
    x = pos.X
    y = pos.Y
    text = AscensionMod.StartingOptions['D1']..' 但是 '..AscensionMod.StartingOptions['D2']
    length = font:GetStringWidth(text)
    scale = 1
    if AscensionMod.SelectedStartingOption == 'D' then
        color = AscensionMod.TextColor['gray']
    else
        color = AscensionMod.TextColor['white']
    end
    font:DrawStringScaled(text,
        x - length * scale / 2, y,
        scale, scale,
        color)
end
AscensionMod:AddCallback(ModCallbacks.MC_POST_RENDER, AscensionMod.RenderStartingOptions)


local actionDownReleased = true
local actionUpReleased = true
local actionConfirmReleased = true
---@param entity Entity
function AscensionMod:SwitchSeletedStartingOption(entity, _, _)
    if AscensionMod.ConfirmedStartingOption then
        return
    end
    if entity == nil or entity.Type ~= EntityType.ENTITY_PLAYER then
        return
    end
    if Input.IsActionPressed(ButtonAction.ACTION_MENUDOWN, 0) then
        if actionDownReleased then
            actionDownReleased = false
            AscensionMod.SelectedStartingOption = AscensionMod.NextStartingOption[AscensionMod.SelectedStartingOption]
        end
    else
        actionDownReleased = true
    end

    if Input.IsActionPressed(ButtonAction.ACTION_MENUUP, 0) then
        if actionUpReleased then
            actionUpReleased = false
            AscensionMod.SelectedStartingOption = AscensionMod.PrevStartingOption[AscensionMod.SelectedStartingOption]
        end
    else
        actionUpReleased = true
    end

    if Input.IsActionPressed(ButtonAction.ACTION_MENUCONFIRM, 0) then
        if actionConfirmReleased then
            actionConfirmReleased = false
            AscensionMod:ConfirmSeletedStartingOption()
        end
    else
        actionConfirmReleased = true
    end
end
AscensionMod:AddCallback(ModCallbacks.MC_INPUT_ACTION, AscensionMod.SwitchSeletedStartingOption)

local startingOptionAB = {
    ['获得 15 便士'] = function()
        local p0 = game:GetPlayer(0)
        scheduler:seq_n(function ()
            Isaac.Spawn(
            EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, CoinSubType.COIN_PENNY,
            Isaac.GetFreeNearPosition(p0.Position, 40), Vector.Zero, nil)
        end, 1, 15, true)
    end,
    ['获得 5 随机炸弹'] = function()
        local p0 = game:GetPlayer(0)
        scheduler:seq_n(function ()
            Isaac.Spawn(
            EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, 0,
            Isaac.GetFreeNearPosition(p0.Position, 40), Vector.Zero, nil)
        end, 1, 5, true)
    end,
    ['获得 2 钥匙圈'] = function()
        local p0 = game:GetPlayer(0)
        scheduler:seq_n(function ()
            Isaac.Spawn(
            EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, KeySubType.KEY_DOUBLEPACK,
            Isaac.GetFreeNearPosition(p0.Position, 40), Vector.Zero, nil)
        end, 1, 2, true)
    end,
    ['获得 2 点射程'] = function()
        local p0 = game:GetPlayer(0)
        AscensionMod.playerStats.rangeAdd = AscensionMod.playerStats.rangeAdd + 2
        p0:AddCacheFlags(CacheFlag.CACHE_RANGE, true)
    end,
}
local startingOptionCDAdvantage = {
    ['获得 20 随机硬币'] = function()
        local p0 = game:GetPlayer(0)
        scheduler:seq_n(function ()
            Isaac.Spawn(
            EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, 0,
            Isaac.GetFreeNearPosition(p0.Position, 40), Vector.Zero, nil)
        end, 1, 20, true)
    end,
    ['获得 10 随机炸弹'] = function()
        local p0 = game:GetPlayer(0)
        scheduler:seq_n(function ()
            Isaac.Spawn(
            EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, 0,
            Isaac.GetFreeNearPosition(p0.Position, 40), Vector.Zero, nil)
        end, 1, 10, true)
    end,
    ['获得 5 随机钥匙'] = function()
        local p0 = game:GetPlayer(0)
        scheduler:seq_n(function ()
            Isaac.Spawn(
            EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, 0,
            Isaac.GetFreeNearPosition(p0.Position, 40), Vector.Zero, nil)
        end, 1, 5, true)
    end,
}
local startingOptionCDDisadvantage = {
    ['失去 2 点幸运'] = function()
        local p0 = game:GetPlayer(0)
        p0:DonateLuck(-2)
    end,
    ['失去 一颗心 最大生命'] = function()
        local p0 = game:GetPlayer(0)
        p0:AddMaxHearts(-2, false)
    end,
    ['获得 一颗碎心'] = function()
        local p0 = game:GetPlayer(0)
        p0:AddBrokenHearts(1)
    end,
    ['元素反应'] = function()
        local p0 = game:GetPlayer(0)
        p0:UsePoopSpell(PoopSpellType.SPELL_BURNING)
        scheduler:once(function ()
            p0:UsePoopSpell(PoopSpellType.SPELL_FART)
        end, 1)
    end,
    ['射程倍率 变为 35%'] = function()
        local p0 = game:GetPlayer(0)
        AscensionMod.playerStats.rangeMul = AscensionMod.playerStats.rangeMul * 0.35
        p0:AddCacheFlags(CacheFlag.CACHE_RANGE, true)
    end,
}


function AscensionMod:ConfirmSeletedStartingOption()
    if AscensionMod.ConfirmedStartingOption then
        return
    end

    game:GetPlayer(0):AnimateHappy()

    AscensionMod.ConfirmedStartingOption = true
    local option = AscensionMod.SelectedStartingOption;
    if option == 'A' or option == 'B' then
        local eventFn = startingOptionAB[AscensionMod.StartingOptions[option]]
        if eventFn ~= nil then
            eventFn()
        end
    else -- C or D
        local eventFn = startingOptionCDAdvantage[AscensionMod.StartingOptions[tostring(option)..'1']]
        if eventFn ~= nil then
            eventFn()
        end
        eventFn = startingOptionCDDisadvantage[AscensionMod.StartingOptions[tostring(option)..'2']]
        if eventFn ~= nil then
            eventFn()
        end
    end

    AscensionMod:ShowPlayer()
    AscensionMod:EnablePlayerControls()
    AscensionMod:RemoveStartingAngelStatue()
end


function AscensionMod:GetStartingOptions()
    local optionABSize = 0
    for _, _ in pairs(startingOptionAB) do
        optionABSize = optionABSize + 1
    end
    local optionA = math.random(optionABSize)
    local optionB = math.random(optionABSize - 1)
    local i = 0
    local j = 0
    for desc, _ in pairs(startingOptionAB) do
        i = i + 1
        j = j + 1
        if i == optionA and AscensionMod.StartingOptions.A == '' then
            AscensionMod.StartingOptions.A = desc
            j = j - 1
        end
        if j == optionB and AscensionMod.StartingOptions.B == ''  then
            AscensionMod.StartingOptions.B = desc
        end
    end

    local optionCDAdvantageSize = 0
    for _, _ in pairs(startingOptionCDAdvantage) do
        optionCDAdvantageSize = optionCDAdvantageSize + 1
    end
    local optionC1 = math.random(optionCDAdvantageSize)
    local optionD1 = math.random(optionCDAdvantageSize - 1)
    i = 0
    j = 0
    for desc, _ in pairs(startingOptionCDAdvantage) do
        i = i + 1
        j = j + 1
        if i == optionC1 and AscensionMod.StartingOptions['C1'] == '' then
            AscensionMod.StartingOptions['C1'] = desc
            j = j - 1
        end
        if j == optionD1 and AscensionMod.StartingOptions['D1'] == ''  then
            AscensionMod.StartingOptions['D1'] = desc
        end
    end

    local optionCDDisadvantageSize = 0
    for _, _ in pairs(startingOptionCDDisadvantage) do
        optionCDDisadvantageSize = optionCDDisadvantageSize + 1
    end
    local optionC2 = math.random(optionCDDisadvantageSize)
    local optionD2 = math.random(optionCDDisadvantageSize - 1)
    i = 0
    j = 0
    for desc, _ in pairs(startingOptionCDDisadvantage) do
        i = i + 1
        j = j + 1
        if i == optionC2 and AscensionMod.StartingOptions['C2'] == '' then
            AscensionMod.StartingOptions['C2'] = desc
            j = j - 1
        end
        if j == optionD2 and AscensionMod.StartingOptions['D2'] == ''  then
            AscensionMod.StartingOptions['D2'] = desc
        end
    end
end


---@param player EntityPlayer
---@param cacheFlag CacheFlag
function AscensionMod:OnEvaluateCache(player, cacheFlag)
    local stats = AscensionMod.playerStats;
    if stats == nil then
        return
    end
    if cacheFlag == CacheFlag.CACHE_RANGE then
        print(player.TearRange, stats.rangeAdd, stats.rangeMul)
        player.TearRange = (player.TearRange + stats.rangeAdd * 40) * stats.rangeMul;
    end
end
AscensionMod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, AscensionMod.OnEvaluateCache)


function AscensionMod:End(isLose)
    if not isLose then
        AscensionMod.ascensionLevel = AscensionMod.ascensionLevel + 1
        AscensionMod:SaveAscensionLevel(AscensionMod.ascensionLevel)
    end
end
AscensionMod:AddCallback(ModCallbacks.MC_POST_GAME_END, AscensionMod.End)


function AscensionMod:SpawnStartingAngelStatue()
    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ANGEL, 0, Vector(320, 200), Vector.Zero, nil)
end

function AscensionMod:RemoveStartingAngelStatue()
    local entities = Isaac.GetRoomEntities()
    for _, entity in ipairs(entities) do
        if entity.Type == EntityType.ENTITY_EFFECT and entity.Variant == EffectVariant.ANGEL then
            entity:Remove()
        end
    end
end

function AscensionMod:GetAscensionLevelFromSave()
    local save = AscensionMod.SaveManager.GetPersistentSave()
    if save == nil then save = {} end
    if save.ascensionLevel == nil then
        save.ascensionLevel = 0
    end
    return save.ascensionLevel
end

function AscensionMod:SaveAscensionLevel(level)
    local save = AscensionMod.SaveManager.GetPersistentSave()
    if save == nil then save = {} end
    if save.ascensionLevel == nil then
        save.ascensionLevel = 0
    end
    save.ascensionLevel = level
end

function AscensionMod:HidePlayer()
    for i = 0, game:GetNumPlayers() do
        local player = game:GetPlayer(i)
        player.Visible = false
    end
end

function AscensionMod:ShowPlayer()
    for i = 0, game:GetNumPlayers() do
        local player = game:GetPlayer(i)
        player.Visible = true
    end
end

function AscensionMod:DisablePlayerControls()
    for i = 0, game:GetNumPlayers() do
        local player = game:GetPlayer(i)
        player.ControlsCooldown = 999999999
    end
end

function AscensionMod:EnablePlayerControls()
    for i = 0, game:GetNumPlayers() do
        local player = game:GetPlayer(i)
        player.ControlsCooldown = 0
    end
end
