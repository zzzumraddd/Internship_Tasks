
# Docker HW



## 1-task

    docker build -t myflask:latest .

    docker run -d -p 5000:5000 --name flask_app myflask:latest
## 1-task

    docker build -t myflask:latest .

    docker run -d -p 5000:5000 --name flask_app myflask:latest
## 2-task

    docker-compose up -d
    
    curl http://localhost:5001/hello


## 3-task

    1. Initialize Swarm
    docker swarm init

    2. Build the image first (Swarm needs pre-built images)
    docker build -t myflaskapp:latest .

    3. Deploy stack
    docker stack deploy -c docker-stack.yml myapp

    4. Check status (should show 3 replicas)
    docker stack services myapp
    docker stack ps myapp

    5. Test
    curl http://localhost:5001/hello
    curl http://localhost:5001/db
## 4-task

    docker scout cves myflaskapp:latest > original-scan.txt

DOCKER IMAGE SECURITY ANALYSIS REPORT

Image Scanned: myflaskapp:latest
Scanner: Docker Scout

FINDINGS:
- Total Vulnerabilities: 4
- Severity: 0 Critical, 0 High, 4 Medium, 0 Low
- Affected Packages:
  1. werkzeug 3.1.3 (2 CVEs)
  2. pip 25.0.1 (1 CVE)
  3. busybox 1.37.0 (1 CVE)

EASY FIXES:
1. Update Werkzeug: 3.1.3 → 3.1.5 (fixes 2 CVEs)
2. Use python:3.12-slim instead of alpine (removes busybox CVE)
3. Update pip during build

PROPOSED IMPROVEMENTS:
- Switch base image from alpine to slim
- Update requirements.txt with latest versions
- Add non-root user for security
- Implement multi-stage build