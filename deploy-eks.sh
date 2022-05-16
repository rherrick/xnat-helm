#!/usr/bin/env bash

# This script presumes you've installed kubectl, awscli, and eksctl, as well as configured
# aws for access. See here for more info:
# 
# https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html
#

# CLUSTER below originally included the definition below, but I don't think it's necessary for now.
#   - name: ${AWS_CLUSTER}-ng-2
#     instanceType: m5.xlarge
#     desiredCapacity: 2
#     volumeSize: 100
#     ssh:
#       publicKeyPath: ~/.ssh/aws_id_ed25519.pub
#
# For ng-1, it included this instead of publicKeyPath:
# 
#   allow: true # will use ~/.ssh/id_rsa.pub as the default ssh key
#
# YMMV
#
# CloudWatch logging can be restricted to the following types:
# 
# cloudWatch:
#   clusterLogging:
#     enableTypes:
#       - "api"
#       - "audit"
#       - "authenticator"
#       - "controllerManager"
#       - "scheduler"
# 

addHelmRepo() {
    local REPO_ID=${1}
    local REPO_URL=${2}
    [[ $(helm repo list | grep -i "${REPO_URL}" | wc -l | tr -d ' ') == 0 ]] && {
        helm repo add ${REPO_ID} ${REPO_URL}
        helm repo update
    }
}

addCluster() {
    aws eks describe-cluster --name ${AWS_CLUSTER} &> /dev/null
    local STATUS=${?}
    [[ ${STATUS} == 0 ]] && {
        echo "${AWS_CLUSTER} already exists, so I'm skipping it. If you need to recreate it, you first must delete"
        echo "it with the following command:"
        echo
        echo "  eksctl delete cluster --name ${AWS_CLUSTER}"
        echo
        return
    }

	cat > ${AWS_CLUSTER_YAML} <<-CLUSTER
		apiVersion: eksctl.io/v1alpha5
		kind: ClusterConfig
		
		metadata:
		  name: ${AWS_CLUSTER}
		  region: ${AWS_REGION}
		
		managedNodeGroups:
		  - name: ${AWS_CLUSTER}-ng-1
		    labels: { role: services }
		    instanceType: m5.large
		    desiredCapacity: 2
		    volumeSize: 80
		    privateNetworking: true
		    ssh:
		      publicKeyPath: ${AWS_SSH_PUB_KEY}
		
		cloudWatch:
		  clusterLogging:
		    enableTypes: ["*"]
	CLUSTER

    eksctl create cluster --config-file ${AWS_CLUSTER_YAML}
}

addValues() {
    [[ -f ${AWS_CLUSTER_VALUES} ]] && {
        echo "${AWS_CLUSTER_VALUES} already exists, so I'm skipping it. If you need to recreate it, delete this file."
        return
    }

	cat > ${AWS_CLUSTER_VALUES} <<-VALUES
		---
		global:
		  postgresql:
		    postgresqlPassword: "xnat"
	VALUES
}

AWS_REGION=us-east-2
AWS_CLUSTER=xnat-dev
AWS_CLUSTER_YAML=${AWS_CLUSTER}-cluster.yaml
AWS_CLUSTER_VALUES=${AWS_CLUSTER}-values.yaml
AWS_CONFIG=~/.aws
AWS_IAM_POLICY=${AWS_CONFIG}/iam_policy.json
AWS_IAM_LB_POLICY=${AWS_CONFIG}/iam_lb_policy.json
AWS_SSH_PUB_KEY=~/.ssh/aws_id_ed25519.pub
CHART_ID=xnat
CHART_NAME=ais/xnat

addHelmRepo stable https://charts.helm.sh/stable
addHelmRepo ais https://australian-imaging-service.github.io/charts

addCluster
addValues

helm upgrade ${CHART_ID} ${CHART_NAME} --install --values ${AWS_CLUSTER_VALUES} --namespace ${AWS_CLUSTER} --create-namespace

# The following is only necessary if you want cluster logging and cloudWatch.clusterLogging.enableTypes
# wasn't included in the cluster definition.
#
# eksctl utils update-cluster-logging --enable-types=all --region=${AWS_REGION} --cluster=${AWS_CLUSTER}
#

#
# This is all for setting up ALB ingress controller on AWS. Not sure if we want to do this or use nginx.
#
# eksctl utils associate-iam-oidc-provider --region ${AWS_REGION} --cluster ${AWS_CLUSTER} --approve
# http --download --output=${AWS_IAM_POLICY} https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
# aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://${AWS_IAM_POLICY} > ${AWS_IAM_LB_POLICY}
# AWS_POLICY_ARN="$(cat ${AWS_IAM_LB_POLICY} | jq '.Policy .Arn' | tr -d '"')"
# eksctl create iamserviceaccount --cluster=${AWS_CLUSTER} --namespace=kube-system --name=aws-load-balancer-controller --attach-policy-arn=${AWS_POLICY_ARN} --override-existing-serviceaccounts --approve
# kubectl apply --kustomize="github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"
# addHelmRepo eks https://aws.github.io/eks-charts
# helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller --set clusterName=${AWS_CLUSTER} --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller --namespace kube-system
# kubectl get deployment --namespace kube-system aws-load-balancer-controller

# WIP and notes
#
# AmazonEKSClusterPolicy and AmazonEKSServicePolicy
