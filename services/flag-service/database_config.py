import os


def build_database_config(environ=None):
    """Return psycopg2 pool arguments without embedding a secret in a URL."""
    env = os.environ if environ is None else environ

    database_url = env.get("DATABASE_URL")
    if database_url:
        return {"dsn": database_url}

    required = ("DB_HOST", "DB_NAME", "DB_USER", "DB_PASSWORD")
    missing = [name for name in required if not env.get(name)]
    if missing:
        raise ValueError(
            f"{', '.join(missing)} deve(m) ser definida(s) quando DATABASE_URL não for usada"
        )

    try:
        port = int(env.get("DB_PORT", "5432"))
    except ValueError as error:
        raise ValueError("DB_PORT deve ser um número inteiro") from error

    return {
        "host": env["DB_HOST"],
        "port": port,
        "dbname": env["DB_NAME"],
        "user": env["DB_USER"],
        "password": env["DB_PASSWORD"],
        "sslmode": env.get("DB_SSLMODE", "require"),
    }
