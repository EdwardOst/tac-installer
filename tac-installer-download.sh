[ "${TAC_INSTALLER_DOWNLOAD_FLAG:-0}" -gt 0 ] && return 0

export TAC_INSTALLER_DOWNLOAD_FLAG=1



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
    [ ! -d "${tac_installer_source_dir}" ]&& echo "ERROR: source_dir does not exist: ${tac_installer_source_dir}" && return 1
    [ ! -f "${tac_installer_source_dir}/${tac_installer_tac_zip_file}" ]&& echo "ERROR: source file does not exist: ${tac_installer_source_dir}/${tac_installer_tac_zip_file}" && return 1

    create_user_directory "${tac_installer_repo_dir}"
    ln -s "${tac_installer_source_dir}/${tac_installer_tac_zip_file}" \
          "${tac_installer_repo_dir}/${tac_installer_tac_zip_file}"
}

