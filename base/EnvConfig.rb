
# 1. Application setting

$app_name = "centos-devbox" # app's folder name
$app_url = "/demo" # the url path perfix for web server, exclude tailing slash, e.g. '/research-master/era'
$vm_hostname = $app_name + ".local"
$app_env_config_prefix = $app_name # used in "app" role to generate environment.ini

# 2. Environment configuration

$vm_ip_address = "192.168.123.123"
$vm_use_sync_folder = true
$vm_memory_size = 512
$vm_use_half_logical_cpus = false

# 3. Also checkout ansible/playbook.yml to comment out unnecessary setup if you want

# exposing configs
class EnvConfig
    APP_NAME = $app_name
    APP_URL = $app_url
    VM_HOSTNAME = $vm_hostname
    APP_ENV_CONFIG_PREFIX = $app_env_config_prefix
    VM_IP_ADDRESS = $vm_ip_address
    VM_USE_SYNC_FOLDER = $vm_use_sync_folder
    VM_MEMORY_SIZE = $vm_memory_size
    VM_USE_HALF_LOGICAL_CPUS = $vm_use_half_logical_cpus
end
