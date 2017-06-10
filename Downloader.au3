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
Global $AccessParam = "hello"

SelfCheckStart()

Func SelfCheckStart()
   If WinExists("TFC.tv Downloader") Then
	  WinActivate("TFC.tv Downloader")
   Else
	  WinStart()
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
			Download()
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

Func DownloadSelector($DownloadPath, $Filename)
   Local $BitRate = "2500000,1500000,1300000,1000000,800000,500000,300000,150000"
   Local $ListRes = "-,-hd-,-sd-,-ge-,ge-"
   Local $FileExt  = ",.mp4.csmil/master.m3u8?"

   Local $aBitRate = StringSplit($BitRate, ",")
   Local $aListRes = StringSplit($ListRes, ",")

   Local $reBitRate = 0

   For $i=1 To $aBitRate[0]
	  For $j=1 To $aListRes[0]
		 Local $DownloadURL = $DownloadPath & $aListRes[$j] & $aBitRate[$i] & $FileExt & $AccessParam
		 Local $DownloadFile = " -c copy -bsf:a aac_adtstoasc " & $Filename & ".mp4"
		 Local $DownloadConvert = $DownloadURL & $DownloadFile
		 RunWait(@ScriptDir & "/ffmpeg.exe -i" & $DownloadConvert, "", @SW_HIDE)
		 If FileExists(@ScriptDir & "/" & $Filename) Then
			Call("LogDisplay", "Downloaded: " & $Filename)
		 EndIf
	  Next
   Next
EndFunc

Func Download()
   Local $aDownloadList = IniReadSection(@ScriptDir & "/test.ini", "DownloadList"); read the list of file to download

   If Not FileExists(@ScriptDir & "/ffmpeg.exe") Then
	  MsgBox($MB_SYSTEMMODAL, "Error", "You need to download FFMPEG")
	  Exit
   EndIf

   If Not @error Then
	 For $i = 1 To $aDownloadList[0][0]
		 Local $FilePath = $aDownloadList[$i][0]
		 Local $FileName = $aDownloadList[$i][1]
		 Local $DownloadURL = "http://o1-i.akamaihd.net/i/" & $FilePath & "/" & $cDate & "/" & $cDate & "-" & $FileName
		 Local $DownloadedFile = $FileName & $cDate
		 Call("DownloadSelector", $DownloadURL, $DownloadedFile)
	 Next
   EndIf
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