# This script is used to generate the markdown files used by Github pages for lightning component jsdocs
npx jsdoc2md nebula-logger/main/logger-engine/lwc/logger/logger.js > ./docs/lightning-components/Logger.md
npx jsdoc2md nebula-logger/main/logger-engine/lwc/logger/logEntryBuilder.js > ./docs/lightning-components/LogEntryBuilder.md

prettier ./docs/lightning-components --write