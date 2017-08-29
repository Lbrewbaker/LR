# Powershell Script to assist in Creating Certificates 
# Must be executed with Administrative Permissions to Create the Certificates for the Local Machine

function Select-RootCert
{

    Write-Host
    Write-Host "Certificates Installed under the Local Machine on your Personal Store"
    $count = 0
    ForEach ($cert in Get-ChildItem Cert:\LocalMachine\My)
    {
        $count += 1
        Write-Host $count - $cert.Subject
    }
    $selectedRoot = Read-Host "Select"
    if ([int]$selectedRoot -le $count) {
       $count = 0
        ForEach ($cert in Get-ChildItem Cert:\LocalMachine\My)
        {
            $count += 1
            if ($count -eq [int]$selectedRoot) { return $cert.Thumbprint }
        } 
    } 
    else {
        Write-Host "Invalid Selection for the Root Certificate"
    }

    return "0"
}

function Generate-RootCert
{
    # This function generates the root certificate and places it in LocalMachine\Personal Folder
    # makecert -r -n "CN=LogRhythm TEST Root CA" -sr LocalMachine -ss MY -a sha256
    #    -r Self-Signed Cert
    #    -n Subject
    #    -sr Location of where the certificate should be stored - Local Machine is what is stated in LogRhythm Documentation
    #    -ss Which certificate store to place it in - MY = Personal
    #    -a The algorithm to utilize
    $subjectCert = Read-Host "What would you like as the Subject of the certificate (Generated Root CA)"
    if ($subjectCert -eq "") { $subjectCert = "Generated Root CA" }

    Write-Host
    Write-Host "What is the duration of time to set for the certificate?"
    Write-Host "1. 12 Months"
    Write-Host "2. 24 Months"
    Write-Host "3. 36 Months (Default)"
    $timeInput = Read-Host "Duration (3)"
    if ($timeInput -eq "1") { $timeSelected = 12 }
    elseif ($timeInput -eq "2") { $timeSelected = 24 }
    else { $timeSelected = 36 }

    # Generates a RSA2048 Self-Signed Certificate
    $newRootCA = New-SelfSignedCertificate -Subject $subjectCert -CertStoreLocation Cert:\LocalMachine\My  -NotAfter (Get-Date).AddMonths($timeSelected) 
    # CertStoreLocation - Location is on the Local Machine in the Personal Certificates Folder
    # KeyUsage - Allows the key to be used to sign other keys
    # NotAfter - Sets the Time Duration that the Certificate is Valid for...
    Write-Host
    Write-Host "Unless an error is displayed above the certificate was created successfully.  You can view the new Root CA"
    Write-Host "through the MMC snap-in for the Local Computer Certificates under the Personal Certificates."
    Write-Host

    Return $newRootCA.Thumbprint
}

function Create-ServerCert ([String]$Thumbprint)
{
    # makecert -pe -n "CN=servername.mycompany.local" -sky exchange -eku 1.3.6.1.5.5.7.3.1 -sr LocalMachine -ss MY -ir Local Machine -is MY -in "Generated Root CA" -a sha256
    #    -pe - Allow the Key to be Exportable
    #    -n  - Subject
    #    -sky exchange - Not Sure Yet  (-KeySpec KeyExchange)
    #    -eku 1.3.6.1.5.5.7.3.1 (Server Authentication)
    #    -sr Location where the certificate should be stored
    #    -ss Which certificate store to place it in
    #    -ir Issuers Certificate Location
    #    -is Issuers Certificate Store
    #    -in Issuers Common Certificate Name
    Write-Host
    $serverName = Read-Host "What is the Server Name of the Server? "
    $domainName = Read-Host "What is the Domain Name of the Server? "
    $serverName = $serverName.ToUpper()
    $serverName = "$serverName.$domainName"
    Write-Host $serverName
    if ($serverName) {
        Write-Host
        Write-Host
        Write-Host "What is the duration of time to set for the certificate?"
        Write-Host "1. 12 Months"
        Write-Host "2. 24 Months"
        Write-Host "3. 36 Months (Default)"
        $timeInput = Read-Host "Duration (3)"
        if ($timeInput -eq "1") { $timeSelected = 12 }
        elseif ($timeInput -eq "2") { $timeSelected = 24 }
        else { $timeSelected = 36 }
        Write-Host
        $addResponse = Read-Host "Specify additional FQDN or DNS entries for certificate (No is default)"
        if (($addResponse -eq "Yes") -or ($addResponse -eq "yes") -or ($addResponse -eq "y")) {
            $addNames = Read-Host "Additional FQDN or DNS entries seperated with a comma"
            $dnsNames = "$serverName, $addNames"
        }
        else {
            $dnsNames = $serverName
        }
        # Get the Generated Root CA's thumbprint that we generated
        $rootCA = (Get-ChildItem -Path Cert:\LocalMachine\My\$Thumbprint)
        New-SelfSignedCertificate -KeyExportPolicy Exportable -Subject "CN=$serverName" -DnsName $dnsNames -CertStoreLocation Cert:\LocalMachine\My -NotAfter (Get-Date).AddMonths($timeSelected) -Signer $rootCA -KeySpec KeyExchange -KeyUsageProperty All
    }
    else {
        Write-Host "The FQDN of the Server needs to be Specified"
        Write-Host
    }
}

function Show-Menu
{
    $input = "a"
    $rootCAThumbprint = "0"
    do
    {
        Write-Host
        Write-Host "===LogRhythm Certificate Management==="
        Write-Host
        Write-Host "1. Generate Root Certificate"
        Write-Host "2. Select Root Certificate to Use"
        Write-Host "3. Create Server or Client Certificate(s) with Root Certificate"
        Write-Host
        if ($rootCAThumbprint -ne "0") {
            Write-Host "Selected Root Certificate is:"
            $currentCert = Get-ChildItem Cert:\LocalMachine\my | Where-Object {$_.Thumbprint -eq $rootCAThumbprint }
            Write-Host Subject: $currentCert.Subject
            Write-Host Thumbprint: $currentCert.Thumbprint
            Write-Host
        }
        Write-Host "Q. Quit"
        $input = Read-Host "Selection: "
        switch ($input)
        {
            '1' {
                    Write-Host
                    $rootCAThumbprint = Generate-RootCert
                    Write-Host
                }
            '2' {
                    Write-Host
                    $rootCAThumbprint = Select-RootCert
                    Write-Host
                }
            '3' {
                    Write-Host
                    if ($rootCAThumbprint -ne "0") {
                        Create-ServerCert -Thumbprint $rootCAThumbprint
                    }
                    else {
                        Write-Host
                        Write-Host "No Root CA has been generated or selected." -ForegroundColor Red
                        Write-Host
                    }
                    Write-Host
                }
        }
    } until (($input -eq 'q') -or ($input -eq 'Q'))
}


Show-Menu

