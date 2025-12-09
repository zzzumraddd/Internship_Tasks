
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

Firewalld o‘rnatilgan serverda faqat 192.168.100.100 IP manzildan kelayotgan so‘rovlar uchun xizmatiga ruxsat bering. Boshqa foydalanuvchilar uchun bu port  bo‘lishi kerak.
HTTP va SSH ochiq bo‘lishi shart.
    
    1)CHANGING ZONE
    firewall-cmd --set-default-zone=public
changed the zone to public because the trusted zone allows all traffic by default, while public enforces firewall rules so only explicitly allowed services and IPs are accepted.
    
    2)ADDING HTTP AND SSH SERVICE
    firewall-cmd --zone=public --add-service=http -permanent
    firewall-cmd --zone=public --add-service=ssh -permanent

![App Screenshot](images/task2-1.png)

    3)Restricting submission of DNS Queries to a sinlge ip address
    sudo firewall-cmd --permanent --add-rich-rule='rule family=ipv4 source address="192.168.100.100" service name="dns" accept'
 
![App Screenshot](images/task2-2.png)

Firewalld rich rules provide an advanced, expressive language for defining granular firewall policies that go beyond basic port and service management. They offer precise control over network traffic, allowing rules based on source and destination addresses, logging, rate limiting, port forwarding, and masquerading (NAT). 

In firewalld rich rules, specifying family="ipv4" (or ipv6) explicitly tells the firewall to apply the rule only to IPv4 traffic, which is crucial when you're targeting specific source/destination IPs or forwarding traffic, as it prevents ambiguity and ensures the rule works as intended, especially if your system handles both IPv4 and IPv6, otherwise, the rule applies to both.

#Why You Need family="ipv4" (or ipv6)

Specificity: When you use IP addresses or ranges (like 192.168.1.0/24) in a rich rule, firewalld needs to know if that address is IPv4 or IPv6.

Context: If you don't provide the family, firewalld tries to guess, but this can fail or lead to unexpected behavior, particularly if you have both types of network 
interfaces or addresses configured.

Clarity: It makes your rules self-documenting and less prone to errors when you reload or manage the firewall.

![App Screenshot](images/task2-3.png)



