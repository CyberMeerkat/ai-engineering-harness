// strip-jwt.mjs — tool.execute.before enforcement plugin
// BLOCKS any Bash command containing a raw JWT (eyJ... pattern) so that
// ephemeral tokens never get cached/allow-listed in permission config.
// Ported from the Claude Code strip-jwt-permissions.sh hook.

// Detect JWT pattern: three base64url-encoded segments joined by dots,
// starting with eyJ, appearing after TOKEN=/Bearer/Authorization: context.
// Matched conservatively to avoid false positives on unrelated "eyJ" text.
const JWT_IN_AUTH_PATTERN = /(TOKEN=|Bearer\s+|Authorization:[^'"]*Bearer\s+)"?eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/;

export const StripJwtPermissions = async ({ project, client, $, directory, worktree }) => {
  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool !== "bash") return;

      const command = output.args?.command || "";
      if (JWT_IN_AUTH_PATTERN.test(command)) {
        throw new Error(
          "BLOCKED: Bash command contains a JWT token (eyJ pattern).\n" +
          "JWTs are ephemeral and should never be approved as a standing " +
          "permission - they accumulate in permission config and bloat lookups.\n\n" +
          "Fix: assign the token to a shell variable first, then reference it:\n" +
          "  export TOKEN=$(...)\n" +
          '  curl -H "Authorization: Bearer $TOKEN" ...'
        );
      }
    },
  };
};
