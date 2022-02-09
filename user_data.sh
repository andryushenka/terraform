#!/bin/bash
yum update -y
yum install httpd -y 

myip=`curl http://169.254.169.254/latest/meta-data/local-ipv4`

cat <<EOF > /var/www/html/index.html
<html>
<body bgcolor="black">
<h2><font color="gold">Build by Terraform (c)HashoCorp <font color="red"> v1.1.5</font></h2><br><p>
<font color="green">Private IP of Servre: <font color="aqua">$myip<br><br>

<font color="magenta">
<b>Version 1.0</b>
</body>
</html>
EOF

sudo service httpd start 
chkconfig httpd on