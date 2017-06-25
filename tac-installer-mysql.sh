[ "${TAC_INSTALLER_MYSQL_INIT_FLAG:-0}" -gt 0 ] && return 0

export TAC_INSTALLER_MySQL_INIT_FLAG=1

tac_installer_mysql_init_script_path=$(readlink -e "${BASH_SOURCE[0]}")
tac_installer_mysql_init_script_dir="${tac_installer_mysql_init_script_path%/*}"

tac_installer_mysql_init_util_path=$(readlink -e "${tac_installer_mysql_init_script_dir}/util/util.sh")
source "${tac_installer_mysql_init_util_path}"


define tac_installer_mysql_init <<'EOF'
    local tac_installer_mysql_client_version="${TAC_INSTALLER_MYSQL_CLIENT_VERSION:-${tac_installer_mysql_client_version:-5.7}}"
    local tac_installer_mysql_client_path="${TAC_INSTALLER_MYSQL_CLIENT_PATH:-${tac_installer_mysql_client_path:-/usr/share/java/mysql-connector-java.jar}}"
    local tac_installer_mysql_admin_user="${TAC_INSTALLER_MYSQL_ADMIN_USER:-${tac_installer_mysql_admin_user:-tadmin}}"
    local tac_installer_mysql_admin_password="${TAC_INSTALLER_MYSQL_ADMIN_PASSWORD:-${tac_installer_mysql_admin_password:-tadmin}}"
    local tac_installer_mysql_host="${TAC_INSTALLER_MYSQL_HOST:-${tac_installer_mysql_host:-192.168.99.1}}"
    local tac_installer_mysql_db="${TAC_INSTALLER_MYSQL_DB:-${tac_installer_mysql_db:-mysql}}"
EOF


function tac_installer_mysql_mysql_client_apt() {
    sudo apt-get install mysql-client
    sudo apt-get install libmysql-java
}


function tac_installer_mysql_random_password() {
    [ "${#}" -lt 1 ] && echo "ERROR: usage: mysql_random_password <password_ref>" && return 1
    [ -z "${1}" ] && echo "ERROR: password_ref empty" && return 1

    local -n password="${1}"
    read -d ' ' password < <(date | md5sum)
}


function tac_installer_mysql_create_tac_db() {
    [ "${#}" -lt 1 ] && echo "ERROR: usage: mysql_create_tac_db <password_ref> [ <tac_installer_tac_db> [ <tac_installer_tac_db_user> ] ]" && return 1
    [ -z "${1}" ] && echo "ERROR: password_ref empty" && return 1

    local -n _generated_password="${1}"

    local tac_installer_tac_db="${2:-${tac_installer_tac_db}}"
    [ -z "${tac_installer_tac_db}" ] && echo "ERROR: no default tac_installer_tac_db" && return 1

    local tac_installer_tac_db_user="${3:-${tac_installer_tac_db_user}}"
    [ -z "${tac_installer_tac_db_user}" ] && echo "ERROR: no default tac_installer_tac_db_user" && return 1

    tac_installer_mysql_random_password _generated_password

    mysql --host="${tac_installer_mysql_host}" \
          --user="${tac_installer_mysql_admin_user}" \
          --password="${tac_installer_mysql_admin_password}" \
          --database="${tac_installer_mysql_db}" \
          <<-EOF
	CREATE DATABASE ${tac_installer_tac_db};
	CREATE USER '${tac_installer_tac_db_user}'@'%' IDENTIFIED BY '${_generated_password}';
	GRANT ALL PRIVILEGES ON ${tac_installer_tac_db}.* TO '${tac_installer_tac_db_user}'@'%';
	EOF
}
