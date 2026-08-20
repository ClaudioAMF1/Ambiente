# Configuração do Ambiente de Programação — IDP

Este repositório contém os scripts para preparar o ambiente de desenvolvimento
descrito nos roteiros das disciplinas, além de um script extra que instala
**Python, Node.js, Docker e as linguagens e frameworks mais usados**.

Disciplinas cobertas:

- **Sistemas Operacionais — 2026/1** (`so-preparacao-do-ambiente-taa-2026-01.pdf`)
- **Criptografia e Segurança — 2026/2** (`cs-preparacao-do-ambiente-2026-02.pdf`)

## Visão geral dos scripts

| Arquivo | Onde executar | O que faz |
|---|---|---|
| `script-instala-atualiza-wsl.ps1` | **Windows** (PowerShell) | Configura o WSL para a versão 2 e instala o **Ubuntu 24.04**. Serve para as duas disciplinas. |
| `script-instalacao-dell-2026.sh` | **Ubuntu / WSL2** | **Sistemas Operacionais 2026/1**: build-essential, **GDB**, **GEF**, NASM, Valgrind, etc. |
| `script-instalacao-cripto-2026-02.sh` | **Ubuntu / WSL2** | **Criptografia e Segurança 2026/2**: GDB/GEF, **pwntools**, **pycryptodome**, **ROPGadget**, **one_gadget**, **Wireshark**, Burp Suite + verificação de versões. |
| `setup-dev-completo.sh` | **Ubuntu / WSL2** | Ambiente de dev completo: Python, Node, Docker, Java, Go, Rust, Ruby, PHP, .NET e frameworks populares. |

---

## Passo a passo

### 1. No Windows — instalar o WSL2 + Ubuntu 24.04

Abra o **PowerShell** (de preferência como Administrador) na pasta deste repositório e rode:

```powershell
powershell -executionpolicy bypass -File .\script-instala-atualiza-wsl.ps1
```

Reinicie se solicitado, abra o **Ubuntu** pelo menu Iniciar e crie seu usuário e
senha do Linux (**lembre-se da senha**).

### 2. No Ubuntu (WSL) — ferramentas de Sistemas Operacionais (2026/1)

```bash
chmod +x script-instalacao-dell-2026.sh
./script-instalacao-dell-2026.sh
```

Isso instala o GDB e o GEF. Para **ativar o GEF**, edite o `~/.gdbinit` e
descomente a linha:

```text
source /opt/.gdbinit-gef.py
```

> Caso a Internet não funcione no WSL, o próprio script ajusta o DNS para
> `8.8.8.8` em `/etc/resolv.conf`, conforme o roteiro.

### 3. No Ubuntu (WSL) — ferramentas de Criptografia e Segurança (2026/2)

```bash
chmod +x script-instalacao-cripto-2026-02.sh
./script-instalacao-cripto-2026-02.sh
```

Para apenas **conferir** se o ambiente já atende aos mínimos do roteiro, sem
instalar nada:

```bash
./script-instalacao-cripto-2026-02.sh --check
```

#### Ferramentas instaladas e versões mínimas do roteiro

| Ferramenta | Mínimo | Como é instalada |
|---|---|---|
| gcc | 13.3.0+ | `apt` (build-essential) |
| gdb | 15.0.50+ | `apt` |
| gef | 2025-10-04+ | download em `/opt/.gdbinit-gef.py` |
| python | 3.12.3+ | `apt` (padrão do Ubuntu 24.04) |
| pwntools | 4.15+ | venv em `~/.venvs/cripto` |
| pycryptodome | 3.21+ | venv em `~/.venvs/cripto` |
| requests | 2.31+ | venv em `~/.venvs/cripto` |
| ROPGadget | 7.6+ | venv em `~/.venvs/cripto` |
| one_gadget | 1.10+ | `gem install one_gadget` |
| Wireshark / tshark | 4.2.2+ | `apt` (captura sem root via grupo `wireshark`) |
| Burp Suite Community | 2026.2.3+ | download do instalador oficial (execução **manual**) |
| IDA Free | 9.2+ | **manual** — exige conta na Hex-Rays |

#### Por que uma venv?

O Ubuntu 24.04 marca o Python do sistema como *externally managed* (PEP 668),
então `pip install pwntools` falha direto no sistema. O script cria uma venv
dedicada em `~/.venvs/cripto` e cria links dos executáveis (`pwn`, `ROPgadget`,
`checksec`) em `~/.local/bin`, de forma que eles funcionam no terminal sem
precisar ativar nada.

Para rodar **scripts Python** com as bibliotecas da disciplina:

```bash
cripto-python meu_exploit.py     # atalho criado no ~/.bashrc
# ou
cripto-activate                  # ativa a venv no shell atual
```

#### Etapas manuais

- **IDA Free 9.2+** — baixe em <https://hex-rays.com/ida-free> (precisa de conta).
- **Burp Suite Community** — o script baixa o instalador para
  `~/Downloads/burpsuite-community-linux.sh`, mas o instalador é **gráfico**:
  rode-o com o WSLg (Windows 11) ou um servidor X ativo.
- **Ativar o GEF** — edite `~/.gdbinit` e descomente `source /opt/.gdbinit-gef.py`.
- **Wireshark no WSL** — a interface gráfica precisa de WSLg; o `tshark`
  (linha de comando) funciona sempre.
- Feche e reabra o WSL depois da instalação, para aplicar o `PATH`, os aliases
  e o grupo `wireshark`.

#### Moodle da disciplina

- Endereço: <https://idp-moodle.online>
- Disciplina: **Criptografia e Segurança - 2026/2**
- Chave de inscrição: `cs-cs-2026-02-cs-cs`

---

### 4. No Ubuntu (WSL) — ambiente de desenvolvimento completo

Instalar **tudo** (Python, Node, Docker e todas as linguagens/frameworks):

```bash
chmod +x setup-dev-completo.sh
./setup-dev-completo.sh
```

Instalar **apenas alguns módulos** (exemplo: só Python, Node e Docker):

```bash
./setup-dev-completo.sh base python node docker
```

Ver a ajuda e a lista de módulos:

```bash
./setup-dev-completo.sh --help
```

#### Módulos disponíveis

| Módulo | Conteúdo |
|---|---|
| `base` | git, curl, wget, build-essential, gcc/g++, make, cmake, gdb, utilitários |
| `python` | Python 3, pip, venv, pipx, Poetry + Django / Flask / FastAPI / Uvicorn |
| `node` | Node.js LTS (via nvm) + npm, yarn, pnpm + Vite |
| `docker` | Docker Engine + Docker Compose plugin (adiciona seu usuário ao grupo `docker`) |
| `java` | OpenJDK 21 + Maven + Gradle |
| `go` | Linguagem Go (versão estável) |
| `rust` | Rust + Cargo (via rustup) |
| `ruby` | Ruby + Bundler + Rails |
| `php` | PHP + Composer |
| `dotnet` | .NET SDK |

---

## Observações importantes

- Os scripts `.sh` foram feitos para **Ubuntu 24.04** (incluindo WSL2) e usam `apt`.
- **Não** execute os scripts como `root`; use seu usuário normal — o `sudo` é
  solicitado apenas quando necessário.
- Depois de instalar o **Docker**, faça logout/login (ou feche e reabra o WSL)
  para usar `docker` sem `sudo`.
- Ao final, rode `source ~/.bashrc` (ou reabra o terminal) para carregar as
  variáveis de ambiente do Go, Rust e nvm.
- Os scripts são **idempotentes** no que é razoável: detectam o que já está
  instalado e evitam reinstalar.
