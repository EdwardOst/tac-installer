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

tac_installer_env_path=$(readlink -e "${tac_installer_script_dir}/tac-installer-env.sh")
source "${tac_installer_env_path}"

tac_installer_mysql_path=$(readlink -e "${tac_installer_script_dir}/tac-installer-mysql.sh")
source "${tac_installer_mysql_path}"

tac_installer_install_path=$(readlink -e "${tac_installer_script_dir}/tac-installer-install.sh")
source "${tac_installer_install_path}"



function tac_installer_help() {
    cat <<-EOF
	tac_installer

	constraints:
	    some commands must be run with sudo privileges to create folders, users, and groups

	usage:
	    tac_installer [options] <command> [command-options] <command-args>

	options:
	    -h help
	    -c specify an alternative configuration as an associative array

	subcommands:
	    create_users
	    create_folders
	    create_env
	    install
	    uninstall
	    install_service
	    uninstall_service

	EOF
}


function tac_installer() {

    declare -A tac_installer_options=(
                  ["--config"]="tac_installer_config"
                  ["--version"]="tac_installer_tac_version"

                  ["--download_url"]="tac_installer_talend_distro_url"
                  ["--download_userid"]="tac_installer_talend_download_userid"
                  ["--download_password"]="tac_installer_talend_download_password"

                  ["--repo_dir"]="tac_installer_repo_dir"
                  ["--tac_base"]="tac_installer_tac_base"
                  ["--install_user"]="tac_installer_install_user"
                  ["--install_group"]="tac_installer_install_group"
                  ["--admin_user"]="tac_installer_tac_admin_user"
                  ["--service_user"]="tac_installer_tac_service_user"
                  ["--group"]="tac_installer_tomcat_group"

                  ["--db"]="tac_installer_tac_db"
                  ["--db_host"]="tac_installer_tac_db_host"
                  ["--db_port"]="tac_installer_tac_db_port"
                  ["--db_user"]="tac_installer_tac_db_user"
                  ["--db_password"]="tac_installer_tac_db_password"
                  ["--db_class"]="tac_installer_tac_db_class"

                  ["--working_dir"]="tac_installer_tac_working_dir"
                  ["--umask"]="tac_installer_umask"
                )

    declare -A tac_installer_exec_options=(
                  ["-c"]="load_config"
                  ["--config"]="load_config"
                )

    declare -A tac_installer_args

    declare -A tac_installer_subcommands=(
                  ["help"]="tac_installer_help"
                  ["download"]="tac_installer_download"
                  ["create_users"]="tac_installer_create_users"
                  ["create_folders"]="tac_installer_create_folders"
                  ["random_password"]="tac_installer_mysql_random_password"
                  ["create_tac_db"]="tac_installer_mysql_create_tac_db"
                  ["install"]="tac_installer_install"
                  ["uninstall"]="tac_installer_uninstall"
                  ["install_service"]="tac_installer_create_instance"
                  ["uninstall_service"]="tac_installer_create_instance"
                )

    declare -A tac_installer_descriptions=(
                  ["--config"]="tac_installer_config"
                  ["--version"]="tac_installer_tac_version"

                  ["--download_url"]="tac_installer_talend_distro_url"
                  ["--download_userid"]="tac_installer_talend_download_userid"
                  ["--download_password"]="tac_installer_talend_download_password"

                  ["--repo_dir"]="tac_installer_repo_dir"
                  ["--tac_base"]="tac_installer_tac_base"
                  ["--install_user"]="tac_installer_install_user"
                  ["--install_group"]="tac_installer_install_group"
                  ["--admin_user"]="tac_installer_tac_admin_user"
                  ["--service_user"]="tac_installer_tac_service_user"
                  ["--group"]="tac_installer_tomcat_group"

                  ["--db"]="tac_installer_tac_db"
                  ["--db_host"]="tac_installer_tac_db_host"
                  ["--db_port"]="tac_installer_tac_db_port"
                  ["--db_user"]="tac_installer_tac_db_user"
                  ["--db_password"]="tac_installer_tac_db_password"
                  ["--db_class"]="tac_installer_tac_db_class"

                  ["--working_dir"]="tac_installer_tac_working_dir"
                  ["--umask"]="tac_installer_umask"

                  ["help"]="tomcat_installer_help"
                  ["download"]="tomcat_installer_download"
                  ["create_users"]="tomcat_installer_create_users"
                  ["create_folders"]="tomcat_installer_create_folders"
                  ["random_password"]="tac_installer_mysql_random_password"
                  ["create_tac_db"]="tac_installer_mysql_create_tac_db"
                  ["install"]="tomcat_installer_install"
                  ["uninstall"]="tomcat_installer_uninstall"
                  ["install_service"]="tomcat_installer_create_instance"
                  ["uninstall_service"]="tomcat_installer_create_instance"
                )

    local optindex
    local -a tac_installer_command

    source /dev/stdin <<<"${tac_installer_init}"
    source /dev/stdin <<<"${tac_installer_mysql_init}"

    load_context

    umask "${tac_installer_umask}"

    parse_args tac_installer_command \
               optindex \
               tac_installer_options \
               tac_installer_exec_options \
               tac_installer_args \
               tac_installer_subcommands \
               tac_installer_descriptions \
               "${@}"
    shift "${optindex}"
    [ "${#tac_installer_command[@]}" == 0 ] && tac_installer_help && return 0

    debugLog "command: ${tac_installer_command[@]} ${@}"
    "${tac_installer_command[@]}" "${@}"

}
