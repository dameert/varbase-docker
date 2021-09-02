#!/bin/bash

##ici les drush
echo "Drush status"
/opt/src/bin/drush status -y -v -r /opt/src/docroot
echo "Drush cache-rebuild"
/opt/src/bin/drush cache-rebuild -y -v -r /opt/src/docroot
echo "Drush updatedb"
/opt/src/bin/drush updatedb -y -v -r /opt/src/docroot
echo "Drush entup"
/opt/src/bin/drush entup -y -v -r /opt/src/docroot
echo "Drush cache-rebuild"
/opt/src/bin/drush cache-rebuild -y -v -r /opt/src/docroot
