---@class ModReference
AscensionMod = RegisterMod("Ascension", 1)

---@class SaveManager
AscensionMod.SaveManager = include('save_manager')
AscensionMod.SaveManager.Init(AscensionMod)

local game = Game()

local RNG_SHIFT_INDEX = 35
AscensionMod.statID = {
    SPEED = 1,
    TEARS = 2,
    DMG = 3,
    RANGE = 4,
    SHOTSPEED = 5,
    LUCK = 6
}

-- https://gist.github.com/efrederickson/4080372
local RomanNumerals = { }

RomanNumerals.numbers = { 1, 5, 10, 50, 100, 500, 1000 }
RomanNumerals.chars = { "I", "V", "X", "L", "C", "D", "M" }

AscensionMod.debug = true

function RomanNumerals.ToRomanNumerals(s)
    --s = tostring(s)
    s = tonumber(s)
    if not s or s ~= s then error"Unable to convert to number" end
    if s == math.huge then error"Unable to convert infinity" end
    s = math.floor(s)
    if s <= 0 then return s end
	local ret = ""
        for i = #RomanNumerals.numbers, 1, -1 do
        local num = RomanNumerals.numbers[i]
        while s - num >= 0 and s > 0 do
            ret = ret .. RomanNumerals.chars[i]
            s = s - num
        end
        --for j = i - 1, 1, -1 do
        for j = 1, i - 1 do
            local n2 = RomanNumerals.numbers[j]
            if s - (num - n2) >= 0 and s < num and s > 0 and num - n2 ~= n2 then
                ret = ret .. RomanNumerals.chars[j] .. RomanNumerals.chars[i]
                s = s - (num - n2)
                break
            end
        end
    end
    return ret
end


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


AscensionMod.ascensionLevel = 0
AscensionMod.ascensions = {
    ['0'] = '深渊 - BOSS 血量更多；每下一层，所有敌人血量成长',
    ['1'] = '进化 - 精英敌人更多；敌人获得降级抗性',
    ['2'] = '赝品 - 基础掉落物更差；金炸弹，金钥匙效果变化',
    ['3'] = '心碎 - 更差的开局',
    ['4'] = '腐烂 - 它们烂了',
    ['5'] = '回收 - 道具品质降低',
    ['6'] = '背刺 - 开局受到伤害',
    ['7'] = '捉拿 - 别想逃！',
    ['8'] = '贪婪 - $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$',
    ['9'] = '坠落 - 下层时可保留的基础更少',
    ['10'] = '坚不可摧 - 心脏敌人更强大',
    ['11'] = '电击 - 滋滋',
    ['12'] = '缄默 - 射程大幅下降',
    ['13'] = '壁垒 - 所有敌人获得爆炸抗性',
    ['14'] = '折翼 - 不再能获得永久飞行',
    ['15'] = '彩虹 - 从第三层开始，BOSS 变得五颜六色',
    ['16'] = '缠绕 - 移动困难',
    ['17'] = '上瘾 - 好兴奋！！！',
    ['18'] = '恐怖 - 每清理 k 个房间，获得恐惧效果',
    ['19'] = '埋伏 - 小心特殊房间',
    ['20'] = '大限已至 - 滴答……滴答……',
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
        if AscensionMod:IsFirstStage() then
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
        if AscensionMod:IsFirstStage() then
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
            return (AscensionMod:IsFirstStage() and (not AscensionMod.FoundPoopLastRun))
        end,
        ['你好……'] = function ()
            return true
        end,
        ['我把你……带回来了……'] = function ()
            return AscensionMod:IsFirstStage()
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

AscensionMod.NPCOptionsDesc = {
    ['angel'] = {
        ['AB'] = {
            ['1'] = '生成 2 钥匙圈',
            ['2'] = '获得 0.1 移速',
            ['3'] = '获得 3 射程',
            ['4'] = '获得 0.5 弹速',
            ['5'] = '失去 0.3 弹速',
            ['6'] = '获得 1 幸运',
            ['7'] = '生成 1 颗魂心',
            ['8'] = '生成 1 张倒位恶魔'
        },
        ['CD1'] = {
            ['1'] = '生成 钥匙 全家福',
            ['2'] = '生成 2 金钥匙',
            ['3'] = '获得 3 幸运',
            ['4'] = '获得 0.2 移速',
            ['5'] = '获得 1 颗心最大生命',
            ['6'] = '获得 1 颗永恒之心',
            ['7'] = '失去 1 颗碎心',
            ['8'] = '获得 2 张神圣卡',
            ['9'] = '生成 痛悔短祷',
            ['10'] = '获得 金色 银丝羽毛',
            ['11'] = '获得 金色 念珠段',
            ['12'] = '获得 1 层祝福', -- todo 大教堂 buff
            ['13'] = '获得 1 层幸运',
            ['14'] = '获得 1 层远见',
            ['15'] = '生成 1 张教皇卡'
        },
        ['CD2'] = {
            ['1'] = '获得 1 层萎靡',
            ['2'] = '获得 1 层虚弱',
            ['3'] = '获得 1 层惩戒',
        }
    },
    ['devil'] = {
        ['AB'] = {
            ['1'] = '生成 2 随机炸弹',
            ['2'] = '生成 5 便士',
            ['3'] = '生成 5 随机硬币',
            ['4'] = '获得 0.4 攻击修正',
            ['5'] = '获得 0.3 射速修正',
            ['6'] = '生成 10 即爆炸弹',
            ['7'] = '生成 1 颗黑心',
            ['8'] = '生成 2 张恶魔卡',
            ['9'] = '生成 1 张力量卡',
        },
        ['CD1'] = {
            ['1'] = '生成 15 随机硬币',
            ['2'] = '生成 7 随机炸弹',
            ['3'] = '生成 金色 恶魔王冠',
            ['4'] = '生成 彼列之书',
            ['5'] = '获得 1 层力量',
            ['6'] = '获得 1 层腐化',
            ['7'] = '生成 5 张恶魔卡',
            ['8'] = '生成 3 张力量卡',
            ['9'] = '生成 2 张倒位力量卡',
        },
        ['CD2'] = {
            ['1'] = '获得 黑暗诅咒 和 致盲诅咒',
            ['2'] = '获得 1 颗碎心',
            ['3'] = '失去所有 钥匙 和 金币',
            ['4'] = '获得 1 层不幸',
            ['5'] = '获得 1 层灾厄', -- 随机超级陆夫人
            ['6'] = '失去 三分之二 射程',
            ['7'] = '失去 2 颗心最大生命',
        }
    }
}

AscensionMod.NPCOptionEvents = {
    ['angel'] = {
        ['AB'] = {
            ['1'] = function()
                AscensionMod:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, KeySubType.KEY_DOUBLEPACK, 2, 0)
            end,
            ['2'] = function ()
                AscensionMod:AddStats(AscensionMod.statID.SPEED, 0.10)
            end,
            ['3'] = function ()
                AscensionMod:AddStats(AscensionMod.statID.RANGE, 3)
            end,
            ['4'] = function ()
                AscensionMod:AddStats(AscensionMod.statID.SHOTSPEED, 0.5)
            end,
            ['5'] = function ()
                AscensionMod:AddStats(AscensionMod.statID.SHOTSPEED, -0.3)
            end,
            ['6'] = function ()
                AscensionMod:AddStats(AscensionMod.statID.LUCK, 1)
            end,
            ['7'] = function ()
                AscensionMod:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, HeartSubType.HEART_SOUL, 1, 0)
            end,
            ['8'] = function ()
                AscensionMod:SpawnCard(Card.CARD_REVERSE_DEVIL, 1, 0)
            end
        },
        ['CD1'] = {
            ['1'] = function()
                scheduler:once(function ()
                    AscensionMod:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, KeySubType.KEY_NORMAL, 1, 0)
                end, 1)
                scheduler:once(function ()
                    AscensionMod:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, KeySubType.KEY_CHARGED, 1, 0)
                end, 2)
                scheduler:once(function ()
                    AscensionMod:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, KeySubType.KEY_DOUBLEPACK, 1, 0)
                end, 3)
                scheduler:once(function ()
                    AscensionMod:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, KeySubType.KEY_GOLDEN, 1, 0)
                end, 4)
            end,
            ['2'] = function ()
                AscensionMod:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, KeySubType.KEY_GOLDEN, 2, 0)
            end,
            ['3'] = function ()
                AscensionMod:AddStats(AscensionMod.statID.LUCK, 3)
            end,
            ['4'] = function ()
                AscensionMod:AddStats(AscensionMod.statID.SPEED, 0.2)
            end,
            ['5'] = function ()
                local p0 = game:GetPlayer(0)
                p0:AddMaxHearts(2, true)
            end,
            ['6'] = function ()
                local p0 = game:GetPlayer(0)
                p0:AddEternalHearts(1)
            end,
            ['7'] = function ()
                local p0 = game:GetPlayer(0)
                p0:AddBrokenHearts(-1)
            end,
            ['8'] = function ()
                AscensionMod:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, Card.CARD_HOLY, 2, 0)
            end,
            ['9'] = function ()
                AscensionMod:SpawnPickup(PickupVariant.PICKUP_COLLECTIBLE,
                    CollectibleType.COLLECTIBLE_ACT_OF_CONTRITION, 1, 0)
            end,
            ['10'] = function ()
                AscensionMod:SwallowTrinket(TrinketType.TRINKET_FILIGREE_FEATHERS, true)
            end,
            ['11'] = function ()
                AscensionMod:SwallowTrinket(TrinketType.TRINKET_ROSARY_BEAD, true)
            end,
            ['12'] = function ()
                AscensionMod:GainStatusOnce('blessing')
            end,
            ['13'] = function ()
                AscensionMod:GainStatusOnce('luck')
            end,
            ['14'] = function ()
                AscensionMod:GainStatusOnce('range')
            end,
            ['15'] = function ()
                AscensionMod:SpawnCard(Card.CARD_HIEROPHANT, 1, 0)
            end
        },
        ['CD2'] = {
            ['1'] = function ()
                AscensionMod:GainStatusOnce('malaise')
            end,
            ['2'] = function ()
                AscensionMod:GainStatusOnce('weakness')
            end,
            ['3'] = function ()
                AscensionMod:GainStatusOnce('discipline')
            end
        }
    },
    ['devil'] = {
        ['AB'] = {
            ['1'] = function ()
                AscensionMod:SpawnPickup(PickupVariant.PICKUP_BOMB, 0, 2, 0)
            end,
            ['2'] = function ()
                AscensionMod:SpawnPickup(PickupVariant.PICKUP_COIN, CoinSubType.COIN_PENNY, 5, 1)
            end,
            ['3'] = function ()
                AscensionMod:SpawnPickup(PickupVariant.PICKUP_COIN, 0, 5, 1)
            end,
            ['4'] = function ()
                AscensionMod:AddStats(AscensionMod.statID.DMG, 0.4)
            end,
            ['5'] = function ()
                AscensionMod:AddStats(AscensionMod.statID.TEARS, 0.3)
            end,
            ['6'] = function ()
                AscensionMod:SpawnPickup(PickupVariant.PICKUP_BOMB, BombSubType.BOMB_TROLL, 10, 1)
            end,
            ['7'] = function ()
                AscensionMod:SpawnPickup(PickupVariant.PICKUP_HEART, HeartSubType.HEART_BLACK, 1, 0)
            end,
            ['8'] = function ()
                AscensionMod:SpawnCard(Card.CARD_DEVIL, 2, 0)
            end,
            ['9'] = function ()
                AscensionMod:SpawnCard(Card.CARD_STRENGTH, 1, 0)
            end,
        },
        ['CD1'] = {
            ['1'] = function ()
                AscensionMod:SpawnPickup(PickupVariant.PICKUP_COIN, 0, 15, 1)
            end,
            ['2'] = function ()
                AscensionMod:SpawnPickup(PickupVariant.PICKUP_BOMB, 0, 7, 1)
            end,
            ['3'] = function ()
                AscensionMod:SpawnTrinket(TrinketType.TRINKET_DEVILS_CROWN, true)
            end,
            ['4'] = function ()
                AscensionMod:SpawnPickup(PickupVariant.PICKUP_COLLECTIBLE, CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL, 1, 0)
            end,
            ['5'] = function ()
                AscensionMod:GainStatusOnce('strength')
            end,
            ['6'] = function ()
                AscensionMod:GainStatusOnce('corruption')
            end,
            ['7'] = function ()
                AscensionMod:SpawnCard(Card.CARD_DEVIL, 5, 2)
            end,
            ['8'] = function ()
                AscensionMod:SpawnCard(Card.CARD_STRENGTH, 3, 2)
            end,
            ['9'] = function ()
                AscensionMod:SpawnCard(Card.CARD_REVERSE_STRENGTH, 2, 0)
            end,
        },
        ['CD2'] = {
            ['1'] = function ()
                local level = game:GetLevel()
                level:AddCurse(LevelCurse.CURSE_OF_DARKNESS, true)
                level:AddCurse(LevelCurse.CURSE_OF_BLIND, true)
            end,
            ['2'] = function ()
                local p0 = game:GetPlayer(0)
                p0:AddBrokenHearts(1)
            end,
            ['3'] = function ()
                local p0 = game:GetPlayer(0)
                p0:AddKeys(-99)
                p0:AddCoins(-999)
            end,
            ['4'] = function ()
                AscensionMod:GainStatusOnce('unluck')
            end,
            ['5'] = function ()
                AscensionMod:GainStatusOnce('cataclysm')
            end,
            ['6'] = function ()
                local p0 = game:GetPlayer(0)
                AscensionMod:AddStats(AscensionMod.statID.RANGE, -(p0.TearRange / 40) / 3 * 2)
            end,
            ['7'] = function ()
                local p0 = game:GetPlayer(0)
                p0:AddMaxHearts(-4, true)
            end,
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

AscensionMod.NPCOptionPredicates = {
    ['angel'] = {
        ['AB'] = {
            ['7'] = function ()
                return not AscensionMod:KeeperOrLost()
            end,
        },
        ['CD1'] = {
            ['5'] = function ()
                return not AscensionMod:KeeperOrLost()
            end,
            ['6'] = function ()
                return not AscensionMod:KeeperOrLost()
            end,
            ['7'] = function ()
                local p0 = game:GetPlayer(0)
                return (p0:GetBrokenHearts() >= 1)
            end,
        }
    },
    ['devil'] = {
        ['CD1'] = {
            ['6'] = function ()
                local p0 = game:GetPlayer(0)
                return (p0:GetBrokenHearts() >= 10)
            end
        },
        ['CD2'] = {
            ['3'] = function ()
                local p0 = game:GetPlayer(0)
                return (p0:GetNumKeys() >= 2 and p0:GetNumCoins() >= 20)
            end,
            ['8'] = function ()
                local p0 = game:GetPlayer(0)
                return (not AscensionMod:KeeperOrLost()) and (p0:GetMaxHearts() >= 4)
            end
        }
    }
}

AscensionMod.NPCDialogueColor = {
    ['angel'] = KColor(1, .98, .76, 1), -- light yellow
    ['devil'] = KColor(.42, 0, .07, 1), -- dark red
}


------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------- !!开局事件!! ------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


local EXTRA_BOMB_ON_START = 3
function AscensionMod:NewRunReset()
    local seeds = game:GetSeeds()
    AscensionMod.startSeed = seeds:GetStartSeed()
    AscensionMod.gameRNG = RNG(AscensionMod.startSeed, RNG_SHIFT_INDEX)

    scheduler:clear()

    if not AscensionMod.debug then
        AscensionMod.ascensionLevel = AscensionMod:GetAscensionLevelFromSave()
    end

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
    AscensionMod.stageCnt = 0

    AscensionMod:ResetStatusLevels()

    local p0 = game:GetPlayer(0)
    p0:AddBombs(EXTRA_BOMB_ON_START)
    if p0:GetPlayerType() == PlayerType.PLAYER_THELOST_B then
        Isaac.Spawn(
            EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, Card.CARD_HOLY,
            Isaac.GetFreeNearPosition(p0.Position, 40), Vector.Zero, nil)
    end

    AscensionMod.a2:Init()
end

function AscensionMod:OnFirstStageOptionConfirm()
    AscensionMod.a3:Start()
    AscensionMod.a6:Start()
    AscensionMod.a12:Start()
end


------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------- 每层发生事件 ------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


function AscensionMod:StartNewStage()
    if AscensionMod:IsFirstStage() then
        AscensionMod:NewRunReset()
    end

    AscensionMod.stageCnt = AscensionMod.stageCnt + 1

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
    return legitNPCIDList[AscensionMod.gameRNG:RandomInt(#legitNPCIDList - 1) + 1]
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
        if AscensionMod.debug then print('Error: Unknown NPC: '..tostring(NPCID)) end
        return 'Error'
    end

    local legitDialogueList = {}
    for dialogue, predicate in pairs(dialoguePredicates) do
        if predicate() then
            table.insert(legitDialogueList, dialogue)
        end
    end

    AscensionMod.FoundPoopLastRun = false

    return legitDialogueList[AscensionMod.gameRNG:RandomInt(#legitDialogueList - 1) + 1]
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
---------------------------------------------------------------- 抽取进层选项 -------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


AscensionMod.options = {}
---@param NPCID string The ID of the NPC you wish to choose options from
function AscensionMod:SetOptions(NPCID)
    if NPCID == nil then if AscensionMod.debug then print('Error: NPC ID is nil while trying to set options.') end return end

    local optionABDescs = AscensionMod.NPCOptionEvents[NPCID]['AB']
    if optionABDescs == nil then
        if AscensionMod.debug then print('Error: No AB option descriptions found for NPC ID: '..tostring(NPCID)) end
        return
    end
    local legitOptionABIDs = {}
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
    for optionID, _ in pairs(optionABDescs) do
        if allLegit then
            table.insert(legitOptionABIDs, optionID)
        elseif predicates[optionID] == nil then
            table.insert(legitOptionABIDs, optionID)
        else
            if predicates[optionID]() then
                table.insert(legitOptionABIDs, optionID)
            end
        end
    end
    local optionsABCnt = #legitOptionABIDs
    local optionA = AscensionMod.gameRNG:RandomInt(optionsABCnt) + 1
    local optionB = AscensionMod.gameRNG:RandomInt(optionsABCnt - 1) + 1
    if optionB >= optionA then
        optionB = optionB + 1
    end
    AscensionMod.options['A'] = tostring(legitOptionABIDs[optionA])
    AscensionMod.options['B'] = tostring(legitOptionABIDs[optionB])

    local optionCD1Descs = AscensionMod.NPCOptionEvents[NPCID]['CD1']
    if optionCD1Descs == nil then
        if AscensionMod.debug then print('Error: No CD1 options found for NPC ID: '..tostring(NPCID)) end
        return
    end
    local legitOptionCD1IDs = {}
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
    for optionID, _ in pairs(optionCD1Descs) do
        if allLegit then
            table.insert(legitOptionCD1IDs, optionID)
        elseif predicates[optionID] == nil then
            table.insert(legitOptionCD1IDs, optionID)
        else
            if predicates[optionID]() then
                table.insert(legitOptionCD1IDs, optionID)
            end
        end
    end
    local optionsCD1Cnt = #legitOptionCD1IDs
    local optionC1 = AscensionMod.gameRNG:RandomInt(optionsCD1Cnt) + 1
    local optionD1 = AscensionMod.gameRNG:RandomInt(optionsCD1Cnt - 1) + 1
    if optionD1 >= optionC1 then
        optionD1 = optionD1 + 1
    end
    AscensionMod.options['C1'] = tostring(legitOptionCD1IDs[optionC1])
    AscensionMod.options['D1'] = tostring(legitOptionCD1IDs[optionD1])

    local optionCD2Descs = AscensionMod.NPCOptionEvents[NPCID]['CD2']
    if optionCD2Descs == nil then
        if AscensionMod.debug then print('Error: No CD2 options found for NPC ID: '..tostring(NPCID)) end
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
    for optionID, _ in pairs(optionCD2Descs) do
        if allLegit then
            table.insert(legitOptionsCD2, optionID)
        elseif predicates[optionID] == nil then
            table.insert(legitOptionsCD2, optionID)
        else
            if predicates[optionID]() then
                table.insert(legitOptionsCD2, optionID)
            end
        end
    end
    local optionsCD2Cnt = #legitOptionsCD2
    local optionC2 = AscensionMod.gameRNG:RandomInt(optionsCD2Cnt) + 1
    local optionD2 = AscensionMod.gameRNG:RandomInt(optionsCD2Cnt - 1) + 1
    if optionD2 >= optionC2 then
        optionD2 = optionD2 + 1
    end
    AscensionMod.options['C2'] = tostring(legitOptionsCD2[optionC2])
    AscensionMod.options['D2'] = tostring(legitOptionsCD2[optionD2])
end


------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------- 渲染进层选项 -------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


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
    if not AscensionMod:IsFirstStage() then
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

    local NPCID = AscensionMod.NPCID
    if NPCID == nil then
        return
    end
    local optionDescs = AscensionMod.NPCOptionsDesc[NPCID]
    if optionDescs == nil then
        if AscensionMod.debug then print('Error: No option descriptions found for NPC: '..tostring(NPCID)) end
        return
    end

    local colorSelected = AscensionMod.TextColor['light_gray']
    if AscensionMod.controledField == 'option' then
        colorSelected = AscensionMod.TextColor['gray']
    end
    local pos = Isaac.WorldToScreen(Vector(320, 260 + yOffset))
    local x = pos.X
    local y = pos.Y
    local text = tostring(optionDescs['AB'][AscensionMod.options['A']])
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
    text = tostring(optionDescs['AB'][AscensionMod.options['B']])
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
    text = tostring(optionDescs['CD1'][AscensionMod.options['C1']])..' 但是 '..tostring(optionDescs['CD2'][AscensionMod.options['C2']])
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
    text = tostring(optionDescs['CD1'][AscensionMod.options['D1']])..' 但是 '..tostring(optionDescs['CD2'][AscensionMod.options['D2']])
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
    local yPos = 145
    local yStep = 25
    local pos = Isaac.WorldToScreen(Vector(565, yPos + yOffset))
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

    if AscensionMod:IsFirstStage() then
        yPos = yPos + yStep
        pos = Isaac.WorldToScreen(Vector(565, yPos + yOffset))
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

    yPos = yPos + yStep
    pos = Isaac.WorldToScreen(Vector(565, yPos + yOffset))
    x = pos.X
    y = pos.Y
    text = '[E] 确认'
    length = font:GetStringWidth(text)
    scale = 1
    color = AscensionMod.TextColor['light_gray']
    font:DrawStringScaled(text,
        x - length * scale, y,
        scale, scale,
        color)
end


------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------ 渲染状态 ---------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


AscensionMod.statusDisplay = {
    malaise = {
        c = KColor(1, 1, 1, 1), -- color
        t = '萎靡' -- text
    },
    weakness = {
        c = KColor(1, 1, 1, 1),
        t = '虚弱'
    },
    discipline = {
        c = KColor(1, 1, 1, 1),
        t = '惩戒'
    },
    blessing = {
        c = KColor(1, 1, 1, 1),
        t = '祝福'
    },
    luck = {
        c = KColor(1, 1, 1, 1),
        t = '幸运'
    },
    range = {
        c = KColor(1, 1, 1, 1),
        t = '远见'
    },
    strength = {
        c = KColor(1, 1, 1, 1),
        t = '力量'
    },
    corruption = {
        c = KColor(1, 1, 1, 1),
        t = '腐化'
    },
    unluck = {
        c = KColor(1, 1, 1, 1),
        t = '不幸'
    },
    cataclysm = {
        c = KColor(1, 1, 1, 1),
        t = '灾厄'
    },
    goldenBomb = {
        c = KColor(1, 1, 1, 1),
        t = '金炸弹'
    },
    goldenKey = {
        c = KColor(1, 1, 1, 1),
        t = '金钥匙'
    },
}

function AscensionMod:RenderStatus()
    local bottomRight = Vector(Isaac.GetScreenWidth() - 30, Isaac.GetScreenHeight() - 50)
    local Y_STEP = 15

    local x = bottomRight.X
    local y = bottomRight.Y
    local text
    local length
    local scale
    local color

    for statusID, num in pairs(AscensionMod.statusLevel) do
        if num > 0 then
            if num <= 20 then
                text = AscensionMod.statusDisplay[statusID].t..' '..RomanNumerals.ToRomanNumerals(num)
            else
                text = AscensionMod.statusDisplay[statusID].t..' '..tostring(num)
            end
            color = AscensionMod.statusDisplay[statusID].c
            length = font:GetStringWidth(text)
            scale = 1
            font:DrawStringScaled(text,
                x - length * scale, y,
                scale, scale,
                color)
            y = y - Y_STEP
        end
    end
end
AscensionMod:AddCallback(ModCallbacks.MC_POST_RENDER, AscensionMod.RenderStatus)


------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------- 选择操作区域 -------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


local actionLeftReleased = true
local actionRightReleased = true
function AscensionMod:SwitchControledField(entity, _, _)
    if AscensionMod.isOptionConfirmed then
        return
    end
    if not AscensionMod:IsFirstStage() then
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
    if not AscensionMod:IsFirstStage() then
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

    if Input.IsActionPressed(ButtonAction.ACTION_BOMB, 0) then
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

    if Input.IsActionPressed(ButtonAction.ACTION_BOMB, 0) then
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

        local optionABEvents = AscensionMod.NPCOptionEvents[NPCID]['AB']
        local optionCD1Events = AscensionMod.NPCOptionEvents[NPCID]['CD1']
        local optionCD2Events = AscensionMod.NPCOptionEvents[NPCID]['CD2']

        local optionID
        local eventFn

        if option == 'A' or option == 'B' then
            optionID = AscensionMod.options[option]
            eventFn = optionABEvents[optionID]
            if eventFn ~= nil then eventFn() else if AscensionMod.debug then print('Error: No event function found for: '..tostring(optionID)) end end
        else
            optionID = AscensionMod.options[tostring(option)..'1']
            eventFn = optionCD1Events[optionID]
            if eventFn ~= nil then eventFn() else if AscensionMod.debug then print('Error: No event function found for: '..tostring(optionID)) end end

            optionID = AscensionMod.options[tostring(option)..'2']
            eventFn = optionCD2Events[optionID]
            if eventFn ~= nil then eventFn() else if AscensionMod.debug then print('Error: No event function found for: '..tostring(optionID)) end end
        end

        AscensionMod:ShowPlayer()
        AscensionMod:RemoveStatue(NPCID)

        scheduler:once(function ()
            AscensionMod:EnablePlayerControls()
        end, 1) -- 延迟 1 帧防止按空格选择时同时触发主动

        if AscensionMod:IsFirstStage() then
            AscensionMod:OnFirstStageOptionConfirm()
        end
    elseif AscensionMod.controledField == 'ascension' then
        AscensionMod.controledField = 'option'
    else
        if AscensionMod.debug then print('Error: unknown controled field: '..tostring(AscensionMod.controledField)) end
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

function AscensionMod:IsFirstStage()
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

---@param toState boolean
function AscensionMod:Debug(toState)
    if toState == nil then
        AscensionMod.debug = not AscensionMod.debug
    else
        AscensionMod.debug = toState
    end
end

function AscensionMod:KeeperOrLost()
    local p0 = game:GetPlayer(0)
    if p0:GetPlayerType() == PlayerType.PLAYER_KEEPER or p0:GetPlayerType() == PlayerType.PLAYER_KEEPER_B or
        p0:GetPlayerType() == PlayerType.PLAYER_THELOST or p0:GetPlayerType() == PlayerType.PLAYER_THELOST_B then
        return true
    end
    return false
end

---@param eType EntityType
---@param num number
---@param delay number
---@param pos Vector
function AscensionMod:SpawnAt(eType, eVariant, eSubType, num, delay, pos)
    if eType == nil then
        if AscensionMod.debug then print('Error: Cannot spawn entity with type "nil".') end
        return
    end
    eVariant = eVariant or 0
    eSubType = eSubType or 0
    num = num or 1
    delay = delay or 0
    pos = pos or (game:GetPlayer(0).Position)

    if delay == 0 then
        if num == 1 then
            return Isaac.Spawn(
                eType, eVariant, eSubType,
                pos, Vector.Zero, nil)
        else
            for _ = 1, num do
                Isaac.Spawn(
                    eType, eVariant, eSubType,
                    pos, Vector.Zero, nil)
            end
        end
    else
        scheduler:seq_n(function ()
            Isaac.Spawn(
                eType, eVariant, eSubType,
                pos, Vector.Zero, nil)
        end, delay, num, true)
    end
end

---@param eType EntityType
---@param num number
---@param delay number
---@param pos Vector
function AscensionMod:SpawnNear(eType, eVariant, eSubType, num, delay, pos)
    if eType == nil then
        if AscensionMod.debug then print('Error: Cannot spawn entity with type "nil".') end
        return
    end
    eVariant = eVariant or 0
    eSubType = eSubType or 0
    num = num or 1
    delay = delay or 0
    pos = pos or (game:GetPlayer(0).Position)

    if delay == 0 then
        for _ = 1, num do
            Isaac.Spawn(
                eType, eVariant, eSubType,
                Isaac.GetFreeNearPosition(pos, 40), Vector.Zero, nil)
        end
    else
        scheduler:seq_n(function ()
            Isaac.Spawn(
                eType, eVariant, eSubType,
                Isaac.GetFreeNearPosition(pos, 40), Vector.Zero, nil)
        end, delay, num, true)
    end
end

---@param eType EntityType
---@param num number
---@param delay number
function AscensionMod:Spawn(eType, eVariant, eSubType, num, delay)
    local p0 = game:GetPlayer(0)
    AscensionMod:SpawnNear(eType, eVariant, eSubType, num, delay, p0.Position)
end

---@param pVariant PickupVariant
---@param num number
---@param delay number
function AscensionMod:SpawnPickup(pVariant, pSubType, num, delay)
    AscensionMod:Spawn(EntityType.ENTITY_PICKUP, pVariant, pSubType, num, delay)
end

function AscensionMod:SpawnPickupAt(pVariant, pSubType, num, delay, pos)
    pos = pos or (game:GetPlayer(0).Position)
    AscensionMod:SpawnAt(EntityType.ENTITY_PICKUP, pVariant, pSubType, num, delay, pos)
end

---@param card Card
---@param num number
---@param delay number
function AscensionMod:SpawnCard(card, num, delay)
    AscensionMod:SpawnPickup(PickupVariant.PICKUP_TAROTCARD, card, num, delay)
end

---@param tType TrinketType
---@param isGolden boolean
function AscensionMod:SpawnTrinket(tType, isGolden)
    if isGolden then
        AscensionMod:SpawnPickup(PickupVariant.PICKUP_TRINKET, tType | TrinketType.TRINKET_GOLDEN_FLAG, 1, 0)
    else
        AscensionMod:SpawnPickup(PickupVariant.PICKUP_TRINKET, tType, 1, 0)
    end
end

---@param tType TrinketType
---@param isGolden boolean
function AscensionMod:SwallowTrinket(tType, isGolden)
    local p0 = game:GetPlayer(0)
    p0:DropTrinket(Isaac.GetFreeNearPosition(p0.Position, 40), true)
    p0:DropTrinket(Isaac.GetFreeNearPosition(p0.Position, 40), true)
    if isGolden then
        p0:AddTrinket(tType | TrinketType.TRINKET_GOLDEN_FLAG)
    else
        p0:AddTrinket(tType)
    end
    p0:UseActiveItem(CollectibleType.COLLECTIBLE_SMELTER, UseFlag.USE_NOANIM, -1)
end

---@param statID number starting from 1 (speed), 2 is tears, 3 is dmg, etc.
---@param value number
function AscensionMod:AddStats(statID, value)
    local p0 = game:GetPlayer(0)
    if statID == 1 then
        AscensionMod.playerStats.speedAdd = AscensionMod.playerStats.speedAdd + value
        p0:AddCacheFlags(CacheFlag.CACHE_SPEED, true)
    elseif statID == 2 then
        AscensionMod.playerStats.tearsAdd = AscensionMod.playerStats.tearsAdd + value
        p0:AddCacheFlags(CacheFlag.CACHE_FIREDELAY, true)
    elseif statID == 3 then
        AscensionMod.playerStats.dmgAdd = AscensionMod.playerStats.dmgAdd + value
        p0:AddCacheFlags(CacheFlag.CACHE_DAMAGE, true)
    elseif statID == 4 then
        AscensionMod.playerStats.rangeAdd = AscensionMod.playerStats.rangeAdd + value
        p0:AddCacheFlags(CacheFlag.CACHE_RANGE, true)
    elseif statID == 5 then
        AscensionMod.playerStats.shotSpeedAdd = AscensionMod.playerStats.shotSpeedAdd + value
        p0:AddCacheFlags(CacheFlag.CACHE_SHOTSPEED, true)
    elseif statID == 6 then
        AscensionMod.playerStats.luckAdd = AscensionMod.playerStats.luckAdd + value
        p0:AddCacheFlags(CacheFlag.CACHE_LUCK, true)
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
----------------------------------------------------------------------- 天使 -------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


AscensionMod.Angel = {}

function AscensionMod.Angel:Discipline()
    local statusLevel = AscensionMod.statusLevel.discipline
    if statusLevel < 1 then return end
    local x = statusLevel - 1

    local room = game:GetRoom()
    if room:GetType() == RoomType.ROOM_DEVIL then
        local p0 = game:GetPlayer(0)
        AscensionMod.playerStats.dmgAdd = AscensionMod.playerStats.dmgAdd - (0.7 + 0.5 * x)
        p0:AddCacheFlags(CacheFlag.CACHE_DAMAGE, true)
    end
end
AscensionMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, AscensionMod.Angel.Discipline)


------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------- 恶魔 -------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


AscensionMod.Devil = {}

function AscensionMod.Devil:Cataclysm() -- tbd
end


------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------- 进阶 0 -----------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


AscensionMod.a0 = {
    ENEMY_HP_SCALE_PER_STAGE = 1.2,
    BOSS_HP_SCALE = 1.5,
    CURSED_GLOBIN_MAX_HEALTH = 33,
}

function AscensionMod.a0.ScaleEnemyHp()
    if AscensionMod.ascensionLevel < 0 then
        return
    end
    -- thanks to enemy health scaling mod
    local entities = Isaac.GetRoomEntities()
    for _, ent in pairs(entities) do
        if ent ~= nil then
            if ent:IsActiveEnemy(false) then
                if ent.FrameCount == 1 then
                    local isBoss = ent:IsBoss()
                    local scale = AscensionMod.a0.GetEnemyHpMul(isBoss)
                    if not (ent.Type == EntityType.ENTITY_GLOBIN and ent.Variant == 3) then
                        -- so that cursed globin don't get infinite health
                        if ent.HitPoints == ent.MaxHitPoints then
                            ent.MaxHitPoints = math.max(math.floor(ent.MaxHitPoints * scale), 1)
                            ent.HitPoints = ent.MaxHitPoints
                        end
                    else
                        if ent.HitPoints == AscensionMod.a0.CURSED_GLOBIN_MAX_HEALTH then
                            ent.MaxHitPoints = math.max(math.floor(ent.MaxHitPoints * scale), 1)
                            ent.HitPoints = ent.MaxHitPoints
                        end
                    end
                end
            end
        end
    end
end
AscensionMod:AddCallback(ModCallbacks.MC_POST_UPDATE, AscensionMod.a0.ScaleEnemyHp)


function AscensionMod.a0.GetEnemyHpMul(isBoss)
    if isBoss == nil then
        isBoss = false
    end
    local stageCnt = AscensionMod.stageCnt
    if isBoss then
        return (AscensionMod.a0.ENEMY_HP_SCALE_PER_STAGE ^ stageCnt) * AscensionMod.a0.BOSS_HP_SCALE
    else
        return (AscensionMod.a0.ENEMY_HP_SCALE_PER_STAGE ^ stageCnt)
    end
end


------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------- 进阶 1 -----------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


AscensionMod.a1 = {
    CHAMPION_CHANCE = 0.6,
    ANTI_DEVOLVE_CHANCE = 0.5
}

function AscensionMod.a1:MakeChampion()
    if AscensionMod.ascensionLevel < 1 then return end
    local entities = Isaac.GetRoomEntities()
    for _, ent in pairs(entities) do
        if ent == nil then goto continue end
        if not ent:IsActiveEnemy(false) then goto continue end
        if not (ent.FrameCount == 1) then goto continue end
        local npc = ent:ToNPC()
        if npc == nil then goto continue end
        if npc:IsChampion() then goto continue end
        if npc:IsBoss() then goto continue end

        local level = game:GetLevel()
        local idx = level:GetCurrentRoomIndex()
        local data = AscensionMod.SaveManager.GetRoomSave(nil, false, idx, false)
        if not data.championRNGSeed then data.championRNGSeed = level:GetCurrentRoomDesc().SpawnSeed end
        local rng = RNG(data.championRNGSeed, RNG_SHIFT_INDEX)
        if rng:RandomFloat() < AscensionMod.a1.CHAMPION_CHANCE then
            ent:ToNPC():MakeChampion(rng:GetSeed())
        end
        data.championRNGSeed = rng:GetSeed()
        ::continue::
    end
end
AscensionMod:AddCallback(ModCallbacks.MC_POST_UPDATE, AscensionMod.a1.MakeChampion)

function AscensionMod.a1:AntiDevolve()
    if AscensionMod.ascensionLevel < 1 then
        return
    end
    if AscensionMod.gameRNG:RandomFloat() < AscensionMod.a1.ANTI_DEVOLVE_CHANCE then
        return true
    end
end
AscensionMod:AddCallback(ModCallbacks.MC_PRE_ENTITY_DEVOLVE, AscensionMod.a1.AntiDevolve)


------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------- 进阶 2 -----------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


AscensionMod.a2 = {
    HEART_DOWNGRADE_CHANCE = 0.9,
    HEART_DOWNGRADE = {
        [HeartSubType.HEART_DOUBLEPACK] = HeartSubType.HEART_SCARED,
        [HeartSubType.HEART_FULL] = HeartSubType.HEART_HALF,
        [HeartSubType.HEART_SOUL] = HeartSubType.HEART_HALF_SOUL,
        [HeartSubType.HEART_BLACK] = HeartSubType.HEART_SOUL,
        [HeartSubType.HEART_ETERNAL] = HeartSubType.HEART_SOUL,
    },
    DOUBLEPACK_DOWNGRADE_CHANCE = 0.7,
    GOLDEN_PICKUP_EXHAUST_CHANCE = 0.3,
    bombCntLastFrame = -1,
    keyCntLastFrame = -1,
}

function AscensionMod.a2:Init()
    AscensionMod.a2.downgradeRNG = RNG(AscensionMod.startSeed, RNG_SHIFT_INDEX)
end

function AscensionMod.a2:DowngradePickup()
    if AscensionMod.ascensionLevel < 2 then return end
    local entities = Isaac.GetRoomEntities()
    local rng = AscensionMod.a2.downgradeRNG
    for _, ent in pairs(entities) do
        if ent == nil then goto continue end

        local eType = ent.Type
        if eType ~= EntityType.ENTITY_PICKUP then goto continue end

        local eVariant = ent.Variant
        local eSubType = ent.SubType

        if eVariant == PickupVariant.PICKUP_HEART then
            local data = AscensionMod.SaveManager.GetNoRerollPickupSave(ent:ToPickup(), false)
            if data.triedDowngrade then goto continue end
            data.triedDowngrade = true
            if rng:RandomFloat() < AscensionMod.a2.HEART_DOWNGRADE_CHANCE then
                local downgradedSubType = AscensionMod.a2.HEART_DOWNGRADE[eSubType]
                if downgradedSubType == nil then goto continue end
                ent:ToPickup():Morph(eType, eVariant, downgradedSubType, true, true, false)
                -- set keepSeed to true to preserve saved data in the SaveManager
            end
        elseif eVariant == PickupVariant.PICKUP_BOMB then
            if eSubType ~= BombSubType.BOMB_DOUBLEPACK then goto continue end
            local data = AscensionMod.SaveManager.GetNoRerollPickupSave(ent:ToPickup(), false)
            if data.triedDowngrade then goto continue end
            data.triedDowngrade = true
            if rng:RandomFloat() < AscensionMod.a2.DOUBLEPACK_DOWNGRADE_CHANCE then
                local downgradedSubType = BombSubType.BOMB_NORMAL
                ent:ToPickup():Morph(eType, eVariant, downgradedSubType, true, true, false)
            end
        elseif eVariant == PickupVariant.PICKUP_KEY then
            if eSubType ~= KeySubType.KEY_DOUBLEPACK then goto continue end
            local data = AscensionMod.SaveManager.GetNoRerollPickupSave(ent:ToPickup(), false)
            if data.triedDowngrade then goto continue end
            data.triedDowngrade = true
            if rng:RandomFloat() < AscensionMod.a2.DOUBLEPACK_DOWNGRADE_CHANCE then
                local downgradedSubType = KeySubType.KEY_NORMAL
                ent:ToPickup():Morph(eType, eVariant, downgradedSubType, true, true, false)
            end
        elseif eVariant == PickupVariant.PICKUP_COIN then
            if eSubType ~= CoinSubType.COIN_DOUBLEPACK then goto continue end
            local data = AscensionMod.SaveManager.GetNoRerollPickupSave(ent:ToPickup(), false)
            if data.triedDowngrade then goto continue end
            data.triedDowngrade = true
            if rng:RandomFloat() < AscensionMod.a2.DOUBLEPACK_DOWNGRADE_CHANCE then
                local downgradedSubType = CoinSubType.COIN_PENNY
                ent:ToPickup():Morph(eType, eVariant, downgradedSubType, true, true, false)
            end
        end
        ::continue::
    end
end
AscensionMod:AddCallback(ModCallbacks.MC_POST_UPDATE, AscensionMod.a2.DowngradePickup)

---@param entPickup EntityPickup
function AscensionMod.a2:CountGoldenPickup(entPickup)
    if AscensionMod.ascensionLevel < 2 then return nil end
    if entPickup.Variant == PickupVariant.PICKUP_BOMB and entPickup.SubType == BombSubType.BOMB_GOLDEN then
        AscensionMod:GainStatusOnce('goldenBomb')
        scheduler:once(function ()
            local p0 = game:GetPlayer(0)
            p0:RemoveGoldenBomb()
        end, 1)
        return nil
    end
    if entPickup.Variant == PickupVariant.PICKUP_KEY and entPickup.SubType == KeySubType.KEY_GOLDEN then
        AscensionMod:GainStatusOnce('goldenKey')
        scheduler:once(function ()
            local p0 = game:GetPlayer(0)
            p0:RemoveGoldenKey()
        end, 1)
        return nil
    end
    return nil
end
AscensionMod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, AscensionMod.a2.CountGoldenPickup)

function AscensionMod.a2:CheckGoldenPickup()
    if AscensionMod.ascensionLevel < 2 then return end
    if AscensionMod.a9.lostPickupThisFrame then
        AscensionMod.a9.lostPickupThisFrame = false
        return
    end
    local p0 = game:GetPlayer(0)
    local bombCntThisFrame = p0:GetNumBombs()
    local keyCntThisFrame = p0:GetNumKeys()
    if AscensionMod.statusLevel.goldenBomb > 0 then
        if bombCntThisFrame == AscensionMod.a2.bombCntLastFrame - 1 then
            p0:AddBombs(1)
            if AscensionMod.gameRNG:RandomFloat() < AscensionMod.a2.GOLDEN_PICKUP_EXHAUST_CHANCE then
                AscensionMod.statusLevel.goldenBomb = AscensionMod.statusLevel.goldenBomb - 1
            end
        end
    end
    if AscensionMod.statusLevel.goldenKey > 0 then
        if keyCntThisFrame == AscensionMod.a2.keyCntLastFrame - 1 then
            p0:AddKeys(1)
            if AscensionMod.gameRNG:RandomFloat() < AscensionMod.a2.GOLDEN_PICKUP_EXHAUST_CHANCE then
                AscensionMod.statusLevel.goldenKey = AscensionMod.statusLevel.goldenKey - 1
            end
        end
    end
    AscensionMod.a2.bombCntLastFrame = bombCntThisFrame
    AscensionMod.a2.keyCntLastFrame = keyCntThisFrame
end
AscensionMod:AddCallback(ModCallbacks.MC_POST_UPDATE, AscensionMod.a2.CheckGoldenPickup)


------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------- 进阶 3 -----------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


AscensionMod.a3 = {
    STARTING_BROKEN_HEARTS = 8,
}

function AscensionMod.a3:Start()
    if AscensionMod.ascensionLevel < 3 then return end
    local p0 = game:GetPlayer(0)
    local pType = p0:GetPlayerType()
    if pType == PlayerType.PLAYER_KEEPER or pType == PlayerType.PLAYER_KEEPER_B then
        AscensionMod:AddStats(AscensionMod.statID.LUCK, -1)
        return
    end
    if pType == PlayerType.PLAYER_THEFORGOTTEN then
        p0:AddBrokenHearts(4)
        return
    end
    if pType == PlayerType.PLAYER_JACOB or pType == PlayerType.PLAYER_ESAU then
        p0:GetMainTwin():AddBrokenHearts(8)
        p0:GetOtherTwin():AddBrokenHearts(8)
        return
    end
    p0:AddBrokenHearts(8)
    if pType == PlayerType.PLAYER_THELOST or pType == PlayerType.PLAYER_THELOST_B then
        AscensionMod:AddStats(AscensionMod.statID.LUCK, -1)
    end
end


------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------- 进阶 4 -----------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


AscensionMod.a4 = {
    SS_SPECIAL = {[0] = true, [1] = true, [6] = true, [12] = true, [13] = true, [16] = true},
    SS_BLUE_FLY_CHANCE = 0.8,
    RED_HEART_ROT_CHANCE = 0.3,
}

function AscensionMod.a4:RotHeart()
    if AscensionMod.ascensionLevel < 4 then
        return
    end
    local entities = Isaac.GetRoomEntities()
    for _, ent in pairs(entities) do
        if ent == nil then goto continue end
        if ent.Type ~= EntityType.ENTITY_PICKUP then goto continue end
        if ent.Variant ~= PickupVariant.PICKUP_HEART then goto continue end
        if ent.FrameCount ~= 1 then goto continue end

        local level = game:GetLevel()
        local roomData = level:GetCurrentRoomDesc().Data
        local rType = roomData.Type
        local rVariant = roomData.Variant
        if rType == RoomType.ROOM_SUPERSECRET then
            if AscensionMod.a4.SS_SPECIAL[rVariant] then
                if AscensionMod.gameRNG:RandomFloat() < AscensionMod.a4.SS_BLUE_FLY_CHANCE then
                    Isaac.Spawn(EntityType.ENTITY_FAMILIAR, FamiliarVariant.BLUE_FLY, 2, ent.Position, Vector.Zero, nil)
                    ent:Remove()
                    goto continue
                end
            end
        end
        if ent.SubType == HeartSubType.HEART_FULL or ent.SubType == HeartSubType.HEART_HALF then
            if AscensionMod.gameRNG:RandomFloat() < AscensionMod.a4.RED_HEART_ROT_CHANCE then
                AscensionMod:SpawnPickupAt(PickupVariant.PICKUP_HEART, HeartSubType.HEART_ROTTEN, 1, 0, ent.Position)
                ent:Remove()
            end
        end
        ::continue::
    end
end
AscensionMod:AddCallback(ModCallbacks.MC_POST_UPDATE, AscensionMod.a4.RotHeart)


------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------- 进阶 6 -----------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


AscensionMod.a6 = {}

function AscensionMod.a6:Start()
    AscensionMod.a6:Backstab()
end

function AscensionMod.a6:Backstab()
    if AscensionMod.ascensionLevel < 6 then
        return
    end
    local p0 = game:GetPlayer(0)
    local hp = p0:GetHearts() / 2 + p0:GetSoulHearts() / 2
    local dmgFlags = DamageFlag.DAMAGE_NO_PENALTIES | DamageFlag.DAMAGE_NO_MODIFIERS
    if hp >= 3 then
        p0:TakeDamage(2, dmgFlags, EntityRef(p0), 0)
    elseif hp >= 2 then
        p0:TakeDamage(1, dmgFlags, EntityRef(p0), 0)
    end
end


------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------- 进阶 9 -----------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


AscensionMod.a9 = {
    KEEP_BOMB = 0.5,
    KEEP_KEY = 0.2,
    KEEP_COIN = 0.5,
    lostPickupThisFrame = false,
}

function AscensionMod.a9:LosePickup()
    if AscensionMod.ascensionLevel < 9 then return end
    local p0 = game:GetPlayer(0)
    local bombs = p0:GetNumBombs()
    p0:AddBombs(math.ceil(bombs * AscensionMod.a9.KEEP_BOMB))
    local keys = p0:GetNumKeys()
    p0:AddKeys(math.ceil(keys * AscensionMod.a9.KEEP_KEY))
    local coins = p0:GetNumCoins()
    p0:AddCoins(math.ceil(coins * AscensionMod.a9.KEEP_COIN))
    AscensionMod.a9.lostPickupThisFrame = true
end
AscensionMod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, AscensionMod.a9.LosePickup)


------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------- 进阶 12 -----------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


AscensionMod.a12 = {}
function AscensionMod.a12:Start()
    AscensionMod.a12:RangeDown()
end

function AscensionMod.a12:RangeDown()
    AscensionMod.playerStats.rangeMul = AscensionMod.playerStats.rangeMul * 0.2
    AscensionMod:AddStats(AscensionMod.statID.RANGE, 5)
end


------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------- 状态 -----------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------


AscensionMod.statusLevel = {
    malaise = 0,
    weakness = 0,
    discipline = 0,
    blessing = 0,
    luck = 0,
    range = 0,
    strength = 0,
    corruption = 0,
    unluck = 0,
    cataclysm = 0,
    goldenBomb = 0,
    goldenKey = 0,
}

AscensionMod.statusEventFn = {
    malaise = function ()
        local x = AscensionMod.statusLevel.malaise - 1
        local n = AscensionMod.stageCnt
        AscensionMod:AddStats(AscensionMod.statID.DMG, -(0.3 + 0.05 * n - math.min(x, 3) * 0.1))
        AscensionMod:AddStats(AscensionMod.statID.TEARS, -(0.2 + 0.03 * n - math.min(x, 2) * 0.1))
    end,
    weakness = function ()
        local x = AscensionMod.statusLevel.weakness - 1
        local n = AscensionMod.stageCnt
        AscensionMod:AddStats(AscensionMod.statID.DMG, -(0.5 + 0.1 * n - math.min(x, 2) * 0.2))
    end,
    luck = function ()
        local x = AscensionMod.statusLevel.luck - 1
        local p0 = game:GetPlayer(0)
        AscensionMod.playerStats.luckMul = AscensionMod.playerStats.luckMul * (1 + 0.2 - math.min(x, 3) * 0.05)
        p0:AddCacheFlags(CacheFlag.CACHE_RANGE, true)
    end,
    range = function ()
        local x = AscensionMod.statusLevel.range - 1
        local p0 = game:GetPlayer(0)
        AscensionMod.playerStats.rangeMul = AscensionMod.playerStats.rangeMul * (1 + 0.3 - math.min(x, 2) * 0.1)
        p0:AddCacheFlags(CacheFlag.CACHE_RANGE, true)
    end,
    strength = function ()
        local x = AscensionMod.statusLevel.strength - 1
        local n = AscensionMod.stageCnt
        AscensionMod:AddStats(AscensionMod.statID.DMG, (1.15 - x * 0.05) ^ n)
    end,
    corruption = function ()
        AscensionMod:SpawnPickup(PickupVariant.PICKUP_HEART, HeartSubType.HEART_BLACK, 1, 0)
        AscensionMod:SwallowTrinket(TrinketType.TRINKET_DAEMONS_TAIL, true)
        AscensionMod:SwallowTrinket(TrinketType.TRINKET_BLACK_FEATHER, true)
    end,
    unluck = function ()
        local x = AscensionMod.statusLevel.unluck - 1
        local p0 = game:GetPlayer(0)
        AscensionMod.playerStats.luckMul = AscensionMod.playerStats.luckMul * (1 - (0.2 - math.min(x, 3) * 0.05))
        p0:AddCacheFlags(CacheFlag.CACHE_LUCK, true)
    end,
}

function AscensionMod:ResetStatusLevels()
    AscensionMod.statusLevel = {
        malaise = 0,
        weakness = 0,
        discipline = 0,
        blessing = 0,
        luck = 0,
        range = 0,
        strength = 0,
        corruption = 0,
        unluck = 0,
        cataclysm = 0,
        goldenBomb = 0,
        goldenKey = 0,
    }
end

function AscensionMod:GainStatus(statusID, level)
    for _  = 1, level do
        AscensionMod.GainStatusOnce(statusID)
    end
end

function AscensionMod:GainStatusOnce(statusID)
    AscensionMod.statusLevel[statusID] = AscensionMod.statusLevel[statusID] + 1
    local eventFn = AscensionMod.statusEventFn[statusID]
    if eventFn ~= nil then eventFn() end
end