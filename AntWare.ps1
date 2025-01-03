Function Verificar-Administrador {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "Permissão de administrador necessária. Reexecutando o script com privilégios elevados..." -ForegroundColor Yellow
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        Exit
    }
}

Verificar-Administrador

Start-Transcript -Path "$env:TEMP\script-log.txt" -Append
Write-Host "Iniciando o script..." -ForegroundColor Green

$ErrorActionPreference = "Stop"

Function Identificar-Navegator {
    param(
        [string]$diretorioEscolhido
    )

    $pastaNavegator = Join-Path -Path $diretorioEscolhido -ChildPath "navegator"

    if (-not (Test-Path $pastaNavegator)) {
        Write-Host "A pasta 'navegator' não foi encontrada no diretório especificado: $diretorioEscolhido" -ForegroundColor Red
        Write-Host "Certifique-se de criar a pasta antes de continuar." -ForegroundColor Yellow
        Exit
    }

    Write-Host "A pasta 'navegator' foi identificada em: $pastaNavegator" -ForegroundColor Green
    return $pastaNavegator
}

Function Configurar-NavegadorOuApp {
    param(
        [string]$nomeAplicativo,
        [string]$caminhoInstalacao,
        [string]$subPasta,
        [string]$regKeyPath,
        [string]$pastaNavegator
    )

    Write-Host "Configurando $nomeAplicativo..." -ForegroundColor Cyan
    $subPastaAplicativo = Join-Path -Path $pastaNavegator -ChildPath $subPasta

    if (-not (Test-Path $subPastaAplicativo)) {
        New-Item -Path $subPastaAplicativo -ItemType Directory -Force
        Write-Host "Subpasta '$subPasta' criada em: $subPastaAplicativo" -ForegroundColor Green
    }

    if (-not (Test-Path $regKeyPath)) {
        New-Item -Path $regKeyPath -Force
        Write-Host "Criada chave de registro: $regKeyPath" -ForegroundColor Yellow
    }

    Set-ItemProperty -Path $regKeyPath -Name "UserDataDir" -Value $subPastaAplicativo
    Set-ItemProperty -Path $regKeyPath -Name "ForceUserDataDir" -Value 1
    Write-Host "$nomeAplicativo configurado para usar a pasta: $subPastaAplicativo" -ForegroundColor Green
}

Function Reverter-NavegadorOuApp {
    param(
        [string]$nomeAplicativo,
        [string]$regKeyPath,
        [string]$subPasta,
        [string]$pastaNavegator
    )

    Write-Host "Iniciando o processo de reversão para $nomeAplicativo..." -ForegroundColor Cyan

    if (Test-Path $regKeyPath) {
        try {
            Remove-ItemProperty -Path $regKeyPath -Name "UserDataDir" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $regKeyPath -Name "ForceUserDataDir" -ErrorAction SilentlyContinue
            Write-Host "As configurações de registro para $nomeAplicativo foram removidas com sucesso." -ForegroundColor Green
        } catch {
            Write-Host "Erro ao tentar remover as configurações do Registro para $nomeAplicativo: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Nenhuma configuração encontrada no Registro para $nomeAplicativo. Já está revertido." -ForegroundColor Yellow
    }

    $subPastaAplicativo = Join-Path -Path $pastaNavegator -ChildPath $subPasta

    if (Test-Path $subPastaAplicativo) {
        try {
            Remove-Item -Path $subPastaAplicativo -Recurse -Force
            Write-Host "A subpasta '$subPasta' foi removida com sucesso." -ForegroundColor Green
        } catch {
            Write-Host "Erro ao tentar remover a subpasta '$subPasta': $_" -ForegroundColor Red
        }
    } else {
        Write-Host "A subpasta '$subPasta' não existe ou já foi removida." -ForegroundColor Yellow
    }
}

$opcoes = @(
    @{Nome = "Edge"; CaminhoInstalacao = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"; SubPasta = "Edge"; RegKeyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"},
    @{Nome = "Chrome"; CaminhoInstalacao = "C:\Program Files\Google\Chrome\Application\chrome.exe"; SubPasta = "Chrome"; RegKeyPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"},
    @{Nome = "Brave"; CaminhoInstalacao = "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe"; SubPasta = "Brave"; RegKeyPath = "HKLM:\SOFTWARE\Policies\BraveSoftware\Brave-Browser"},
    @{Nome = "Opera"; CaminhoInstalacao = "C:\Program Files\Opera\opera.exe"; SubPasta = "Opera"; RegKeyPath = "HKLM:\SOFTWARE\Policies\Opera Software\Opera"}
)

$diretorioEscolhido = Read-Host "Digite o diretório completo onde está a pasta 'navegator'"
$pastaNavegator = Identificar-Navegator -diretorioEscolhido $diretorioEscolhido

Write-Host "Escolha uma opção:" -ForegroundColor Cyan
Write-Host "1. Configurar um navegador ou aplicativo."
Write-Host "2. Reverter a configuração."

$acao = Read-Host "Digite o número da opção desejada"

if ($acao -eq 1) {
    Write-Host "Escolha o aplicativo ou navegador para configurar:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $opcoes.Length; $i++) {
        Write-Host "$($i + 1). $($opcoes[$i].Nome)"
    }

    $escolha = Read-Host "Digite o número correspondente ao aplicativo ou navegador"

    if ($escolha -ge 1 -and $escolha -le $opcoes.Length) {
        $aplicativoEscolhido = $opcoes[$escolha - 1]
        Configurar-NavegadorOuApp -nomeAplicativo $aplicativoEscolhido.Nome -caminhoInstalacao $aplicativoEscolhido.CaminhoInstalacao -subPasta $aplicativoEscolhido.SubPasta -regKeyPath $aplicativoEscolhido.RegKeyPath -pastaNavegator $pastaNavegator
    } else {
        Write-Host "Opção inválida. O script será encerrado." -ForegroundColor Red
    }
} elseif ($acao -eq 2) {
    Write-Host "Escolha o aplicativo ou navegador para reverter:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $opcoes.Length; $i++) {
        Write-Host "$($i + 1). $($opcoes[$i].Nome)"
    }

    $escolha = Read-Host "Digite o número correspondente ao aplicativo ou navegador"

    if ($escolha -ge 1 -and $escolha -le $opcoes.Length) {
        $aplicativoEscolhido = $opcoes[$escolha - 1]
        Reverter-NavegadorOuApp -nomeAplicativo $aplicativoEscolhido.Nome -regKeyPath $aplicativoEscolhido.RegKeyPath -subPasta $aplicativoEscolhido.SubPasta -pastaNavegator $pastaNavegator
    } else {
        Write-Host "Opção inválida. O script será encerrado." -ForegroundColor Red
    }
} else {
    Write-Host "Opção inválida. O script será encerrado." -ForegroundColor Red
}

Write-Host "Processo concluído! Pressione qualquer tecla para sair." -ForegroundColor Green
[System.Console]::ReadKey($true) | Out-Null
Stop-Transcript

# By Pullchra
