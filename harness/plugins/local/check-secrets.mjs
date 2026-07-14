// check-secrets.mjs — tool.execute.before enforcement plugin
// BLOCKS file writes/edits that contain hardcoded secrets.
// Ported from the Claude Code check-secrets.sh hook (14 AgentShield-inspired
// detection patterns). Skips .opencode state/data/memory paths where tokens
// may legitimately appear (e.g. session logs referencing an OAuth token).

const SECRET_PATTERNS = [
  { name: "AWS Access Key ID", re: /AKIA[0-9A-Z]{16}/ },
  { name: "AWS Secret Access Key", re: /(aws_secret_access_key|AWS_SECRET_ACCESS_KEY)\s*[=:]\s*[A-Za-z0-9/+=]{40}/ },
  { name: "GitHub token", re: /gh[posrn]_[A-Za-z0-9_]{36,}|github_pat_[A-Za-z0-9_]{22,}/ },
  { name: "API key/secret", re: /(api[_-]?key|api[_-]?secret|access[_-]?token)\s*[=:]\s*["']?[A-Za-z0-9_-]{20,}/i },
  { name: "Private key block", re: /-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----/ },
  { name: "Database connection string with password", re: /(postgres|mysql|mongodb|redis):\/\/[^:]+:[^@]+@/i },
  { name: "JWT token", re: /eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}/ },
  { name: "Slack webhook URL", re: /hooks\.slack\.com\/services\/T[A-Z0-9]{8,}\/B[A-Z0-9]{8,}\/[A-Za-z0-9]{20,}/ },
  { name: "SendGrid API key", re: /SG\.[A-Za-z0-9_-]{22}\.[A-Za-z0-9_-]{43}/ },
  { name: "Stripe API key", re: /(sk|pk)_(test|live)_[A-Za-z0-9]{20,}/ },
  { name: "Hardcoded password", re: /(password|passwd|pwd)\s*[=:]\s*["'][^"']{8,}["']/i },
];

// Paths where secret-looking content may legitimately appear (state/session
// data referencing tokens, not source/config files).
const SKIP_PATH_PATTERN = /[\\/]\.opencode[\\/](state|data|compact)[\\/]|[\\/]memory[\\/]/;

export const CheckSecrets = async ({ project, client, $, directory, worktree }) => {
  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool !== "write" && input.tool !== "edit") return;

      const filePath = output.args?.filePath || "";
      if (SKIP_PATH_PATTERN.test(filePath)) return;

      const content = output.args?.content ?? output.args?.newString ?? "";
      if (!content) return;

      for (const { name, re } of SECRET_PATTERNS) {
        // JWTs are commonly shown as examples in docs — don't block .md/.txt
        if (name === "JWT token" && /\.(md|txt)$/i.test(filePath)) continue;
        // .env/.yml/.yaml files are expected to hold real passwords/secrets
        if (name === "Hardcoded password" && /\.(env|ya?ml)$/i.test(filePath)) continue;

        if (re.test(content)) {
          throw new Error(
            `BLOCKED: ${name} detected in ${filePath || "(new file)"}\n` +
            `Secrets must be stored in .env files, never hardcoded in source or config.`
          );
        }
      }
    },
  };
};
