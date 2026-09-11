#!/usr/bin/env bash

set -e

SQLSERVER_CONTAINER="etl-bd-source"
BAK_PATH="$1"
DB_DIR="/var/opt/mssql/AdvenWorkBAK"
SA_PASSWORD="SqlServer123!"

if [ -z "$BAK_PATH" ]; then
    echo "Uso:"
    echo "  ./scripts/setup.sh /caminho/para/banco.bak"
    exit 1
fi

if [ ! -f "$BAK_PATH" ]; then
    echo "ERRO: arquivo não encontrado:"
    echo "$BAK_PATH"
    exit 1
fi

echo "======================================"
echo " Iniciando ambiente Docker"
echo "======================================"

docker compose up -d

echo ""
echo "Aguardando SQL Server iniciar..."

until docker exec "$SQLSERVER_CONTAINER" \
    /opt/mssql-tools18/bin/sqlcmd \
    -S localhost \
    -U sa \
    -P "$SA_PASSWORD" \
    -C \
    -Q "SELECT 1" > /dev/null 2>&1
do
    sleep 3
    echo "Aguardando SQL Server..."
done

echo "SQL Server pronto."

echo ""
echo "Criando diretório para o backup..."

docker exec "$SQLSERVER_CONTAINER" \
    mkdir -p "$DB_DIR"

echo ""
echo "Copiando arquivo do AdventureWorks para o container..."

docker cp "$BAK_PATH" \
    "$SQLSERVER_CONTAINER:$DB_DIR/database.bak"

echo ""
echo "Verificando arquivo de backup..."

docker exec "$SQLSERVER_CONTAINER" \
    ls -lh "$DB_DIR/database.bak"

echo ""
echo "Descobrindo informações do backup..."

FILELIST=$(docker exec "$SQLSERVER_CONTAINER" \
    /opt/mssql-tools18/bin/sqlcmd \
    -S localhost \
    -U sa \
    -P "$SA_PASSWORD" \
    -C \
    -h -1 \
    -W \
    -w 65535 \
    -s "|" \
    -Q "SET NOCOUNT ON;
        RESTORE FILELISTONLY
        FROM DISK = '$DB_DIR/database.bak';")

if [ -z "$FILELIST" ]; then
    echo "ERRO: não foi possível ler o arquivo de backup."
    exit 1
fi

echo ""
echo "Arquivos encontrados no backup:"
echo "$FILELIST"

# RESTORE FILELISTONLY:
# Campo 1 = LogicalName
# Campo 3 = Type
#
# Type:
# D = Data
# L = Log

LOGICAL_DATA=$(echo "$FILELIST" | \
    awk -F'|' '$3 ~ /^[[:space:]]*D[[:space:]]*$/ {print $1; exit}' | xargs)

LOGICAL_LOG=$(echo "$FILELIST" | \
    awk -F'|' '$3 ~ /^[[:space:]]*L[[:space:]]*$/ {print $1; exit}' | xargs)

if [ -z "$LOGICAL_DATA" ]; then
    echo ""
    echo "ERRO: não foi possível identificar o arquivo de dados do backup."
    exit 1
fi

if [ -z "$LOGICAL_LOG" ]; then
    echo ""
    echo "ERRO: não foi possível identificar o arquivo de log do backup."
    exit 1
fi

echo ""
echo "Logical Data: $LOGICAL_DATA"
echo "Logical Log : $LOGICAL_LOG"

DATABASE_NAME=$(basename "$BAK_PATH" .bak | tr -cd '[:alnum:]_-')

if [ -z "$DATABASE_NAME" ]; then
    DATABASE_NAME="adventure_works_db"
fi

echo ""
echo "Banco que será restaurado: $DATABASE_NAME"

echo ""
echo "Verificando se o banco já existe..."

DATABASE_EXISTS=$(docker exec "$SQLSERVER_CONTAINER" \
    /opt/mssql-tools18/bin/sqlcmd \
    -S localhost \
    -U sa \
    -P "$SA_PASSWORD" \
    -C \
    -h -1 \
    -W \
    -Q "SET NOCOUNT ON;
        SELECT COUNT(*)
        FROM sys.databases
        WHERE name = '$DATABASE_NAME';")

DATABASE_EXISTS=$(echo "$DATABASE_EXISTS" | xargs)

if [ "$DATABASE_EXISTS" = "1" ]; then

    echo ""
    echo "O banco '$DATABASE_NAME' já existe."
    echo "Nenhuma restauração será realizada."

else

    echo ""
    echo "Restaurando banco..."

    docker exec "$SQLSERVER_CONTAINER" \
        /opt/mssql-tools18/bin/sqlcmd \
        -S localhost \
        -U sa \
        -P "$SA_PASSWORD" \
        -C \
        -Q "RESTORE DATABASE [$DATABASE_NAME]
            FROM DISK = '$DB_DIR/database.bak'
            WITH
                MOVE '$LOGICAL_DATA' TO '/var/opt/mssql/data/${DATABASE_NAME}.mdf',
                MOVE '$LOGICAL_LOG' TO '/var/opt/mssql/data/${DATABASE_NAME}_log.ldf',
                RECOVERY,
                REPLACE;"

    echo ""
    echo "Banco restaurado com sucesso."

fi

echo ""
echo "======================================"
echo " Ambiente pronto!"
echo "======================================"

echo ""
echo "PostgreSQL:"
echo "  Host: localhost"
echo "  Port: 5432"
echo "  Database: etl-warehouse"
echo "  User: postgres"
echo "  Password: postgres123"

echo ""
echo "SQL Server:"
echo "  Host: localhost"
echo "  Port: 1433"
echo "  Database: $DATABASE_NAME"
echo "  User: sa"
echo "  Password: $SA_PASSWORD"

echo ""
echo "DBeaver pode ser usado normalmente."