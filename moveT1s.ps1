<################################################
Move (T1s) across edge clusters
Author: @ldelorenzi - Jan 23  


Usage:
moveT1s.ps1 -nsxUrl <NSX Manager URL (with HTTPS)) -sourceClusterName <Edge Cluster Name> -destinationClusterName <Edge Cluster Name> -execute <$true/$false> -count <count of T1 Gateways to move>
Credentials will be asked at the beginning
################################################>
[CmdletBinding()]
param (
    [string]$nsxUrl,
    [string]$sourceClusterName,
    [string]$destinationClusterName,
    [bool]$execute=$false,
    [int32]$count=0
)
$global:connectionRefusedCount = 0
function restCall {
    [CmdletBinding()]
    param (
        $url,
        $headers,
        $method,
        $body
    )
    switch ($method) {
        "GET"{
            try {
                "Executing " + $method + " operation" | Tee-Object -FilePath $logpath -append | Write-Host
                $result = Invoke-RestMethod -Uri $url -SkipCertificateCheck -Headers $headers -Method $method -ErrorAction stop
            }
            catch {
                 $_ | Tee-Object -FilePath $logpath -append | Write-Host
                "##Connection Refused, retrying after 2 seconds##" | Tee-Object -FilePath $logpath -append | Write-Host
                $global:connectionRefusedCount += 1
                $result = $null
                while (!$result)
                {
                    Start-Sleep 2
                    "Retrying..." | Tee-Object -FilePath $logpath -append | Write-Host
                    $result = Invoke-RestMethod -Uri $url -SkipCertificateCheck -Headers $headers -Method $method -ErrorAction stop
                }   
            }
        }
        {$_ -in "PUT","PATCH","POST"} {
            try {
                "Executing " + $method + " operation" | Tee-Object -FilePath $logpath -append | Write-Host
                $result = Invoke-RestMethod -Uri $url -SkipCertificateCheck -Headers $headers -Method $method -Body $body -ErrorAction stop
            }
            catch {
                $_ | Tee-Object -FilePath $logpath -append
                "##Connection Refused, retrying after 2 seconds##" | Tee-Object -FilePath $logpath -append | Write-Host
                $global:connectionRefusedCount += 1
                $result = $null
                while (!$result)
                {
                    Start-Sleep 2
                    "Retrying..." | Tee-Object -FilePath $logpath -append | Write-Host
                    $result = Invoke-RestMethod -Uri $url -SkipCertificateCheck -Headers $headers -Method $method -ErrorAction stop -Body $body
                }   
            }
        }
    }
    return $result
}

$nsxusername = Read-Host "Enter username"
$nsxpassword = Read-Host "Enter Password" -MaskInput
$logpath = "moveT1s.txt"


$userpass  = $nsxusername + ":" + $nsxpassword
$bytes= [System.Text.Encoding]::UTF8.GetBytes($userpass)
$encodedlogin=[Convert]::ToBase64String($bytes)
$authnsxheader = "Basic " + $encodedlogin
$nsxheader = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$nsxheader.Add("Authorization",$authnsxheader)
$nsxheader.Add('Content-Type','application/json')

#Get Edge Clusters
$uri = $nsxurl + "/api/v1/edge-clusters" 
$res = restCall -url $uri -headers $nsxheader -method 'GET'
$edgeClusters = $res.results
#Map clusters
foreach ($cluster in $edgeClusters)
{
    if($cluster.display_name -eq $sourceClusterName)
    {
        $oldCluster = $cluster
    }
    elseif($cluster.display_name -eq $destinationClusterName)
    {
        $newCluster = $cluster
    }
}
#Get all T1s
$uri = $nsxurl + "/policy/api/v1/infra/tier-1s"
$res = restCall -url $uri -headers $nsxheader -method 'GET'
$tier1s = $res.results
#Check if number of T1s to move was inputted
if($count -ne 0)
{
    $testTier1s = $tier1s | select -first $count
}
else 
{
    $testTier1s = $tier1s
}

Write-Host T1 Count $testtier1s.count
foreach ($t1 in $testTier1s)
{
    $uri = $nsxurl + "/policy/api/v1/infra/tier-1s/"+$t1.id+"/locale-services/default" 
    $res = restCall -url $uri -headers $nsxheader -method 'GET'
    Write-Host Checking Tier 1 $t1.display_name
    if($res.edge_cluster_path.split("/")[7] -eq $oldCluster.id)
    {
        Write-Host $t1.display_name is on Source cluster and will be moved if execute is set to true
        Write-Host 
        if($execute)
        {
            Write-Host Execute is set to true, moving T1 to Destination cluster
            $res.edge_cluster_path = $res.edge_cluster_path.replace($oldCluster.id,$newCluster.id)
            $jsonBody = $res | ConvertTo-Json -depth 9
            Write-Host Moving $t1.display_name from $sourceClusterName to $destinationClusterName
            $moveCluster = restCall -url $uri -headers $nsxheader -method 'PATCH' -body $jsonBody
        }
    }
    else {
        Write-Host $t1.display_name is not on $sourceClusterName
    }
}
