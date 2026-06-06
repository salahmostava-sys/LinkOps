const fs = require('node:fs');
const path = require('node:path');

function walk(dir) {
    let results = [];
    const list = fs.readdirSync(dir);
    list.forEach(file => {
        file = dir + '/' + file;
        const stat = fs.statSync(file);
        if (stat?.isDirectory()) {
            results = results.concat(walk(file));
        } else { 
            results.push(file);
        }
    });
    return results;
}

const allFiles = walk('scripts').concat(['fix.js', 'fix_auth_role.js', 'fix_remaining_auth_uid.js', 'generate_fk_indexes.js']);

allFiles.forEach(file => {
    if (!fs.existsSync(file)) return;
    let content = fs.readFileSync(file, 'utf8');
    let original = content;

    // Remove trailing whitespaces for all scripts (.ps1, .js, .py)
    if (file.endsWith('.ps1') || file.endsWith('.js') || file.endsWith('.py')) {
        content = content.replace(/[ \t]+$/gm, '');
    }

    // Fix node imports
    if (file.endsWith('.js')) {
        content = content.replaceAll("require('fs')", "require('node:fs')");
        content = content.replaceAll('require("fs")', 'require("node:fs")');
        content = content.replaceAll("require('child_process')", "require('node:child_process')");
        content = content.replaceAll('require("child_process")', 'require("node:child_process")');
    }

    // Replace replace with replaceAll where flagged
    if (file.includes('generate_fk_indexes.js')) {
        content = content.replaceAll(String.raw`sql.replace(/--.*\n/g, '')`, String.raw`sql.replaceAll(/--.*\n/g, '')`);
    }
    
    // Fix python function
    if (file.endsWith('fix_migrations.py')) {
        content = content.replaceAll('def replace_policy(content):', 'def replace_policy(content=content):');
        content = content.replaceAll('def replace_trigger(content):', 'def replace_trigger(content=content):');
    }

    // Replace Write-Host with Write-Output in PS1
    if (file.endsWith('.ps1')) {
        content = content.replaceAll('Write-Host', 'Write-Output');
        content = content.replaceAll('$matches ', '$matchRes ');
        content = content.replaceAll('$matches[', '$matchRes[');
    }

    if (content !== original) {
        fs.writeFileSync(file, content);
        console.log('Fixed', file);
    }
});
