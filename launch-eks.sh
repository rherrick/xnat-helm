#!/usr/bin/env bash

# Start here:
# https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html
eksctl create cluster --name xnat-dev --version 1.15 --region us-east-2 --nodegroup-name standard-workers --node-type t3.medium --nodes 3 --nodes-min 1 --nodes-max 4 --ssh-access --ssh-public-key /Users/rherrick/.ssh/id_rsa.pub --managed

kubectl get svc
kubectl get nodes

# Test it here:
# https://docs.aws.amazon.com/eks/latest/userguide/eks-guestbook.html
# kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-master-controller.json
# kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-master-service.json
# kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-slave-controller.json
# kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-slave-service.json
# kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/guestbook-controller.json
# kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/guestbook-service.json
# kubectl get services -o wide

# Now delete that
kubectl delete rc/redis-master rc/redis-slave rc/guestbook svc/redis-master svc/redis-slave svc/guestbook

