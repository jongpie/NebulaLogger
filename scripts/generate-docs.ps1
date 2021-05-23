# This script is used to generate the markdown files used by Github pages
npx apexdocs-generate --configPath config/apexdocs.json --scope global public --sourceDir nebula-logger/main --targetDir docs
prettier --write ./docs
