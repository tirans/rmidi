#!/bin/bash
# Make all fix scripts executable

echo "Making all scripts executable..."

chmod +x fix_git_submodule.sh
chmod +x apply_fixes.sh
chmod +x validate_tests.py
chmod +x validate_pytest.py
chmod +x test_briefcase_builds.sh
chmod +x setup_icons.sh

echo "Done! All scripts are now executable."
echo ""
echo "Next steps:"
echo "1. Run: ./apply_fixes.sh"
echo "2. Run: python validate_pytest.py"
