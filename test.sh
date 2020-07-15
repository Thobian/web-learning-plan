
useradd -m thobian

chmod 644 /var/lib/minikube/certs/ca.key

su thobian

mkdir /home/thobian/.minikube && cd /home/thobian/.minikube

cp /var/lib/minikube/certs/ca.crt /var/lib/minikube/certs/ca.key ./

openssl genrsa -out thobian.key 2048

openssl req -new -key thobian.key -out thobian.csr -subj "/CN=thobian"

openssl x509 -req -in thobian.csr -CA ./ca.crt -CAkey ./ca.key -CAcreateserial -out thobian.crt -days 365



mkdir /home/thobian/.kube && cd /home/thobian/.kube

cat << EOF > config
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /home/thobian/.minikube/ca.crt
    server: $(kubectl config view -o jsonpath='{range .clusters[*]}{.cluster.server}{"\n"}')
  name: minikube
contexts:
- context:
    cluster: minikube
    user: thobian
  name: minikube
current-context: minikube
kind: Config
preferences: {}
users:
- name: thobian
  user:
    client-certificate: /home/thobian/.minikube/thobian.crt
    client-key: /home/thobian/.minikube/thobian.key
EOF

# 没权限
kubectl get pods --namespace kube-system


# 设置权限
mkdir /home/thobian/yaml && cd /home/thobian/yaml
    
cat << EOF > cluster_role.yaml
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: admin
rules:
- apiGroups: [""]
  resources: ["*"]
  verbs: ["*"]
EOF

cat << EOF > role_binding.yaml
kind: ClusterRoleBinding 
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: admin-binding
subjects:
- kind: User
  name: thobian
  apiGroup: ""
roleRef:
  kind: ClusterRole
  name: admin
  apiGroup: ""
EOF

su root
kubectl apply -f cluster_role.yaml
kubectl apply -f role_binding.yaml
  

# 设置完成
su thobian
kubectl get pods --namespace kube-system



curl --key /home/thobian/.minikube/thobian.key --cert /home/thobian/.minikube/thobian.crt https://172.17.0.24:8443/api/v1/namespaces/default/pods

curl --key /root/.minikube/client.key --cert /root/.minikube/client.crt https://172.17.0.24:8443


https://katacoda.com/embed/minikube/?v=2&embed=true&ui=panel&host=kubernetes.io&url=https%3A%2F%2Fkubernetes.io%2Fdocs%2Ftutorials%2Fhello-minikube%2F&target=my-panel&nonce=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWJlZCI6dHJ1ZSwiZG9tYWluIjoiaHR0cHM6Ly9rdWJlcm5ldGVzLmlvL2RvY3MvdHV0b3JpYWxzL2hlbGxvLW1pbmlrdWJlLyIsImlwIjoiMTI0LjE1Ni4xMzIuMTMwIiwiaWF0IjoxNTk0NjQ2MjA1LCJleHAiOjE1OTQ2NDYyMzV9.duLA7c1J0KmfzHa0wBZOI3UDTIn1QEo5B0piO1lbr44&port=30000&command=start.sh
