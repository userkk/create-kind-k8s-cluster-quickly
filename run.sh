#!/bin/bash

#set -xeu

cd /root/kind

/usr/bin/kind-linux-amd64 create cluster --config=cluster.yaml && sleep 5

loadimage="harbor.kengdie.xyz/k8s/calico/cni:v3.24.5 
harbor.kengdie.xyz/k8s/traefik:v2.9
harbor.kengdie.xyz/k8s/bitnami/metrics-server:0.6.1
harbor.kengdie.xyz/k8s/calico/kube-controllers:v3.24.5
harbor.kengdie.xyz/k8s/calico/node:v3.24.5
harbor.kengdie.xyz/k8s/donch/net-tools:latest
harbor.kengdie.xyz/k8s/kennethreitz/httpbin:latest"

for image in `echo $loadimage`
do
	docker pull $image
done
# registry.cn-hangzhou.aliyuncs.com/rdc-incubator/kt-connect-shadow:v0.3.6
/usr/bin/kind-linux-amd64 load docker-image --name cks $loadimage && sleep 5 &&  kubectl create -f calico.yaml

until [[ $(kubectl get po -A | awk '{print $3}' | awk -F'/' '{if($1!=$2) {print $0}}') == "READY" ]]
do
	echo -e "\e[31m Doing: K8s Cluster is Creating\e[0m"
	sleep 3
	kubectl get po -A -o wide
done

kubectl taint node cks-control-plane node-role.kubernetes.io/master:NoSchedule-

echo -e "\e[31m Success: Created K8s Cluster\e[0m"

kubectl create -f prepare.yaml
kubectl create -f traefic-ingress.yaml
kubectl create -f metrics-server-components.yaml

until [[ $(kubectl get po -A | awk '{print $3}' | awk -F'/' '{if($1!=$2) {print $0}}') == "READY" ]]
do
	echo -e "\e[31m Doing: Test Env is Creating\e[0m"
	sleep 3
	kubectl get po -A -o wide | grep -v Running
done
echo -e "\e[31m Success: Created Test Env\e[0m"

#masterip=$(docker inspect cks-control-plane -f={{.NetworkSettings.Networks.kind.IPAddress}})
#mastername=$(docker inspect cks-control-plane -f={{.Config.Hostname}})


cd -
