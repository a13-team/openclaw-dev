# security-agent.ps1 - Context-aware command safety evaluator
# Smart enough to understand context, not just patterns

param(
    [string]$Command = "",
    [string]$WorkDir = "."
)

$RED = "`e[0;31m"
$GREEN = "`e[0;32m"
$YELLOW = "`e[1;33m"
$CYAN = "`e[0;36m"
$NC = "`e[0m"

# Reinstallable targets - safe to delete if lock file exists
$ReinstallableDirs = @(
    "node_modules",
    ".venv",
    "venv",
    "env",
    "vendor",
    "bower_components",
    ".npm",
    ".cache",
    ".parcel-cache",
    ".next",
    ".nuxt",
    ".astro",
    ".vite",
    ".turbo",
    "__pycache__",
    ".pytest_cache",
    ".mypy_cache"
)

# Always-block dangerous patterns
$DangerousPatterns = @(
    "rm\s+-rf\s+/",
    "rm\s+-rf\s+/etc",
    "rm\s+-rf\s+/var",
    "rm\s+-rf\s+/usr",
    "rm\s+-rf\s+/home",
    "del\s+/f\s+/",
    "del\s+/f\s+/etc",
    "del\s+/f\s+/windows",
    "format\s+[a-z]:",
    "dd\s+.*of=/dev/sd",
    "mkfs",
    "icacls\s+.*\s+/grant\s+Everyone",
    "chmod\s+777\s+/etc",
    "sudo\s+su",
    "eval\s+\$\(",
    "base64\s+-d\s+.*\|.*sh"
)

function Test-ReinstallableTarget {
    param([string]$Target)

    foreach ($dir in $ReinstallableDirs) {
        if ($Target -match [regex]::Escape($dir)) {
            return $true
        }
    }
    return $false
}

function Test-HasLockFile {
    param([string]$WorkDir)

    $lockFiles = @(
        "package-lock.json",
        "yarn.lock",
        "pnpm-lock.yaml",
        "Pipfile.lock",
        "poetry.lock",
        "requirements.lock",
        "composer.lock",
        "Gemfile.lock",
        "go.sum"
    )

    foreach ($lock in $lockFiles) {
        if (Test-Path (Join-Path $WorkDir $lock)) {
            return $true
        }
    }
    return $false
}

function Test-TestDatabase {
    param([string]$Cmd)

    if ($Cmd -match "test|testing|spec") { return $true }
    if ($Cmd -match "DB_HOST=localhost") { return $true }
    if ($Cmd -match "DATABASE_URL=postgres://.*:5432/test") { return $true }

    return $false
}

function Test-DatabaseRisk {
    param([string]$Cmd)

    # PHP artisan with destructive commands
    if ($Cmd -match "php\s+artisan") {
        if ($Cmd -match "migrate:refresh|db:wipe|db:seed") {
            return $true
        }
    }

    # SQL destructive operations
    if ($Cmd -match "drop\s+table|truncate|delete\s+from\s+\w+\s*$") {
        return $true
    }

    return $false
}

function Invoke-Evaluate {
    param(
        [string]$Cmd,
        [string]$WorkDir
    )

    Write-Host "${CYAN}🔍 Analyzing: $Cmd${NC}" -NoNewline
    Write-Host ""

    # 1. Check always-block dangerous patterns
    foreach ($pattern in $DangerousPatterns) {
        if ($Cmd -match $pattern) {
            Write-Host "${RED}❌ DENIED: $Cmd${NC}"
            Write-Host "${RED}⛔ Always blocked: matches critical danger pattern${NC}"
            Write-Host ""
            Write-Host "${YELLOW}This pattern is never approved regardless of context.${NC}"
            return $false
        }
    }

    # 2. Extract target path
    $target = ""
    if ($Cmd -match "(rm|del|Remove-Item)") {
        $target = ($Cmd -replace '.*(rm|del|Remove-Item)[^/]*', '') -replace '["'\'']', ''
        $target = ($target -split '\s+')[0]
    }

    # 3. Check reinstallable target with lock file
    if ($target -and (Test-ReinstallableTarget $target)) {
        if (Test-HasLockFile $WorkDir) {
            Write-Host "${GREEN}✅ APPROVED: $Cmd${NC}"
            Write-Host "${GREEN}💡 Context: Reinstallable target detected (has lock file)${NC}"
            Write-Host ""
            Write-Host "${CYAN}📝 Reminder: Run 'npm install' / 'pip install' / etc after this${NC}"
            return $true
        } else {
            Write-Host "${YELLOW}⚠️ CAUTION: $Cmd${NC}"
            Write-Host "${YELLOW}⚠️ Target looks reinstallable but no lock file found${NC}"
            Write-Host ""
            Write-Host "${CYAN}💡 Consider creating lock file first:${NC}"
            Write-Host "   npm install --package-lock-only"
            Write-Host "   pip freeze > requirements.lock"
            Write-Host ""
            Write-Host "${YELLOW}⚠️ Proceeding but verify you can restore dependencies${NC}"
            return $true
        }
    }

    # 4. Check database risks
    if (Test-DatabaseRisk $Cmd) {
        if (Test-TestDatabase $Cmd) {
            Write-Host "${GREEN}✅ APPROVED: $Cmd${NC}"
            Write-Host "${GREEN}💡 Context: Test database operation${NC}"
            return $true
        } else {
            Write-Host "${RED}❌ DENIED: $Cmd${NC}"
            Write-Host "${RED}⛔ Database modification detected outside test environment${NC}"
            Write-Host ""
            Write-Host "${YELLOW}✅ To get approved:${NC}"
            Write-Host "1. Use test database: `$env:DB_NAME = 'test_db'"
            Write-Host "2. Or run with test flag: --env testing"
            Write-Host "3. Or use docker test container"
            Write-Host ""
            Write-Host "${CYAN}💡 Example fix:${NC}"
            Write-Host "   `$env:NODE_ENV = 'test'; $Cmd"
            Write-Host "   docker-compose exec -e DB_NAME=test_db app $Cmd"
            return $false
        }
    }

    # 5. Git force push
    if ($Cmd -match "git\s+push\s+.*(-f|--force)") {
        Write-Host "${YELLOW}⚠️ CONDITIONAL: git force push detected${NC}"
        Write-Host "This can overwrite remote work. Confirm:"
        Write-Host "  - Remote is correct (not wrong repo)"
        Write-Host "  - No collaborators' work will be lost"
        Write-Host ""
        Write-Host "${GREEN}✅ Auto-approved if this is your feature branch${NC}"
        return $true
    }

    # 6. Git clean
    if ($Cmd -match "git\s+clean") {
        Write-Host "${YELLOW}⚠️ CONDITIONAL: git clean (untracked files will be deleted)${NC}"
        Write-Host "This permanently deletes untracked files."
        Write-Host ""
        if ($Cmd -match "-n|--dry-run") {
            Write-Host "${GREEN}✅ Auto-approved (dry-run detected)${NC}"
            return $true
        }
        Write-Host "${YELLOW}⚠️ Proceeding - verify no important untracked files${NC}"
        return $true
    }

    # 7. Credential on command line
    if ($Cmd -match "(sk-|ghp_|openssh-|token|secret|password)\s*=") {
        Write-Host "${RED}❌ DENIED: Credential on command line${NC}"
        Write-Host "${RED}⛔ Rule: Secrets must use env vars or config files${NC}"
        Write-Host ""
        Write-Host "${YELLOW}✅ Fix: `$env:TOKEN = 'xxx'; $Cmd${NC}"
        return $false
    }

    # 8. Pipe to shell from remote
    if ($Cmd -match "(curl|wget).*\|\s*(bash|sh|python|ruby)") {
        Write-Host "${RED}❌ DENIED: Pipe to shell from remote URL${NC}"
        Write-Host "${RED}⛔ Risk: Remote code execution without review${NC}"
        Write-Host ""
        Write-Host "${YELLOW}✅ Fix:${NC}"
        Write-Host "   curl -o script.ps1 https://..."
        Write-Host "   Get-Content script.ps1  # Review first"
        Write-Host "   ./script.ps1"
        return $false
    }

    # 9. Default: APPROVE
    Write-Host "${GREEN}✅ APPROVED: $Cmd${NC}"
    Write-Host "${GREEN}💡 Context: No risk factors detected${NC}"
    return $true
}

# Main
if (-not $Command) {
    Write-Host "Usage: security-agent.ps1 -Command '<command>' [-WorkDir '<dir>']"
    Write-Host ""
    Write-Host "Context-aware security evaluator:"
    Write-Host "  - Respects reinstallable targets (node_modules with lock file)"
    Write-Host "  - Blocks database modifications outside test env"
    Write-Host "  - Warns on force operations"
    Write-Host "  - Never blocks credential exposure"
    exit 0
}

$result = Invoke-Evaluate $Command $WorkDir
exit $(if ($result) { 0 } else { 1 })
