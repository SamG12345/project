#!/bin/sh

sudo sed -i "s|http://de.archive.ubuntu.com/ubuntu/|http://archive.ubuntu.com/ubuntu/|" /etc/apt/sources.list
sudo apt update
sudo apt install -y curl docker.io openssh-server net-tools nmap
sudo usermod -aG docker $USER
newgrp docker
snap install kubectl --classic
curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64 

minikube start

# host (* nopt checked)
cat << "EOF" > host.yaml
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: "2026-07-11T16:48:49Z"
  labels:
    app: host-os
  name: http
  namespace: host
  resourceVersion: "9854"
  uid: 53c4a05e-c0af-4643-bcbb-5900bd1f9727
spec:
  clusterIP: 10.43.73.207
  clusterIPs:
  - 10.43.73.207
  externalTrafficPolicy: Cluster
  internalTrafficPolicy: Cluster
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  ports:
  - name: 8080-53422
    nodePort: 31564
    port: 8080
    protocol: TCP
    targetPort: 53422
  selector:
    app: host-os
  sessionAffinity: None
  type: NodePort
status:
  loadBalancer: {}
EOF

cat << "EOF" > host-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-inbound-traffic
  namespace: host
spec:
  podSelector:
    matchLabels:
      app: host-os
  policyTypes:
    - Ingress
  ingress:
    - from:
        - ipBlock:
            cidr: 0.0.0.0/0 #192.168.1.0/24 # 2. Allow traffic from a specific network subnet
            except:
              - 192.168.1.50/32 # Block this specific bad actor IP
        - namespaceSelector:
            matchLabels:
              environment: host # 3. Allow traffic from specific namespaces
        - podSelector:
            matchLabels:
              role: frontend # 4. Allow traffic from specific backend/frontend pods
      ports:
        - protocol: TCP
          port: 8080 # 5. Only open this specific container port
EOF

cat << "EOF" > host-os.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: "2026-07-11T16:53:46Z"
  generation: 1
  labels:
    app: host-os
  name: host-os
  namespace: host
  resourceVersion: "9947"
  uid: 3fc3fa53-a4f8-413b-b0d9-73adee9da4a6
spec:
  progressDeadlineSeconds: 600
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: host-os
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: host-os
    spec:
      containers:
      - image: cgr.dev/chainguard/kubectl:latest
        command: ["/bin/bash", "-c"]
        args: ["apt update;", "while true; do echo 'Keeping container alive'; sleep 30; done"]
        imagePullPolicy: Always
        name: host-os-cont
        
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
status: {}
EOF

kubectl apply -f host-os.yaml # host os
kubectl apply -f host.yaml # host nodeport
kubuectl apply -f host-ingress.yaml # host ingress

cat << "EOF" > info.txt
deployment host-os created
service nodeport host created
rule 
EOF

bash install_docker.sh
