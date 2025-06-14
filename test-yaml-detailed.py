#!/usr/bin/env python3
import yaml
import sys

file_path = ".github/actions/build-apps/action.yml"

try:
    with open(file_path, 'r') as f:
        content = f.read()
        yaml.safe_load(content)
    print(f"✅ {file_path} - YAML syntax is valid!")
    
    # Also show line count for reference
    lines = content.count('\n')
    print(f"   Total lines: {lines}")
    
    sys.exit(0)
except yaml.YAMLError as e:
    print(f"❌ {file_path} - YAML error: {e}")
    
    # Try to find the problematic line
    if hasattr(e, 'problem_mark'):
        mark = e.problem_mark
        print(f"   Error at line {mark.line + 1}, column {mark.column + 1}")
        
        # Show context around the error
        lines = content.split('\n')
        start = max(0, mark.line - 2)
        end = min(len(lines), mark.line + 3)
        
        print("\n   Context around error:")
        for i in range(start, end):
            prefix = ">>>" if i == mark.line else "   "
            print(f"   {prefix} {i+1}: {lines[i]}")
    
    sys.exit(1)
except Exception as e:
    print(f"❌ {file_path} - Error: {e}")
    sys.exit(1)
