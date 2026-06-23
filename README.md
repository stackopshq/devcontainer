# Infrastructure DevContainer

Image de développement pour l'Infrastructure as Code (IaC) du monorepo `infrastructure`.
Construite sur **Rocky Linux 10 (UBI)** et publiée sur
`ghcr.io/stackopshq/infrastructure/devcontainer:latest`.

## 🧰 Outils installés

Les versions sont alignées sur celles de `.tasks.d/install/Taskfile.yml` et du
groupe `ansible` de `pyproject.toml` du repo `infrastructure`.

| Catégorie     | Outil                       | Version    |
| ------------- | --------------------------- | ---------- |
| Task runner   | Task                        | v3.49.1    |
| Runtime       | Node.js                     | 22         |
| Python        | uv + Python                 | 0.11.3 / 3.13.9 |
| Kubernetes    | kubectl                     | v1.35.3    |
| Kubernetes    | Helm                        | v4.1.3     |
| Kubernetes    | Kustomize                   | v5.8.0     |
| GitOps        | Flux                        | 2.7.2      |
| IaC           | OpenTofu                    | v1.11.5    |
| IaC           | Terraform                   | v1.15.6    |
| IaC           | terraform-docs              | v0.21.0    |
| Secrets       | Vault (OpenBao-compatible)  | v1.21.4    |
| Ansible       | ansible-core                | 2.20.7     |
| Ansible       | ansible-lint                | 26.4.0     |
| Ansible       | molecule (+ plugins)        | 26.4.0     |

Outils système : `git`, `curl`, `jq`, `gnupg2`, `unzip`/`tar`/`xz`, `gcc`,
`libffi`/`openssl`/`cairo-devel`, `vim`, `bind-utils`, `net-tools`,
`bash-completion`.

## 👤 Utilisateur

- **Nom** : `devops` — **UID/GID** : `1000/1000`
- **Sudo** : sans mot de passe

## 📁 Structure

```
.
├── Containerfile       # Définition de l'image
├── init.sh             # Script d'installation des outils
├── devcontainer.json   # Configuration VS Code Dev Containers
└── README.md
```

## 🔨 Build local

```bash
podman build -t ghcr.io/stackopshq/infrastructure/devcontainer:latest -f Containerfile .
```

## 🚀 CI/CD (GitLab)

`.gitlab-ci.yml` construit l'image avec **Buildah** et la pousse dans la
**Container Registry** du projet (`$CI_REGISTRY_IMAGE`).

Déclencheurs :

- Push sur la branche par défaut **si** `Containerfile` ou `init.sh` changent.
- Tag git → image taggée avec le tag (release versionnée).
- Déclenchement manuel depuis l'UI GitLab (rebuild forcé).

Tags publiés : `:latest`, `:<short-sha>`, et `:<git-tag>` sur les tags git.

## ➕ Ajouter un outil

1. Ajouter une fonction `install_*()` dans `init.sh` (avec un commentaire
   `# renovate:` pour épingler la version).
2. Appeler la fonction depuis `main()`.
3. Reconstruire l'image.
