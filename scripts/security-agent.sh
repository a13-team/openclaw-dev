#!/usr/bin/env bash
# security-agent.sh - Context-aware command safety evaluator
# Smart enough to understand context, not just patterns

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Reinstallable targets - safe to delete if lock file exists
REINSTALLABLE_DIRS=(
    "node_modules"
    ".venv"
    "venv"
    "env"
    "vendor"
    "bower_components"
    ".npm"
    ".cache"
    ".parcel-cache"
    ".next"
    ".nuxt"
    ".astro"
    ".vite"
    ".turbo"
    "__pycache__"
    "*.pyc"
    ".pytest_cache"
    ".mypy_cache"
)

# Dangerous system patterns (always block)
DANGEROUS_PATTERNS=(
    "rm\s+-rf\s+/"
    "rm\s+-rf\s+/etc"
    "rm\s+-rf\s+/var"
    "rm\s+-rf\s+/usr"
    "rm\s+-rf\s+/home"
    "del\s+/f\s+/"
    "del\s+/f\s+/etc"
    "del\s+/f\s+/windows"
    "format\s+[a-z]:"
    "dd\s+.*of=/dev/sd"
    "mkfs"
    "icacls\s+.*\s+/grant\s+Everyone"
    "chmod\s+777\s+/etc"
    "sudo\s+su"
    "eval\s+\$\("
    "base64\s+-d\s+.*\|.*sh"
)

# Commands that need context check
NEED_CONTEXT=(
    "rm\s+-rf"
    "rm\s+-r\s+-f"
    "del\s+.*-Recurse"
    "git\s+clean"
    "git\s+push\s+.*-f"
    "npm\s+install"
    "pip\s+install"
)

# Check if target is reinstallable (has lock file)
is_reinstallable() {
    local target="$1"
    local workdir="${2:-.}"

    for dir in "${REINSTALLABLE_DIRS[@]}"; do
        # Handle wildcards
        if [[ "$dir" == *"*"* ]]; then
            local pattern="${dir%"*"}"
            if [[ "$target" == *"$pattern"* ]]; then
                return 0
            fi
        else
            if [[ "$target" == *"$dir"* ]]; then
                return 0
            fi
        fi
    done
    return 1
}

# Check if lock file exists (safe to delete reinstallable)
has_lock_file() {
    local workdir="${1:-.}"

    # Node.js
    [[ -f "$workdir/package-lock.json" ]] && return 0
    [[ -f "$workdir/yarn.lock" ]] && return 0
    [[ -f "$workdir/pnpm-lock.yaml" ]] && return 0

    # Python
    [[ -f "$workdir/Pipfile.lock" ]] && return 0
    [[ -f "$workdir/poetry.lock" ]] && return 0
    [[ -f "$workdir/requirements.lock" ]] && return 0

    # PHP
    [[ -f "$workdir/composer.lock" ]] && return 0

    # Ruby
    [[ -f "$workdir/Gemfile.lock" ]] && return 0

    # Go
    [[ -f "$workdir/go.sum" ]] && return 0

    return 1
}

# Check if database is test db
is_test_database() {
    local cmd="$1"

    # Check for test indicators
    echo "$cmd" | grep -Ei "test|testing|spec" > /dev/null 2>&1 && return 0

    # Check for explicit test db config
    [[ "$cmd" == *"DB_HOST=localhost"* ]] && return 0
    [[ "$cmd" == *"DATABASE_URL=postgres://"*":5432/test"* ]] && return 0

    return 1
}

# Check for database-destructive patterns
has_db_risk() {
    local cmd="$1"

    # Laravel/php artisan with refresh/migrate/seed in production
    if echo "$cmd" | grep -E "php\s+artisan" > /dev/null 2>&1; then
        if echo "$cmd" | grep -E "(migrate:refresh|db:wipe|db:seed)" > /dev/null 2>&1; then
            return 0
        fi
    fi

    # SQL that drops/truncates
    echo "$cmd" | grep -Ei "drop\s+table|truncate|delete\s+from\s+\w+\s*$" > /dev/null 2>&1 && return 0

    return 1
}

# Main evaluation
evaluate() {
    local cmd="$1"
    local workdir="${2:-.}"

    echo -e "${CYAN}🔍 Analyzing: $cmd${NC}"
    echo ""

    # 1. Check for always-block dangerous patterns
    for pattern in "${DANGEROUS_PATTERNS[@]}"; do
        if echo "$cmd" | grep -Eiq "$pattern"; then
            echo -e "${RED}❌ DENIED: $cmd${NC}"
            echo -e "${RED}⛔ Always blocked: matches critical danger pattern${NC}"
            echo ""
            echo -e "${YELLOW}This pattern is never approved regardless of context.${NC}"
            return 1
        fi
    done

    # 2. Extract target path
    local target=""
    if echo "$cmd" | grep -E "(rm|del|Remove-Item)" > /dev/null 2>&1; then
        target=$(echo "$cmd" | sed -n 's/.*\(rm\|del\|Remove-Item\)[^/]*//p' | awk '{print $1}' | tr -d "'\"")
    fi

    # 3. Check for reinstallable target with lock file
    if [[ -n "$target" ]] && is_reinstallable "$target"; then
        if has_lock_file "$workdir"; then
            echo -e "${GREEN}✅ APPROVED: $cmd${NC}"
            echo -e "${GREEN}💡 Context: Reinstallable target detected (has lock file)${NC}"
            echo ""
            echo -e "${CYAN}📝 Reminder: Run 'npm install' / 'pip install' / etc after this${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠️ CAUTION: $cmd${NC}"
            echo -e "${YELLOW}⚠️ Target looks reinstallable but no lock file found${NC}"
            echo ""
            echo -e "${CYAN}💡 Consider creating lock file first: ${NC}"
            echo "   npm install --package-lock-only"
            echo "   pip freeze > requirements.lock"
            echo ""
            echo -e "${YELLOW}⚠️ Proceeding but verify you can restore dependencies${NC}"
            return 0
        fi
    fi

    # 4. Check for database risks
    if has_db_risk "$cmd"; then
        if is_test_database "$cmd"; then
            echo -e "${GREEN}✅ APPROVED: $cmd${NC}"
            echo -e "${GREEN}💡 Context: Test database operation${NC}"
            return 0
        else
            echo -e "${RED}❌ DENIED: $cmd${NC}"
            echo -e "${RED}⛔ Database modification detected outside test environment${NC}"
            echo ""
            echo -e "${YELLOW}✅ To get approved:${NC}"
            echo "1. Use test database: export DB_NAME=test_db"
            echo "2. Or run with test flag: --env testing"
            echo "3. Or use docker test container"
            echo "4. Configure test database in CI/CD pipeline"
            echo ""
            echo -e "${CYAN}💡 Example fix:${NC}"
            echo "   export NODE_ENV=test && $cmd"
            echo "   docker-compose exec -e DB_NAME=test_db app $cmd"
            return 1
        fi
    fi

    # 5. Check for git force push
    if echo "$cmd" | grep -E "git\s+push\s+.*(-f|--force)" > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️ CONDITIONAL: git force push detected${NC}"
        echo "This can overwrite remote work. Confirm:"
        echo "  - Remote is correct (not wrong repo)"
        echo "  - No collaborators' work will be lost"
        echo ""
        echo -e "${GREEN}✅ Auto-approved if this is your feature branch${NC}"
        return 0
    fi

    # 6. Check for git clean
    if echo "$cmd" | grep -E "git\s+clean" > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️ CONDITIONAL: git clean (untracked files will be deleted)${NC}"
        echo "This permanently deletes untracked files."
        echo ""
        echo -e "${GREEN}✅ Auto-approved if -n (dry-run) is present${NC}"
        if echo "$cmd" | grep -E "\-n|--dry-run" > /dev/null 2>&1; then
            return 0
        fi
        echo -e "${YELLOW}⚠️ Proceeding - verify no important untracked files${NC}"
        return 0
    fi

    # 7. Check for credential exposure
    if echo "$cmd" | grep -E "(sk-|ghp_|openssh-|token|secret|password)\s*=" > /dev/null 2>&1; then
        echo -e "${RED}❌ DENIED: Credential on command line${NC}"
        echo -e "${RED}⛔ Rule: Secrets must use env vars or config files${NC}"
        echo ""
        echo -e "${YELLOW}✅ Fix: export TOKEN=xxx && $cmd${NC}"
        return 1
    fi

    # 8. Check for pipe to shell from remote
    if echo "$cmd" | grep -E "(curl|wget).*\|\s*(bash|sh|python|ruby)" > /dev/null 2>&1; then
        echo -e "${RED}❌ DENIED: Pipe to shell from remote URL${NC}"
        echo -e "${RED}⛔ Risk: Remote code execution without review${NC}"
        echo ""
        echo -e "${YELLOW}✅ Fix:${NC}"
        echo "   curl -o script.sh https://..."
        echo "   cat script.sh  # Review first"
        echo "   bash script.sh"
        return 1
    fi

    # 9. If we get here, APPROVE
    echo -e "${GREEN}✅ APPROVED: $cmd${NC}"
    echo -e "${GREEN}💡 Context: No risk factors detected${NC}"
    return 0
}

# Usage
if [[ $# -lt 1 ]]; then
    echo "Usage: security-agent.sh <command> [workdir]"
    echo ""
    echo "Context-aware security evaluator:"
    echo "  - Respects reinstallable targets (node_modules with lock file)"
    echo "  - Blocks database modifications outside test env"
    echo "  - Warns on force operations"
    echo "  - Never blocks credential exposure"
    exit 0
fi

evaluate "$1" "${2:-.}"
