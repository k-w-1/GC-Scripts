# Ok, so perhaps this is not such a complicated script that I need to post it here; but perhaps just for awareness. 
# On my workstation, I noticed that Flow.exe from Adobe was eating tons of CPU cycles; and also seemed to cause 
# FireFox to lag. Some initial research pointed to it being some glitch with language input methods, but I found 
# the best thing to do was simply kill the Flow.exe process. Unfortunately it seems to be re-spawned by some unknown 
# mechanism, so this script simply checks for it by process name every 5 seconds and kills it on sight.

while (1) {
    if ((get-process -Name Flow -ErrorAction 'silentlycontinue') -ne $null) {
        Stop-Process -Name Flow
    }
    Start-Sleep -Seconds 5
}
