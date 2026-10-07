# Odoo 18.0 desde código fuente (mismos pasos que la guía SGE), empaquetado para Railway
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

# Paso 1-2: sistema + dependencias (sin servidor PostgreSQL: lo da Railway)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git ca-certificates gosu postgresql-client \
    build-essential python3-dev python3-venv python3-pip \
    libpq-dev libxml2-dev libxslt1-dev libldap2-dev libsasl2-dev \
    libjpeg-dev zlib1g-dev libssl-dev libffi-dev \
 && rm -rf /var/lib/apt/lists/*

# Paso 4: usuario de servicio (el de Ubuntu 24.04 con UID 1000 se elimina antes)
RUN userdel -r ubuntu 2>/dev/null || true \
 && useradd --system --create-home --home-dir /opt/odoo --user-group --shell /usr/sbin/nologin odoo

# Paso 5: código de Odoo (rama 18.0, descarga superficial)
RUN git clone https://github.com/odoo/odoo.git --depth 1 --branch 18.0 /opt/odoo/odoo

# Paso 6: venv + dependencias
RUN python3 -m venv /opt/odoo/venv \
 && /opt/odoo/venv/bin/pip install --no-cache-dir --upgrade pip wheel \
 && /opt/odoo/venv/bin/pip install --no-cache-dir -r /opt/odoo/odoo/requirements.txt

RUN mkdir -p /etc/odoo /var/lib/odoo && chown -R odoo:odoo /opt/odoo /etc/odoo /var/lib/odoo

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
