<?php

/**
 * Tell WordPress to be used as network
 */

define('WP_ALLOW_MULTISITE', '(#WP_ALLOW_MULTISITE#)');

if(defined('WP_ALLOW_MULTISITE') && WP_ALLOW_MULTISITE) {
  define('MULTISITE', true);
  define('SUBDOMAIN_INSTALL', '(#SUBDOMAIN_INSTALL#)');
  define('DOMAIN_CURRENT_SITE', '(#DOMAIN_CURRENT_SITE#)');
  define('PATH_CURRENT_SITE','/');
  define('SITE_ID_CURRENT_SITE', 1 );
  define('BLOG_ID_CURRENT_SITE', 1 );
}