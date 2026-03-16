#Requires AutoHotkey v2.0

getOcrResult(x1, y1, x2, y2, scale, object := false) {
    WinGetClientPos &clientX, &clientY, , , "ahk_exe RobloxPlayerBeta.exe"

    x1 += clientX
    y1 += clientY
    x2 += clientX
    y2 += clientY
    w := x2 - x1
    h := y2 - y1

    ocrBorder := Pin(x1, y1, x2, y2, 5000, "b1 flash0")  ; Draw a border around the OCR area.
    Sleep 100

    result := OCR.FromRect(x1, y1, w, h, , scale)

    ocrBorder.Destroy()

    if object
        return result
    else
        return result.Text
}



/*
getOcrResult(start, end, scale) {
    WinGetClientPos &windowTopLeftX, &windowTopLeftY, , , "ahk_exe RobloxPlayerBeta.exe"

    ocrStart := [start[1] + windowTopLeftX, start[2] + windowTopLeftY]
    ocrEnd := [end[1] + windowTopLeftX, end[2] + windowTopLeftY]
    ocrSize := [end[1] - start[1], end[2] - start[2]]

    ocrBorder := Pin(ocrStart[1], ocrStart[2], ocrEnd[1], ocrEnd[2], 100, "b1 flash0")  ; Draw a border around the OCR area.
    Sleep 100

    result := OCR.FromRect(ocrStart[1], ocrStart[2], ocrSize[1], ocrSize[2], , scale)

    ocrBorder.Destroy()

    return result.Text
}
*/