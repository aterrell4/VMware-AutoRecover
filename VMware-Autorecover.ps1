#On first run, the vCenter username and password are required. After first run, the credentials are stored in the PowerCLI credential DB and not prompted for again making the script fully automated.
#VMs prefixed with "Retired" will be ignored.
#VMs prefixed with "Priority#" (Priority1, Priority2, etc) will be booted in numerical order.
# Written by Adam Terrell 
# email me: aterrell@vertisys.com


#Start Logging of session
$datetime = get-date -format yyyy-MM-dd-hhmm
#Change This Path To Your Own Destination
$logpath= "C:\options\VM-Booting_"+$datetime+".powershell_log"
Start-Transcript -path $logpath
#Check if VMWare PowerCLI is installed if it isn't make it so.
if (Get-Module -ListAvailable -Name VMware.powercli) {
    Write-Host -BackgroundColor White -ForegroundColor Green "Dependencies are present!"
} 
else {
    Write-Host -BackgroundColor Red -ForegroundColor White  "Module does not exist attempting install."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Install-PackageProvider -Name Nuget -Confirm:$False
    Install-Module -Name VMware.PowerCLI -AllowClobber -Confirm:$False -Force
}
#Use this to bypass Invalid Certificate Errors when connecting
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
#Target URL or IP of vCenter Server
$VCSURL = "_FILL_THIS_IN_WITH_IP_OR_FQDN_"
#Leave this on HTTPS
$Protocol = "https"
#Credential Store Check
$CredStorePresence = Get-VICredentialStoreItem
#Check if stored credential exists. If yes, do not prompt for password storage. If no, prompt for password to store.
#Perform VIServer Connection based on using stored credential or not.
if ($CredStorePresence.User -ne $null) {
    Write-Host -BackgroundColor White -ForegroundColor Green "Stored Credential Found."
    Write-Host -BackgroundColor White -ForegroundColor Green "Connecting Using Stored Credential: $CredStorePresence.User"
    Connect-VIServer -Server $VCSURL -User $CredStorePresence.User -Protocol $Protocol
}
else {
    # Warn User of ClearText Storage and Transmission
    Write-Host -ForegroundColor Red "#############################################################################################"
    Write-Host -ForegroundColor Red "NOTICE: This Script records and sends passwords in clear text. Use from trusted source only." 
    Write-Host -ForegroundColor Red "#############################################################################################"
    Write-Host -BackgroundColor Magenta -ForegroundColor Yellow "No Stored Credential Found. Please Enter Credentials to be stored."
    Write-Host -BackgroundColor Magenta -ForegroundColor Yellow "Notice: Use embedded SSO credential to ensure functionality when AD is unreachable."
    Write-Host -BackgroundColor Magenta -ForegroundColor White "Enter Username e.g administrator@vsphere.local :"
    $CacheUser = Read-host
    Write-Host -BackgroundColor Magenta -ForegroundColor White "Enter Password for user :"
    $CachePassword = Read-host
    #Password For Login. Stored in Cleartext. Note: If value contains special characters, leave the ' ' around the PW
    $VCSPassword = $CachePassword
    Connect-VIServer -Server $VCSURL -User $CacheUser -Password $VCSPassword -Protocol $Protocol -SaveCredentials
}
#Get all VMs that are currently powered off.
$AllofflineVMs = Get-VM | Where-Object {( $_.PowerState -eq "PoweredOff") -and ($_.Name -notlike "Retired*")}
$PriorityVMs = $AllofflineVMs | Where-Object {( $_.Name -like "Priority*")} | Sort -Property Name
$offlineVMs = $AllofflineVMs | Where-Object {( $_.PowerState -eq "PoweredOff") -and ($_.Name -notlike "Retired*" -and $_.Name -notlike "Priority*")}
#Bring Priority Offline VMs up
Foreach($PriorityVM in $PriorityVMs) {
    #Generate Pause Between Each VM boot using RNG between 10 and 30 seconds to avoid boot storm
    $pausetime = Get-Random -Minimum 10 -Maximum 30
    Write-Host -ForegroundColor Green "Now Starting: $PriorityVM . If using script interactively press any key to skip boot pause time."
    timeout $pausetime
    Start-VM -VM $PriorityVM
}
#Bring Offline VMs up
Foreach($VM in $offlineVMs) {
    #Generate Pause Between Each VM boot using RNG between 10 and 30 seconds to avoid boot storm
    $pausetime = Get-Random -Minimum 10 -Maximum 30
    Write-Host -ForegroundColor Green "Now Starting: $VM . If using script interactively press any key to skip boot pause time."
    timeout $pausetime
    Start-VM -VM $VM
 }
#Cleanup Session 
Disconnect-VIServer -Confirm:$False
Stop-Transcript