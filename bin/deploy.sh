#!/bin/bash -Eeu
trap 'echo "ERROR: ${0}:${LINENO} > ${BASH_COMMAND} [${?}] (${SECONDS}sec)" 1>&2' ERR
shopt -s expand_aliases
set -o pipefail

# 初期化
REAL_PATH=$(realpath "${0}")
BASH_NAME="${REAL_PATH##*/}"
BASH_HOME="${REAL_PATH%/*}"
TOOL_HOME=$(realpath "${TOOL_HOME:-${BASH_HOME}/..}")

#-------------------------------------
# 環境初期化
if ! [ -d "${HOME}/mrolab-shell" ]; then
    git clone "https://github.com/mro-lab/mrolab-shell" -b 2.2.mro
fi 
source ${HOME}/mrolab-shell/bin/import

# 引数解析
argp "${@}"

#-------------------------------------
# root 設定
function root_setup {
    if ! type gcc; then
        sudo su - <<- EOF
        yum -y install openssl-devel
        yum -y install bzip2-devel
        yum -y install libffi-devel
        yum -y install gcc 
EOF
    fi
}

# bashrc インストール
function install_bashrc {
    cp -f ${TOOL_HOME}/conf/.bashrc ${HOME}/.bashrc
}

# python インストール
function install_python {
    local version="${1:-3.9.6}"
    
    if ${HOME}/python/bin/python --version | grep "${version}"; then
        echo "pytohn installed."
        return 0
    fi
    (
        cd ${HOME}
        wget "https://www.python.org/ftp/python/${version}/Python-${version}.tgz" -O "Python-${version}.tgz"
        gtar xvzf "Python-${version}.tgz"
        cd "Python-${version}"
        ./configure --enable-optimizations --prefix=${HOME}/python
        make install
        ln -nfs python3 ${HOME}/python/bin/python
        rm -rf ${HOME}/Python-${version}		# 容量削減のため削除
        rm -rf ${HOME}/Python-${version}.tgz	# 容量削減のため削除
    )
}

# awsctl インストール
function install_awsctl {
    ${HOME}/python/bin/python -m pip install boto3
    ${HOME}/python/bin/python -m pip install pybase62
    source ${BASH_HOME}/github_credential
    ln -nfs mrolab-python ${HOME}/mrolab
    git_clone "${HOME}/mrolab-python" "mro-lab/mrolab-python" "1.2" "${GITHUB_CREDENTIAL}"
    git_clone "${HOME}/awsctl" "mro-lab/awsctl" "2.0" "${GITHUB_CREDENTIAL}"
}

# 全部設定
function all {
    root_setup
    install_bashrc
    install_python
    install_awsctl
    echo "please 'exit' once for .bashrc reload."
}

# 使い方
function usage {
    cat ${0} | sed -n '/^#.*#$/,$p' | egrep ';;|#'
}


#-------------------------------------
# action #
case "${ARGP[0]:-}" in
    root_setup)             root_setup          "${ARGP[@]:1}" ;;   # root 設定
    install_bashrc)         install_bashrc      "${ARGP[@]:1}" ;;   # bashrc インストール
    install_python)         install_python      "${ARGP[@]:1}" ;;   # python インストール
    install_awsctl)         install_awsctl      "${ARGP[@]:1}" ;;   # awsctl インストール
    all)                    all                 "${ARGP[@]:1}" ;;   # 全部設定
    *)                      usage                              ;;   # 使い方
esac
