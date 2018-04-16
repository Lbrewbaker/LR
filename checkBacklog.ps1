$date = (Get-Date).AddMinutes(-2)
$datemax = (Get-Date).AddMinutes(-30)
$Files = @(Get-ChildItem "C:\Program Files\LogRhythm\LogRhythm AI Engine\data" *.* | where-object {$_.DateModified -le $date -and $_.Name -Like "*.dat"})
$FileCount = $Files.Count
$FileLastMod = $Files[0].LastWriteTime
If ($FileCount -gt 10 -and $FileLastMod -lt $datemax)
{
Send-MailMessage -SmtpServer "emailserver.domain.com" -From "alert@domain.com" -To "you@domain.com" -Subject "LR AIE Backlogged" -Body "The Logrhythm AIE Engine is delayed in processing more than 30 minutes, $FileCount files in data folder and oldest last modified file $FileLastMod"
}
Else
{Exit}