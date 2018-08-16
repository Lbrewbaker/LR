# Test connection to several servers/ports.  Poor mans port scanner to test alarms in the LR SIEM.
# Written: Luke Brewbaker - LogRhythm QA Engineer
# Updated: 8/15/2018


  $servers = Get-Content -Path C:\temp\servers.txt   #list of servers to connect to
  $ports = Get-Content -Path C:\temp\ports.txt    #list of ports.  Use commonly known ones.
  
  

foreach ($server in $servers){
  
  #recursive loop to check each port per server.  
  foreach($port in $ports){
	Write-Host "Connecting to $server on port $port"
    $socket = New-Object System.Net.Sockets.TcpClient($source, $port)
  }
  #prints error if connection refused.  
  catch [Exception]{
    Write-Host $_.Exception.GetType().FullName
    Write-Host $_.Exception.Message
  }

  Write-Host "Connected"
}#End for loop