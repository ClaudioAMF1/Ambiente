#!/usr/bin/env bash
#
# setup-dev-completo.sh
# -----------------------------------------------------------------------------
# Script de instalacao de um ambiente de desenvolvimento completo para
# Ubuntu 24.04 (incluindo WSL2). Instala Python, Node.js, Docker e as
# linguagens e frameworks mais utilizados.
#
# Disciplina: Sistemas Operacionais - IDP 2026/1
#
# Uso:
#   chmod +x setup-dev-completo.sh
#   ./setup-dev-completo.sh                 # instala TUDO (perfil completo)
#   ./setup-dev-completo.sh base python node docker   # instala somente o que listar
#   ./setup-dev-completo.sh --help          # mostra a ajuda
#
# Modulos disponiveis:
#   base     -> utilitarios essenciais (git, curl, build-essential, etc.)
#   python   -> Python 3, pip, venv, pipx, poetry + frameworks (Django/Flask/FastAPI)
#   node     -> Node.js LTS (via nvm) + npm, yarn, pnpm + ferramentas (Vite, etc.)
#   docker   -> Docker Engine + Docker Compose plugin
#   java     -> OpenJDK 21 + Maven + Gradle
#   go       -> Linguagem Go (ultima versao estavel)
#   rust     -> Rust + Cargo (via rustup)
#   ruby     -> Ruby + Bundler + Rails
#   php      -> PHP + Composer
#   dotnet   -> .NET SDK
#   all      -> todos os modulos acima
# -----------------------------------------------------------------------------

set -uo pipefail

# ----------------------------- Cores e logging ------------------------------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

log()    { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()     { echo -e "${GREEN}[ OK ]${NC} $*"; }
warn()   { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()    { echo -e "${RED}[ERRO]${NC} $*" >&2; }
section(){ echo -e "\n${GREEN}========== $* ==========${NC}\n"; }

# ----------------------------- Verificacoes ---------------------------------
# Ajuda funciona em qualquer contexto (inclusive root), antes das demais checagens.
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
fi

if [[ "${EUID}" -eq 0 ]]; then
  err "Nao execute este script como root. Use seu usuario normal (o sudo sera pedido quando necessario)."
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  err "O comando 'sudo' nao foi encontrado. Instale-o antes de continuar."
  exit 1
fi

# Detecta se eh WSL (apenas informativo)
if grep -qi microsoft /proc/version 2>/dev/null; then
  log "Ambiente WSL detectado."
fi

command_exists() { command -v "$1" >/dev/null 2>&1; }

# ----------------------------- Modulo: base ---------------------------------
install_base() {
  section "BASE - utilitarios essenciais"
  sudo apt update
  sudo apt upgrade -y
  sudo apt install -y \
    build-essential gcc g++ make cmake gdb \
    git curl wget unzip zip tar \
    ca-certificates gnupg lsb-release software-properties-common \
    apt-transport-https \
    nano vim htop tree jq \
    pkg-config libssl-dev
  ok "Utilitarios base instalados."
}

# ----------------------------- Modulo: python -------------------------------
install_python() {
  section "PYTHON - linguagem e frameworks"
  sudo apt install -y python3 python3-pip python3-venv python3-dev pipx
  pipx ensurepath >/dev/null 2>&1 || true

  # Poetry (gerenciador de dependencias/projetos)
  if ! command_exists poetry; then
    pipx install poetry || warn "Falha ao instalar Poetry (siga manualmente se precisar)."
  fi

  # Frameworks mais usados em um ambiente isolado recomendado pelo pip.
  # Instalamos as ferramentas de linha de comando globalmente via pipx quando faz sentido.
  log "Instalando frameworks Python populares (Django, Flask, FastAPI) via pipx..."
  pipx install django   >/dev/null 2>&1 || warn "Django: instale em um venv do projeto se preferir."
  # Flask e FastAPI normalmente vao por projeto/venv; deixamos pip global como fallback.
  python3 -m pip install --user --upgrade pip flask fastapi uvicorn 2>/dev/null \
    || warn "Instalacao global de Flask/FastAPI pulada (use venv por projeto)."

  ok "Python e frameworks configurados. Dica: use 'python3 -m venv .venv' por projeto."
  python3 --version
}

# ----------------------------- Modulo: node ---------------------------------
install_node() {
  section "NODE.JS - runtime e gerenciadores de pacote"
  export NVM_DIR="$HOME/.nvm"
  if [[ ! -d "$NVM_DIR" ]]; then
    log "Instalando nvm (Node Version Manager)..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  fi
  # Carrega o nvm na sessao atual
  # shellcheck disable=SC1091
  [[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"

  if command_exists nvm; then
    log "Instalando Node.js LTS..."
    nvm install --lts
    nvm use --lts
    nvm alias default 'lts/*'

    log "Instalando gerenciadores e ferramentas (yarn, pnpm, vite)..."
    npm install -g npm@latest yarn pnpm vite create-vite >/dev/null 2>&1 \
      || warn "Falha em alguns pacotes globais npm."
    ok "Node.js configurado."
    node --version
    npm --version
  else
    err "nvm nao carregou. Abra um novo terminal e rode o script novamente para o modulo node."
  fi
}

# ----------------------------- Modulo: docker -------------------------------
install_docker() {
  section "DOCKER - engine e compose"
  if command_exists docker; then
    ok "Docker ja instalado: $(docker --version)"
    return
  fi
  # Repositorio oficial do Docker
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # Permite usar docker sem sudo (efetivo apos novo login)
  sudo usermod -aG docker "$USER"
  warn "Voce foi adicionado ao grupo 'docker'. Faca logout/login (ou abra novo terminal WSL) para usar docker sem sudo."
  ok "Docker instalado: $(docker --version 2>/dev/null || echo 'verifique apos relogar')"
}

# ----------------------------- Modulo: java ---------------------------------
install_java() {
  section "JAVA - OpenJDK + Maven + Gradle"
  sudo apt install -y openjdk-21-jdk maven gradle
  ok "Java configurado."
  java -version 2>&1 | head -n1
}

# ----------------------------- Modulo: go -----------------------------------
install_go() {
  section "GO - linguagem"
  if command_exists go; then
    ok "Go ja instalado: $(go version)"
    return
  fi
  GO_VERSION="1.22.4"
  ARCH=$(dpkg --print-architecture)
  [[ "$ARCH" == "amd64" ]] && GOARCH="amd64" || GOARCH="arm64"
  TARBALL="go${GO_VERSION}.linux-${GOARCH}.tar.gz"
  log "Baixando Go ${GO_VERSION}..."
  curl -fsSLo "/tmp/${TARBALL}" "https://go.dev/dl/${TARBALL}"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "/tmp/${TARBALL}"
  rm -f "/tmp/${TARBALL}"
  if ! grep -q '/usr/local/go/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH=$PATH:/usr/local/go/bin' >> "$HOME/.bashrc"
  fi
  export PATH=$PATH:/usr/local/go/bin
  ok "Go instalado: $(go version)"
}

# ----------------------------- Modulo: rust ---------------------------------
install_rust() {
  section "RUST - linguagem e Cargo"
  if command_exists rustc; then
    ok "Rust ja instalado: $(rustc --version)"
    return
  fi
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  # shellcheck disable=SC1091
  [[ -s "$HOME/.cargo/env" ]] && \. "$HOME/.cargo/env"
  ok "Rust instalado: $(rustc --version 2>/dev/null || echo 'reinicie o terminal')"
}

# ----------------------------- Modulo: ruby ---------------------------------
install_ruby() {
  section "RUBY - linguagem + Bundler + Rails"
  sudo apt install -y ruby-full
  sudo gem install bundler rails || warn "Falha ao instalar bundler/rails via gem."
  ok "Ruby configurado: $(ruby --version)"
}

# ----------------------------- Modulo: php ----------------------------------
install_php() {
  section "PHP - linguagem + Composer"
  sudo apt install -y php php-cli php-mbstring php-xml php-curl unzip
  if ! command_exists composer; then
    log "Instalando Composer..."
    curl -sS https://getcomposer.org/installer | php
    sudo mv composer.phar /usr/local/bin/composer
  fi
  ok "PHP configurado: $(php --version | head -n1)"
}

# ----------------------------- Modulo: dotnet -------------------------------
install_dotnet() {
  section ".NET - SDK"
  if command_exists dotnet; then
    ok ".NET ja instalado: $(dotnet --version)"
    return
  fi
  sudo apt install -y dotnet-sdk-8.0 || {
    warn "Pacote dotnet-sdk-8.0 nao encontrado no repositorio padrao; instalando via script oficial."
    curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh
    bash /tmp/dotnet-install.sh --channel 8.0
    rm -f /tmp/dotnet-install.sh
  }
  ok ".NET configurado: $(dotnet --version 2>/dev/null || echo 'reinicie o terminal')"
}

# ----------------------------- Ajuda ----------------------------------------
show_help() {
  sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//'
}

# ----------------------------- Resumo final ---------------------------------
summary() {
  section "RESUMO DA INSTALACAO"
  printf "%-12s %s\n" "Ferramenta" "Versao"
  printf "%-12s %s\n" "----------" "------"
  command_exists gcc     && printf "%-12s %s\n" "gcc"     "$(gcc --version | head -n1)"
  command_exists python3 && printf "%-12s %s\n" "python3" "$(python3 --version)"
  command_exists node    && printf "%-12s %s\n" "node"    "$(node --version)"
  command_exists docker  && printf "%-12s %s\n" "docker"  "$(docker --version)"
  command_exists java    && printf "%-12s %s\n" "java"    "$(java -version 2>&1 | head -n1)"
  command_exists go      && printf "%-12s %s\n" "go"      "$(go version)"
  command_exists rustc   && printf "%-12s %s\n" "rust"    "$(rustc --version)"
  command_exists ruby    && printf "%-12s %s\n" "ruby"    "$(ruby --version)"
  command_exists php     && printf "%-12s %s\n" "php"     "$(php --version | head -n1)"
  command_exists dotnet  && printf "%-12s %s\n" "dotnet"  "$(dotnet --version)"
  echo
  warn "Reabra o terminal (ou rode 'source ~/.bashrc') para carregar todas as variaveis de ambiente."
}

# ----------------------------- Main -----------------------------------------
main() {
  local modules=("$@")

  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    show_help
    exit 0
  fi

  # Sem argumentos OU 'all' => instala tudo
  if [[ $# -eq 0 || "${1:-}" == "all" ]]; then
    modules=(base python node docker java go rust ruby php dotnet)
  fi

  # base eh sempre necessario primeiro
  if [[ ! " ${modules[*]} " =~ " base " ]]; then
    modules=(base "${modules[@]}")
  fi

  log "Modulos selecionados: ${modules[*]}"

  for m in "${modules[@]}"; do
    case "$m" in
      base)   install_base   ;;
      python) install_python ;;
      node)   install_node   ;;
      docker) install_docker ;;
      java)   install_java   ;;
      go)     install_go     ;;
      rust)   install_rust   ;;
      ruby)   install_ruby   ;;
      php)    install_php    ;;
      dotnet) install_dotnet ;;
      all)    ;; # ja tratado acima
      *) warn "Modulo desconhecido: '$m' (ignorado)" ;;
    esac
  done

  summary
  ok "Concluido!"
}

main "$@"
