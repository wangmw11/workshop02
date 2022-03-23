all:
    hosts:
        ${code_server}:
            ansible_host: ${code_server_ip}
            ansible_user: root
            ansible_ssh_private_key_file: ${private_key}