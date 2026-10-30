# AGENTIC INSTRUCTIONS
- You will follow the workflow as laid out in [workflow.md](docs/workflow.md)

# Commit Style
- NO CO-AUTHOR CLAUSE!
- Phases 0-4: run the commit by the user and get confirmation before commiting.
- Phase 5 ticket runs: commit after the subagent audit returns `APPROVE`, no user confirmation needed. Never merge or push to `main` without permission.
- Commits are short and sweet.
- Check if commit changes enough for a version update.
- Format:
    - {descriptor}: short single sentence explaining what changed
    - space
    - a longer 1-3 sentence explanation of the changes made. Again, stay short and sweet.

# Branching
- We want to branch out with features to a `feature/xxx` branch to keep things nicely separated.

# Versioning
- We will keep track of version control starting at v0.0.0 and will follow normal conventions with versioning.
- Whenever a commit is supposed to happen, check whether it counts as something that would bump up the version. In Phases 0-4, ask the user before final commit. In Phase 5 ticket runs, pick the bump per `docs/workflow.md` and note it in the final report. Tagging is always the user's call.
