<#
   NSX-T 3.0 Portgroup to Segment Migrator v1.0
   
   This script will find all the portgroups in your infrastructure that are currently in use.
   It will get the VLAN, Gateway and CIDR for each of them
   Then, It will prompt you to create all the segments in NSX-T
   
   Author: ldelorenzi@vmware.com
   Aug 5, 2020
 #>

#$vcenter="vcsa-01a.corp.local" 
$nsxmanager = "nsxapp-01a.corp.local"

#$vcpassword = ConvertTo-SecureString 'VMware1!' -AsPlainText -Force
#$nsxpassword = ConvertTo-SecureString 'VMware1!VMware1!' -AsPlainText -Force
$overlayTransportZone = "nsx-overlay-transportzone"
#$vccredential = New-Object System.Management.Automation.PSCredential('administrator@vsphere.local', $vcpassword)
#$nsxcredential = New-Object System.Management.Automation.PSCredential('admin', $nsxpassword)



$vcenter=Read-Host "Enter vCenter FQDN"
$vccredential = Get-Credential -message "Enter vCenter Credentials"
#$nsxmanager=Read-Host "Enter NSX Manager FQDN"
#$nsxcredential = Get-Credential -message "Enter NSX Credentials"
#$overlayTransportZone = Read-Host "Enter NSX Overlay Transport Zone name"
Connect-VIServer -Server $vcenter -credential $vccredential

$PossibleSegments = @()
$vms = Get-VM 

foreach ($vm in $vms) {
    $networkObject = "" | Select Portgroups,IP,Gateway,Subnetmask,DNS,Prefix
    $networkObject.Portgroups = ($vm | Get-NetworkAdapter | Get-VDPortgroup).Name
	$networkObject.Portgroups
    $networkObject.IP  = $vm.Guest.IPAddress
	Write-Host $vm
	if ($vm.extensiondata.guest.ipstack){
		$device = ($vm.extensiondata.guest.ipstack[0].iprouteconfig.iproute | where {$_.network -eq "0.0.0.0"}).gateway.device 
		
		$networkObject.gateway = ($vm.extensiondata.guest.ipstack[0].iprouteconfig.iproute | 
			where {$_.network -eq "0.0.0.0"}).gateway.ipaddress
		$networkObject.gateway
		$networkObject.Prefix = ($vm.extensiondata.guest.ipstack[0].iprouteconfig.iproute | 
			where {$_.network.length -gt 6} | where {$_.network -like "*.*"} | 
				where {$_.prefixlength -ne 32} | where {$_.network.substring(0,4) -ne "224."}  | 
					where {$_.prefixlength -ne 0} | where {$_.network.substring(0,8) -ne "169.254."} | 
						where {$_.gateway.device -eq $device}).prefixlength
		$networkObject.Prefix
						
		 foreach ($pg in $networkObject.Portgroups)
		{
			$PGObject = "" | Select Name, VLAN, Gateway
			$PGObject.Name = $pg
			$PGObject.VLAN = (Get-VDPortgroup $pg).VlanConfiguration.VlanId
			$PGObject.Gateway = $networkObject.Gateway + "/" + $networkObject.Prefix
			#Skip Trunk vLAN
			if ((Get-VDPortgroup $pg).VlanConfiguration.vlantype -ne 'Trunk'){
				$PossibleSegments += $PGObject
			 }
		}
	}
}
$UniqueSegments = $PossibleSegments | Where {$_.Gateway -ne $null} | sort-object -Property  @{E="Name"; Descending=$True}, @{E="Gateway"; Descending=$True} -unique

Write-Host "############################################################"
Write-Host "Found the following possible segments in your infrastructure"
$uniqueSegments | % {
	Write-Host Portgroup $_.name with VLAN $_.VLAN and gateway $_.gateway
}

Write-host "Would you like to Create these segments on NSX-T?" -ForegroundColor Yellow 
    $Readhost = Read-Host " ( y / n ) " 
    Switch ($ReadHost) 
     { 
       Y {Write-host "Yes, create segments"; $createSegments=$true} 
       N {Write-Host "No, don't create segments"; $createSegments=$false} 
       Default {Write-Host "Default, Skip PublishSettings"; $createSegments=$false} 
     } 


if ($createsegments){
    $getTzUrl = "https://$nsxmanager/api/v1/transport-zones"
	$getTzRequest = Invoke-RestMethod -Uri $gettzurl -Authentication Basic -Credential $nsxcredential -Method get -ContentType "application/json" -SkipCertificateCheck
	$gettzrequest.results | % {
	if ($_.display_name -eq $overlayTransportZone){
		$overlayTzId = $_.id
		Write-Host found transport zone id: $overlayTzId
	}
}
	foreach ($segment in $uniqueSegments)
	{
		$segmentDisplayName = $segment.name + "-VLAN" + $segment.VLAN + "-GW" + $segment.gateway
		$Body = @{
			display_name = $segmentDisplayName
			subnets = @(
					@{
					gateway_address = $segment.gateway
					}
				)
			transport_zone_path="/infra/sites/default/enforcement-points/default/transport-zones/$overlayTzId"
			 }
		$jsonBody = ConvertTo-Json $Body
		Write-Host "Creating Segment $segmentDisplayName on transport zone $overlayTransportZone" 
		$patchSegmentUrl = "https://$nsxmanager/policy/api/v1/infra/segments/" + $segmentDisplayName
		$patchRequest = Invoke-RestMethod -Uri $patchSegmentUrl -Authentication Basic -Credential $nsxCredential -Method patch -body $jsonBody -ContentType "application/json" -SkipCertificateCheck
	}
}
	 
 
Disconnect-VIServer -confirm:$false







