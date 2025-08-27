{ pkgs, system, ... }:
{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    port = 5433;
    authentication = pkgs.lib.mkOverride 10 ''
      #type database  DBuser  auth-method
      local all       all     trust
      host    b_connect_test_db    b_connect_test_user    127.0.0.1/32    scram-sha-256
      host    b_connect_test_db    b_connect_test_user    ::1/128         scram-sha-256
    '';
  };

  system.activationScripts.postgresInit = {
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      # wait up to 30s for Postgres to be ready
      for i in $(seq 1 30); do
        if sudo -u postgres psql -p 5433 -c '\q' &>/dev/null; then
          break
        fi
        sleep 1
      done

      # create the role if it doesn't exist
      if ! sudo -u postgres psql -p 5433 \
           -tAc "SELECT 1 FROM pg_roles WHERE rolname='b_connect_test_user'" \
           | grep -q 1; then
        sudo -u postgres psql -p 5433 \
          -c "CREATE ROLE b_connect_test_user WITH LOGIN PASSWORD '123456';"
      fi

      # create the database if it doesn't exist
      if ! sudo -u postgres psql -p 5433 \
           -lqt \
         | cut -d '|' -f1 \
         | grep -qw b_connect_test_db; then
        sudo -u postgres psql -p 5433 \
          -c "CREATE DATABASE b_connect_test_db OWNER b_connect_test_user;"
      fi
    '';
  };
}
