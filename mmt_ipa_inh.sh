#!/bin/bash
# 买买提打包工具
# Author：陈胜
# Mail:  sheng.chen01@bqjr.cn
# Date：2017.3.2
# Update: 2019.09.24

#脚本使用说明
#示例：mmt_ipa.sh [needUpload] [projectPath]
#needUpload  [必传]　是否需要上传到服务器 　　1:上传　0:不上传
#projectPath [可选]　编译打包的工程所在目录  绝对路径，如果路径有空格，请用""包裹.
# 当前目录，不上传  mmt_ipa.sh 0
# 指定目录，上传ipa mmt_ipa.sh 1 "/data/mmt/projct/"
#====================================================

#name,version
#recordAppLog "买买钱包2017.09" "v1.2.3"
function recordAppLog() {
  logPath="${WorkPath}app_release.log"
  #文件名 app_release.log
  #1、读取上个版本记录时间，文件第一行
  recordTime=$(head -1 "${logPath}")
  #2、获取 git日志
  git_log=$(git log --pretty=format:"%h - %an, %ad : %s"  --since="${recordTime}")
  #3、存入文件
  #url_need_show=$(/usr/libexec/PlistBuddy -c "Print:url_need_show" "${MDM_PLIST}")

  echo -e "\n\n----------------------------------------------------">>"${logPath}"
  echo -e "[$1] [$2] [$3] \n[$(date)]">>"${logPath}"
  echo -e '----------------------------------------------------'>>"${logPath}"
  #4、更新Log记录时间
  updateTime=$(date +%Y-%m-%dT%H:%M:%S | sed 's/-0/-/g')
  sed -i "" "s/$recordTime/$updateTime/g" "${logPath}"

  #5、写入到日志
  echo -e "${git_log}" >> "${logPath}"
  #完成#
}

function showErrorNoti(){
  osascript -e 'display notification "脚本执行失败,请关注！" with title "😂😂😂😂"'
}
#输出错误信息(字符串)
function put_error() {
  echo -e "\033[1;31m$1 \033[0m"
}
#输出警告信息(字符串)
function put_warning() {
  echo -e "\033[1;33m$1 \033[0m"
}
#输出提示信息(字符串)
function put_prompt() {
  echo -e "\033[1;32m$1 \033[0m"
}


#########[MAIN]#############
date_start=`date +%s`

ShellPath=""
if [ -n "$2" ] ;then
  ShellPath=$2
else
  ShellPath=$(cd "$(dirname "$0")"; pwd)
fi

#工作副本目录,  可更新路径
WorkPath="${ShellPath}/"
cd "${ShellPath}"

#编译模式  Debug & Release
Configuration="Release"

put_error '\n----------------------------------------------------
|    买买提iOS APP打包工具
|    v2.0 20191108
|    Create by 陈胜.Sherwin
----------------------------------------------------\n'

put_prompt "\n==>(0x01)-->获取工程基本信息...
----------------------------------------------------"

# 读取项目的当前工程的配置信息
#获取app显示名称
projectBuildSettings=$(xcodebuild -showBuildSettings)
#echo ${projectBuildSettings}

#获取app名称
APP_DisplayName=$(echo "${projectBuildSettings}" | grep PRODUCT_MODULE_NAME | head -1 | awk -F "= " '{print $2}')

#获取编译版本
APP_BVersion=$(echo "${projectBuildSettings}" | grep CURRENT_PROJECT_VERSION | head -1 | awk -F "= " '{print $2}')

#获取APP的主版本号
APP_Version=$(echo "${projectBuildSettings}" | grep MARKETING_VERSION | head -1 | awk -F "= " '{print $2}')


APP_TARGETNAME=$(echo "${projectBuildSettings}" | grep TARGETNAME | head -1 | awk -F "= " '{print $2}')

# 设置编译项目的taget
BuildTargetName=$APP_TARGETNAME

put_warning "APP_TARGETNAME: ${APP_TARGETNAME}
APP_DisplayName: ${APP_DisplayName}
APP_BVersion: ${APP_BVersion}
APP_Version: ${APP_Version}"

put_prompt "==>(0x01)  √   NICE WORK.\n"


# 拷贝项目代码到工作目录

TEMP_F="temp"

###工程配置文件路径
put_prompt "\n==>(0x02)-->配置工程文件路径...
----------------------------------------------------"

#获取当前工程名称.
project_path="${ShellPath}"
project_name=$(ls | grep xcodeproj | awk -F.xcodeproj '{print $1}')

#创建保存打包结果的目录
CU_DATA=`date +%Y-%m-%d_%H_%M`
result_path="${project_path}/build_release_${CU_DATA}"
mkdir -p "${result_path}"

if [ ! -e "${project_name}.xcodeproj" ]; then
  showErrorNoti
  put_error "--> ERROR-错误401：找不到需要编译的工程,SO? 编译APP中断."
  exit 401
fi

put_warning "project_name: ${project_name}
result_path:  ${result_path}"

put_prompt "==>(0x02)  √   NICE WORK.\n"

# 编译打包

#打包完的程序目录
appDir="${result_path}/${APP_DisplayName}.app"
#dSYM的路径
dsymDir="${result_path}/${BuildTargetName}.app.dSYM"

#编译工程
put_prompt "\n==>(0x03)-->开始编译，耗时操作,请稍等...
----------------------------------------------------"
put_warning "project_name: ${project_name}
BuildTargetName: ${BuildTargetName}
Configuration:  ${Configuration}"

#"${xcode_build}" clean / -arch arm64 -arch armv7 ONLY_ACTIVE_ARCH=NO  "${project_name}"
xcodebuild -quiet -configuration "${Configuration}" -workspace "${ShellPath}/${project_name}".xcworkspace -scheme "${BuildTargetName}" -arch arm64 ONLY_ACTIVE_ARCH=NO TARGETED_DEVICE_FAMILY=1 DEPLOYMENT_LOCATION=YES CONFIGURATION_BUILD_DIR="${result_path}" clean build

#查询编译APP是否成功
echo ${appDir}

if [ ! -e "${appDir}" ]; then
  showErrorNoti
  put_error "--> ERROR-错误501：编译工程失败,请认真检查工程配置."
  exit 500
else
	put_prompt "\n==>(0x03)  √  NICE WORK. 工程编译完成.\n"
fi


put_prompt "\n==>(0x04)-->🕹🕹🕹开始导出IPA包，耗时操作,请稍等...
----------------------------------------------------"

IPA_APP_DIR="${ShellPath}/${APP_DisplayName}_${APP_Version}_${CU_DATA}"
mkdir "${IPA_APP_DIR}"

IPA_PATH="${IPA_APP_DIR}/${APP_DisplayName}_v${APP_Version}_build${APP_BVersion}.ipa"
APP_PATH="${IPA_APP_DIR}/${APP_DisplayName}_${APP_Version}.app"
SYM_PATH="${APP_PATH}.dSYM"

#复制编译好的APP到 目标文件夹里，注：编译出来的目录，有可能是软连接.


#xcrun 开始打包
# 需要多个不同渠道打包版本.

#xcode8.3 不能用了 PackageApplication
#cp -r "${appDir}" "${APP_PATH}"
#/usr/bin/xcrun -sdk iphoneos PackageApplication -v "${APP_PATH}"  -o "${IPA_PATH}"
#######
cd "${IPA_APP_DIR}"
mkdir "Payload"
cp -r "${appDir}" "Payload"
zip -r "${IPA_PATH}" "Payload"
#######

#查询打包是否成功
if [ ! -f "${IPA_PATH}" ]; then
  showErrorNoti
  put_error "----------------------------------------------------
	-->(0x04) ERROR-错误501：找不到签名生成的IPA包, SO? 打包APP失败."
	exit 1
else
  osascript -e 'display notification "IPA打包成功！" with title "😍😍😍"'
  put_prompt "\n==>(0x04)  √  NICE WORK. IPA打包成功.\n"
fi

#拷贝过来.app.dSYM到输出目录
mv "${dsymDir}" "${SYM_PATH}"
rm -rf "${result_path}"

######################
date_end=`date +%s`
times=$[$date_end-$date_start]
######################

put_prompt "\n😍🥰😘😗😙😚😋😛😝😜🤪
-->Nice Worker! -->打包成功!  GET √ "

put_warning "----------------------------------------------------
|*   安装包--->  ${IPA_APP_DIR}
|*   耗时: ${times} s
|*   完成: `date`
----------------------------------------------------"

#记录当前日志
recordAppLog "${APP_DisplayName}" "${APP_Version}" "${APP_BVersion}"

open "${IPA_APP_DIR}"

######################
#上传到蒲公英,  传参如果为　1，则进行上传操作. 其它值忽略.
if [ "$1" = "1" ] ;then

  put_prompt "\n==>(0x05)-->正中上传到蒲公英,请稍等... "
  pgyerUKey="***********"  #这里替换蒲公英ukey
  pgyerApiKey="4edfcca58d221e970781756b16c99762" # 这里替换蒲公英apiKey
  RESULT=$(curl -F "file=@${IPA_PATH}" -F "_api_key=$pgyerApiKey"  -F "buildInstallType=2" -F "buildPassword=1234" https://www.pgyer.com/apiv2/app/upload)

  #获取下载地址:
  pgyDowloadSkey=$(echo ${RESULT} | awk -F 'buildShortcutUrl":"' '{print $2}' | awk -F '","' '{print $1}' | head -1)

  if [ -n ${pgyDowloadSkey} ] ; then
  put_prompt "\n\t
   ---🍏🍎🍐🍊🍋🍌🍉🍇🍓🍈🍒🍑🥭🍍🥥---
   ==>(0x05) 完成上传操作,下载地址:[👉 https://www.pgyer.com/${pgyDowloadSkey}  密码:1234👈]
   -----------------MORE INFO-----------------------------\n ${RESULT} \n "
  fi

fi
######################

exit 0
