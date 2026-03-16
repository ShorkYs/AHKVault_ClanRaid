#Requires AutoHotkey v2.0



reconnectClient(*) {
    deeplink := "roblox://placeID=8737899170"
    deeplink .= "&linkCode=" privateServerLinkCode.Value

    try
        Run deeplink
    catch
        return false
    
    UpdateStatus("Reconnecting client")
    activateRoblox()
    Sleep 25000
    UpdateStatus("Reconnect finished")

    if RaidRunning
        StartEntireRaidMacro()

    return true
}







