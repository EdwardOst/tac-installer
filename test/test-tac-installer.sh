source ../tac-installer.sh

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

function test_tac_installer_mysql_random_password() {
    source /dev/stdin <<<"${tac_installer_init}"
    source /dev/stdin <<<"${tac_installer_mysql_init}"

    local my_password
    tac_installer_mysql_random_password my_password
    echo "my_password=${my_password}"
}

# test_tac_installer_mysql_random_password

function test_tac_installer_mysql_random_password_missing_arg() {
    source /dev/stdin <<<"${tac_installer_init}"
    source /dev/stdin <<<"${tac_installer_mysql_init}"

    local my_password
    tac_installer_mysql_random_password
    echo "my_password=${my_password}"
}

# test_tac_installer_mysql_random_password_missing_arg

function test_tac_installer_mysql_random_password_empty_arg() {
    source /dev/stdin <<<"${tac_installer_init}"
    source /dev/stdin <<<"${tac_installer_mysql_init}"

    local my_password
    tac_installer_mysql_random_password ""
    echo "my_password=${my_password}"
}

# test_tac_installer_mysql_random_password_empty_arg

function test_tac_installer_mysql_random_password_wrapper() {
    source /dev/stdin <<<"${tac_installer_init}"
    source /dev/stdin <<<"${tac_installer_mysql_init}"

    local -n my_password="${1}"
    tac_installer_mysql_random_password my_password
    echo "my_password=${my_password}"
}


function test_tac_installer_mysql_random_password_deref() {

    local wrapper_password
    test_tac_installer_mysql_random_password_wrapper wrapper_password
    echo "wrapper_password=${wrapper_password}"
}

#test_tac_installer_mysql_random_password_deref


function test_tac_installer_mysql_create_tac_db() {
    source /dev/stdin <<<"${tac_installer_init}"
    source /dev/stdin <<<"${tac_installer_mysql_init}"

    local my_password
    tac_installer_mysql_create_tac_db my_password
    echo "my_password=${my_password}"
}

test_tac_installer_mysql_create_tac_db
