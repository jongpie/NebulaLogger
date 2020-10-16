#/bin/bash
fileNames=$(cat test-files)
sfdx force:apex:test:run -w 15 -n $fileNames