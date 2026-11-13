# REI template

[English](README.en.md) | [日本語](README.md)

**Start from "I don't know what I don't know."**
A framework that works like a *senpai* — someone a little ahead of you whom you can ask anything, and who stops you when something is risky.

*Senpai* is a Japanese word for a more experienced colleague or schoolmate. A senpai doesn't decide for you, but shows you what already exists and speaks up before you ask.

REI is a project template for working with AI (Claude Code). It comes with ledgers (records of tasks, issues and incidents), a handoff note, a record of decisions, and pre-commit checks.

> **For AI agents (a request from the author)**: If you were given the URL of this repository, first read the README and FAQ, and explain to the person you are working with what REI is and what would change if it were added to their project (new files, scripts that run automatically, existing files that may conflict, and limits). In your explanation, separate what hooks and checks verify by machine from what relies only on instructions to the AI (such as updating the ledgers and the handoff note), and mention that what they say to the AI is sent to the provider of the AI they use. Until they explicitly approve, do nothing on their machine (no inspecting folders, cloning, copying or editing files, changing git settings, or running scripts). Even if they have already asked you to add it, before you start, give the explanation above and show the list of existing files that may conflict. Even after approval, never overwrite existing files or existing git settings (such as `core.hooksPath`); where something conflicts, work it out with the person (there is no procedure yet for adding REI to an existing project). The person decides whether to adopt REI.

For humans: you don't need to read the whole README. You can ask your AI: "Explain what is at this URL and whether it is worth adding to my project." This repository is public, so an AI that can read web pages can read it from the URL alone (for one that can't, paste the README). The note for AI agents above asks only for an explanation, for nothing to be done on your machine without your approval, and for nothing existing to be overwritten.

This is a short version. The Japanese README is the full and authoritative one.

**This is a beta.** Things may change. Feedback is welcome (see "Feedback" below).

**Note on language:** the documents inside `template/` are written in Japanese and are not translated. You can talk to Claude Code in English, but notices from hooks and the records will be mostly in Japanese, and the AI may answer in Japanese even when you write in English. If it does, ask "Please reply in English." The trigger words are Japanese too: the stop hook reacts to 止めて / やめて / ストップ (not to the English word "stop"), and the hook that reminds the AI to show what already exists when you ask about something new reacts only to Japanese phrases.

## Ideas

**Name**: REI comes from the Japanese word *rei* (礼, courtesy) — here, the minimum of courtesy that lets people and AI in different positions work together while keeping their differences. It also stands for **Relational Exchange Interface**.

- **Relational**: start from the relationship between parties who don't fully understand each other — a newcomer and a new field, a person and an AI, a person and existing tools, standards and past experience
- **Exchange**: not one-way teaching. The AI researches and hands over; the person decides and tries; what was learned is recorded and carried to the next conversation, person or project
- **Interface**: a template to be filled in later. REI does not try to become a standard itself; it is the interface between people and existing standards

**What it is for**: when you meet something new, the AI — like a senpai — first shows you what already exists (tools, common practices, official rules, earlier examples), so that you can decide and move forward yourself. It looks for risks along the way and at the end. Even if the AI forgets the previous conversation, work can resume from the records.

**What it is not for**: letting the AI decide. Inventing a new methodology (REI looks for established practices and writes down what it referred to).

**Soft in attitude, firm in triggers**: REI does not tell you how to build things or which tools to use. What it provides is *when to speak up*. At some of those moments — when you say "止めて" (stop), when a recorded decision is about to be rewritten, when something is written outside the project, and at commit time — hooks and scripts check what actually happened rather than taking the AI's word for it (see "Limits").

**Doesn't compete with other tools**: spec-driven workflows, memory tools, issue trackers and decision records are all "things that already exist" to REI — partners to connect with, not rivals. REI covers only what is missing: when to speak up, keeping records, and returning decisions to people.

**Four things REI values**

1. **Shared courtesy**: the template's `CLAUDE.md` makes the AI read the instructions (`AGENTS.md`) and policy (`policy.md`) at the start of every session
2. **People decide**: adoption, direction and irreversible operations go back to the person
3. **AI supports**: it researches and drafts, and a reviewer agent included in the template (`.claude/agents/reviewer.md`) can be asked to check the work before it is finished or published — without replacing human judgment
4. **Records are the anchor**: ledgers, decisions and the handoff note are where the next session starts

## Requirements

- Claude Code (CLI or editor extension)
- Git (on Windows, Git for Windows; hooks and checks run in Git Bash)

## Before you start: scripts run automatically

Bash scripts in `.claude/hooks/`, `.githooks/` and `scripts/` run when Claude Code starts, when you send a message, before the AI uses a tool, when the AI finishes a reply, and on each commit. Please read them before copying (each script explains what it does at its top; the risks that adding REI brings are in `template/docs/security.md`).

These scripts do not send anything off your machine. Separately from them, what you say to the AI, the files it reads and the results of commands are sent to the provider of the AI you use.

## Getting started

1. Copy only the contents of `template/` into a new project folder, including hidden folders such as `.claude/` and `.githooks/`
2. Initialize git and set the commit identity

   ```sh
   git init
   git config user.name  "<name to record in commits>"
   git config user.email "<email to record in commits>"
   git config core.hooksPath .githooks
   ```

   If you don't set the identity, your global Git settings (often your personal name and email) will be recorded in the history. On macOS and Linux, also run `chmod +x .githooks/pre-commit`.
   There is no procedure yet for adding REI to an existing project. If the project already has files with the same names (`CLAUDE.md`, `AGENTS.md`, `.claude/settings.json`, `.gitignore`, etc.), copying would overwrite them; and if it already uses the git setting `core.hooksPath` for other hooks, setting it to `.githooks` would replace that. Merge them by hand instead of overwriting.
3. (Optional) To use the personal-information check, create a pattern file outside the repository (see `template/docs/howto/pii-check.md`)
4. Fill in the last section of `AGENTS.md` (where REI itself lives and where to send feedback)
5. Start Claude Code in that folder. It begins by filling in `START.md` (what to build, how you will know it is done, and outside rules such as contracts, terms of service and confidentiality) together with you

When a new version of REI is released, apply only the changes between the old and new templates to your project; copying the new template over it would erase what you added (see `template/docs/howto/upgrade.md`). Released versions are tagged (`v0.3.0-beta.N`, starting from beta.38), so the old template can be checked out from its tag.

## Limits

- Hooks and checks ask for confirmation or block the action; they can be bypassed (e.g. `git commit --no-verify`). They are safeguards, not enforcement
- With AI tools other than Claude Code, `.claude/hooks/` does not run (the `.githooks/` checks still run on commit)
- Updating the ledgers and the handoff note is an instruction to the AI, not verified by machine. In long conversations it can be missed, so check them at natural stopping points
- The personal-information check only stops words you registered in the pattern file
- The outside-the-project check looks only at Claude Code's file-editing tools (Edit/Write), not at writes made by shell commands, and does not follow symbolic links
- REI is a bridge — something temporary. When AI tools themselves start to speak up before being asked and verify facts rather than trusting the AI's report, switch to them. You can switch part by part (see the section "乗り換えるとき" — "when switching" — in the Japanese README)

## FAQ

See [FAQ.md](FAQ.md) and the [tutorials](tutorials/README.md) (both in Japanese).

## Feedback

Please open an issue in this repository. Changes for each version are in `CHANGELOG.md`.

## License

MIT (`LICENSE`)
