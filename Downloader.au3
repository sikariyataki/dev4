#include <Array.au3>
#include <AutoItConstants.au3>
#include <Date.au3>
#include <EditConstants.au3>
#include <InetConstants.au3>
#include <GUIConstantsEx.au3>
#include <MsgBoxConstants.au3>
#include <Process.au3>
#include <String.au3>
#include <WinAPIFiles.au3>
#include <WindowsConstants.au3>

Global $iDate = StringSplit(_NowDate(),"/")
Global $cDate = StringFormat("%04i%02i%02i",$iDate[3],$iDate[1],$iDate[2])

SelfCheckStart()

Func SelfCheckStart()
   If WinExists("TFC.tv Downloader") Then
	  WinActivate("TFC.tv Downloader")
   Else
	  WinStart()
   EndIf
EndFunc

Func CheckRequirements()
   If Not FileExists(@ScriptDir & "/z.ini") Then
	  MsgBox($MB_SYSTEMMODAL, "Error", "You need to download the INI file.")
	  Exit
   EndIf

   If Not FileExists(@ScriptDir & "/ffmpeg.exe") Then
	  MsgBox($MB_SYSTEMMODAL, "Error", "You need to download FFMPEG")
	  Exit
   EndIf
EndFunc

Func WinStart()
   Opt("GUICoordMode", 1)
   Opt("GUICloseOnESC", 0)
   $GUI = GUICreate("TFC.tv Downloader", 600, 300)
   GUISetState(@SW_SHOW)

   Local $Label1 = GUICtrlCreateLabel("Paste TFC.tv access parameter below:", 20, 20, 480, 20)
   Local $Label2 = GUICtrlCreateLabel("PinoyDev.org", 500, 265, 80, 20, 0x0002)
   GUICtrlSetFont($Label1, 14)
   GUICtrlSetFont($Label2, 9)
   Local $TextBox1 = GUICtrlCreateInput("", 20, 50, 480, 30 )
   GUICtrlSetFont($TextBox1, 12)
   Local $Button1 = GUICtrlCreateButton("Download", 510, 50, 70, 30)
   Local $Button2 = GUICtrlCreateButton("Update INI File", 20, 260, 100, 30)
   Local $Button3 = GUICtrlCreateButton("Download FFMPEG", 125, 260, 120, 30)
   Local $Combo1 = GUICtrlCreateCombo("",  250, 262, 100, 30)
   GUICtrlSetData($Combo1, "2500000|1500000|1300000|1000000|800000|500000|300000|150000","2500000")
   GUICtrlSetFont($Combo1, 12)
   Local $Combo2 = GUICtrlCreateCombo("",  360, 262, 70, 30)
   GUICtrlSetData($Combo2, "-|-sd-|-hd-","-hd-")
   GUICtrlSetFont($Combo2, 12)
   Local $Group1 = GUICtrlCreateGroup("Download Logs", 20, 90, 560, 160)
   GUICtrlSetFont($Group1, 10)
   GUIStartGroup()
   Global $Edit1 = GUICtrlCreateEdit("" & @CRLF, 25, 110, 550, 135)

   While 1
	  $UIEvent = GUIGetMsg()
	  Select
		 Case $UIEvent = $GUI_EVENT_CLOSE
			ExitLoop
		 Case $UIEvent = $Button1
			GUICtrlSetData($Edit1,"")
			Download(GUICtrlRead($TextBox1), GUICtrlRead($Combo1), GUICtrlRead($Combo2) )
		 Case $UIEvent = $Button2
			UpdateINIFile()
		 Case $UIEvent =$Label2
			ShellExecute("http://pinoydev.org")
	  EndSelect
   WEnd
EndFunc

Func LogDisplay($sTxt)
   GUICtrlSetData($Edit1, $sTxt, 1)
EndFunc

Func DownloadSelector($DownloadPath, $Filename, $AccessParam, $BitRate, $Res)
   Local $FileExt  = ",.mp4.csmil/master.m3u8?"

   Call("LogDisplay", "Downloading: " & $Filename & @CRLF)
   Local $FilenameExt = $Filename & ".mp4"
   Local $DownloadURL = $DownloadPath & $Res &  "," & $BitRate & $FileExt & $AccessParam
   Local $DownloadFile = " -c copy -bsf:a aac_adtstoasc " & '"' & $FilenameExt & '"'
   Local $DownloadConvert = '"' & $DownloadURL & '"' & $DownloadFile
   If Not FileExists(@ScriptDir & "\" & $FilenameExt) Then
	  ;ConsoleWrite(@ScriptDir & "\ffmpeg.exe -i " & $DownloadConvert & @CRLF)
	  RunWait(@ScriptDir & "\ffmpeg.exe -i " & $DownloadConvert, "", @SW_HIDE)
   EndIf
   If FileExists(@ScriptDir & "\" & $FilenameExt) Then
	  Call("LogDisplay", "Downloaded: " & $Filename & @CRLF)
   EndIf
EndFunc

Func Download($AccessParam, $BitRate, $Res)
   CheckRequirements()

   Local $aDownloadList = IniReadSection(@ScriptDir & "\z.ini", "DownloadList"); read the list of file to download

   If Not @error Then
	 For $i = 1 To $aDownloadList[0][0]
		 Local $FilePath = $aDownloadList[$i][0]
		 Local $FileName = $aDownloadList[$i][1]
		 Local $DownloadURL = "http://o1-i.akamaihd.net/i/" & $FilePath & "/" & $cDate & "/" & $cDate & "-" & $FileName
		 Local $DownloadedFile = $FileName & $cDate
		 Call("DownloadSelector", $DownloadURL, $DownloadedFile, $AccessParam, $BitRate, $Res)
	  Next
   EndIf
   Call("LogDisplay","Download completed!")
EndFunc


Func UpdateINIFile()
   Local $sFilePath = _WinAPI_GetTempFileName(@TempDir)
   Local $hDownload = InetGet("https://dev4.pinoydev.org/config.ini", $sFilePath, $INET_FORCERELOAD, $INET_DOWNLOADBACKGROUND)
   Do
	 Sleep(250)
   Until InetGetInfo($hDownload, $INET_DOWNLOADCOMPLETE)
   InetClose($hDownload)
   FileCopy($sFilePath, @ScriptDir &"\z.ini", $FC_OVERWRITE + $FC_CREATEPATH)
   FileDelete($sFilePath)
   MsgBox($MB_SYSTEMMODAL,"Response", "Update completed.")
EndFunc

Func FFMPEG()
   Local $sFilePath = _WinAPI_GetTempFileName(@TempDir)
   Local $hDownload = InetGet("https://dev4.pinoydev.org/ffmpeg.exe", $sFilePath, $INET_FORCERELOAD, $INET_DOWNLOADBACKGROUND)
   Do
	 Sleep(250)
   Until InetGetInfo($hDownload, $INET_DOWNLOADCOMPLETE)
   InetClose($hDownload)
   FileCopy($sFilePath, @ScriptDir &"\ffmpeg.exe", $FC_OVERWRITE + $FC_CREATEPATH)
   FileDelete($sFilePath)
   MsgBox($MB_SYSTEMMODAL,"Response", "Update completed.")
EndFunc
