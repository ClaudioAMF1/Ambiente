# Configuração do Ambiente de Programação — Sistemas Operacionais (IDP 2026/1)

Este repositório contém os scripts para preparar o ambiente de desenvolvimento
descrito no roteiro da disciplina (`so-preparacao-do-ambiente-taa-2026-01.pdf`),
além de um script extra que instala **Python, Node.js, Docker e as linguagens e
frameworks mais usados**.

## Visão geral dos scripts

| Arquivo | Onde executar | O que faz |
|---|---|---|
| `script-instala-atualiza-wsl.ps1` | **Windows** (PowerShell) | Configura o WSL para a versão 2 e instala o **Ubuntu 24.04**. |
| `script-instalacao-dell-2026.sh` | **Ubuntu / WSL2** | Instala as ferramentas da disciplina: build-essential, **GDB**, **GEF**, NASM, Valgrind, etc. (fiel ao roteiro). |
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

### 2. No Ubuntu (WSL) — ferramentas da disciplina

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

### 3. No Ubuntu (WSL) — ambiente de desenvolvimento completo

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
