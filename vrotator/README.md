```md
# PixelBot — Технические вопросы и ответы

## 1. Как аддон узнаёт кулдауны?

**Ответ:** `GetSpellCooldown()`

```lua
local startTime, duration = GetSpellCooldown("Mortal Strike")

-- Если кулдауна нет:
-- startTime = 0, duration = 0

-- Если на кулдауне:
-- startTime = GetTime() (когда начался CD)
-- duration = 10000 (10 секунд в миллисекундах)

-- Проверка "готов ли спелл":
local isReady = (startTime == 0) or (duration == 0)

-- Проверка "сколько осталось":
local remaining = 0
if startTime > 0 and duration > 0 then
    remaining = (startTime + duration - GetTime()) / 1000  -- в секундах
end
```

**Нюансы:**
- Возвращает время в **миллисекундах**
- Нужно вычислять `remaining = startTime + duration - GetTime()`
- Есть **GCD** (global cooldown) — отдельный кулдаун 1.5 сек

---

## 2. Как аддон узнаёт баффы/дебаффы?

**Ответ:** `UnitBuff()` / `UnitDebuff()`

```lua
-- Баффы на игроке (1-40 слоты):
for i = 1, 40 do
    local name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId = UnitBuff("player", i)
    if name then
        -- Бафф есть
        if name == "Sudden Death" then
            hasSuddenDeath = true
        end
    else
        break  -- Дальше пусто
    end
end

-- Дебаффы на цели:
for i = 1, 40 do
    local name = UnitDebuff("target", i)
    if name == "Rend" then
        targetHasRend = true
    end
end
```

**Нюансы:**
- Нужно итерировать **1-40 слотов** (или до `nil`)
- `UnitBuff("player", i)` — баффы на игроке
- `UnitDebuff("target", i)` — дебаффы на цели
- Можно проверять по **имени** или **spellId**

---

## 3. Как аддон узнаёт ресурсы (мана, ярость, энергия)?

**Ответ:** `UnitPower()`

```lua
-- Ярость (warrior):
local rage = UnitPower("player", 0)

-- Мана (mage, priest):
local mana = UnitPower("player", 0)
local manaPercent = mana / UnitPowerMax("player", 0) * 100

-- Энергия (rogue):
local energy = UnitPower("player", 3)

-- Фокус (hunter):
local focus = UnitPower("player", 2)

-- Руны (death knight):
local runes = UnitPower("player", 6)  -- 0-6 рун
local runeCooldowns = {}
for i = 1, 6 do
    local start, duration = GetRuneCooldown(i)
    runeCooldowns[i] = {start = start, duration = duration}
end

-- Сила рун (death knight):
local runicPower = UnitPower("player", 7)
```

**Нюансы:**
- Тип 0 = мана/ярость (зависит от класса)
- Тип 3 = энергия
- Тип 6 = руны (кол-во доступных)
- Тип 7 = сила рун (DK)

---

## 4. Как аддон узнаёт что спелл готов?

**Ответ:** `GetSpellCooldown()` + проверка GCD

```lua
-- Проверка кулдауна спелла:
local startTime, duration = GetSpellCooldown("Mortal Strike")
local isReady = (startTime == 0) or (duration == 0)

-- Проверка GCD (global cooldown):
local gcdStart, gcdDuration = GetSpellCooldown(61304)  -- GCD spell ID
-- ИЛИ:
local gcdStart, gcdDuration = GetSpellCooldown("Mortal Strike")
-- GCD показывается как кулдаун самого спелла

local isGCD = (gcdStart > 0) and (gcdDuration > 0)

-- Спелл готов если:
-- 1. Нет кулдауна на спелле
-- 2. Нет GCD (или GCD < 0.1 сек)
```

**Нюансы:**
- GCD = 1.5 сек (уменьшается от haste)
- Некоторые спеллы **не триггерят GCD** (например, тринкеты)
- Нужно проверять **и спелл CD, и GCD**

---

## 5. Как аддон узнаёт дистанцию до цели?

**Ответ:** `CheckInteractDistance()` — ограничено

```lua
-- Возвращает 1-5 или nil:
-- 1 = 5 ярдов (вплотную)
-- 2 = 8 ярдов
-- 3 = 11 ярдов
-- 4 = 28 ярдов
-- 5 = 33 ярда

local dist = CheckInteractDistance("target", 3)
if dist == 1 then
    -- Вплотную (< 5 ярдов)
elseif dist == 2 then
    -- < 8 ярдов
elseif dist == nil then
    -- > 33 ярдов или нет цели
end
```

**Нюансы:**
- **Нет точной дистанции** в Lua API
- Только 5 порогов (5, 8, 11, 28, 33 ярда)
- Для melee спеллов достаточно `dist == 1`
- Для ranged — проверить `dist ~= nil`

---

## 6. Как аддон узнаёт что цель атакуема?

**Ответ:** `UnitCanAttack()` + `UnitIsDeadOrGhost()`

```lua
-- Цель существует:
local targetExists = UnitExists("target")

-- Цель атакуема:
local canAttack = UnitCanAttack("player", "target")

-- Цель жива:
local isAlive = not UnitIsDeadOrGhost("target")

-- Цель в бою:
local inCombat = UnitAffectingCombat("player")

-- Комплексная проверка:
local validTarget = targetExists and canAttack and isAlive
```

**Нюансы:**
- `UnitExists("target")` — есть ли цель
- `UnitCanAttack("player", "target")` — могу ли атаковать
- `UnitIsDeadOrGhost("target")` — мертва ли цель
- `UnitIsFriend("player", "target")` — дружественная ли

---

## 7. Как аддон определяет приоритет спеллов?

**Ответ:** Жёсткий if-else в ротации

```lua
return function()
    -- Приоритет 1 (самый важный):
    if can_cast("Mortal Strike") then
        return {key = "1"}
    end
    
    -- Приоритет 2:
    if can_cast("Overpower") and hasBuff("Overpower!") then
        return {key = "2"}
    end
    
    -- Приоритет 3:
    if can_cast("Execute") and targetHP < 20 then
        return {key = "3"}
    end
    
    -- Нет действия:
    return nil
end
```

**Нюансы:**
- Порядок if-else = порядок приоритета
- Первый true = выполняется
- Можно добавить **приоритет числом** для гибкости:
```lua
return {key = "1", priority = 1}
return {key = "2", priority = 2}
```

---

## 8. Что если несколько условий?

**Ответ:** AND логика (все условия должны быть true)

```lua
return function()
    -- Условие 1 AND Условие 2 AND Условие 3:
    if can_cast("Execute") 
       and targetHP < 20 
       and rage >= 60 then
        return {key = "3"}
    end
    
    -- Можно усложнить (A И (B ИЛИ C)):
    if can_cast("Spell") 
       and (hasBuff("Buff1") or hasBuff("Buff2")) then
        return {key = "1"}
    end
end
```

**Нюансы:**
- Lua поддерживает `and`, `or`, `not`
- Можно комбинировать как угодно
- Главное — читаемость кода

---

## 9. Как бот понимает ЧТО нажимать?

**Ответ:** RGB пиксель = клавиша + модификаторы

```
R (0-255) = код клавиши (ASCII)
G (0-7) = модификаторы
B (255) = сигнал что это не мусор
```

**Коды клавиш:**
```
49 = '1', 50 = '2', ..., 48 = '0'
81 = 'q', 87 = 'w', 69 = 'e', 82 = 'r'
...
112 = 'f1', 113 = 'f2', ..., 123 = 'f12'
```

**Модификаторы:**
```
0 = нет
1 = SHIFT
2 = CTRL
3 = ALT
4 = CTRL+SHIFT
5 = CTRL+ALT
6 = ALT+SHIFT
7 = CTRL+ALT+SHIFT
```

**Пример:**
```
(49, 0, 255) = жми '1'
(49, 1, 255) = жми 'SHIFT+1'
(82, 2, 255) = жми 'CTRL+R'
(0, 0, 0) = ничего не жать
```

**Нюансы:**
- 255 клавиш (хватит с запасом)
- 8 комбинаций модификаторов
- B=255 = защита от ложных срабатываний

---

## 10. Как бот понимает КОГДА нажимать?

**Ответ:** 60 FPS опрос экрана

```python
while True:
    screen = capture_screen()  # ~5-10ms
    key, mods = read_signal_pixel(screen)  # ~1ms
    
    if key:
        press_key_with_modifiers(key, mods)  # ~1ms
    
    time.sleep(1/60)  # 16.6ms = 60 FPS
```

**Нюансы:**
- **Общая задержка:** 5-15ms (скриншот + обработка + ввод)
- **GCD = 1.5 сек** — бот не будет спамить быстрее
- Если пиксель горит **постоянно** — бот будет жать 60 раз/сек
- **Решение:** аддон должен гасить пиксель после нажатия (или бот должен ждать GCD)

---

## 11. Что если аддон не видит спелл на Action Bar?

**Ответ:** `GetActionInfo()` вернёт nil

```lua
for slot = 1, 12 do
    local actionType, id = GetActionInfo(slot)
    
    if actionType == nil then
        -- Пустой слот
    elseif actionType == "spell" then
        local spellName = GetSpellName(id, BOOKTYPE_SPELL)
        -- Спелл на баре
    else
        -- Макрос, предмет, маунт
    end
end
```

**Нюансы:**
- Спелл может быть в **книге** но не на **баре**
- Аддон должен проверять **оба места**
- Если спелл не на баре — **нельзя получить бинд**
- **Решение:** пользователь должен повесить спелл на бар

---

## 12. Как обрабатывать макросы?

**Ответ:** Парсить `/cast` из макроса

```lua
-- Получить текст макроса:
local macroText = GetMacroBody(macroIndex)

-- Парсить /cast:
local spellName = macroText:match("/cast%s+(.+)")
-- "Mortal Strike" из "/cast Mortal Strike"

-- Если макрос с условиями:
-- /cast [mod:ctrl] Spell1; Spell2
-- Нужно парсить сложнее
```

**Нюансы:**
- Макросы могут быть **сложными** (`[mod:ctrl]`, `[harm]`, итд)
- Один макрос может кастовать **разные спеллы**
- **Решение:** для макросов — отдельная логика или игнор

---

## 13. Как бот понимает что нажал?

**Ответ:** SendInput эмулирует нажатие

```python
def press_key_with_modifiers(key, modifiers):
    # Нажимаем модификаторы
    for mod in modifiers:
        key_down(MODIFIER_VK[mod])
    
    # Нажимаем основную клавишу
    key_down(VK_CODES[key])
    key_up(VK_CODES[key])
    
    # Отпускаем модификаторы
    for mod in reversed(modifiers):
        key_up(MODIFIER_VK[mod])
```

**Нюансы:**
- **WoW обрабатывает ввод** в следующем кадре
- **Задержка:** 1-2 кадра (16-33ms)
- Если бот жмёт **быстрее GCD** — WoW проигнорирует
- **Решение:** бот должен ждать ~100ms после нажатия

---

## 14. Что если игрок меняет бинды во время игры?

**Ответ:** Событие `ACTIONBAR_SLOT_CHANGED`

```lua
local frame = CreateFrame("Frame")
frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
frame:RegisterEvent("SPELLS_CHANGED")
frame:SetScript("OnEvent", function(self, event)
    if event == "ACTIONBAR_SLOT_CHANGED" then
        -- Пересканировать Action Bar
        addon:ScanActionBar()
    elseif event == "SPELLS_CHANGED" then
        -- Спеллы изменились (таланты, итд)
        addon:ScanActionBar()
    end
end)
```

**Нюансы:**
- Событие срабатывает при **изменении бара**
- Нужно **пересканировать** и обновить `spellToKey`
- Бот **не узнает** пока аддон не скажет
- **Решение:** аддон должен **мигнуть** пикселем "обновление"

---

## 15. Как тестировать/дебажить?

**Ответ:** Вывод в чат + логирование

```lua
-- Аддон пишет в чат:
print("[PixelBot] Mortal Strike -> 1 (CD: 0s)")
print("[PixelBot] Action: Mortal Strike (key: 1)")

-- Или в отдельный фрейм:
local debugFrame = CreateFrame("Frame", "PixelBotDebug", UIParent)
-- Рендерить текст поверх UI
```

```python
# Бот логирует:
import logging
logging.basicConfig(filename='pixelbot.log', level=logging.INFO)

logging.info(f"Сигнал: key={key}, mods={modifiers}")
logging.info(f"Нажато: {key} + {modifiers}")
```

**Нюансы:**
- Чат может **скроллиться**
- Лучше **отдельный debug фрейм** в UI
- Бот должен логировать **время, сигнал, действие**

---

## Итого

| Вопрос | Решение | Статус |
|--------|---------|--------|
| Кулдауны | `GetSpellCooldown()` | ✅ |
| Баффы/дебаффы | `UnitBuff()`, `UnitDebuff()` | ✅ |
| Ресурсы | `UnitPower()` | ✅ |
| Спелл готов | `GetSpellCooldown() == 0` | ✅ |
| Дистанция | `CheckInteractDistance()` (ограничено) | ⚠️ |
| Цель атакуема | `UnitCanAttack()`, `UnitExists()` | ✅ |
| Приоритет | If-else в ротации | ✅ |
| Несколько условий | `and`, `or`, `not` | ✅ |
| Что нажимать | RGB пиксель (клавиша + моды) | ✅ |
| Когда нажимать | 60 FPS опрос | ✅ |
| Спелл не на баре | `GetActionInfo()` = nil | ⚠️ |
| Макросы | Парсить `/cast` | ⚠️ |
| Бот нажал | SendInput | ✅ |
| Смена биндов | `ACTIONBAR_SLOT_CHANGED` | ✅ |
| Дебаг | Чат + логи | ✅ |
```
