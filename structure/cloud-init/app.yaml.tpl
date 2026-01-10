#cloud-config
package_update: true
packages:
  - docker.io
  - docker-compose-plugin
  - git
  - curl
  - ca-certificates

write_files:
  - path: /usr/local/bin/bootstrap-app.sh
    permissions: "0755"
    content: |
      #!/usr/bin/env bash
      set -euxo pipefail

      systemctl enable --now docker

      APP_DIR="/opt/app"
      REPO_DIR="$APP_DIR/repo"
      mkdir -p "$APP_DIR"

      echo "[app] clone repo (branch=${git_branch})"
      if [ ! -d "$REPO_DIR/.git" ]; then
        git clone -b "${git_branch}" --single-branch "${git_repo}" "$REPO_DIR"
      else
        cd "$REPO_DIR"
        git fetch origin "${git_branch}"
        git checkout "${git_branch}"
        git pull --ff-only origin "${git_branch}"
      fi

      cd "$REPO_DIR"

      echo "[app] write .env"
      SECRET="$(openssl rand -hex 32 || echo "change_me")"
      cat > .env <<EOF
      PROJECT_NAME=${project_name}
      PROJECT_API_V1_STR=/api/v1
      PROJECT_SECRET_KEY=${project_secret_key}
      PROJECT_ACCESS_TOKEN_EXPIRE_MINUTES=720
      PROJECT_PINCODE_EXPIRE_MINUTES=15
      PROJECT_DEFAULT_QUERY_LIMIT=100
      PROJECT_SUPER_USER_EMAIL=${superuser_email}
      PROJECT_SUPER_USER_PASSWORD=${superuser_password}

      POSTGRES_SERVER=${db_ip}
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

      echo "[app] wait db tcp 5432"
      for i in $(seq 1 60); do
        if (echo > /dev/tcp/${db_ip}/5432) >/dev/null 2>&1; then
          echo "[app] db port is open"
          break
        fi
        sleep 2
      done

      echo "[app] run migrations"
      docker compose -f docker-compose.prod.yaml --profile migrations run --rm migrations

      echo "[app] start app"
      docker compose -f docker-compose.prod.yaml up -d --build

      echo "[app] local healthcheck"
      for i in $(seq 1 60); do
        if curl -fsS http://localhost:8000/api/v1/health >/dev/null 2>&1; then
          echo "[app] app healthy"
          exit 0
        fi
        sleep 2
      done

      echo "[app] ERROR: app not healthy"
      docker compose -f docker-compose.prod.yaml logs --tail=200 app || true
      exit 1

runcmd:
  - [bash, -lc, "/usr/local/bin/bootstrap-app.sh > /var/log/bootstrap-app.log 2>&1"]
