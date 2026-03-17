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
    global RaidRunning

    UpdateStatus("Auto raid: entering room center")
    moveDirection("w", 950)
    Sleep 120

    currentRoom := 1
    while (RaidRunning && currentRoom < 10) {
        targetRoom := currentRoom + 1
        UpdateStatus("Room " currentRoom ": clearing for room " targetRoom " unlock")

        path := []
        posX := 0
        posY := 0

        unlocked := ClearRoomAndTrackPath(targetRoom, &path, &posX, &posY)
        if !RaidRunning
            return

        if unlocked {
            UpdateStatus("Room " targetRoom " unlocked, returning to center")
            ReverseTrackedPath(path)
            Sleep 120

            if (targetRoom < 10) {
                UpdateStatus("Advancing to room " targetRoom)
                moveDirection("w", 2000)
                Sleep 150
            }
            currentRoom := targetRoom
        }
        else {
            UpdateStatus("Unlock timeout in room " currentRoom ", retrying clear")
        }
    }

    if RaidRunning
        UpdateStatus("Reached room 10")
}

ClearRoomAndTrackPath(targetRoom, &path, &posX, &posY, maxClearMs := 90000) {
    global RaidRunning

    startedAt := A_TickCount
    while RaidRunning && (A_TickCount - startedAt < maxClearMs) {
        foundRoom := DetectUnlockedRoomPopup()
        if (foundRoom && foundRoom = targetRoom)
            return true

        step := PickRoomStep(posX, posY)
        if !IsObject(step)
            step := {dir: "s", dur: 180}

        if PerformTrackedStep(step.dir, step.dur, targetRoom, &path, &posX, &posY)
            return true

        Sleep 60
    }

    return false
}

PerformTrackedStep(dir, durationMs, targetRoom, &path, &posX, &posY) {
    global RaidRunning

    remaining := durationMs
    chunkMs := 120

    while (remaining > 0) {
        if !RaidRunning
            return false

        partMs := Min(chunkMs, remaining)
        moveDirection(dir, partMs)
        path.Push({dir: dir, dur: partMs})
        UpdateVirtualPosition(dir, partMs, &posX, &posY)

        foundRoom := DetectUnlockedRoomPopup()
        if (foundRoom && foundRoom = targetRoom)
            return true

        remaining -= partMs
        Sleep 15
    }

    return false
}

PickRoomStep(posX, posY, maxFromCenter := 2000) {
    candidates := []

    dur := Random(220, 700)

    if (posY + dur <= maxFromCenter)
        candidates.Push({dir: "w", dur: dur, weight: 1})
    if (posY - dur >= -maxFromCenter)
        candidates.Push({dir: "s", dur: dur, weight: 1})
    if (posX + dur <= maxFromCenter)
        candidates.Push({dir: "d", dur: dur, weight: 1})
    if (posX - dur >= -maxFromCenter)
        candidates.Push({dir: "a", dur: dur, weight: 1})

    if (posX > 1000)
        candidates.Push({dir: "a", dur: Random(250, 550), weight: 3})
    if (posX < -1000)
        candidates.Push({dir: "d", dur: Random(250, 550), weight: 3})
    if (posY > 1000)
        candidates.Push({dir: "s", dur: Random(250, 550), weight: 3})
    if (posY < -1000)
        candidates.Push({dir: "w", dur: Random(250, 550), weight: 3})

    if (candidates.Length = 0)
        return false

    weighted := []
    for _, cand in candidates {
        repeatCount := cand.HasOwnProp("weight") ? cand.weight : 1
        Loop repeatCount
            weighted.Push({dir: cand.dir, dur: cand.dur})
    }

    return weighted[Random(1, weighted.Length)]
}

UpdateVirtualPosition(dir, durationMs, &posX, &posY) {
    if (dir = "w")
        posY += durationMs
    else if (dir = "s")
        posY -= durationMs
    else if (dir = "d")
        posX += durationMs
    else if (dir = "a")
        posX -= durationMs
}

ReverseTrackedPath(path) {
    global RaidRunning

    loop path.Length {
        if !RaidRunning
            return

        idx := path.Length - A_Index + 1
        step := path[idx]
        moveDirection(OppositeDir(step.dir), step.dur)
        Sleep 10
    }
}

OppositeDir(dir) {
    if (dir = "w")
        return "s"
    if (dir = "s")
        return "w"
    if (dir = "a")
        return "d"
    if (dir = "d")
        return "a"
    return dir
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
            return
        if DetectUnlockedRoomPopup()
            return
        Sleep 300
    }
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
    global statusLabel, statusDetailLabel
    defaultTitle := (message = "") ? "Roblox" : "Roblox: "
    try WinSetTitle(defaultTitle message, "ahk_exe RobloxPlayerBeta.exe")
    try {
        if statusLabel
            statusLabel.Value := "• " (message = "" ? "Idle" : message)
        if statusDetailLabel
            statusDetailLabel.Value := ">>> " (message = "" ? "READY" : StrUpper(message))
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
    try PositionAuxiliaryGuis()
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
