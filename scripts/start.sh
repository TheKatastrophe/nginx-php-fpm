#!/bin/bash

if [ ! -e /.first-run-complete ]; then

  # Install Extras
  if [ ! -z "$RPMS" ]; then
   yum install -y $RPMS
  fi

  # Install Composer globally
  php -r "readfile('https://getcomposer.org/installer');" > /tmp/composer-setup.php
  php /tmp/composer-setup.php -- --install-dir=/usr/bin --filename=composer
  php -r "unlink('/tmp/composer-setup.php');"

  # Display PHP error's or not
  if [[ "$ERRORS" == "true" ]] ; then
    sed -i -e "s/error_reporting =.*/error_reporting = E_ALL/g" /etc/php.ini
    sed -i -e "s/display_errors =.*/display_errors = On/g" /etc/php.ini
  fi

  # Create path for PHP sessions
  mkdir -p -m 0777 /var/lib/php/session

  # Set PHP timezone
  if [ -z "$PHPTZ" ]; then
    PHPTZ="Europe/London"
  fi
  echo date.timezone = $PHPTZ >>/etc/php.ini

  # Tweak nginx to match the workers to cpu's

  procs=$(cat /proc/cpuinfo |grep processor | wc -l)
  sed -i -e "s/worker_processes 5/worker_processes $procs/" /etc/nginx/nginx.conf

  echo "Do not remove this file." > /.first-run-complete
fi

# Again set the right permissions (needed when mounting from a volume)
chown -Rf nginx.nginx /usr/share/nginx/html/

# Start supervisord and services
/usr/bin/supervisord -n -c /etc/supervisord.conf
