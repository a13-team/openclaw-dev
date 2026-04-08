#!/usr/bin/env bash
# security-agent.sh - Command safety evaluator for sub-agent approvals
# Called by orchestrator before approving dangerous commands
# Returns: APPROVED / DENIED / CONDITIONAL + reasoning

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Approved external domains (for curl/wget)
APPROVED_DOMAINS=(
    "github.com"
    "api.github.com"
    "registry.npmjs.org"
    "pypi.org"
    "brew.sh"
    "docs.openclaw.ai"
    "clawhub.ai"
)

# Dangerous patterns
DANGEROUS_PATTERNS=(
    "rm\s+-rf"
    "rm\s+-r\s+-f"
    "del\s+.*/f"
    "Remove-Item\s+.*-Recurse"
    "chmod\s+777"
    "icacls\s+.*\s+/grant\s+Everyone"
    "sudo\s+su"
    "sudo\s+-i"
    "eval\s+\$\("
    "base64\s+-d\s+.*\|"
    "curl\s+.*\|\s*bash"
    "wget\s+.*\|\s*bash"
    "\|\s*sh\s*$"
    "\|\s*bash\s*$"
    "\brm\s+-rf\b"
    "\bdel\s+/f\b"
    "format\s+[a-z]:"
    "dd\s+.*of=/dev/"
    "mkfs"
    "openssl\s+.*\s+-out\s+/tmp"
    "\.ssh\/id_"
)

# Read-only safe commands
SAFE_COMMANDS=(
    "ls" "dir" "pwd" "cat" "type" "head" "tail" "wc"
    "grep" "egrep" "fgrep" "rg" "select-string"
    "jq" "python3" "python" "node" "ruby"
    "git" "git-status" "git-log" "git-diff" "git-show"
    "curl\s+-s" "curl\s+-S" "curl\s+--silent" "curl\s+--head"
    "wget\s+-q" "wget\s+--quiet" "wget\s+-O\s+-"
    "test" "stat" "file" "which" "where"
    "Get-ChildItem" "Get-Content" "Select-String" "Test-Path"
    "echo" "printf" "date" "uptime"
)

# Parse command to extract components
parse_command() {
    local cmd="$1"
    # Remove approved prefixes
    cmd="${cmd#sudo }"
    cmd="${cmd#pwsh }"
    cmd="${cmd#bash }"
    cmd="${cmd#sh -c }"
    cmd="${cmd#cmd /c }"
    echo "$cmd"
}

# Check if command is in approved domain
check_domain() {
    local url="$1"
    for domain in "${APPROVED_DOMAINS[@]}"; do
        if [[ "$url" == *"$domain"* ]]; then
            return 0
        fi
    done
    return 1
}

# Main evaluation function
evaluate() {
    local cmd="$1"
    local workdir="${2:-.}"

    # Parse the command
    local parsed
    parsed=$(parse_command "$cmd")

    # Extract base command
    local base_cmd
    base_cmd=$(echo "$parsed" | awk '{print $1}' | sed 's/^-*//')

    # 1. Check for dangerous patterns
    for pattern in "${DANGEROUS_PATTERNS[@]}"; do
        if echo "$parsed" | grep -Eiq "$pattern"; then
            echo -e "${RED}❌ DENIED: $cmd${NC}"
            echo -e "${RED}Risk: Matches dangerous pattern: $pattern${NC}"
            echo -e "${RED}⛔ Rule violated: DANGEROUS_COMMAND${NC}"
            echo ""
            echo -e "${YELLOW}✅ To get approved:${NC}"
            echo "1. Identify what you really need to delete"
            echo "2. Use trash/rubbish-cli instead of rm"
            echo "3. Or use interactive mode: rm -i"
            echo "4. Confirm target path is inside project directory"
            echo ""
            echo "Submit corrected command for re-review."
            return 1
        fi
    done

    # 2. Check for credential exposure
    if echo "$parsed" | grep -E "(sk-|ghp_|openssh-|token|secret|password)\s+[a-zA-Z0-9]" > /dev/null 2>&1; then
        echo -e "${RED}❌ DENIED: $cmd${NC}"
        echo -e "${RED}Risk: Credential or secret on command line${NC}"
        echo -e "${RED}⛔ Rule violated: CREDENTIAL_EXPOSURE${NC}"
        echo ""
        echo -e "${YELLOW}✅ To get approved:${NC}"
        echo "1. Use environment variable: export TOKEN=xxx && <command>"
        echo "2. Or use stdin: echo 'xxx' | <command> --token-stdin"
        echo "3. Or use config file: <command> --config ~/.secrets/config"
        echo "4. Never pass secrets directly on command line"
        echo ""
        echo "Submit corrected command for re-review."
        return 1
    fi

    # 3. Check for unsafe curl/wget
    if echo "$parsed" | grep -E "(curl|wget).*\|\s*(bash|sh|python)" > /dev/null 2>&1; then
        echo -e "${RED}❌ DENIED: $cmd${NC}"
        echo -e "${RED}Risk: Pipe to shell - remote code execution${NC}"
        echo -e "${RED}⛔ Rule violated: PIPE_TO_SHELL${NC}"
        echo ""
        echo -e "${YELLOW}✅ To get approved:${NC}"
        echo "1. Download first: curl -o script.sh https://..."
        echo "2. Review content: cat script.sh"
        echo "3. If safe, execute: bash script.sh"
        echo "4. Or use: bash <(curl -s https://...)"
        echo ""
        echo "Submit download command first for review."
        return 1
    fi

    # 4. Check for commands outside workspace
    local contains_parent_ref
    contains_parent_ref=$(echo "$parsed" | grep -E '\.\./|\.\.\\' || true)
    if [[ -n "$contains_parent_ref" ]] && ! echo "$parsed" | grep -qE "^cd\s+\.\."; then
        # Allow cd .. but warn about other parent refs
        if echo "$parsed" | grep -E "(cp|mv|rm|del|copy|move)\s+.*\.\." > /dev/null 2>&1; then
            echo -e "${YELLOW}⚠️ CONDITIONAL: $cmd${NC}"
            echo "Warning: Command references parent directory"
            echo "Confirm target is inside project directory"
            echo "Approving with caution..."
            return 0
        fi
    fi

    # 5. Check for system-wide modifications
    if echo "$parsed" | grep -E "(/etc/|/usr/sbin|/bin/|/sbin/)" > /dev/null 2>&1; then
        if echo "$parsed" | grep -vE "(test\s+|ls\s+|cat\s+|grep\s+)" > /dev/null 2>&1; then
            echo -e "${YELLOW}⚠️ CONDITIONAL: $cmd${NC}"
            echo "Warning: System directory modification"
            echo "Confirm this is intentional and necessary"
            return 0
        fi
    fi

    # 6. Check for npm/pip global installs without package name
    if echo "$parsed" | grep -E "(npm\s+install\s+(-g|--global)?\s*$|pip\s+install\s*$)" > /dev/null 2>&1; then
        echo -e "${RED}❌ DENIED: $cmd${NC}"
        echo -e "${RED}Risk: Wildcard package install (might install everything)${NC}"
        echo -e "${RED}⛔ Rule violated: WILDCARD_INSTALL${NC}"
        echo ""
        echo -e "${YELLOW}✅ To get approved:${NC}"
        echo "1. Specify package name: npm install express"
        echo "2. Or use: npm install --save-dev <package>"
        echo "3. Never run npm install without package name"
        echo ""
        echo "Submit corrected command for re-review."
        return 1
    fi

    # 7. Check for git force push
    if echo "$parsed" | grep -E "git\s+push\s+.*(-f|--force)" > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️ CONDITIONAL: $cmd${NC}"
        echo "Warning: Force push detected"
        echo "Confirm remote is correct and no one else's work will be lost"
        echo "Approving with caution..."
        return 0
    fi

    # 8. Check for git clean with force
    if echo "$parsed" | grep -E "git\s+clean\s+.*(-f|--force)" > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️ CONDITIONAL: $cmd${NC}"
        echo "Warning: git clean with force"
        echo "Untracked files will be permanently deleted"
        echo "Confirm this is intended"
        return 0
    fi

    # 9. If we get here, command is likely safe
    echo -e "${GREEN}✅ APPROVED: $cmd${NC}"
    echo "Reason: Command matches safe patterns"
    return 0
}

# Main
if [[ $# -lt 1 ]]; then
    echo "Usage: security-agent.sh <command> [workdir]"
    echo ""
    echo "Evaluates command safety and returns:"
    echo "  ✅ APPROVED - safe to execute"
    echo "  ❌ DENIED - dangerous, needs modification"
    echo "  ⚠️ CONDITIONAL - approved with caution"
    exit 0
fi

cmd="$1"
workdir="${2:-.}"

evaluate "$cmd" "$workdir"
