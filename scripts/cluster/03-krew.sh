#!/bin/bash

# https://krew.sigs.k8s.io/docs/user-guide/setup/install/
echo "> Install Krew"
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew.tar.gz" &&
  tar zxvf krew.tar.gz &&
  KREW=./krew-"${OS}_${ARCH}" &&
  "$KREW" install krew
)

echo "PATH=\"\${KREW_ROOT:-\$HOME/.krew}/bin:\$PATH\"" >> ~/.profile
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

echo '> Install Krew plugins'
kubectl krew install ctx
kubectl krew install ns
