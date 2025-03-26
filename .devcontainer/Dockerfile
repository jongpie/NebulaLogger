FROM salesforce/cli:2.82.6-full

# Set up sf plugins
RUN mkdir $HOME/.config && mkdir $HOME/.config/sf \
  # && echo '[ "@jongpie/sfdx-bummer-plugin", "jamessimone/sf-trace-plugin", "sf-trace-plugin" ]' > $HOME/.config/sf/unsignedPluginAllowList.json \
  && echo '[ "@jongpie/sfdx-bummer-plugin" ]' > $HOME/.config/sf/unsignedPluginAllowList.json \
  && sf plugins install code-analyzer@ \
  && sf plugins install @salesforce/sfdx-scanner \
  && sf plugins install @salesforce/plugin-agent \
  && sf plugins install @jongpie/sfdx-bummer-plugin \
  && echo y | sf plugins install jamessimone/sf-trace-plugin

# Set up Oh My Bash
RUN bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" \
  && sed -i 's/OSH_THEME=.*/OSH_THEME="agnoster"/' ~/.bashrc

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH
