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
    print_style "   update  \$env  [\$project]" "info"; printf "\t 更新不存在的项目，并生成相应开发环境空间代码，并重启服务.\n"
    print_style "   deploy   \$env  \$project  \$branch" "info";  printf "\t 部署项目.\n"
    print_style "   restart  "     "info"; printf "\t 重启服务.\n"
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
hostTemplateFile=$rootDir/hosts_template
dockerComposerFile=$rootDir/devdock/docker-compose.yml
nginxTemplatesDir=$rootDir/nginx_template
nginxDestinationDir=$rootDir/nginx

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
# use generate_project_env env project
generate_project_env(){
    if [ -z "$2" ] ; then
    	projects=`ls -l ${userDir} |grep ^d | awk '{print $9}'`

    	for project in ${projects} 
    	do
            generate_project_env_one $1 $project
    	done
    else
    	generate_project_env_one $1 $2
    fi
}
#生产nginx配置文件
generate_nginx_config(){
    #nginx配置目录

    if [ ! -d "$nginxUserDir" ]; then
        mkdir -p $nginxUserDir
    fi

    #复制nginx配置到用户配置目录
    \cp -Rf $nginxTemplatesDir/* $nginxUserDir
    print_style "复制nginx配置到用户配置目录成功。执行命令 cp -Rf $nginxTemplatesDir/* $nginxUserDir \n" "info"

    #批量替换文件名
    cd $nginxUserDir
    ls . | sed -r "s#dev(.*)#mv & $1\1#" | bash
    ls -lh $nginxUserDir
    #批量替换配置
    find $nginxUserDir -type f | xargs sed  -ri "s/dev/$1/g"

    \cp -R $nginxUserDir/* $nginxDestinationDir
}
#生产dockerCompose 文件
generate_docker_file(){
  #生成dockerhost映射，根据host_template

    if [ -f "$hostTemplateFile" ]; then
		print_style "$hostTemplateFile found. 添加hos配置\n" "info"
		#while IFS='=' read -r key value
		while read line
		do
			#echo $line
			if [ -n "$line" ]; then
			  print_style "$line \n" "info"
			  newHost=$(echo $line | sed  "s/dev/$1/")
			  print_style "$newHost \n" "info"
			  str=`grep $newHost $dockerComposerFile`
			  if [[ -z "$str" &&  -n "$newHost" ]]; then
				sed -i "/#replace_extra_host#/i\      - $newHost:127.0.0.1" $dockerComposerFile
				print_style " docker-compose.yml 添加 $newHost:127.0.0.1 成功 \n" "info"
			  else
				print_style "docker-compose.yml 已经添加过 $newHost:127.0.0.1 \n" "warning"
			  fi
			fi
		done < "$hostTemplateFile"

    else
		print_style "$hostTemplateFile not found\n" "danger"
    fi
}
#重启开发环境
restart_docker(){
    print_style "开始重启开发环境\n" "info"
    cd $rootDir/devdock
    docker-compose stop
    docker-compose up -d
    docker-compose ps
    print_style "开发环境重启成功\n" "info"
}

#生成个人开发环境配置
generate_project_env_one(){

    if [ -z "$1" ]; then
        print_style "缺少工程\$1参数 \n\n" "danger"
    fi

    if [ -z "$2" ]; then
        print_style "缺少工程\$2参数 \n\n" "danger"
    fi

    projectEnvDir=$userDir/$2/environments/dev
    destinationEnvDir=$userEnvDir/$2/dev

    if [ -d "$projectEnvDir" ]; then
        print_style "生成项目$1配置文件 path=$userDir/$2 \n" "info"

        if [ ! -d "$destinationEnvDir" ]; then
            mkdir -p $destinationEnvDir
        fi

        \cp -Rf $projectEnvDir/* $destinationEnvDir
        print_style "执行命令 cp -Rf $projectEnvDir/* $destinationEnvDir \n" "info"

        #替换已生的环境配置，其中的域名替换为个人的域名
        find $destinationEnvDir -type f | xargs sed  -ri "s/(dev)(\.[^php])/$1\2/g"
        find $destinationEnvDir -type f | xargs sed  -ri "s/http:\/\/dev/http:\/\/$1/g"
        print_style "替换工程配置文件成功 $destinationEnvDir \n" "info"
        #find ./ -type f | xargs grep

    fi

}

# 更新已经存在的项目代码及配置
generate_code_dir(){
    # copy 代码目录

    if [ -z "$2" ] ; then
		if [ -d "$userDir" ]; then
			projects=`ls -l ${devDir} |grep ^d | awk '{print $9}'`

			for project in ${projects}
			do
				userProjectDir=$userDir/$project
				if [ -d "$userProjectDir" ]; then
				print_style "项目userProjectDir 已经存在 \n" "danger"
				else
				 print_style "复制项目${devDir}/$project 到用户目录 $userDir \n" "info"
				 \cp -Rf ${devDir}/$project ${userDir}
				fi
			done
		else
			\cp -Rf ${devDir}/* ${userDir}
			ls $userDir -lh
		fi

    else
       projectDevDir=$devDir/$2
		if [ -d "$projectDevDir" ];then
          print_style "复制项目$projectDevDir 到用户目录 $userDir \n" "info"
    	    \cp -Rf ${devDir}/$2 ${userDir}
		else
    	    print_style "项目$projectDevDir 不存在 \n" "danger"
		fi
    fi
}

#删除用户代码空间
delete_project_code(){
	if [[ -z "$2" ]];then
		rm -rf $userDir
	else
		rm -rf $userDir/$2
	fi;
}
#删除用户配置文件
delete_project_conf(){
	if [[ -z "$2" ]];then
		rm -rf $envDir/$1
	else
		rm -rf $envDir/$1/$2
	fi;
}
#删除用户nginx配置文件
delete_nginx_conf(){
  if [[ -z "$2" ]]; then
    nginxConfFiles=`ls -l ${nginxUserDir} |grep ^d | awk '{print $9}'`
    for nginxConfFile in ${nginxConfFiles}
    do
        delNginxFile=$nginxDestinationDir/$nginxConfFile
        if [ -f "$delNginxFile" ]; then
          rm -f $delNginxFile
          print_style " 删除 $delNginxFile \n" "info"
        else
           print_style "$delNginxFile 文件存在 \n" "warning"
        fi
    done
  fi

}
#删除docker-compose.yml中的域名映射
delete_docker_conf(){
    sed -i "/ - $1/d" $dockerComposerFile
}

 # 目录是否存在
userDir="$rootDir/$2"

if [ ! -d "$userDir" ] ; then
    print_style "用户$userDir目录不存在,创建用户目录 \n\n" "info"
    mkdir -p $userDir
        
fi

userEnvDir="$envDir/$2"
nginxUserDir=$envDir/$2/nginx
if [ ! -d "$userEnvDir" ] ; then
    print_style "用户$userEnvDir,创建成功 \n\n" "info"
    mkdir -p $userEnvDir
fi

if [ "$1" == "create" ] ; then

    if [ "$2" == "dev" ] ; then
      print_style "dev 是开发基础环境及代码空间不能创建 \n" "danger"
      exit 1;
    fi

    print_style "初始化$2代码空间，创建开发环境相关配置文件 \n" "info"
    generate_code_dir $2 $3
    
    #生成项目配置文件
    print_style "创建成功后会重启开发环境\n" "info"
    generate_project_env $2 $3
    print_style "生成用户nginx配置文件\n" "info"
    generate_nginx_config $2
    print_style "添加host到docker-compose.yml \n" "info"
    generate_docker_file $2
    restart_docker


elif [ "$1" == "update" ]; then
    print_style "更新$2代码空间，更新$2开发环境相关配置文件 \n" "info"
    generate_code_dir $2 $3
    print_style "更新成功后会重启开发环境\n" "info"
    generate_project_env $2 $3
    print_style "生成用户nginx配置文件\n" "info"
    generate_nginx_config $2
    print_style "添加host到docker-compose.yml \n" "info"
    generate_docker_file $2
    restart_docker
elif [[ "$1" == "deploy" ]]; then
    root=/kalading/webroot
    if [[ -z "$3"  ||  -z "$4" ]];then
        print_style "\$project 或 \$branch 不能为空 \n" "danger"
        exit 0
    fi
    env=$2
    
    #判断是否是前端项目，前端项目都是frontend命名
    isFrontend=`echo $3 | grep 'frontend'`
    if [[ -z "$isFrontend" ]]; then
    	currentProject=$rootDir/$2/$3
    else
	currentProject=$rootDir/$2/opt/$3
    fi

    branch=$4

    if [[ ! -d $currentProject ]]; then
         print_style "$currentProject 不存在 \n" "danger"
         exit 0
    fi

    cd $currentProject

    git checkout master -f
    git pull
    git fetch
    git checkout $branch -f
    git pull origin $branch
    print_style "当前运行命令目录 `pwd` \n" "info"
    if [[ -z "$isFrontend" ]]; then
    	if [[ "$2" == "dev" ]]; then
			if [[ "$3" == 'notice' || "$3" == 'notify' ]];then
                \cp -f environments/dev/.env .env
			else
				\cp -R environments/dev/* .
			fi
    	else
			if [[ "$3" == 'notice' || "$3" == 'notify' ]];then
                \cp -f environments/$3/dev/.env .env
			else
				\cp -R $userEnvDir/$3/dev/* .
			fi
    	fi
    
        if [[ "$3" == 'notice' || "$3" == 'notify' ]]; then
            	find . -type d -name storage|xargs chmod -R 0777 
        else
			find . -type d -name runtime|xargs chmod -R 0777
    		find . -type d -name assets|xargs chmod -R 0777
    		rm -f api/runtime/hprose_cache
    		rm -f backend/runtime/hprose_cache
    		rm -f console/runtime/hprose_cache
			chmod -R 777 common/runtime
    		composer dump-autoload -o
    		echo "yes"|php ./yii cache/flush-schema
        fi
    else 
    	\cp -R $userEnvDir/$3/opt/* .
		#替换为个人域名及配置
		frontendConf=./src/config/api.js
		if [[ -f "$frontendConf" ]]; then
           sed  -ri "s/dev\./$2\./g"  $frontendConf
           print_style "替换 $3 工程配置文件成功 $frontendConf \n" "info"
        fi
		yarn install
        yarn run build
        \cp -R ./dist/* $rootDir/$2/$3
        cd $rootDir/$2/$3
        sed -i "s#<\/head>#<script>var env = 'dev'; var publicPath = '/';<\/script><\/head>#" ./index.html 
        \cp -f index.html index.php
    fi

    if [[ "$3" == 'notify' ]]; then
    	restart_docker
    fi
elif [ "$1" == "restart" ]; then
    restart_docker

elif [ "$1" == "delete" ]; then
    print_style "删除$2代码空间，及开发环境相关配置文件 \n" "info"
    print_style "删除成功后会重启开发环境\n" "info"
    if [ -z "$3" ]; then
      delete_docker_conf $2
      delete_nginx_conf $2
      delete_project_code $2
      delete_project_conf $2
    fi;
    delete_project_code $2 $3
    print_style "删除$2/$3代码空间成功\n" "info"
    restart_docker
else
    print_style "缺少参数.\n" "danger"
    display_options
    exit 1
fi


#取得模板下面所有的域名
#grep 'server_name' ./* | awk '{ print $3 }' | awk -F ';' '{ print $1 }'
