while ($true){
    $sourceA = "C:\path\to\somefileA.txt"
    $sourceB = "C:\path\to\somefileB.txt"

    $hashA = (Get-FileHash $sourceA).hash
    $hashB = (Get-FileHash $sourceB).hash

    $dateA = [datetime](Get-ItemProperty -Path $sourceA -Name LastWriteTime).lastwritetime
    $dateB = [datetime](Get-ItemProperty -Path $sourceB -Name LastWriteTime).lastwritetime

    if ($dateA -gt $dateB){
        Write-Output "NEW data" 
        if ($hashA -ne $hashB){
            Write-Output "NEW data"
            sleep 5
        }

    }
    else {
        Write-Output "Same data"
        sleep 5
    }
}