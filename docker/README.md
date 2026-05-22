# Docker

This folder documents containerization decisions shared across the services.

Requirement coverage:

- Create one optimized Dockerfile for each of the five services.
- Prefer multi-stage builds for Go services.
- Keep Python images small and production-oriented.
- Run containers with explicit ports and environment variables.
- Use the root `docker-compose.yml` to prove the complete local environment.
