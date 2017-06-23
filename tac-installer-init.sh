[ "${TAC_INSTALLER_INIT_FLAG:-0}" -gt 0 ] && return 0

export TAC_INSTALLER_INIT_FLAG=1

tac_installer_init_script_path=$(readlink -e "${BASH_SOURCE[0]}")
tac_installer_init_script_dir="${tac_installer_init_script_path%/*}"

tac_installer_init_util_path=$(readlink -e "${tac_installer_init_script_dir}/util/util.sh")
source "${tac_installer_init_util_path}"


define tac_installer_init <<'EOF'
    local tac_installer_talend_version="${TAC_INSTALLER_TALEND_VERSION:-${tac_installer_talend_version:-6.3.1}}"
    local tac_installer_talend_version_suffix="${tac_installer_talend_version//.}"
    local tac_installer_talend_distro_root="${TAC_INSTALLER_TALEND_DISTRO_ROOT:-${tac_installer_talend_distro_root:-tpdsbdrt}}"
    local tac_installer_talend_distro_timestamp="${TAC_INSTALLER_TALEND_DISTRO_TIMESTAMP:-${tac_installer_talend_distro_timestamp:-20161216}}"
    local tac_installer_talend_distro_build="${TAC_INSTALLER_TALEND_DISTRO_BUILD:-${tac_installer_talend_distro_build:-1026}}"
    local tac_installer_talend_download_host="${TAC_INSTALLER_TALEND_DOWNLOAD_HOST:-${tac_installer_talend_download_host:-www.opensourceetl.net}}"
    local tac_installer_tac_zip_file="Talend-AdministrationCenter-${tac_installer_talend_distro_timestamp}_${tac_installer_talend_distro_build}-V${tac_installer_talend_version}.zip"
    local tac_installer_tac_war_file="org.talend.administrator-${TALEND_VERSION}.war"

    local tac_installer_talend_download_userid="${TALEND_INSTALLER_TALEND_DOWNLOAD_USERID:-${tac_installer_talend_download_userid:-eost}}"
    local tac_installer_talend_download_password="${TALEND_INSTALLER_TALEND_DOWNLOAD_PASSWORD:-${talend_installer_talend_download_password:-Ahha9oax7n-}}"

    local tac_installer_repo_dir="${TAC_INSTALLER_REPO_DIR:-${tac_installer_repo_dir:-/opt/repo/talend/tac}}"
    local tac_installer_tac_base="${TAC_INSTALLER_TAC_BASE:-${tac_installer_tac_base:-/opt/Talend/${tac_installer_talend_version}/tac}}"
    local tac_installer_install_user="${TAC_INSTALLER_INSTALL_USER:-${tac_installer_install_user:-talend}}"
    local tac_installer_tac_admin_user="${TAC_INSTALLER_TAC_ADMIN_USER:-${tac_installer_tac_admin_user:-tac_admin}}"
    local tac_installer_tac_service_user="${TAC_INSTALLER_TAC_SERVICE_USER:-${tac_installer_tac_service_user:-tac}}"
    local tac_installer_tomcat_group="${TAC_INSTALLER_TOMCAT_GROUP:-${tac_installer_tomcat_group:-tomcat}}"

    local tac_installer_tac_db="${TAC_INSTALLER_TAC_DB:-${tac_installer_tac_db:-tac_test}}"
    local tac_installer_tac_db_host="${TAC_INSTALLER_TAC_DB_HOST:-${tac_installer_tac_db_host:-192.168.99.1}}"
    local tac_installer_tac_db_port="${TAC_INSTALLER_TAC_DB_PORT:-${tac_installer_tac_db_port:-3306}}"
    local tac_installer_tac_db_user="${TAC_INSTALLER_TAC_DB_USER:-${tac_installer_tac_db_user:-tadmin_test}}"
    local tac_installer_tac_db_password="${TAC_INSTALLER_TAC_DB_PASSWORD:-${tac_installer_tac_db_password:-tadmin_test}}"
    local tac_installer_tac_db_class="${TAC_INSTALLER_TAC_DB_CLASS:-${tac_installer_tac_db_class:-com.mysql.jdbc.Driver}}"
EOF


declare -A tomcat_installer_context=(
    ["tac_installer_talend_version"]="${TAC_INSTALLER_TALEND_VERSION:-${tac_installer_talend_version:-6.3.1}}"
    ["tac_installer_talend_version_suffix"]="${tac_installer_talend_version//.}"
    ["tac_installer_talend_distro_root"]="${TAC_INSTALLER_TALEND_DISTRO_ROOT:-${tac_installer_talend_distro_root:-tpdsbdrt}}"
    ["tac_installer_talend_distro_timestamp"]="${TAC_INSTALLER_TALEND_DISTRO_TIMESTAMP:-${tac_installer_talend_distro_timestamp:-20161216}}"
    ["tac_installer_talend_distro_build"]="${TAC_INSTALLER_TALEND_DISTRO_BUILD:-${tac_installer_talend_distro_build:-1026}}"
    ["tac_installer_talend_download_host"]="${TAC_INSTALLER_TALEND_DOWNLOAD_HOST:-${tac_installer_talend_download_host:-www.opensourceetl.net}}"
    ["tac_installer_tac_zip_file"]="Talend-AdministrationCenter-${tac_installer_talend_distro_timestamp}_${tac_installer_talend_distro_build}-V${tac_installer_talend_version}.zip"

    ["tac_installer_talend_download_userid"]="${TALEND_INSTALLER_TALEND_DOWNLOAD_USERID:-${tac_installer_talend_download_userid:-eost}}"
    ["tac_installer_talend_download_password"]="${TALEND_INSTALLER_TALEND_DOWNLOAD_PASSWORD:-${talend_installer_talend_download_password:-Ahha9oax7n-}}"

    ["tac_installer_repo_dir"]="${TAC_INSTALLER_REPO_DIR:-${tac_installer_repo_dir:-/opt/repo/talend/tac}}"
    ["tac_installer_tac_base"]="${TAC_INSTALLER_TAC_BASE:-${tac_installer_tac_base:-/opt/Talend/${tac_installer_talend_version}/tac}}"
    ["tac_installer_tac_admin_user"]="${TAC_INSTALLER_TAC_ADMIN_USER:-${tac_installer_tac_admin_user:-tac_admin}}"
    ["tac_installer_tomcat_group"]="${TAC_INSTALLER_TOMCAT_GROUP:-${tac_installer_tomcat_group:-tomcat}}"
    )

