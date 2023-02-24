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
    & "setx" ("path `"%path%;$pypath\;$pypath\Scripts\`"").Split(" ")
} catch {
    Write-Error "Setup failed successfully!"
}