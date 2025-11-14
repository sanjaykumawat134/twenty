#!/bin/sh
set -e

setup_and_migrate_db() {
    if [ "${DISABLE_DB_MIGRATIONS}" = "true" ]; then
        echo "Database setup and migrations are disabled, skipping..."
        return
    fi

    echo "Running database setup and migrations..."

    echo "=================================================="
    echo "🟡 Running database setup and migrations..."
    echo "=================================================="
    echo "PG_DATABASE_USER:       ${PG_DATABASE_USER}"
    echo "PG_DATABASE_PASSWORD:   ${PG_DATABASE_PASSWORD}"
    echo "PG_DATABASE_HOST:       ${PG_DATABASE_HOST}"
    echo "PG_DATABASE_PORT:       ${PG_DATABASE_PORT}"
    echo "PG_DATABASE_URL:        ${PG_DATABASE_URL}"
    echo "REDIS_URL:              ${REDIS_URL}"
    echo "--------------------------------------------------"

    # Run setup and migration scripts
    has_schema=$(psql -tAc "SELECT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'core')" ${PG_DATABASE_URL})
    if [ "$has_schema" = "f" ]; then
        echo "Database appears to be empty, running migrations."
        NODE_OPTIONS="--max-old-space-size=1500" tsx ./scripts/setup-db.ts
        yarn database:migrate:prod
    fi

    yarn command:prod upgrade
    echo "Successfully migrated DB!"
}
# setup_and_migrate_db() {
#     if [ "${DISABLE_DB_MIGRATIONS}" = "true" ]; then
#         echo "Database setup and migrations are disabled, skipping..."
#         return
#     fi

#     echo "=================================================="
#     echo "🟡 Running database setup and migrations..."
#     echo "=================================================="
#     echo "PG_DATABASE_USER:       ${PG_DATABASE_USER}"
#     echo "PG_DATABASE_PASSWORD:   ${PG_DATABASE_PASSWORD}"
#     echo "PG_DATABASE_HOST:       ${PG_DATABASE_HOST}"
#     echo "PG_DATABASE_PORT:       ${PG_DATABASE_PORT}"
#     echo "PG_DATABASE_URL:        ${PG_DATABASE_URL}"
#     echo "REDIS_URL:              ${REDIS_URL}"
#     echo "--------------------------------------------------"

#     # Run setup and migration scripts
#     echo "🔍 Checking if 'core' schema exists..."
#     has_schema=$(psql -tAc "SELECT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'core')" ${PG_DATABASE_URL} 2>&1)

#     echo "psql result: ${has_schema}"

#     if echo "$has_schema" | grep -q "error"; then
#         echo "❌ Failed to connect to PostgreSQL. Please check connection details above."
#         exit 1
#     fi

#     if [ "$has_schema" = "f" ]; then
#         echo "🧱 Database appears to be empty, running migrations..."
#         NODE_OPTIONS="--max-old-space-size=1500" tsx ./scripts/setup-db.ts
#         yarn database:migrate:prod
#     fi

#     echo "⬆️ Running yarn command:prod upgrade"
#     yarn command:prod upgrade

#     echo "✅ Successfully migrated DB!"
# }

register_background_jobs() {
    if [ "${DISABLE_CRON_JOBS_REGISTRATION}" = "true" ]; then
        echo "Cron job registration is disabled, skipping..."
        return
    fi

    echo "Registering background sync jobs..."
    if yarn command:prod cron:register:all; then
        echo "Successfully registered all background sync jobs!"
    else
        echo "Warning: Failed to register background jobs, but continuing startup..."
    fi
}

setup_and_migrate_db
register_background_jobs

# Continue with the original Docker command
exec "$@"
