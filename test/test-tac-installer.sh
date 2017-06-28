set -e

source ../util/util.sh

debugLog "SOURCED util.sh"

debugLog "SOURCING tac-installer-init.sh"

source ../tac-installer-init.sh

debugLog "SOURCING tac-installer-env.sh"

source ../tac-installer-env.sh

debugLog "SOURCING tac-installer-download.sh"

source ../tac-installer-download.sh

debugLog "SOURCING tac-installer-mysql.sh"

source ../tac-installer-mysql.sh

debugLog "SOURCING tac-installer-install.sh"

source ../tac-installer-install.sh

debugLog "SOURCING tac-installer.sh"

source ../tac-installer.sh

debugLog "SOURCING tomcat-installer.sh"

source ../../tomcat-installer/tomcat-installer.sh

debugLog "FINISHED SOURCING"



function test_tac_installer_download() {
    source /dev/stdin <<<"${tac_installer_init}"
    tac_installer_download
    echo "finished: test_tac_installer_download"
}

# test_tac_installer_download


function test_tac_installer_download_local() {
    source /dev/stdin <<<"${tac_installer_init}"
    tac_installer_download_local "/home/eost/shared"
    echo "finished: test_tac_installer_download_local"
}

# test_tac_installer_download_local


function test_tac_installer_unzip_tac() {
    source /dev/stdin <<<"${tac_installer_init}"
    local _tac_working_dir
    tac_installer_unzip_tac _tac_working_dir
    echo "tac_working_dir=${_tac_working_dir}"
    ls "${_tac_working_dir}"
    echo "finished: test_tac_installer_download_local"
}

#test_tac_installer_unzip_tac


function test_tac_installer_unzip_tac_work_dir_root() {
    source /dev/stdin <<<"${tac_installer_init}"
    local _tac_working_dir
    mkdir -p "/home/eost/test_tmp"
    tac_installer_unzip_tac _tac_working_dir "/home/eost/test_tmp"
    echo "tac_working_dir=${_tac_working_dir}"
    ls "${_tac_working_dir}"
    echo "finished: test_tac_installer_download_local"
}

#test_tac_installer_unzip_tac_work_dir_root


function test_tac_installer_unzip_war() {
    source /dev/stdin <<<"${tac_installer_init}"

    local _tac_working_dir
    tac_installer_unzip_tac _tac_working_dir
    echo "tac_working_dir=${_tac_working_dir}"

    local _tac_war_dir
    tac_installer_unzip_war "${_tac_working_dir}" _tac_war_dir
}

# test_tac_installer_unzip_war


function test_tac_installer_prepare_war() {
    source /dev/stdin <<<"${tac_installer_init}"

    local _tac_working_dir
    tac_installer_unzip_tac _tac_working_dir
    echo "tac_working_dir=${_tac_working_dir}"

    local _tac_war_dir
    tac_installer_unzip_war "${_tac_working_dir}" _tac_war_dir

    tac_installer_prepare_war "${_tac_war_dir}"
}

# test_tac_installer_prepare_war


function test_tac_installer_install() {
    debugStack

    source /dev/stdin <<<"${tomcat_installer_init}"
    source /dev/stdin <<<"${tac_installer_init}"
    source /dev/stdin <<<"${tac_installer_mysql_init}"

    debugVar "tomcat_installer_service_user"

    declare -A tac_installer_context
    read_dictionary "tac_installer_context.properties" "tac_installer_context"
    load_dictionary tac_installer_context tac_installer

    tomcat_installer create_instance "${tac_installer_tac_base}" \
                                     "${tac_installer_tac_admin_user}" \
                                     "${tac_installer_tomcat_group}" \
                                     "${tac_installer_tac_service_user}" \
                                     "${tac_installer_tomcat_group}"

    tac_installer install
}


function prepare() {
    source /dev/stdin <<<"${tomcat_installer_init}"
    source /dev/stdin <<<"${tac_installer_init}"
    source /dev/stdin <<<"${tac_installer_mysql_init}"

    tac_installer_clean
    tac_installer_setup
}

function install() {
    debugStack

    source /dev/stdin <<<"${tomcat_installer_init}"
    source /dev/stdin <<<"${tac_installer_init}"
    source /dev/stdin <<<"${tac_installer_mysql_init}"

    debugVar "tomcat_installer_service_user"

    declare -A tac_installer_context
    read_dictionary "tac_installer_context.properties" "tac_installer_context"
    load_dictionary tac_installer_context tac_installer

    tac_installer_download_local /home/eost/shared

    tomcat_installer create_instance "${tac_installer_tac_base}" \
                                     "${tac_installer_tac_admin_user}" \
                                     "${tac_installer_tomcat_group}" \
                                     "${tac_installer_tac_service_user}" \
                                     "${tac_installer_tomcat_group}"

    local tac_db_password
    tac_installer create_tac_db tac_db_password
    local password_file="mysql_$(date +%Y_%m_%d_%H_%M_%S).password"
    echo "${tac_db_password}" > "${tac_installer_repo_dir}/${password_file}"
    chmod 400 "${tac_installer_repo_dir}/${password_file}"

    tac_installer install
}



"${@}"
