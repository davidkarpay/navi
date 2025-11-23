# Pull Request Management Guide

## 🔗 Quick Actions

### Create Pull Request

**Option 1: Via GitHub Web UI** (Recommended)
1. Visit: https://github.com/davidkarpay/navi/pull/new/claude/agent-team-status-reporting-01Lrcrb19zYcjrxVsKUDmU2o
2. Use the PR description from `PR_DESCRIPTION.md`
3. Set base branch to: `main`
4. Title: `Development Team Action Plans & Status Reports`
5. Click "Create Pull Request"

**Option 2: Via GitHub CLI** (if available)
```bash
# Create PR with description from file
gh pr create \
  --base main \
  --head claude/agent-team-status-reporting-01Lrcrb19zYcjrxVsKUDmU2o \
  --title "Development Team Action Plans & Status Reports" \
  --body-file PR_DESCRIPTION.md
```

---

## 📋 PR Checklist

Before creating the PR, verify:
- [x] All commits pushed to remote
- [x] Branch is up to date
- [x] No merge conflicts
- [x] PR description ready
- [x] Success criteria defined

After creating the PR:
- [ ] Add labels (if applicable): `documentation`, `planning`, `enhancement`
- [ ] Assign reviewers
- [ ] Link any related issues
- [ ] Add to project board (if using)

---

## 🔍 Managing the PR

### View PR Details
```bash
# List all PRs
gh pr list

# View specific PR
gh pr view <PR-number>

# View PR in browser
gh pr view <PR-number> --web
```

### Update the PR
```bash
# Make changes to your branch
git add <files>
git commit -m "Update action plans based on feedback"
git push

# The PR will automatically update
```

### Get PR Status
```bash
# Check CI/CD status
gh pr checks <PR-number>

# View PR reviews
gh pr reviews <PR-number>
```

### Respond to Review Comments
```bash
# View review comments
gh pr diff <PR-number>

# Add review comment
gh pr review <PR-number> --comment -b "Updated based on feedback"

# Request re-review
gh pr review <PR-number> --request-reviewer @username
```

---

## ✅ Merging the PR

### Pre-Merge Checklist
- [ ] All review comments addressed
- [ ] CI/CD checks passing (if configured)
- [ ] Approval received from reviewer(s)
- [ ] No merge conflicts
- [ ] Ready to start execution

### Merge Options

**Option 1: Merge via GitHub UI**
1. Go to PR page
2. Click "Merge pull request"
3. Choose merge type:
   - **Merge commit**: Preserves all commits (recommended for this PR)
   - **Squash and merge**: Combines into single commit
   - **Rebase and merge**: Linear history

**Option 2: Merge via CLI**
```bash
# Merge PR
gh pr merge <PR-number> --merge

# Squash merge
gh pr merge <PR-number> --squash

# Rebase merge
gh pr merge <PR-number> --rebase

# Auto-delete branch after merge
gh pr merge <PR-number> --merge --delete-branch
```

### After Merging
```bash
# Switch to main branch
git checkout main

# Pull latest changes
git pull origin main

# Clean up local branch (optional)
git branch -d claude/agent-team-status-reporting-01Lrcrb19zYcjrxVsKUDmU2o
```

---

## 🔄 Common PR Operations

### Close PR Without Merging
```bash
gh pr close <PR-number> --comment "Closing because..."
```

### Reopen Closed PR
```bash
gh pr reopen <PR-number>
```

### Convert to Draft
```bash
gh pr ready <PR-number> --undo
```

### Mark as Ready for Review
```bash
gh pr ready <PR-number>
```

### Add Labels
```bash
gh pr edit <PR-number> --add-label "documentation,planning"
```

### Add Reviewers
```bash
gh pr edit <PR-number> --add-reviewer @username
```

### Add to Milestone
```bash
gh pr edit <PR-number> --milestone "v1.0"
```

---

## 📊 PR Review Process

### Request Review
```bash
# Request review from specific users
gh pr review <PR-number> --request-reviewer @user1,@user2

# Request review from team
gh pr review <PR-number> --request-team @org/team-name
```

### Approve PR
```bash
gh pr review <PR-number> --approve --body "LGTM! Great work on the action plans."
```

### Request Changes
```bash
gh pr review <PR-number> --request-changes --body "Please address the following..."
```

### Comment on PR
```bash
gh pr review <PR-number> --comment --body "Quick question about the timeline..."
```

---

## 🎯 Specific Actions for This PR

### Create the PR
```bash
# Recommended: Use GitHub web UI with this URL
open https://github.com/davidkarpay/navi/pull/new/claude/agent-team-status-reporting-01Lrcrb19zYcjrxVsKUDmU2o

# Or via CLI (copy description from PR_DESCRIPTION.md)
gh pr create \
  --title "Development Team Action Plans & Status Reports" \
  --body-file PR_DESCRIPTION.md \
  --base main
```

### Quick Review
```bash
# View files changed
git diff main...claude/agent-team-status-reporting-01Lrcrb19zYcjrxVsKUDmU2o

# View commit messages
git log main..claude/agent-team-status-reporting-01Lrcrb19zYcjrxVsKUDmU2o --oneline
```

### Verify Before Merge
```bash
# Check that all files are present
ls -la *ACTION_PLAN.md

# Verify no conflicts with main
git fetch origin main
git merge-base --is-ancestor origin/main HEAD && echo "No conflicts" || echo "Needs rebase"
```

---

## 🐛 Troubleshooting

### Problem: PR Creation Fails
**Solution**: Ensure you have GitHub CLI installed and authenticated
```bash
gh auth status
gh auth login
```

### Problem: Branch Behind Main
**Solution**: Rebase on main
```bash
git fetch origin main
git rebase origin/main
git push --force-with-lease
```

### Problem: Merge Conflicts
**Solution**: Resolve conflicts
```bash
git fetch origin main
git merge origin/main
# Resolve conflicts in editor
git add <resolved-files>
git commit
git push
```

### Problem: Can't Push
**Solution**: Check branch protection rules or force with lease
```bash
git push --force-with-lease
```

---

## 📝 PR Template (for future PRs)

Save this as `.github/pull_request_template.md`:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update
- [ ] Infrastructure/DevOps
- [ ] Planning/Strategy

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No new warnings generated
- [ ] Tests pass locally

## Related Issues
Fixes #(issue number)
```

---

## 🔗 Useful Links

- **GitHub PR Documentation**: https://docs.github.com/en/pull-requests
- **GitHub CLI Manual**: https://cli.github.com/manual/gh_pr
- **Repository PRs**: https://github.com/davidkarpay/navi/pulls
- **This Branch**: https://github.com/davidkarpay/navi/tree/claude/agent-team-status-reporting-01Lrcrb19zYcjrxVsKUDmU2o

---

## 🎓 Best Practices

1. **Keep PRs Focused**: One logical change per PR
2. **Write Clear Descriptions**: Explain what, why, and how
3. **Reference Issues**: Link related issues or tickets
4. **Request Specific Reviewers**: Tag people with relevant expertise
5. **Respond Promptly**: Address review comments quickly
6. **Keep History Clean**: Use meaningful commit messages
7. **Test Before Requesting Review**: Ensure all checks pass
8. **Be Open to Feedback**: Code review improves quality

---

**Current Branch**: `claude/agent-team-status-reporting-01Lrcrb19zYcjrxVsKUDmU2o`
**Target Branch**: `main`
**Files Changed**: 8 files, 6,213 lines added
**Status**: ✅ Ready to create PR
