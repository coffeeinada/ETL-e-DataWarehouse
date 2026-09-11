param(
    [Parameter(Mandatory=$true)]
    [string]$BakPath
)

$Container = "etl-bd-source"
$BackupDir = "/var/opt/mssql/AdvenWorkBAK"
$Password = "SqlServer123!"

if (!(Test-Path $BakPath)) {
    Write-Host "ERRO: arquivo não encontrado:"
    Write-Host $BakPath
    exit 1
}

Write-Host "======================================"
Write-Host " Iniciando ambiente Docker"
Write-Host "======================================"

docker compose up -d

Write-Host ""
Write-Host "Aguardando SQL Server iniciar..."

do {
    Start-Sleep -Seconds 3

    docker exec $Container `
        /opt/mssql-tools18/bin/sqlcmd `
        -S localhost `
        -U sa `
        -P $Password `
        -C `
        -Q "SELECT 1" 2>$null

    $Ready = ($LASTEXITCODE -eq 0)

    if (!$Ready) {
        Write-Host "Aguardando SQL Server..."
    }

} while (!$Ready)

Write-Host "SQL Server pronto."

Write-Host ""
Write-Host "Copiando backup para o container..."

docker exec $Container mkdir -p $BackupDir

docker cp $BakPath `
    "${Container}:${BackupDir}/database.bak"

Write-Host ""
Write-Host "Descobrindo informações do backup..."

$FileList = docker exec $Container `
    /opt/mssql-tools18/bin/sqlcmd `
    -S localhost `
    -U sa `
    -P $Password `
    -C `
    -h -1 `
    -W `
    -Q "SET NOCOUNT ON;
        RESTORE FILELISTONLY
        FROM DISK = '$BackupDir/database.bak';"

$Lines = $FileList -split "`r?`n"

$LogicalData = $Lines[0].Trim()
$LogicalLog = $Lines[1].Trim()

if ([string]::IsNullOrWhiteSpace($LogicalData) -or
    [string]::IsNullOrWhiteSpace($LogicalLog)) {

    Write-Host "ERRO: não foi possível identificar os arquivos do backup."
    exit 1
}

Write-Host "Logical Data: $LogicalData"
Write-Host "Logical Log : $LogicalLog"

$DatabaseName = [System.IO.Path]::GetFileNameWithoutExtension($BakPath)

$DatabaseName = $DatabaseName -replace '[^a-zA-Z0-9_-]', '_'

Write-Host ""
Write-Host "Banco que será restaurado: $DatabaseName"

$Exists = docker exec $Container `
    /opt/mssql-tools18/bin/sqlcmd `
    -S localhost `
    -U sa `
    -P $Password `
    -C `
    -h -1 `
    -W `
    -Q "SET NOCOUNT ON;
        SELECT COUNT(*)
        FROM sys.databases
        WHERE name = '$DatabaseName';"

$Exists = $Exists.Trim()

if ($Exists -eq "1") {

    Write-Host ""
    Write-Host "O banco '$DatabaseName' já existe."
    Write-Host "Nenhuma restauração será realizada."

} else {

    Write-Host ""
    Write-Host "Restaurando banco..."

    $Sql = @"
RESTORE DATABASE [$DatabaseName]
FROM DISK = '$BackupDir/database.bak'
WITH
    MOVE '$LogicalData' TO '/var/opt/mssql/data/${DatabaseName}.mdf',
    MOVE '$LogicalLog' TO '/var/opt/mssql/data/${DatabaseName}_log.ldf',
    RECOVERY,
    REPLACE;
"@

    docker exec $Container `
        /opt/mssql-tools18/bin/sqlcmd `
        -S localhost `
        -U sa `
        -P $Password `
        -C `
        -Q $Sql

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERRO ao restaurar o banco."
        exit 1
    }

    Write-Host ""
    Write-Host "Banco restaurado com sucesso."
}

Write-Host ""
Write-Host "======================================"
Write-Host " Ambiente pronto!"
Write-Host "======================================"

Write-Host ""
Write-Host "PostgreSQL:"
Write-Host "  Host: localhost"
Write-Host "  Port: 5432"
Write-Host "  Database: etl-warehouse"
Write-Host "  User: postgres"
Write-Host "  Password: postgres123"

Write-Host ""
Write-Host "SQL Server:"
Write-Host "  Host: localhost"
Write-Host "  Port: 1433"
Write-Host "  Database: $DatabaseName"
Write-Host "  User: sa"
Write-Host "  Password: $Password"