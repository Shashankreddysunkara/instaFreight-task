#!/usr/bin/env bash

export KUBECONFIG=/home/ubuntu/kubeconfig_ops-eks
CONSUL_DNS_IP=$(kubectl get svc ops-consul-dns -o jsonpath='{.spec.clusterIP}')

cat <<EOF >/home/ubuntu/coredns_cm.yml
apiVersion: v1
data:
  Corefile: |
    .:53 {
        errors
        health
        kubernetes cluster.local in-addr.arpa ip6.arpa {
          pods insecure
          upstream
          fallthrough in-addr.arpa ip6.arpa
        }
        prometheus :9153
        forward . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
    }
        consul {
                errors
                cache 30
      forward . $CONSUL_DNS_IP
        }
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
  annotations:
EOF

kubectl replace -n kube-system -f /home/ubuntu/coredns_cm.yml

# kubectl get -n kube-system cm/coredns --export -o yaml | kubectl replace -n kube-system -f coredns_cm.yml
