#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_FILE="$SCRIPT_DIR/.gonthera/project.json"
POM_FILE="$SCRIPT_DIR/pom.xml"
JAVA_PLACEHOLDER="__SETUP_PROJECT_MAIN_PACKAGE__"
TEMP_FILES=()
LAST_TEMP_FILE=""

cleanup() {
    local file
    for file in "${TEMP_FILES[@]}"; do
        if [[ -f "$file" ]]; then
            rm -f -- "$file"
        fi
    done
    return 0
}

trap cleanup EXIT

fail() {
    printf 'Erro: %s\n' "$1" >&2
    exit 1
}

require_project_root() {
    [[ -f "$POM_FILE" ]] || fail "pom.xml não encontrado ao lado do script."
    [[ -f "$PROJECT_FILE" ]] || fail ".gonthera/project.json não encontrado ao lado do script."
    [[ -f "$SCRIPT_DIR/mvnw" ]] || fail "Maven Wrapper não encontrado ao lado do script."
}

json_string_value() {
    local key="$1"
    awk -F '"' -v key="$key" '$0 ~ "\\\"" key "\\\"[[:space:]]*:" { print $4; exit }' "$PROJECT_FILE"
}

validate_project_name() {
    [[ "$1" =~ ^[a-z][a-z0-9-]*$ ]]
}

validate_java_package() {
    local package_name="$1"
    local segment

    [[ "$package_name" =~ ^[a-z_][a-z0-9_]*(\.[a-z_][a-z0-9_]*)+$ ]] || return 1

    IFS='.' read -r -a segments <<< "$package_name"
    for segment in "${segments[@]}"; do
        case "$segment" in
            abstract|assert|boolean|break|byte|case|catch|char|class|const|continue|default|do|double|else|enum|extends|final|finally|float|for|goto|if|implements|import|instanceof|int|interface|long|native|new|package|private|protected|public|return|short|static|strictfp|super|switch|synchronized|this|throw|throws|transient|try|void|volatile|while|record|sealed|permits|var|yield)
                return 1
                ;;
        esac
    done
}

prompt_until_valid() {
    local prompt="$1"
    local example="$2"
    local validator="$3"
    local value

    while true; do
        printf '%s\n' "$prompt" >&2
        printf 'Exemplo: %s\n> ' "$example" >&2
        IFS= read -r value

        if "$validator" "$value"; then
            printf '%s' "$value"
            return
        fi

        printf 'Valor inválido. Tente novamente.\n\n' >&2
    done
}

new_temp_file() {
    LAST_TEMP_FILE="$(mktemp "${TMPDIR:-/tmp}/setup-project.XXXXXX")"
    TEMP_FILES+=("$LAST_TEMP_FILE")
}

replace_literal_in_file() {
    local file="$1"
    local old_value="$2"
    local new_value="$3"
    local temp_file

    [[ "$old_value" == "$new_value" ]] && return

    new_temp_file
    temp_file="$LAST_TEMP_FILE"
    awk -v old="$old_value" -v new="$new_value" '
        {
            line = $0
            output = ""
            while ((position = index(line, old)) > 0) {
                output = output substr(line, 1, position - 1) new
                line = substr(line, position + length(old))
            }
            print output line
        }
    ' "$file" > "$temp_file"
    mv -- "$temp_file" "$file"
}

update_pom_coordinates() {
    local group_id="$1"
    local artifact_id="$2"
    local temp_file

    new_temp_file
    temp_file="$LAST_TEMP_FILE"
    awk -v group_id="$group_id" -v artifact_id="$artifact_id" '
        {
            line = $0

            if (!parent_closed) {
                print line
                if (line ~ /<\/parent>/) {
                    parent_closed = 1
                }
                next
            }

            if (!group_updated && line ~ /<groupId>[^<]*<\/groupId>/) {
                sub(/<groupId>[^<]*<\/groupId>/, "<groupId>" group_id "</groupId>", line)
                group_updated = 1
            } else if (!artifact_updated && line ~ /<artifactId>[^<]*<\/artifactId>/) {
                sub(/<artifactId>[^<]*<\/artifactId>/, "<artifactId>" artifact_id "</artifactId>", line)
                artifact_updated = 1
            } else if (!name_updated && line ~ /<name>[^<]*<\/name>/) {
                sub(/<name>[^<]*<\/name>/, "<name>" artifact_id "</name>", line)
                name_updated = 1
            } else if (!description_updated && line ~ /<description>[^<]*<\/description>/) {
                sub(/<description>[^<]*<\/description>/, "<description>" artifact_id "</description>", line)
                description_updated = 1
            }

            print line
        }

        END {
            if (!group_updated || !artifact_updated || !name_updated || !description_updated) {
                exit 2
            }
        }
    ' "$POM_FILE" > "$temp_file" || fail "não foi possível atualizar as coordenadas do pom.xml."
    mv -- "$temp_file" "$POM_FILE"
}

update_manual_java_sources() {
    local old_main_package="$1"
    local new_main_package="$2"
    local old_root_package="$3"
    local new_root_package="$4"
    local source_list
    local file

    new_temp_file
    source_list="$LAST_TEMP_FILE"
    find "$SCRIPT_DIR/src/main/java" "$SCRIPT_DIR/src/test/java" \
        -type f -name '*.java' ! -path '*_gen/*' -print > "$source_list"

    while IFS= read -r file; do
        replace_literal_in_file "$file" "$old_main_package" "$JAVA_PLACEHOLDER"
        replace_literal_in_file "$file" "$old_root_package" "$new_root_package"
        replace_literal_in_file "$file" "$JAVA_PLACEHOLDER" "$new_main_package"
    done < "$source_list"

    relocate_java_sources "$source_list"
}

relocate_java_sources() {
    local source_list="$1"
    local file
    local source_root
    local package_name
    local destination_directory
    local destination_file

    while IFS= read -r file; do
        [[ -f "$file" ]] || continue

        case "$file" in
            "$SCRIPT_DIR/src/main/java/"*) source_root="$SCRIPT_DIR/src/main/java" ;;
            "$SCRIPT_DIR/src/test/java/"*) source_root="$SCRIPT_DIR/src/test/java" ;;
            *) fail "fonte Java fora dos diretórios esperados: $file" ;;
        esac

        package_name="$(awk '
            /^[[:space:]]*package[[:space:]]+/ {
                line = $0
                sub(/^[[:space:]]*package[[:space:]]+/, "", line)
                sub(/[[:space:]]*;[[:space:]]*$/, "", line)
                print line
                exit
            }
        ' "$file")"

        [[ -n "$package_name" ]] || continue

        destination_directory="$source_root/${package_name//.//}"
        destination_file="$destination_directory/$(basename -- "$file")"

        if [[ "$file" != "$destination_file" ]]; then
            [[ ! -e "$destination_file" ]] || fail "o destino já existe: $destination_file"
            mkdir -p -- "$destination_directory"
            mv -- "$file" "$destination_file"
        fi
    done < "$source_list"

    find "$SCRIPT_DIR/src/main/java" "$SCRIPT_DIR/src/test/java" -depth -type d -empty -delete
}

confirm_configuration() {
    local confirmation

    printf '\nConfiguração solicitada:\n'
    printf '  Projeto:        %s\n' "$PROJECT_NAME"
    printf '  Pasta:          %s\n' "$PROJECT_NAME"
    printf '  Maven groupId:  %s\n' "$NEW_ROOT_PACKAGE"
    printf '  Maven artifact: %s\n' "$PROJECT_NAME"
    printf '  Pacote Java:    %s\n' "$NEW_MAIN_PACKAGE"
    printf '  Pacote raiz:    %s\n' "$NEW_ROOT_PACKAGE"
    printf '\nO diretório .git atual será excluído ao final. Continuar? [s/N] '
    IFS= read -r confirmation

    case "$confirmation" in
        s|S|sim|SIM|Sim) ;;
        *) printf 'Configuração cancelada.\n'; exit 0 ;;
    esac
}

require_project_root

OLD_MAIN_PACKAGE="$(json_string_value mainPackage)"
OLD_PROJECT_NAME="$(json_string_value projectName)"
[[ -n "$OLD_MAIN_PACKAGE" ]] || fail "mainPackage não encontrado em .gonthera/project.json."
[[ -n "$OLD_PROJECT_NAME" ]] || fail "projectName não encontrado em .gonthera/project.json."

OLD_ROOT_PACKAGE="${OLD_MAIN_PACKAGE%.*}"
[[ "$OLD_ROOT_PACKAGE" != "$OLD_MAIN_PACKAGE" ]] || fail "o mainPackage atual não possui um pacote raiz."

PROJECT_NAME="$(prompt_until_valid 'Informe o nome do projeto.' 'customer-service' validate_project_name)"
NEW_MAIN_PACKAGE="$(prompt_until_valid 'Informe o pacote Java principal.' 'com.gonthera.customerservice' validate_java_package)"
NEW_ROOT_PACKAGE="${NEW_MAIN_PACKAGE%.*}"

TARGET_DIRECTORY="$(dirname -- "$SCRIPT_DIR")/$PROJECT_NAME"
if [[ "$TARGET_DIRECTORY" != "$SCRIPT_DIR" && -e "$TARGET_DIRECTORY" ]]; then
    fail "já existe um arquivo ou diretório em $TARGET_DIRECTORY."
fi

confirm_configuration

replace_literal_in_file "$PROJECT_FILE" "$OLD_PROJECT_NAME" "$PROJECT_NAME"
replace_literal_in_file "$PROJECT_FILE" "$OLD_MAIN_PACKAGE" "$NEW_MAIN_PACKAGE"
update_pom_coordinates "$NEW_ROOT_PACKAGE" "$PROJECT_NAME"
update_manual_java_sources "$OLD_MAIN_PACKAGE" "$NEW_MAIN_PACKAGE" "$OLD_ROOT_PACKAGE" "$NEW_ROOT_PACKAGE"

printf '\nValidando a configuração do Gonthera CLI...\n'
(cd "$SCRIPT_DIR" && ./mvnw -B -ntp gonthera-cli:validate) \
    || fail "a validação falhou. O Git foi preservado para permitir a revisão das alterações."

FINAL_DIRECTORY="$SCRIPT_DIR"
if [[ "$TARGET_DIRECTORY" != "$SCRIPT_DIR" ]]; then
    PARENT_DIRECTORY="$(dirname -- "$SCRIPT_DIR")"
    CURRENT_DIRECTORY_NAME="$(basename -- "$SCRIPT_DIR")"
    cd "$PARENT_DIRECTORY"
    mv -- "$CURRENT_DIRECTORY_NAME" "$PROJECT_NAME"
    FINAL_DIRECTORY="$TARGET_DIRECTORY"
fi

if [[ -e "$FINAL_DIRECTORY/.git" ]]; then
    rm -rf -- "$FINAL_DIRECTORY/.git"
fi

trap - EXIT
cleanup

printf '\nProjeto configurado com sucesso.\n'
printf 'Diretório: %s\n' "$FINAL_DIRECTORY"
printf 'O repositório Git do template foi removido. Use git init quando quiser iniciar o novo histórico.\n'
