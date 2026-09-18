[CmdletBinding()]
param([string]$CertificatesPath)
$ErrorActionPreference='Stop'; Set-StrictMode -Version 2.0
$CertificateFileName='eve-certificates-en-US.xml.gzip'; $BackupStateName='EVEMonCertificatesEnhanced.original.json'; $CustomMin=910001000L; $CustomMax=910001999L
function Read-GZipText { param([string]$Path) $f=[IO.File]::OpenRead($Path);try{$g=New-Object -TypeName System.IO.Compression.GZipStream -ArgumentList @($f,[System.IO.Compression.CompressionMode]::Decompress);try{$r=New-Object -TypeName System.IO.StreamReader -ArgumentList @($g,[System.Text.Encoding]::UTF8,$true);try{return $r.ReadToEnd()}finally{$r.Dispose()}}finally{$g.Dispose()}}finally{$f.Dispose()} }
function Write-GZipXml { param([xml]$Xml,[string]$Path) $f=[IO.File]::Create($Path);try{$g=New-Object -TypeName System.IO.Compression.GZipStream -ArgumentList @($f,[System.IO.Compression.CompressionMode]::Compress);try{$e=New-Object -TypeName System.Text.UTF8Encoding -ArgumentList @($false);$w=New-Object -TypeName System.IO.StreamWriter -ArgumentList @($g,$e);try{$Xml.Save($w);$w.Flush()}finally{$w.Dispose()}}finally{$g.Dispose()}}finally{$f.Dispose()} }
if(Get-Process -Name EVEMon -ErrorAction SilentlyContinue){throw 'EVEMon jest uruchomiony. Zamknij go calkowicie.'}
if($CertificatesPath){$certPath=(Resolve-Path -LiteralPath $CertificatesPath).Path}else{$certPath=Join-Path (Join-Path $env:APPDATA 'EVEMon') $CertificateFileName}
if(-not(Test-Path -LiteralPath $certPath -PathType Leaf)){throw "Brak $certPath"}
$statePath=Join-Path (Split-Path -Parent $certPath) $BackupStateName
if(-not(Test-Path -LiteralPath $statePath -PathType Leaf)){throw "Brak logicznego backupu $statePath; nie bede zgadywal oryginalnych definicji."}
$state=Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
[xml]$xml=Read-GZipText -Path $certPath
# Remove our added classes.
foreach($cl in @($xml.SelectNodes('/certificatesDatafile/certificateGroup/certificateClass'))){$id=0L;[void][long]::TryParse([string]$cl.GetAttribute('id'),[ref]$id);if($id -ge $CustomMin -and $id -le $CustomMax){[void]$cl.ParentNode.RemoveChild($cl)}}
# Restore exact original classes by class id into original groups.
foreach($e in @($state.entries)){
    $gid=[string]$e.group_id; $cid=[string]$e.class_id
    $group=$xml.SelectSingleNode("/certificatesDatafile/certificateGroup[@id='$gid']")
    if(-not $group){throw "Nie znaleziono oryginalnej grupy id=$gid dla class id=$cid."}
    foreach($cur in @($group.SelectNodes("certificateClass[@id='$cid']"))){[void]$group.RemoveChild($cur)}
    $frag=$xml.CreateDocumentFragment(); $frag.InnerXml=[string]$e.outer_xml; $node=$xml.ImportNode($frag.FirstChild,$true); [void]$group.AppendChild($node)
}
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'; $backup="$certPath.backup-before-certificates-enhanced-uninstall-$stamp"; $tmp="$certPath.uninstall-certificates-enhanced-temp"
try{Write-GZipXml -Xml $xml -Path $tmp;[xml]$verify=Read-GZipText -Path $tmp;Copy-Item -LiteralPath $certPath -Destination $backup -Force;Copy-Item -LiteralPath $tmp -Destination $certPath -Force}finally{if(Test-Path -LiteralPath $tmp){Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue}}
Write-Host 'OK - przywrocono oryginalne certyfikaty i usunieto dodatki EVEMon Certificates Enhanced.' -ForegroundColor Green
Write-Host "Backup stanu sprzed uninstall: $backup"
Write-Host "Logiczny backup pozostawiono: $statePath"
