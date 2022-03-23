/*
data digitalocean_ssh_key mykey {
  name = "mykey"
}
*/

resource digitalocean_ssh_key mykey{
    name = "mykey"
    public_key= file("./mykey.pub")
}

// Image
resource docker_image dov-bear {
    name = "chukmunnlee/dov-bear:v2"
    keep_locally = true
}

// container
resource docker_container dov-bear-container {
    count = 3
    name = "dov-${count.index}"
    image = docker_image.dov-bear.latest
    ports {
        internal = 3000
        //external = 8080
    }
    env = [
        "INSTANCE_NAME=dov-${count.index}"
    ]
}

resource local_file nginx_conf {
    filename = "nginx.conf"
    content = templatefile("nginx.conf.tftpl", {
        docker_host_ip = var.docker_host_ip 
        container_ports = [ for p in docker_container.dov-bear-container[*].ports[*]: element(p, 0).external ]
    })
    file_permission = "0644"
} 

resource local_file root_at_ip {
    filename = "root@${digitalocean_droplet.nginx.ipv4_address}"
    content = ""
    file_permission = "0644"
}

resource digitalocean_droplet nginx {
  name   = "nginx"
  image = var.droplet_image
  region = var.droplet_region
  size = var.droplet_size
  //ssh_keys = [data.digitalocean_ssh_key.shawn_key.fingerprint]
  ssh_keys = [digitalocean_ssh_key.mykey.fingerprint]
  connection {
    type = "ssh"
    user = "root"
    private_key = file(var.private_key)
    host = self.ipv4_address
  }
  
  // Install nginx package
    provisioner remote-exec {
        inline = [
            "apt update",
            "apt install -y nginx"
        ]
    }

    // Copy config file over
    provisioner file {
        source = "./nginx.conf"
        destination = "/etc/nginx/nginx.conf"
    }

    // Restart nginx cause we have updated the configuration
    provisioner remote-exec {
        inline = [
            "systemctl restart nginx"
        ]
    }
}

output external-ports {
    //value = docker_container.dov-bear-container[*].ports[*].external
    value = join(",", [ for p in docker_container.dov-bear-container[*].ports[*]: element(p, 0).external ])
}

output nginx_ip {
    value = digitalocean_droplet.nginx.ipv4_address
}

/*
output key{
    value = data.digitalocean_ssh_key.mykey.id
}
*/