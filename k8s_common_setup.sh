#!/bin/bash

sudo apt install git curl make

CURRENT_DIR="$(pwd)"
: ${OSH_INFRA_PATH:="../openstack-helm-infra"}
cd ${OSH_INFRA_PATH}
make dev-deploy setup-host
make dev-deploy k8s
cd ${CURRENT_DIR}

sudo -H -E pip3 install --upgrade pip
sudo -H -E pip3 install \
  -c${UPPER_CONSTRAINTS_FILE:=https://releases.openstack.org/constraints/upper/${OPENSTACK_RELEASE:-xena}} \
  cmd2 python-openstackclient python-heatclient --ignore-installed


export HELM_CHART_ROOT_PATH=/home/ubuntu/openstack-helm-infra/
export OSH_INFRA_PATH=/home/ubuntu/openstack-helm-infra/


sudo -H mkdir -p /etc/openstack
sudo -H chown -R $(id -un): /etc/openstack
FEATURE_GATE="tls"; if [[ ${FEATURE_GATES//,/ } =~ (^|[[:space:]])${FEATURE_GATE}($|[[:space:]]) ]]; then
  tee /etc/openstack/clouds.yaml << EOF
  clouds:
    openstack_helm:
      region_name: RegionOne
      identity_api_version: 3
      cacert: /etc/openstack-helm/certs/ca/ca.pem
      auth:
        username: 'admin'
        password: 'password'
        project_name: 'admin'
        project_domain_name: 'default'
        user_domain_name: 'default'
        auth_url: 'https://keystone.openstack.svc.cluster.local/v3'
EOF
else
  tee /etc/openstack/clouds.yaml << EOF
  clouds:
    openstack_helm:
      region_name: RegionOne
      identity_api_version: 3
      auth:
        username: 'admin'
        password: 'password'
        project_name: 'admin'
        project_domain_name: 'default'
        user_domain_name: 'default'
        auth_url: 'http://keystone.openstack.svc.cluster.local/v3'
EOF
fi

kubectl label node kind-control-plane openstack-control-plane=enabled;
kubectl label node kind-control-plane linuxbridge=enabled;
kubectl label node kind-control-plane openstack-compute-node=enabled


cd openstack-helm-infra/

make -C ${HELM_CHART_ROOT_PATH} helm-toolkit

make -C ${HELM_CHART_ROOT_PATH} ingress

: ${OSH_EXTRA_HELM_ARGS:=""}
tee /tmp/ingress-kube-system.yaml << EOF
deployment:
  mode: cluster
  type: DaemonSet
network:
  host_namespace: true
EOF


touch /tmp/ingress-component.yaml

if [ -n "${OSH_DEPLOY_MULTINODE}" ]; then
  tee --append /tmp/ingress-kube-system.yaml << EOF
pod:
  replicas:
    error_page: 2
EOF

  tee /tmp/ingress-component.yaml << EOF
pod:
  replicas:
    ingress: 2
    error_page: 2
EOF
fi



helm upgrade --install ingress-kube-system ${HELM_CHART_ROOT_PATH}/ingress \
  --namespace=kube-system \
  --values=/tmp/ingress-kube-system.yaml \
  ${OSH_EXTRA_HELM_ARGS} \
  ${OSH_EXTRA_HELM_ARGS_INGRESS} \
  ${OSH_EXTRA_HELM_ARGS_INGRESS_KUBE_SYSTEM}

helm upgrade --install ingress-openstack ${HELM_CHART_ROOT_PATH}/ingress \
  --namespace=openstack \
  --values=/tmp/ingress-component.yaml \
  ${OSH_EXTRA_HELM_ARGS} \
  ${OSH_EXTRA_HELM_ARGS_INGRESS} \
  ${OSH_EXTRA_HELM_ARGS_INGRESS_OPENSTACK}


helm upgrade --install ingress-ceph ${HELM_CHART_ROOT_PATH}/ingress \
  --namespace=ceph \
  --values=/tmp/ingress-component.yaml \
  ${OSH_EXTRA_HELM_ARGS} \
  ${OSH_EXTRA_HELM_ARGS_INGRESS} \
  ${OSH_EXTRA_HELM_ARGS_INGRESS_CEPH}


