#!/bin/bash

print_style () {

    if [ "$2" == "info" ] ; then
        COLOR="96m"
    elif [ "$2" == "success" ] ; then
        COLOR="92m"
    elif [ "$2" == "warning" ] ; then
        COLOR="93m"
    elif [ "$2" == "danger" ] ; then
        COLOR="91m"
    else #default color
        COLOR="0m"
    fi

    STARTCOLOR="\e[$COLOR"
    ENDCOLOR="\e[0m"

    printf "$STARTCOLOR%b$ENDCOLOR" "$1"
}

display_options () {
    printf "有效的命令及格式:\n";
    print_style "   create  \$env" "info"; printf "\t\t\t 创建个人的开发环境代码空间.并重启服务\n"
    print_style "   update  \$env  [all|\$project]" "info"; printf "\t 更新不存在的项目，并生成相应开发环境空间代码，并重启服务.\n"
    print_style "   upgrade \$env  [all|\$project]" "info"; printf "\t 更新已存在的项目，环境配置，并重启服务.\n"
    print_style "   delete  \$env" "danger"; printf "\t\t\t 删除人个项目开发环境.\n"
}

if [[ $# -eq 0 ]] ; then
    print_style "缺少参数.\n" "danger"
    display_options
    exit 1
fi

if [[ -z $2 ]] ; then
    print_style "缺少参数,个人项目名 \$env .\n" "danger"
    display_options
    exit 1
fi

#root 目录
rootDir=/kalading/webroot
#dev 目录 
devDir=$rootDir/dev
#env 目录 
envDir=$rootDir/env

if [ ! -d "$devDir" ] ; then
    print_style "公用开发代码目录不存在\n" "danger"
    exit 1
fi

#开发环境项目配置目录 
if [ ! -d "$envDir" ] ; then
    print_style "开发环境项目配置目录不存在\n" "warning"
    mkdir -p $envDir
    print_style "开发环境项目配置目录 [$envDir],创建成功\n" "info"
else
    print_style "开发环境项目配置目录[$envDir]\n" "info"
fi

# 生成自己的项目配置文件
# use generate_self_env env project
generate_self_env(){
    if [ -z "$2" ] ; then
    	projects=`ls -l ${userDir} |grep ^d | awk '{print $9}'`


    	for project in ${projects} 
    	do
            generate_self_env_one $project
    	done
    else
    	generate_self_env_one $2	
    fi

}

generate_self_env_one(){

    if [ -z "$1" ]; then
        print_style "缺少工程\$project参数 \n\n" "danger"
    fi

   
	  projectEnvDir=$userDir/$1/environments/dev
    destinationEnvDir=$userEnvDir/$1/dev

    if [ -d "$projectEnvDir" ]; then
        print_style "生成项目$1配置文件 path=$userDir/$1 \n" "info"

        if [ ! -d "$destinationEnvDir" ]; then
            mkdir -p $destinationEnvDir
        fi

        \cp -Rf $projectEnvDir/* $destinationEnvDir
        print_style "执行命令 cp -Rf $projectEnvDir/* $destinationEnvDir \n" "info"

        #替换已生的环境配置，其中的域名替换为个人的域名

    fi

    #替换已生的环境配置，其中的域名替换为个人的域名

    #生成docker-compose ngingx配置文件
}

 # 目录是否存在
userDir="$rootDir/$2"

if [ ! -d "$userDir" ] ; then
    print_style "用户$userDir目录不存在,创建用户目录 \n\n" "info"
    mkdir -p $userDir

# cd ${DOCKER_DIR}
# \cp -Rf environments/${host_env}/* .
# chmod -R 0755 ${DOCKER_DIR}
# find . -type d -env runtime|xargs chmod -R 0777
# find . -type d -env assets |xargs chmod -R 0777
        
fi

userEnvDir="$envDir/$2"
if [ ! -d "$userEnvDir" ] ; then
    print_style "用户$userEnvDir,创建成功 \n\n" "info"
    mkdir -p $userEnvDir
fi

if [ "$1" == "create" ] ; then
    print_style "初始化$2代码空间，创建开发环境相关配置文件 \n" "info"


    # copy 代码目录
    \cp -Rf ${devDir}/* ${userDir}
    ls $userDir -la
    
    #生成项目配置文件
    generate_self_env
    print_style "创建成功后会重启开发环境\n" "info"

elif [ "$1" == "update" ]; then
    print_style "更新$2代码空间，创建开发环境相关配置文件 \n" "info"
    print_style "更新成功后会重启开发环境\n" "info"
    docker-compose stop

    print_style "Stopping Docker Sync\n" "info"
    docker-sync stop

elif [ "$1" == "upgrade" ]; then
	
    print_style "更新$2开发环境相关配置文件 \n" "info"
    print_style "更新成功后会重启开发环境\n" "info"

elif [ "$1" == "delete" ]; then
    print_style "删除$2代码空间，及开发环境相关配置文件 \n" "info"
    print_style "删除成功后会重启开发环境\n" "info"
    docker-sync clean
else
    print_style "缺少参数.\n" "danger"
    display_options
    exit 1
fi


#取得模板下面所有的域名
#grep 'server_name' ./* | awk '{ print $3 }' | awk -F ';' '{ print $1 }'
