[CmdletBinding()]
param(
    [string]$CertificatesPath,
    [string]$SkillsPath,
    [string]$DefinitionsPath = (Join-Path $PSScriptRoot 'EVEMon-Certificates-Enhanced.definitions.json'),
    [switch]$Preview
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
$CertificateFileName = 'eve-certificates-en-US.xml.gzip'
$SkillsFileName = 'eve-skills-en-US.xml.gzip'
$BackupStateName = 'EVEMonCertificatesEnhanced.original.json'
$AllowedGrades = @('Basic','Standard','Improved','Advanced','Elite')

function Read-GZipText {
    param([Parameter(Mandatory=$true)][string]$Path)
    $file=[System.IO.File]::OpenRead($Path)
    try {
        $gzip=New-Object -TypeName System.IO.Compression.GZipStream -ArgumentList @($file,[System.IO.Compression.CompressionMode]::Decompress)
        try { $reader=New-Object -TypeName System.IO.StreamReader -ArgumentList @($gzip,[System.Text.Encoding]::UTF8,$true); try { return $reader.ReadToEnd() } finally { $reader.Dispose() } }
        finally { $gzip.Dispose() }
    } finally { $file.Dispose() }
}
function Write-GZipXml {
    param([System.Xml.XmlDocument]$Xml,[string]$Path)
    $file=[System.IO.File]::Create($Path)
    try {
        $gzip=New-Object -TypeName System.IO.Compression.GZipStream -ArgumentList @($file,[System.IO.Compression.CompressionMode]::Compress)
        try { $enc=New-Object -TypeName System.Text.UTF8Encoding -ArgumentList @($false); $w=New-Object -TypeName System.IO.StreamWriter -ArgumentList @($gzip,$enc); try { $Xml.Save($w); $w.Flush() } finally { $w.Dispose() } }
        finally { $gzip.Dispose() }
    } finally { $file.Dispose() }
}
function Find-EVEMonExe {
    $c=@()
    if (${env:ProgramFiles(x86)}) { $c += (Join-Path ${env:ProgramFiles(x86)} 'EVEMon\EVEMon.exe') }
    if ($env:ProgramFiles) { $c += (Join-Path $env:ProgramFiles 'EVEMon\EVEMon.exe') }
    foreach($p in $c){ if(Test-Path -LiteralPath $p -PathType Leaf){ return (Resolve-Path -LiteralPath $p).Path } }
    return $null
}
function Find-ResourceFile { param([string]$FileName)
    $c=@(); $exe=Find-EVEMonExe
    if($exe){ $c += (Join-Path (Split-Path -Parent $exe) "Resources\$FileName") }
    if(${env:ProgramFiles(x86)}){ $c += (Join-Path ${env:ProgramFiles(x86)} "EVEMon\Resources\$FileName") }
    if($env:ProgramFiles){ $c += (Join-Path $env:ProgramFiles "EVEMon\Resources\$FileName") }
    foreach($p in $c){ if(Test-Path -LiteralPath $p -PathType Leaf){ return (Resolve-Path -LiteralPath $p).Path } }
    return $null
}
function Resolve-DataFile { param([string]$Explicit,[string]$Name,[switch]$Writable)
    if($Explicit){ if(-not(Test-Path -LiteralPath $Explicit -PathType Leaf)){throw "Nie znaleziono $Name`: $Explicit"}; return (Resolve-Path -LiteralPath $Explicit).Path }
    $appDir=Join-Path $env:APPDATA 'EVEMon'; $app=Join-Path $appDir $Name
    if(Test-Path -LiteralPath $app -PathType Leaf){ return (Resolve-Path -LiteralPath $app).Path }
    $res=Find-ResourceFile -FileName $Name
    if(-not $res){ throw "Nie znaleziono $Name w APPDATA ani Resources EVEMona." }
    if($Writable){ New-Item -ItemType Directory -Path $appDir -Force | Out-Null; Copy-Item -LiteralPath $res -Destination $app -Force; return (Resolve-Path -LiteralPath $app).Path }
    return $res
}
function Build-SkillMap { param([System.Xml.XmlDocument]$Xml)
    $m=@{}; foreach($n in @($Xml.SelectNodes("//*[local-name()='skill' and @id and @name]"))){$m[[string]$n.GetAttribute('name')]=[string]$n.GetAttribute('id')}
    if($m.Count -lt 100){throw "Podejrzanie malo skilli: $($m.Count)"}; return $m
}
function Find-ClassByName { param([System.Xml.XmlDocument]$Xml,[string[]]$Names)
    foreach($name in $Names){
        foreach($cl in @($Xml.SelectNodes('/certificatesDatafile/certificateGroup/certificateClass'))){ if([string]$cl.GetAttribute('name') -eq $name){ return $cl } }
    }
    return $null
}
function New-Elem { param([System.Xml.XmlDocument]$Doc,[string]$Name,[hashtable]$Attrs)
    $n=$Doc.CreateElement($Name); foreach($k in $Attrs.Keys){$n.SetAttribute([string]$k,[string]$Attrs[$k])}; return $n
}
function Replace-Requires { param([System.Xml.XmlDocument]$Doc,[System.Xml.XmlElement]$Certificate,$Definition,[hashtable]$SkillMap)
    foreach($old in @($Certificate.SelectNodes('requires'))){[void]$Certificate.RemoveChild($old)}
    foreach($g in @($Definition.grades)){
        $grade=[string]$g.grade
        foreach($r in @($g.requirements)){
            $skill=[string]$r.skill; $level=[int]$r.level
            if(-not $SkillMap.ContainsKey($skill)){throw "Brak skilla '$skill' w EVEMon skills datafile."}
            $n=New-Elem -Doc $Doc -Name 'requires' -Attrs @{id=$SkillMap[$skill];skill=$skill;level=$level;grade=$grade}
            [void]$Certificate.AppendChild($n)
        }
    }
}
function Remove-CustomClasses { param([System.Xml.XmlDocument]$Xml,[int64]$Min,[int64]$Max)
    $removed=@()
    foreach($cl in @($Xml.SelectNodes('/certificatesDatafile/certificateGroup/certificateClass'))){
        $id=0L; [void][long]::TryParse([string]$cl.GetAttribute('id'),[ref]$id)
        if($id -ge $Min -and $id -le $Max){$removed += [string]$cl.GetAttribute('name'); [void]$cl.ParentNode.RemoveChild($cl)}
    }
    return $removed
}

if(Get-Process -Name 'EVEMon' -ErrorAction SilentlyContinue){throw 'EVEMon jest uruchomiony. Zamknij go calkowicie.'}
Write-Host ''
Write-Host 'PREREQUISITE: run EVEMon once and install all datafile/SDE updates before applying this package.' -ForegroundColor Cyan
Write-Host 'Then close EVEMon completely. This installer never patches eve-skills.' -ForegroundColor Cyan
Write-Host ''
if(-not(Test-Path -LiteralPath $DefinitionsPath -PathType Leaf)){throw "Brak definicji: $DefinitionsPath"}
$def=Get-Content -LiteralPath $DefinitionsPath -Raw | ConvertFrom-Json
$defs=@($def.definitions)
$certPath=Resolve-DataFile -Explicit $CertificatesPath -Name $CertificateFileName -Writable
$skillPath=Resolve-DataFile -Explicit $SkillsPath -Name $SkillsFileName
Write-Host "Certificates: $certPath"
Write-Host "Skills:       $skillPath"
[xml]$skillsXml=Read-GZipText -Path $skillPath; $skillMap=Build-SkillMap -Xml $skillsXml
$missing=@($def.required_skills | Where-Object {-not $skillMap.ContainsKey([string]$_)})
if($missing.Count -gt 0){throw "Brak wymaganych skilli ($($missing.Count)):`r`n  - $($missing -join "`r`n  - ")`r`nNic nie zapisano."}
[xml]$xml=Read-GZipText -Path $certPath
if(-not $xml.DocumentElement -or $xml.DocumentElement.Name -ne 'certificatesDatafile'){throw 'Nieoczekiwany format certificates datafile.'}

$matches=@(); $missingCerts=@(); $optionalMissing=@()
foreach($d in $defs | Where-Object {$_.mode -eq 'replace'}){
    $names=@([string]$d.source_name,[string]$d.target_name) | Select-Object -Unique
    $cl=Find-ClassByName -Xml $xml -Names $names
    if(-not $cl){ if([bool]$d.optional){$optionalMissing += [string]$d.source_name}else{$missingCerts += [string]$d.source_name}; continue }
    $matches += [pscustomobject]@{definition=$d;class=$cl;group=$cl.ParentNode}
}
if($missingCerts.Count -gt 0){
    $avail=@($xml.SelectNodes('/certificatesDatafile/certificateGroup/certificateClass') | ForEach-Object {[string]$_.GetAttribute('name')} | Where-Object {$_ -match 'Missile|Turret|Drone|Tanking|Weapon'} | Sort-Object)
    throw "Nie znaleziono wymaganych domyslnych certyfikatow:`r`n  - $($missingCerts -join "`r`n  - ")`r`nKandydaci w pliku:`r`n  - $($avail -join "`r`n  - ")`r`nNic nie zapisano."
}
Write-Host ''
Write-Host 'EVEMon Certificates Enhanced - plan zmian:' -ForegroundColor Cyan
foreach($m in $matches){Write-Host "  REPLACE: $($m.definition.source_name) -> $($m.definition.target_name)"}
foreach($d in $defs | Where-Object {$_.mode -eq 'new'}){Write-Host "  ADD:     $($d.target_name)  [anchor: $($d.group_anchor)]"}
foreach($n in $optionalMissing){Write-Host "  SKIP optional: $n (brak w tej wersji EVEMona)" -ForegroundColor Yellow}
if($Preview){Write-Host '';Write-Host 'PREVIEW - nic nie zapisano.' -ForegroundColor Green; exit 0}

# First-install semantic backup of only the default classes we modify.
$statePath=Join-Path (Split-Path -Parent $certPath) $BackupStateName
if(-not(Test-Path -LiteralPath $statePath -PathType Leaf)){
    $entries=@()
    foreach($m in $matches){
        $cl=$m.class; $grp=$m.group
        $entries += [pscustomobject]@{group_id=[string]$grp.GetAttribute('id');group_name=[string]$grp.GetAttribute('name');class_id=[string]$cl.GetAttribute('id');class_name=[string]$cl.GetAttribute('name');outer_xml=$cl.OuterXml}
    }
    [pscustomobject]@{format=1;created=(Get-Date).ToString('o');certificate_file=$certPath;entries=$entries} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $statePath -Encoding UTF8
    Write-Host "Backup logiczny domyslnych klas: $statePath"
}else{Write-Host "Backup logiczny juz istnieje:      $statePath"}

$customRemoved=Remove-CustomClasses -Xml $xml -Min ([int64]$def.custom_class_id_min) -Max ([int64]$def.custom_class_id_max)
foreach($m in $matches){
    $d=$m.definition; $cl=$m.class
    $cl.SetAttribute('name',[string]$d.target_name)
    $certs=@($cl.SelectNodes('certificate'))
    if($certs.Count -ne 1){throw "Certyfikat '$($d.source_name)' ma $($certs.Count) wezlow certificate; oczekiwano 1."}
    Replace-Requires -Doc $xml -Certificate $certs[0] -Definition $d -SkillMap $skillMap
}
foreach($d in $defs | Where-Object {$_.mode -eq 'new'}){
    $anchor=Find-ClassByName -Xml $xml -Names @([string]$d.group_anchor)
    if(-not $anchor){throw "Nie znaleziono anchor '$($d.group_anchor)' dla '$($d.target_name)'."}
    $group=$anchor.ParentNode
    $cl=New-Elem -Doc $xml -Name 'certificateClass' -Attrs @{id=[string]$d.class_id;name=[string]$d.target_name;description=[string]$d.description}
    $cert=New-Elem -Doc $xml -Name 'certificate' -Attrs @{id=[string]$d.certificate_id;description=[string]$d.description}
    Replace-Requires -Doc $xml -Certificate $cert -Definition $d -SkillMap $skillMap
    [void]$cl.AppendChild($cert); [void]$group.AppendChild($cl)
}

# Validate every patched/new cert has exactly all five grades and resolvable skills.
foreach($d in $defs){
    $cl=Find-ClassByName -Xml $xml -Names @([string]$d.target_name)
    if(-not $cl){ if([bool]$d.optional){continue}else{throw "Walidacja: brak '$($d.target_name)'"} }
    $cert=@($cl.SelectNodes('certificate'))[0]
    foreach($g in $AllowedGrades){ if(@($cert.SelectNodes("requires[@grade='$g']")).Count -eq 0){throw "Walidacja: '$($d.target_name)' nie ma grade $g"} }
}
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'; $backup="$certPath.backup-certificates-enhanced-$stamp"; $tmp="$certPath.certificates-enhanced-temp"
try{
    if(Test-Path -LiteralPath $tmp){Remove-Item -LiteralPath $tmp -Force}
    Write-GZipXml -Xml $xml -Path $tmp
    [xml]$verify=Read-GZipText -Path $tmp
    if(-not $verify.DocumentElement){throw 'Walidacja gzip/XML nie powiodla sie.'}
    Copy-Item -LiteralPath $certPath -Destination $backup -Force
    Copy-Item -LiteralPath $tmp -Destination $certPath -Force
} finally { if(Test-Path -LiteralPath $tmp){Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue} }
Write-Host ''
Write-Host 'OK - zainstalowano EVEMon Certificates Enhanced.' -ForegroundColor Green
Write-Host "Backup calego datafile: $backup"
Write-Host "Backup logiczny:         $statePath"
Write-Host "Usuniete poprzednie custom classes tego projektu: $($customRemoved.Count)"
Write-Host 'eve-skills: NIE MODYFIKOWANY.'
Write-Host 'Uwaga: zmienione wymagania domyslnych certyfikatow zmieniaja tez ich wynik w Ship Mastery; eve-masteries nie jest patchowany.' -ForegroundColor Yellow
