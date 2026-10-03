VRT = VRT or {}

-- Скрытая служебная таблица кодов клавиш для перевода в ASCII / Virtual Key коды
local KeyCodes = {
    -- Цифры
    ["1"] = 49, ["2"] = 50, ["3"] = 51, ["4"] = 52, ["5"] = 53,
    ["6"] = 54, ["7"] = 55, ["8"] = 56, ["9"] = 57, ["0"] = 48,
    -- Буквы (Движок биндов WoW возвращает их капсом)
    ["A"] = 65, ["B"] = 66, ["C"] = 67, ["D"] = 68, ["E"] = 69, ["F"] = 70,
    ["G"] = 71, ["H"] = 72, ["I"] = 73, ["J"] = 74, ["K"] = 75, ["L"] = 76,
    ["M"] = 77, ["N"] = 78, ["O"] = 79, ["P"] = 80, ["Q"] = 81, ["R"] = 82,
    ["S"] = 83, ["T"] = 84, ["U"] = 85, ["V"] = 86, ["W"] = 87, ["X"] = 88,
    ["Y"] = 89, ["Z"] = 90,
    -- Функциональные
    ["F1"] = 112, ["F2"] = 113, ["F3"] = 114, ["F4"] = 115, ["F5"] = 116, ["F6"] = 117,
    ["F7"] = 118, ["F8"] = 119, ["F9"] = 120, ["F10"] = 121, ["F11"] = 122, ["F12"] = 123,
}

local lastLoggedBind = nil

-- Создаем графический фрейм для пикселя бота
local signalFrame = CreateFrame("Frame", "VR_SignalPixelFrame", UIParent)
signalFrame:SetSize(5, 5) -- Размер 5х5 пикселей
signalFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0) -- Впритык в верхний левый угол

-- Создаем текстуру внутри фрейма для заливки цветом
local signalTexture = signalFrame:CreateTexture(nil, "BACKGROUND")
signalTexture:SetAllPoints(signalFrame)
signalFrame.texture = signalTexture

-- Устанавливаем самый высокий приоритет отрисовки, чтобы фрейм не перекрывался картой или баффами
signalFrame:SetFrameStrata("TOOLTIP")

-- Функция прямой покраски пикселя (значения R, G, B от 0 до 255)
function VRT.SetSignalColor(r, g, b)
    local numR = tonumber(r) or 0
    local numG = tonumber(g) or 0
    local numB = tonumber(b) or 0
    
    signalFrame.texture:SetTexture(numR / 255, numG / 255, numB / 255, 1)
end

-- Функция парсинга бинда и отправки сигнала боту
function VRT.SendBindSignal(bindString)
    if not bindString or bindString == "NOT_BOUND" then
        VRT.SetSignalColor(0, 0, 0)
        lastLoggedBind = nil
        VRT.Log("Bind not found: " .. bindString)
        return
    end

    -- Флаги модификаторов
    local hasShift = string.match(bindString, "SHIFT%-") and 1 or 0
    local hasCtrl  = string.match(bindString, "CTRL%-") and 1 or 0
    local hasAlt   = string.match(bindString, "ALT%-") and 1 or 0

    -- Вырезаем саму основную клавишу (всё, что после последнего дефиса)
    local mainKey = string.match(bindString, "([^-]+)$")
    local keyCode = KeyCodes[mainKey]

    -- Если клавиша не поддерживается нашей базой, тушим пиксель
    if not keyCode then
        VRT.SetSignalColor(0, 0, 0)
        VRT.Log("No keyCode for: " .. bindString)
        return
    end

    -- Кодируем модификаторы в значение Зеленого канала (0-7)
    -- 0=нет, 1=SHIFT, 2=CTRL, 3=ALT, 4=CTRL+SHIFT, 5=CTRL+ALT, 6=ALT+SHIFT, 7=CTRL+ALT+SHIFT
    local modifierCode = 0
    if hasShift == 1 and hasCtrl == 0 and hasAlt == 0 then modifierCode = 1 end
    if hasShift == 0 and hasCtrl == 1 and hasAlt == 0 then modifierCode = 2 end
    if hasShift == 0 and hasCtrl == 0 and hasAlt == 1 then modifierCode = 3 end
    if hasShift == 1 and hasCtrl == 1 and hasAlt == 0 then modifierCode = 4 end
    if hasShift == 0 and hasCtrl == 1 and hasAlt == 1 then modifierCode = 5 end
    if hasShift == 1 and hasCtrl == 0 and hasAlt == 1 then modifierCode = 6 end
    if hasShift == 1 and hasCtrl == 1 and hasAlt == 1 then modifierCode = 7 end

    ----------------------------------------------------
    -- БЛОК ЛОГИРОВАНИЯ В ЧАТ
    ----------------------------------------------------
    -- Собираем понятную строку модификаторов для текста
    local modText = ""
    if hasCtrl == 1 then modText = modText .. "CTRL+" end
    if hasAlt == 1 then modText = modText .. "ALT+" end
    if hasShift == 1 then modText = modText .. "SHIFT+" end
    
    -- Выводим лог: Текст бинда, RGB цвет пикселя и расшифровку клавиш
    VRT.Log(string.format(
        "Send: |cffffffff%s|r |cff888888->|r RGB(%d, %d, 255) |cff888888->|r Press: |cff00ff00%s%s|r", 
        bindString, keyCode, modifierCode, modText, mainKey
    ))
    
    -- Запоминаем последний лог
    lastLoggedBind = bindString
    ----------------------------------------------------

    -- Красим: R = код клавиши, G = код модификаторов, B = 255 (сигнал валиден)
    VRT.SetSignalColor(keyCode, modifierCode, 255)
end

-- По умолчанию при загрузке аддона тушим пиксель в черный цвет
VRT.SetSignalColor(0, 0, 0)
