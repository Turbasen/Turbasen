# -*- mode: ruby -*-
# vi: set ft=ruby :

# Boostrap Script
$script = <<SCRIPT

# Update & Install
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | tee /etc/apt/sources.list.d/10gen.list
apt-get update
apt-get install -y build-essential python-setuptools git curl mongodb-10gen=2.4.5 tcl8.5
easy_install pip && pip install setuptools --no-use-wheel --upgrade && pip install dotcloud

# Make build directory
mkdir ~/build; cd ~/build

# Build and install Redis
echo "Installing Redis..."
wget http://redis.googlecode.com/files/redis-2.4.11.tar.gz
tar xzvf redis-2.4.11.tar.gz
cd ~/build/redis-2.4.11/
make
make install
make test

sed -i 's|daemonize no|daemonize yes|g' redis.conf
sed -i 's|# bind 127.0.0.1|bind 127.0.0.1|g' redis.conf
sed -i 's|dir ./|dir /var/lib/redis|g' redis.conf
mkdir /etc/redis
mv redis.conf /etc/redis/redis.conf

wget https://gist.githubusercontent.com/lsbardel/257298/raw/d48b84d89289df39eaddc53f1e9a918f776b3074/redis-server-for-init.d-startup
sed -i 's|DAEMON=/usr/bin/redis-server|DAEMON=/usr/local/bin/redis-server|g' redis-server-for-init.d-startup
mv redis-server-for-init.d-startup /etc/init.d/redis-server
chmod +x /etc/init.d/redis-server

useradd redis
mkdir -p /var/lib/redis
mkdir -p /var/log/redis
chown redis.redis /var/lib/redis
chown redis.redis /var/log/redis

update-rc.d redis-server defaults
service redis-server start

# Vagratnt Environment Varaibles
echo "Setting environment variables..."

echo "export NODE_ENV=development" >> /home/vagrant/.bashrc
echo "export PORT_WWW=8080" >> /home/vagrant/.bashrc
echo "export MONGO_URI=mongodb://localhost:27017/test" >> /home/vagrant/.bashrc
echo "export DOTCLOUD_CACHE_REDIS_HOST=localhost" >> /home/vagrant/.bashrc
echo "export DOTCLOUD_CACHE_REDIS_PORT=6379" >> /home/vagrant/.bashrc
echo "\n\n" >> /home/vagrant/.bashrc

# NodeJS via NVM
echo "Installing NVM..."
export HOME=/home/vagrant
curl https://raw.github.com/creationix/nvm/master/install.sh | sh
echo "source ~/.nvm/nvm.sh" >> /home/vagrant/.bashrc
source /home/vagrant/.nvm/nvm.sh
#nvm install 0.8
nvm install 0.10
#nvm install 0.11
chown -R vagrant:vagrant /home/vagrant/.nvm
export HOME=/home/root

# NPM package install
echo "Installing NPM packages..."
echo "PATH=$PATH:/vagrant/node_modules/.bin" >> /home/vagrant/.bashrc
PATH=$PATH:/vagrant/node_modules/.bin
cd /vagrant && rm -rf node_modules
[ -f package.json ] && npm install

echo "cd /vagrant" >> /home/vagrant/.bashrc

SCRIPT

Vagrant.configure("2") do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "precise32"

  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
  config.vm.box_url = "http://files.vagrantup.com/precise32.box"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  config.vm.network :forwarded_port, guest: 8080, host: 8080

  # The shell provisioner allows you to upload and execute a script as the root
  # user within the guest machine.
  config.vm.provision :shell, :inline => $script

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network :private_network, ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network :public_network

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "256", "--cpus", "2"]
  end

end
