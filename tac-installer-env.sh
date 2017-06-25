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



# requires-sudo
function tac_installer_create_users() {
    debugStack

    group_exists "${tac_installer_tomcat_group}"  || sudo groupadd "${tac_installer_tomcat_group}"
    group_exists "${tac_installer_install_group}"  || sudo groupadd "${tac_installer_install_group}"
    group_exists "${tac_installer_tac_admin_user}"  || sudo groupadd "${tac_installer_tac_admin_user}"
    group_exists "${tac_installer_tac_service_user}"  || sudo groupadd "${tac_installer_tac_service_user}"

    user_exists "${tac_installer_install_user}" || sudo useradd -s /usr/sbin/nologin -g "${tac_installer_install_group}" "${tac_installer_install_user}"
    user_exists "${tac_installer_tac_admin_user}" || sudo useradd -s /usr/sbin/nologin -g "${tac_installer_tac_admin_user}" "${tac_installer_tac_admin_user}"
    user_exists "${tac_installer_tac_service_user}" || sudo useradd -s /usr/sbin/nologin -g "${tac_installer_tac_service_user}" "${tac_installer_tac_service_user}"

    # all users belong to tomcat group
    sudo usermod -a -G "${tac_installer_tomcat_group}" "${tac_installer_install_user}"
    sudo usermod -a -G "${tac_installer_tomcat_group}" "${tac_installer_tac_admin_user}"
    sudo usermod -a -G "${tac_installer_tomcat_group}" "${tac_installer_tac_service_user}"

    # all users belong to install group
    sudo usermod -a -G "${tac_installer_install_group}" "${tac_installer_tac_admin_user}"
    sudo usermod -a -G "${tac_installer_install_group}" "${tac_installer_tac_service_user}"

    # install user belongs to all admin groups
    sudo usermod -a -G "${tomcat_installer_tac_admin_user}" "${tac_installer_install_user}"
    sudo usermod -a -G "${tomcat_installer_tac_service_user}" "${tac_installer_install_user}"

    sudo tee -a /etc/sudoers.d/tomcat > /dev/null <<-EOF
	# members of tac_admin group can sudo to tac_admin user
	%${tac_installer_tac_admin_user}	ALL=(${tac_installer_tac_admin_user}) ALL

	# tac installer can sudo to tac_admin or tac_service without a password
	${tac_installer_install_user}	ALL=(${tac_installer_tac_admin_user},${tac_installer_tac_service_user}) NOPASSWD: ALL
	EOF
}


# requires-sudo
function tac_installer_create_folders() {
    debugStack

    create_user_directory "${tac_installer_tac_base}" "${tac_installer_tac_admin_user}" "${tac_installer_tomcat_group}"
    create_user_directory "${tac_installer_tac_base}/tac-archive" "${tac_installer_tac_service_user}" "${tac_installer_tomcat_group}"
    create_user_directory "${tac_installer_tac_base}/jobs" "${tac_installer_tac_service_user}" "${tac_installer_tomcat_group}"
    create_user_directory "${tac_installer_tac_base}/executionLogs" "${tac_installer_tac_service_user}" "${tac_installer_tomcat_group}"
    create_user_directory "${tac_installer_tac_base}/cmdline" "${tac_installer_tac_service_user}" "${tac_installer_tomcat_group}"
    create_user_directory "${tac_installer_tac_base}/components" "${tac_installer_tac_service_user}" "${tac_installer_tomcat_group}"
    create_user_directory "${tac_installer_tac_working_dir}" "${tac_installer_install_user}" "${tac_installer_install_group}" 770
}


# requires-sudo
function tac_installer_create_env() {
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

function tac_installer_tac_update_hosts() {
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
function tac_installer_install_service() {
    sudo cp talend-tac /etc/init.d
    sudo chmod +x /etc/init.d/talend-tac
    sudo update-rc.d talend-tac defaults
    sudo service talend-tac start
}
