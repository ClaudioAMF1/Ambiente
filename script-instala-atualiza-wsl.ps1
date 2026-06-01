# script-instala-atualiza-wsl.ps1
# -----------------------------------------------------------------------------
# Configura o WSL para a versao 2.0 e instala o Ubuntu 24.04, conforme o
# roteiro de Sistemas Operacionais - IDP 2026/1.
#
# Como executar (no PowerShell, de preferencia como Administrador):
#   powershell -executionpolicy bypass -File .\script-instala-atualiza-wsl.ps1
# -----------------------------------------------------------------------------

Write-Host "==> Configuracao do WSL2 + Ubuntu 24.04 (IDP 2026/1)" -ForegroundColor Cyan

# Verifica privilegios de administrador
$ehAdmin = ([Security.Principal.WindowsPrincipal] `
  [Security.Principal.WindowsIdentity]::GetCurrent() `
  ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $ehAdmin) {
    Write-Host "[AVISO] Execute este script como Administrador para evitar erros." -ForegroundColor Yellow
}

# 1. Habilita os recursos necessarios do Windows
Write-Host "==> Habilitando recursos do Windows (WSL e Virtual Machine Platform)..." -ForegroundColor Cyan
try {
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
} catch {
    Write-Host "[AVISO] Nao foi possivel habilitar recursos via DISM: $_" -ForegroundColor Yellow
}

# 2. Atualiza o kernel do WSL e define a versao 2 como padrao
Write-Host "==> Atualizando o WSL..." -ForegroundColor Cyan
wsl --update
wsl --set-default-version 2

# 3. Instala o Ubuntu 24.04
Write-Host "==> Instalando o Ubuntu 24.04..." -ForegroundColor Cyan
wsl --install -d Ubuntu-24.04

Write-Host ""
Write-Host "==> Concluido!" -ForegroundColor Green
Write-Host "Se solicitado, REINICIE o computador e inicie o Ubuntu pelo menu Iniciar." -ForegroundColor Green
Write-Host "Na primeira execucao, crie seu usuario e senha do Linux (LEMBRE-SE da senha)." -ForegroundColor Green
