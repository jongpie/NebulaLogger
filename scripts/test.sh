#/bin/bash
fileNames=$(cat test-files)
echo "Beginning test run for ${fileNames}"
# if the job fails, clean up automatically
sfdx force:apex:test:run -w 15 -n $fileNames || node scripts/findTestsCleanup.js