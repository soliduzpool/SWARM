<#
SWARM is open-source software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
SWARM is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>
function Global:Get-FairpoolData {
    $Wallets = @()
    $(arg).Type | ForEach-Object {
        $Sel = $_
        $Pool = "fairpool"
        $(vars).Share_Table.$Sel.Add($Pool, @{ })
        $User_Wallet = $($(vars).Miners | Where-Object Type -eq $Sel | Where-Object MinerPool -eq $Pool | Select-Object -Property Wallet -Unique).Wallet
        if ($Wallets -notcontains $User_Wallet) { try { $HTML = Invoke-WebRequest -Uri "https://fairpool.pro/site/wallet_miners_results?address=$User_Wallet" -TimeoutSec 10 -ErrorAction Stop }catch { log "Failed to get Shares from $Pool" } }
        $Wallets += $User_Wallet
        $string = $HTML.Content
        $string = $string -split "<strong style=`"padding-left:4px;`">"
        $string = $string -split "</td></tr></tr><tfoot>"
        $string = $string | ForEach-Object { if ($_ -like "*%; line-height*") { $_ } }
        if ($String) {
            $string | ForEach-Object {
                $Algo_Table = @{ }
                $Cur = $_
                $Algo = $Cur -split "</strong> \(" | Select-Object -Last 1;
                $Algo = $Algo -split "\)</td><td" | Select-Object -First 1
                $CoinName = $Cur -split "</strong> \(" | Select-Object -First 1;
                $Percent = $Cur -split "style=`"width: " | ForEach-Object { if ($_ -like "*%*") { $_ } }
                $Percent = $Percent -split "%;" | Select-Object -First 1
                try { if ([Double]$Percent -gt 0) { $SPercent = $Percent }else { $SPercent = 0 } }catch { log "A Share Value On Site Could Not Be Read on $Pool" }
                $CoinSymbol = "$CoinName`:$Algo".ToUpper()
                $(vars).Share_Table.$Sel.$Pool.Add($CoinSymbol, @{ })
                $(vars).Share_Table.$Sel.$Pool.$CoinSymbol.Add("Name", $CoinName)
                $(vars).Share_Table.$Sel.$Pool.$CoinSymbol.Add("Percent", $SPercent)
                $(vars).Share_Table.$Sel.$Pool.$CoinSymbol.Add("Algo", $Algo)
            }
        }
    }
}