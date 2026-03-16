#Requires AutoHotkey v2.0
#singleinstance force 
#NoTrayIcon
#Include "%A_ScriptDir%\Modules"
#include Movement.ahk
#include PixelSearchStuff.ahk
#Include <OCR>
#Include <Pin>
#include reconnect.ahk
#include GUI.ahk
WHITE_TRANSITION_SCREEN := {x: 689, y: 101,  colour: "0x070711 "}

global RaidRunning := false
global LastDetectedRoom := ""
global CurrentRoomCenter := false
global RAID_ROOM_BORDER_COLOR := 0xFFFFFF
global RAID_ROOM_BORDER_VARIATION := 35

f1::{
    StartEntireRaidMacro()
}
StartEntireRaidMacro() {
    global RaidRunning
    RaidRunning := true
    RunRaidStart()
    StartRaidLoop()
}

f2::{
    RaidRunning := false
    UpdateStatus("Raid stopped")
}

StartRaidRoutine() {
    global RaidRunning
    if !RaidRunning
        return
    RunRaidStart()
    StartRaidLoop()
}

RunRaidStart() {
    resizeRobloxWindow()
    activateRoblox()
    Movetoevent()

    waitForWhiteScreen()
    waitForNonWhiteScreen()
    UpdateStatus("Inside the event room, moving to raid zone")

    Movetoraidzone()

    if DetectRoom10Text() {
        SendEvent "{Click 350, 443}"
    }
    else {
        UpdateStatus("Create raid not found")
    }

    SendEvent "{W down}"
    waitForWhiteScreen()
    SendEvent "{W up}"
    waitForNonWhiteScreen()

    UpdateStatus("Inside raid, starting auto movement")
    RunAutoRaid()
}

RunAutoRaid() {
    global RaidRunning, CurrentRoomCenter

    UpdateStatus("Auto raid: pressing Q")
    SendEvent "{q}"
    Sleep 1000

    UpdateStatus("Auto raid: entering room flow")
    moveDirection("w", 1200)
    Sleep 300

    loop 12 {
        if !RaidRunning
            return

        center := DetectCurrentRoomCenter()
        if center {
            CurrentRoomCenter := center
            UpdateStatus("Room center detected at " center.x "," center.y)
            SweepCurrentRoomFromCenter(center)
        } else {
            UpdateStatus("Room border not detected, using fallback sweep")
            FallbackRoomSweep()
        }

        UpdateStatus("Waiting for room unlock...")
        unlockedRoom := WaitForRoomUnlock()
        if !unlockedRoom {
            UpdateStatus("No unlock detected, exiting auto raid loop")
            break
        }

        UpdateStatus("Unlocked room " unlockedRoom)
        if (unlockedRoom = "10")
            break

        ProceedToNextRoomFromCenter()
        Sleep 400
    }

    UpdateStatus("Auto raid movement complete, monitoring...")
}

SweepCurrentRoomFromCenter(center) {
    global RaidRunning

    routes := [
        {key: "w",  ms: 850},
        {key: "d",  ms: 850},
        {key: "s",  ms: 850},
        {key: "a",  ms: 850},
        {key: "wd", ms: 900},
        {key: "sd", ms: 900},
        {key: "sa", ms: 900},
        {key: "wa", ms: 900}
    ]

    for _, route in routes {
        if !RaidRunning
            return

        returnPath := []
        MoveAndRememberStep(route, &returnPath)
        Sleep 100
        ReturnByPath(returnPath)
        Sleep 120
    }
}

FallbackRoomSweep() {
    global RaidRunning

    fallbackRoutes := [
        {key: "w", ms: 700},
        {key: "d", ms: 650},
        {key: "s", ms: 700},
        {key: "a", ms: 650}
    ]

    for _, route in fallbackRoutes {
        if !RaidRunning
            return

        returnPath := []
        MoveAndRememberStep(route, &returnPath)
        Sleep 80
        ReturnByPath(returnPath)
        Sleep 100
    }
}

MoveAndRememberStep(step, &returnPath) {
    moveDirection(step.key, step.ms)
    returnPath.Push({key: InverseMoveKey(step.key), ms: step.ms})
}

ReturnByPath(returnPath) {
    Loop returnPath.Length {
        i := returnPath.Length - A_Index + 1
        step := returnPath[i]
        moveDirection(step.key, step.ms)
    }
}

InverseMoveKey(keyString) {
    inverse := ""
    for key in StrSplit(keyString) {
        switch key {
            case "w": inverse .= "s"
            case "s": inverse .= "w"
            case "a": inverse .= "d"
            case "d": inverse .= "a"
            default: inverse .= key
        }
    }
    return inverse
}

ProceedToNextRoomFromCenter() {
    moveDirection("w", 1450)
}

DetectCurrentRoomCenter() {
    global RAID_ROOM_BORDER_COLOR, RAID_ROOM_BORDER_VARIATION

    rect := GetRobloxClientRect()
    if !rect
        return false

    left := rect.x + 85
    right := rect.x + rect.w - 45
    top := rect.y + 45
    bottom := rect.y + rect.h - 95

    minX := 99999
    maxX := -1
    minY := 99999
    maxY := -1
    found := false

    rowSamples := 28
    Loop rowSamples {
        y := top + Floor((A_Index - 1) * (bottom - top) / (rowSamples - 1))

        if PixelSearch(&x1, &y1, left, y, right, y, RAID_ROOM_BORDER_COLOR, RAID_ROOM_BORDER_VARIATION) {
            found := true
            minX := Min(minX, x1)
            maxX := Max(maxX, x1)
            minY := Min(minY, y)
            maxY := Max(maxY, y)
        }

        if PixelSearch(&x2, &y2, right, y, left, y, RAID_ROOM_BORDER_COLOR, RAID_ROOM_BORDER_VARIATION) {
            found := true
            minX := Min(minX, x2)
            maxX := Max(maxX, x2)
            minY := Min(minY, y)
            maxY := Max(maxY, y)
        }
    }

    colSamples := 18
    Loop colSamples {
        x := left + Floor((A_Index - 1) * (right - left) / (colSamples - 1))

        if PixelSearch(&x3, &y3, x, top, x, bottom, RAID_ROOM_BORDER_COLOR, RAID_ROOM_BORDER_VARIATION) {
            found := true
            minX := Min(minX, x)
            maxX := Max(maxX, x)
            minY := Min(minY, y3)
            maxY := Max(maxY, y3)
        }

        if PixelSearch(&x4, &y4, x, bottom, x, top, RAID_ROOM_BORDER_COLOR, RAID_ROOM_BORDER_VARIATION) {
            found := true
            minX := Min(minX, x)
            maxX := Max(maxX, x)
            minY := Min(minY, y4)
            maxY := Max(maxY, y4)
        }
    }

    if !found
        return false

    return {
        x: Round((minX + maxX) / 2),
        y: Round((minY + maxY) / 2),
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY
    }
}

GetRobloxClientRect() {
    hwnd := WinExist("ahk_exe RobloxPlayerBeta.exe")
    if !hwnd
        return false

    x := 0, y := 0, w := 0, h := 0
    WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
    return {x: x, y: y, w: w, h: h}
}

WaitForDrasticColorChange(threshold := 30, maxSeconds := 60, sensitivity := 40) {
    global RaidRunning

    hwnd := WinExist("ahk_exe RobloxPlayerBeta.exe")
    if !hwnd
        return

    winX := 0, winY := 0, winW := 0, winH := 0
    WinGetPos(&winX, &winY, &winW, &winH, "ahk_id " hwnd)

    cols := 5, rows := 4
    samplePoints := []
    loop rows {
        r := A_Index
        loop cols {
            c := A_Index
            px := winX + (winW * c // (cols + 1))
            py := winY + (winH * r // (rows + 1))
            samplePoints.Push({x: px, y: py})
        }
    }

    baseline := []
    for pt in samplePoints {
        try
            baseline.Push(PixelGetColor(pt.x, pt.y))
        catch
            baseline.Push(0)
    }

    totalPixels := samplePoints.Length
    maxLoops := maxSeconds * (1000 // 100)

    loop maxLoops {
        if !RaidRunning
            return

        changedCount := 0
        for i, pt in samplePoints {
            try {
                current := PixelGetColor(pt.x, pt.y)
                base    := baseline[i]

                bR := (base    >> 16) & 0xFF
                bG := (base    >>  8) & 0xFF
                bB :=  base           & 0xFF
                cR := (current >> 16) & 0xFF
                cG := (current >>  8) & 0xFF
                cB :=  current        & 0xFF

                diff := Abs(cR - bR) + Abs(cG - bG) + Abs(cB - bB)
                if (diff > sensitivity * 3)
                    changedCount++
            }
        }

        pct := (changedCount / totalPixels) * 100
        UpdateStatus("Waiting for screen change... (" Round(pct) "% changed)")

        if (pct >= threshold)
            return

        Sleep 100
    }

    UpdateStatus("Screen change timeout — continuing anyway")
}

WaitForRoomUnlock() {
    global RaidRunning
    loop 400 {
        if !RaidRunning
            return false
        foundRoom := DetectUnlockedRoomPopup()
        if foundRoom
            return foundRoom
        Sleep 300
    }

    return false
}

WaitForSpecificRoom(targetRoom) {
    global RaidRunning
    loop 400 {
        if !RaidRunning
            return
        foundRoom := DetectUnlockedRoomPopup()
        if (foundRoom = targetRoom)
            return
        Sleep 300
    }
}

StartRaidLoop() {
    global RaidRunning, LastDetectedRoom

    LastDetectedRoom := ""

    loop {
        if !RaidRunning
            return

        if IsDisconnected() {
            UpdateStatus("Disconnect detected")
            reconnectClient()
            return
        }

        if DetectClanPointsPopup() {
            UpdateStatus("Final popup detected")
            HandleRaidCompletion()
            LastDetectedRoom := ""
            UpdateStatus("Back to monitoring popups")
            continue
        }

        foundRoom := DetectUnlockedRoomPopup()
        if (foundRoom && foundRoom != LastDetectedRoom) {
            LastDetectedRoom := foundRoom
            UpdateStatus("Unlocked room " foundRoom)
        }

        Sleep 300
    }
}

updateStatus(message, addToLog := true) {
    global statusLabel
    defaultTitle := (message = "") ? "Roblox" : "Roblox: "
    try WinSetTitle(defaultTitle message, "ahk_exe RobloxPlayerBeta.exe")
    try {
        if statusLabel
            statusLabel.Value := (message = "" ? "Idle" : message)
    }
}

activateRoblox() {
    try {
        WinActivate "ahk_exe RobloxPlayerBeta.exe"
    } catch {
        MsgBox "Roblox window not found.", , 16
        ExitApp
    }
    Sleep 100
}

resizeRobloxWindow() {
    updateStatus("Resizing the Roblox window")
    try {
        windowHandle := WinGetID("ahk_exe RobloxPlayerBeta.exe")
    } catch {
        MsgBox "Roblox window not found.", , 16
        ExitApp
    }
    WinActivate windowHandle
    WinRestore windowHandle
    WinMove , , A_ScreenWidth, 600, windowHandle
    WinMove , , 800, 600, windowHandle 
    updateStatus("")
}

isScreenWhite() {
    search := WHITE_TRANSITION_SCREEN
    return PixelSearch(&x, &y, search.x, search.y, search.x, search.y, search.colour, 2)
}

waitForWhiteScreen() {
    updateStatus("Waiting for black screen")
    maxLoops := 50
    loop maxLoops {
        updateStatus("Waiting for  black screen (" A_Index "/" maxLoops ")")
        if isScreenWhite()
            return true
        Sleep 1000
    }
    return false
}

waitForNonWhiteScreen() {
    updateStatus("Waiting for non- black screen")
    maxLoops := 50
    loop maxLoops {
        updateStatus("Waiting for non-black screen (" A_Index "/" maxLoops ")")
        if !isScreenWhite()
            return true
        Sleep 1000
    }
    return false
}

global ROOM_10_REGEX := "Who can join"

DetectRoom10Text() {
    global ROOM_10_REGEX

    hwnd := WinExist("ahk_exe RobloxPlayerBeta.exe")
    if !hwnd
        return false

    winX := 0, winY := 0, winW := 0, winH := 0
    WinGetPos(&winX, &winY, &winW, &winH, "ahk_id " hwnd)

    Loop 10
    {
        ocrResult := OCR.FromRect(winX, winY, winW, winH)
        text := ocrResult.Text
        text := StrLower(text)
        text := RegExReplace(text, "[^\w\s!]", "")
        text := RegExReplace(text, "\s+", " ")

        if RegExMatch(text, ROOM_10_REGEX) {
            UpdateStatus("Raid room found")
            return true
        }

        Sleep(120)
    }

    UpdateStatus("Raid room NOT found")
    reconnectClient()
    return false
}

global ROOM_UNLOCK_REGEX := "you\s*have\s*unlocked\s*room\s*(10|[2-9])"
global CLAN_POINTS_REGEX := "i)\bpoints?\s+for\s+your\s+clan\b"

DetectUnlockedRoomPopup() {
    global ROOM_UNLOCK_REGEX

    hwnd := WinExist("ahk_exe RobloxPlayerBeta.exe")
    if !hwnd
        return false

    rx := 225
    ry := 356
    rw := 562 - 225
    rh := 479 - 356

    winX := 0, winY := 0
    WinGetPos(&winX, &winY,,, "ahk_id " hwnd)

    x := winX + rx
    y := winY + ry

    ocrResult := OCR.FromRect(x, y, rw, rh)
    text := ocrResult.Text
    text := StrLower(text)
    text := RegExReplace(text, "[^\w\s!]", "")
    text := RegExReplace(text, "\s+", " ")

    if RegExMatch(text, ROOM_UNLOCK_REGEX, &match)
        return match[1]

    return false
}

DetectClanPointsPopup() {
    global CLAN_POINTS_REGEX

    hwnd := WinExist("ahk_exe RobloxPlayerBeta.exe")
    if !hwnd
        return false

    winX := 0, winY := 0, winW := 0, winH := 0
    WinGetPos(&winX, &winY, &winW, &winH, "ahk_id " hwnd)

    ocrResult := OCR.FromRect(winX, winY, winW, winH)
    text := ocrResult.Text
    text := StrLower(text)
    text := RegExReplace(text, "[^\w\s!]", "")
    text := RegExReplace(text, "\s+", " ")

    return RegExMatch(text, CLAN_POINTS_REGEX)
}

f3::ExitApp

f4::{
    hwnd := WinExist("ahk_exe RobloxPlayerBeta.exe")
    if !hwnd {
        MsgBox "Roblox window not found.", , 16
        return
    }

    winX := 0, winY := 0, winW := 0, winH := 0
    WinGetPos(&winX, &winY, &winW, &winH, "ahk_id " hwnd)

    ocrResult := OCR.FromRect(winX, winY, winW, winH)
    text := ocrResult.Text

    MsgBox text, "OCR - Roblox Window Text", 0
}

global DISCONNECT_REGEX := "(same account launched|you were disconnected|reconnect|leave|disconnected)"

IsDisconnected() {
    global DISCONNECT_REGEX

    hwnd := WinExist("ahk_exe RobloxPlayerBeta.exe")
    if !hwnd
        return true

    winX := 0, winY := 0, winW := 0, winH := 0
    WinGetPos(&winX, &winY, &winW, &winH, "ahk_id " hwnd)

    ocrResult := OCR.FromRect(winX, winY, winW, winH)
    text := ocrResult.Text
    text := StrLower(text)
    text := RegExReplace(text, "[^\w\s]", "")
    text := RegExReplace(text, "\s+", " ")

    return RegExMatch(text, DISCONNECT_REGEX) ? true : false
}

HandleRaidCompletion() {
    global LeprechaunCheckbox, BossRoomCheckbox, sleepTimeInput

    UpdateStatus("Handling raid completion")

    leprechaunEnabled := LeprechaunCheckbox.Value
    bossEnabled := BossRoomCheckbox.Value
    sleepSeconds := sleepTimeInput.Value

    if (leprechaunEnabled && !bossEnabled) {
        SendEvent "{q}"
        Sleep 1000
        moveDirection("w", 340)
        Sleep 836
        moveDirection("a", 231)
        Sleep 1000
        SendEvent "{E}"
        Sleep 500
    }
    else if (leprechaunEnabled && bossEnabled) {
        moveDirection("a", 1089)
        Sleep 420
        moveDirection("w", 1241)
        Sleep 4988
        SendEvent "{click 264, 275}"
        moveDirection("s", 903)
        Sleep 227
        moveDirection("d", 2730)
        Sleep 184
        moveDirection("s", 263)
        Sleep 111
        moveDirection("d", 519)
        Sleep 115
        SendEvent "{Click 231, 419}"
        Sleep 1235
        SendEvent "{Click 231, 419}"
        moveDirection("d", 3616)
        Sleep(sleepSeconds * 1000)
        moveDirection("d", 1206)
        Sleep 4242
        moveDirection("a", 7055)
        Sleep 221
        moveDirection("w", 935)
        Sleep 138
        moveDirection("a", 635)
        Sleep 172
        moveDirection("e", 115)
    }
    else if (bossEnabled && !leprechaunEnabled) {
        moveDirection("a", 1089)
        Sleep 420
        moveDirection("w", 1241)
        Sleep 4988
        SendEvent "{click 264, 275}"
        moveDirection("s", 903)
        Sleep 227
        moveDirection("d", 2730)
        Sleep 184
        moveDirection("s", 263)
        Sleep 111
        moveDirection("d", 519)
        Sleep 115
        SendEvent "{Click 231, 419}"
        Sleep 1235
        SendEvent "{Click 231, 419}"
        moveDirection("d", 3616)
        Sleep(sleepSeconds * 1000)
    }

    SendEvent "{Click 231, 419}"
    Sleep 500
    SendEvent "{Click 111, 335}"
    Sleep 500

    if !waitForWhiteScreen() {
        UpdateStatus("White screen missed, retrying button")
        SendEvent "{Click 111, 335}"
        Sleep 500
        SendEvent "{Click 231, 419}"
        Sleep 500
        SendEvent "{Click 111, 335}"
        Sleep 300

        if !waitForWhiteScreen() {
            UpdateStatus("Failed to detect white screen")
            return
        }
    }

    if !waitForNonWhiteScreen() {
        UpdateStatus("Failed to detect non-white screen")
        return
    }

    Sleep 1500
    UpdateStatus("Raid completion handled")
}
