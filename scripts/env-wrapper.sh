#!/bin/bash
# env-wrapper.sh, ABr

# unset variables - override them in user-specific environment variables
# SAB_MINISHIFT_IS_KUBE_FOR_MAC - is this kube-for-mac install?
# SAB_MINISHIFT_KUBE_CONFIG - path to kube.config to use during Makefile
#
# minishift tokens (used to control minishift)
# SAB_MINISHIFT_PRIVATE_REGISTRY - set to value for local private registry
# SAB_MINISHIFT_PRIVATE_REGISTRY_CA_CERT - ca cert for the local private registry
# SAB_MINISHIFT_DOCKER_USER - docker user accessing via ssh to trust private registry
# SAB_MINISHIFT_DOCKER_PASSWORD - ditto
# SAB_MINISHIFT_DOCKER_HOST - ditto
# SAB_MINISHIFT_DOCKER_PORT - ditto
# SAB_MINISHIFT_PRIVATE_REGISTRY_TRUST_SCRIPT - accepts all six options and establishes trust


# set user-specific environment variables
SAB_MINISHIFT_ENV_WRAPPER_RC=0
SAB_MINISHIFT_ENV_WRAPPER_PWD="$PWD"
SAB_MINISHIFT_ENV_DIR="$HOME/.sab-projects/sab-minishift"
if [ -s "$SAB_MINISHIFT_ENV_DIR"/env ] ; then
  cd "$SAB_MINISHIFT_ENV_DIR"
  source ./env
  SAB_MINISHIFT_ENV_WRAPPER_RC=$?
  cd "$SAB_MINISHIFT_ENV_WRAPPER_PWD"
fi
[ $SAB_MINISHIFT_ENV_WRAPPER_RC -ne 0 ] && exit $SAB_MINISHIFT_ENV_WRAPPER_RC

# for port forwarding
SAB_MINISHIFT_DEFAULT_HOST_IP_ADDR=$(ip a | grep -e '\sinet\s' | grep -v '\s127\.' | head -n 1 | awk '{print $2}' | sed -e 's/^\([^/]\+\).*/\1/')
SAB_MINISHIFT_HOST_IP_ADDR=${SAB_MINISHIFT_HOST_IP_ADDR:-${SAB_MINISHIFT_DEFAULT_HOST_IP_ADDR}}
export \
  SAB_MINISHIFT_DEFAULT_HOST_IP_ADDR \
  SAB_MINISHIFT_HOST_IP_ADDR

# MiniShift tokens (auto-generated / persistent)
SAB_MINISHIFT_TOKENS=${PWD}/.localdata/minishift/tokens
SAB_MINISHIFT_TOKENS_INITIAL_CLUSTER_TOKEN_FILE="$SAB_MINISHIFT_TOKENS"/initial_cluster_token
SAB_MINISHIFT_TOKENS_ETCD_DISCOVERY_TOKEN_FILE="$SAB_MINISHIFT_TOKENS"/etcd_discovery_token
mkdir -p "$SAB_MINISHIFT_TOKENS"
[ ! -s "$SAB_MINISHIFT_TOKENS_INITIAL_CLUSTER_TOKEN_FILE" ] && \
  python -c "import string; import random; print(''.join(random.SystemRandom().choice(string.ascii_lowercase + string.digits) for _ in range(40)))" \
  > "$SAB_MINISHIFT_TOKENS_INITIAL_CLUSTER_TOKEN_FILE"
[ ! -s "$SAB_MINISHIFT_TOKENS_ETCD_DISCOVERY_TOKEN_FILE" ] && \
  python -c "import string; import random; print(\"etcd-cluster-\" + ''.join(random.SystemRandom().choice(string.ascii_lowercase + string.digits) for _ in range(5)))" \
  > "$SAB_MINISHIFT_TOKENS_ETCD_DISCOVERY_TOKEN_FILE"
SAB_MINISHIFT_TOKENS_INITIAL_CLUSTER_TOKEN=$(cat "$SAB_MINISHIFT_TOKENS_INITIAL_CLUSTER_TOKEN_FILE")
SAB_MINISHIFT_TOKENS_ETCD_DISCOVERY_TOKEN=$(cat "$SAB_MINISHIFT_TOKENS_ETCD_DISCOVERY_TOKEN_FILE")
export \
  SAB_MINISHIFT_TOKENS \
  SAB_MINISHIFT_TOKENS_INITIAL_CLUSTER_TOKEN \
  SAB_MINISHIFT_TOKENS_ETCD_DISCOVERY_TOKEN

# some minishift variable defaults
SAB_MINISHIFT_START_ARGS="${SAB_MINISHIFT_START_ARGS:---memory 4096 --cpus 2}"
export \
  SAB_MINISHIFT_START_ARGS

# call original app
if [ x"$1" != x'source-only' ] ; then
  eval "$@"
fi

