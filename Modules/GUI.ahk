#Requires AutoHotkey v2.0

; ▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
; COLOR SCHEME - Modern Dark Theme
; ▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰

global COLORS := {
    ; Header - Rich gold
    headerBg:            "0xFFB84D",
    headerText:          "0x1a1a1a",

    ; Backgrounds
    bg:                  "0x0d1117",
    cardBg:              "0x161b22",
    inputBg:             "0x0d1117",

    ; Text
    text:                "0xe6edf3",
    textDim:             "0x7d8590",
    textBright:          "0xffffff",

    ; UI Elements
    divider:             "0x21262d",

    ; Status Colors
    success:             "0x3fb950",
    warning:             "0xd29922",
    danger:              "0xf85149",

    ; Buttons
    buttonPrimary:       "0xFFB84D",
    buttonPrimaryText:   "0x1a1a1a",
    buttonSecondary:     "0x21262d",
    buttonSecondaryText: "0xe6edf3",
    buttonDanger:        "0xda3633",
    buttonDangerText:    "0xffffff"
}

global RaidRunning           := false
global RaidGui               := ""
global InstructionsGui       := ""
global StatusGui             := ""
global privateServerLinkCode := ""
global statusLabel           := ""
global statusDetailLabel     := ""
global instructionsInput     := ""
global keybindInput          := ""

CreateRaidGui()
CreateInstructionsGui()
CreateStatusGui()
SetTimer(PositionAuxiliaryGuis, 500)

; ▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
; GUI INITIALIZATION
; ▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰

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
    RaidGui.Add("Text", "x0 y50 w400 Center BackgroundTrans", "AHK Vault  V1.0.0")

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

    RaidGui.SetFont("s9 c" SubStr(COLORS.buttonSecondaryText, 3), "Segoe UI")
    btnInstructions := RaidGui.AddButton("x20 y395 w360 h28", "⌘  Instructions + Keybinds")
    btnInstructions.OnEvent("Click", ToggleInstructionsGui)

    RaidGui.Show("w400 h440")
    PositionAuxiliaryGuis()
}

CreateInstructionsGui() {
    global InstructionsGui, instructionsInput, keybindInput

    InstructionsGui := Gui("+AlwaysOnTop +ToolWindow", "Instructions / Keybinds")
    InstructionsGui.BackColor := SubStr(COLORS.bg, 3)
    InstructionsGui.MarginX := 10
    InstructionsGui.MarginY := 10

    InstructionsGui.SetFont("s9 bold c" SubStr(COLORS.textBright, 3), "Segoe UI")
    InstructionsGui.Add("Text", "x10 y10", "Instructions")

    InstructionsGui.SetFont("s8 c" SubStr(COLORS.text, 3), "Segoe UI")
    instructionsInput := InstructionsGui.AddEdit(
        "x10 y30 w380 h100 Background" SubStr(COLORS.cardBg, 3) " c" SubStr(COLORS.text, 3),
        "- F1 = Start Macro`n- F2 = Stop Macro`n- Keep Roblox visible while macro runs")

    InstructionsGui.SetFont("s9 bold c" SubStr(COLORS.textBright, 3), "Segoe UI")
    InstructionsGui.Add("Text", "x10 y138", "Keybinds")

    InstructionsGui.SetFont("s8 c" SubStr(COLORS.text, 3), "Segoe UI")
    keybindInput := InstructionsGui.AddEdit(
        "x10 y158 w380 h100 Background" SubStr(COLORS.cardBg, 3) " c" SubStr(COLORS.text, 3),
        "F1 - Start Entire Raid Macro`nF2 - Stop Macro`nF3 - Exit App`nF4 - OCR Debug")

    InstructionsGui.Show("Hide w400 h270")
}

CreateStatusGui() {
    global StatusGui, statusLabel, statusDetailLabel

    StatusGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "Status HUD")
    StatusGui.BackColor := "0A1020"
    StatusGui.MarginX := 6
    StatusGui.MarginY := 4

    StatusGui.SetFont("s7 bold c7DD3FC", "Segoe UI")
    StatusGui.Add("Text", "x6 y4 w108 h14 BackgroundTrans", "STATUS HUD")

    StatusGui.SetFont("s10 bold cE2E8F0", "Segoe UI")
    statusLabel := StatusGui.Add("Text", "x8 y24 w104 h18 BackgroundTrans", "• Idle")

    StatusGui.SetFont("s6 c64748B", "Consolas")
    statusDetailLabel := StatusGui.Add("Text", "x8 y46 w104 h26 BackgroundTrans", ">>> READY")

    StatusGui.Show("w120 h80")
    PositionAuxiliaryGuis()
}

ToggleInstructionsGui(*) {
    global InstructionsGui

    if !InstructionsGui
        return

    if InstructionsGui.Visible
        InstructionsGui.Hide()
    else {
        InstructionsGui.Show("NoActivate")
        PositionAuxiliaryGuis()
    }
}

PositionAuxiliaryGuis(*) {
    global RaidGui, InstructionsGui, StatusGui

    robloxHwnd := WinExist("ahk_exe RobloxPlayerBeta.exe")
    if !robloxHwnd {
        if RaidGui
            RaidGui.Show("x10 y10 NoActivate")
        if InstructionsGui && InstructionsGui.Visible
            InstructionsGui.Show("x10 y458 NoActivate")
        if StatusGui
            StatusGui.Show("x10 y10 NoActivate")
        return
    }

    rbX := 0, rbY := 0, rbW := 0, rbH := 0
    WinGetPos(&rbX, &rbY, &rbW, &rbH, "ahk_id " robloxHwnd)

    raidW := 400, raidH := 440
    startX := rbX + rbW
    startY := rbY

    if (startX + raidW > A_ScreenWidth)
        startX := Max(0, A_ScreenWidth - raidW)

    if RaidGui
        RaidGui.Show("x" startX " y" startY " NoActivate")

    if InstructionsGui && InstructionsGui.Visible
        InstructionsGui.Show("x" startX " y" (startY + raidH + 8) " NoActivate")

    if StatusGui
        StatusGui.Show("x" rbX " y" rbY " NoActivate")
}

; ▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰
; GUI HANDLERS
; ▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰

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
