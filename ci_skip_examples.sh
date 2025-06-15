#!/bin/bash
# Quick CI Skip Examples
# Demonstrates how to use the new skip functionality

echo "🎯 CI Skip Examples for r2midi"
echo "================================="

echo ""
echo "📝 Method 1: Commit Message Skip Tags"
echo "-------------------------------------"

echo "Skip tests only:"
echo '  git commit -m "Quick fix [skip tests]"'

echo ""
echo "Skip code quality only:"
echo '  git commit -m "WIP changes [skip lint]"'

echo ""
echo "Skip both tests and code quality:"
echo '  git commit -m "Fast deploy [skip tests] [skip lint]"'

echo ""
echo "🖥️  Method 2: Manual Workflow Dispatch"
echo "--------------------------------------"
echo "1. Go to GitHub → Actions → CI workflow"
echo "2. Click 'Run workflow'"
echo "3. Check desired skip options:"
echo "   ☑️ Skip pytest execution"
echo "   ☑️ Skip code quality checks"
echo "4. Click 'Run workflow'"

echo ""
echo "✅ What Still Runs When Skipping"
echo "--------------------------------"
echo "Even when you skip tests/lint, these always run:"
echo "• Security scans (safety, bandit)"
echo "• Build tests (briefcase validation)"
echo "• CI summary report"

echo ""
echo "🚀 Quick Deploy Commands"
echo "-----------------------"

# Example 1: Hotfix
echo "Hotfix (skip tests):"
echo "git add ."
echo 'git commit -m "hotfix: critical bug [skip tests]"'
echo "git push"

echo ""
# Example 2: WIP
echo "Work in progress (skip everything):"
echo "git add ."
echo 'git commit -m "wip: refactoring [skip tests] [skip lint]"'
echo "git push"

echo ""
# Example 3: Quick iteration
echo "Quick iteration (skip lint):"
echo "git add ."
echo 'git commit -m "feat: new feature [skip lint]"'
echo "git push"

echo ""
echo "💡 Pro Tips"
echo "----------"
echo "• Use 'python test_qt_local.py' to test locally first"
echo "• Skip sparingly - for urgent fixes or WIP branches"
echo "• Re-enable for production merges"
echo "• Clear commit messages explaining why you're skipping"

echo ""
echo "🔄 All code remains intact - skips only affect WHEN jobs run!"
