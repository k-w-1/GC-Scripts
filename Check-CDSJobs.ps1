# Check-CDSJobs
# A purpose-built tool to keep track of job postings at the Canadian Digital Service!
# Kevin White | 2021-01-15 | https://github.com/k-w-1/

#Create an HTMLFile COM object to work with
$HTML = New-Object -Com "HTMLFile"

#Load up the CDS careers page
#Unknown reason (protected by CloudFlare?), but Invoke-WebRequest craps out for digital.canada.ca; below works a treat (and may even be faster?)
#Later note: probably I just needed -UseBasicParsing for IWR, but this works anyway.
$HTML.IHTMLDocument2_write((New-Object Net.WebClient).DownloadString("https://digital.canada.ca/careers/"))

#correct the weird way the href is returned. Since $HTML is a COM object, it appears we need to give it a break between updating the href and copying to another object.
$HTML.body.getElementsByClassName("job-posting-link") | % { $_.href = "https://digital.canada.ca" + $_.href.trimStart("about:") } 

#get only the parts we want, and name the prop's better
$list = $HTML.body.getElementsByClassName("job-posting-link") | select-object -property @{N='Title';E={$_.innerText}}, @{N='URL';E={$_.href}}

if($null -eq $list) {
    Write-Warning "Either there are no jobs currently posted, or CDS has updated their page and this scrape is broken."
}

#debug
$list | ft

#Gui display
$list | Out-GridView -Title "CDS Jobs" -PassThru |

#after the Grid, only selected items + OK (vs cancel) will be passed to below for launching
% { start $_.URL }
