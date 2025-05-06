FROM node:23.10.0-bookworm

ARG GIT_VERSION=2.49.0
ARG SF_CLI_VERSION=2.86.9
ARG SF_LWC_JEST_VERSION=7.0.1

RUN apt-get update && apt-get install -y \
  gnupg \
  jq \
  locales \
  openssh-client \
  && sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
  && locale-gen en_US.UTF-8 \
  && update-locale LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8 \
  LANGUAGE=en_US:en \
  LC_ALL=en_US.UTF-8

# Install & setup CLI - docs for environment variables: https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_dev_cli_env_variables.htm
RUN npm install --global \
  @salesforce/cli@${SF_CLI_VERSION} \
  @salesforce/sfdx-lwc-jest@${SF_LWC_JEST_VERSION}
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
  # Another possible theme option: powerline-icon
  && sed -i 's/OSH_THEME=.*/OSH_THEME="agnoster"/' ~/.bashrc
