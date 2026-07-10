package main

import (
	"net/url"
	"strings"
	"testing"
)

func TestDatabaseDSNPrefersDatabaseURL(t *testing.T) {
	t.Setenv("DATABASE_URL", "postgres://local:local@db:5432/auth_db?sslmode=disable")
	t.Setenv("DB_HOST", "ignored")

	dsn, err := databaseDSN()
	if err != nil {
		t.Fatalf("databaseDSN() returned an error: %v", err)
	}
	if dsn != "postgres://local:local@db:5432/auth_db?sslmode=disable" {
		t.Fatalf("databaseDSN() = %q", dsn)
	}
}

func TestDatabaseDSNBuildsSplitConfiguration(t *testing.T) {
	t.Setenv("DATABASE_URL", "")
	t.Setenv("DB_HOST", "2001:db8::1")
	t.Setenv("DB_PORT", "5433")
	t.Setenv("DB_NAME", "auth_db")
	t.Setenv("DB_USER", "auth_user")
	t.Setenv("DB_PASSWORD", "p@ss:/?# word")
	t.Setenv("DB_SSLMODE", "verify-full")

	dsn, err := databaseDSN()
	if err != nil {
		t.Fatalf("databaseDSN() returned an error: %v", err)
	}
	parsed, err := url.Parse(dsn)
	if err != nil {
		t.Fatalf("generated DSN is invalid: %v", err)
	}
	password, _ := parsed.User.Password()
	if parsed.Hostname() != "2001:db8::1" || parsed.Port() != "5433" || parsed.User.Username() != "auth_user" || password != "p@ss:/?# word" || parsed.Path != "/auth_db" || parsed.Query().Get("sslmode") != "verify-full" {
		t.Fatalf("generated DSN has unexpected components: %q", dsn)
	}
}

func TestDatabaseDSNRejectsMissingSplitSettingWithoutLeakingPassword(t *testing.T) {
	t.Setenv("DATABASE_URL", "")
	t.Setenv("DB_HOST", "postgres")
	t.Setenv("DB_NAME", "")
	t.Setenv("DB_USER", "auth_user")
	t.Setenv("DB_PASSWORD", "do-not-leak")

	_, err := databaseDSN()
	if err == nil || !strings.Contains(err.Error(), "DB_NAME") {
		t.Fatalf("expected a DB_NAME validation error, got %v", err)
	}
	if strings.Contains(err.Error(), "do-not-leak") {
		t.Fatal("validation error leaked the database password")
	}
}
