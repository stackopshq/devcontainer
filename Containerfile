# syntax=docker/dockerfile:1.23
FROM docker.io/rockylinux/rockylinux:10-ubi
LABEL org.opencontainers.image.title="Infrastructure DevContainer"
LABEL org.opencontainers.image.description="Development container for infrastructure as code (Ansible, OpenTofu, Kubernetes, Vault)"
LABEL org.opencontainers.image.version="2.0"

COPY init.sh /.devcontainer/init.sh
RUN chmod +x /.devcontainer/init.sh \
    && /.devcontainer/init.sh \
    && rm -rf /.devcontainer

# Image runs as root by default (needed by GitLab CI jobs that write across the
# shared build tree). VS Code uses the unprivileged `devops` user via the
# "containerUser" setting in devcontainer.json.
WORKDIR /workspaces/infrastructure

CMD ["sleep", "infinity"]
