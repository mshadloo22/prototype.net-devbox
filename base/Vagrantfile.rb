# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'optparse'

vpn_mode = false
vpn_mode_web_port = 4567

OptionParser.new { |opts|
    opts.banner = "Usage: #{File.basename($0)} -u -i -s filename"

    opts.on('--vpn-mode', 'VPN connection mode. VM IP and port will be different.') do
        vpn_mode = true
    end

    opts.on('--vpn-mode-web-port=PORT', 'Port forwarding from PORT to guest 80 port.') do |port|
        vpn_mode_web_port = port.to_i
    end

    # accepting default vagrant opts in this wrapper script, so Vagrant is able to receive these opts
    vagrant_default_opts = ['no-color', 'provider=PROVIDER', 'provision']

    vagrant_default_opts.each do |opt|
        opts.on("--#{opt}", 'Vagrant default option') do
        end
    end
}.parse!

def which(cmd)
    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each { |ext|
            exe = File.join(path, "#{cmd}#{ext}")
            return exe if File.executable? exe
        }
    end
    return nil
end

vagrant_command = ARGV[0] || ''

require_network_setup = ['up', 'reload'].include? vagrant_command

if require_network_setup && vpn_mode
    puts "\nVPN mode is enablerd, port forwarding from #{vpn_mode_web_port} to guest 80 port\n\n"
end

if require_network_setup
    puts 'Gathering required plugins...'

    required_plugins = []

    if Vagrant::Util::Platform.windows?
        puts 'Plugin vagrant-vbguest is required for Windows Platform.'
        required_plugins << 'vagrant-vbguest'
    end

    if vpn_mode
        puts 'Plugin vagrant-sshfs is required for VPN connection mode.'
        required_plugins << 'vagrant-sshfs'
    end

    plugins_to_install = required_plugins.select { |plugin| not Vagrant.has_plugin? plugin }

    if not plugins_to_install.empty?
        puts "Installing missing plugins: #{plugins_to_install.join(' ')}"

        if system "vagrant plugin install #{plugins_to_install.join(' ')}"
            exec "vagrant #{ARGV.join(' ')}"
        else
            abort 'Installation of one or more plugins has failed. Aborting.'
        end
    end

    puts
end

is_base = Object.const_defined?('EnvConfig')

# include base config if EnvConfig hasn't been defined yet
require_relative 'EnvConfig' if !is_base

vagrant_root = is_base ? File.dirname(__FILE__) + '/../' : File.dirname(__FILE__) + '/'
base_ansible_path = is_base ? 'base/ansible/' : 'ansible/'

Vagrant.configure('2') do |config|

    ####################################
    # Application-based configurations #
    ####################################

    app_name = EnvConfig::APP_NAME
    app_url = EnvConfig::APP_URL
    vm_hostname = EnvConfig::VM_HOSTNAME
    app_env_config_prefix = EnvConfig::APP_ENV_CONFIG_PREFIX
    app_dirs = (EnvConfig.const_defined?(:APP_DIRS) and not EnvConfig::APP_DIRS.nil?) ? EnvConfig::APP_DIRS : ['admin', 'api', 'data', 'frontend']

    ###################################
    # Optional configuration          #
    ###################################

    vm_ip_address = EnvConfig::VM_IP_ADDRESS
    vm_use_sync_folder = EnvConfig::VM_USE_SYNC_FOLDER
    vm_memory_size = EnvConfig::VM_MEMORY_SIZE
    vm_use_more_logical_cpus = EnvConfig::VM_USE_MORE_LOGICAL_CPUS

    # VPN mode configuration

    vm_ip_address = '127.0.0.1' if vpn_mode # ip address to be used when VPN mode is enabled

    # Dynamic configuration

    vm_cpus = 1
    if vm_use_more_logical_cpus
        # gathering environment information
        host_cpus = 1
        # windows https://stackoverflow.com/a/33238716 ?
        # ?? https://stackoverflow.com/questions/22919076/find-number-of-cpus-and-cores-per-cpu-using-command-prompt
        # wmic cpu get NumberOfLogicalProcessors
        # wmic cpu get NumberOfCores
        #
        unless Vagrant::Util::Platform.windows?
            host_cpus = `awk "/^processor/ {++n} END {print n}" /proc/cpuinfo 2> /dev/null || sh -c 'sysctl hw.logicalcpu 2> /dev/null || echo ": 2"' | awk \'{print \$2}\' `.chomp.to_i
        end

        # vm_cpus = host_cpus / 2 if host_cpus > 1
        vm_cpus = 2 if host_cpus > 2
    end

    ###################################
    # Standard Vagrant configurations #
    ###################################

    config.vm.box = 'centos/7'

    # initialize other configurations variables
    post_up_message = ''

    # standard config steps
    config.vm.provider :virtualbox do |v|
        v.name = app_name
        v.memory = vm_memory_size
        v.cpus = vm_cpus

        v.customize [
            'modifyvm', :id,
            '--name', app_name,
            '--natdnsproxy1', 'off',
            '--natdnshostresolver1', 'off',
        ]
    end

    config.vm.hostname = vm_hostname
    # Use forwarded_port if in VPN connection mode. Default is private_network
    if vpn_mode
        config.vm.network :forwarded_port, guest: 80, host: vpn_mode_web_port if vpn_mode
    else
        config.vm.network :private_network, ip: vm_ip_address
    end
    config.ssh.forward_agent = true

    sync_method = 'nfs'
    if  Vagrant::Util::Platform.windows?
        sync_method = 'virtualbox'
    elsif vpn_mode
        sync_method = 'sshfs'
    end

    config.vm.synced_folder vagrant_root, '/vagrant', type: sync_method

    # If ansible is in your path it will provision from your HOST machine
    # If ansible is not found in the path it will be instaled in the VM and provisioned from there
    env_vars = {
        app: app_name,
        url: app_url,
        hostname: vm_hostname,
        ip_address: vm_ip_address,
        use_synced_folder: vm_use_sync_folder
    }

    # Make sure inventories directory present
    FileUtils.mkpath vagrant_root + 'ansible/inventories/'

    # Generate inventories file
    File.open(vagrant_root + 'ansible/inventories/dev', 'w') { |file| file.write("[#{app_name}]\n#{vm_ip_address}") }
    config.vm.provision :shell, path: base_ansible_path + 'init.sh', env: env_vars

    if vm_use_sync_folder

        for app_dir in app_dirs

            if (app_dir.kind_of?(Array))
                # old app may not have standard folder structure
                local_dir = app_dir[0]
                vm_dir = app_dir[1]
            else
                local_dir = app_dir
                vm_dir = (['admin', 'api', 'app', 'frontend'].include? app_dir) ? "#{app_dir}/current" : app_dir
            end

            sync_local_path = vagrant_root + "src/#{local_dir}/"
            sync_vm_path = "/data/web/#{app_name}/#{vm_dir}"

            unless Dir.exists? sync_local_path
                Dir.mkdir(sync_local_path, 0755)
            end

            config.vm.synced_folder sync_local_path, sync_vm_path, type: sync_method
        end
    end

    # set post up message if any
    if post_up_message.length != 0
        config.vm.post_up_message = post_up_message
    end

end

at_exit do
    if require_network_setup
        if vpn_mode
            puts "\nVPN mode is enabled. Web URL is http://localhost:#{vpn_mode_web_port}/\n\n"
        end
    end
end
