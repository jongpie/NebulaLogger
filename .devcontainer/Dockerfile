FROM node:22.15.0-bookworm

ARG SF_CLI_VERSION=2.86.9
ARG SF_LWC_JEST_VERSION=7.0.1
# ARG PRETTIER_VERSION=3.5.3
# ARG PRETTIER_PLUGIN_APEX_VERSION=2.2.5

# WORKDIR /workspaces/NebulaLogger

# Updates + locale setup
RUN apt-get update && \
  apt-get install -y locales && \
  sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen && \
  locale-gen en_US.UTF-8 && \
  update-locale LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Set up npm dependencies (including sf CLI)
# COPY package.json ./
# COPY package-lock.json ./
# COPY package*.json ./
# RUN npm ci

# TODO new
# RUN npm install --global @salesforce/cli@${SF_CLI_VERSION} \
#   && npm install --global @salesforce/sfdx-lwc-jest@${SF_LWC_JEST_VERSION} \
#   && npm install --global prettier@${PRETTIER_VERSION} \
#   && npm install --global prettier-plugin-apex@${PRETTIER_PLUGIN_APEX_VERSION}
RUN npm install --global \
  @salesforce/cli@${SF_CLI_VERSION} \
  @salesforce/sfdx-lwc-jest@${SF_LWC_JEST_VERSION}
  # prettier@${PRETTIER_VERSION}
  # prettier-plugin-apex@${PRETTIER_PLUGIN_APEX_VERSION}
# "@cparra/apexdocs": "1.13.7",
# "@salesforce/cli": "^2.86.9",
# "@salesforce/sfdx-lwc-jest": "^7.0.1",
# "@types/jest-when": "^3.5.5",
# "husky": "^9.1.7",
# "jest-when": "^3.7.0",
# "jsdoc-to-markdown": "^9.1.1",
# "lint-staged": "^15.5.0",
# "prettier": "^3.5.3",
# "prettier-plugin-apex": "^2.2.5",
# "pwsh": "^0.3.0"

# Now that the npm dependencies are installed locally via package.json, make global shortcuts for them
# so they can be easily used within the devcontainer/VS Code.
# RUN ln -s ./node_modules/.bin/prettier /usr/local/bin/prettier
# RUN ln -s ./node_modules/.bin/sf /usr/local/bin/sf
# sf CLI environment variables: https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_dev_cli_env_variables.htm
ENV FORCE_SHOW_SPINNER=true \
  SF_DISABLE_AUTOUPDATE=true \
  SF_DISABLE_TELEMETRY=true \
  SF_LOG_LEVEL=debug \
  SF_SKIP_NEW_VERSION_CHECK=true

# Set up sf plugins
RUN mkdir $HOME/.config && mkdir $HOME/.config/sf \
  # TODO revisit sf-trace-plugin install weirdness with @jamessimone
  && echo '[ "@dx-cli-toolbox/sfdx-toolbox-package-utils", "@jongpie/sfdx-bummer-plugin", "jamessimone/sf-trace-plugin", "sf-trace-plugin" ]' > $HOME/.config/sf/unsignedPluginAllowList.json \
  && sf plugins install code-analyzer \
  && sf plugins install community \
  && sf plugins install custom-metadata \
  && sf plugins install @dx-cli-toolbox/sfdx-toolbox-package-utils \
  && sf plugins install @jongpie/sfdx-bummer-plugin \
  # I am still not clear why this is needed, but echo y is still needed here.
  # Putting the plugin into the allow list (above) doesn't seem to work for some reason.
  && echo y | sf plugins install jamessimone/sf-trace-plugin

# Set up Java
RUN apt-get update && apt-get install -y curl zip unzip && \
  curl -s "https://get.sdkman.io" | bash && \
  bash -c "source $HOME/.sdkman/bin/sdkman-init.sh && sdk install java 21-tem"
ENV JAVA_HOME=/root/.sdkman/candidates/java/current
ENV PATH="$JAVA_HOME/bin:$PATH"

# Set up Oh My Bash
RUN bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" \
  && sed -i 's/OSH_THEME=.*/OSH_THEME="agnoster"/' ~/.bashrc
