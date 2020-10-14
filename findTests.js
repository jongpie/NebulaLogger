const fs = require("fs");
const path = require("path")
const dirPath = path.join(__dirname, 'nebula-logger/tests');

const testFileNames = [];

function walkSync(currentDirPath) {
  fs.readdirSync(currentDirPath).forEach(function (name) {
      const filePath = path.join(currentDirPath, name);
      const stat = fs.statSync(filePath);
      if (stat.isFile() && name.indexOf('Test') > -1 && !name.endsWith('-meta.xml')) {
          testFileNames.push(name.replace('.cls', ''));
      } else if (stat.isDirectory()) {
          walkSync(filePath);
      }
  });
}

walkSync(dirPath);
fs.writeFileSync("./test-files", '"' + testFileNames.join(',') + '"')




