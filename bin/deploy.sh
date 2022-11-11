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
# root 設定
function root_setup {
	if ! type gcc; then
		sudo su - << EOF
		yum -y install openssl-devel
		yum -y install bzip2-devel
		yum -y install libffi-devel
		yum -y install gcc 
	fi
EOF
}

# bashrc インストール
function install_bashrc {
	cp -f ${TOOL_HOME}/conf/.bashrc ${HOME}/.bashrc
}

# python インストール
function install_python {
	local version="${1:-3.9.6}"
	if ! [ -d "Python-${version}/python" ]; then
		wget "https://www.python.org/ftp/python/${version}/Python-${version}.tgz"
		gtar xvzf "Python-${version}.tgz"
		(
		    cd "Python-${version}"
		    ./configure --enable-optimizations --prefix=${HOME}/python
		    make install
		)
		ln -nfs python3 ${HOME}/python/bin/python
		rm -rf ${HOME}/Python-${version}*
	fi
}

# git クローン
function git_clone {
	local git_path="${1:?ERROR: require git path. user/repository}"
	local version="${2:+-d ${2}}"
	local install="${3:-}"
	if ! [ -d "${install}" ]; then
	    git clone "https://$(github_access_token)@github.com/${git_path}" ${version} ${install}
	fi
}

# github アクセストークン入力
function github_access_token {
    if [ -z "${GITHUB_ACCESS_TOKEN}" ]; then
        read -sp 'INFO: require github access token: ' GITHUB_ACCESS_TOKEN
        echo '' # 入力完了を示す echo
    fi
    echo "${GITHUB_ACCESS_TOKEN}"
}

# 全部設定
function all {
    root_setup
    install_bashrc
    install_python
    exit	# 強制的に exit して .bashrc を読み直す
}

#-------------------------------------
# 使い方
function usage {
    cat ${0} | sed -n '/^#.*#$/,$p' | egrep ';;|#'
}


#-------------------------------------
# 環境初期化
git_clone "mro-lab/mrolab-shell" "" "${HOME}/mrolab-shell"
source ${HOME}/mrolab-shell/lib/argp.shm
source ${HOME}/mrolab-shell/lib/common.shm
source ${HOME}/mrolab-shell/lib/config.shm

# 引数解析
argp "${@}"

# action #
case "${ARGP[0]:-}" in
    root_setup)             root_setup			"${ARGP[@]:1}" ;;   # 
    install_bashrc)			install_bashrc		"${ARGP[@]:1}" ;;   # 
    install_python)			install_python		"${ARGP[@]:1}" ;;   # 
    github_access_token)	github_access_token	"${ARGP[@]:1}" ;;   # 
    all)                    all                 "${ARGP[@]:1}" ;;   # 全部設定
    *)                      usage                              ;;   # 使い方
esac
