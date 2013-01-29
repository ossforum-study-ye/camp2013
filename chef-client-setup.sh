#!/bin/sh
##### Chef Clientの設定(CentOS 5.8用) #####
# date : 2013/1/29
# author : Team 3-1
###########################################

# 必要に応じて変更すること

## chef-clientのhostname 
HOSTNAME=client20
## chef-serverのIPアドレス
CHEF_SERVER_IP=157.1.150.14

# Configure hostname

hostname $HOSTNAME

# Install Ruby

yum -y install wget
wget -O /etc/yum.repos.d/aegisco.repo http://rpm.aegisco.com/aegisco/el5/aegisco.repo
yum -y install ruby ruby-devel ruby-ri ruby-rdoc ruby-shadow gcc gcc-c++ automake autoconf make curl dmidecode

# Install RubyGems from Source

cd /tmp
curl -O http://production.cf.rubygems.org/rubygems/rubygems-1.8.10.tgz
tar zxf rubygems-1.8.10.tgz
cd rubygems-1.8.10
sudo ruby setup.rb --no-format-executable

# Install Chef Gem

sudo gem install chef --no-ri --no-rdoc

# CHEF-2906バグ対応
# remove old version Ruby and install new version

yum remove -y ruby ruby-devel ruby-libs 
yum install -y ruby-1.8.7.299-7 ruby-devel-1.8.7.299-7 ruby-libs-1.8.7.299-7

# Chef Serverから鍵ファイルをコピーする

mkdir /root/.chef/
scp ${CHEF_SERVER_IP}:/tmp/ossforum.pem ~/.chef/ossforum.pem

# knifeの設定(対話型)

## 対話型のコマンド実行のため、expectをインストールする
yum install -y expect

expect -c " 
set timeout 5
spawn knife configure -u ossforum -s http://$CHEF_SERVER_IP:4000 --validation-client-name chef-validator --validation-key /etc/chef/validation.pem
expect \"knife.rb]\" ; send \"\n\"
expect \"blank):\" ; send \"\n\"
interact
"

# Create client.rb

sudo mkdir -p /etc/chef
cat <<[EOF] > /etc/chef/client.rb
log_level          :info
log_location       STDOUT
ssl_verify_mode    :verify_none
validation_client_name "chef-validator"
validation_key         "/etc/chef/validation.pem"
client_key               "/etc/chef/client.pem"
chef_server_url    "http://${CHEF_SERVER_IP}:4000";
[EOF]

# 公開鍵のコピー

scp ${CHEF_SERVER_IP}:/etc/chef/validation.pem /etc/chef/validation.pem

# ノードの登録

chef-client
