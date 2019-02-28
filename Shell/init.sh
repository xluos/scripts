#!/bin/bash
# 判断是否有权限
if [ -w / ];then
  echo '============================'
  echo '开始。。。'
  echo '============================'
else
  echo '============================'
  echo '无权限，请用sudo提权或root用户'
  echo '============================'
  exit 1
fi
read -s -p "输入密码：" PSW
SECUSER=`who am i | awk '{print $1}'`
function sources () {
  # 清华源
  TUNA='# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
  deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic main restricted universe multiverse
  # deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic main restricted universe multiverse
  deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse
  # deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse
  deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-backports main restricted universe multiverse
  # deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-backports main restricted universe multiverse
  deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-security main restricted universe multiverse
  # deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-security main restricted universe multiverse

  # 预发布软件源，不建议启用
  # deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-proposed main restricted universe multiverse
  # deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ bionic-proposed main restricted universe multiverse'
  # 替换源
  sources='/etc/apt/sources.list'
  echo '============================'
  echo '更新源'
  echo '============================'
  # sources='./test.txt'

  if [ -f $sources ];then
    mv  $sources $sources.bak
  fi
  echo "$TUNA" > $sources
}
sources
# 添加Docker的官方GPG密钥
echo '============================'
echo '添加Docker的官方GPG密钥'
echo '============================'
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
# 添加YarnGPG密钥
echo '============================'
echo '添加YarnGPG密钥'
echo '============================'
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

# 更新apt包索引
echo '============================'
echo '更新索引'
echo '============================'
apt-get update # >> init.log

function installDocker () {
  # 卸载老版本docker相关
  echo '============================'
  echo '卸载老版本docker相关'
  echo '============================'

  apt-get -y remove docker docker-engine docker.io containerd runc # >> init.log

  # 安装包以允许apt通过HTTPS使用存储库：
  echo '============================'
  echo '安装包以允许apt通过HTTPS使用存储库'
  echo '============================'

  apt-get -y install \
      apt-transport-https \
      ca-certificates \
      curl \
      gnupg-agent \
      software-properties-common # >> init.log

  # 设置获取稳定版
  echo '============================'
  echo '设置获取稳定版'
  echo '============================'

  add-apt-repository \
    "deb [arch=amd64] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/ubuntu \
    $(lsb_release -cs) \
    stable"

  # 更新apt包索引
  echo '============================'
  echo '更新索引'
  echo '============================'
  apt-get update # >> init.log

  # 安装 Docker CE
  echo '============================'
  echo '安装 Docker CE'
  echo '============================'
  apt-get -y install docker-ce docker-ce-cli containerd.io # >> init.log

  # 创建docker组
  echo '============================'
  echo '创建docker组'
  echo '============================'
  groupadd docker

  # 将当前用户添加到该docker组
  echo '============================'
  echo '将当前用户添加到该docker组'
  echo '============================'
  usermod -aG docker $SECUSER

  # 设置docker加速器
  echo '============================'
  echo '设置docker加速器'
  echo '============================'

  mkdir -p /etc/docker
  tee /etc/docker/daemon.json <<-'EOF'
  {
    "registry-mirrors": ["https://nv6a3q2c.mirror.aliyuncs.com"]
  }
EOF
  systemctl daemon-reload
  systemctl restart docker
}
installDocker

# 安装node, yarn
echo '============================'
echo '安装node, yarn'
echo '============================'
apt-get -y install nodejs yarn # >> init.log

# 安装node全局模块
yarn config set registry https://registry.npm.taobao.org
yarn global add n nrm npm

# 安装zsh
echo '============================'
echo '安装，配置zsh'
echo '============================'
apt-get -y install zsh # >> init.log

echo '============================'
echo '下载oh-my-zsh'
echo '============================'
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sed 's/env zsh -l//')"

echo '============================'
echo '配置oh-my-zsh'
echo '============================'
if [ -f ~/.zshrc ];then
  sed -i 's/^\(ZSH_THEME=\)'\"'.*'\"'/\1'\"'ys'\"'/'  ~/.zshrc
else
  echo '============================'
  echo 'zshr不存在！'
  echo '============================'
fi

# 配置vim
echo '============================'
echo '配置vim'
echo '============================'

tee ~/.vimrc <<-'EOF'
set ts=4
set expandtab
set nu
set relativenumber
EOF
echo '============================'
echo '设置zsh为默认shell'
echo '============================'
echo $PSW | sudo -u $SECUSER chsh -s `which zsh`
sudo -u $SECUSER zsh -l
