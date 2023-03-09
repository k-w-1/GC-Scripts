#If you're on VPN, the pip install will fail since Python doesn't use the system root certs, and the GC content filtering uses a self-signed cert
$VPNPath = "C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client"
stop-process -Name "vpnui" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
$status = $(cmd /c "`"$VPNPath\vpncli.exe`" status") | Select-String " Connected"
start "$VPNPath\vpnui.exe"
if($status.Count -gt 0) {
    Write-Error "You need to disconnect from VPN before running this script to ensure Pip can be installed properly!"
    sleep -Seconds 5
} else {
    #Prevent subsequent commands from running if something fails...
    try {
        Write-Host "Finding latest exe (NB: this is somewhat brittle if Python updates their page layout)..."
        $page = iwr -UseBasicParsing -Uri "https://www.python.org/downloads/"
        $newest_python = ($page.Links.Where({$_.outerHTML -like "*class=`"button`"*" -and $_.href -like "*.exe"}).href | select -First 1)

        $installerpath = ($env:TEMP + "/pyinstaller.exe")
        Write-Host "Downloading $newest_python to $installerpath..."
        iwr -uri $newest_python -OutFile $installerpath

        #run installer, wait until complete
        Write-Host "Running installer. Make sure to install just for yourself!"
        Start-Process $installerpath -Wait

        Write-Host "Cleaning up $installerpath"
        Remove-Item $installerpath

        Write-Host "Finding path to Python (got snake oil?)"
        $pypath = (gci -Path ($env:LOCALAPPDATA + "\Programs\Python\") | Where-Object {$_.Name -like "Python*"} | Sort-Object -Property LastWriteTime -Descending | select -First 1 )

        Write-Host "Installing AZ via pip..."
        #(nb: starting with & so it'll reuse the console window insteaad of launching a new as start-process would)
        & "$pypath\python.exe" ("-m pip install azure-cli").Split(" ")

        Write-Host "Setting path to Python and for Az (also convienently adds pip)."
        #not sure why, but for some reason the trailing slash gets trimmed, so it's doubled to compensate.
        & "setx" @("path", "`"%path%;$pypath\;$pypath\Scripts\\`"")
    } catch {
        Write-Error "Setup failed successfully!"
    }
}