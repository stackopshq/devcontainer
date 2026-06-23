#!/usr/bin/env bash
set -euo pipefail

USER_NAME=devops
USER_UID=1000
USER_GID=1000
USER_HOME=/home/${USER_NAME}

# ---------------------------------------------------------------------------
# Versions (renovate-managed) — kept in sync with .tasks.d/install/Taskfile.yml
# ---------------------------------------------------------------------------
# renovate: datasource=github-tags depName=go-task/task
TASK_VERSION=v3.49.1
# renovate: datasource=node depName=node
NODE_MAJOR=22
# renovate: datasource=github-releases depName=fluxcd/flux2
FLUX_VERSION=2.7.2
# renovate: datasource=github-tags depName=helm/helm
HELM_VERSION=v4.1.3
# renovate: datasource=github-tags depName=kubernetes/kubernetes
KUBECTL_VERSION=v1.35.3
# renovate: datasource=github-releases depName=kubernetes-sigs/kustomize
KUSTOMIZE_VERSION=v5.8.0
# renovate: datasource=github-releases depName=opentofu/opentofu
OPENTOFU_VERSION=v1.11.5
# renovate: datasource=github-releases depName=hashicorp/terraform
TERRAFORM_VERSION=v1.15.6
# renovate: datasource=github-releases depName=terraform-docs/terraform-docs
TFDOCS_VERSION=v0.21.0
# renovate: datasource=github-releases depName=hashicorp/vault
VAULT_VERSION=v1.21.4
# renovate: datasource=github-releases depName=astral-sh/uv
UV_VERSION=0.11.3
# renovate: datasource=python-version depName=python
PYTHON_VERSION=3.13.9
# Ansible tooling — mirrors the `ansible` dependency group in pyproject.toml
# renovate: datasource=pypi depName=ansible-core
ANSIBLE_CORE_VERSION=2.20.7
# renovate: datasource=pypi depName=ansible-lint
ANSIBLE_LINT_VERSION=26.4.0
# renovate: datasource=pypi depName=molecule
MOLECULE_VERSION=26.4.0

log() { echo -e "\n=== $* ==="; }

# Keep installs lean: no docs/man, no weak (recommended) dependencies.
DNF_OPTS="--setopt=install_weak_deps=False --setopt=tsflags=nodocs"

install_system_deps() {
  log "Installing base system dependencies"
  dnf update -y -q $DNF_OPTS
  dnf install -y $DNF_OPTS dnf-plugins-core
  dnf config-manager --enable crb
  dnf install -y $DNF_OPTS \
    ca-certificates \
    sudo \
    curl \
    gnupg2 \
    bind-utils \
    net-tools \
    unzip \
    tar \
    xz \
    git \
    libffi-devel \
    openssl-devel \
    cairo-devel \
    gcc \
    vim-minimal \
    jq \
    bash-completion \
    python3 \
    python3-pip
}

install_python_libs() {
  log "Pre-installing common Python libraries (system python3)"
  # Pre-seeded so consumer CI jobs don't pip-install them on every run.
  # --break-system-packages: Rocky 10 marks the env externally-managed (PEP 668).
  python3 -m pip install --break-system-packages --no-cache-dir \
    pyyaml requests urllib3
}

install_nodejs() {
  log "Installing Node.js ${NODE_MAJOR}"
  curl --silent --fail -Lo /tmp/nodesource_setup.sh \
    "https://rpm.nodesource.com/setup_${NODE_MAJOR}.x"
  bash /tmp/nodesource_setup.sh
  dnf install -y $DNF_OPTS nodejs
  rm -f /tmp/nodesource_setup.sh
  node --version
}

install_task() {
  log "Installing Task ${TASK_VERSION}"
  curl --silent --fail -Lo /tmp/task.tar.gz \
    "https://github.com/go-task/task/releases/download/${TASK_VERSION}/task_linux_amd64.tar.gz"
  mkdir -p /tmp/task
  tar -zxf /tmp/task.tar.gz -C /tmp/task
  install -m 0755 /tmp/task/task /usr/local/bin/task
  rm -rf /tmp/task.tar.gz /tmp/task
  task --version
}

install_flux() {
  log "Installing Flux ${FLUX_VERSION}"
  curl -sSfL -o /tmp/flux.tar.gz \
    "https://github.com/fluxcd/flux2/releases/download/v${FLUX_VERSION}/flux_${FLUX_VERSION}_linux_amd64.tar.gz"
  tar -zxf /tmp/flux.tar.gz -C /tmp
  install -m 0755 /tmp/flux /usr/local/bin/flux
  rm -f /tmp/flux.tar.gz /tmp/flux
  flux --version
}

install_helm() {
  log "Installing Helm ${HELM_VERSION}"
  curl -sSfL -o /tmp/helm.tar.gz \
    "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz"
  tar -zxf /tmp/helm.tar.gz -C /tmp
  install -m 0755 /tmp/linux-amd64/helm /usr/local/bin/helm
  rm -rf /tmp/helm.tar.gz /tmp/linux-amd64
  helm version --short
}

install_kubectl() {
  log "Installing kubectl ${KUBECTL_VERSION}"
  curl -sSfL -o /tmp/kubectl \
    "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
  install -m 0755 /tmp/kubectl /usr/local/bin/kubectl
  rm -f /tmp/kubectl
  kubectl version --client
}

install_kustomize() {
  log "Installing Kustomize ${KUSTOMIZE_VERSION}"
  curl -sSfL -o /tmp/kustomize.tar.gz \
    "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz"
  tar -xzf /tmp/kustomize.tar.gz -C /tmp
  install -m 0755 /tmp/kustomize /usr/local/bin/kustomize
  rm -f /tmp/kustomize.tar.gz /tmp/kustomize
  kustomize version
}

install_opentofu() {
  log "Installing OpenTofu ${OPENTOFU_VERSION}"
  local stripped="${OPENTOFU_VERSION#v}"
  curl -sSfL -o /tmp/install-opentofu.sh https://get.opentofu.org/install-opentofu.sh
  chmod +x /tmp/install-opentofu.sh
  /tmp/install-opentofu.sh --install-method standalone --opentofu-version "${stripped}"
  rm -rf /tmp/install-opentofu.sh /tmp/tmp.*
  tofu --version
}

install_terraform() {
  log "Installing Terraform ${TERRAFORM_VERSION}"
  local stripped="${TERRAFORM_VERSION#v}"
  curl -sSfL -o /tmp/terraform.zip \
    "https://releases.hashicorp.com/terraform/${stripped}/terraform_${stripped}_linux_amd64.zip"
  unzip -q /tmp/terraform.zip -d /tmp/terraform
  install -m 0755 /tmp/terraform/terraform /usr/local/bin/terraform
  rm -rf /tmp/terraform.zip /tmp/terraform
  terraform version
}

install_tfdocs() {
  log "Installing terraform-docs ${TFDOCS_VERSION}"
  curl -sSfL -o /tmp/tfdocs.tar.gz \
    "https://github.com/terraform-docs/terraform-docs/releases/download/${TFDOCS_VERSION}/terraform-docs-${TFDOCS_VERSION}-linux-amd64.tar.gz"
  mkdir -p /tmp/tfdocs
  tar -xzf /tmp/tfdocs.tar.gz -C /tmp/tfdocs
  install -m 0755 /tmp/tfdocs/terraform-docs /usr/local/bin/terraform-docs
  rm -rf /tmp/tfdocs.tar.gz /tmp/tfdocs
  terraform-docs --version
}

install_vault() {
  log "Installing Vault ${VAULT_VERSION}"
  local stripped="${VAULT_VERSION#v}"
  curl -sSfL -o /tmp/vault.zip \
    "https://releases.hashicorp.com/vault/${stripped}/vault_${stripped}_linux_amd64.zip"
  unzip -q /tmp/vault.zip -d /tmp/vault
  install -m 0755 /tmp/vault/vault /usr/local/bin/vault
  rm -rf /tmp/vault.zip /tmp/vault
  vault --version
}

install_uv_python() {
  log "Installing uv ${UV_VERSION} and Python ${PYTHON_VERSION}"
  # Install uv straight from the GitHub release archive (avoids astral.sh/install.sh)
  curl -sSfL -o /tmp/uv.tar.gz \
    "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-x86_64-unknown-linux-gnu.tar.gz"
  mkdir -p /tmp/uv
  tar -xzf /tmp/uv.tar.gz -C /tmp/uv --strip-components=1
  install -m 0755 /tmp/uv/uv /usr/local/bin/uv
  install -m 0755 /tmp/uv/uvx /usr/local/bin/uvx
  rm -rf /tmp/uv.tar.gz /tmp/uv
  uv --version
  # Provision the project Python interpreter system-wide
  export UV_PYTHON_INSTALL_DIR=/opt/uv/python
  uv python install "${PYTHON_VERSION}"
  uv python list
}

install_ansible() {
  log "Installing Ansible (ansible-core ${ANSIBLE_CORE_VERSION})"
  # Expose uv-managed tool binaries system-wide (mirrors pyproject `ansible` group)
  export UV_TOOL_BIN_DIR=/usr/local/bin
  export UV_TOOL_DIR=/opt/uv/tools
  export UV_PYTHON_INSTALL_DIR=/opt/uv/python
  # ansible-core provides ansible, ansible-playbook, ansible-galaxy, ansible-vault…
  # runtime helpers from the group are injected with --with
  uv tool install --python "${PYTHON_VERSION}" \
    "ansible-core==${ANSIBLE_CORE_VERSION}" \
    --with jmespath \
    --with mitogen \
    --with pymysql \
    --with docker
  uv tool install --python "${PYTHON_VERSION}" "ansible-lint==${ANSIBLE_LINT_VERSION}"
  uv tool install --python "${PYTHON_VERSION}" \
    "molecule==${MOLECULE_VERSION}" \
    --with molecule-plugins
  ansible --version
  ansible-lint --version
}

create_user() {
  log "Creating user ${USER_NAME} (${USER_UID}:${USER_GID})"
  if ! getent group "$USER_GID" >/dev/null; then
    groupadd -g "$USER_GID" "$USER_NAME"
  fi
  if ! getent passwd "$USER_NAME" >/dev/null; then
    useradd -m -u "$USER_UID" -g "$USER_GID" -s /bin/bash "$USER_NAME"
  fi
  mkdir -p "${USER_HOME}/.config" "${USER_HOME}/.kube"
  echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/"$USER_NAME"
  chmod 0440 /etc/sudoers.d/"$USER_NAME"
  chown -R "$USER_UID":"$USER_GID" "${USER_HOME}"
}

compress_binaries() {
  # renovate: datasource=github-releases depName=upx/upx
  local UPX_VERSION=5.0.2
  log "Compressing large binaries with UPX ${UPX_VERSION}"
  curl -sSfL -o /tmp/upx.tar.xz \
    "https://github.com/upx/upx/releases/download/v${UPX_VERSION}/upx-${UPX_VERSION}-amd64_linux.tar.xz"
  mkdir -p /tmp/upx
  tar -xJf /tmp/upx.tar.xz -C /tmp/upx --strip-components=1
  local upx=/tmp/upx/upx
  # Only the large standalone Go/Rust CLIs — not node/python interpreters.
  for path in \
    /usr/local/bin/vault \
    /usr/local/bin/terraform \
    /usr/local/bin/flux \
    /usr/local/bin/helm \
    /usr/local/bin/kubectl \
    /usr/local/bin/task \
    /usr/local/bin/kustomize \
    /usr/local/bin/terraform-docs \
    /usr/local/bin/uv \
    /opt/opentofu/tofu; do
    [ -f "$path" ] || continue
    echo "UPX: $path"
    # -1 (fast): near-identical ratio to --best on Go binaries, but seconds
    # instead of many minutes on the ~0.5 GB vault binary.
    "$upx" -1 --no-progress "$path" 2>/dev/null || echo "  (skipped: not compressible)"
  done
  rm -rf /tmp/upx /tmp/upx.tar.xz
}

slim_down() {
  # Build toolchain (gcc, *-devel) is intentionally kept so `uv sync` can
  # compile Python extensions inside the container. Only strip docs/locales.
  log "Removing documentation and locales"
  rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/info/* \
         /usr/share/locale/* /usr/share/i18n/locales/* 2>/dev/null || true
}

setup_completions() {
  log "Configuring shell completions"
  local dir=/etc/bash_completion.d
  mkdir -p "$dir"
  kubectl completion bash      > "$dir/kubectl"      2>/dev/null || true
  helm completion bash         > "$dir/helm"         2>/dev/null || true
  flux completion bash         > "$dir/flux"         2>/dev/null || true
  task --completion bash       > "$dir/task"         2>/dev/null || true
  vault -autocomplete-install 2>/dev/null || true
  terraform -install-autocomplete 2>/dev/null || true
}

main() {
  install_system_deps
  install_python_libs
  install_nodejs
  install_task
  install_flux
  install_helm
  install_kubectl
  install_kustomize
  install_opentofu
  install_terraform
  install_tfdocs
  install_vault
  install_uv_python
  install_ansible
  setup_completions
  create_user
  compress_binaries
  slim_down

  log "Cleaning up"
  dnf clean all
  rm -rf /var/cache/dnf /tmp/* /root/.cache

  log "All tools installed successfully"
}

main "$@"
