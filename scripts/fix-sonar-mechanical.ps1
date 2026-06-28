# Bulk SonarQube mechanical fixes
# Phase 1a: Replace `void someFunc()` with `someFunc().catch(() => {})` or `{ someFunc(); }`
# Phase 1b: parseInt â†’ Number.parseInt, parseFloat â†’ Number.parseFloat, isNaN â†’ Number.isNaN
# Phase 1c: .replace(regex_g) â†’ .replaceAll(string)
# Phase 1d: window â†’ globalThis (only specific patterns)
# Phase 1e: parentNode.removeChild(childNode) â†’ childNode.remove()

$root = "d:\MuhimmatAltawseel\frontend"

# --- Phase 1a: void operator fixes ---
# Pattern: `void someExpression` in .ts/.tsx files
# We need to be careful - only fix `void funcCall()` patterns, not `void` type annotations
$tsFiles = Get-ChildItem -Path $root -Recurse -Include "*.ts","*.tsx" | Where-Object { $_.FullName -notmatch "node_modules|dist|\.test\." }

$voidFixCount = 0
foreach ($file in $tsFiles) {
    $content = Get-Content $file.FullName -Raw
    $original = $content

    # Fix `void refetch()` or `void queryClient.invalidateQueries(...)` patterns
    # Replace `void someFunc(` with `someFunc(` when on its own line (statement)
    # For onClick handlers: `() => void func()` â†’ `() => { func(); }`

    # Pattern 1: onClick={() => void someFunc(args)}  â†’  onClick={() => { someFunc(args); }}
    $content = $content -replace 'onClick=\{?\(\)\s*=>\s*void\s+(\w[\w.]*\([^)]*\))\}?', 'onClick={() => { $1; }}'

    # Pattern 2: `void someFunc();` on its own line â†’ `someFunc();`
    # But NOT `void` as a type
    $content = $content -replace '(?m)^(\s+)void\s+([\w.]+(?:\([^)]*\)|\.\w+\([^)]*\)));?\s*$', '$1$2;'

    # Pattern 3: onRetry={() => void perfQ.refetch()} â†’ onRetry={() => { perfQ.refetch(); }}
    $content = $content -replace '\(\)\s*=>\s*void\s+([\w.]+\([^)]*\))', '() => { $1; }'

    # Pattern 4: `() => { void someFunc(); }` â†’ `() => { someFunc(); }`
    $content = $content -replace 'void\s+([\w.]+(?:\.[\w]+)*\(\))', '$1'

    if ($content -ne $original) {
        Set-Content $file.FullName $content -NoNewline
        $voidFixCount++
        Write-Output "Fixed void: $($file.Name)"
    }
}
Write-Output "Phase 1a: Fixed $voidFixCount files with void operator"

# --- Phase 1b: parseInt/parseFloat/isNaN â†’ Number.* ---
$numFixCount = 0
foreach ($file in $tsFiles) {
    $content = Get-Content $file.FullName -Raw
    $original = $content

    # parseInt( â†’ Number.parseInt(  (but not Number.parseInt or already prefixed)
    $content = $content -replace '(?<!Number\.)(?<!\w)parseInt\(', 'Number.parseInt('

    # parseFloat( â†’ Number.parseFloat(
    $content = $content -replace '(?<!Number\.)(?<!\w)parseFloat\(', 'Number.parseFloat('

    # isNaN( â†’ Number.isNaN(  (but not Number.isNaN)
    $content = $content -replace '(?<!Number\.)(?<!\w)isNaN\(', 'Number.isNaN('

    if ($content -ne $original) {
        Set-Content $file.FullName $content -NoNewline
        $numFixCount++
        Write-Output "Fixed Number.*: $($file.Name)"
    }
}
Write-Output "Phase 1b: Fixed $numFixCount files with parseInt/parseFloat/isNaN"

Write-Output "`n=== Done ==="
