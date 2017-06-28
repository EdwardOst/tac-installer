source ../tac-installer.sh

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

#test_tac_installer_mysql_create_tac_db

"${@}"
