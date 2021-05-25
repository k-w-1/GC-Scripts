#Adjust as needed
$VPNHost = "your.VPN.host.gc.ca"

#You need to connect successfully to this network once to make a profile; you can confirm the profile name with 'netsh wlan show profiles'
$wlanProfile = "Usually your SSID"

#note, probably no need to adjust AnswersPath unless you have some really weird filesystem restrictions. When in doubt, this can be set to any writeable path (e.g. Documents)
$AnswersPath = "${env:TEMP}\VPNanswers.txt"
$VPNPath = "C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client"

"Checking Wi-Fi..."
if((Get-NetAdapter | where { $_.Name -like "Wi-Fi*"} ).Status -ne 'Up')  {
    "Connecting to Wi-Fi..."
    netsh wlan connect name=$wlanProfile
}

#vpncli.exe won't let us connect a connection if this app is running (but everything else works, wtf cisco?)
stop-process -Name "vpnui" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

#Note: have to do this rather than -NoClobber & SilentlyContinue because apparently out-file doesn't really work like that.
if (-Not (Test-path $AnswersPath)) { "Writing answer file to $AnswersPath"; "connect $VPNHost`r`ny`r`nexit" | Out-File -FilePath $AnswersPath -Encoding ascii }

"Checking VPN..."
#Find out current status, since vpncli chokes on the -s if the connection is already active. 
#Note the leading space for ' Connected', this is req'd else it will match disCONNECTED as well.
#Note 2: vpncli doesn't seem to play nicely when executed directly inside PS, hence the cmd /c
$status = $(cmd /c "`"$VPNPath\vpncli.exe`" status") | Select-String " Connected"

if($status.Count -gt 0) {
    "VPN seems to be connected already!"
    sleep -Seconds 5
} else {
    #Go for takeoff!
    "Connecting VPN..."

    #Note: should add a timeout or something here; seems like it craps the bed occasionally and/or just needs a 2nd try?
    #Note 2: seems like vpncli actually has it's own built-in timeout.

    cmd /c "`"$VPNPath\vpncli.exe`" -s < `"$AnswersPath`"" | Out-Null
}

"Triggering WCF login..."
# invoke-webrequest here to trigger Web Content Filtering login; the FF url is good because it sets a bunch of headers to force a full load (and use no caching)
# the -UseBasicParsing is important because IWR will actually try and render the page (including JS) so it can take forever on weird pages
Invoke-Webrequest -UseBasicParsing -TimeoutSec 10 -Method Head -uri "http://detectportal.firefox.com/" -UseDefaultCredentials | Out-Null

#restart the UI (also conveniently toasts a 'you're connected' message)
start "$VPNPath\vpnui.exe"
