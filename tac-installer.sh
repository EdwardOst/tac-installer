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

define tac_installer_init <<'EOF'
    local tac_installer_talend_version="${TAC_INSTALLER_TALEND_VERSION:-${tac_installer_talend_version:-6.3.1}}"
    local tac_installer_talend_version_suffix="${tac_installer_talend_version//.}"
    local tac_installer_talend_distro_root="${TAC_INSTALLER_TALEND_DISTRO_ROOT:-${tac_installer_talend_distro_root:-tpdsbdrt}}"
    local tac_installer_talend_distro_timestamp="${TAC_INSTALLER_TALEND_DISTRO_TIMESTAMP:-${tac_installer_talend_distro_timestamp:-20161216_1026}}"
    local tac_installer_talend_download_host="${TAC_INSTALLER_TALEND_DOWNLOAD_HOST:-${tac_installer_talend_download_host:-www.opensourceetl.net}}"
    local tac_installer_tac_zip_file="Talend-AdministrationCenter-${tac_installer_talend_distro_timestamp}-V${tac_installer_talend_version}.zip"

    local tac_installer_talend_download_userid="${TALEND_INSTALLER_TALEND_DOWNLOAD_USERID:-${tac_installer_talend_download_userid:-eost}}"
    local tac_installer_talend_download_password="${TALEND_INSTALLER_TALEND_DOWNLOAD_PASSWORD:-${talend_installer_talend_download_password:-Ahha9oax7n-}}"

    local tac_installer_repo_dir="${TAC_INSTALLER_REPO_DIR:-${tac_installer_repo_dir:-/opt/repo/talend/tac}}"
    local tac_installer_tac_base="${TAC_INSTALLER_TAC_BASE:-${tac_installer_tac_base:-/opt/tac}}"
    local tac_installer_tac_admin_user="${TAC_INSTALLER_TAC_ADMIN_USER:-${tac_installer_tac_admin_user:-tac_admin}}"
    local tac_installer_tomcat_group="${TAC_INSTALLER_TOMCAT_GROUP:-${tac_installer_tomcat_group:-tomcat}}"
EOF


#
# retrieve tac install files from GCS
#
function tac_retrieve() {
        local _tacInstallDir=${talendInstallDir}/tac
        local _zipFile=Talend-AdministrationCenter-${talendDate}_${talendRelease}-V${TALEND_VERSION}.zip

        talend_retrieve tac ${_zipFile}
        talend_retrieve tac ${_zipFile}.MD5
        (cd ${_tacInstallDir}; md5sum -c ${_zipFile}.MD5)
}


function tac_installer_download() {
    wget --no-clobber \
        --directory-prefix="${tac_installer_repo_dir}" \
        --http-user="${tac_installer_talend_download_userid}" \
        --http-password="${tac_installer_talend_download_password}" \
        "http://${tac_installer_talend_download_host}/tis/${tac_installer_talend_distro_root}_${tac_installer_talend_version_suffix}/${tac_installer_tac_zip_file}"

    wget --no-clobber \
        --directory-prefix="${tac_installer_repo_dir}" \
        --http-user="${tac_installer_talend_download_userid}" \
        --http-password="${tac_installer_talend_download_password}" \
        "http://${tac_installer_talend_download_host}/tis/${tac_installer_talend_distro_root}_${tac_installer_talend_version_suffix}/${tac_installer_tac_zip_file}.MD5"

    (cd "${tac_installer_repo_dir}"; md5sum -c "${tac_installer_tac_zip_file}.MD5")
}


function tac_installer_download_local() {
    [ "${#}" -lt 1 ] && echo "ERROR: usage: tac_installer_download_local <source_dir>" && return 1
    local tac_installer_source_dir="${1}"
    create_user_directory "${tac_installer_repo_dir}"
    ln -s "${tac_installer_source_dir}/${tac_installer_tac_zip_file}"
          "${tac_installer_repo_dir}/${tac_installer_tac_zip_file}"
}


function tac_installer_create_folders() {
    sudo -s -u "${tac_installer_tac_admin_user}" -g "${tac_installer_tomcat_group}" <<-EOF
	mkdir -p "${tac_installer_tac_base}/tac-archive"
	mkdir -p "${tac_installer_tac_base}/jobs"
	mkdir -p "${tac_installer_tac_base}/executionLogs"
	mkdir -p "${tac_installer_tac_base}/cmdline"
	mkdir -p "${tac_installer_tac_base}/components"
	EOF
}


function tac_installer_unzip_war() {
    [ "${#}" -lt 1 ] && echo "ERROR: usage: tac_unzip <tac_working_dir_ref>" && return 1

    local -n tac_working_dir="${1}"
    tac_working_dir=$(mktemp -d --tmpdir=.)

    sudo -u "${tac_installer_tac_admin}" -g "${tac_installer_tomcat_group}" \
         unzip -q "${tac_installer_repo_dir}/${tac_installer_tac_zip_file}" -d "${tac_working_dir}"
}


function tac_installer_prepare_war() {
function tacPrepareWar() {
        [ $# -lt 1 ] && echo "ERROR: usage: tacPrepareWar tacWorkingDir" && return 1
        [ ! -d "${1}" ] && echo "ERROR: tac working directory parameter does not exist: ${1}" && return 1

        local _tacWorkingDir="${1}"; debugVar _tacWorkingDir
        local _unzipDir="${_tacWorkingDir}/Talend-AdministrationCenter-${talendDate}_${talendRelease}-V${TALEND_VERSION}"; debugVar _unzipDir
        local _tacWarDir=${_unzipDir}/tac; debugVar _tacWarDir

        unzip -q ${_unzipDir}/org.talend.administrator-${TALEND_VERSION}.war -d ${_tacWarDir}

        debugLog "backup tac webapp configuration"
        local _tacConfigProperties="${_tacWarDir}/WEB-INF/classes/configuration.properties"; debugVar _tacConfigProperties
        cp -n ${_tacConfigProperties}  ${_tacConfigProperties}.orig

        debugLog "comment out old database connection"
        cat  ${_tacConfigProperties}.orig \
                | sed -e "s/^\(database\.url[ \t]*=.*$\)/\#\1/" \
                | sed -e "s/^\(database\.driver[ \t]*=.*$\)/\#\1/" \
                | sed -e "s/^\(database\.username[ \t]*=.*$\)/\#\1/" \
                | sed -e "s/^\(database\.password[ \t]*=.*$\)/\#\1/" \
                > ${_tacConfigProperties}.new

        debugLog "insert new database connection properties immediately after Used Values flag"
        cat ${_tacConfigProperties}.new \
                | sed -e "s/^\(### Used values ###.*$\)/\1\n/" \
                | sed -e "s/^\(### Used values ###.*$\)/\1\ndatabase\.password=${tacDbPassword}/" \
                | sed -e "s/^\(### Used values ###.*$\)/\1\ndatabase\.username=${tacDbUsername}/" \
                | sed -e "s/^\(### Used values ###.*$\)/\1\ndatabase\.driver=org\.gjt\.mm\.mysql\.Driver/" \
                | sed -e "s/^\(### Used values ###.*$\)/\1\ndatabase.url=jdbc:mysql:\/\/${tacDbHost}:${tacDbPort}\/${tacDatabase}/" \
                > ${_tacConfigProperties}.new2

        cp ${_tacConfigProperties}.new2  ${_tacConfigProperties}

        result _tacWarDir
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
        local _tomcatHomeDir="${1:-"/opt/apache-tomcat-${tomcatVersion}"}"; debugVar _tomcatHomeDir
        local _tacDir="${2:-"/opt/Talend/${TALEND_VERSION}/tac"}"; debugVar _tacDir
        local _tacTomcatDir="${_tacDir}/apache-tomcat"; debugVar _tacTomcatDir

        # create TAC directory
        createUserOwnedDirectory ${_tacDir}
        tacConfig ${_tacDir}

        # prepare the tomcat configuration
        tacConfigTomcatInstance ${_tomcatHomeDir} ${_tacTomcatDir}

        # unzip and prepare the tac webapp configuration
        local _tacUnzip_result;
        tacUnzip
        local _tacWorkingDir=${_tacUnzip_result}; debugVar _tacWorkingDir

        local _tacPrepareWar_result;
        tacPrepareWar ${_tacWorkingDir}
        local _tacWarDir=${_tacPrepareWar_result}; debugVar _tacWarDir

        # copy the mysql client symbolic link to tac library
        mysql_client_path
        cp ${_mysql_client_path_result} ${_tacWarDir}/WEB-INF/lib

        mv ${_tacWarDir} ${_tacTomcatDir}/webapps

        debugLog "create tac initialization script in /etc/profile.d"
        sudo tee /etc/profile.d/tac-${TALEND_VERSION}.sh <<EOF
export CATALINA_HOME=${_tomcatHomeDir}
export CATALINA_BASE=${_tacTomcatDir}
export TAC_HOME=${_tacWarDir}
EOF

}


# create_tomcat_user
# install_tomcat
tac_download
tac_config
tac_unzip
tac_config_tomcat_instance
tac_prepare_war
tac_create_db
#tac_install_service
