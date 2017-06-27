[ "${TAC_INSTALLER_INSTALL_FLAG:-0}" -gt 0 ] && return 0

export TAC_INSTALLER_INSTALL_FLAG=1



tac_installer_script_path=$(readlink -e "${BASH_SOURCE[0]}")
tac_installer_script_dir="${tac_installer_script_path%/*}"

tac_installer_util_path=$(readlink -e "${tac_installer_script_dir}/util/util.sh")
source "${tac_installer_util_path}"

tac_installer_string_path=$(readlink -e "${tac_installer_script_dir}/util/string-util.sh")
source "${tac_installer_string_path}"

tac_installer_user_path=$(readlink -e "${tac_installer_script_dir}/util/user-util.sh")
source "${tac_installer_user_path}"

tac_installer_file_path=$(readlink -e "${tac_installer_script_dir}/util/file-util.sh")
source "${tac_installer_file_path}"

tac_installer_user_path=$(readlink -e "${tac_installer_script_dir}/util/user-util.sh")
source "${tac_installer_user_path}"

#tac_installer_parse_args_path=$(readlink -e "${tac_installer_script_dir}/util/parse-args.sh")
#source "${tac_installer_parse_args_path}"

#tac_installer_scope_context_path=$(readlink -e "${tac_installer_script_dir}/util/scope-context.sh")
#source "${tac_installer_scope_context_path}"

#tac_installer_init_path=$(readlink -e "${tac_installer_script_dir}/tac-installer-init.sh")
#source "${tac_installer_init_path}"

#tac_installer_download_path=$(readlink -e "${tac_installer_script_dir}/tac-installer-download.sh")
#source "${tac_installer_download_path}"

#tac_installer_env_path=$(readlink -e "${tac_installer_script_dir}/tac-installer-env.sh")
#source "${tac_installer_env_path}"

#tac_installer_mysql_path=$(readlink -e "${tac_installer_script_dir}/tac-installer-mysql.sh")
#source "${tac_installer_mysql_path}"



function tac_installer_unzip_tac() {
    debugStack

    sudo -u "${tac_installer_install_user}" -g "${tac_installer_install_group}" \
        unzip -q "${tac_installer_repo_dir}/${tac_installer_tac_zip_file}" -d "${tac_installer_tac_working_dir}"
}


function tac_installer_unzip_war() {
    debugStack

    local usage="usage: tac_installer_unzip_war <tac_war_dir_ref>"
    [ "${#}" -lt 1 ] && echo -e "${usage}\nERROR: missing tac_war_dir_ref argument" && return 1
    [ -z "${1}" ] && echo -e "${usage}\nERROR: tac_war_dir_ref empty" && return 1
    local -n _tac_war_dir="${1}"

    local unzip_dir="${tac_installer_tac_working_dir}/Talend-AdministrationCenter-${tac_installer_talend_distro_timestamp}_${tac_installer_talend_distro_build}-V${tac_installer_talend_version}"
    [ ! -d "${unzip_dir}" ] && echo -e "${usage}\nERROR: tac unzip directory does not exist: ${unzip_dir}" && return 1

    local tac_war_file="${unzip_dir}/org.talend.administrator-${tac_installer_talend_version}.war"
    [ ! -f "${tac_war_file}" ] && echo -e "${usage}\nERROR: tac_war_file does not exist: ${tac_war_file}" && return 1

    _tac_war_dir="${tac_installer_tac_working_dir}/tac"
    sudo -u "${tac_installer_tac_admin_user}" -g "${tac_installer_tomcat_group}" \
        unzip -q "${tac_war_file}" -d "${_tac_war_dir}"
}


function tac_installer_prepare_war() {
    debugStack

    local usage="usage: prepare_war <tac_war_dir>"
    [ "${#}" -lt 1  ] && echo -e "${usage}\nERROR: missing tac_war_dir argument" && return 1
    local tac_war_dir="${1}"
    [ ! -d "${tac_war_dir}" ] && echo -e "${usage}\nERROR: tac war directory parameter ${tac_war_dir} does not exist" && return 1

    local tac_config_properties="${tac_war_dir}/WEB-INF/classes/configuration.properties"

    sudo -s -u "${tac_installer_tac_admin_user}" -g "${tac_installer_tomcat_group}"<<-EOF
	cp -n "${tac_config_properties}" "${tac_config_properties}.orig"

	cat  "${tac_config_properties}.orig" \
	    | sed -e "s/^\(database\.url[ \t]*=.*$\)/\#\1/" \
	    | sed -e "s/^\(database\.driver[ \t]*=.*$\)/\#\1/" \
	    | sed -e "s/^\(database\.username[ \t]*=.*$\)/\#\1/" \
	    | sed -e "s/^\(database\.password[ \t]*=.*$\)/\#\1/" \
        > "${tac_config_properties}.new"

	cat "${tac_config_properties}.new" \
	    |  sed -e "s/^\(### Used values ###.*$\)/\1\n/" \
	    | sed -e "s/^\(### Used values ###.*$\)/\1\ndatabase\.password=${tac_installer_tac_db_password}/" \
	    | sed -e "s/^\(### Used values ###.*$\)/\1\ndatabase\.username=${tac_installer_tac_db_user}/" \
	    | sed -e "s/^\(### Used values ###.*$\)/\1\ndatabase\.driver=${tac_installer_tac_db_class}/" \
	    | sed -e "s/^\(### Used values ###.*$\)/\1\ndatabase.url=jdbc:mysql:\/\/${tac_installer_tac_db_host}:${tac_installer_tac_db_port}\/${tac_installer_tac_db}/" \
	    > "${tac_config_properties}.new2"

	cp "${tac_config_properties}.new2" "${tac_config_properties}"
	EOF
}


function tac_installer_install() {
    echo "**** tac_installer_install *****"
    debugStack

    local usage="usage: tac_install [ <tomcat_home_dir> [ <tac_home_dir> ] ]"

    local tac_home_dir="${1:-${tac_installer_tac_base}}"
    [ ! -d "${tac_home_dir}" ] && echo -e "${usage}\nERROR: tac_dir ${tac_home_dir} does not exist" && return 1

    local tomcat_home_dir="${2:-${tomcat_installer_tomcat_dir}}"
    [ ! -d "${tomcat_home_dir}" ] && echo -e "${usage}\nERROR: tomcat_home_dir ${tomcat_home_dir} does not exist" && return 1

    # unzip tac distro
    tac_installer_unzip_tac

    # unzip tac war file
    local tac_war_dir
    tac_installer_unzip_war tac_war_dir

    debugVar tac_war_dir

    # prepare tac webapp
    tac_installer_prepare_war "${tac_war_dir}"

    sudo -s -u "${tac_installer_tac_admin_user}" -g "${tac_installer_tomcat_group}" <<-EOF
	# copy the mysql client symbolic link to tac library
        cp "${tac_installer_mysql_client_path}" "${tac_war_dir}/WEB-INF/lib"
        # set permissions
	find "${tac_war_dir}" -type d -print0 | xargs -0 chmod 750
	find "${tac_war_dir}" -type f -print0 | xargs -0 chmod 640
	# move the prepared webapp to the tac webapps directory
	mv "${tac_war_dir}" "${tac_home_dir}/webapps"
	EOF
}
