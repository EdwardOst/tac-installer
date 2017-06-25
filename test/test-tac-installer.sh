set -e

source ../util/util.sh

debugLog "SOURCING tac-installer.sh"

source ../tac-installer.sh

debugLog "SOURCING tomcat-installer.sh"

source ../../tomcat-installer/tomcat-installer.sh


function clean() {
    debugStack

    sudo rm -rf /opt/Talend

#    user_exists "${tac_installer_install_user}" && sudo userdel "${tac_installer_install_user}"
    user_exists "${tac_installer_tac_admin_user}" && sudo userdel "${tac_installer_tac_admin_user}"
    user_exists "${tac_installer_tac_service_user}" && sudo userdel "${tac_installer_tac_service_user}"

#    group_exists "${tac_installer_install_group}" && sudo groupdel "${tac_installer_install_group}"
    group_exists "${tac_installer_tac_admin_user}" && sudo groupdel "${tac_installer_tac_admin_user}"
    group_exists "${tac_installer_tac_service_user}" && sudo groupdel "${tac_installer_tac_service_user}"

    return 0
}


function setup() {
    debugStack

    source /dev/stdin <<<"${tomcat_installer_init}"
    source /dev/stdin <<<"${tac_installer_init}"
    source /dev/stdin <<<"${tac_installer_mysql_init}"

    clean
    tac_installer_create_users
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

    echo "tomcat_installer_service_user=${tomcat_installer_tomcat_service_user}"
    tomcat_installer create_instance "${tac_installer_tac_base}" \
                                     "${tac_installer_tac_admin_user}" \
                                     "${tac_installer_tomcat_group}" \
                                     "${tac_installer_tac_service_user}" \
                                     "${tac_installer_tomcat_group}"
    tac_installer_create_folders

    tac_installer_install
}

echo "starting"
DEBUG_LOG=true
setup
test_tac_installer_install
