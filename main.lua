---@class ModReference
AscensionMod = RegisterMod("Ascension", 1)

---@class SaveManager
AscensionMod.SaveManager = include('save_manager')
AscensionMod.SaveManager.Init(AscensionMod)

local game = Game()


------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------- 延时触发辅助工具 ---------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


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


------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------- 复制来的中文字体 ---------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


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


------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------- 文本颜色预设 -------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


AscensionMod.TextColor = {
    ['white'] = KColor(1, 1, 1, 1),
    ['gray'] = KColor(.5, .5, .5, 1),
}


------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------- 进阶游戏内介绍文本 -------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


AscensionMod.ascensions = {
    ['0'] = '',
    ['1'] = '',
    ['2'] = '',
    ['3'] = '',
    ['4'] = '',
    ['5'] = '',
    ['6'] = '',
    ['7'] = '',
    ['8'] = '',
    ['9'] = '',
    ['10'] = '',
    ['11'] = '',
    ['12'] = '',
    ['13'] = '',
    ['14'] = '',
    ['15'] = '',
    ['16'] = '',
    ['17'] = '',
    ['18'] = '',
    ['19'] = '',
    ['20'] = '',
}


------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------- 用于辅助选项切换 ---------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


AscensionMod.NextOption = {
    ['A'] = 'B',
    ['B'] = 'C',
    ['C'] = 'D',
    ['D'] = 'A',
}

AscensionMod.PrevOption = {
    ['A'] = 'D',
    ['B'] = 'A',
    ['C'] = 'B',
    ['D'] = 'C',
}


------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------- NPC 各项设置 ------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


AscensionMod.NPCPredicates = {
    ['angel'] = function ()
        if AscensionMod:FirstStage() then
            return true
        end
        return false
    end,
    ['devil'] = function ()
        if AscensionMod:FirstStage() then
            return false
        end
        return true
    end,
}

AscensionMod.NPCDialogues = {
    ['angel'] = {
        ['至少……也要见到……第一坨大便吧……'] = function ()
            return (AscensionMod:FirstStage() and (not AscensionMod.FoundPoopLastRun))
        end,
        ['你好……'] = function ()
            return true
        end,
        ['我把你……带回来了……'] = function ()
            return AscensionMod:FirstStage()
        end
    },
    ['devil'] = {
        ['至少……也要见到……第一坨大便吧……'] = function ()
            return (AscensionMod:FirstStage() and (not AscensionMod.FoundPoopLastRun))
        end,
        ['代价……'] = function ()
            return true
        end
    }
}

AscensionMod.NPCOptions = {
    ['angel'] = {
        ['AB'] = {
            ['获得 10 便士'] = function()
                local p0 = game:GetPlayer(0)
                scheduler:seq_n(function ()
                    Isaac.Spawn(
                    EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, CoinSubType.COIN_PENNY,
                    Isaac.GetFreeNearPosition(p0.Position, 40), Vector.Zero, nil)
                end, 1, 10, true)
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
        },
        ['CD1'] = {
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
        },
        ['CD2'] = {
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
    }
}


------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------- 每层发生事件 ------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


function AscensionMod:NewRunReset()
    scheduler:clear()
    AscensionMod.ascensionLevel = AscensionMod:GetAscensionLevelFromSave()
    AscensionMod.playerStats = {
        rangeAdd = 0,
        rangeMul = 1,
    }
end

function AscensionMod:StartNewStage()
    if AscensionMod:FirstStage() then
        AscensionMod:NewRunReset()
    end

    AscensionMod.NPCID = AscensionMod:GetNPC()

    AscensionMod.Dialogue = AscensionMod:GetDialogue(AscensionMod.NPCID)

    AscensionMod.Options = {} -- A, B, C1-C2, D1-D2
    AscensionMod:SetOptions(AscensionMod.NPCID)

    AscensionMod.ConfirmedOption = false
    AscensionMod.SelectedOption = 'A'

    AscensionMod:SpawnAngelStatue()

    AscensionMod:DisablePlayerControls()
    AscensionMod:HidePlayer()
end
AscensionMod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, AscensionMod.StartNewStage)


------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------- 选择 NPC 和 对话 ---------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


---@return string NPCID id of the chosen npc
function AscensionMod:GetNPC()
    local legitNPCIDList = AscensionMod:GetLegitNPCs()
    return legitNPCIDList[math.random(#legitNPCIDList)]
end

function AscensionMod:GetLegitNPCs()
    local legitNPCIDList = {}
    for id, predicateFn in pairs(AscensionMod.NPCPredicates) do
        if predicateFn() then
            table.insert(legitNPCIDList, id)
        end
    end
    return legitNPCIDList;
end

---@param NPCID string The NPC you wish to pick a dialogue from
---@return string dialogue A random legit dialogue from NPC
function AscensionMod:GetDialogue(NPCID)
    local dialoguePredicates = AscensionMod.NPCDialogues[NPCID]
    if dialoguePredicates == nil then
        print('Error: Unknown NPC: '..tostring(NPCID))
        return 'Error'
    end

    local legitDialogueList = {}
    for dialogue, predicate in pairs(dialoguePredicates) do
        if predicate() then
            table.insert(legitDialogueList, dialogue)
        end
    end

    AscensionMod.FoundPoopLastRun = false

    return legitDialogueList[math.random(#legitDialogueList)]
end


------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------- 生成 NPC "雕像" ---------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


function AscensionMod:SpawnAngelStatue()
    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ANGEL, 0, Vector(320, 200), Vector.Zero, nil)
end

function AscensionMod:RemoveAngelStatue()
    local entities = Isaac.GetRoomEntities()
    for _, entity in ipairs(entities) do
        if entity.Type == EntityType.ENTITY_EFFECT and entity.Variant == EffectVariant.ANGEL then
            entity:Remove()
        end
    end
end


------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------- 抽取 / 显示进层选项 ------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


---@param NPCID string The ID of the NPC you wish to choose options from
function AscensionMod:SetOptions(NPCID)
    if NPCID == nil then print('Error: NPC ID is nil while trying to set options.') return end

    local optionsAB = AscensionMod.NPCOptions[NPCID]['AB']
    if optionsAB == nil then
        print('Error: No AB options found for NPC ID: '..tostring(NPCID))
        return
    end
    local optionsABCnt = AscensionMod:GetTableSize(optionsAB)
    local optionA = math.random(optionsABCnt)
    local optionB = math.random(optionsABCnt - 1)
    if optionB >= optionA then
        optionB = optionB + 1
    end
    local i = 0
    for desc, _ in pairs(optionsAB) do
        i = i + 1
        if i == optionA then AscensionMod.Options['A'] = desc end
        if i == optionB then AscensionMod.Options['B'] = desc end
    end

    local optionsCD1 = AscensionMod.NPCOptions[NPCID]['CD1']
    if optionsCD1 == nil then
        print('Error: No CD1 options found for NPC ID: '..tostring(NPCID))
        return
    end
    local optionsCD1Cnt = AscensionMod:GetTableSize(optionsCD1)
    local optionC1 = math.random(optionsCD1Cnt)
    local optionD1 = math.random(optionsCD1Cnt - 1)
    if optionD1 >= optionC1 then
        optionD1 = optionD1 + 1
    end
    i = 0
    for desc, _ in pairs(optionsCD1) do
        i = i + 1
        if i == optionC1 then AscensionMod.Options['C1'] = desc end
        if i == optionD1 then AscensionMod.Options['D1'] = desc end
    end

    local optionsCD2 = AscensionMod.NPCOptions[NPCID]['CD2']
    if optionsCD2 == nil then
        print('Error: No CD2 options found for NPC ID: '..tostring(NPCID))
        return
    end
    local optionsCD2Cnt = AscensionMod:GetTableSize(optionsCD2)
    local optionC2 = math.random(optionsCD2Cnt)
    local optionD2 = math.random(optionsCD2Cnt - 1)
    if optionD2 >= optionC2 then
        optionD2 = optionD2 + 1
    end
    i = 0
    for desc, _ in pairs(optionsCD2) do
        i = i + 1
        if i == optionC2 then AscensionMod.Options['C2'] = desc end
        if i == optionD2 then AscensionMod.Options['D2'] = desc end
    end
end

function AscensionMod:RenderStartingOptions()
    if AscensionMod.ConfirmedOption then
        return
    end

    local ascensionLevelDisplay = tostring(AscensionMod.ascensionLevel)
    if ascensionLevelDisplay == 'nil' then
        ascensionLevelDisplay = '0'
    end

    local pos = Isaac.WorldToScreen(Vector(320, 220))
    local x = pos.X
    local y = pos.Y
    local text = AscensionMod.StartingDialogue
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
    text = AscensionMod.ascensions[ascensionLevelDisplay]
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
    text = AscensionMod.Options['A']
    length = font:GetStringWidth(text)
    scale = 1
    if AscensionMod.SelectedOption == 'A' then
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
    text = AscensionMod.Options['B']
    length = font:GetStringWidth(text)
    scale = 1
    if AscensionMod.SelectedOption == 'B' then
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
    text = AscensionMod.Options['C1']..' 但是 '..AscensionMod.Options['C2']
    length = font:GetStringWidth(text)
    scale = 1
    if AscensionMod.SelectedOption == 'C' then
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
    text = AscensionMod.Options['D1']..' 但是 '..AscensionMod.Options['D2']
    length = font:GetStringWidth(text)
    scale = 1
    if AscensionMod.SelectedOption == 'D' then
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


------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------- 切换 / 确认选项 ----------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


local actionDownReleased = true
local actionUpReleased = true
local actionConfirmReleased = true
---@param entity Entity
function AscensionMod:SwitchSeletedOption(entity, _, _)
    if AscensionMod.ConfirmedOption then
        return
    end
    if entity == nil or entity.Type ~= EntityType.ENTITY_PLAYER then
        return
    end
    if Input.IsActionPressed(ButtonAction.ACTION_MENUDOWN, 0) then
        if actionDownReleased then
            actionDownReleased = false
            AscensionMod.SelectedOption = AscensionMod.NextOption[AscensionMod.SelectedOption]
        end
    else
        actionDownReleased = true
    end

    if Input.IsActionPressed(ButtonAction.ACTION_MENUUP, 0) then
        if actionUpReleased then
            actionUpReleased = false
            AscensionMod.SelectedOption = AscensionMod.PrevOption[AscensionMod.SelectedOption]
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
AscensionMod:AddCallback(ModCallbacks.MC_INPUT_ACTION, AscensionMod.SwitchSeletedOption)

function AscensionMod:ConfirmSeletedStartingOption()
    if AscensionMod.ConfirmedOption then
        return
    end

    for i = 0, game:GetNumPlayers() - 1 do
        game:GetPlayer(i):AnimateHappy()
    end

    AscensionMod.ConfirmedOption = true
    local option = AscensionMod.SelectedOption;
    if option == 'A' or option == 'B' then
        local eventFn = startingOptionAB[AscensionMod.Options[option]]
        if eventFn ~= nil then
            eventFn()
        end
    else -- C or D
        local eventFn = startingOptionCDAdvantage[AscensionMod.Options[tostring(option)..'1']]
        if eventFn ~= nil then
            eventFn()
        end
        eventFn = startingOptionCDDisadvantage[AscensionMod.Options[tostring(option)..'2']]
        if eventFn ~= nil then
            eventFn()
        end
    end

    AscensionMod:ShowPlayer()
    AscensionMod:RemoveAngelStatue()

    scheduler:once(function ()
        AscensionMod:EnablePlayerControls()
    end, 1)
end


------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------- 控制玩家属性 ----------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


---@param player EntityPlayer
---@param cacheFlag CacheFlag
function AscensionMod:OnEvaluateCache(player, cacheFlag)
    local stats = AscensionMod.playerStats;
    if stats == nil then
        return
    end
    if cacheFlag == CacheFlag.CACHE_RANGE then
        player.TearRange = (player.TearRange + stats.rangeAdd * 40) * stats.rangeMul;
    end
end
AscensionMod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, AscensionMod.OnEvaluateCache)


------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------- 杂项 --------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


function AscensionMod:End(isLose)
    if not isLose then
        if AscensionMod.ascensionLevel < AscensionMod:GetMaxAscensionLevel() then
            AscensionMod.ascensionLevel = AscensionMod.ascensionLevel + 1
        end
        AscensionMod:SaveAscensionLevel(AscensionMod.ascensionLevel)
    end
end
AscensionMod:AddCallback(ModCallbacks.MC_POST_GAME_END, AscensionMod.End)

function AscensionMod:GetMaxAscensionLevel() -- starts from 0
    return AscensionMod:GetTableSize(AscensionMod.ascensions)
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

function AscensionMod:FirstStage()
    -- aka. basement 1 / cellar 1 / burning basement 1
    local level = game:GetLevel()
    local stage = level:GetStage()
    if stage == 1 and (not level:IsAltStage()) then
        return true
    end
    return false
end

---@param t table
function AscensionMod:GetTableSize(t)
    local s = 0
    for _, _ in pairs(t) do
        s = s + 1
    end
    return s
end


------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------- 至少……也要见到……第一坨大便吧…… --------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


AscensionMod.FoundPoopLastRun = false -- 用于开局对话
function AscensionMod:LookForPoop(entityType, _, _, gridIndex, _)
    if AscensionMod.FoundPoopLastRun then
        return
    end
    if entityType >= 1000 then -- 1000+ is grid entity because of reasons
        local room = game:GetRoom()
        scheduler:once(function()
            local gridEntity = room:GetGridEntityFromPos(room:GetGridPosition(gridIndex))
            if gridEntity ~= nil then
                if gridEntity:GetType() == GridEntityType.GRID_POOP then
                    AscensionMod.FoundPoopLastRun = true
                end
            end
        end, 1)
    end
end
AscensionMod:AddCallback(ModCallbacks.MC_PRE_ROOM_ENTITY_SPAWN, AscensionMod.LookForPoop)