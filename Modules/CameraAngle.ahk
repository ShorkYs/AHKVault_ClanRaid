; Function to change the camera angle based on given x, y angles and distance
ChangeCameraAngle(ChangeCamAngleX, ChangeCamAngleY, CamAngleDistance) {
    ; Press and hold the right mouse button
    SendEvent "{RButton down}"

    ; Loop through the given distance and change the camera angle accordingly
    Loop CamAngleDistance {
        DllCall("mouse_event", "uint", 1, "int", ChangeCamAngleX, "int", ChangeCamAngleY, "uint", 0, "int", 0)
        Sleep(1)
    }

    ; Release the right mouse button
    SendEvent "{RButton up}"
}