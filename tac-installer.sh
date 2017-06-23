[ "${TAC_INSTALLER_FLAG:-0}" -gt 0 ] && return 0

export TAC_INSTALLER_FLAG=1

set -e
#set -x



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

tac_installer_parse_args_path=$(readlink -e "${tac_installer_script_dir}/util/parse-args.sh")
source "${tac_installer_parse_args_path}"

tac_installer_scope_context_path=$(readlink -e "${tac_installer_script_dir}/util/scope-context.sh")
source "${tac_installer_scope_context_path}"

tac_installer_init_path=$(readlink -e "${tac_installer_script_dir}/tac-installer-init.sh")
source "${tac_installer_init_path}"

tac_installer_download_path=$(readlink -e "${tac_installer_script_dir}/tac-installer-download.sh")
source "${tac_installer_download_path}"

tac_installer_mysql_path=$(readlink -e "${tac_installer_script_dir}/tac-installer-mysql.sh")
source "${tac_installer_mysql_path}"



function tac_installer_create_users() {

    set -x

    group_exists "${tac_installer_tomcat_group}"  || sudo groupadd "${tac_installer_tomcat_group}"
    group_exists "${tac_installer_install_user}"  || sudo groupadd "${tac_installer_install_user}"
    group_exists "${tac_installer_tac_admin_user}"  || sudo groupadd "${tac_installer_tac_admin_user}"
    group_exists "${tac_installer_tac_service_user}"  || sudo groupadd "${tac_installer_tac_service_user}"

    user_exists "${tac_installer_install_user}" || sudo useradd -s /usr/sbin/nologin -g "${tac_installer_install_user}" "${tac_installer_install_user}"
    user_exists "${tac_installer_tac_admin_user}" || sudo useradd -s /usr/sbin/nologin -g "${tac_installer_tac_admin_user}" "${tac_installer_tac_admin_user}"
    user_exists "${tac_installer_tac_service_user}" || sudo useradd -s /usr/sbin/nologin -g "${tac_installer_tac_service_user}" "${tac_installer_tac_service_user}"

    # all users belong to tomcat group
    sudo usermod -a -G "${tac_installer_tomcat_group}" "${tomcat_installer_install_user}"
    sudo usermod -a -G "${tac_installer_tomcat_group}" "${tomcat_installer_tac_admin_user}"
    sudo usermod -a -G "${tac_installer_tomcat_group}" "${tomcat_installer_tac_service_user}"

    # install user belongs to all admin groups
    sudo usermod -a -G "${tomcat_installer_tac_admin_user}" "${tomcat_installer_install_user}"
    sudo usermod -a -G "${tomcat_installer_tac_service_user}" "${tomcat_installer_install_user}"

    sudo tee -a /etc/sudoers.d/tomcat <<-EOF
	# members of tac_admin group can sudo to tac_admin user
	%${tac_installer_tac_admin_user}	ALL=(${tac_installer_tac_admin_user}) ALL

	# members of tac installer group can sudo to tac_admin or tac_service without a password
	%${tac_installer_install_user}	ALL=(${tac_installer_tac_admin_user},${tac_installer_tac_service_user}) NOPASSWD: ALL
	EOF
}


function tac_installer_create_folders() {
    sudo -s -u "${tac_installer_tac_service_user}" -g "${tac_installer_tomcat_group}" <<-EOF
	mkdir -p "${tac_installer_tac_base}/tac-archive"
	mkdir -p "${tac_installer_tac_base}/jobs"
	mkdir -p "${tac_installer_tac_base}/executionLogs"
	mkdir -p "${tac_installer_tac_base}/cmdline"
	mkdir -p "${tac_installer_tac_base}/components"
	EOF
}


function tac_installer_unzip_tac() {
    [ "${#}" -lt 1 ] && echo "ERROR: usage: unzip_tac <tac_working_dir_ref> [ <work_dir_root> ]" && return 1
    local -n tac_working_dir="${1}"

    local work_dir_root="${2:-${PWD}}"
    [ ! -d "${work_dir_root}" ] && echo "ERROR: tac working directory root does not exist: ${work_dir_root}" && return 1

    tac_working_dir=$(mktemp -d --tmpdir="${work_dir_root}")

    sudo -u "${tac_installer_tac_admin_user}" -g "${tac_installer_tomcat_group}" \
        unzip -q "${tac_installer_repo_dir}/${tac_installer_tac_zip_file}" -d "${tac_working_dir}"
}


function tac_installer_unzip_war() {
    [ "${#}" -lt 2 ] && echo "ERROR: usage: unzip_war <tac_working_dir> <tac_war_dir_ref>" && return 1
    local tac_working_dir="${1}"
    [ ! -d "${tac_working_dir}" ] && echo "ERROR: tac working directory parameter does not exist: ${tac_working_dir}" && return 1

    [ -z "${2}" ] && echo "ERROR: tac_war_dir_ref empty" && return 1
    local -n tac_war_dir="${2}"

    local unzip_dir="${tac_working_dir}/Talend-AdministrationCenter-${tac_installer_talend_distro_timestamp}_${tac_installer_talend_distro_build}-V${tac_installer_talend_version}"
    [ ! -d "${unzip_dir}" ] && echo "ERROR: tac unzip directory does not exist: ${unzip_dir}" && return 1

    local tac_war_file="${unzip_dir}/org.talend.administrator-${tac_installer_talend_version}.war"
    [ ! -f "${tac_war_file}" ] && echo "ERROR: tac_war_file does not exist: ${tac_war_file}" && return 1

    tac_war_dir="${unzip_dir}/tac"

    sudo -u "${tac_installer_tac_admin_user}" -g "${tac_installer_tomcat_group}" \
        unzip -q "${tac_war_file}" -d "${tac_war_dir}"
}


function tac_installer_prepare_war() {
    [ "${#}" -lt 1  ] && echo "ERROR: usage: prepare_war <tac_war_dir>" && return 1
    local tac_war_dir="${1}"
    [ ! -d "${tac_war_dir}" ] && echo "ERROR: tac war directory parameter does not exist: ${tac_war_dir}" && return 1

    local tac_config_properties="${tac_war_dir}/WEB-INF/classes/configuration.properties"
    cp -n "${tac_config_properties}" "${tac_config_properties}.orig"

    debugLog "comment out old database connection"
    cat  "${tac_config_properties}.orig" \
        | sed -e "s/^\(database\.url[ \t]*=.*$\)/\#\1/" \
        | sed -e "s/^\(database\.driver[ \t]*=.*$\)/\#\1/" \
        | sed -e "s/^\(database\.username[ \t]*=.*$\)/\#\1/" \
        | sed -e "s/^\(database\.password[ \t]*=.*$\)/\#\1/" \
        > "${tac_config_properties}.new"

    debugLog "insert new database connection properties immediately after Used Values flag"
    cat "${tac_config_properties}.new" \
        | sed -e "s/^\(### Used values ###.*$\)/\1\n/" \
        | sed -e "s/^\(### Used values ###.*$\)/\1\ndatabase\.password=${tac_installer_tac_db_password}/" \
        | sed -e "s/^\(### Used values ###.*$\)/\1\ndatabase\.username=${tac_installer_tac_db_user}/" \
        | sed -e "s/^\(### Used values ###.*$\)/\1\ndatabase\.driver=${tac_installer_tac_db_class}/" \
        | sed -e "s/^\(### Used values ###.*$\)/\1\ndatabase.url=jdbc:mysql:\/\/${tac_installer_tac_db_host}:${tac_installer_tac_db_port}\/${tac_installer_tac_db}/" \
        > "${tac_config_properties}.new2"

    cp "${tac_config_properties}.new2"  "${tac_config_properties}"
}


#
# tac_install
#
# assumes tomcat has been installed
# Creates a Tomcat instance, unzips Talend install, modmifies the war, adds war to new Tomcat instance.
#
# usage:
#       tac_install [ tomcatHome [ tacHome ] ]
#
function tac_installer_install() {
    local tac_home_dir="${1:-${tac_installer_tac_base}}"
    sudo [ ! -d "${tac_home_dir}" ] && echo -e "ERROR: tac_dir ${tac_home_dir} does not exist.\nusage: tac_install [ <tac_home_dir> [ <tomcat_home_dir> ] ]" && return 1

    local tomcat_home_dir="${2:-${tomcat_installer_tomcat_dir}}"
    sudo [ ! -d "${tomcat_home_dir}" ] && echo -e "ERROR: tomcat_home_dir ${tomcat_home_dir} does not exist.\nusage: tac_install [ <tomcat_home_dir> [ <tac_home_dir> ] ]" && return 1

    # unzip tac distro
    local _tac_working_dir
    tac_installer_unzip_tac _tac_working_dir

    # unzip tac war file
    local _tac_war_dir
    tac_installer_unzip_war "${_tac_working_dir}" _tac_war_dir

    # prepare tac webapp
    tac_installer_prepare_war "${_tac_war_dir}"

#    sudo chown -R "${tac_installer_tac_admin_user}:${tac_installer_tomcat_group}" "${_tac_war_dir}"

    sudo -s -u "${tac_installer_tac_admin_user}" -g "${tac_installer_tomcat_group}" <<-EOF
	# copy the mysql client symbolic link to tac library
        cp "${tac_installer_mysql_client_path}" "${_tac_war_dir}/WEB-INF/lib"
	chmod 750 $(find "${_tac_war_dir}" -type d)
	chmod 640 $(find "${_tac_war_dir}" -type f)
	# move the prepared webapp to the tac webapps directory
	mv "${_tac_war_dir}" "${tac_home_dir}/webapps"
	EOF

    debugLog "create tac initialization script in /etc/profile.d"
    sudo tee "/etc/profile.d/tac-${tac_installer_talend_version}.sh" <<-EOF
	export CATALINA_HOME=${tomcat_home_dir}
	export CATALINA_BASE=${tac_home_dir}
	EOF
}


#
# tac_update_hosts
#
# update hosts file with tac db host name and ip address from talend environment.
#

function tac_update_hosts() {
        sudo cp -n /etc/hosts /etc/hosts.orig
        sudo tee -a /etc/hosts <<-HOSTS
	${tacDbIP}     ${tacDbHost}
	HOSTS
}


#
# tac_install_service
#
# copy the talend-tac script to the /etc/init.d directory and add it as an OS service
# update the hosts file with the names of the tac db host.
# TODO: support OS other than ubuntu
#
function tac_install_service() {
    sudo cp talend-tac /etc/init.d
    sudo chmod +x /etc/init.d/talend-tac
    sudo update-rc.d talend-tac defaults
    sudo service talend-tac start
}
