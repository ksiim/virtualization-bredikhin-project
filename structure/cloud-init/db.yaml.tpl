#cloud-config
package_update: true
packages:
  - docker.io
  - docker-compose-plugin
  - curl
  - ca-certificates
  - jq

write_files:
  - path: /usr/local/bin/bootstrap-db.sh
    permissions: "0755"
    content: |
      #!/usr/bin/env bash
      set -euxo pipefail

      echo "[db] enable docker"
      systemctl enable --now docker

      echo "[db] detect secondary disk (not root)"
      ROOT_SRC="$(findmnt -n -o SOURCE /)"
      ROOT_DISK="/dev/$(lsblk -no PKNAME "$ROOT_SRC")"
      DISK="$(lsblk -dpno NAME,TYPE | awk '$2=="disk"{print $1}' | grep -v "$ROOT_DISK" | head -n 1 || true)"

      if [ -z "${DISK:-}" ]; then
        echo "[db] ERROR: secondary disk not found. Check Terraform secondary_disk attachment."
        exit 1
      fi

      echo "[db] using disk: $DISK"

      echo "[db] format disk if needed"
      if ! blkid "$DISK" >/dev/null 2>&1; then
        mkfs.ext4 -F "$DISK"
      fi

      echo "[db] mount disk to /mnt/pgdata"
      mkdir -p /mnt/pgdata
      UUID="$(blkid -s UUID -o value "$DISK")"
      grep -q "$UUID" /etc/fstab || echo "UUID=$UUID /mnt/pgdata ext4 defaults,nofail 0 2" >> /etc/fstab
      mount -a

      echo "[db] ensure permissions for postgres container (uid 999)"
      chown -R 999:999 /mnt/pgdata
      chmod 700 /mnt/pgdata

      echo "[db] run postgres container"
      docker rm -f postgres || true
      docker run -d \
        --name postgres \
        --restart unless-stopped \
        -e POSTGRES_DB='${db_name}' \
        -e POSTGRES_USER='${db_user}' \
        -e POSTGRES_PASSWORD='${db_pass}' \
        -p 5432:5432 \
        -v /mnt/pgdata:/var/lib/postgresql/data \
        postgres:15

      echo "[db] check readiness"
      for i in $(seq 1 60); do
        if docker exec postgres pg_isready -U '${db_user}' -d '${db_name}' >/dev/null 2>&1; then
          echo "[db] postgres is ready"
          exit 0
        fi
        sleep 2
      done

      echo "[db] ERROR: postgres not ready"
      docker logs --tail=200 postgres || true
      exit 1

runcmd:
  - [bash, -lc, "/usr/local/bin/bootstrap-db.sh > /var/log/bootstrap-db.log 2>&1"]
