#!/usr/bin/env bash

AWS_REGION=us-east-2
AWS_CLUSTER=xnat-dev
AWS_CONFIG=~/.aws
AWS_IAM_POLICY=${AWS_CONFIG}/iam_policy.json
AWS_IAM_LB_POLICY=${AWS_CONFIG}/iam_lb_policy.json
AWS_SSH_PUB_KEY=~/.ssh/aws_id_ed25519.pub

# cat > ${AWS_CLUSTER}-cluster.yaml <<VALUES
# apiVersion: eksctl.io/v1alpha5
# kind: ClusterConfig
# 
# metadata:
#   name: ${AWS_CLUSTER}
#   region: ${AWS_REGION}
# 
# managedNodeGroups:
#   - name: ${AWS_CLUSTER}-ng-1
#     labels: { role: services }
#     instanceType: m5.large
#     desiredCapacity: 2
#     volumeSize: 80
#     privateNetworking: true
#     ssh:
#       publicKeyPath: ${AWS_SSH_PUB_KEY}
# 
# cloudWatch:
#   clusterLogging:
#     enableTypes: ["*"]
# VALUES

# VALUES above originally included the definition below, but I don't think it's necessary for now.
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

# eksctl create cluster -f ${AWS_CLUSTER}-cluster.yaml

# The following is only necessary if you want cluster logging and cloudWatch.clusterLogging.enableTypes
# wasn't included in the cluster definition.
#
# eksctl utils update-cluster-logging --enable-types=all --region=us-east-2 --cluster=${AWS_CLUSTER}
#

# eksctl utils associate-iam-oidc-provider --region ${AWS_REGION} --cluster ${AWS_CLUSTER} --approve
# http --download --output=${AWS_IAM_POLICY} https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
# aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://${AWS_IAM_POLICY} > ${AWS_IAM_LB_POLICY}

AWS_POLICY_ARN="$(cat ${AWS_IAM_LB_POLICY} | jq '.Policy .Arn' | tr -d '"')"
eksctl create iamserviceaccount --cluster=${AWS_CLUSTER} --namespace=kube-system --name=aws-load-balancer-controller --attach-policy-arn=${AWS_POLICY_ARN} --override-existing-serviceaccounts --approve


