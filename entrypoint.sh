#!/bin/bash
set -e

# Credenciales de administrador de Postgres (Railway las inyecta desde el servicio de BD)
: "${PGHOST:?Falta PGHOST}"; : "${PGUSER:?Falta PGUSER}"
: "${PGPASSWORD:?Falta PGPASSWORD}"; : "${PGDATABASE:?Falta PGDATABASE}"
PGPORT="${PGPORT:-5432}"

# Odoo NO arranca con el usuario 'postgres', así que usamos un rol propio (Paso 3 de la guía)
ODOO_DB_USER="odoo"
ODOO_DB_NAME="${ODOO_DB_NAME:-odoo}"
ODOO_DB_PASSWORD="${ODOO_DB_PASSWORD:-$PGPASSWORD}"

echo ">> Preparando rol y base de datos en PostgreSQL..."
psql -v ON_ERROR_STOP=1 -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" \
     -v pw="$ODOO_DB_PASSWORD" -v dbn="$ODOO_DB_NAME" -v dbu="$ODOO_DB_USER" <<'SQL'
SELECT format('CREATE ROLE %I LOGIN CREATEDB PASSWORD %L', :'dbu', :'pw')
  WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = :'dbu') \gexec
SELECT format('ALTER ROLE %I PASSWORD %L', :'dbu', :'pw') \gexec
SELECT format('CREATE DATABASE %I OWNER %I', :'dbn', :'dbu')
  WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = :'dbn') \gexec
SQL

# Paso 7: odoo.conf generado con las variables de entorno
cat > /etc/odoo/odoo.conf <<CONF
[options]
admin_passwd = ${ADMIN_PASSWD:-cambia_esta_clave}
db_host = ${PGHOST}
db_port = ${PGPORT}
db_user = ${ODOO_DB_USER}
db_password = ${ODOO_DB_PASSWORD}
db_name = ${ODOO_DB_NAME}
dbfilter = ^${ODOO_DB_NAME}\$
list_db = False
addons_path = /opt/odoo/odoo/addons
data_dir = /var/lib/odoo
http_interface = 0.0.0.0
http_port = ${PORT:-8069}
proxy_mode = True
without_demo = all
CONF
chown odoo:odoo /etc/odoo/odoo.conf
chown -R odoo:odoo /var/lib/odoo

ODOO="/opt/odoo/venv/bin/python /opt/odoo/odoo/odoo-bin -c /etc/odoo/odoo.conf"

# Paso 8: inicializar la BD solo la primera vez
INIT=$(PGPASSWORD="$ODOO_DB_PASSWORD" psql -h "$PGHOST" -p "$PGPORT" -U "$ODOO_DB_USER" -d "$ODOO_DB_NAME" -tAc "SELECT to_regclass('public.ir_module_module')" || true)
if [ -z "$INIT" ]; then
  echo ">> Base de datos vacía: inicializando módulo base (puede tardar varios minutos)..."
  gosu odoo $ODOO -i base --stop-after-init
fi

echo ">> Arrancando Odoo..."
exec gosu odoo $ODOO
