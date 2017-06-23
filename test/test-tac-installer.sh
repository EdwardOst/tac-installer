set -e

echo "STARTING"


echo "SOURCING"

echo "SOURCING tac-installer.sh"

source ../tac-installer.sh

echo "SOURCING tomcat-installer.sh"

source ../../tomcat-installer/tomcat-installer.sh

echo "SOURCED"

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
    source /dev/stdin <<<"${tomcat_installer_init}"
    source /dev/stdin <<<"${tac_installer_init}"
    source /dev/stdin <<<"${tac_installer_mysql_init}"

    set -x
#    tac_installer_create_users
    tac_installer_create_folders
#    tomcat_installer create_instance "${tac_installer_tac_base}"

#    tac_installer_install
}

echo "test_tac_installer_install"
set -x
test_tac_installer_install
