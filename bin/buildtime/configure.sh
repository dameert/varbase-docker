#!/bin/bash

cat >> /opt/src/varbase/docroot/sites/default/settings.php << EOL
$settings['install_profile'] = 'varbase';
$settings['hash_salt'] = getenv('HASH_SALT');
$settings['trusted_host_patterns'] = getenv('TRUSTED_HOST_PATTERNS');

$databases['default']['default'] = [
  'database' => getenv('MYSQL_DATABASE'),
  'driver' => 'mysql',
  'host' => getenv('MYSQL_HOST'),
  'namespace' => 'Drupal\\Core\\Database\\Driver\\mysql',
  'password' => urlencode(getenv('MYSQL_PASSWORD')),
  'port' => getenv('MYSQL_PORT'),
  'prefix' => '',
  'username' => getenv('MYSQL_USER'),
];

$https = getenv('FORCE_HTTPS');
if (false !== $https) {
    $settings['https'] = TRUE;
    $_SERVER['HTTPS'] = 'on';
}

$syncDir = getenv('CONFIG_SYNC_DIRECTORY');
if (false !== $syncDir) {
 $config_directories['sync'] = getenv('CONFIG_SYNC_DIRECTORY');
}

EOL
