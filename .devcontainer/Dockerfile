FROM node:22.15.0-bookworm

WORKDIR /workspaces/NebulaLogger

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
# https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_dev_cli_env_variables.htm
ENV FORCE_SHOW_SPINNER=true
# ENV SF_CONTAINER_MODE=true
ENV SF_DISABLE_AUTOUPDATE=true
ENV SF_DISABLE_TELEMETRY=true
ENV SF_LOG_LEVEL=debug
ENV SF_SKIP_NEW_VERSION_CHECK=true
COPY package.json ./
COPY package-lock.json ./
RUN npm ci

# Now that the npm dependencies are installed locally via package.json, (re-)install some of them globally
# so they can be easily used within the devcontainer/VS Code.
RUN npm install -g @salesforce/cli@$(node -p "require('./package.json').devDependencies['@salesforce/cli']")
RUN npm install -g prettier@$(node -p "require('./package.json').devDependencies['prettier']")

# Set up sf plugins
RUN mkdir $HOME/.config && mkdir $HOME/.config/sf \
  # TODO revisit sf-trace-plugin install weirdness with @jamessimone
  && echo '[ "@jongpie/sfdx-bummer-plugin", "jamessimone/sf-trace-plugin", "sf-trace-plugin" ]' > $HOME/.config/sf/unsignedPluginAllowList.json \
  && sf plugins install code-analyzer \
  && sf plugins install community \
  && sf plugins install custom-metadata \
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
