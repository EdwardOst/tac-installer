[ "${TAC_INSTALLER_FLAG:-0}" -gt 0 ] && return 0

export TAC_INSTALLER_FLAG=1

set -e
#set -x



tac_installer_script_path=$(readlink -e "${BASH_SOURCE[0]}")
tac_installer_script_dir="${tac_installer_script_path%/*}"

tac_installer_util_path=$(readlink -e "${tac_installer_script_dir}/util/util.sh")
source "${tac_installer_util_path}"

tac_installer_file_path=$(readlink -e "${tac_installer_script_dir}/util/file-util.sh")
source "${tac_installer_file_path}"

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



function tac_installer_create_folders() {
    sudo -s -u "${tac_installer_tac_admin_user}" -g "${tac_installer_tomcat_group}" <<-EOF
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
        | sed -e "s/^\(### Used values ###.*$\)/\1\ndatabase\.password=${tacDbPassword}/" \
        | sed -e "s/^\(### Used values ###.*$\)/\1\ndatabase\.username=${tacDbUsername}/" \
        | sed -e "s/^\(### Used values ###.*$\)/\1\ndatabase\.driver=org\.gjt\.mm\.mysql\.Driver/" \
        | sed -e "s/^\(### Used values ###.*$\)/\1\ndatabase.url=jdbc:mysql:\/\/${tacDbHost}:${tacDbPort}\/${tacDatabase}/" \
        > "${tac_config_properties}.new2"

    cp "${tac_config_properties}.new2"  "${tac_config_properties}"
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



#
# tac_install
#
# assumes tomcat has been installed
# Creates a Tomcat instance, unzips Talend install, modmifies the war, adds war to new Tomcat instance.
#
# usage:
#       tac_install [ tomcatHome [ tacHome ] ]
#
function tac_install() {
    [ "${#}" -lt 2 ] && echo "ERROR: usage: tac_install <tomcat_home_dir> <tac_home_dir>" && return 1

    local tomcat_home_dir="${1:-/opt/apache-tomcat-${tomcatVersion}}"
    local tac_home_dir="${2:-/opt/Talend/${tac_installer_talend_version}/tac}"
    local _tacTomcatDir="${tac_home_dir}/apache-tomcat"

    # unzip tac distro
    local tac_working_dir
    tac_installer_unzip_tac tac_working_dir

    # unzip tac war file
    local tac_war_dir
    tac_installer_unzip_war "${tac_working_dir}" tac_war_dir

    # prepare tac webapp
    tac_prepare_war "${tac_war_dir}"

    # copy the mysql client symbolic link to tac library
    cp "${mysql_client_path}" "${tac_war_dir}/WEB-INF/lib"

    mv "${tac_war_dir}" "${tac_home_dir}/webapps"

    debugLog "create tac initialization script in /etc/profile.d"
    sudo tee "/etc/profile.d/tac-${tac_installer_talend_version}.sh" <<-EOF
	export CATALINA_HOME=${tomcat_home_dir}
	export CATALINA_BASE=${_tacTomcatDir}
	EOF
}
