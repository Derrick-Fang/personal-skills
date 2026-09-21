# AGENT.md

## Project Purpose

This project is a **centralized storage and distribution repository for personal skills**.

It does exactly two things:

1. **Synced storage**: Acts as a local repository that stays in sync (pull / push) with the remote personal-skill repository on GitHub, centrally managing all skills.
2. **Distribution sync**: After a machine pulls this repository, it detects which agent harnesses (e.g., Codex, Claude Code) are installed on the machine and syncs the skills into each agent's skill management path.

## Features

### 1. Skill Storage

- All skills are stored in this repository and synced with the remote GitHub repository via git.
- This repository is the single source of truth for skills.

### 2. Detect Agent Harnesses and Distribute Skills

Provide a script (e.g., `sync.sh` or `sync.py`) with the following workflow:

1. Detect which agent harnesses exist on the current machine (by checking their characteristic commands, config directories, or skill directories), for example:
   - **Claude Code**: `~/.claude/skills/`
   - **Codex**: `~/.codex/skills/` (or its actual skill path)
2. Sync (copy or symlink) the skills from this repository into each detected agent's skill management path.
3. The sync operation is **additive only**: it only copies/updates skills into the target paths and never deletes anything from them; skills removed from the repository will not be removed from the machine.

## Constraints

- **This repository only stores and distributes skills; it does nothing else.**
- Do not implement extra features such as skill authoring-spec checks, execution, or search.
- Do not manage the configuration or installation of the agent harnesses themselves.
- The sync script only reads and writes skill-related content and must not touch any other agent configuration files.

## Usage (Recommended)

```bash
# Pull the latest skills
git pull

# Sync to all agent harnesses on this machine
./sync.sh
```

## Guidelines for Agents

- Changes to this repository should be limited to: adding/removing/updating skills, or improving the sync script.
- Do not introduce features or dependencies unrelated to skill storage and distribution.
