#!/bin/bash
set -e

# Variables que Railway inyecta desde el servicio Postgres (ver README)
: "${PGHOST:?Falta PGHOST}"; : "${PGUSER:?Falta PGUSER}"
: "${PGPASSWORD:?Falta PGPASSWORD}"; : "${PGDATABASE:?Falta PGDATABASE}"

# Paso 7: odoo.conf generado con las variables de entorno
cat > /etc/odoo/odoo.conf <<CONF
[options]
admin_passwd = ${ADMIN_PASSWD:-cambia_esta_clave}
db_host = ${PGHOST}
db_port = ${PGPORT:-5432}
db_user = ${PGUSER}
db_password = ${PGPASSWORD}
db_name = ${PGDATABASE}
dbfilter = ^${PGDATABASE}\$
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
INIT=$(PGPASSWORD="$PGPASSWORD" psql -h "$PGHOST" -p "${PGPORT:-5432}" -U "$PGUSER" -d "$PGDATABASE" -tAc "SELECT to_regclass('public.ir_module_module')" || true)
if [ -z "$INIT" ]; then
  echo ">> Base de datos vacía: inicializando módulo base..."
  gosu odoo $ODOO -i base --stop-after-init
fi

exec gosu odoo $ODOO
