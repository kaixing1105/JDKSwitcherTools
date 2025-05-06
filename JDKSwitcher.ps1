<#
JDK 版本切换工具 by Xing - 2025
#>

function QExit {
    Write-Host "`n[按 Q 键退出]" -ForegroundColor Cyan
    do {
        $key = [System.Console]::ReadKey($true).Key
    } while ($key -ne 'Q')
    exit
}

# 检查管理员权限
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[错误] 请以管理员身份运行此脚本！" -ForegroundColor Red
    QExit
}

try {
    Write-Host "`n[1/5] 环境初始化检查..." -ForegroundColor Cyan

    $currentJavaVersion = $null
    $currentJavaPath = cmd /c "where java 2>nul"

    if ($currentJavaPath) {
        $javaVersion = cmd /c "java -version 2>&1"
        Write-Host "当前JDK版本信息：`n"
        $javaVersion | ForEach-Object { Write-Host $_ }

        foreach ($line in $javaVersion) {
            if ($line -match 'version "([\d\.]+)') {
                $verStr = $matches[1]
                if ($verStr -like "1.8*") {
                    $currentJavaVersion = 8
                } else {
                    $parts = $verStr -split '\.'
                    if ($parts[0] -match '^\d+$') {
                        $currentJavaVersion = [int]$parts[0]
                    }
                }
                break
            }
        }
    } else {
        Write-Host "未检测到系统Java环境" -ForegroundColor Yellow
    }

    Write-Host "`n[2/5] 精确扫描Java目录..." -ForegroundColor Cyan
    Write-Host "[提示] JDK需安装在默认目录（C:\Program Files\Java\），否则可能无法正常切换。"  -ForegroundColor Yellow

    $jdkRoot = "C:\Program Files\Java"
    if (-not (Test-Path -LiteralPath $jdkRoot)) {
        Write-Host "[错误] Java安装目录不存在：$jdkRoot" -ForegroundColor Red
        QExit
    }

    $jdkList = @(
        Get-ChildItem -LiteralPath $jdkRoot -Directory -Force |
        Where-Object { $_.Attributes -notmatch 'ReparsePoint|Hidden|System' -and (Test-Path -LiteralPath $_.FullName) } |
        ForEach-Object {
            $dir = $_.FullName
            $dirName = $_.Name
            Write-Host "[扫描] 正在检查目录: $dir" -ForegroundColor DarkGray

            $javaExe = Join-Path -Path $dir -ChildPath "bin\java.exe"
            if (-not (Test-Path -LiteralPath $javaExe)) {
                Write-Host "[跳过] 无效目录（缺少java.exe）: $dir" -ForegroundColor DarkGray
                return
            }

            $version = switch -Regex ($dirName) {
                '^jdk[-_]?([0-9]+)' { [int]$matches[1]; break }
                '^jre1\.([0-9]+)'  { [int]$matches[1]; break }
                default {
                    Write-Host "[跳过] 非标准目录格式: $dirName" -ForegroundColor DarkGray
                    return
                }
            }

            [PSCustomObject]@{
                Version     = $version
                DisplayName = "jdk-$version"
                JavaHome    = $dir
                JavaExe     = $javaExe
                IsJDK       = (Test-Path (Join-Path $dir "bin\javac.exe"))
            }
        } |
        Sort-Object Version -Unique
    )

    if (-not $jdkList) {
        Write-Host "[错误] 未找到有效的JDK安装" -ForegroundColor Red
        QExit
    }

    Write-Host "`n[3/5] 有效Java版本列表：" -ForegroundColor Cyan
    Write-Host ("-" * 70)
    Write-Host "编号     类型     名称           JDK安装路径"
    foreach ($jdk in $jdkList) {
        $type = if ($jdk.IsJDK) { "JDK" } else { "JRE" }
        Write-Host ("{0,-8} {1,-8} {2,-14} {3}" -f $jdk.Version, $type, $jdk.DisplayName, $jdk.JavaHome)
    }
    Write-Host ("-" * 70)

    if (@($jdkList).Count -le 1) {
        Write-Host "`n[提示] 当前系统仅检测到一个JDK版本，不能进行版本切换。" -ForegroundColor Yellow
        QExit
    }

    # ---------------------------
    # 4. 用户交互
    # ---------------------------
    if (-not $currentJavaVersion) {
        Write-Host "`n[4/5] JDK环境变量配置操作" -ForegroundColor Cyan
        Write-Host "[提示] 输入版本编号后，系统将自动配置JDK环境变量！"  -ForegroundColor Yellow
    } else {
        Write-Host "`n[4/5] 版本切换操作" -ForegroundColor Cyan
        Write-Host "[提示] 输入版本编号后，系统将自动修改环境变量！"  -ForegroundColor Yellow
    }
    Write-Host ""

    :inputLoop while ($true) {
        if (-not $currentJavaVersion) {
            $inputVer = Read-Host "请输入要初始化配置的 JDK 版本编号（输入 Q 退出）"
        } else {
            $inputVer = Read-Host "请输入要切换的 JDK 版本编号（输入 Q 退出）"
        }

        if ($inputVer -eq 'Q') { QExit }
        if ($inputVer -notmatch '^\d+$') {
            Write-Host "[错误] 请输入有效的数字编号！" -ForegroundColor Red
            continue
        }
        $inputVerInt = [int]$inputVer
        if ($null -ne $currentJavaVersion -and ($inputVerInt -eq $currentJavaVersion -or ($currentJavaVersion -eq 8 -and $inputVerInt -eq 1))) {
            Write-Host "`n[!] 你输入的版本与当前环境一致，无需切换！`n" -ForegroundColor Yellow
            continue
        }
        $selected = $jdkList | Where-Object { $_.Version -eq $inputVerInt }
        if (-not $selected) {
            Write-Host "`n[错误] 版本 [ $inputVer ] 不存在于可用列表中！`n" -ForegroundColor Red
            continue
        }
        break
    }

    Write-Host "`n[5/5] 正在安全更新环境..." -ForegroundColor Cyan
    Write-Host ""

    $originalPath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $cleanPath = $originalPath -split ';' |
                 Where-Object { $_ -and $_ -notmatch ([regex]::Escape($jdkRoot) + '.*\\bin') } |
                 Select-Object -Unique

    $newJavaBin = "$($selected.JavaHome)\bin"
    $newPath = @($newJavaBin) + $cleanPath

    try {
        [System.Environment]::SetEnvironmentVariable('JAVA_HOME', $selected.JavaHome, 'Machine')
        [System.Environment]::SetEnvironmentVariable('CLASSPATH', ";%JAVA_HOME%\lib\dt.jar;%JAVA_HOME%\lib\tools.jar;", 'Machine')
        [System.Environment]::SetEnvironmentVariable('Path', ($newPath -join ';'), 'Machine')
        Write-Host "[√] 系统变量更新成功" -ForegroundColor Green
    } catch {
        Write-Host "[!] 注册表更新失败：$($_.Exception.Message)" -ForegroundColor Red
        QExit
    }

    Write-Host "`n[!] 正在最终验证（等待3秒）..." -ForegroundColor Yellow
    3..1 | ForEach-Object { Write-Host "倒计时 $_ 秒..." -ForegroundColor Yellow; Start-Sleep -Seconds 1 }

    $env:JAVA_HOME = $selected.JavaHome
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $finalCheck = & {
        $exePath = cmd /c "where java 2>nul"
        $exeVersion = cmd /c "java -version 2>&1"
        [PSCustomObject]@{ Path = $exePath; Version = $exeVersion }
    }

    if ($finalCheck.Path -match [regex]::Escape($newJavaBin)) {
        Write-Host "`n[√] 最终验证通过" -ForegroundColor Green
        Write-Host "`n当前JDK版本信息：`n"
        $finalCheck.Version | ForEach-Object { Write-Host $_ }
    } else {
        Write-Host "[!] 验证失败，可能原因：" -ForegroundColor Red
        Write-Host "1. 防病毒软件拦截"
        Write-Host "2. 需要重启终端"
        QExit
    }

    Write-Host "`n[!] 操作完成，按 Q 键退出..." -ForegroundColor Green
    do { } while ([System.Console]::ReadKey($true).Key -ne 'Q')
    Stop-Process -Id $PID

} catch {
    Write-Host "`n[!] 致命[错误] $($_.Exception.Message)" -ForegroundColor Red
    QExit
}
