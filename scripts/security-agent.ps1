# security-agent.ps1 - Command safety evaluator for sub-agent approvals
# Called by orchestrator before approving dangerous commands
# Returns: APPROVED / DENIED / CONDITIONAL + reasoning

param(
    [Parameter(Mandatory=$true)]
    [string]$Command,

    [string]$WorkDir = "."
)

# Colors
$Red = "`e[0;31m"
$Green = "`e[0;32m"
$Yellow = "`e[1;33m"
$NC = "`e[0m"

# Approved external domains
$ApprovedDomains = @(
    "github.com",
    "api.github.com",
    "registry.npmjs.org",
    "pypi.org",
    "brew.sh",
    "docs.openclaw.ai",
    "clawhub.ai"
)

# Dangerous patterns
$DangerousPatterns = @(
    "rm\s+-rf",
    "rm\s+-r\s+-f",
    "Remove-Item\s+.*-Recurse\s+.*-Force",
    "del\s+.*[/\\]f",
    "chmod\s+777",
    "icacls\s+.*\s+/grant\s+Everyone",
    "sudo\s+su",
    "sudo\s+-i",
    "Invoke-Expression\s+\$\(",
    "iex\s+\$\(",
    "base64\s+-d\s+.*\|",
    "curl\s+.*\|\s*bash",
    "wget\s+.*\|\s*bash",
    "\|\s*sh\s*$",
    "\|\s*bash\s*$",
    "\brm\s+-rf\b",
    "\bdel\s+/f\b",
    "format\s+[a-z]:",
    "dd\s+.*of=/dev/",
    "mkfs"
)

function Write-Denied {
    param([string]$Reason, [string]$Rule)
    Write-Host "${Red}❌ DENIED: $Command${NC}" -NoNewline
    Write-Host ""
    Write-Host "${Red}Risk: $Reason${NC}"
    Write-Host "${Red}⛔ Rule violated: $Rule${NC}"
    Write-Host ""
    Write-Host "${Yellow}✅ To get approved:${NC}"
    Write-Host "1. Identify what you really need to delete"
    Write-Host "2. Use trash/rubbish-cli instead of Remove-Item"
    Write-Host "3. Or use -Confirm flag for interactive confirmation"
    Write-Host "4. Confirm target path is inside project directory"
    Write-Host ""
    Write-Host "Submit corrected command for re-review."
    exit 1
}

function Write-Approved {
    param([string]$Reason = "Command matches safe patterns")
    Write-Host "${Green}✅ APPROVED: $Command${NC}" -NoNewline
    Write-Host ""
    Write-Host "Reason: $Reason"
    exit 0
}

function Write-Conditional {
    param([string]$Warning, [string]$Note = "")
    Write-Host "${Yellow}⚠️ CONDITIONAL: $Command${NC}" -NoNewline
    Write-Host ""
    Write-Host "Warning: $Warning"
    if ($Note) { Write-Host $Note }
    exit 0
}

function Evaluate-Command {
    # Remove prefixes
    $parsed = $Command -replace '^sudo\s+', ''
    $parsed = $parsed -replace '^pwsh\s+', ''
    $parsed = $parsed -replace '^bash\s+', ''

    # 1. Check dangerous patterns
    foreach ($pattern in $DangerousPatterns) {
        if ($parsed -match $pattern) {
            Write-Denied -Reason "Matches dangerous pattern: $pattern" -Rule "DANGEROUS_COMMAND"
        }
    }

    # 2. Check for credential exposure
    if ($parsed -match '(sk-|ghp_|token|secret|password)\s+[a-zA-Z0-9]') {
        Write-Denied -Reason "Credential or secret on command line" -Rule "CREDENTIAL_EXPOSURE"
    }

    # 3. Check for unsafe curl/wget with pipe
    if ($parsed -match '(curl|wget).*\|\s*(bash|sh|python)') {
        Write-Denied -Reason "Pipe to shell - remote code execution" -Rule "PIPE_TO_SHELL"
    }

    # 4. Check for wildcard installs
    if ($parsed -match 'npm\s+install\s*$)' -or $parsed -match 'pip\s+install\s*$)') {
        Write-Denied -Reason "Wildcard package install" -Rule "WILDCARD_INSTALL"
    }

    # 5. Check for force push
    if ($parsed -match 'git\s+push\s+.*(-f|--force)') {
        Write-Conditional -Warning "Force push detected" -Note "Confirm remote is correct"
    }

    # 6. Check for system modifications
    if ($parsed -match '(/etc/|/usr/sbin|/bin/|/sbin/)' -and $parsed -notmatch '(test\s+|Get-Content\s+|Select-String\s+)') {
        Write-Conditional -Warning "System directory modification" -Note "Confirm this is intentional"
    }

    # 7. If we get here, command is likely safe
    Write-Approved
}

# Main
if (-not $Command) {
    Write-Host "Usage: security-agent.ps1 -Command '<command>' [-WorkDir '<dir>']"
    Write-Host ""
    Write-Host "Evaluates command safety:"
    Write-Host "  ✅ APPROVED - safe to execute"
    Write-Host "  ❌ DENIED - dangerous, needs modification"
    Write-Host "  ⚠️ CONDITIONAL - approved with caution"
    exit 0
}

Evaluate-Command
