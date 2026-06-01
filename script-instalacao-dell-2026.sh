#!/usr/bin/env bash
#
# script-instalacao-dell-2026.sh
# -----------------------------------------------------------------------------
# Configuracao do ambiente Ubuntu (WSL2) para a disciplina de
# Sistemas Operacionais - IDP 2026/1.
#
# Instala as ferramentas de baixo nivel utilizadas na disciplina:
#   - Compiladores e build tools (gcc, g++, make, build-essential)
#   - GDB (depurador) + GEF (GDB Enhanced Features)
#   - NASM, Valgrind e utilitarios diversos
#
# Uso (dentro do Ubuntu/WSL):
#   chmod +x script-instalacao-dell-2026.sh
#   ./script-instalacao-dell-2026.sh
# -----------------------------------------------------------------------------

set -uo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()   { echo -e "${GREEN}[ OK ]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()  { echo -e "${RED}[ERRO]${NC} $*" >&2; }

if [[ "${EUID}" -eq 0 ]]; then
  err "Nao execute como root. Use seu usuario normal (o sudo sera pedido quando necessario)."
  exit 1
fi

# -----------------------------------------------------------------------------
# 1. Correcao de DNS (conforme roteiro) - opcional, util quando a Internet falha
# -----------------------------------------------------------------------------
fix_dns() {
  if ! ping -c1 -W2 8.8.8.8 >/dev/null 2>&1; then
    warn "Sem conectividade. Ajustando DNS para 8.8.8.8 em /etc/resolv.conf (conforme roteiro)."
    echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf >/dev/null
  fi
}

# -----------------------------------------------------------------------------
# 2. Atualizacao do sistema
# -----------------------------------------------------------------------------
log "Atualizando lista de pacotes (apt update)..."
fix_dns
sudo apt update
sudo apt upgrade -y

# -----------------------------------------------------------------------------
# 3. Ferramentas da disciplina
# -----------------------------------------------------------------------------
log "Instalando ferramentas de desenvolvimento e depuracao..."
sudo apt install -y \
  build-essential gcc g++ make cmake \
  gdb \
  nasm \
  valgrind \
  git curl wget unzip \
  python3 python3-pip \
  nano vim \
  man-db manpages-dev

ok "Ferramentas base instaladas."

# -----------------------------------------------------------------------------
# 4. GEF (GDB Enhanced Features)
#    Instala o GEF em /opt/.gdbinit-gef.py e deixa a linha de carregamento
#    COMENTADA no ~/.gdbinit (igual ao roteiro: o aluno ativa quando quiser).
# -----------------------------------------------------------------------------
install_gef() {
  log "Instalando GEF (GDB Enhanced Features)..."
  if [[ ! -f /opt/.gdbinit-gef.py ]]; then
    sudo curl -fsSL https://raw.githubusercontent.com/hugsy/gef/main/gef.py \
      -o /opt/.gdbinit-gef.py \
      || { warn "Falha ao baixar o GEF. Verifique a Internet e tente novamente."; return; }
  fi

  # Garante a linha (comentada) no ~/.gdbinit, conforme o roteiro
  touch "$HOME/.gdbinit"
  if ! grep -q '/opt/.gdbinit-gef.py' "$HOME/.gdbinit"; then
    echo "# source /opt/.gdbinit-gef.py" >> "$HOME/.gdbinit"
  fi
  ok "GEF instalado em /opt/.gdbinit-gef.py."
  warn "Para ATIVAR o GEF, edite ~/.gdbinit e descomente a linha:"
  echo "      source /opt/.gdbinit-gef.py"
}
install_gef

# -----------------------------------------------------------------------------
# 5. Teste rapido do GDB
# -----------------------------------------------------------------------------
log "Verificando instalacao..."
gcc --version | head -n1
gdb --version | head -n1

ok "Ambiente Ubuntu pronto para a disciplina de Sistemas Operacionais (IDP 2026/1)."
