#!/usr/bin/env python3
"""Render the OCI Kustomize overlay using non-secret Terraform outputs."""

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys


REPO_ROOT = Path(__file__).resolve().parent.parent
TERRAFORM_DIR = REPO_ROOT / "infra" / "oci"
OVERLAY_DIR = REPO_ROOT / "k8s" / "overlays" / "oci"
DEFAULT_OUTPUT = REPO_ROOT / "dist" / "k8s" / "oci.yaml"
PLACEHOLDER = re.compile(r"__[A-Z0-9_]+__")


def run(command):
    result = subprocess.run(
        command,
        cwd=REPO_ROOT,
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout


def terraform_outputs():
    raw = run(["terraform", f"-chdir={TERRAFORM_DIR}", "output", "-json"])
    document = json.loads(raw)
    return {name: entry["value"] for name, entry in document.items()}


def required(mapping, key):
    value = mapping[key]
    if value is None or value == "":
        raise ValueError(f"Terraform output {key} is empty")
    return str(value)


def replacements(outputs, image_tag):
    context = outputs["deployment_context"]
    databases = outputs["postgresql_systems"]
    repositories = outputs["ocir_repositories"]
    vault = outputs["vault"]
    names = vault["secret_names"]

    values = {
        "__IMAGE_TAG__": image_tag,
        "__OCI_REGION__": required(context, "region"),
        "__OCI_COMPARTMENT_OCID__": required(context, "compartment_id"),
        "__OCI_AUTH_DB_HOST__": required(databases["auth-service"], "private_ip"),
        "__OCI_FLAG_DB_HOST__": required(databases["flag-service"], "private_ip"),
        "__OCI_TARGETING_DB_HOST__": required(
            databases["targeting-service"], "private_ip"
        ),
        "__OCI_REDIS_URL__": required(outputs["redis"], "tls_url"),
        "__OCI_QUEUE_OCID__": required(outputs["evaluation_queue"], "id"),
        "__OCI_QUEUE_MESSAGES_ENDPOINT__": required(
            outputs["evaluation_queue"], "messages_endpoint"
        ),
        "__OCI_NOSQL_TABLE_OCID__": required(outputs["analytics_table"], "id"),
        "__OCI_VAULT_ID__": required(vault, "id"),
        "__OCI_AUTH_ADMIN_PASSWORD_SECRET_NAME__": required(
            names["postgres_admin_passwords"], "auth-service"
        ),
        "__OCI_FLAG_ADMIN_PASSWORD_SECRET_NAME__": required(
            names["postgres_admin_passwords"], "flag-service"
        ),
        "__OCI_TARGETING_ADMIN_PASSWORD_SECRET_NAME__": required(
            names["postgres_admin_passwords"], "targeting-service"
        ),
        "__OCI_AUTH_APP_PASSWORD_SECRET_NAME__": required(
            names["postgres_app_passwords"], "auth-service"
        ),
        "__OCI_FLAG_APP_PASSWORD_SECRET_NAME__": required(
            names["postgres_app_passwords"], "flag-service"
        ),
        "__OCI_TARGETING_APP_PASSWORD_SECRET_NAME__": required(
            names["postgres_app_passwords"], "targeting-service"
        ),
        "__OCI_AUTH_MASTER_KEY_SECRET_NAME__": required(names, "auth_master_key"),
        "__OCI_INTERNAL_API_KEY_SECRET_NAME__": required(names, "internal_api_key"),
    }

    for service in (
        "auth-service",
        "flag-service",
        "targeting-service",
        "evaluation-service",
        "analytics-service",
    ):
        token = f"__OCIR_{service.upper().replace('-', '_')}_IMAGE__"
        values[token] = required(repositories[service], "image_path")

    return values


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--image-tag",
        default=os.environ.get("IMAGE_TAG"),
        help="Immutable image tag already pushed to OCIR (or set IMAGE_TAG).",
    )
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    return parser.parse_args()


def main():
    args = parse_args()
    if not args.image_tag:
        raise ValueError("--image-tag or IMAGE_TAG is required")
    if not re.fullmatch(r"[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}", args.image_tag):
        raise ValueError("image tag is not a valid OCI/Docker tag")

    rendered = run(["kubectl", "kustomize", str(OVERLAY_DIR)])
    for token, value in replacements(terraform_outputs(), args.image_tag).items():
        rendered = rendered.replace(token, value)

    remaining = sorted(set(PLACEHOLDER.findall(rendered)))
    if remaining:
        raise ValueError("unresolved manifest placeholders: " + ", ".join(remaining))

    output = args.output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(rendered, encoding="utf-8")
    output.chmod(0o600)
    print(f"Rendered {output.relative_to(REPO_ROOT)} (no secret values included)")


if __name__ == "__main__":
    try:
        main()
    except (KeyError, ValueError, subprocess.CalledProcessError) as error:
        print(f"error: {error}", file=sys.stderr)
        sys.exit(1)
