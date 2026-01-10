#cloud-config
package_update: true
packages:
  - git
  - curl
  - ca-certificates
  - jq
  - netcat-openbsd

write_files:
  - path: /usr/local/bin/bootstrap-app.sh
    permissions: "0755"
    content: |
      #!/usr/bin/env bash
      set -euxo pipefail
      exec > >(tee -a /var/log/bootstrap-app.log) 2>&1

      SSH_USER="${ssh_user}"
      APP_DIR="/opt/app"
      REPO_DIR="/opt/app/repo"

      echo "[app] install docker (official)"
      if ! command -v docker >/dev/null 2>&1; then
        curl -fsSL https://get.docker.com | sh
      fi

      echo "[app] enable docker"
      systemctl enable --now docker

      echo "[app] allow docker without sudo for ${ssh_user} (next login)"
      usermod -aG docker "${ssh_user}" || true

      echo "[app] clone repo"
      mkdir -p "$APP_DIR"
      if [ ! -d "$REPO_DIR/.git" ]; then
        git clone -b ${git_branch} --single-branch ${git_repo} "$REPO_DIR"
      else
        git -C "$REPO_DIR" fetch --all
        git -C "$REPO_DIR" checkout ${git_branch}
        git -C "$REPO_DIR" pull
      fi

      cd "$REPO_DIR"

      echo "[app] write .env"
      cat > "$REPO_DIR/.env" <<EOF
      PROJECT_NAME=${project}
      PROJECT_API_V1_STR=/api/v1
      PROJECT_SECRET_KEY=${project_secret}
      PROJECT_ACCESS_TOKEN_EXPIRE_MINUTES=720
      PROJECT_PINCODE_EXPIRE_MINUTES=60
      PROJECT_SUPER_USER_EMAIL=${superuser_email}
      PROJECT_SUPER_USER_PASSWORD=${superuser_password}

      POSTGRES_SERVER=${db_host}
      POSTGRES_PORT=5432
      POSTGRES_USER=${db_user}
      POSTGRES_PASSWORD=${db_pass}
      POSTGRES_DATABASE=${db_name}

      AWS_ACCESS_KEY_ID=${s3_access_key_id}
      AWS_SECRET_ACCESS_KEY=${s3_secret_access_key}
      AWS_ENDPOINT_URL=https://storage.yandexcloud.net
      AWS_REGION=ru-central1
      AWS_STORAGE_BUCKET_NAME=${bucket_name}
      EOF

      echo "[app] wait DB tcp 5432 (${db_host}:5432)"
      for i in $(seq 1 120); do
        if nc -vz "${db_host}" 5432 >/dev/null 2>&1; then
          echo "[app] DB port is open"
          break
        fi
        sleep 2
      done

      echo "[app] run migrations (retry)"
      for attempt in $(seq 1 10); do
        if DOCKER_BUILDKIT=1 COMPOSE_DOCKER_CLI_BUILD=1 docker compose -f docker-compose.prod.yaml --profile migrations run --rm migrations; then
          echo "[app] migrations OK"
          break
        fi
        echo "[app] migrations failed, retry in 10s (attempt=$attempt)"
        sleep 10
      done

      echo "[app] start app"
      DOCKER_BUILDKIT=1 COMPOSE_DOCKER_CLI_BUILD=1 docker compose -f docker-compose.prod.yaml up -d app

      echo "[app] local healthcheck"
      for i in $(seq 1 60); do
        if curl -fsS http://localhost:8000/api/v1/health >/dev/null 2>&1; then
          echo "[app] healthy"
          exit 0
        fi
        sleep 2
      done

      echo "[app] ERROR: app not healthy"
      docker ps -a || true
      docker logs --tail=200 virtualization_app || true
      exit 1

runcmd:
  - [bash, -lc, "/usr/local/bin/bootstrap-app.sh"]

