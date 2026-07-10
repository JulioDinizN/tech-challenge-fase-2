package main

import (
	"fmt"
	"net"
	"net/url"
	"os"
)

// databaseDSN preserves DATABASE_URL for local development and also supports
// split settings so Kubernetes can inject a Vault-backed password without
// assembling a connection string containing credentials.
func databaseDSN() (string, error) {
	if databaseURL := os.Getenv("DATABASE_URL"); databaseURL != "" {
		return databaseURL, nil
	}

	required := map[string]string{
		"DB_HOST":     os.Getenv("DB_HOST"),
		"DB_NAME":     os.Getenv("DB_NAME"),
		"DB_USER":     os.Getenv("DB_USER"),
		"DB_PASSWORD": os.Getenv("DB_PASSWORD"),
	}
	for name, value := range required {
		if value == "" {
			return "", fmt.Errorf("%s deve ser definida quando DATABASE_URL não for usada", name)
		}
	}

	port := os.Getenv("DB_PORT")
	if port == "" {
		port = "5432"
	}
	sslMode := os.Getenv("DB_SSLMODE")
	if sslMode == "" {
		sslMode = "require"
	}

	dsn := &url.URL{
		Scheme: "postgresql",
		User:   url.UserPassword(required["DB_USER"], required["DB_PASSWORD"]),
		Host:   net.JoinHostPort(required["DB_HOST"], port),
		Path:   required["DB_NAME"],
	}
	query := dsn.Query()
	query.Set("sslmode", sslMode)
	dsn.RawQuery = query.Encode()

	return dsn.String(), nil
}
