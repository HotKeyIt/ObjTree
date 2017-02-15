; LV_SortArrow by Solar. http://www.autohotkey.com/forum/viewtopic.php?t=69642
; h = ListView handle
; c = 1 based index of the column
; d = Optional direction to set the arrow. "asc" or "up". "desc" or "down".
;#Include <_Struct>
LV_SortArrow(h, i,d:=""){
	static C:=Struct("UINT mask,int fmt,int cx,LPTSTR pszText,int cchTextMax,int iSubItem,int iImage,int iOrder,int cxMin,int cxDefault,int cxIdeal")
	static LVM_GETCOLUMN:=(A_IsUnicode?0x105f:0x1019),LVM_GETHEADER:=0x101f,HDM_GETITEMCOUNT:=0x1200,LVM_SETCOLUMN:=(A_IsUnicode?0x1060:0x101a)
   i -= 1 ; convert to 0 based index
   C.mask:=1,DllCall("SendMessage","UPTR",h,"uint",LVM_GETCOLUMN,"UPTR",i,"UPTR",C[""])
   If ((fmt:=C.fmt)&1024){
		If (d && d = "asc" || d = "up")
			Return
		C.fmt:=fmt&~1024|512,DllCall("SendMessage","UPTR",h,"uint",LVM_SETCOLUMN,"UPTR",i,"UPTR",C[""])
	} else if (fmt&512){	
		If (d && d = "desc" || d = "down")
			Return
		C.fmt:=fmt&~512|1024,DllCall("SendMessage","UPTR",h,"uint",LVM_SETCOLUMN,"UPTR",i,"UPTR",C[""])
	} else { ; no arrow set. check and remove arrow on other columns
		Loop % DllCall("SendMessage","UPTR",DllCall("SendMessage","UPTR",h,"uint",LVM_GETHEADER,"UPTR",0,"UPTR",0,"UPTR")
							,"uint",HDM_GETITEMCOUNT,"UPTR",0,"UPTR",0,"UPTR")
        If (A_Index - 1 != c) ; skip our new column that we already checked.
				DllCall("SendMessage","UPTR",h,"uint",LVM_GETCOLUMN,"UPTR",A_Index-1,"UPTR",C[""])
				,C.fmt:=C.fmt & ~1536
				,DllCall("SendMessage","UPTR",h,"uint",LVM_SETCOLUMN,"UPTR",A_Index-1,"UPTR",C[""])
		C.fmt:=C.fmt|(d && d = "desc" || d = "down" ? 512 : 1024),DllCall("SendMessage","UPTR",h,"uint",LVM_SETCOLUMN,"UPTR",i,"UPTR",C[""])
	}
}