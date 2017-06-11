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

Global $WriteLog, $CurrentVersion = 1
Global $aDate = StringSplit(_Now(), "/")
Global $cDate = StringFormat("%04i%02i%02i",$aDate[3],$aDate[1],$aDate[2])
Global $StreamURL = "http://o1-i.akamaihd.net/i/"
Global $StreamExt = ",.mp4.csmil/master.m3u8?"
Global $defaultBitrate = "150000,300000,500000,800000,1000000,1300000,1500000,2500000"

SelfCheckStart()

Func WinStart()
   Opt("GUICoordMode", 1)
   Opt("GUICloseOnESC", 0)
   $GUI = GUICreate("TFC.tv Downloader", 600, 300)
   GUISetState(@SW_SHOW)

   Local $Label1 = GUICtrlCreateLabel("Paste TFC.tv access parameter below:", 20, 20, 480, 20)
   Local $Label2 = GUICtrlCreateLabel("PinoyDev.org", 500, 265, 80, 20, 0x0002)
   Local $TextBox1 = GUICtrlCreateInput("", 20, 50, 480, 30 )
   Local $BtnDownload = GUICtrlCreateButton("Download", 510, 50, 70, 30)
   Local $BtnINI = GUICtrlCreateButton("Update INI File", 20, 260, 100, 30)
   Local $BtnFFMPEG = GUICtrlCreateButton("Download FFMPEG", 125, 260, 120, 30)
   Local $sFile = GUICtrlCreateCombo("Select file to download",  400, 100, 180, 30)
   Local $sDate = GUICtrlCreateDate("", 470, 140, 110, 30, $DTS_SHORTDATEFORMAT)
   Local $iBitrate = GUICtrlCreateCombo("default",  480, 220, 100, 30)
   Local $iResolution = GUICtrlCreateCombo("",  510, 180, 70, 30)
   Local $LogContainer = GUICtrlCreateGroup("Download Logs", 20, 90, 370, 160)
		 $WriteLog = GUICtrlCreateEdit("", 25, 110, 360, 135)

   GUICtrlSetFont($Label1, 14)
   GUICtrlSetFont($Label2, 9)
   GUICtrlSetFont($TextBox1, 12)
   GUICtrlSetFont($LogContainer, 10)
   GUICtrlSetFont($sFile, 10)
   GUICtrlSetFont($sDate, 12)
   GUICtrlSetFont($iResolution, 12)
   GUICtrlSetFont($iBitrate, 12)
   GUICtrlSetData($iResolution, "-|-sd-|-hd-","-hd-")
   GUICtrlSetData($iBitrate, "150000|300000|500000|800000|1000000|1300000|1500000|2500000")
   GUIStartGroup()

   Local $aDList = DownloadList()

   For $i = 1 To $aDList[0]
	  GUICtrlSetData($sFile, $aDList[$i])
   Next

   While 1
	  $UIEvent = GUIGetMsg()
	  Select
		 Case $UIEvent = $GUI_EVENT_CLOSE
			ExitLoop
		 Case $UIEvent = $BtnDownload
			DownloadStart(GUICtrlRead($sFile), GUICtrlRead($sDate), GUICtrlRead($TextBox1), cBitRate(GUICtrlRead($iBitrate)), GUICtrlRead($iResolution) )
		 Case $UIEvent = $BtnINI
			INIFile()
		 Case $UIEvent = $BtnFFMPEG
			FFMPEG()
		 Case $UIEvent =$Label2
			ShellExecute("http://pinoydev.org")
	  EndSelect
   WEnd
EndFunc

Func cBitRate($br)
   If $br == 'default' Then
	  $br = $defaultBitrate
   EndIf
   Return $br
EndFunc

Func DownloadList()
   Return IniReadSectionNames(@ScriptDir & "\download.ini")
EndFunc

Func DownloadStart($sFile, $sDate, $AccessParam, $bitRate, $res)
   If CheckRequirements() Then
	  ; http://o2-f.akamaihd.net/z/tvt/20170611/20170611-tvt-p-hd-,150000,300000,500000,800000,1000000,1300000,1500000,2500000,.mp4.csmil/manifest.f4m
	  $aDate = StringSplit($sDate, "/")
	  $cDate = StringFormat("%04i%02i%02i",$aDate[3],$aDate[1],$aDate[2])
	  $sFile = StringStripWS($sFile, $STR_STRIPLEADING + $STR_STRIPTRAILING + $STR_STRIPSPACES)
	  Local $StreamDate = "/" & $cDate & "/" & $cDate
	  Local $_file, $_path

	  If $sFile <> "Select file to download" Then
		 Local $DLFile = IniReadSection(@ScriptDir & "\download.ini", $sFile)

		 If UBound($DLFile) == 3 Then
			For $i = 1 To $DLFile[0][0]
			   If $DLFile[$i][0] == 'file'  Then
				  $_file = $DLFile[$i][1]
			   EndIf
			   If $DLFile[$i][0] == 'path'  Then
				  $_path = $DLFile[$i][1]
			   EndIf
			Next
		 Else
			Call("ConsoleLog", "Error: download.ini is not valid")
		 EndIf

		 Local $DownloadURL = $StreamURL & $_path & $StreamDate & "-" & $_file & $res & "," & $bitRate & $StreamExt

		 Call("DownloadSection", $DownloadURL, $sFile, $AccessParam, $bitRate, $res)
	  EndIf
   EndIf
EndFunc

Func DownloadSection($DownloadURL, $sFilename, $AccessParam, $BitRate, $Res)
   Local $Filename = $sFilename & $cDate & ".mp4"
   Local $ffURL = '"' & $DownloadURL & '"'
   Local $ffCopy = " -c copy -bsf:a aac_adtstoasc " & '"' & $Filename & '"'
   Call("ConsoleLog", "Downloading... " & $Filename & @CRLF)
   If Not FileExists(@ScriptDir & "\" & $Filename) Then
	  ConsoleWrite(@ScriptDir & "\ffmpeg.exe -i " & $ffURL & $ffCopy & @CRLF)
	  ;RunWait(@ScriptDir & "\ffmpeg.exe -i " & $DownloadConvert, "", @SW_HIDE)
   EndIf
   If FileExists(@ScriptDir & "\" & $Filename) Then
	  Call("ConsoleLog", "Download completed -> " & $Filename & @CRLF)
   EndIf
EndFunc

Func INIFile()
   Local $sFilePath = _WinAPI_GetTempFileName(@TempDir)
   Local $hDownload = InetGet("https://dev4.pinoydev.org/download/download.ini", $sFilePath, $INET_FORCERELOAD, $INET_DOWNLOADBACKGROUND)
   Do
	 Sleep(250)
   Until InetGetInfo($hDownload, $INET_DOWNLOADCOMPLETE)
   InetClose($hDownload)
   FileCopy($sFilePath, @ScriptDir &"\download.ini", $FC_OVERWRITE + $FC_CREATEPATH)
   FileDelete($sFilePath)
   Call("ConsoleLog","INI Download completed." & @CRLF)
EndFunc

Func FFMPEG()
   If FileExists(@ScriptDir &"\ffmpeg.exe") Then
	  Call("ConsoleLog","FFMPEG is ready." & @CRLF)
   Else
	  Local $iMBbytes = 1048576
	  Local $sourceURL = "https://dev4.pinoydev.org/download/ffmpeg.exe"
	  Local $sFilePath = _WinAPI_GetTempFileName(@TempDir)
	  Local $hDownload = InetGet($sourceURL, $sFilePath, $INET_FORCERELOAD, $INET_DOWNLOADBACKGROUND)
	  Local $iFileSize = InetGetSize($sourceURL)
	  ProgressOn("Downloading...", "Retrieving FFMPEG.")

	  Do
		Sleep(250)
		Local $iDLPercentage = Round(InetGetInfo($hDownload, $INET_DOWNLOADREAD) * 100 / $iFileSize, 0)
		Local $iDLBytes = Round(InetGetInfo($hDownload, $INET_DOWNLOADREAD) / $iMBbytes, 2)
		Local $iDLTotalBytes = Round($iFileSize / $iMBbytes, 2)

		; Update progress UI
		If IsNumber($iDLBytes) And $iDLBytes >= 0 Then
			ProgressSet($iDLPercentage, $iDLPercentage & "% - Downloaded " & $iDLBytes & " MB of " & $iDLTotalBytes & " MB")
		Else
			ProgressSet(0, "Downloading FFMPEG")
		EndIf
	  Until InetGetInfo($hDownload, $INET_DOWNLOADCOMPLETE)
	  InetClose($hDownload)
	  FileCopy($sFilePath, @ScriptDir &"\ffmpeg.exe", $FC_OVERWRITE + $FC_CREATEPATH)
	  FileDelete($sFilePath)
   EndIf
EndFunc

Func ConsoleLog($sTxt)
   GUICtrlSetData($WriteLog, $sTxt, 1)
EndFunc

Func SelfCheckStart()
   If WinExists("TFC.tv Downloader") Then
	  WinActivate("TFC.tv Downloader")
   Else
	  WinStart()
   EndIf
EndFunc

Func CheckRequirements()
   If Not FileExists(@ScriptDir & "\download.ini") Then
	  Call("ConsoleLog", "Error: Please download the INI file." & @CRLF)
	  Return False
   ElseIf Not FileExists(@ScriptDir & "\ffmpeg.exe") Then
	  Call("ConsoleLog", "Error: Please download FFMPEG" & @CRLF)
	  Return False
   Else
	  Return True
   EndIf
EndFunc

Func CheckVersionUpdate()
   Local $sFilePath = _WinAPI_GetTempFileName(@TempDir)
   Local $hDownload = InetGet("https://dev4.pinoydev.org/version.ini", $sFilePath, $INET_FORCERELOAD, $INET_DOWNLOADBACKGROUND)
   Do
	 Sleep(250)
   Until InetGetInfo($hDownload, $INET_DOWNLOADCOMPLETE)
   InetClose($hDownload)
   Local $aversion = IniReadSection(@ScriptDir & "\download.ini", "Program");
   If( $aversion[0][1]==$CurrentVersion ) Then
	  Call("ConsoleLog","Version checked: You are using the current version." & @CRLF)
   Else
	  Call("ConsoleLog","Version checked: A new version is available." & @CRLF)
   EndIf
   FileDelete($sFilePath)
EndFunc