# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

begin
	configuration = YAML.load_file('config.yaml')
rescue Errno::ENOENT
	abort "No config.yaml found."
end

Vagrant.configure("2") do |config|
	config.vm.box = "ubuntu_12.04"
	config.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/precise/current/precise-server-cloudimg-amd64-vagrant-disk1.box"

	config.vm.provision :shell, :path => 'manifests/init.sh'

	configuration.each do |site_config|
		site_name = site_config[0]
		site_configuration = site_config[1]

		config.vm.define site_name do |selamp|
			selamp.vm.hostname = site_name
			# Create a forwarded port mapping which allows access to a specific port
			# within the machine from a port on the host machine. In the example below,
			# accessing "localhost:8080" will access port 80 on the guest machine.
			# config.vm.network :forwarded_port, guest: 80, host: 8080

			# Create a private network, which allows host-only access to the machine
			# using a specific IP.
			selamp.vm.network :private_network, ip: site_configuration['ip']

			# Create a public network, which generally matched to bridged network.
			# Bridged networks make the machine appear as another physical device on
			# your network.
			# config.vm.network :public_network

			# Share an additional folder to the guest VM. The first argument is
			# the path on the host to the actual folder. The second argument is
			# the path on the guest to mount the folder. And the optional third
			# argument is a set of non-required options.
			# config.vm.synced_folder "../data", "/vagrant_data"
			selamp.vm.synced_folder site_configuration['path'], "/var/www/website", id: "website"

			# Provider-specific configuration so you can fine-tune various
			# backing providers for Vagrant. These expose provider-specific options.
			# Example for VirtualBox:
			#
			# config.vm.provider :virtualbox do |vb|
			#   # Don't boot with headless mode
			#   vb.gui = true
			#
			#   # Use VBoxManage to customize the VM. For example to change memory:
			#   vb.customize ["modifyvm", :id, "--memory", "1024"]
			# end
			#
			# View the documentation for the provider you're using for more
			# information on available options.
			#
			#  config.vm.provider :virtualbox do |vb|
			#    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
			#    vb.customize ["modifyvm", :id, "--memory", 1024]
			#    vb.customize ["modifyvm", :id, "--cpus", 2]
			#    vb.customize ["modifyvm", :id, "--name", "selamp"]
			#  end

			selamp.vm.provider :virtualbox do |vb|
				vb.customize ["modifyvm", :id, "--memory", 1024]
				vb.customize ["modifyvm", :id, "--cpus", 2]
			end

			# provisioning
			selamp.vm.provision :puppet do |puppet|
				puppet.manifests_path = "manifests"
				puppet.module_path = "modules"
				puppet.options = ['--verbose']
				puppet.manifest_file  = "selamp.pp"
				puppet.facter = {
					"website" => site_configuration['website']['name'],
					"vhost" => site_configuration['website']['vhost']
				}
			end
		end
	end
end
