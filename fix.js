const fs = require('fs');

let c = fs.readFileSync('frontend/shared/components/settings/ProjectSettings.tsx', 'utf8');

c = c.replace(
  "import type React from 'react';",
  "import type React from 'react';\nconst t = (isRTL: boolean, ar: string, en: string) => isRTL ? ar : en;"
);

c = c.replace(/isRTL \? '(.*?)' : '(.*?)'/g, "t(isRTL, '$1', '$2')");
c = c.replace(/isRTL \? `(.*?)` : `(.*?)`/g, "t(isRTL, `$1`, `$2`)");
c = c.replace(/isRTL \? opt\.labelAr : opt\.labelEn/g, "t(isRTL, opt.labelAr, opt.labelEn)");

fs.writeFileSync('frontend/shared/components/settings/ProjectSettings.tsx', c);
