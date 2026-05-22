#!/usr/bin/env python3
"""
UserPromptSubmit hook: fires before every user message.
Injects SDD task-size classification reminder into model context.
"""
import json, sys

# Accept optional event name argument (default: UserPromptSubmit)
# Usage: python3 sdd_task_check.py [EventName]
event_name = sys.argv[1] if len(sys.argv) > 1 else "UserPromptSubmit"

msg = (
    "[SDD TASK SIZE CHECK] Classify the task BEFORE any work: "

    "CONSULTA = question / lookup / concept / research / error explanation → answer directly. "
    "  ENGRAM SAVE if Odoo context: models, modules, views, fields, ORM, XML, QWeb, OWL, "
    "  sequences, security, controllers, errors, discoveries — save non-obvious findings. "
    "  NO save if generic question unrelated to Odoo or the current project. "

    "SENCILLO = 1 file, 1-2 targeted changes, punctual bug fix → proceed directly + ENGRAM SAVE after (mandatory). "

    "MODERADO = 2+ files / new logic / new model with views → STOP, run /sdd-ff FIRST. Never inline. "

    "COMPLEJO = new module / multi-file architecture / cross-module flow → STOP, run /sdd-ff FIRST. Never inline. "

    "CRITICAL: NEVER read Odoo source, SSH into servers, or write inline code for Moderado/Complejo. "
    "If unsure about size → escalate to next level."
)

if event_name == "PostCompact":
    print(json.dumps({"systemMessage": msg}))
else:
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": event_name,
            "additionalContext": msg
        }
    }))
