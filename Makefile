.PHONY: pr merge sync status help

# Create PR from current branch to IceSimulation
pr:
	@echo "Creating PR from $(shell git branch --show-current) → IceSimulation..."
	gh pr create --base IceSimulation --title "$(title)" --body "$(body)"

# Merge PR by number (uses admin bypass for solo work)
merge:
	@echo "Merging PR #$(num)..."
	gh pr merge $(num) --squash --admin --delete-branch

# Sync IceSimulation with remote
sync:
	git checkout IceSimulation && git pull origin IceSimulation

# Show PR list
status:
	gh pr list --base IceSimulation

# Quick PR: push current branch and create PR
quick-pr:
	@BRANCH=$(shell git branch --show-current); \
	if [ "$$BRANCH" = "IceSimulation" ] || [ "$$BRANCH" = "master" ]; then \
		echo "Error: Create a feature branch first (git checkout -b feature/name)"; \
		exit 1; \
	fi; \
	git push -u origin $$BRANCH && \
	gh pr create --base IceSimulation

help:
	@echo "Usage:"
	@echo "  make quick-pr          Push branch and create PR (from feature branch)"
	@echo "  make merge num=N       Merge PR #N (e.g., make merge num=5)"
	@echo "  make status            List open PRs"
	@echo "  make sync              Pull latest IceSimulation"
	@echo ""
	@echo "Workflow:"
	@echo "  git checkout -b feature/my-feature"
	@echo "  # make changes, git add . && git commit -m 'message'"
	@echo "  make quick-pr"
	@echo "  make merge num=<PR_NUMBER>"
