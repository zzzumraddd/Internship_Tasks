
# Kubernetes Homework Assignment – Nginx App Deployment




## 1-task

Deployment & Service

* Create a Deployment called custom-nginx with the image nginx:latest.

* Run 2 replicas.

custom-nginx.yaml

        apiVersion: apps/v1
        kind: Deployment
        metadata:
        name: custom-nginx
        labels:
            app: custom-nginx
        spec:
        replicas: 2
        selector:
            matchLabels:
            app: custom-nginx
        template:
            metadata:
            labels:
                app: custom-nginx
            spec:
            containers:
                - name: nginx-container
                image: nginx:latest
                ports:
                - containerPort: 80


* Expose it with a ClusterIP and a NodePort Service.

customNginx-clusterIP.yaml

        apiVersion: v1
        kind: Service
        metadata:
        name: custom-nginx-clusterip
        spec:
        type: ClusterIP
        selector:
            app: custom-nginx
        ports:
            - port: 80
            targetPort: 80
            protocol: TCP

customNginx-nodePort.yaml

        apiVersion: v1
        kind: Service
        metadata: 
        name: custom-nginx-nodeport
        spec:
        type: NodePort
        selector:
            app: custom-nginx
        ports:
            - port: 80
            targetPort: 80

## 2-task

Ingress
Install and configure Ingress Controller (like NGINX Ingress).

        # Untaint master node
        kubectl taint nodes --all node-role.kubernetes.io/control-plane:NoSchedule-

        # Install ingress-controller
        curl https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml | kubectl apply -f -  

        # Patch hostnetwork  
        $ cat <<EOF > patch.yml
        spec:
        template:
            spec:
            hostNetwork: true
        EOF  

        kubectl patch deployment ingress-nginx-controller --patch-file patch.yml -n ingress-nginx


Create an Ingress resource to expose the NGINX deployment via domain nginx.local.

customNginx-ingress.yaml

        apiVersion: networking.k8s.io/v1
        kind: Ingress
        metadata:
        name: nginx-ingress-resource
        annotations:
            nginx.ingress.kubernetes.io/rewrite-target: /
        spec:
        ingressClassName: nginx
        rules:
            - host: nginx.local
            http:
            paths: 
                - path: /
                pathType: Prefix
                backend:
                service:
                    name: custom-nginx
                    port: 
                    number: 80



Use curl or /etc/hosts to test.

        kubectl get svc -n ingress-nginx ingress-nginx-controller
    
        change /etc/hosts

        <IP ADRESS> nginx.local

        curl http://nginx.local

![App Screenshot](images/output1.png)

## 3-task

ConfigMap

* Create a ConfigMap named nginx-config with a custom NGINX config (e.g. it should say AnyOps Sila).

* Mount this ConfigMap into the container at path: /etc/nginx/conf.d/default.conf.

A Kubernetes ConfigMap is an API object used to store non-confidential configuration data in key-value pairs. It allows you to decouple environment-specific configurations from your application container images, keeping your workloads portable across development, staging, and production environments without needing image rebuilds. 

To mount a ConfigMap as a volume in Kubernetes, you must define it in the spec.volumes section of your Pod or Deployment manifest, and then reference it within your container using spec.containers.volumeMounts. Each key in the ConfigMap automatically becomes a file inside the mounted directory.

nginx-config.yaml 

        apiVersion: v1
        kind: ConfigMap
        metadata:
        name: nginx-server-config
        data:
        nginx.conf: |
            user nginx;
            worker_processes auto;
            events {
            worker_connections 1024;
            }
            http {
            server {
                listen 80;
                server_name localhost;
                location / {
                root /usr/share/nginx/html;
                index index.html;
                }
            }
            }
        index.html: |
            <h1>Anyops Sila!</h1>


nginx-deployment.yaml 

        apiVersion: apps/v1
        kind: Deployment
        metadata:
        name: nginx-deployment
        spec:
        replicas: 1
        selector:
            matchLabels:
            app: nginx
        template:
            metadata:
            labels:
                app: nginx
            spec:
            containers:
            - name: nginx
                image: nginx:alpine
                ports:
                - containerPort: 80
                volumeMounts:
                - name: config-volume
                mountPath: /etc/nginx/nginx.conf
                subPath: nginx.conf
                - name: html-volume
                mountPath: /usr/share/nginx/html/index.html
                subPath: index.html
            volumes:
            - name: config-volume
                configMap:
                name: nginx-server-config
            - name: html-volume
                configMap:
                name: nginx-server-config


        kubectl exec -it $(kubectl get pod -l app=nginx -o jsonpath='{.items[0].metadata.name}') -- curl localhost
        
        Output: <h1>Anyops Sila!</h1>

![App Screenshot](images/output2.png)




## 4-task

Secret
* Create a Secret named nginx-secrets with:

username: admin

password: anyops123

        apiVersion: v1
        kind: Secret
        metadata:
        name: secret-basic-auth 
        type: Opaque
        stringData:
        username: admin 
        password: anyops123

* Use envFrom in the Deployment to load the secret as environment variables.

nginx-deployment.yaml 

        apiVersion: apps/v1
        kind: Deployment
        metadata:
        name: nginx-deployment
        spec:
        replicas: 1
        selector:
            matchLabels:
            app: nginx
        template:
            metadata:
            labels:
                app: nginx
            spec:
            containers:
            - name: nginx
                image: nginx:alpine
                ports:
                - containerPort: 80
                envFrom:
                - secretRef:
                    name: secret-basic-auth  
                volumeMounts:
                - name: config-volume
                mountPath: /etc/nginx/nginx.conf
                subPath: nginx.conf
                - name: html-volume
                mountPath: /usr/share/nginx/html/index.html
                subPath: index.html
            volumes:
            - name: config-volume
                configMap:
                name: nginx-server-config
            - name: html-volume
                configMap:
                name: nginx-server-config

        kubectl get pods
        
        kubectl exec -it nginx-deployment-79c5dfd58d-zwstp -- sh

![App Screenshot](images/output3.png)

![App Screenshot](images/output4.png)
## 5-task

Environment Variable

Add a static environment variable in Deployment:

* TZ: Asia/Tashkent to configure timezone.

        env:
                - name: TZ
                    value: "Asia/Tashkent"


![App Screenshot](images/output5.png)
## 6-task

 Resource Requests & Limits
Define resource requests and limits in the Deployment:
64 megabayt ram and 100 millicore cpu req
128 megabayt ram and 128 millicore cpu limit

        resources:
                requests:
                    memory: "64Mi"
                    cpu: "100m"
                limits:
                    memory: "128Mi"
                    cpu: "128m"

![App Screenshot](images/output6.png)