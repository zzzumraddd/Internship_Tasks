
# 8-lesson Security(Firewall & SELinux)




# 1-task
Web-server deb nomlangan serverga faqat quyidagi trafikni ruxsat bering:
22 (ssh)
80 (http)
443 (https)
Lekin  faqat 192.168.56.0/24 tarmoqdan ochiq bo‘lishi kerak.
Boshqa barcha trafik  qilinsin.
ufw status verbose orqali to‘g‘ri ishlayotganini isbotlang.

    1) SETTING THE HOSTNAME
    sudo hostname set-hostname web-server
    2) (INSTALLING UFW FOR CENTOS)
    ENABLE EPEL REPOSITORY:
    sudo dnf install epel-release -y
    sudo systemctl start ufw
    3) ALLOWING THE FOLLOWING TRAFFIC THROUGH THE GIVEN IP ADRESS
    sudo ufw allow from 192.168.56.0/24 to any port <port-number>
![App Screenshot](images/task1-1.png)

    4) Deny or delete all incoming traffic by default system
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
![App Screenshot](images/task1-2.png)
![App Screenshot](images/task1-3.png)

Moments occured and fixed outside the given task
(P.s. some rules that needed to be deleted and how they were deleted)
![App Screenshot](images/task1-4.png)
## 2-task
