#!/bin/bash

yum install httpd php -y
systemctl enable httpd
systemctl restart httpd

cat <<EOF > /var/www/html/index.php
<?php
\$output = shell_exec('echo $HOSTNAME');
echo "<h1><center><pre>\$output</pre></center></h1>";
echo "<h1><center><pre>  Version2  </pre></center></h1>";
?>
EOF
