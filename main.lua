---@class ModReference
AscensionMod = RegisterMod("Ascension", 1)

---@class SaveManager
AscensionMod.SaveManager = include('save_manager')
AscensionMod.SaveManager.Init(AscensionMod)

local game = Game()

local SHIFT_INDEX = 35
local seeds
local startSeed
local rng


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
    ['light_gray'] = KColor(.7, .7, .7, 1),
}


------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------- 进阶游戏内介绍文本 -------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


AscensionMod.ascensions = {
    ['0'] = '深渊 - BOSS 血量增长 25%；每下一层，所有敌人血量增长6%',
    ['1'] = '精英小怪更多',
    ['2'] = '地面随机生成蜘蛛网',
    ['3'] = '所有魂心和红心变为半颗，双倍基础掉落物变为单倍，金色基础在3次使用后消耗',
    ['4'] = '红心角色初始变为一颗红心血量（不改变血量上限）魂心角色失去一颗魂心',
    ['5'] = '所有角色初始射程，移速，射速，伤害，按原有值下降一定数量 游魂免疫该移速下降',
    ['6'] = '商店更贵',
    ['7'] = '初始携带四颗碎心 店主改为-4幸运 lost额外获得-4幸运',
    ['8'] = '覆盖进阶0 每下一层 敌人血量增长',
    ['9'] = '初始主动道具充能归0，每进入一个新房间10%概率失去一点充能',
    ['10'] = '最大炸弹数变为30，最大钥匙数变为10',
    ['11'] = '每层 50% 再获得一个新的随机诅咒',
    ['12'] = '初始携带七颗碎心 店主改为-7幸运 lost额外获得-7幸运 覆盖进阶7效果',
    ['13'] = '敌人获得60%炸弹抗性',
    ['14'] = '进入新的特殊房间（除boss房）后受到一次半颗心伤害',
    ['15'] = '最大钱数变为35，深口袋最大钱数变为99',
    ['16'] = '4级道具85%概率重选，3级道具70%概率重选',
    ['17'] = '最大钥匙数变为3，最大炸弹数变为20',
    ['18'] = '死亡证明变为内在孩童',
    ['19'] = '飞行失效 飞行道具拾取时生成一张倒吊人 倒吊人飞行有效',
    ['20'] = '每3分钟受到一次半颗心伤害',
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

AscensionMod.NextControledField = {
    ['option'] = 'ascension',
    ['ascension'] = 'option'
}

AscensionMod.PrevControledField = {
    ['option'] = 'ascension',
    ['ascension'] = 'option'
}


------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------- NPC 各项设置 ------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


AscensionMod.NPCPredicates = {
    ['angel'] = function ()
        -- 第一层必出 二三章可出 大教堂可出
        if AscensionMod:FirstStage() then
            return true
        else
            local level = game:GetLevel()
            local stage = level:GetStage()
            if stage == LevelStage.STAGE2_1 or stage == LevelStage.STAGE2_2 or
                stage == LevelStage.STAGE3_1 or stage == LevelStage.STAGE3_2 or
                (stage == LevelStage.STAGE5 and level:GetStageType() == StageType.STAGETYPE_WOTL) then -- cathedral
                return true
            end
        end
        return false
    end,
    ['devil'] = function ()
        -- 除了第一层和大教堂都可出
        if AscensionMod:FirstStage() then
            return false
        end
        local level = game:GetLevel()
        local stage = level:GetStage()
        if (stage == LevelStage.STAGE5 and level:GetStageType() == StageType.STAGETYPE_WOTL) then
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
        end,
        ['重铸……天使荣耀……'] = function ()
            return true
        end,
        ['……诱惑……拒绝……'] = function ()
            return true
        end,
        ['我……等着……'] = function ()
            return true
        end,
    },
    ['devil'] = {
        ['代价……'] = function ()
            return true
        end,
        ['这样……才对……'] = function ()
            return true
        end,
        ['……做何……交易……'] = function ()
            return true
        end,
        ['力量……'] = function ()
            return true
        end,
    }
}

AscensionMod.NPCStatues = {
    ['angel'] = { -- [1] for spawn, [2] for remove
        function (yOffset)
            AscensionMod.NPCStatue = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ANGEL, 0, Vector(320, 200 + yOffset), Vector.Zero, nil)
        end,
        function()
            AscensionMod.NPCStatue:Remove()
        end,
    },
    ['devil'] = {
        function (yOffset)
            AscensionMod.NPCStatue = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.DEVIL, 0, Vector(320, 200 + yOffset), Vector.Zero, nil)
        end,
        function()
            AscensionMod.NPCStatue:Remove()
        end
    }
}

AscensionMod.NPCOptionPredicates = {
    ['angel'] = {
        ['AB'] = {
            ['失去 一颗 碎心'] = function ()
                local p0 = game:GetPlayer(0)
                return (p0:GetBrokenHearts() >= 1)
            end
        }
    }
}

AscensionMod.NPCOptions = {
    ['angel'] = {
        ['AB'] = {
            ['获得 2 钥匙圈'] = function()
                local p0 = game:GetPlayer(0)
                scheduler:seq_n(function ()
                    Isaac.Spawn(
                    EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, KeySubType.KEY_DOUBLEPACK,
                    Isaac.GetFreeNearPosition(p0.Position, 40), Vector.Zero, nil)
                end, 1, 2, true)
            end,
            ['获得 0.08 移速'] = function ()
                local p0 = game:GetPlayer(0)
                AscensionMod.playerStats.speedAdd = AscensionMod.playerStats.speedAdd + 0.08
                p0:AddCacheFlags(CacheFlag.CACHE_SPEED, true)
            end,
            ['获得 3 射程'] = function ()
                local p0 = game:GetPlayer(0)
                AscensionMod.playerStats.rangeAdd = AscensionMod.playerStats.rangeAdd + 3
                p0:AddCacheFlags(CacheFlag.CACHE_SPEED, true)
            end,
            ['获得 1.5 幸运'] = function ()
                local p0 = game:GetPlayer(0)
                AscensionMod.playerStats.luckAdd = AscensionMod.playerStats.luckAdd + 1.5
                p0:AddCacheFlags(CacheFlag.CACHE_LUCK, true)
            end,
            ['获得 一颗 魂心'] = function ()
                local p0 = game:GetPlayer(0)
                p0:AddSoulHearts(2)
            end,
        },
        ['CD1'] = {
            ['获得 钥匙 全家福'] = function()
                local p0 = game:GetPlayer(0)
                scheduler:once(function ()
                    Isaac.Spawn(
                    EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, KeySubType.KEY_NORMAL,
                    Isaac.GetFreeNearPosition(p0.Position, 40), Vector.Zero, nil)
                end, 1)
                scheduler:once(function ()
                    Isaac.Spawn(
                    EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, KeySubType.KEY_CHARGED,
                    Isaac.GetFreeNearPosition(p0.Position, 40), Vector.Zero, nil)
                end, 2)
                scheduler:once(function ()
                    Isaac.Spawn(
                    EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, KeySubType.KEY_DOUBLEPACK,
                    Isaac.GetFreeNearPosition(p0.Position, 40), Vector.Zero, nil)
                end, 3)
                scheduler:once(function ()
                    Isaac.Spawn(
                    EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, KeySubType.KEY_GOLDEN,
                    Isaac.GetFreeNearPosition(p0.Position, 40), Vector.Zero, nil)
                end, 4)
            end,
            ['获得 4 金钥匙'] = function()
                local p0 = game:GetPlayer(0)
                scheduler:seq_n(function ()
                    Isaac.Spawn(
                    EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, KeySubType.KEY_GOLDEN,
                    Isaac.GetFreeNearPosition(p0.Position, 40), Vector.Zero, nil)
                end, 1, 4, true)
            end,
            ['获得 3 幸运'] = function ()
                local p0 = game:GetPlayer(0)
                AscensionMod.playerStats.luckAdd = AscensionMod.playerStats.luckAdd + 3
                p0:AddCacheFlags(CacheFlag.CACHE_LUCK, true)
            end,
            ['获得 0.15 移速'] = function ()
                local p0 = game:GetPlayer(0)
                AscensionMod.playerStats.speedAdd = AscensionMod.playerStats.speedAdd + 0.15
                p0:AddCacheFlags(CacheFlag.CACHE_SPEED, true)
            end,
            ['失去 1 颗碎心'] = function ()
                local p0 = game:GetPlayer(0)
                p0:AddBrokenHearts(-1)
            end
        },
        ['CD2'] = {
            ['虚弱'] = function()
                local p0 = game:GetPlayer(0)
                AscensionMod.playerStats.dmgAdd = AscensionMod.playerStats.dmgAdd - 0.4
                p0:AddCacheFlags(CacheFlag.CACHE_DAMAGE, true)
                AscensionMod.playerStats.tearsAdd = AscensionMod.playerStats.tearsAdd - 0.2
                p0:AddCacheFlags(CacheFlag.CACHE_FIREDELAY, true)
            end,
            ['萎靡'] = function()
                local p0 = game:GetPlayer(0)
                AscensionMod.playerStats.dmgAdd = AscensionMod.playerStats.dmgAdd - 0.7
                p0:AddCacheFlags(CacheFlag.CACHE_DAMAGE, true)
            end,
        }
    },
    ['devil'] = {
        ['AB'] = {
        },
        ['CD1'] = {
        },
        ['CD2'] = {
        }
    },
    ['placeholder'] = {
        ['AB'] = {
            ['获得 10 便士'] = function()
                local p0 = game:GetPlayer(0)
                scheduler:seq_n(function ()
                    Isaac.Spawn(
                    EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, CoinSubType.COIN_PENNY,
                    Isaac.GetFreeNearPosition(p0.Position, 40), Vector.Zero, nil)
                end, 1, 10, true)
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

AscensionMod.NPCDialogueColor = {
    ['angel'] = KColor(1, .98, .76, 1), -- light yellow
    ['devil'] = KColor(.42, 0, .07, 1), -- dark red
}


------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------- 每层发生事件 ------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


function AscensionMod:NewRunReset()
    seeds = game:GetSeeds()
    startSeed = seeds:GetStartSeed()
    rng = RNG(startSeed, SHIFT_INDEX)
    scheduler:clear()
    AscensionMod.ascensionLevel = AscensionMod:GetAscensionLevelFromSave()
    AscensionMod.playerStats = {
        speedAdd = 0,
        speedMul = 1,
        tearsAdd = 0,
        tearsMul = 1,
        dmgAdd = 0,
        dmgMul = 1,
        rangeAdd = 0,
        rangeMul = 1,
        shotSpeedAdd = 0,
        shotSpeedMul = 1,
        luckAdd = 0,
        luckMul = 1,
    }
end

function AscensionMod:StartNewStage()
    if AscensionMod:FirstStage() then
        AscensionMod:NewRunReset()
    end

    AscensionMod.NPCID = AscensionMod:GetNPC()

    AscensionMod.dialogue = AscensionMod:GetDialogue(AscensionMod.NPCID)

    AscensionMod.options = {} -- A, B, C1-C2, D1-D2
    AscensionMod:SetOptions(AscensionMod.NPCID)

    AscensionMod.controledField = 'option'
    AscensionMod.isOptionConfirmed = false
    AscensionMod.SelectedOption = 'A'

    AscensionMod:SpawnStatue(AscensionMod.NPCID)

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
    return legitNPCIDList[rng:RandomInt(#legitNPCIDList - 1) + 1]
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

    return legitDialogueList[rng:RandomInt(#legitDialogueList - 1) + 1]
end


------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------- 生成 NPC "雕像" ---------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


local HUSH_STAGE_Y_OFFSET = 120
function AscensionMod:SpawnStatue(NPCID)
    local yOffset = 0
    if game:GetLevel():GetStage() == LevelStage.STAGE4_3 then
        yOffset = HUSH_STAGE_Y_OFFSET
    end
    AscensionMod.NPCStatues[NPCID][1](yOffset)
end

function AscensionMod:RemoveStatue(NPCID)
    AscensionMod.NPCStatues[NPCID][2]()
end


------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------- 抽取 / 显示进层选项 ------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


AscensionMod.options = {}
---@param NPCID string The ID of the NPC you wish to choose options from
function AscensionMod:SetOptions(NPCID)
    if NPCID == nil then print('Error: NPC ID is nil while trying to set options.') return end

    local optionsAB = AscensionMod.NPCOptions[NPCID]['AB']
    if optionsAB == nil then
        print('Error: No AB options found for NPC ID: '..tostring(NPCID))
        return
    end
    local legitOptionsAB = {}
    local allLegit = false
    local predicates
    if AscensionMod.NPCOptionPredicates[NPCID] == nil then
        allLegit = true
    else
        if AscensionMod.NPCOptionPredicates[NPCID]['AB'] == nil then
            allLegit = true
        else
            predicates = AscensionMod.NPCOptionPredicates[NPCID]['AB']
        end
    end
    for name, _ in pairs(optionsAB) do
        if allLegit then
            table.insert(legitOptionsAB, name)
        elseif predicates[name] == nil then
            table.insert(legitOptionsAB, name)
        else
            if predicates[name]() then
                table.insert(legitOptionsAB, name)
            end
        end
    end
    local optionsABCnt = AscensionMod:GetTableSize(legitOptionsAB)
    local optionA = rng:RandomInt(optionsABCnt - 1) + 1
    local optionB = rng:RandomInt(optionsABCnt - 1 - 1) + 1
    if optionB >= optionA then
        optionB = optionB + 1
    end
    local i = 0
    for _, desc in ipairs(legitOptionsAB) do
        i = i + 1
        if i == optionA then AscensionMod.options['A'] = desc end
        if i == optionB then AscensionMod.options['B'] = desc end
    end


    local optionsCD1 = AscensionMod.NPCOptions[NPCID]['CD1']
    if optionsCD1 == nil then
        print('Error: No CD1 options found for NPC ID: '..tostring(NPCID))
        return
    end
    local legitOptionsCD1 = {}
    allLegit = false
    if AscensionMod.NPCOptionPredicates[NPCID] == nil then
        allLegit = true
    else
        if AscensionMod.NPCOptionPredicates[NPCID]['CD1'] == nil then
            allLegit = true
        else
            predicates = AscensionMod.NPCOptionPredicates[NPCID]['CD1']
        end
    end
    for name, _ in pairs(optionsCD1) do
        if allLegit then
            table.insert(legitOptionsCD1, name)
        elseif predicates[name] == nil then
            table.insert(legitOptionsCD1, name)
        else
            if predicates[name]() then
                table.insert(legitOptionsCD1, name)
            end
        end
    end
    local optionsCD1Cnt = AscensionMod:GetTableSize(legitOptionsCD1)
    local optionC1 = rng:RandomInt(optionsCD1Cnt - 1) + 1
    local optionD1 = rng:RandomInt(optionsCD1Cnt - 1 - 1) + 1
    if optionD1 >= optionC1 then
        optionD1 = optionD1 + 1
    end
    i = 0
    for _, desc in ipairs(legitOptionsCD1) do
        i = i + 1
        if i == optionC1 then AscensionMod.options['C1'] = desc end
        if i == optionD1 then AscensionMod.options['D1'] = desc end
    end


    local optionsCD2 = AscensionMod.NPCOptions[NPCID]['CD2']
    if optionsCD2 == nil then
        print('Error: No CD2 options found for NPC ID: '..tostring(NPCID))
        return
    end
    local legitOptionsCD2 = {}
    allLegit = false
    if AscensionMod.NPCOptionPredicates[NPCID] == nil then
        allLegit = true
    else
        if AscensionMod.NPCOptionPredicates[NPCID]['CD2'] == nil then
            allLegit = true
        else
            predicates = AscensionMod.NPCOptionPredicates[NPCID]['CD2']
        end
    end
    for name, _ in pairs(optionsCD2) do
        if allLegit then
            table.insert(legitOptionsCD2, name)
        elseif predicates[name] == nil then
            table.insert(legitOptionsCD2, name)
        else
            if predicates[name]() then
                table.insert(legitOptionsCD2, name)
            end
        end
    end
    local optionsCD2Cnt = AscensionMod:GetTableSize(legitOptionsCD2)
    local optionC2 = rng:RandomInt(optionsCD2Cnt - 1) + 1
    local optionD2 = rng:RandomInt(optionsCD2Cnt - 1 - 1) + 1
    if optionD2 >= optionC2 then
        optionD2 = optionD2 + 1
    end
    i = 0
    for _, desc in ipairs(legitOptionsCD2) do
        i = i + 1
        if i == optionC2 then AscensionMod.options['C2'] = desc end
        if i == optionD2 then AscensionMod.options['D2'] = desc end
    end
end

function AscensionMod:RenderMenu()
    if AscensionMod.isOptionConfirmed then
        return
    end

    AscensionMod:RenderDialogueText()
    AscensionMod:RenderAscensionText()
    AscensionMod:RenderOptionsText()
    AscensionMod:RenderExtraInfoText()
end
AscensionMod:AddCallback(ModCallbacks.MC_POST_RENDER, AscensionMod.RenderMenu)

function AscensionMod:RenderDialogueText()
    local yOffset = 0
    if game:GetLevel():GetStage() == LevelStage.STAGE4_3 then
        yOffset = HUSH_STAGE_Y_OFFSET
    end
    local pos = Isaac.WorldToScreen(Vector(320, 220 + yOffset))
    local x = pos.X
    local y = pos.Y
    local text = tostring(AscensionMod.dialogue)
    local length = font:GetStringWidth(text)
    local scale = 1.7
    local color = AscensionMod.NPCDialogueColor[AscensionMod.NPCID]
    if color == nil then
        color = AscensionMod.TextColor['white']
    end
    font:DrawStringScaled(text,
        x - length * scale / 2, y,
        scale, scale,
        color)
end

function AscensionMod:RenderAscensionText()
    local yOffset = 0
    if game:GetLevel():GetStage() == LevelStage.STAGE4_3 then
        yOffset = HUSH_STAGE_Y_OFFSET
    end
    local colorSelected = AscensionMod.TextColor['light_gray']
    if AscensionMod.controledField == 'ascension' then
        colorSelected = AscensionMod.TextColor['gray']
    end
    if not AscensionMod:FirstStage() then
        colorSelected = AscensionMod.TextColor['white']
    end

    local ascensionLevelDisplay = tostring(AscensionMod.ascensionLevel)
    if ascensionLevelDisplay == 'nil' then
        ascensionLevelDisplay = '0'
    end

    local pos = Isaac.WorldToScreen(Vector(80, 360 + yOffset))
    local x = pos.X
    local y = pos.Y
    local text = "进阶: "..ascensionLevelDisplay
    local length = font:GetStringWidth(text)
    local scale = 1
    local color = colorSelected
    font:DrawStringScaled(text,
        x, y,
        scale, scale,
        color)

    pos = Isaac.WorldToScreen(Vector(80, 380 + yOffset))
    x = pos.X
    y = pos.Y
    text = tostring(AscensionMod.ascensions[ascensionLevelDisplay])
    length = font:GetStringWidth(text)
    scale = 1
    color = AscensionMod.TextColor['white']
    font:DrawStringScaled(text,
        x, y,
        scale, scale,
        color)
end

function AscensionMod:RenderOptionsText()
    local yOffset = 0
    if game:GetLevel():GetStage() == LevelStage.STAGE4_3 then
        yOffset = HUSH_STAGE_Y_OFFSET
    end
    local colorSelected = AscensionMod.TextColor['light_gray']
    if AscensionMod.controledField == 'option' then
        colorSelected = AscensionMod.TextColor['gray']
    end
    local pos = Isaac.WorldToScreen(Vector(320, 260 + yOffset))
    local x = pos.X
    local y = pos.Y
    local text = tostring(AscensionMod.options['A'])
    local length = font:GetStringWidth(text)
    local scale = 1
    local color
    if AscensionMod.SelectedOption == 'A' then
        color = colorSelected
    else
        color = AscensionMod.TextColor['white']
    end
    font:DrawStringScaled(text,
        x - length * scale / 2, y,
        scale, scale,
        color)

    pos = Isaac.WorldToScreen(Vector(320, 280 + yOffset))
    x = pos.X
    y = pos.Y
    text = tostring(AscensionMod.options['B'])
    length = font:GetStringWidth(text)
    scale = 1
    if AscensionMod.SelectedOption == 'B' then
        color = colorSelected
    else
        color = AscensionMod.TextColor['white']
    end
    font:DrawStringScaled(text,
        x - length * scale / 2, y,
        scale, scale,
        color)

    pos = Isaac.WorldToScreen(Vector(320, 300 + yOffset))
    x = pos.X
    y = pos.Y
    text = tostring(AscensionMod.options['C1'])..' 但是 '..tostring(AscensionMod.options['C2'])
    length = font:GetStringWidth(text)
    scale = 1
    if AscensionMod.SelectedOption == 'C' then
        color = colorSelected
    else
        color = AscensionMod.TextColor['white']
    end
    font:DrawStringScaled(text,
        x - length * scale / 2, y,
        scale, scale,
        color)

    pos = Isaac.WorldToScreen(Vector(320, 320 + yOffset))
    x = pos.X
    y = pos.Y
    text = tostring(AscensionMod.options['D1'])..' 但是 '..tostring(AscensionMod.options['D2'])
    length = font:GetStringWidth(text)
    scale = 1
    if AscensionMod.SelectedOption == 'D' then
        color = colorSelected
    else
        color = AscensionMod.TextColor['white']
    end
    font:DrawStringScaled(text,
        x - length * scale / 2, y,
        scale, scale,
        color)
end

function AscensionMod:RenderExtraInfoText()
    local yOffset = 0
    if game:GetLevel():GetStage() == LevelStage.STAGE4_3 then
        yOffset = HUSH_STAGE_Y_OFFSET
    end
    local pos = Isaac.WorldToScreen(Vector(565, 145 + yOffset))
    local x = pos.X
    local y = pos.Y
    local text = '↑ ↓ 切换选项'
    local length = font:GetStringWidth(text)
    local scale = 1
    local color = AscensionMod.TextColor['light_gray']
    font:DrawStringScaled(text,
        x - length * scale, y,
        scale, scale,
        color)

    if not AscensionMod:FirstStage() then
        return
    end

    pos = Isaac.WorldToScreen(Vector(565, 170 + yOffset))
    x = pos.X
    y = pos.Y
    text = '← → 切换菜单'
    length = font:GetStringWidth(text)
    scale = 1
    color = AscensionMod.TextColor['light_gray']
    font:DrawStringScaled(text,
        x - length * scale, y,
        scale, scale,
        color)
end


------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------- 选择操作区域 -------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


local actionLeftReleased = true
local actionRightReleased = true
function AscensionMod:SwitchControledField(entity, _, _)
    if AscensionMod.isOptionConfirmed then
        return
    end
    if not AscensionMod:FirstStage() then
        return
    end
    if entity == nil or entity.Type ~= EntityType.ENTITY_PLAYER then
        return
    end
    if Input.IsActionPressed(ButtonAction.ACTION_SHOOTLEFT, 0) then
        if actionLeftReleased then
            actionLeftReleased = false
            AscensionMod.controledField = AscensionMod.PrevControledField[AscensionMod.controledField]
        end
    else
        actionLeftReleased = true
    end
    if Input.IsActionPressed(ButtonAction.ACTION_SHOOTRIGHT, 0) then
        if actionRightReleased then
            actionRightReleased = false
            AscensionMod.controledField = AscensionMod.NextControledField[AscensionMod.controledField]
        end
    else
        actionRightReleased = true
    end
end
AscensionMod:AddCallback(ModCallbacks.MC_INPUT_ACTION, AscensionMod.SwitchControledField)


------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------- 选择进阶等级 -------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


local actionDownReleased = true
local actionUpReleased = true
local actionConfirmReleased = true
function AscensionMod:SwitchAscensionLevel(entity, _, _)
    if AscensionMod.isOptionConfirmed or AscensionMod.controledField ~= 'ascension' then
        return
    end
    if not AscensionMod:FirstStage() then
        AscensionMod.controledField = 'option'
        return
    end
    if entity == nil or entity.Type ~= EntityType.ENTITY_PLAYER then
        return
    end

    local maxSavedAscensionLevel = AscensionMod:GetAscensionLevelFromSave()
    local maxDefinedAscensionLevel = AscensionMod:GetMaxAscensionLevel()
    local maxAscensionLevel
    if AscensionMod.debug then
        maxAscensionLevel = maxDefinedAscensionLevel
    else
        maxAscensionLevel = maxSavedAscensionLevel
    end

    if Input.IsActionPressed(ButtonAction.ACTION_MENUDOWN, 0) then
        if actionDownReleased then
            actionDownReleased = false
            if AscensionMod.ascensionLevel < maxAscensionLevel then
                AscensionMod.ascensionLevel = AscensionMod.ascensionLevel + 1
            else
                AscensionMod.ascensionLevel = 0
            end
        end
    else
        actionDownReleased = true
    end

    if Input.IsActionPressed(ButtonAction.ACTION_MENUUP, 0) then
        if actionUpReleased then
            actionUpReleased = false
            if AscensionMod.ascensionLevel > 0 then
                AscensionMod.ascensionLevel = AscensionMod.ascensionLevel - 1
            else
                AscensionMod.ascensionLevel = maxAscensionLevel
            end
        end
    else
        actionUpReleased = true
    end

    if Input.IsActionPressed(ButtonAction.ACTION_MENUCONFIRM, 0) then
        if actionConfirmReleased then
            actionConfirmReleased = false
            AscensionMod:ConfirmSeletedOption()
        end
    else
        actionConfirmReleased = true
    end
end
AscensionMod:AddCallback(ModCallbacks.MC_INPUT_ACTION, AscensionMod.SwitchAscensionLevel)


------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------- 切换 / 确认选项 ----------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


---@param entity Entity
function AscensionMod:SwitchSeletedOption(entity, _, _)
    if AscensionMod.isOptionConfirmed or AscensionMod.controledField ~= 'option' then
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
            AscensionMod:ConfirmSeletedOption()
        end
    else
        actionConfirmReleased = true
    end
end
AscensionMod:AddCallback(ModCallbacks.MC_INPUT_ACTION, AscensionMod.SwitchSeletedOption)

function AscensionMod:ConfirmSeletedOption()
    if AscensionMod.isOptionConfirmed then
        return
    end

    if AscensionMod.controledField == 'option' then
        for i = 0, game:GetNumPlayers() - 1 do
            game:GetPlayer(i):AnimateHappy()
        end

        AscensionMod.isOptionConfirmed = true
        local option = AscensionMod.SelectedOption;

        local NPCID = AscensionMod.NPCID
        local optionsAB = AscensionMod.NPCOptions[NPCID]['AB']
        local optionsCD1 = AscensionMod.NPCOptions[NPCID]['CD1']
        local optionsCD2 = AscensionMod.NPCOptions[NPCID]['CD2']
        local key
        local eventFn
        if option == 'A' or option == 'B' then
            key = AscensionMod.options[option]
            eventFn = optionsAB[key]
            if eventFn ~= nil then eventFn() else print('Error: No event function found for: '..tostring(key)) end
        else
            key = AscensionMod.options[tostring(option)..'1']
            eventFn = optionsCD1[key]
            if eventFn ~= nil then eventFn() else print('Error: No event function found for: '..tostring(key)) end

            key = AscensionMod.options[tostring(option)..'2']
            eventFn = optionsCD2[key]
            if eventFn ~= nil then eventFn() else print('Error: No event function found for: '..tostring(key)) end
        end

        AscensionMod:ShowPlayer()
        AscensionMod:RemoveStatue(NPCID)

        scheduler:once(function ()
            AscensionMod:EnablePlayerControls()
        end, 1) -- 延迟 1 帧防止按空格选择时同时触发主动
    elseif AscensionMod.controledField == 'ascension' then
        AscensionMod.controledField = 'option'
    else
        print('Error: unknown controled field: '..tostring(AscensionMod.controledField))
    end
end


------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------- 控制玩家属性 ----------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


---@param player EntityPlayer
---@param cacheFlag CacheFlag
function AscensionMod:OnEvaluateCache(player, cacheFlag)
    local stats = AscensionMod.playerStats
    if stats == nil then
        return
    end
    if cacheFlag == CacheFlag.CACHE_SPEED then
        player.MoveSpeed = (player.MoveSpeed + stats.speedAdd) * stats.speedMul
    end
    if cacheFlag == CacheFlag.CACHE_FIREDELAY then
        local d = player.MaxFireDelay
        local t = 30 / (d + 1) -- tears
        t = (t + stats.tearsAdd) * stats.tearsMul
        if t < 0 then
            t = 0
        end
        d = (30 / t) - 1
        player.MaxFireDelay = d
    end
    if cacheFlag == CacheFlag.CACHE_DAMAGE then
        player.Damage = (player.Damage + stats.dmgAdd) * stats.dmgMul
    end
    if cacheFlag == CacheFlag.CACHE_RANGE then
        player.TearRange = (player.TearRange + stats.rangeAdd * 40) * stats.rangeMul
    end
    if cacheFlag == CacheFlag.CACHE_SHOTSPEED then
        player.ShotSpeed = (player.ShotSpeed + stats.shotSpeedAdd) * stats.shotSpeedMul
    end
    if cacheFlag == CacheFlag.CACHE_LUCK then
        player.Luck = (player.Luck + stats.luckAdd) * stats.luckMul
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
    return AscensionMod:GetTableSize(AscensionMod.ascensions) - 1
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
    if stage == 1 and (level:GetStageType() ~= StageType.STAGETYPE_REPENTANCE) and (level:GetStageType() ~= StageType.STAGETYPE_REPENTANCE_B) then
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

AscensionMod.debug = false
---@param toState boolean
function AscensionMod:Debug(toState)
    if toState == nil then
        AscensionMod.debug = not AscensionMod.debug
    else
        AscensionMod.debug = toState
    end
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


------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------- 进阶 0 -----------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
-- 每下一层，敌人血量增长 6%；boss血量增加25%