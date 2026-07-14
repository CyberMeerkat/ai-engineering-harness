---
name: incident-report-logger
description: Produce incident reports in a fixed operational format for clients, outages, and remediation summaries. Use when the user asks to log, write, or format an incident report.
---

## Purpose
Use this skill when the user wants an incident report, outage summary, post-incident log, or operational incident write-up.

## Required output format
Always output the incident report in exactly this structure and order, using the same section names:

Client: <client name>
Topic: <incident topic>

Incident Date: <date>
Status: <status>
Severity: <severity>
Time Alerted: <time>
Time Resolved: <time>
Total Time to Fix: <duration>

Overview
<short paragraph>

Root Cause
<short paragraph>

Impact
• <impact item>
• <impact item>
• <impact item>

Resolution
<short paragraph>

Key Risks
• <risk item>
• <risk item>
• <risk item>

Recommendations
<short paragraph>

## Formatting rules
- Keep the field labels exactly as written: `Client`, `Topic`, `Incident Date`, `Status`, `Severity`, `Time Alerted`, `Time Resolved`, `Total Time to Fix`, `Overview`, `Root Cause`, `Impact`, `Resolution`, `Key Risks`, `Recommendations`.
- Preserve the blank lines between the header block and each section.
- Use the bullet character `•` for `Impact` and `Key Risks` items.
- Write in concise operational language.
- Do not add extra sections unless the user explicitly requests them.
- If details are missing, ask only for the missing fields required to complete the format.

## Content guidance
- `Overview`: summarize what failed, where, and the restoration path.
- `Root Cause`: identify the technical trigger and failure propagation.
- `Impact`: list user-visible and platform-visible consequences.
- `Resolution`: describe the remediation that restored service.
- `Key Risks`: focus on operational gaps exposed by the incident.
- `Recommendations`: provide a concise prevention-oriented summary.

## Example style
Match this style closely:
- direct
- factual
- terse but complete
- oriented toward infrastructure and operational reporting

## Invocation guidance
This skill is appropriate for requests like:
- "log an incident report"
- "write a postmortem summary"
- "format this outage note"
- "turn these notes into an incident report"
