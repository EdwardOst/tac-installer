set -e
set -x


tomcatVersion="8.5.15"
TALEND_VERSION="6.3.1"


function create_tomcat_user() {

sudo groupadd tomcat
sudo useradd -s /bin/false -g tomcat tomcat
for u in $(sudo lid -g -n talend); do sudo usermod -a -G tomcat $u; done

}

function install_tomcat() {

targetDir="/opt"
tomcatDir="${targetDir}/apache-tomcat-${tomcatVersion}"
tomcat_tgz="apache-tomcat-${tomcatVersion}.tar.gz"

wget "http://apache.osuosl.org/tomcat/tomcat-8/v${tomcatVersion}/bin/apache-tomcat-${tomcatVersion}.tar.gz"

sudo tar -xzf "${tomcat_tgz}" --directory "${targetDir}"
# sudo chown -R tomcat:tomcat "${tomcatDir}"

sudo ln -s "${tomcatDir}" "${targetDir}/tomcat"
sudo chown -h tomcat:tomcat "${targetDir}/tomcat"

# grant permissions to tomcat
sudo chgrp -R tomcat "${tomcatDir}/conf"
sudo chown ec2-user "${tomcatDir}/conf"
sudo chmod g+rwx "${tomcatDir}/conf"
sudo chmod g+r ${tomcatDir}/conf/*
sudo chown -R tomcat:tomcat "${tomcatDir}/work/" "${tomcatDir}/temp/" "${tomcatDir}/logs/"
sudo chown root "${tomcatDir}/conf"

}

function tac_download() {
   wget "http://www.opensourceetl.net/tis/tpdsbdrt_631/Talend-AdministrationCenter-20161216_1026-V6.3.1.zip"
}


function tac_config() {
        local _tomcatHomeDir="/opt/tomcat"
        local _tacDir="/opt/Talend/${TALEND_VERSION}/tac"}"
        local _tacTomcatDir="${_tacDir}/apache-tomcat"

        # create TAC directory
        mkdir -p "${_tacDir}"
        sudo chown talend:talend "${_tacDir}"
        mkdir ${_tacDir}/tac-archive
        mkdir ${_tacDir}/logs
        mkdir ${_tacDir}/jobs
        mkdir ${_tacDir}/executionLogs
        mkdir ${_tacDir}/cmdline
        mkdir ${_tacDir}/components
}



function tac_unzip() {
        local _tacInstallDir="${talendInstallDir}/tac"; debugVar _tacInstallDir
        local _tacWorkingDir=$(mktemp -d --tmpdir=.); debugVar _tacWorkingDir
        local _zipFile="Talend-AdministrationCenter-${talendDate}_${talendRelease}-V${TALEND_VERSION}.zip"; debugVar _zipFile
        unzip -q ${_tacInstallDir}/${_zipFile} -d ${_tacWorkingDir}
        result _tacWorkingDir
}



function tac_config_tomcat_instance() {

        [ $# -lt 2 ] && echo "ERROR: usage: tacConfigTomcatInstassnce tomcatHomeDir tacTomcatDir" && return 1

        local _tomcatHomeDir="${1}"; debugVar _tomcatHomeDir
        local _tacTomcatDir="${2}"; debugVar _tacTomcatDir

        debugLog "create TAC Tomcat directory"
        createUserOwnedDirectory ${_tacTomcatDir}

        debugLog "create TAC tomcat instance files"
        mkdir ${_tacTomcatDir}/bin
        mkdir ${_tacTomcatDir}/conf
        mkdir ${_tacTomcatDir}/lib
        mkdir ${_tacTomcatDir}/logs
        mkdir ${_tacTomcatDir}/webapps
        mkdir ${_tacTomcatDir}/work
        mkdir ${_tacTomcatDir}/temp
        cp ${_tomcatHomeDir}/conf/* ${_tacTomcatDir}/conf

        debugLog "remove last tomcat-users end tag"
        cp -n ${_tacTomcatDir}/conf/tomcat-users.xml ${_tacTomcatDir}/conf/tomcat-users.xml.orig
        cat ${_tacTomcatDir}/conf/tomcat-users.xml.orig | sed -e "s/^\(<\/tomcat-users>\)//" > ${_tacTomcatDir}/conf/tomcat-users.xml

#       cat >> ${_tacTomcatDir}/conf/tomcat-users.xml <<EOF
#  <user username="tadmin" password="tadmin" roles="manager-gui,admin-gui"/>
#</tomcat-users>
#EOF

        debugLog "copy default tomcat apps"
        cp -a ${_tomcatHomeDir}/webapps/ ${_tacTomcatDir}/

        debugLog "set up policy directory with logical link to default policy"
        mkdir -p ${_tacTomcatDir}/work
        mkdir -p ${_tacTomcatDir}/conf/policy.d
        ln -s ${_tacTomcatDir}/conf/catalina.policy ${_tacTomcatDir}/conf/policy.d/catalina.policy

        debugLog "grant permissions to tomcat user"
        sudo chgrp -R tomcat ${_tacTomcatDir}/conf
        sudo chmod g+rwx ${_tacTomcatDir}/conf
        sudo chmod g+r ${_tacTomcatDir}/conf/*
        sudo chown -R tomcat:tomcat ${_tacTomcatDir}/work/ ${_tacTomcatDir}/temp/ ${_tacTomcatDir}/logs/

        debugLog "tacConfigTomcatInstance finished"
}













########

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
