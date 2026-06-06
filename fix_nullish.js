const fs = require('node:fs');

function walk(dir) {
    let results = [];
    const list = fs.readdirSync(dir);
    list.forEach(file => {
        file = dir + '/' + file;
        const stat = fs.statSync(file);
        if (stat?.isDirectory()) {
            if(!file.includes('node_modules') && !file.includes('.git') && !file.includes('dist')) {
                results = results.concat(walk(file));
            }
        } else if(file.endsWith('.ts') || file.endsWith('.tsx')) {
            results.push(file);
        }
    });
    return results;
}

const allFiles = walk('frontend');

allFiles.forEach(file => {
    let content = fs.readFileSync(file, 'utf8');
    let original = content;

    // String(x || '') -> String(x ?? '')
    content = content.replace(/String\((.*?)\s*\|\|\s*''\)/g, "String($1 ?? '')");

    // Replace some obvious ones where it is an object property:
    content = content.replace(/([a-zA-Z0-9_?.[\]]+)\s*\|\|\s*''/g, (match, p1) => {
        // If it looks like property access, use ??
        if(p1.includes('.') || p1.includes('?')) {
            return `${p1} ?? ''`;
        }
        return match;
    });

    if (content !== original) {
        fs.writeFileSync(file, content);
        console.log('Fixed || to ?? in', file);
    }
});
