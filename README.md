# Odoo 18 en Railway (instalación desde fuente)

Mismo procedimiento que la guía *Desplegar Odoo en Linux* (SGE), empaquetado en un Dockerfile.

| Guía SGE | Aquí |
|---|---|
| Paso 1-2 apt + dependencias | `Dockerfile` (apt-get) |
| Paso 3 PostgreSQL + rol `odoo` | Servicio Postgres de Railway; `entrypoint.sh` crea el rol `odoo` y la BD `odoo` (Odoo no admite el usuario `postgres`) |
| Paso 4 usuario `odoo` | `Dockerfile` (adduser) + `gosu` |
| Paso 5 git clone 18.0 | `Dockerfile` |
| Paso 6 venv + requirements | `Dockerfile` |
| Paso 7 `odoo.conf` | `entrypoint.sh` (con variables de entorno) |
| Paso 8 init + arranque | `entrypoint.sh` |
| Paso 11 systemd / Paso 12 Nginx+HTTPS | Lo hace Railway (reinicio automático y dominio HTTPS) |

## Despliegue
1. Sube este repo a GitHub.
2. En Railway: **New Project → Deploy PostgreSQL**.
3. **New → GitHub Repo →** este repo (Railway detecta el Dockerfile).
4. En el servicio de Odoo, pestaña **Variables**:
   - `PGHOST` = `${{Postgres.PGHOST}}`
   - `PGPORT` = `${{Postgres.PGPORT}}`
   - `PGUSER` = `${{Postgres.PGUSER}}`
   - `PGPASSWORD` = `${{Postgres.PGPASSWORD}}`
   - `PGDATABASE` = `${{Postgres.PGDATABASE}}`
   - `ADMIN_PASSWD` = una contraseña maestra segura
   (si tu servicio de BD no se llama `Postgres`, cambia ese nombre)
5. Pestaña **Volumes**: añade un volumen montado en `/var/lib/odoo` (adjuntos y sesiones).
6. **Settings → Networking → Generate Domain**.
7. La primera vez tarda unos minutos en inicializar la BD. Luego entra en el dominio: usuario `admin`, contraseña `admin` (cámbiala ya).

## Comprobaciones
- Logs del servicio: `Modules loaded.` / `Registry loaded`
- `curl -I https://TU-DOMINIO/web/login` → `HTTP/2 200`
