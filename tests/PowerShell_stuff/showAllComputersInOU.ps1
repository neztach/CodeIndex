# Find AD Computer objects in specific OU 
Import-Module ActiveDirectory
Get-ADComputer -Server 'exampleServer.domain.com' -Filter * -Property * -SearchBase "OU=Computers,DC=DOMAIN,DC=COM" | Format-Table Name,OperatingSystem,OperatingSystemServicePack,OperatingSystemVersion -Wrap –Auto