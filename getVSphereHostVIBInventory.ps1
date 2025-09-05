$vc1fqdn = Read-Host "Enter Target vCenter Server FQDN"
$vc1user = Read-Host "Username"
$vc1pass = Read-Host "Password" -AsSecureString
$vc1credential = New-Object System.Management.Automation.PSCredential($vc1user, $vc1pass)

$vc1 = Connect-VIServer -Server $vc1fqdn -Credential $vc1credential

[pscustomobject]@{
	Host = ""
	AcceptanceLevel = ""
	Name = ""
	Version = ""
}

[array]$output = @()
$esxhost = Get-VMHost | Where-Object {$_.ConnectionState -eq 'Connected'}

ForEach ($vmhost in $esxhost) {
	$esxcli = Get-EsxCli -VMHost $vmhost -V2
	ForEach ($vib in ($esxcli.software.vib.list.Invoke())) {
		$output += [pscustomobject]@{
			Host = $vmhost.Name
			AcceptanceLevel = $vib.AcceptanceLevel
			Name = $vib.Name
			Version = $vib.Version
		}
	}
}

$outfilename = $vc1.Name + "_HostVIBInventory.csv"
$output | Export-Csv -Path .\$outfilename