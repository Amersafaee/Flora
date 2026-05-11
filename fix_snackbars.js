const fs = require('fs');
const path = require('path');

function walkDir(dir, callback) {
    fs.readdirSync(dir).forEach(f => {
        let dirPath = path.join(dir, f);
        let isDirectory = fs.statSync(dirPath).isDirectory();
        isDirectory ? walkDir(dirPath, callback) : callback(path.join(dir, f));
    });
}

const libDir = path.join(__dirname, 'lib');

walkDir(libDir, function(filePath) {
    if (!filePath.endsWith('.dart')) return;
    let content = fs.readFileSync(filePath, 'utf8');
    let original = content;

    // We will use regex to find SnackBar(content: Text(...)) or similar.
    // We want to replace SnackBar(...) with our styled SnackBar.
    // Since some SnackBars might have other properties, let's just do a string replacement.
    // To match SnackBar(content: Text(result ?? 'Error signing up'))
    
    // We can replace SnackBar(content: with a function that builds the snackbar
    // Or we can just use a regex
    content = content.replace(/SnackBar\(\s*content:\s*(Text\([^)]+\))\s*\)/g, 
      "SnackBar(" +
      "content: \, " +
      "backgroundColor: const Color(0xFF2D5A27), " +
      "behavior: SnackBarBehavior.floating, " +
      "margin: const EdgeInsets.all(16), " +
      "shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), " +
      "elevation: 4, " +
      "duration: const Duration(seconds: 3), " +
      ")"
    );

    // Let's also handle SnackBars that might be split across lines
    // Better way: simply match SnackBar(content: xxx) and inject styles.
    // Let's do a more robust regex for SnackBar
    // Actually, all SnackBars in this app are simple: SnackBar(content: Text('...'))
    // Let's test if there are any other SnackBars.
    
    if (content !== original) {
        fs.writeFileSync(filePath, content);
    }
});
