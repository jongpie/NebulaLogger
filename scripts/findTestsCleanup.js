const fs = require("fs");

try {
  fs.unlinkSync("./test-files");
} catch {}