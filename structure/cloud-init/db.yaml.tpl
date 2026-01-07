#cloud-config
package_update: true
packages:
  - ca-certificates
  - curl
  - git

runcmd:
  - [ bash, -lc, "curl -fsSL https://get.docker.com | sh" ]
  - [ bash, -lc, "usermod -aG docker ${ssh_user}" ]
  - [ bash, -lc, "mkdir -p /mnt/pgdata" ]
  - [ bash, -lc, "DISK=$(lsblk -ndo NAME,TYPE | awk '$2==\"disk\"{print $1}' | tail -n 1); DEV=/dev/$DISK; (blkid $DEV || mkfs.ext4 -F $DEV); mount $DEV /mnt/pgdata; grep -q /mnt/pgdata /etc/fstab || echo \"$DEV /mnt/pgdata ext4 defaults,nofail 0 2\" >> /etc/fstab" ]
  - [ bash, -lc, "mkdir -p /opt/app && chown -R ${ssh_user}:${ssh_user} /opt/app" ]
  - [ bash, -lc, "su - ${ssh_user} -c 'git clone -b ${git_branch} ${git_repo} /opt/app || (cd /opt/app && git fetch && git checkout ${git_branch} && git pull)'" ]
  - [ bash, -lc, "cd /opt/app && docker compose -f docker-compose.db.yml up -d" ]
