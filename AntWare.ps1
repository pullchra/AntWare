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

Function Verificar-Instalacao {
    param(
        [string]$nomeAplicativo,
        [string]$caminhoInstalacao
    )

    if (Test-Path $caminhoInstalacao) {
        Write-Host "$nomeAplicativo está instalado." -ForegroundColor Cyan
        return $true
    } else {
        Write-Host "$nomeAplicativo não está instalado. Verifique se ele está corretamente instalado no seu sistema." -ForegroundColor Yellow
        return $false
    }
}

Function Copiar-Dados {
    param(
        [string]$origem,
        [string]$destino
    )

    if (Test-Path $origem) {
        if (-not (Test-Path $destino)) {
            New-Item -Path $destino -ItemType Directory -Force
            Write-Host "Criada nova pasta de destino: $destino" -ForegroundColor Green
        }

        Write-Host "Copiando dados de '$origem' para '$destino'..." -ForegroundColor Cyan
        try {
            Copy-Item -Path "$origem\*" -Destination $destino -Recurse -Force
            Write-Host "Dados copiados com sucesso!" -ForegroundColor Green
        } catch {
            Write-Host "Erro ao copiar dados: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "A pasta de origem '$origem' não foi encontrada. Nenhuma ação será realizada." -ForegroundColor Yellow
    }
}

Function Configurar-NavegadorOuApp {
    param(
        [string]$nomeAplicativo,
        [string]$caminhoInstalacao,
        [string]$subPasta,
        [string]$regKeyPath,
        [string]$pastaAntiga
    )

    if (Verificar-Instalacao -nomeAplicativo $nomeAplicativo -caminhoInstalacao $caminhoInstalacao) {
        $subPastaAplicativo = Join-Path -Path $pastaNavegator -ChildPath $subPasta
        if (-not (Test-Path $subPastaAplicativo)) {
            New-Item -Path $subPastaAplicativo -ItemType Directory -Force
            Write-Host "Subpasta '$subPasta' criada em: $subPastaAplicativo" -ForegroundColor Green
        }

        Copiar-Dados -origem $pastaAntiga -destino $subPastaAplicativo

        if (-not (Test-Path $regKeyPath)) {
            Write-Host "Criando chave de registro: $regKeyPath" -ForegroundColor Yellow
            New-Item -Path $regKeyPath -Force
        }

        Set-ItemProperty -Path $regKeyPath -Name "UserDataDir" -Value $subPastaAplicativo
        Set-ItemProperty -Path $regKeyPath -Name "ForceUserDataDir" -Value 1
        Write-Host "$nomeAplicativo configurado para usar a pasta: $subPastaAplicativo" -ForegroundColor Green
    }
}

Function Reverter-Configuracoes {
    param(
        [string]$nomeAplicativo,
        [string]$regKeyPath,
        [string]$subPasta
    )

    $pastaAplicativo = Join-Path -Path $pastaNavegator -ChildPath $subPasta
    if (Test-Path $pastaAplicativo) {
        Remove-Item -Path $pastaAplicativo -Recurse -Force
        Write-Host "Pasta '$subPasta' removida com sucesso." -ForegroundColor Green
    } else {
        Write-Host "A pasta '$subPasta' não foi encontrada. Nenhuma ação será realizada." -ForegroundColor Yellow
    }

    if (Test-Path $regKeyPath) {
        Remove-Item -Path $regKeyPath -Recurse -Force
        Write-Host "Configuração de registro removida para '$nomeAplicativo'." -ForegroundColor Green
    } else {
        Write-Host "A chave de registro para '$nomeAplicativo' não foi encontrada." -ForegroundColor Yellow
    }
}

$diretorioEscolhido = Read-Host "Digite o caminho completo onde a pasta 'navegator' está localizada (exemplo: C:\Testes\) "
$pastaNavegator = Join-Path -Path $diretorioEscolhido -ChildPath "navegator"

if (-not (Test-Path $pastaNavegator)) {
    Write-Host "A pasta 'navegator' não foi encontrada no diretório especificado. O script será encerrado." -ForegroundColor Red
    Exit
}

$opcoes = @(
    @{Nome = "Edge"; CaminhoInstalacao = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"; SubPasta = "Edge"; RegKeyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; PastaAntiga = "$env:LOCALAPPDATA\Microsoft\Edge\User Data"},
    @{Nome = "Chrome"; CaminhoInstalacao = "C:\Program Files\Google\Chrome\Application\chrome.exe"; SubPasta = "Chrome"; RegKeyPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"; PastaAntiga = "$env:LOCALAPPDATA\Google\Chrome\User Data"},
    @{Nome = "Brave"; CaminhoInstalacao = "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe"; SubPasta = "Brave"; RegKeyPath = "HKLM:\SOFTWARE\Policies\BraveSoftware\Brave-Browser"; PastaAntiga = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"},
    @{Nome = "Opera"; CaminhoInstalacao = "C:\Program Files\Opera\opera.exe"; SubPasta = "Opera"; RegKeyPath = "HKLM:\SOFTWARE\Policies\Opera Software\Opera"; PastaAntiga = "$env:LOCALAPPDATA\Opera Software\Opera Stable"},
    @{Nome = "Discord"; CaminhoInstalacao = "C:\Users\$env:USERNAME\AppData\Local\Discord\app-*.exe"; SubPasta = "Discord"; RegKeyPath = "HKCU:\Software\Discord"; PastaAntiga = "$env:APPDATA\discord"}
)

Write-Host "Escolha uma opção:"
for ($i = 0; $i -lt $opcoes.Length; $i++) {
    Write-Host "$($i + 1) - $($opcoes[$i].Nome)"
}

$escolha = Read-Host "Digite o número da opção desejada"

if ($escolha -ge 1 -and $escolha -le $opcoes.Length) {
    $aplicativoEscolhido = $opcoes[$escolha - 1]
    $acao = Read-Host "Digite 'C' para configurar ou 'R' para reverter as configurações"
    
    if ($acao -ieq "C") {
        Configurar-NavegadorOuApp -nomeAplicativo $aplicativoEscolhido.Nome -caminhoInstalacao $aplicativoEscolhido.CaminhoInstalacao -subPasta $aplicativoEscolhido.SubPasta -regKeyPath $aplicativoEscolhido.RegKeyPath -pastaAntiga $aplicativoEscolhido.PastaAntiga
    } elseif ($acao -ieq "R") {
        Reverter-Configuracoes -nomeAplicativo $aplicativoEscolhido.Nome -regKeyPath $aplicativoEscolhido.RegKeyPath -subPasta $aplicativoEscolhido.SubPasta
    } else {
        Write-Host "Opção inválida. O script será encerrado." -ForegroundColor Red
    }
} else {
    Write-Host "Opção inválida. O script será encerrado." -ForegroundColor Red
}

Write-Host "Processo concluído! Pressione qualquer tecla para sair." -ForegroundColor Green
[System.Console]::ReadKey($true) | Out-Null
Stop-Transcript
