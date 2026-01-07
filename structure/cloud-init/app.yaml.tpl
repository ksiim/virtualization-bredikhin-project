#cloud-config
package_update: true
packages:
  - ca-certificates
  - curl
  - git

runcmd:
  - [ bash, -lc, "curl -fsSL https://get.docker.com | sh" ]
  - [ bash, -lc, "usermod -aG docker ${ssh_user}" ]
  - [ bash, -lc, "mkdir -p /opt/app && chown -R ${ssh_user}:${ssh_user} /opt/app" ]
  - [ bash, -lc, "su - ${ssh_user} -c 'git clone -b ${git_branch} ${git_repo} /opt/app || (cd /opt/app && git fetch && git checkout ${git_branch} && git pull)'" ]
  - [ bash, -lc, "cat >/opt/app/.env <<'EOF'\nDATABASE_URL=postgresql+asyncpg://${db_user}:${db_pass}@${db_ip}:5432/${db_name}\nEOF" ]
  - [ bash, -lc, "cd /opt/app && docker compose -f docker-compose.prod.yaml up -d --build" ]
