#!/usr/bin/env bash

CHART_NAME="${1}"
[[ -z ${CHART_NAME} ]] && { CHART_NAME="xnat-web"; }

echo "Installing current project as Helm chart ${CHART_NAME}"
echo

helm install ${CHART_NAME} .

STATUS="${?}"
[[ ${STATUS} != 0 ]] && {
    echo
    echo "A non-zero status was returned by the helm install command. This probably means"
    echo "the deploy failed. Please check for any error messages and try again."
    echo
    exit ${STATUS}
}

echo
echo "Install of ${CHART_NAME} complete"
echo

helm list

echo
echo "Full set of pods, services, deployments, and ingresses"
echo

kubectl get pods,services,deployments,ingresses

export NODE_PORT=$(kubectl get --namespace default -o jsonpath="{.spec.ports[0].nodePort}" svc xnat-web)
export NODE_IP=$(kubectl get nodes --namespace default -o jsonpath="{.items[0].status.addresses[0].address}")

echo
echo "The ostensible URL is: http://${NODE_IP}:${NODE_PORT}"
echo "In practice, the URL you probably need is: http://localhost:${NODE_PORT}"
echo
echo "You can stop this deployment by running the command:"
echo
echo " $ helm uninstall ${CHART_NAME}"
echo

