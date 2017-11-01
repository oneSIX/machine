﻿# Wrap the prompt by default.
$Global:WrapPrompt = $true;

# Load PoSh-Git.
$Global:PoShGitInstalled = (Get-Module -ListAvailable -Name posh-git)
if($Global:PoShGitInstalled) {
    Import-Module posh-git
    Push-Location
    Start-SshAgent -Quiet
    Pop-Location
} else {
    Write-Host "PoSh-Git has not been installed."
}

# The prompt
Function Global:Prompt()
{
    # Store the last exit code.
    $REALLASTEXITCODE = $LASTEXITCODE

    # Not at top row? Check if we should insert a blank space.
    if($host.ui.rawui.CursorPosition.Y -ge 1) {
        $previous = $host.ui.rawui.CursorPosition.Y - 1
        $rect = New-Object System.Management.Automation.Host.Rectangle(0, $previous, 1, $previous)
        $content = $host.UI.RawUI.GetBufferContents($rect)
        if($content.Character -ne " ") {
            Write-Host ""
        }
    }

    # User and computer name
    Write-Host ([Environment]::UserName) -n -f ([ConsoleColor]::Cyan)
    Write-Host "@" -n
    Write-Host ([net.dns]::GetHostName()) -n -f ([ConsoleColor]::Green)

    # Current path
    Write-Host " " -n
    Write-Host "[" -nonewline -f ([ConsoleColor]::Yellow)
    Write-Host($pwd.ProviderPath) -nonewline
    Write-Host "]" -n -f ([ConsoleColor]::Yellow)

    # Git status
    if($Global:PoShGitInstalled) {
        Write-VcsStatus
    }

    # Show stack
    if ((get-location -stack).Count -gt 0) {
        write-host " " -NoNewLine
        write-host (("+" * ((get-location -stack).Count))) -NoNewLine -ForegroundColor Cyan
    }

    # New line
    Write-Host ""

    # Print exit code
    if ($REALLASTEXITCODE -ne 0) {
        write-host " X $REALLASTEXITCODE " -NoNewLine -BackgroundColor DarkRed -ForegroundColor Yellow
        write-host " " -NoNewline
    }

    # Prompt
    $windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $windowsPrincipal = new-object 'System.Security.Principal.WindowsPrincipal' $windowsIdentity
    $IsAdministrator = $windowsPrincipal.IsInRole("Administrators") -eq 1;
    $PromptColor = if ($IsAdministrator) {[ConsoleColor]::Red} Else {[ConsoleColor]::Green}
    Write-Host "λ" -n -f ($PromptColor)

    # Set the window title.
    $CurrentPath = $pwd.ProviderPath
    $WindowTitle = if ($IsAdministrator) {"[Admin] " + $CurrentPath} Else {$CurrentPath}
    $host.UI.RawUI.WindowTitle = $WindowTitle;

    $global:LASTEXITCODE = $REALLASTEXITCODE
    return " "
}

# Copies the current location to the clipboard.
Function Copy-CurrentLocation()
{
    $Result = (Get-Location).Path | clip.exe
    Write-Host "Copied current location to clipboard."
    return $Result
}

# Creates a new directory and enters it.
Function New-Directory([string]$Name)
{
    $Directory = New-Item -Path $Name -ItemType Directory;
    if(Test-Path $Directory) {
        Set-Location $Name;
    }
}

# Goes to the git repository directory.
Function Enter-SourceLocation()
{
    if([string]::IsNullOrWhiteSpace($Global:SourceLocation)) {
        Write-Host "Source location has not been set."
        return
    }
    Set-Location $Global:SourceLocation
}

# Aliases
Set-Alias open start
Set-Alias ccl Copy-CurrentLocation
Set-Alias gs Enter-SourceLocation
Set-Alias mcd New-Directory
Set-Alias back popd
Set-Alias build ./build.ps1