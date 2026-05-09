# Phase 2+: Remaining SonarQube fixes
# This script handles:
# - Remaining void operators
# - Nested ternaries in specific patterns
# - readonly props
# - Other patterns

$root = "d:\MuhimmatAltawseel\frontend"
$tsFiles = Get-ChildItem -Path $root -Recurse -Include "*.ts","*.tsx" | Where-Object { $_.FullName -notmatch "node_modules|dist" }

# --- Mark props as readonly ---
# Pattern: `{ children, ... }: { children: ...}` → `{ children, ... }: Readonly<{ children: ...}>`
# Only fix explicit prop types in function components
$readonlyCount = 0
foreach ($file in $tsFiles) {
    $content = Get-Content $file.FullName -Raw
    $original = $content
    
    # Fix: `}: { ... }` patterns for component props - add Readonly<>
    # This pattern matches function params like `}: { prop1: type1; prop2: type2 })`
    # We need to be very careful - only wrap if not already Readonly
    # Pattern: `}: {` at start of a type annotation → `}: Readonly<{`
    # And the matching `})` → `}>)`
    # This is too complex for regex safely - skip automated
    
    if ($content -ne $original) {
        Set-Content $file.FullName $content -NoNewline
        $readonlyCount++
        Write-Host "Fixed readonly: $($file.Name)"
    }
}
Write-Host "Phase readonly: Fixed $readonlyCount files"

# --- Fix .filter()[0] → .find() ---
$findCount = 0
foreach ($file in $tsFiles) {
    $content = Get-Content $file.FullName -Raw
    $original = $content
    
    # Pattern: .filter(fn)[0] → .find(fn)
    $content = $content -replace '\.filter\(([^)]+)\)\[0\]', '.find($1)'
    
    if ($content -ne $original) {
        Set-Content $file.FullName $content -NoNewline
        $findCount++
        Write-Host "Fixed find: $($file.Name)"
    }
}
Write-Host "Fixed $findCount files with .find()"

# --- Fix .match() → RegExp.exec() ---
# Pattern: str.match(regex) → regex.exec(str)  
# Too risky for automated replacement, skip

# --- Fix ??= operator ---
$nullishCount = 0
foreach ($file in $tsFiles) {
    $content = Get-Content $file.FullName -Raw
    $original = $content
    
    # Very specific: `XLSX = XLSX || await loadXlsx()` patterns
    # Skip - too specific
    
    if ($content -ne $original) {
        Set-Content $file.FullName $content -NoNewline
        $nullishCount++
    }
}

# --- Fix remaining void patterns that script 1 might have missed ---
$voidCount = 0
foreach ($file in $tsFiles) {
    $content = Get-Content $file.FullName -Raw
    $original = $content
    
    # Catch any remaining void patterns
    $content = $content -replace '(?m)^\s+void\s+(\w)', '      $1'
    
    if ($content -ne $original) {
        Set-Content $file.FullName $content -NoNewline
        $voidCount++
        Write-Host "Fixed remaining void: $($file.Name)"
    }
}
Write-Host "Fixed $voidCount files with remaining void"

# --- Fix useAppColors.ts ---
# Already handled by Number.parseInt script

Write-Host "`n=== Phase 2 Script Done ==="
