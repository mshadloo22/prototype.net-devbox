#!/usr/bin/env bash

if ! rpm -qa | grep -qw ansible; then
    # Update Repositories
    sudo yum -y update

    # Install Ansible
    sudo yum install -y ansible
fi

# Setup Ansible for Local Use and Run
cp /vagrant/ansible/inventories/dev /etc/ansible/hosts -f
chmod 666 /etc/ansible/hosts

# Add vagrant's insecure private key
export SSH_KEY_LINE=`cat /vagrant/base/ansible/files/authorized_keys | tr -d '\n'`
export SSH_KEY_FILE="/home/vagrant/.ssh/authorized_keys"
grep -q "$SSH_KEY_LINE" "$SSH_KEY_FILE" || echo "$SSH_KEY_LINE" >> "$SSH_KEY_FILE"

# Setup Ansible roles path. This parameter roles path will only be used/searched
# when Ansible cannot find reqested role in default roles/ directory
# https://docs.ansible.com/ansible/latest/reference_appendices/config.html#envvar-ANSIBLE_ROLES_PATH
export ANSIBLE_ROLES_PATH=/vagrant/ansible/roles

sudo -E ansible-playbook /vagrant/base/ansible/playbook.yml \
    -e app=$app -e url=$url -e hostname=$hostname -e ip_address=$ip_address \
    -e use_synced_folder=$use_synced_folder --connection=local