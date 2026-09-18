$ErrorActionPreference = "Stop"

$ProjectRoot = $PSScriptRoot
$ProjectFile = Join-Path $ProjectRoot ".gonthera/project.json"
$PomFile = Join-Path $ProjectRoot "pom.xml"
$JavaPlaceholder = "__SETUP_PROJECT_MAIN_PACKAGE__"
$Utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)

function Stop-Setup([string]$Message) {
    throw "Erro: $Message"
}

function Test-ProjectName([string]$Value) {
    return $Value -match '^[a-z][a-z0-9-]*$'
}

function Test-JavaPackage([string]$Value) {
    if ($Value -notmatch '^[a-z_][a-z0-9_]*(\.[a-z_][a-z0-9_]*)+$') {
        return $false
    }

    $Keywords = @(
        "abstract", "assert", "boolean", "break", "byte", "case", "catch", "char",
        "class", "const", "continue", "default", "do", "double", "else", "enum",
        "extends", "final", "finally", "float", "for", "goto", "if", "implements",
        "import", "instanceof", "int", "interface", "long", "native", "new", "package",
        "private", "protected", "public", "return", "short", "static", "strictfp", "super",
        "switch", "synchronized", "this", "throw", "throws", "transient", "try", "void",
        "volatile", "while", "record", "sealed", "permits", "var", "yield"
    )

    foreach ($Segment in $Value.Split('.')) {
        if ($Keywords -contains $Segment) {
            return $false
        }
    }

    return $true
}

function Read-ValidValue(
    [string]$Prompt,
    [string]$Example,
    [scriptblock]$Validator
) {
    while ($true) {
        Write-Host $Prompt
        $Value = Read-Host "Exemplo: $Example`n>"

        if (& $Validator $Value) {
            return $Value
        }

        Write-Host "Valor inválido. Tente novamente.`n" -ForegroundColor Yellow
    }
}

function Write-Utf8File([string]$Path, [string]$Content) {
    [System.IO.File]::WriteAllText($Path, $Content, $Utf8WithoutBom)
}

function Update-Pom(
    [string]$GroupId,
    [string]$ArtifactId
) {
    [xml]$Pom = Get-Content -LiteralPath $PomFile -Raw
    $Namespace = New-Object System.Xml.XmlNamespaceManager($Pom.NameTable)
    $Namespace.AddNamespace("m", $Pom.DocumentElement.NamespaceURI)

    $GroupNode = $Pom.SelectSingleNode("/m:project/m:groupId", $Namespace)
    $ArtifactNode = $Pom.SelectSingleNode("/m:project/m:artifactId", $Namespace)
    $NameNode = $Pom.SelectSingleNode("/m:project/m:name", $Namespace)
    $DescriptionNode = $Pom.SelectSingleNode("/m:project/m:description", $Namespace)

    if ($null -eq $GroupNode -or $null -eq $ArtifactNode -or $null -eq $NameNode -or $null -eq $DescriptionNode) {
        Stop-Setup "não foi possível localizar as coordenadas do projeto no pom.xml."
    }

    $GroupNode.InnerText = $GroupId
    $ArtifactNode.InnerText = $ArtifactId
    $NameNode.InnerText = $ArtifactId
    $DescriptionNode.InnerText = $ArtifactId

    $Settings = New-Object System.Xml.XmlWriterSettings
    $Settings.Indent = $true
    $Settings.IndentChars = "`t"
    $Settings.Encoding = $Utf8WithoutBom
    $Settings.OmitXmlDeclaration = $false

    $Writer = [System.Xml.XmlWriter]::Create($PomFile, $Settings)
    try {
        $Pom.Save($Writer)
    } finally {
        $Writer.Dispose()
    }
}

function Update-JavaSources(
    [string]$OldMainPackage,
    [string]$NewMainPackage,
    [string]$OldRootPackage,
    [string]$NewRootPackage
) {
    $SourceRoots = @(
        (Join-Path $ProjectRoot "src/main/java"),
        (Join-Path $ProjectRoot "src/test/java")
    )

    $JavaFiles = Get-ChildItem -LiteralPath $SourceRoots -Filter "*.java" -File -Recurse |
        Where-Object { $_.FullName -notmatch '[\\/][^\\/]+_gen[\\/]' }

    foreach ($File in $JavaFiles) {
        $Content = [System.IO.File]::ReadAllText($File.FullName)
        $Content = $Content.Replace($OldMainPackage, $JavaPlaceholder)
        $Content = $Content.Replace($OldRootPackage, $NewRootPackage)
        $Content = $Content.Replace($JavaPlaceholder, $NewMainPackage)
        Write-Utf8File $File.FullName $Content
    }

    foreach ($File in $JavaFiles) {
        if (-not (Test-Path -LiteralPath $File.FullName)) {
            continue
        }

        $Content = [System.IO.File]::ReadAllText($File.FullName)
        $PackageMatch = [regex]::Match($Content, '(?m)^\s*package\s+([a-zA-Z0-9_.]+)\s*;')
        if (-not $PackageMatch.Success) {
            continue
        }

        $SourceRoot = $SourceRoots | Where-Object { $File.FullName.StartsWith("$_$([System.IO.Path]::DirectorySeparatorChar)") } | Select-Object -First 1
        if ($null -eq $SourceRoot) {
            Stop-Setup "fonte Java fora dos diretórios esperados: $($File.FullName)"
        }

        $PackagePath = $PackageMatch.Groups[1].Value.Replace('.', [System.IO.Path]::DirectorySeparatorChar)
        $DestinationDirectory = Join-Path $SourceRoot $PackagePath
        $DestinationFile = Join-Path $DestinationDirectory $File.Name

        if ($File.FullName -ne $DestinationFile) {
            if (Test-Path -LiteralPath $DestinationFile) {
                Stop-Setup "o destino já existe: $DestinationFile"
            }

            New-Item -ItemType Directory -Path $DestinationDirectory -Force | Out-Null
            Move-Item -LiteralPath $File.FullName -Destination $DestinationFile
        }
    }

    foreach ($SourceRoot in $SourceRoots) {
        Get-ChildItem -LiteralPath $SourceRoot -Directory -Recurse |
            Sort-Object FullName -Descending |
            Where-Object { -not (Get-ChildItem -LiteralPath $_.FullName -Force) } |
            Remove-Item -Force
    }
}

if (-not (Test-Path -LiteralPath $PomFile)) {
    Stop-Setup "pom.xml não encontrado ao lado do script."
}
if (-not (Test-Path -LiteralPath $ProjectFile)) {
    Stop-Setup ".gonthera/project.json não encontrado ao lado do script."
}
if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot "mvnw.cmd"))) {
    Stop-Setup "Maven Wrapper não encontrado ao lado do script."
}

$GontheraProject = Get-Content -LiteralPath $ProjectFile -Raw | ConvertFrom-Json
$OldMainPackage = [string]$GontheraProject.mainPackage
$OldProjectName = [string]$GontheraProject.projectName

if ([string]::IsNullOrWhiteSpace($OldMainPackage) -or [string]::IsNullOrWhiteSpace($OldProjectName)) {
    Stop-Setup "mainPackage ou projectName ausente em .gonthera/project.json."
}

$OldRootPackage = $OldMainPackage.Substring(0, $OldMainPackage.LastIndexOf('.'))
$ProjectName = Read-ValidValue "Informe o nome do projeto." "customer-service" { param($Value) Test-ProjectName $Value }
$NewMainPackage = Read-ValidValue "Informe o pacote Java principal." "com.gonthera.customerservice" { param($Value) Test-JavaPackage $Value }
$NewRootPackage = $NewMainPackage.Substring(0, $NewMainPackage.LastIndexOf('.'))
$ParentDirectory = Split-Path -Parent $ProjectRoot
$TargetDirectory = Join-Path $ParentDirectory $ProjectName

if ($TargetDirectory -ne $ProjectRoot -and (Test-Path -LiteralPath $TargetDirectory)) {
    Stop-Setup "já existe um arquivo ou diretório em $TargetDirectory."
}

Write-Host "`nConfiguração solicitada:"
Write-Host "  Projeto:        $ProjectName"
Write-Host "  Pasta:          $ProjectName"
Write-Host "  Maven groupId:  $NewRootPackage"
Write-Host "  Maven artifact: $ProjectName"
Write-Host "  Pacote Java:    $NewMainPackage"
Write-Host "  Pacote raiz:    $NewRootPackage"

$Confirmation = Read-Host "`nO diretório .git atual será excluído ao final. Continuar? [s/N]"
if ($Confirmation -notmatch '^(s|sim)$') {
    Write-Host "Configuração cancelada."
    exit 0
}

$GontheraProject.projectName = $ProjectName
$GontheraProject.mainPackage = $NewMainPackage
$ProjectJson = $GontheraProject | ConvertTo-Json -Depth 100
Write-Utf8File $ProjectFile "$ProjectJson`n"

Update-Pom $NewRootPackage $ProjectName
Update-JavaSources $OldMainPackage $NewMainPackage $OldRootPackage $NewRootPackage

Write-Host "`nValidando a configuração do Gonthera CLI..."
Push-Location $ProjectRoot
try {
    & (Join-Path $ProjectRoot "mvnw.cmd") -B -ntp gonthera-cli:validate
    if ($LASTEXITCODE -ne 0) {
        Stop-Setup "a validação falhou. O Git foi preservado para permitir a revisão das alterações."
    }
} finally {
    Pop-Location
}

$FinalDirectory = $ProjectRoot
if ($TargetDirectory -ne $ProjectRoot) {
    Set-Location $ParentDirectory
    Rename-Item -LiteralPath $ProjectRoot -NewName $ProjectName
    $FinalDirectory = $TargetDirectory
}

$GitDirectory = Join-Path $FinalDirectory ".git"
if (Test-Path -LiteralPath $GitDirectory) {
    Remove-Item -LiteralPath $GitDirectory -Recurse -Force
}

Write-Host "`nProjeto configurado com sucesso." -ForegroundColor Green
Write-Host "Diretório: $FinalDirectory"
Write-Host "O repositório Git do template foi removido. Use git init quando quiser iniciar o novo histórico."
