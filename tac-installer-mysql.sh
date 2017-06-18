function tac_create_db() {
    if [ "${1}" = "-h" -o "${1}" = "--help" ] ; then
        cat <<-HELPDOC

	tac_create_db

	  DESCRIPTION

	      create empty tac database

	  CONSTRAINTS
	      Assumes database config variables.
	      Assumes mysql client installed.
	      Assumes mysql on target server.

	  USAGE:
	      tac_create_db [ dbname [ tadmin_user [ tadmin_password ] ] ]

	      parameter: dbname: defaults to tac

	  TODO:
	      store generated hashed password and perhaps the password for the tadmin account in the talend properties file.

	HELPDOC
	return 0
    fi

    local tac_installer_tac_database="${1:-${tacDatabase:-'tac'}}"; 
    local tac_installer_tac_database_userid="${2:-${tacDbUsername:-'tadmin'}}"; debugVar tac_installer_tac_database_userid
    mysql_create_db "${tac_installer_tac_database}"

        mysql_random_password
        echo "_mysql_random_password_result=${_mysql_random_password_result}"
        local _tacDbPassword=${_mysql_random_password_result}
        echo "tacDbPassword=${_tacDbPassword}" >> ${TALEND_HOME}/talend-${TALEND_VERSION}.properties
        mysql_hashed_password ${_mysql_random_password_result}
        mysql_create_user "${tac_installer_tac_database}" tadmin "${_mysql_hashed_password_result}"
}

