#!/usr/bin/env bash
#
# script-instalacao-cripto-2026-02.sh
# -----------------------------------------------------------------------------
# Configuracao do ambiente Ubuntu 24.04 (WSL2) para a disciplina de
# Criptografia e Seguranca - IDP 2026/2 (Prof. Jeremias Moreira Gomes).
#
# Ferramentas exigidas pelo roteiro:
#   gcc 13.3.0+      gdb 15.0.50+     gef (2025-10-04+)   python 3.12.3+
#   pwntools 4.15+   pycryptodome 3.21+   requests 2.31+
#   ROPGadget 7.6+   one_gadget 1.10+     Wireshark 4.2.2+
#   Burp Suite Community 2026.2.3+       IDA Free 9.2+ (instalacao manual)
#
# Uso (dentro do Ubuntu/WSL):
#   chmod +x script-instalacao-cripto-2026-02.sh
#   ./script-instalacao-cripto-2026-02.sh              # instala tudo
#   ./script-instalacao-cripto-2026-02.sh --check      # so verifica versoes
#   ./script-instalacao-cripto-2026-02.sh --help       # ajuda
# -----------------------------------------------------------------------------

set -uo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
log()     { echo -e "${BLUE}[INFO]${NC} $*"; }
ok()      { echo -e "${GREEN}[ OK ]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()     { echo -e "${RED}[ERRO]${NC} $*" >&2; }
section() { echo -e "\n${GREEN}========== $* ==========${NC}\n"; }

# Ambiente virtual dedicado da disciplina (Ubuntu 24.04 e "externally managed",
# PEP 668, entao nao da para instalar pacotes Python direto com pip no sistema).
VENV_DIR="$HOME/.venvs/cripto"
BIN_DIR="$HOME/.local/bin"

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  awk 'NR>1 { if ($0 !~ /^#/) exit; sub(/^# ?/, ""); print }' "$0"
  exit 0
fi

# -----------------------------------------------------------------------------
# Comparacao de versoes (usada na verificacao final)
# -----------------------------------------------------------------------------
# ver_ge <instalada> <minima> -> 0 se instalada >= minima
ver_ge() {
  [[ "$1" == "$2" ]] && return 0
  local menor
  menor="$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)"
  [[ "$menor" == "$2" ]]
}

FALHAS=0
check_version() {
  local nome="$1" minima="$2" atual="$3"
  if [[ -z "$atual" ]]; then
    err "$nome: NAO INSTALADO (roteiro exige $minima+)"
    FALHAS=$((FALHAS + 1))
  elif ver_ge "$atual" "$minima"; then
    ok "$nome $atual (>= $minima)"
  else
    warn "$nome $atual esta ABAIXO do minimo do roteiro ($minima+)"
    FALHAS=$((FALHAS + 1))
  fi
}

# Extrai o primeiro "numero.numero..." de uma string
ver_de() { grep -oE '[0-9]+(\.[0-9]+)+' <<<"${1:-}" | head -n1; }

venv_pkg_version() {
  [[ -x "$VENV_DIR/bin/python" ]] || return 0
  "$VENV_DIR/bin/python" - "$1" <<'PY' 2>/dev/null
import sys
from importlib.metadata import version, PackageNotFoundError
try:
    print(version(sys.argv[1]))
except PackageNotFoundError:
    pass
PY
}

# -----------------------------------------------------------------------------
# Verificacao final de versoes (roteiro Criptografia e Seguranca 2026/2)
# -----------------------------------------------------------------------------
verificar_ambiente() {
  section "Verificacao das versoes exigidas pelo roteiro"

  check_version "gcc"      "13.3.0"   "$(ver_de "$(gcc --version 2>/dev/null | head -n1)")"
  check_version "gdb"      "15.0.50"  "$(ver_de "$(gdb --version 2>/dev/null | head -n1)")"
  check_version "python3"  "3.12.3"   "$(ver_de "$(python3 --version 2>/dev/null)")"

  if [[ -f /opt/.gdbinit-gef.py ]]; then
    ok "gef instalado em /opt/.gdbinit-gef.py"
  else
    err "gef: NAO INSTALADO"
    FALHAS=$((FALHAS + 1))
  fi

  check_version "pwntools"     "4.15"   "$(venv_pkg_version pwntools)"
  check_version "pycryptodome" "3.21"   "$(venv_pkg_version pycryptodome)"
  check_version "requests"     "2.31"   "$(venv_pkg_version requests)"
  check_version "ROPGadget"    "7.6"    "$(venv_pkg_version ROPGadget)"
  check_version "one_gadget"   "1.10"   "$(ver_de "$(one_gadget --version 2>/dev/null)")"
  check_version "Wireshark"    "4.2.2"  "$(ver_de "$(tshark --version 2>/dev/null | head -n1)")"

  # Burp Suite e IDA Free: instalacao manual, apenas informamos o estado
  if command -v burpsuite >/dev/null 2>&1 || [[ -d "$HOME/BurpSuiteCommunity" ]]; then
    ok "Burp Suite Community aparenta estar instalado"
  else
    warn "Burp Suite Community: instalacao MANUAL (veja as instrucoes no final)"
  fi
  warn "IDA Free 9.2+: instalacao MANUAL pelo aluno (exige conta na Hex-Rays)"

  echo
  if [[ "$FALHAS" -eq 0 ]]; then
    ok "Todas as ferramentas automatizadas atendem aos minimos do roteiro."
  else
    warn "$FALHAS item(ns) precisam de atencao. Releia as mensagens acima."
  fi
}

if [[ "${1:-}" == "--check" ]]; then
  verificar_ambiente
  exit 0
fi

if [[ "${EUID}" -eq 0 ]]; then
  err "Nao execute como root. Use seu usuario normal (o sudo sera pedido quando necessario)."
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  err "O comando 'sudo' nao foi encontrado. Instale-o antes de continuar."
  exit 1
fi

# -----------------------------------------------------------------------------
# 1. Correcao de DNS (conforme roteiro) - util quando a Internet falha no WSL
# -----------------------------------------------------------------------------
section "1/8 - Conectividade e atualizacao do sistema"

if ! ping -c1 -W2 8.8.8.8 >/dev/null 2>&1; then
  warn "Sem conectividade. Ajustando DNS para 8.8.8.8 em /etc/resolv.conf (conforme roteiro)."
  echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf >/dev/null
fi

log "Atualizando lista de pacotes..."
sudo apt update
sudo apt upgrade -y

# -----------------------------------------------------------------------------
# 2. Toolchain de compilacao e depuracao
# -----------------------------------------------------------------------------
section "2/8 - Compiladores, depurador e utilitarios"

sudo apt install -y \
  build-essential gcc g++ make cmake \
  gdb gdbserver \
  nasm valgrind \
  binutils patchelf file xxd \
  git curl wget unzip \
  python3 python3-pip python3-venv python3-dev \
  ruby-full \
  nano vim \
  man-db manpages-dev

ok "Toolchain instalada."

# -----------------------------------------------------------------------------
# 3. GEF (GDB Enhanced Features)
# -----------------------------------------------------------------------------
section "3/8 - GEF (GDB Enhanced Features)"

if [[ ! -f /opt/.gdbinit-gef.py ]]; then
  log "Baixando o GEF..."
  sudo curl -fsSL https://raw.githubusercontent.com/hugsy/gef/main/gef.py \
    -o /opt/.gdbinit-gef.py \
    || warn "Falha ao baixar o GEF. Verifique a Internet e rode o script novamente."
fi

if [[ -f /opt/.gdbinit-gef.py ]]; then
  touch "$HOME/.gdbinit"
  if ! grep -q '/opt/.gdbinit-gef.py' "$HOME/.gdbinit"; then
    echo "# source /opt/.gdbinit-gef.py" >> "$HOME/.gdbinit"
  fi
  ok "GEF instalado em /opt/.gdbinit-gef.py."
  warn "Para ATIVAR o GEF, edite ~/.gdbinit e descomente a linha:"
  echo "        source /opt/.gdbinit-gef.py"
fi

# -----------------------------------------------------------------------------
# 4. Ambiente Python da disciplina (pwntools, pycryptodome, requests, ROPGadget)
# -----------------------------------------------------------------------------
section "4/8 - Ferramentas Python (venv dedicada)"

log "Criando/atualizando a venv em $VENV_DIR ..."
mkdir -p "$(dirname "$VENV_DIR")"
if [[ ! -x "$VENV_DIR/bin/python" ]]; then
  python3 -m venv "$VENV_DIR" || { err "Falha ao criar a venv."; exit 1; }
fi

"$VENV_DIR/bin/pip" install --upgrade pip setuptools wheel >/dev/null

log "Instalando pwntools, pycryptodome, requests e ROPGadget..."
"$VENV_DIR/bin/pip" install --upgrade \
  'pwntools>=4.15' \
  'pycryptodome>=3.21' \
  'requests>=2.31' \
  'ROPGadget>=7.6' \
  || warn "Alguma dependencia Python falhou. Rode o script novamente apos checar a Internet."

# Expoe os executaveis da venv no PATH do usuario, sem precisar ativar a venv
mkdir -p "$BIN_DIR"
for exe in pwn pwnstrip ROPgadget checksec; do
  if [[ -x "$VENV_DIR/bin/$exe" ]]; then
    ln -sf "$VENV_DIR/bin/$exe" "$BIN_DIR/$exe"
  fi
done

# Atalho para abrir um shell/python ja com as bibliotecas da disciplina
if ! grep -q 'alias cripto-python' "$HOME/.bashrc" 2>/dev/null; then
  {
    echo ""
    echo "# Ambiente da disciplina Criptografia e Seguranca (IDP 2026/2)"
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo "alias cripto-python='$VENV_DIR/bin/python'"
    echo "alias cripto-activate='source $VENV_DIR/bin/activate'"
  } >> "$HOME/.bashrc"
fi

ok "Ferramentas Python instaladas em $VENV_DIR."
log "Use 'cripto-python meu_script.py' ou 'cripto-activate' para ativar a venv."

# -----------------------------------------------------------------------------
# 5. one_gadget (gem Ruby)
# -----------------------------------------------------------------------------
section "5/8 - one_gadget"

if ! command -v one_gadget >/dev/null 2>&1; then
  log "Instalando one_gadget via gem..."
  sudo gem install one_gadget --no-document \
    || warn "Falha ao instalar o one_gadget. Tente manualmente: sudo gem install one_gadget"
else
  ok "one_gadget ja instalado."
fi

# -----------------------------------------------------------------------------
# 6. Wireshark / tshark
# -----------------------------------------------------------------------------
section "6/8 - Wireshark"

# Responde antecipadamente ao prompt do debconf: permite captura sem ser root.
echo "wireshark-common wireshark-common/install-setuid boolean true" \
  | sudo debconf-set-selections

sudo DEBIAN_FRONTEND=noninteractive apt install -y wireshark tshark \
  || warn "Falha ao instalar o Wireshark."

if getent group wireshark >/dev/null 2>&1; then
  if ! id -nG "$USER" | grep -qw wireshark; then
    sudo usermod -aG wireshark "$USER"
    warn "Voce foi adicionado ao grupo 'wireshark'. Feche e reabra o WSL para capturar sem sudo."
  fi
fi

if grep -qi microsoft /proc/version 2>/dev/null; then
  log "WSL detectado: a interface grafica do Wireshark exige WSLg (Windows 11) ou um servidor X."
  log "O 'tshark' (versao em linha de comando) funciona em qualquer caso."
fi

# -----------------------------------------------------------------------------
# 7. Burp Suite Community (download do instalador oficial)
# -----------------------------------------------------------------------------
section "7/8 - Burp Suite Community"

BURP_DIR="$HOME/Downloads"
BURP_FILE="$BURP_DIR/burpsuite-community-linux.sh"

if command -v burpsuite >/dev/null 2>&1 || [[ -d "$HOME/BurpSuiteCommunity" ]]; then
  ok "Burp Suite Community ja parece instalado."
else
  mkdir -p "$BURP_DIR"
  log "Baixando o instalador oficial do Burp Suite Community..."
  if curl -fsSL -o "$BURP_FILE" \
      "https://portswigger.net/burp/releases/download?product=community&type=LinuxX64"; then
    chmod +x "$BURP_FILE"
    ok "Instalador salvo em $BURP_FILE"
    warn "O instalador do Burp e GRAFICO. Execute-o com WSLg/servidor X ativo:"
    echo "        $BURP_FILE"
  else
    warn "Nao foi possivel baixar o Burp automaticamente."
    echo "        Baixe manualmente em: https://portswigger.net/burp/communitydownload"
  fi
fi

# -----------------------------------------------------------------------------
# 8. Verificacao final
# -----------------------------------------------------------------------------
verificar_ambiente

section "Etapas manuais (conforme o roteiro)"
cat <<'EOF'
1) IDA Free 9.2+
   Necessario criar uma conta para baixar e instalar:
   https://hex-rays.com/ida-free

2) Burp Suite Community 2026.2.3+
   Se o download automatico funcionou, rode o instalador grafico:
   ~/Downloads/burpsuite-community-linux.sh
   Caso contrario: https://portswigger.net/burp/communitydownload

3) Ativar o GEF
   Edite ~/.gdbinit e descomente a linha:
   source /opt/.gdbinit-gef.py

4) Moodle da disciplina
   Endereco: https://idp-moodle.online
   Disciplina: Criptografia e Seguranca - 2026/2
   Chave de inscricao: cs-cs-2026-02-cs-cs

5) Recarregue o shell para aplicar PATH, aliases e o grupo 'wireshark':
   exec bash   (ou feche e reabra o WSL)
EOF
