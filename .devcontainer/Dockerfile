FROM salesforce/cli:2.134.1-full

# Set up sf plugins
RUN sf plugins trust allowlist add -n sf-trace-plugin -n @jongpie/sfdx-bummer-plugin \
  && sf plugins trust allowlist list \
  # TODO migrate all scripts (including in build.yml) to use
  # the new code-analyzer plugin / eliminate sfdx-scanner
  && sf plugins install code-analyzer@ \
  && sf plugins install @jongpie/sfdx-bummer-plugin \
  && sf plugins install sf-trace-plugin

# Set up Oh My Bash
RUN bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" \
  && sed -i 's/OSH_THEME=.*/OSH_THEME="agnoster"/' ~/.bashrc

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH
