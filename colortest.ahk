; #IfWinExist, ahk_exe DunDefGame.exe

; Display_CreateWindowCapture(ByRef device, ByRef context, ByRef pixels, ByRef id = "") {		
	; if !id
		; WinGet, id, ID
	; device := DllCall("GetDC", UInt, id)
	; context := DllCall("gdi32.dll\CreateCompatibleDC", UInt, device)
	; WinGetPos, , , w, h, ahk_id %id%
	; pixels := DllCall("gdi32.dll\CreateCompatibleBitmap", UInt, device, Int, w, Int, h)
	; DllCall("gdi32.dll\SelectObject", UInt, context, UInt, pixels)
	; DllCall("PrintWindow", "UInt", id, UInt, context, UInt, 0)
; }

; Display_DeleteWindowCapture(ByRef device, ByRef context, ByRef pixels, ByRef id) {
	; DllCall("ReleaseDC", UInt, id, UInt, device)
	; DllCall("gdi32.dll\DeleteDC", UInt, context)
	; DllCall("gdi32.dll\DeleteObject", UInt, pixels)
; }

; Display_GetPixel(ByRef context, x, y) {
	; return DllCall("GetPixel", UInt, context, Int, x, Int, y)
; }	

; ;16762518 build
; ;790289
; ;11141016 victory
; ;328707 fail


; x::
	; ControlGet, DDid, Hwnd,,, ahk_exe DunDefGame.exe
	; device := ""
	; context := ""
	; pixels := ""
	; Display_CreateWindowCapture(device, context, pixels, %DDid%)
	; c := Display_GetPixel(context, 2452, 168)
	; Display_DeleteWindowCapture(device, context, pixels, %DDid%)
	; Tooltip, %c%
; return

#Include Gdip_All.ahk

x::
	ControlGet, DDId, Hwnd,,, ahk_exe DunDefGame.exe
	token := Gdip_Startup()
	bitmap := Gdip_BitmapFromHWND(DDId)
	color := Gdip_GetPixel(bitmap, (x-50), (y-50))
	Gdip_DisposeImage(bitmap)
	Gdip_Shutdown(token)
return

