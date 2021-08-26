function Start-DegenBot {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false)]
        [int] $sleepInterval = 3,
        [Parameter(Mandatory=$true)]
        [string] $botKey,
        [Parameter(Mandatory=$true)]
        [string] $chatID
    )

    BEGIN {
        #bot api key
        <#removed#>
        #incoming messages page
        $updatePage      = "https://api.telegram.org/bot$botkey/getUpdates"
        #get me link
        $getMeLink       = "https://api.telegram.org/bot$botkey/getMe"
        #send message link
        $sendMessageLink = "https://api.telegram.org/bot$botkey/sendMessage"
        #set webhook
        $setWebhookLink  = "https://api.telegram.org/bot$botkey/setWebhook"
        #base TG API Endpoing
        $apiEP           = "https://api.telegram.org/bot$botkey"

        $offset = 0
        $cycle  = 0
        $start  = Get-Date
    }
        
    PROCESS {

        while ($true) {
            Write-Host "// Start time:    $start //" -ForegroundColor DarkBlue
            
            $json = Invoke-RestMethod -Uri $updatePage -Body @{offset=$offset}
            Write-Host -ForegroundColor Cyan "Reading messages:  $json"
            #Write-Host $json.ok
            
            $len = $json.result.length
            $i   = 0
            #Write-Host $json.result 
            #Write-Host $json.result.length

            while ($i -lt $len) {
                $offset = $json.result[$i].update_id + 1
                Write-Host "New offset:  $offset"
                #Write-Host $json.result[$i].message.text -ForegroundColor Yellow

                if ($json.result[$i].message.text -match "/gas") {
                    Write-Host "gas price was called" -ForegroundColor Green
                    $gas = & { $gas_resp = irm -Method Get -Uri "https://www.gasnow.org/api/v3/gas/price" -Headers @{"Cache-Control" = "no-cache"}
                               $gas_values = New-Object -TypeName psobject -Property @{ "Rapid" = $gas_resp.data.rapid / 1e9
                                                                             "Fast"  = $gas_resp.data.fast             / 1e9
                                                                             "Std"   = $gas_resp.data.standard         / 1e9 } #..\Check_GasNow_Gas.ps1
                        $gas_values
                    }

                    $msgObj = [PSCustomObject]@{
                        chat_id = $chatID
                        text    = "Rapid:  $( [math]::Round($gas.Rapid) )`
Fast:  $( [math]::Round($gas.Fast) )`
Std:  $( [math]::Round($gas.Std) )"
                    }
                    
                    Invoke-RestMethod -Method Post -Uri $sendMessageLink -Body ($msgObj | ConvertTo-Json) -ContentType "application/json"

                } else {
                    Write-Host "just normal chatting..." -ForegroundColor Red
                }

                $i++
            }

            Start-Sleep -Seconds $sleepInterval
            $cycle++
            Write-Host "// Update Cycle $cycle complete //" -ForegroundColor Gray
            $currTime = Get-Date
            Write-Host "// Current time:  $currTime //" -ForegroundColor DarkBlue

        }
    }

}