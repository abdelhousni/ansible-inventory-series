# The image behind db2: Debian 12, whose PostgreSQL is 15. Python for
# Ansible's modules (python3-apt for package_facts), and the PostgreSQL 15 client package.
FROM docker.io/library/debian:bookworm-slim@sha256:3783cc01769c7b2b1b83a5c5ad96c815348e28ed7da68e2e3687004faa906251
RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 python3-apt postgresql-client-15 \
    && rm -rf /var/lib/apt/lists/*
CMD ["sleep", "infinity"]
