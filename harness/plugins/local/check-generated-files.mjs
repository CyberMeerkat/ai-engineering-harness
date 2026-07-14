// check-generated-files.mjs — tool.execute.before enforcement plugin
// BLOCKS edits to files marked with a "GENERATED FILE - DO NOT EDIT" style
// header. Fix at the generator level or use a patching mechanism instead.
// Ported from the Claude Code check-generated-files.sh hook.

import fs from "node:fs";

const MARKER_PATTERN = /GENERATED FILE.*DO NOT EDIT|@generated|AUTO-GENERATED/i;
const HEAD_BYTES = 2048; // enough to cover a handful of header lines

export const CheckGeneratedFiles = async ({ project, client, $, directory, worktree }) => {
  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool !== "edit") return;

      const filePath = output.args?.filePath;
      if (!filePath) return;

      let head;
      try {
        const fd = fs.openSync(filePath, "r");
        const buf = Buffer.alloc(HEAD_BYTES);
        const bytesRead = fs.readSync(fd, buf, 0, HEAD_BYTES, 0);
        fs.closeSync(fd);
        head = buf.toString("utf8", 0, bytesRead);
      } catch {
        // File doesn't exist yet (new file via edit) or can't be read —
        // nothing to check.
        return;
      }

      if (MARKER_PATTERN.test(head)) {
        throw new Error(
          `BLOCKED: ${filePath} is a generated file. Do not edit directly.\n` +
          `Fix at the generator level or use a patching mechanism instead.`
        );
      }
    },
  };
};
