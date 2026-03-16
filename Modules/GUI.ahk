#Requires AutoHotkey v2.0

global COLORS := {
    headerBg:            "0xFFB84D",
    headerText:          "0x1a1a1a",
    bg:                  "0x0d1117",
    cardBg:              "0x161b22",
    inputBg:             "0x0d1117",
    text:                "0xe6edf3",
    textDim:             "0x7d8590",
    textBright:          "0xffffff",
    divider:             "0x21262d",
    success:             "0x3fb950",
    warning:             "0xd29922",
    danger:              "0xf85149",
    buttonPrimary:       "0xFFB84D",
    buttonPrimaryText:   "0x1a1a1a",
    buttonSecondary:     "0x21262d",
    buttonSecondaryText: "0xe6edf3",
    buttonDanger:        "0xda3633",
    buttonDangerText:    "0xffffff",
    hudBg:               "0x070b14",
    hudAccent:           "0x3d5afe"
}

global RaidRunning           := false
global RaidGui               := ""
global InstructionsGui       := ""
global StatusHudGui          := ""
global privateServerLinkCode := ""
global statusLabel           := ""
global statusHudMain         := ""
global statusHudLog          := ""

global LeprechaunCheckbox    := ""
global BossRoomCheckbox      := ""
global Room3BossCheckbox     := ""
global Room9BossCheckbox     := ""
global sleepTimeInput        := ""

global instruction1Edit      := ""
global instruction2Edit      := ""
global instruction3Edit      := ""
global keybind1Edit          := ""
global keybind2Edit          := ""
global keybind3Edit          := ""

CreateRaidGui()
CreateInstructionsGui()
CreateStatusHudGui()
SetTimer(RepositionAttachedGuis, 1000)

CreateRaidGui() {
    global RaidGui, privateServerLinkCode
    global LeprechaunCheckbox, BossRoomCheckbox, Room3BossCheckbox, Room9BossCheckbox, sleepTimeInput

    RaidGui := Gui("+AlwaysOnTop -MaximizeBox", "Raid Macro")
    RaidGui.BackColor := SubStr(COLORS.bg, 3)
    RaidGui.MarginX := 0
    RaidGui.MarginY := 0

    RaidGui.Add("Progress", "x0 y0 w400 h80 Background" SubStr(COLORS.headerBg, 3))

    RaidGui.SetFont("s18 bold c" SubStr(COLORS.headerText, 3), "Segoe UI")
    RaidGui.Add("Text", "x0 y15 w400 Center BackgroundTrans", "⚔️ Raid Macro")

    RaidGui.SetFont("s8 c" SubStr(COLORS.headerText, 3), "Segoe UI")
    RaidGui.Add("Text", "x0 y50 w400 Center BackgroundTrans", "AHK Vault  V1.1.0")

    RaidGui.SetFont("s10 bold c" SubStr(COLORS.textBright, 3), "Segoe UI")
    RaidGui.Add("Text", "x20 y95", "Server Settings")
    RaidGui.Add("Progress", "x20 y116 w360 h2 Background" SubStr(COLORS.divider, 3))

    RaidGui.SetFont("s9 c" SubStr(COLORS.textDim, 3), "Segoe UI")
    RaidGui.Add("Text", "x20 y124", "Private Server Code")

    privateServerLinkCode := RaidGui.AddEdit(
        "x20 y142 w360 h26 Background" SubStr(COLORS.cardBg, 3) " c" SubStr(COLORS.text, 3))

    RaidGui.SetFont("s10 bold c" SubStr(COLORS.textBright, 3), "Segoe UI")
    RaidGui.Add("Text", "x20 y182", "Raid Options")
    RaidGui.Add("Progress", "x20 y203 w360 h2 Background" SubStr(COLORS.divider, 3))

    RaidGui.SetFont("s9 c" SubStr(COLORS.textDim, 3), "Segoe UI")
    RaidGui.Add("Text", "x20 y211", "Boss Sleep Time (seconds)")

    sleepTimeInput := RaidGui.AddEdit(
        "x20 y228 w80 h26 Background" SubStr(COLORS.cardBg, 3) " c" SubStr(COLORS.text, 3), "5")

    RaidGui.SetFont("s9 c" SubStr(COLORS.text, 3), "Segoe UI")
    LeprechaunCheckbox := RaidGui.AddCheckBox(
        "x20 y264 w175 h22 c" SubStr(COLORS.text, 3) " Background" SubStr(COLORS.bg, 3),
        "Leprechaun Chest")
    BossRoomCheckbox := RaidGui.AddCheckBox(
        "x205 y264 w175 h22 c" SubStr(COLORS.text, 3) " Background" SubStr(COLORS.bg, 3),
        "Boss Room (lvl 15k+)")
    Room3BossCheckbox := RaidGui.AddCheckBox(
        "x20 y290 w175 h22 c" SubStr(COLORS.text, 3) " Background" SubStr(COLORS.bg, 3),
        "Room 3 Boss (lvl 500+)")
    Room9BossCheckbox := RaidGui.AddCheckBox(
        "x205 y290 w175 h22 c" SubStr(COLORS.text, 3) " Background" SubStr(COLORS.bg, 3),
        "Room 9 Boss (lvl 5k+)")

    RaidGui.SetFont("s10 bold c" SubStr(COLORS.textBright, 3), "Segoe UI")
    RaidGui.Add("Text", "x20 y326", "Controls")
    RaidGui.Add("Progress", "x20 y347 w360 h2 Background" SubStr(COLORS.divider, 3))

    RaidGui.SetFont("s9 bold c" SubStr(COLORS.buttonPrimaryText, 3), "Segoe UI")
    btnStart := RaidGui.AddButton("x20 y355 w110 h30", "▶  Start")
    btnStart.OnEvent("Click", StartRaidFromGui)

    RaidGui.SetFont("s9 c" SubStr(COLORS.buttonSecondaryText, 3), "Segoe UI")
    btnStop := RaidGui.AddButton("x140 y355 w110 h30", "■  Stop")
    btnStop.OnEvent("Click", StopRaidFromGui)

    RaidGui.SetFont("s9 c" SubStr(COLORS.buttonDangerText, 3), "Segoe UI")
    btnReconnect := RaidGui.AddButton("x260 y355 w120 h30", "↺  Reconnect")
    btnReconnect.OnEvent("Click", ReconnectFromGui)

    RaidGui.Show("w400 h400")
    PositionRaidGuiToRoblox()
}

CreateInstructionsGui() {
    global InstructionsGui, instruction1Edit, instruction2Edit, instruction3Edit
    global keybind1Edit, keybind2Edit, keybind3Edit

    InstructionsGui := Gui("+AlwaysOnTop -MaximizeBox", "Instructions & Keybinds")
    InstructionsGui.BackColor := SubStr(COLORS.bg, 3)
    InstructionsGui.MarginX := 12
    InstructionsGui.MarginY := 10

    InstructionsGui.SetFont("s10 bold c" SubStr(COLORS.textBright, 3), "Segoe UI")
    InstructionsGui.Add("Text", "x10 y8", "Instructions + Keybinds")
    InstructionsGui.Add("Progress", "x10 y30 w380 h2 Background" SubStr(COLORS.divider, 3))

    InstructionsGui.SetFont("s8 c" SubStr(COLORS.textDim, 3), "Segoe UI")
    InstructionsGui.Add("Text", "x10 y40 w260", "Instruction")
    InstructionsGui.Add("Text", "x280 y40 w100", "Keybind")

    y := 60
    instruction1Edit := InstructionsGui.AddEdit("x10 y" y " w260 h24 Background" SubStr(COLORS.cardBg, 3) " c" SubStr(COLORS.text, 3), "Start Raid")
    keybind1Edit := InstructionsGui.AddEdit("x280 y" y " w100 h24 Background" SubStr(COLORS.cardBg, 3) " c" SubStr(COLORS.text, 3), "F1")

    y += 34
    instruction2Edit := InstructionsGui.AddEdit("x10 y" y " w260 h24 Background" SubStr(COLORS.cardBg, 3) " c" SubStr(COLORS.text, 3), "Stop Raid")
    keybind2Edit := InstructionsGui.AddEdit("x280 y" y " w100 h24 Background" SubStr(COLORS.cardBg, 3) " c" SubStr(COLORS.text, 3), "F2")

    y += 34
    instruction3Edit := InstructionsGui.AddEdit("x10 y" y " w260 h24 Background" SubStr(COLORS.cardBg, 3) " c" SubStr(COLORS.text, 3), "Exit Script")
    keybind3Edit := InstructionsGui.AddEdit("x280 y" y " w100 h24 Background" SubStr(COLORS.cardBg, 3) " c" SubStr(COLORS.text, 3), "F3")

    InstructionsGui.SetFont("s8 c" SubStr(COLORS.textDim, 3), "Segoe UI")
    InstructionsGui.Add("Text", "x10 y172 w370", "Tip: You can edit these notes/keybind labels anytime.")

    InstructionsGui.Show("w400 h200")
    PositionInstructionsGuiBelowRaid()
}

CreateStatusHudGui() {
    global StatusHudGui, statusHudMain, statusHudLog

    StatusHudGui := Gui("+AlwaysOnTop -Caption +Border +ToolWindow", "Status HUD")
    StatusHudGui.BackColor := SubStr(COLORS.hudBg, 3)
    StatusHudGui.MarginX := 6
    StatusHudGui.MarginY := 4

    StatusHudGui.SetFont("s7 bold c" SubStr(COLORS.textBright, 3), "Segoe UI")
    StatusHudGui.Add("Text", "x6 y4 w108 h12 BackgroundTrans", "STATUS HUD")
    StatusHudGui.Add("Progress", "x4 y18 w112 h2 Background" SubStr(COLORS.hudAccent, 3))

    StatusHudGui.SetFont("s9 c" SubStr(COLORS.success, 3), "Segoe UI")
    statusHudMain := StatusHudGui.Add("Text", "x8 y24 w102 h16 BackgroundTrans", "• Idle")

    StatusHudGui.SetFont("s7 c" SubStr(COLORS.textDim, 3), "Consolas")
    statusHudLog := StatusHudGui.Add("Text", "x8 y44 w104 h30 BackgroundTrans", "ready")

    StatusHudGui.Show("w120 h80")
    PositionStatusHudToRoblox()
}

RepositionAttachedGuis(*) {
    PositionRaidGuiToRoblox()
    PositionInstructionsGuiBelowRaid()
    PositionStatusHudToRoblox()
}

PositionRaidGuiToRoblox() {
    global RaidGui

    if !RaidGui
        return

    rb := GetRobloxRect()
    if !rb
        return

    guiW := 400
    x := rb.x + rb.w + 12
    y := rb.y
    RaidGui.Show("x" x " y" y " w" guiW " h400 NoActivate")
}

PositionInstructionsGuiBelowRaid() {
    global RaidGui, InstructionsGui

    if (!RaidGui || !InstructionsGui)
        return

    rx := 0, ry := 0, rw := 0, rh := 0
    WinGetPos(&rx, &ry, &rw, &rh, "ahk_id " RaidGui.Hwnd)

    x := rx
    y := ry + rh + 10
    InstructionsGui.Show("x" x " y" y " w400 h200 NoActivate")
}

PositionStatusHudToRoblox() {
    global StatusHudGui

    if !StatusHudGui
        return

    rb := GetRobloxRect()
    if !rb
        return

    x := rb.x + 8
    y := rb.y + 8
    StatusHudGui.Show("x" x " y" y " w120 h80 NoActivate")
}

GetRobloxRect() {
    hwnd := WinExist("ahk_exe RobloxPlayerBeta.exe")
    if !hwnd
        return false

    x := 0, y := 0, w := 0, h := 0
    WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
    return {x: x, y: y, w: w, h: h}
}

StartRaidFromGui(*) {
    global RaidRunning
    RaidRunning := true
    updateStatus("Starting raid")
    RunRaidStart()
    StartRaidLoop()
}

StopRaidFromGui(*) {
    global RaidRunning
    RaidRunning := false
    updateStatus("Raid stopped")
}

ReconnectFromGui(*) {
    reconnectClient()
}
