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



declare config_properties="test_context.properties"

function clean_folders() {
    debugStack

    sudo rm -rf "${tac_installer_tac_base}"

    return 0
}


function clean_users() {
    debugStack

    user_exists "${tac_installer_tac_admin_user}" && sudo userdel "${tac_installer_tac_admin_user}"
    user_exists "${tac_installer_tac_service_user}" && sudo userdel "${tac_installer_tac_service_user}"

    group_exists "${tac_installer_tac_admin_user}" && sudo groupdel "${tac_installer_tac_admin_user}"
    group_exists "${tac_installer_tac_service_user}" && sudo groupdel "${tac_installer_tac_service_user}"

    user_exists "${tac_installer_install_user}" && sudo userdel "${tac_installer_install_user}"
    group_exists "${tac_installer_install_group}" && sudo groupdel "${tac_installer_install_group}"

    group_exists "${tac_installer_tomcat_group}"  || sudo groupdel "${tac_installer_tomcat_group}"

    return 0
}


function clean() {
    debugStack

    source /dev/stdin <<<"${tomcat_installer_init}"
    source /dev/stdin <<<"${tac_installer_init}"
    source /dev/stdin <<<"${tac_installer_mysql_init}"

    clean_folders
    clean_users
}


function setup_users() {
    local -A test_context

    debugStack

    source /dev/stdin <<<"${tomcat_installer_init}"
    source /dev/stdin <<<"${tac_installer_init}"
    source /dev/stdin <<<"${tac_installer_mysql_init}"

    tac_installer_create_users
    tac_installer_create_folders

    export_dictionary test_context tac_installer
    unset test_context[init]
    unset test_context[mysql_init]
    write_dictionary test_context "${config_properties}"
}


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
    read_dictionary "${config_properties}" "tac_installer_context"
    load_dictionary tac_installer_context tac_installer

    tomcat_installer create_instance "${tac_installer_tac_base}" \
                                     "${tac_installer_tac_admin_user}" \
                                     "${tac_installer_tomcat_group}" \
                                     "${tac_installer_tac_service_user}" \
                                     "${tac_installer_tomcat_group}"

    tac_installer install
}

"${@}"
