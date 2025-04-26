FROM ghcr.io/actions/actions-runner:2.323.0

ARG MELANGE_VERSION=v0.23.10

USER root

RUN \
    TEMP_DEPS="build-essential git meson ninja-build libcap-dev" \
    &&
    apt-get -qq update \
    && \
    apt-get -qq install -y --no-install-recommends --no-install-suggests \
        ca-certificates \
        jo \
        moreutils \
        wget \
        zstd \
        gcc \
        awscli \
    && \
    git clone https://github.com/containers/bubblewrap \
        && pushd bubblewrap \
        && meson --prefix=/usr -Drequire_userns=true . output \
        && cd output \
        && ninja \
        && ninja install \
        && popd \
        && rm -rf bubblewrap \
    curl -fsSL "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" -o /usr/local/bin/yq \
        && chmod +x /usr/local/bin/yq \
    && \
    curl -fsL https://github.com/chainguard-dev/melange/releases/download/${MELANGE_VERSION}/melange_${MELANGE_VERSION#v}_linux_amd64.tar.gz | tar xzf - --strip-components=1 -C /usr/local/bin \
    && \
    mkdir -p -m 755 /etc/apt/keyrings \
        && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        && cat $out | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
        && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
        && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
        && apt update \
        && apt install gh -y \
    && apt-get purge -y --auto-remove $TEMP_DEPS \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER runner

RUN curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh
