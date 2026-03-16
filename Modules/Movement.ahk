#Requires AutoHotkey v2.0

moveDirection(moveKey, timeMs) {
    keys := StrSplit(moveKey)

    for key in keys
        hold .= "{" key " down}"

    loop 5
        Send hold

    Sleep timeMs

    for key in keys
        release .= "{" key " up}"
    
    loop 5
        Send release
}



Movetoevent(){
    updateStatus("Moving to Event")
    SendEvent "{click 101, 151}"
    Sleep 250
    SendEvent "{click 22, 167}"
    Sleep 4000
        SendEvent "{click 101, 151}"
    Sleep 250
    SendEvent "{click 22, 167}"
    Sleep 4000
    moveDirection("q", 91)
    Sleep 687
    moveDirection("a", 294)
    Sleep 831
    moveDirection("s", 577)
    Sleep 584
    moveDirection("s", 231)
    
}
Movetoraidzone(){
    moveDirection("q", 63)
    Sleep 450
    moveDirection("w", 1802)
    Sleep 102
    moveDirection("d", 195)
    Sleep 583
    moveDirection("w", 208)
}
