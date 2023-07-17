# Getting Started

Ao copiar este projeto deve-se fazer as seguintes configurações:

Definir as seguintes variaveis de ambiente

    DATABASE_SCHEMA_NAME=<nome >
    DB_NAME=<No<me do banco |POSTGRES|MYSQL>
    DB_PASSWORD=<Senha do bancp>
    DB_USERNAME=<usuario banco>
    SECRET_JWT=<Secret JWT>
    SERVER_PORT=<POrta servidor>
    SERVICE_NAME=<NOme do serviço>

O projeto é configurado para ser multitenancy com locatarios usando schemas

sendo assim os schemas da base deven ser cirados usando o seguinte padrão:

"NOMEBANCO_NOMESCHEMA" ambos em maiusculo, para manter um padrão, mas o nome do schema não precisa ser necessariamente maiusculo
basta estar de acordo com o cadastrado na tabela user_supplier
