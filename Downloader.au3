#include <Array.au3>
#include <AutoItConstants.au3>
#include <Constants.au3>
#include <Date.au3>
#include <EditConstants.au3>
#include <InetConstants.au3>
#include <GUIConstantsEx.au3>
#include <MsgBoxConstants.au3>
#include <Process.au3>
#include <String.au3>
#include <WinAPIFiles.au3>
#include <WindowsConstants.au3>
#include <ButtonConstants.au3>
Opt("GUICoordMode", 1)
Opt("GUICloseOnESC", 0)

Global $AccessToken, $WriteLog, $CurrentVersion = 1, $TokenGenTime = "2017/06/20 00:00:00"
Global $aDate = StringSplit(_Now(), "/")
Global $cDate = StringFormat("%04i%02i%02i",$aDate[3],$aDate[1],$aDate[2])
Global $StreamURL = "http://o1-i.akamaihd.net/i/"
Global $StreamExt = ",.mp4.csmil/master.m3u8?"
Global $defaultBitrate = "150000,300000,500000,800000,1000000,1300000,1500000,2500000"
Global $DownloadDir = @ScriptDir, $LabelDir

SelfCheckStart()

Func WinStart()
   $GUI = GUICreate("TFC.tv Downloader", 600, 300)


   Local $Credits = GUICtrlCreateLabel("PinoyDev.org", 500, 265, 80, 20, 0x0002)
   Local $BtnDownload = GUICtrlCreateButton("Download", 400, 50, 180, 30)
   Local $BtnINI = GUICtrlCreateButton("Download INI File", 20, 220, 100, 30)
   Local $BtnFFMPEG = GUICtrlCreateButton("Download FFMPEG", 125, 220, 120, 30)
   Local $BtnGetToken = GUICtrlCreateButton("Set Token Manually", 250, 220, 140, 30)
   Local $sFile = GUICtrlCreateCombo("Select file to download",  400, 100, 180, 30)
   Local $sDate = GUICtrlCreateDate("", 470, 140, 110, 30, $DTS_SHORTDATEFORMAT)
   Local $iBitrate = GUICtrlCreateCombo("default",  480, 220, 100, 30)
   Local $iResolution = GUICtrlCreateCombo("",  510, 180, 70, 30)
   Local $LogContainer = GUICtrlCreateGroup("ConsoleLog", 20, 40, 370, 160)
		 $WriteLog = GUICtrlCreateEdit("", 25, 60, 360, 135)
		 $LabelDir = GUICtrlCreateLabel("Download Location: " & $DownloadDir, 20, 265, 480, 20)

   GUICtrlSetFont($Credits, 9)
   GUICtrlSetFont($LabelDir, 10)
   GUICtrlSetColor($LabelDir, 0xCC0000)
   GUICtrlSetFont($LogContainer, 10)
   GUICtrlSetFont($sFile, 10)
   GUICtrlSetFont($sDate, 12)
   GUICtrlSetFont($iResolution, 12)
   GUICtrlSetFont($iBitrate, 12)
   GUICtrlSetData($iResolution, "-|-sd-|-hd-","-hd-")
   GUICtrlSetData($iBitrate, "150000|300000|500000|800000|1000000|1300000|1500000|2500000")
   GUIStartGroup()

   DownloadList($sFile)

   GUISetState(@SW_SHOW)
   While 1
	  $UIEvent = GUIGetMsg()
	  Select
		 Case $UIEvent = $GUI_EVENT_CLOSE
			ExitLoop
		 Case $UIEvent = $BtnDownload
			DownloadStart(GUICtrlRead($sFile), GUICtrlRead($sDate), cBitRate(GUICtrlRead($iBitrate)), GUICtrlRead($iResolution) )
		 Case $UIEvent = $BtnINI
			INIFile()
			DownloadList($sFile)
		 Case $UIEvent = $BtnFFMPEG
			FFMPEG()
		 Case $UIEvent = $BtnGetToken
			EnterAccessToken()
		 Case $UIEvent = $LabelDir
			SetDownloadDir()
		 Case $UIEvent =$Credits
			ShellExecute("http://pinoydev.org")
	  EndSelect
   WEnd
   GUIDelete()
EndFunc

Func cBitRate($br)
   If $br == 'default' Then
	  $br = $defaultBitrate
   EndIf
   Return $br
EndFunc

Func DownloadList($sFile)
   If FileExists(@ScriptDir & "\download.ini") Then
	  Local $aDList = IniReadSectionNames(@ScriptDir & "\download.ini")
	  If IsArray($aDList) Then
		 For $i = 1 To $aDList[0]
			GUICtrlSetData($sFile, $aDList[$i])
		 Next
	  EndIf
   EndIf
EndFunc

Func DownloadStart($sFile, $sDate, $bitRate, $res)
   If CheckRequirements() Then
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

		 Call("DownloadSection", $DownloadURL, $sFile, $bitRate, $res)
	  EndIf
   EndIf
EndFunc

Func DownloadSection($FileURL, $sFilename, $BitRate, $Res)
   Local $Filename = $sFilename & "_" & $cDate & ".mp4"
   If Not FileExists($DownloadDir & "\" & $Filename) Then
	  Local $Filetemp = $DownloadDir & "\downloading_" & $sFilename & '.mp4'
	  Local $DownloadURL = '"' & $FileURL & GetAccessToken() & '"'
	  Local $DownloadStart = @ScriptDir & "\ffmpeg.exe -i " &  $DownloadURL & " -c copy -bsf:a aac_adtstoasc " & '"' & $Filetemp & '"'
	  Local $DownloadFinal = @ScriptDir & "\ffmpeg.exe -ss 00:00:15.0 -i " & '"' & $Filetemp & '"' & " -c copy " & '"' & $DownloadDir & "\" & $Filename & '"'
	  Local $DownloadTime = _NowCalc()
	  Call("ConsoleLog", "Download started " & $Filename & @CRLF)
	  RunWait($DownloadStart)
	  RunWait($DownloadFinal)
	  FileDelete($Filetemp)
	  ;ConsoleWrite($DownloadStart & @CRLF)
	  ;ConsoleWrite($DownloadFinal & @CRLF)
	  If _DateDiff('s', $DownloadTime, _NowCalc()) < 10 Then
		 Call("ConsoleLog", "ERROR: Download failed for " & $sFilename & ". File is not ready" & @CRLF)
	  EndIf
	  If FileExists($DownloadDir & "\" & $Filename) Then
		 Call("ConsoleLog", "Download completed -> " & $Filename & @CRLF)
	  EndIf
   Else
	  If FileExists($DownloadDir & "\" & $Filename) Then
		 Call("ConsoleLog", $Filename & " already exist."& @CRLF)
	  EndIf
   EndIf
EndFunc

Func INIFile()
   Call("ConsoleLog","DOWNLOADING INI FILE... Please wait a few moment..." & @CRLF)
   Local $sFilePath = _WinAPI_GetTempFileName(@TempDir)
   Local $hDownload = InetGet("https://dev4.pinoydev.org/download/download.ini", $sFilePath, $INET_FORCERELOAD, $INET_DOWNLOADBACKGROUND)
   Do
	 Sleep(250)
   Until InetGetInfo($hDownload, $INET_DOWNLOADCOMPLETE)
   InetClose($hDownload)
   FileCopy($sFilePath, @ScriptDir &"\download.ini", $FC_OVERWRITE + $FC_CREATEPATH)
   FileDelete($sFilePath)
   Call("ConsoleLog","COMPLETED: INI file is ready." & @CRLF)
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

Func GetAccessToken()
   Local $TokenFile = @ScriptDir & "\dist\token.exe"
   If FileExists($TokenFile) Then
	  If _DateDiff('s', $TokenGenTime, _NowCalc()) > 300 Then
		 $TokenGenTime = _NowCalc()
		 Call("ConsoleLog", "Please wait... Generating access token..." & @CRLF)
		 ;Local $pid = Run(@ComSpec & " /c ping www.google.com", "", @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)
		 Local $pid = Run($TokenFile, "", @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)
					  ProcessWaitClose($pid)
		 Local $tok = StdoutRead($pid)
		 Call("ConsoleLog", "SUCCESS! Access token generated." & @CRLF)
		 If StringInStr($tok, '&') Then
			$tok = StringSplit($tok, '&')[1]
		 EndIf
		 $AccessToken = StringStripWS($tok, $STR_STRIPLEADING + $STR_STRIPTRAILING + $STR_STRIPSPACES)
	  EndIf
   Else
	  Call("ConsoleLog", "ERROR: Could not generate token. Please set token manually." & @CRLF)
   EndIf

   Return $AccessToken
EndFunc

Func EnterAccessToken()
   $AccessToken = InputBox("Enter Access Token","You can manually enter access token here in case it generates bad token.")
EndFunc

Func SetDownloadDir()
   $sFileSelectFolder = FileSelectFolder("Select folder","")
   If @error Then
	  Call("ConsoleLog", "No folder selected." & @CRLF)
   Else
	  $DownloadDir = $sFileSelectFolder
   EndIf
   GUICtrlSetData($LabelDir, "Download Location: " & $DownloadDir)
EndFunc