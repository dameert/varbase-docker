#!/bin/bash

function check-env-variables {
  if [[ ! -n ${MYSQL_DATABASE} ]]; then
    echo "Variable MYSQL_DATABASE is required"
    exit 1
  fi
  if [[ ! -n ${MYSQL_HOST} ]]; then
    echo "Variable MYSQL_HOST is required"
    exit 1
  fi
  if [[ ! -n ${MYSQL_PASSWORD} ]]; then
    echo "Variable MYSQL_PASSWORD is required"
    exit 1
  fi
  if [[ ! -n ${MYSQL_PORT} ]]; then
    echo "Variable MYSQL_PORT is required"
    exit 1
  fi
  if [[ ! -n ${MYSQL_USER} ]]; then
    echo "Variable MYSQL_USER is required"
    exit 1
  fi
  if [[ ! -n ${HASH_SALT} ]]; then
    echo "Variable HASH_SALT is required"
    exit 1
  fi
  if [[ ! -n ${TRUSTED_HOST_PATTERNS} ]]; then
    echo "Variable TRUSTED_HOST_PATTERNS is required"
    exit 1
  fi
}

function create-wrapper-scripts {
  local -r _instance_name=$1

  mkdir -p /opt/bin/ems-jobs

  cat >/opt/bin/$_instance_name <<EOL
#!/bin/bash
# This script is autogenerated by the container startup script
set -o allexport
source /tmp/$_instance_name
set +o allexport

if [ \${1:-list} = sql ] || [ \${1:-list} = dump ] ; then
  if [ \${1:-list} = sql ] ; then
    mysql --port=\$DB_PORT --host=\$DB_HOST --user=\$DB_USER --password=\$DB_PASSWORD \$DB_NAME
  else
    mysqldump --port=\$DB_PORT --host=\$DB_HOST --user=\$DB_USER --password=\$DB_PASSWORD \$DB_NAME
  fi;
else
  export VARBASE_PROCESS_COMMAND=$_instance_name
  /opt/src/vendor/drush/drush/drush \$@
fi;
EOL

  chmod a+x /opt/bin/$_instance_name

}

function create-apache-vhost {
  local -r _name=$1

  echo "Configure Apache Virtual Host for [ $_name ] CMS Domain ..."

  if [ -f /etc/apache2/conf.d/$_name.conf ] ; then
    rm /etc/apache2/conf.d/$_name.conf
  fi

  cat > /etc/apache2/conf.d/$_name.conf <<EOL
# This VirtualHost is autogenerated by the container startup script
<VirtualHost *:9000>
    ServerName $SERVER_NAME
EOL

  if ! [ -z ${SERVER_ALIASES+x} ]; then
    echo "Configure Apache ServerAlias [ ${SERVER_ALIASES} ] ..."
    cat >> /etc/apache2/conf.d/$name.conf << EOL
    ServerAlias $SERVER_ALIASES
EOL
  fi

  cat >> /etc/apache2/conf.d/$_name.conf << EOL

    # Uncomment the following line to force Apache to pass the Authorization
    # header to PHP: required for "basic_auth" under PHP-FPM and FastCGI
    #
    # SetEnvIfNoCase ^Authorization$ "(.+)" HTTP_AUTHORIZATION=\$1

    # For Apache 2.4.9 or higher
    # Using SetHandler avoids issues with using ProxyPassMatch in combination
    # with mod_rewrite or mod_autoindex
    <FilesMatch \.php\$>
        SetHandler "proxy:unix:/var/run/php-fpm/php-fpm.sock|fcgi://localhost/"
    </FilesMatch>

    Header always append X-Frame-Options DENY
    Header always append X-XSS-Protection 1
    Header always append X-Content-Type-Options nosniff

    RewriteEngine on
    RewriteCond %{HTTP_HOST} !$VHOST_DOMAIN$ [NC]
    RewriteCond %{QUERY_STRING} (^|&)q=(user(/|$)|users(/|$)|admin(/|$)|node(/|$)) [NC,OR]
    RewriteCond %{REQUEST_URI} /(admin|user|users|node)(/|$) [NC,OR]
    RewriteCond %{REQUEST_URI} /(update.php|install.php)$ [NC]
    RewriteRule . - [F]

    RewriteCond %{HTTP_HOST} !$VHOST_DOMAIN$ [NC]
    RewriteCond %{REQUEST_URI} files/webform [NC]
    RewriteRule . - [F]

    DocumentRoot /opt/src/docroot
    <Directory /opt/src/docroot >
        # enable the .htaccess rewrites
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /dev/stderr
    CustomLog /dev/stdout common

EOL

  echo "Configure Apache Environment Variables ..."
  cat /tmp/$_name | sed '/^\s*$/d' | grep  -v '^#' | sed "s/\([a-zA-Z0-9_]*\)\=\(.*\)/        SetEnv \1 \2/g" >> /etc/apache2/conf.d/$_name.conf

  cat >> /etc/apache2/conf.d/$_name.conf << EOL

</VirtualHost>
EOL

  echo "Apache Virtual Host for [ $_name ] CMS Domain configured successfully ..."

}

function configure {
  local -r _name=$1

  local -r _today=$(date +"%Y_%m_%d")

  check-env-variables
  create-apache-vhost "${_name}"
  create-wrapper-scripts "${_name}"

  for filename in $(ls /opt/bin/extra)
  do
    basefilename = $(basename $filename);
    if [[ -n $(env | grep VARBASE_EXEC_${basefilenameˆˆ}) ]]; then
      source /opt/bin/extra/${filename}
    fi
  done

  echo "[INFO] Run /opt/bin/drush/update.sh manually in order to launch database updates and cache clear."
  echo "[INFO] Staging script support is experimental. It can be launched manually using the existing stage.sh scripts."

}

function install {

  if [ ! -z "$AWS_S3_CONFIG_BUCKET_NAME" ]; then
    echo "Found AWS_S3_CONFIG_BUCKET_NAME environment variable.  Reading properties files ..."

    export AWS_S3_CONFIG_BUCKET_NAME=${AWS_S3_CONFIG_BUCKET_NAME#s3://}

    list=(`aws s3 ls ${AWS_S3_CONFIG_BUCKET_NAME%/}/ ${AWS_CLI_EXTRA_ARGS} | awk '{print $4}'`)

    for config in ${list[@]};
    do

      name=${config%.*}

      echo "Install [ $name ] CMS Domain from S3 Bucket [ $config ] file ..."

      aws s3 cp s3://${AWS_S3_CONFIG_BUCKET_NAME%/}/$config ${AWS_CLI_EXTRA_ARGS} - | envsubst > /tmp/$name
      source /tmp/$name

      configure "${name}"

      echo "Install [ $name ] CMS Domain from S3 Bucket [ $config ] file successfully ..."

    done

  elif [ "$(ls -A /opt/secrets)" ]; then

    echo "Found '/opt/secrets' folder with files.  Reading properties files ..."

    for file in /opt/secrets/*; do

      filename=$(basename $file)
      name=${filename%.*}

      echo "Install [ $name ] CMS Domain from FS Folder /opt/secrets/ [ $filename ] file ..."

      envsubst < $file > /tmp/$name
      source /tmp/$name

      configure "${name}"

      echo "Install [ $name ] CMS Domain from FS Folder /opt/secrets/ [ $filename ] file successfully ..."

    done

  elif [ "$(ls -A /opt/configs)" ]; then

    echo "Found '/opt/configs' folder with files.  Reading properties files ..."

    for file in /opt/configs/*; do

      filename=$(basename $file)
      name=${filename%.*}

      echo "Install [ $name ] CMS Domain from FS Folder /opt/configs/ [ $filename ] file ..."

      envsubst < $file > /tmp/$name
      source /tmp/$name

      configure "${name}"

      echo "Install [ $name ] CMS Domain from FS Folder /opt/configs/ [ $filename ] file successfully ..."

    done

  else

    echo "Install [ default ] CMS Domain from Environment variables ..."

    touch /tmp/default

    configure "default"

    echo "Install [ default ] CMS Domain from Environment variables successfully ..."

  fi

}

if [ ! -z "$AWS_S3_ENDPOINT_URL" ]; then
  echo "Found AWS_S3_ENDPOINT_URL environment variable.  Add --endpoint-run argument to AWS CLI"
  AWS_CLI_EXTRA_ARGS="--endpoint-url ${AWS_S3_ENDPOINT_URL}"
fi

install
