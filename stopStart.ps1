Do{
$input = Read-Host -Prompt '1:Start or 2:Stop services?'


#starts services and exits script
If ($input -eq 1){
Write-Host "Starting Services"
Get-Service | Where-Object {$_.displayName.StartsWith("LogRhythm")} | Start-Service 
Get-Service | Where-Object {$_.displayName.StartsWith("LogRhythm")} | Set-Service -StartupType Automatic
break; 
}


 #stops services and exits script
ElseIf ($input -eq 2){
Write-Host "Stopping Services"
Get-Service | Where-Object {$_.displayName.StartsWith("LogRhythm")} | Stop-Service
break;
}

Else{
Write-Host "Invalid Input"
}

}
While ($true)

