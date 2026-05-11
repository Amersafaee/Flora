const fs = require('fs');

function fixFiles() {
  const files = ['lib/screens/badges_screen.dart', 'lib/screens/care_plan_screen.dart', 'lib/screens/care_screen.dart', 'lib/screens/family_tree_screen.dart', 'lib/screens/light_meter_screen.dart', 'lib/screens/vacation_mode_screen.dart', 'lib/screens/home_screen.dart', 'lib/theme/app_theme.dart'];
  
  for (const file of files) {
    if (!fs.existsSync(file)) continue;
    let content = fs.readFileSync(file, 'utf8');
    
    // Fix invalid constants due to Theme.of(context)
    content = content.replace(/const Text\([^,]+,\s*style:\s*TextStyle\([^)]*Theme\.of\(context\)[^)]*\)\)/g, match => match.replace('const Text', 'Text'));
    content = content.replace(/const Text\([^,]+,\s*style:\s*TextStyle\([^)]*textColor[^)]*\)\)/g, match => match.replace('const Text', 'Text'));
    content = content.replace(/const Text\([^,]+,\s*style:\s*const TextStyle\([^)]*Theme\.of\(context\)[^)]*\)\)/g, match => match.replace('const Text', 'Text').replace('const TextStyle', 'TextStyle'));
    
    // Fix invalid const array with Text containing Theme.of(context)
    content = content.replace(/const \[\s*Text/g, "[ Text");
    
    // Fix undefined name ''
    content = content.replace(/Icon\(\\, color: textColor\)/g, "Icon(Icons.arrow_back, color: textColor)");
    
    // Fix missing context in light_meter_screen.dart
    if (file.includes('light_meter_screen.dart')) {
      content = content.replace(/_buildInfoCard\(/g, "_buildInfoCard(context: context, ");
      content = content.replace(/context: context, context: context, /g, "context: context, "); // clean up double
    }

    // Fix care_screen.dart undefined context
    if (file.includes('care_screen.dart')) {
        content = content.replace(/color:\s*Theme\.of\(context\).colorScheme.onSurface/g, "color: Color(0xFF191C1B)"); // Revert context usage in static/stateless where it's broken, we will fix properly
    }
    
    // Fix home_screen.dart and app_theme.dart onBackground
    if (file.includes('home_screen.dart') || file.includes('app_theme.dart')) {
        content = content.replace(/onBackground/g, "onSurface");
    }

    fs.writeFileSync(file, content);
  }
}
fixFiles();
