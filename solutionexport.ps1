. .\WriteLog.ps1

try
{
#Update name of solution in below line, instead of DynamicsCRMSolutionExport ,add name of solution
$solutionName ="DynamicsCRMSolutionExport"
$versionFileName = "C:\temp\version.txt"
$exportLocation ="C:\temp"
Set-StrictMode -Version latest
function InstallModule{
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$moduleName = "Microsoft.Xrm.Data.Powershell"
$moduleVersion = "2.7.2"
if (!(Get-Module -ListAvailable -Name $moduleName )) {
Write-host "Module Not found, installing now"
$moduleVersion
Install-Module -Name $moduleName -MinimumVersion $moduleVersion -Force
}
else
{
Write-host "Module Found"
}
}
function GetCrmConn{
param(
[string]$user,
[string]$secpasswd,
[string]$crmUrl)
Write-Host "UserId: $user Password: $secpasswd CrmUrl: $crmUrl"
$secpasswd2 = ConvertTo-SecureString -String $secpasswd -AsPlainText -Force
write-host "Creating credentials"
$mycreds = New-Object System.Management.Automation.PSCredential ($User, $secpasswd2)
write-host "Credentials object created"
write-host "Establishing crm connection next"
$crm = Connect-CrmOnline -Credential $mycreds -ServerUrl $CrmUrl
write-host "Crm connection established"
return $crm
}
InstallModule
#Update Source CRM instance details below:
Write-Host "going to create first connection"
$Crm1 = GetCrmConn -user "sourceusername.onmicrosoft.com" -secpasswd "sourcepassword" -crmUrl "SourceCrmUrl"
Write-Host "first connection created"
Set-CrmConnectionTimeout -conn $Crm1 -TimeoutInSeconds 100

$solution = Get-CrmRecords -EntityLogicalName solution -FilterAttribute uniquename -FilterOperator "eq" -FilterValue $solutionName -Fields friendlyname,version -conn $Crm1
If ($solution.Count -ne 1) {
Write-Error "The number of retuned solutions is not correct. Expected 1, returned $($solution.Count)"
exit 1
}
$latestVersion = $solution.CrmRecords[0].version
$oldVersion = Get-Content $versionFileName
if($latestVersion -eq $oldVersion){
Write-Host ""
Write-Host "Old Version:$oldVersion Latest Version:$latestVersion"
Write-Host ""
Write-Host "Latest version matched previous version. Terminating script."
exit 0
}

Write-Host "Exporting Solution"
Export-CrmSolution -conn $Crm1 -SolutionName "$solutionName" -SolutionFilePath $exportLocation1 -SolutionZipFileName "$solutionName.zip"

Set-Content -Path $versionFileName -Value $latestVersion
Write-host "version of file is changed from $oldVersion to $latestVersion "
}
catch
{
Write-Log -Message $_.Exception.Message
Write-Host $_.ScriptStackTrace
Write-Host $_.Exception.StackTrace
Write-Host $_.Exception.InnerException
}
