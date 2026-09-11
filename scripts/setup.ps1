param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$BakPath
)

$ErrorActionPreference = "Stop"

$SQLSERVER_CONTAINER = "etl-bd-source"
$DB_DIR = "/var/opt/mssql/AdvenWorkBAK"
$SA_PASSWORD = "SqlServer123!"

# ============================================================
# Validação do argumento
# ============================================================

if ([string]::IsNullOrWhiteSpace($BakPath)) {
    Write-Host "Uso:"
    Write-Host "  .\scripts\setup.ps1 C:\caminho\para\banco.bak"
    exit 1
}

if (!(Test-Path -LiteralPath $BakPath -PathType Leaf)) {
    Write-Host "ERRO: arquivo não encontrado:"
    Write-Host $BakPath
    exit 1
}

# Obtém caminho absoluto
$BakPath = (Resolve-Path -LiteralPath $BakPath).Path

# ============================================================
# Iniciando Docker
# ============================================================

Write-Host "======================================"
Write-Host " Iniciando ambiente Docker"
Write-Host "======================================"

docker compose up -d

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: docker compose up falhou."
    exit 1
}

# ============================================================
# Aguardando SQL Server
# ============================================================

Write-Host ""
Write-Host "Aguardando SQL Server iniciar..."

$Ready = $false

while (!$Ready) {

    docker exec $SQLSERVER_CONTAINER `
        /opt/mssql-tools18/bin/sqlcmd `
        -S localhost `
        -U sa `
        -P $SA_PASSWORD `
        -C `
        -Q "SELECT 1" `
        2>$null

    if ($LASTEXITCODE -eq 0) {
        $Ready = $true
    }
    else {
        Write-Host "Aguardando SQL Server..."
        Start-Sleep -Seconds 3
    }
}

Write-Host "SQL Server pronto."

# ============================================================
# Criando diretório para o backup
# ============================================================

Write-Host ""
Write-Host "Criando diretório para o backup..."

docker exec $SQLSERVER_CONTAINER `
    mkdir -p $DB_DIR

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: não foi possível criar o diretório."
    exit 1
}

# ============================================================
# Copiando backup
# ============================================================

Write-Host ""
Write-Host "Copiando arquivo do AdventureWorks para o container..."

docker cp $BakPath `
    "${SQLSERVER_CONTAINER}:${DB_DIR}/database.bak"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: não foi possível copiar o arquivo."
    exit 1
}

# ============================================================
# Verificando backup
# ============================================================

Write-Host ""
Write-Host "Verificando arquivo de backup..."

docker exec $SQLSERVER_CONTAINER `
    ls -lh "${DB_DIR}/database.bak"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: arquivo de backup não encontrado dentro do container."
    exit 1
}

# ============================================================
# RESTORE FILELISTONLY
# ============================================================

Write-Host ""
Write-Host "Descobrindo informações do backup..."

$FileListQuery = @"
SET NOCOUNT ON;

RESTORE FILELISTONLY
FROM DISK = '$DB_DIR/database.bak';
"@

$FileList = docker exec $SQLSERVER_CONTAINER `
    /opt/mssql-tools18/bin/sqlcmd `
    -S localhost `
    -U sa `
    -P $SA_PASSWORD `
    -C `
    -h -1 `
    -W `
    -w 65535 `
    -s "|" `
    -Q $FileListQuery

if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($FileList)) {
    Write-Host "ERRO: não foi possível ler o arquivo de backup."
    exit 1
}

Write-Host ""
Write-Host "Arquivos encontrados no backup:"
Write-Host $FileList

# ============================================================
# Identificando arquivos DATA e LOG
#
# RESTORE FILELISTONLY:
# Campo 1 = LogicalName
# Campo 3 = Type
#
# Type:
# D = Data
# L = Log
# ============================================================

$LogicalData = $null
$LogicalLog = $null

$Lines = $FileList -split "`r?`n"

foreach ($Line in $Lines) {

    if ([string]::IsNullOrWhiteSpace($Line)) {
        continue
    }

    $Fields = $Line -split "\|"

    if ($Fields.Count -lt 3) {
        continue
    }

    $LogicalName = $Fields[0].Trim()
    $FileType = $Fields[2].Trim()

    if ($FileType -eq "D" -and [string]::IsNullOrWhiteSpace($LogicalData)) {
        $LogicalData = $LogicalName
    }

    if ($FileType -eq "L" -and [string]::IsNullOrWhiteSpace($LogicalLog)) {
        $LogicalLog = $LogicalName
    }
}

if ([string]::IsNullOrWhiteSpace($LogicalData)) {
    Write-Host ""
    Write-Host "ERRO: não foi possível identificar o arquivo de dados do backup."
    exit 1
}

if ([string]::IsNullOrWhiteSpace($LogicalLog)) {
    Write-Host ""
    Write-Host "ERRO: não foi possível identificar o arquivo de log do backup."
    exit 1
}

Write-Host ""
Write-Host "Logical Data: $LogicalData"
Write-Host "Logical Log : $LogicalLog"

# ============================================================
# Nome do banco
# ============================================================

$DatabaseName = [System.IO.Path]::GetFileNameWithoutExtension($BakPath)

# Equivalente ao:
# tr -cd '[:alnum:]_-'

$DatabaseName = $DatabaseName -replace '[^a-zA-Z0-9_-]', ''

if ([string]::IsNullOrWhiteSpace($DatabaseName)) {
    $DatabaseName = "adventure_works_db"
}

Write-Host ""
Write-Host "Banco que será restaurado: $DatabaseName"

# ============================================================
# Verificando se banco já existe
# ============================================================

Write-Host ""
Write-Host "Verificando se o banco já existe..."

$DatabaseExists = docker exec $SQLSERVER_CONTAINER `
    /opt/mssql-tools18/bin/sqlcmd `
    -S localhost `
    -U sa `
    -P $SA_PASSWORD `
    -C `
    -h -1 `
    -W `
    -Q "SET NOCOUNT ON;
        SELECT COUNT(*)
        FROM sys.databases
        WHERE name = '$DatabaseName';"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: não foi possível verificar os bancos existentes."
    exit 1
}

$DatabaseExists = $DatabaseExists.Trim()

if ($DatabaseExists -eq "1") {

    Write-Host ""
    Write-Host "O banco '$DatabaseName' já existe."
    Write-Host "Nenhuma restauração será realizada."

}
else {

    # ========================================================
    # Restaurando banco
    # ========================================================

    Write-Host ""
    Write-Host "Restaurando banco..."

    # Escapa aspas simples caso o LogicalName contenha uma
    $SafeLogicalData = $LogicalData.Replace("'", "''")
    $SafeLogicalLog = $LogicalLog.Replace("'", "''")

    $RestoreQuery = @"
RESTORE DATABASE [$DatabaseName]
FROM DISK = '$DB_DIR/database.bak'
WITH
    MOVE '$SafeLogicalData' TO '/var/opt/mssql/data/${DatabaseName}.mdf',
    MOVE '$SafeLogicalLog' TO '/var/opt/mssql/data/${DatabaseName}_log.ldf',
    RECOVERY,
    REPLACE;
"@

    docker exec $SQLSERVER_CONTAINER `
        /opt/mssql-tools18/bin/sqlcmd `
        -S localhost `
        -U sa `
        -P $SA_PASSWORD `
        -C `
        -Q $RestoreQuery

    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "ERRO: falha ao restaurar o banco."
        exit 1
    }

    Write-Host ""
    Write-Host "Banco restaurado com sucesso."
}

# ============================================================
# Final
# ============================================================

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
Write-Host "  Password: $SA_PASSWORD"

Write-Host ""
Write-Host "DBeaver pode ser usado normalmente."
