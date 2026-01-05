
# Networking 3-lesson




# 1-task

Configure Nginx to serve two sites based on different hostnames.

![App Screenshot](images/task1-1.png)

![App Screenshot](images/task1-2.png)

![App Screenshot](images/task1-3.png)

![App Screenshot](images/task1-4.png)

![App Screenshot](images/task1-5.png)

![App Screenshot](images/task1-6.png)
# 2-task

Enable Gzip compression in Nginx for faster loading.

![App Screenshot](images/task2-1.png)

![App Screenshot](images/task2-2.png)
## 3-task

Research how Nginx can be used as a load balancer (prepare config file).

NGINX can act as a reverse proxy that sits in front of multiple backend servers. Incoming client requests are received by NGINX and then distributed across backends using a load-balancing algorithm (by default, round-robin). This improves scalability, availability, and fault tolerance: if one backend is slow or unavailable, traffic is sent to others.

    upstream backend {
        server 10.0.0.1;
        server 10.0.0.2;
    }

    server {
        listen 80;
        location / {
            proxy_pass http://backend;
        }
    }






