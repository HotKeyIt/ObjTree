ObjTree(ByRef obj,Title:="ObjTree",Options:="+ReadOnly +Resize,Edit=-Wrap,GuiShow=w640 h480",ToolTip:=""){
	return new _ObjTree(obj,Title,Options,ToolTip)
}
Class _ObjTree {
	__New(ByRef obj, Title:="ObjTree",Options:="+ReadOnly +Resize,Edit=-Wrap,GuiShow=w640 h480",ToolTip:=""){
		If RegExMatch(Options,"i)^\s*([-\+]?ReadOnly)(\d+)?\s*$",option)
			Options:="+AlwaysOnTop +Resize,GuiShow=w640 h480",this.ReadOnly:=option.1,this.ReadOnlyLevel:=option.2
		else this.ReadOnly:="+ReadOnly"
		Loop Parse, Options, "`,", A_Space
		{
		 opt := Trim(SubStr(A_LoopField,1,InStr(A_LoopField,"=")-1))
		 If RegExMatch(A_LoopField,"i)([-\+]?ReadOnly)(\d+)?",option)
			this.ReadOnly:=option.1,this.ReadOnlyLevel:=option.2
		 If (InStr("Font,GuiShow,Edit",opt))
			%opt% := SubStr(A_LoopField,InStr(A_LoopField,"=") + 1,StrLen(A_LoopField))  
		 else GuiOptions:=RegExReplace(A_LoopField,"i)[-\+]?ReadOnly\s?")
		}
		this.Gui:=GuiCreate(GuiOptions,Title),	this.hwnd:=this.gui.hwnd
		,fun:=this.Close.Bind(this),	this.Gui.OnEvent("Close",fun) ;,	this.Gui.OnEvent("Escape",fun)
		if (Font)
			Gui.SetFont(SubStr(Font,1,Pos := InStr(Font,":") - 1),SubStr(Font,Pos + 2,StrLen(Font)))
		; Get Gui size
		if !RegExMatch(GuiShow,"\b[w]([0-9]+\b).*\b[h]([0-9]+\b)",size)
			size:=[640,480]
		; Get hwnd of new window
		this.Hwnd:=this.gui.hwnd,IsAHK_H:=this.IsAHK_H()
		; Apply Gui options and create Gui
		,this.Gui.AddButton("x0 y0 NoTab Hidden Default","Show/Expand Object")
		,TV:=this.TV:=this.Gui.AddTreeView("xs w" (size.1*0.3) " h" (size.2) " ys " (IsAHK_H?"aw1/3 ah":"") " +0x800 +ReadOnly")
		,LV:=this.LV:=this.Gui.AddListView("x+1 w" (size.1*0.7) " h" (size.2*0.5) " ys " (IsAHK_H?"aw2/3 ah1/2 ax1/3":"") " AltSubmit Checked " this.ReadOnly,"[IsObj] Key/Address|Value/Address| ItemID")
		,fun:=this.TVSelect.Bind(this,LV),	TV.OnEvent("ItemSelect",fun) ,LV.ModifyCol(3,"0")
		,fun:=this.LVSelect.Bind(this,TV),	LV.OnEvent("Click",fun)
		,fun:=this.LVDoubleClick.Bind(this,TV),	LV.OnEvent("DoubleClick",fun)
		,fun:=this.LVEdit.Bind(this,TV),	LV.OnEvent("ItemEdit",fun)
		,fun:=this.LVCheck.Bind(this,TV),	LV.OnEvent("ItemCheck",fun)
		,EditKey:=this.EditKey:=this.Gui.AddEdit("y+1 w" (size.1*0.7) " h" (size.2*0.11) (IsAHK_H?" axr aw2/3 ah1/5 ax1/3 ay1/2 +HScroll":"") " " this.ReadOnly)
		,EditKey.Enabled:=false,	fun:=this.EditKeyEdit.Bind(this,TV,LV),EditKey.OnEvent("Change",fun)
		,EditValue:=this.EditValue:=this.Gui.AddEdit("y+1 w" (size.1*0.7) " h" (size.2*0.39) (IsAHK_H?" axr aw2/3 ah3/10 ax1/3 ay1/5 +HScroll":"") " " this.ReadOnly)
		,EditValue.Enabled:=false,	fun:=this.EditValueEdit.Bind(this,TV,LV),EditValue.OnEvent("Change",fun)
		; Items will hold TV_Item <> Object relation
		,this.Items:={},	this.obj:=obj
		; Create Menus to be used for all ObjTree windows (ReadOnly windows have separate Menu)
		,fun:=this.TVExpandAll.Bind(this.TV),	Menu("ObjTree" (&this),"Add","E&xpand All",fun)
		,fun:=this.TVCollapseAll.Bind(this,this.TV),	Menu("ObjTree" (&this),"Add","C&ollapse All",fun)
		; Convert object to TreeView and create a clone for our object
		; Changes can be optionally saved when ObjTree is closed when -ReadOnly is used
		If (this.ReadOnly="-ReadOnly"){
			this.newObj:=this.CreateClone(obj),this.Items[newObj]:=0,this.TVAdd(this.newObj,0)
			; Add additional Menu items when not Readonly
			,Menu("ObjTree" (&this),"Add"),	fun:=this.TVInsert.Bind(this,this.TV),	Menu("ObjTree" (&this),"Add","&Insert",fun)
			,fun:=this.TVInsertChild.Bind(this,this.TV),	Menu("ObjTree" (&this),"Add","I&nsertChild",fun)
			,Menu("ObjTree" (&this),"Add"),	fun:=this.TVDelete.Bind(this,this.TV),	Menu("ObjTree" (&this),"Add","&Delete",fun)
		} else this.Items[this.newObj:=obj]:=0,this.TVAdd(obj,0)
		if !IsAHK_H{
			ObjTree_Attach(TV.hwnd,"w1/2 h")
			,ObjTree_Attach(LV.hwnd,"w1/2 h1/2 x1/2 y0")
			,ObjTree_Attach(EditKey.hwnd,"w2/2 h1/5 x1/3 y1/2")
			,ObjTree_Attach(EditValue.hwnd,"w2/2 h3/10 x1/3 y1/5")
		}
		this.Tooltip:=ToolTip,	fun:=this.TVContextMenu.Bind(this),		this.TV.OnEvent("ContextMenu",fun),		this.gui.Show(GuiShow)
		,this.WM_Notify:=this.Notify.Bind(this,TV),	OnMessage(78,this.WM_Notify) ;WM_NOTIFY
	}
	IsAHK_H() {   ; Written by SKAN, modified by HotKeyIt
		; www.autohotkey.com/forum/viewtopic.php?p=233188#233188  CD:24-Nov-2008 / LM:27-Oct-2010
		If FSz := DllCall("Version\GetFileVersionInfoSizeW", "Str",A_AhkPath, "UInt",0 ){
		VarSetCapacity( FVI, FSz, 0 ),DllCall("Version\GetFileVersionInfoW", "Str",A_AhkPath, "UInt",0, "UInt",FSz, "PTR",&FVI )
		If DllCall( "Version\VerQueryValueW", "PTR",&FVI, "Str","\VarFileInfo\Translation", "PTR*",Transl, "PTR",0 )
			&& (Trans:=format("{1:.8X}",NumGet(Transl+0,"UInt")))
			&& DllCall( "Version\VerQueryValueW", "PTR",&FVI, "Str","\StringFileInfo\" SubStr(Trans,-4) SubStr(Trans,1,4) "\FILEVERSION", "PTR*",InfoPtr, "UInt",0 )
			return !!InStr(StrGet(InfoPtr),"H")
		}
	}
	Notify(TV,wParam,lParam){
		static ToolTipText,TVN_GETINFOTIP := 0XFFFFFE70 - 14 - 0 ;TVN_FIRST := 0xfffffe70 / 0=Unicode
		/*
			ObjTree is also used to Monitor messages for TreeView: ObjeTree(obj=wParam,Title=lParam,Options=msg,ishwnd=hwnd)
			when ishwnd is a handle, this routine is taken
		*/
		
		; Check if this message is relevant
		If (NumGet(lParam,A_PtrSize*2,"Uint")!=TVN_GETINFOTIP)
			Return
		; HDR.Item contains the relevant TV_ID
		TV_Text:=TV.GetText(TV_Item:=NumGet(lParam+A_PtrSize*5,"PTR"))
		
		; Check if this GUI uses a ToolTip object that contains the information in same structure as the TreeView
		If ToolTipText:=this.ToolTip { ; Gui has own ToolTip object
			; following will resolve the item in ToolTip object
			object:=[TV_Text],item:=TV_Item
			While item:=TV.GetParent(item)
				object.Push(TV.GetText(item))
			; Resolve our item/value in ToolTip object
			While object.MaxIndex(){
				if !IsObject(ToolTipText){
					ToolTipText:=""
					break
				}
				ToolTipText:=ToolTipText[object.Pop()]
			}
			; Item is not an object and is not empty, display value in ToolTip
			If !IsObject(ToolTipText)&&ToolTipText!=""
				Return NumPut((ToolTipText.="",&ToolTipText),lParam+A_PtrSize*3,"PTR") ;HDR.pszText[""]:=&(ToolTipText.="")
			ToolTipText:=""
		}
		; Gui has no ToolTip object or item could not be resolved
		; Get the value of item and display in ToolTip
		; Check if Item is an object and if so, display first 20 keys (first 50 chars) and values (first 100 chars)
		object:=this.items[TV_Item,TV_Text]
		if !IsObject(object)
			ToolTipText:=object ""
		else If IsObject(object) && IsFunc(object)
			ToolTipText:="[Func]`t`t" object.Name "`nBuildIn:`t`t" object.IsBuiltIn "`nVariadic:`t" object.IsVariadic "`nMinParams:`t" object.MinParams "`nMaxParams:`t" object.MaxParams
		else
			for key,v in object
			{
				ToolTipText.=(ToolTipText?"`n":"") SubStr(key,1,50) (StrLen(key)>50?"...":"") " = " (IsObject(v)?"[Obj] ":SubStr(v,1,100) (StrLen(v)>100?"...":""))
				If (A_Index>20){
					ToolTipText.="`n..."
					break
				}
			}
		Return NumPut(&ToolTipText,lParam+A_PtrSize*3,"PTR") ;(HDR.pszText[""]:=&ToolTipText)
	}
	Close(){
		this.gui.Opt("+OwnDialogs")
		If this.changed && "Yes"=MsgBox("Do you want to save changes?",,4){
			for k,v in this.obj
				this.obj.Delete(k)
			for k,v in this.newObj
				this.obj[k]:=v
		}
		this.newObj:=""
		this.gui.destroy()
		OnMessage(78,this.WM_Notify,0)
	}
	TVContextMenu(TV,Item, IsRightClick){
		TV.Modify(Item)
		Menu "ObjTree" (&this),"Show"
	}
	CreateClone(obj){
		clone:=ObjClone(obj)
		for k,v in obj{
			If IsObject(v)
				clone[k]:=this.CreateClone(v)
		}
		Return clone
	}
	EditKeyEdit(TV,LV){
		static count:=0
		id:=LV.GetText(row:=LV.GetNext("Selected"),3)	,obj:=this.items[id],	key:=TV.GetText(id),	newkey:=this.EditKey.Value
		if newkey=key
			return
		If Obj.HasKey(newKey)
			Return (this.gui.Opt("+OwnDialogs"),this.EditValue.Text:=key,MsgBox("Key " newKey " already exists"))
		obj[newkey]:=obj[key],	obj.Delete(key),	TV.Modify(id,,newkey),	LV.Modify(row,,newkey)
		,TV.Modify(this.items[this.items[id]],"Sort"),	LV.ModifyCol(1,"Sort AutoHdr"),	this.changed:=1
	}
	EditValueEdit(TV,LV){
		this.changed:=1
		,this.items[TV.GetSelection(),LV.GetText(row:=LV.GetNext("Selected"))]:=value:=this.EditValue.Value
		,LV.Modify(Row,,,value)
	}
	TVAdd(obj,parent:=""){
		for k,v in obj
		{
			If (IsObject(v) && !this.Items.Haskey(v))
				this.Items[v]:=this.TV.Add(IsObject(k)?Chr(177) " " (&k):k,parent,"Sort"),this.Items[this.Items[v]]:=obj
				,this.TVAdd(v,this.Items[v])
			else
				this.Items[lastParent:=this.TV.Add(IsObject(k)?Chr(177) " " (&k):k,parent,"Sort")]:=obj
		}
	}
	TVExpandAll(Menu){
		this.Modify(item:=this.GetSelection(),"+Expand")
		if this.GetChild(item)
			While(item:=this.GetNext(item,"F")) && this.GetParent(item)
				this.Modify(item,"+Expand")
	}
	TVInsert(TV){
		this.gui.Opt("+OwnDialogs")
		Loop this.ReadOnlyLevel
			if !TV_Item:=TV.GetParent(TV_Item?TV_Item:TV.GetSelection())
				Return MsgBox("New Items can be inserted only from level " this.ReadOnlyLevel "!")
		if !parent:=TV.GetParent(obj:=TV.GetSelection())
			item:=this.newObj.Push(obj:=[]),this.items[obj]:=TV.Add(item,,"Sort"),this.items[this.items[obj]]:=obj
		else
			this.Items[item:=this.TV.Add(k:=this.Items[obj].Push(""),parent,"Sort")]:=this.Items[obj]
		this.changed:=1
	}
	TVInsertChild(TV){
		Loop this.ReadOnlyLevel-1
			if !TV_Item:=TV.GetParent(TV_Item?TV_Item:TV.GetSelection())
				Return MsgBox("New Items can be inserted only from level " this.ReadOnlyLevel "!")
		this.gui.Opt("+OwnDialogs")
		if !IsObject(v:=this.items[parent:=TV.GetSelection(),k:=TV.GetText(parent)]){
			if "Yes"=MsgBox(k " is not an object, would you like to convert it to object?",,4)
				this.Items[parent,k]:=obj:={(k):v},this.Items[obj]:=TV.Add(k,parent,"Sort")
			else Return
		} else
			this.Items[item:=TV.Add(this.Items[parent,k].Push(""),parent,"Sort")]:=this.Items[parent,k]
		this.changed:=1
	}
	TVDelete(TV){
		this.gui.Opt("+OwnDialogs")
		Loop this.ReadOnlyLevel
			if !TV_Item:=TV.GetParent(TV_Item?TV_Item:TV.GetSelection())
				Return MsgBox("New Items can be deleted only from level " this.ReadOnlyLevel "!")
		k:=TV.GetText(item:=TV.GetSelection())
		If "Yes"=MsgBox("Do you want to Delete " k,,4){
			If IsObject(this.items[item])
				this.TVDeepDelete(TV,item)
			else
				this.items.Delete(item),TV.Delete(item)
			this.changed:=1
		}
	}
	TVDeepDelete(TV,parent){
		If child:=TV.GetChild(parent){
			Loop {
				if TV.GetChild(child)
					this.TVDeepDelete(TV,child)
				this.items[parent].Delete(TV.GetText(child)),	this.items.Delete(this.items[child]),	this.items.Delete(child),	TV.Delete(child),	next:=TV.GetNext(child,"F")
				if TV.GetParent(next)!=parent
					return
				child:=next
			}
		} else 
			this.items[parent].Delete(TV.GetText(parent)),TV.Delete(parent),this.items.Delete(parent)
	}
	TVCollapseAll(TV,parent:=0){
		if parent="C&ollapse All"
			parent:=TV.GetSelection()
		If child:=TV.GetChild(parent)
			Loop {
				if TV.GetChild(child)
					this.TVCollapseAll(TV,child)
				next:=TV.GetNext(child,"F")
				if TV.GetParent(next)!=parent
					return TV.Modify(parent,"-Expand")
				child:=next
			}
	}
	TVSelect(LV,TV,item){
		this.LV.Delete(),	this.EditValue.Text:="",	this.EditValue.Enabled:=false	,text:=TV.GetText(item),	TV.Modify(item,"Select")
		if !TV.Getparent(item)
			obj:=this.newObj,next:=item:=0
		else obj:=this.items[item],next:=item:=TV.GetParent(item)
		Loop this.ReadOnlyLevel
			if !TV_Item:=TV.GetParent(TV_Item?TV_Item:TV.GetSelection())
				ReadOnly:=1
		Loop {
			While item:=TV.GetNext(item,"Full")
				if next=TV.GetParent(item)
					break
			if item=0||TV.GetParent(item)!=next
				break
			k:=TV.GetText(item),v:=obj[k]
			LV.Add(((IsObject(v)||IsObject(k))?"Check":"") (text=(IsObject(k)?(Chr(177) " " (&k)):k)?(LV_CurrRow:=A_Index," Select"):"")
						,IsObject(k)?(Chr(177) " " (&k)):k,IsObject(v) && IsFunc(v)?"[" (v.IsBuiltIn?"BuildIn ":"") (v.IsVariadic?"Variadic ":"") "Func] " v.Name:IsObject(v)?(Chr(177) " " (&v)):v,item)
			If (LV_CurrRow=A_Index)
				LV.Modify(LV_CurrRow,"Vis Select"),	this.EditValue.Enabled:=!IsObject(v)&&!ReadOnly,	this.EditValue.Text:=v,	this.EditKey.Enabled:=!IsObject(k)&&!ReadOnly,	this.EditKey.Text:=k
		}
		Loop 2
			LV.ModifyCol(A_Index,"AutoHdr") ;autofit contents
	}
	LVCheck(TV,LV,item){
		if LV.GetCount()<item
			return
		LV.Modify(LV.GetNext("Selected"),"-Select"),	LV.Modify(item,"Select"),	this.LVSelect(TV,LV,item),	LV.Modify(item,(TV.GetChild(LV.GetText(item,3))?"":"-") "Check")
	}
	LVEdit(TV,LV,item){
		id:=LV.GetText(item,3)	,obj:=this.items[id],	key:=TV.GetText(id),	newkey:=LV.GetText(item)
		Loop this.ReadOnlyLevel
			if !TV_Item:=TV.GetParent(TV_Item?TV_Item:TV.GetSelection())
				Return (this.gui.Opt("+OwnDialogs"),LV.Modify(item,,key),MsgBox("New Items can be edited only from level " this.ReadOnlyLevel "!"))
		If Obj.HasKey(newKey)
			Return (this.gui.Opt("+OwnDialogs"),LV.Modify(item,,key),MsgBox("Key " newKey " already exists"))
		obj[newkey]:=obj[key],	obj.Delete(key),	TV.Modify(id,,newkey),	TV.Modify(this.items[this.items[id]],"Sort"),	LV.ModifyCol(1,"Sort")
		,this.EditKey.Text:=newkey,	this.changed:=1
	}
	LVSelect(TV,LV,item){
		if LV.GetCount()<item
			return
		TV.Modify(id:=LV.GetText(item,3),"Select")
		Loop this.ReadOnlyLevel
			if !TV_Item:=TV.GetParent(TV_Item?TV_Item:TV.GetSelection())
				ReadOnly:=1
		this.EditKey.Enabled:=!ReadOnly,	this.EditKey.Text:=LV.GetText(item)
		if !IsObject(this.items[id,LV.GetText(item)]){
			this.EditValue.Enabled:=!ReadOnly,	this.EditValue.Text:=this.items[id,LV.GetText(item)]
		} else this.EditValue.Text:="",this.EditValue.Enabled:=false
	}
	LVDoubleClick(TV,LV){
		if IsObject(value:=this.items[TV.GetSelection(),key:=LV.GetText(LV.GetNext("Selected"))])
			TV.Modify(item:=this.items[value],"+Expand Select"),(item:=TV.GetChild(item))?this.TVSelect(LV,TV,item):(this.gui.Opt("+OwnDialogs"),MsgBox("Object `"" key "`" is empty!"))
	}
}