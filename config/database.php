<?php

// ** MySQL settings - You can get this info from your web host ** //

/** The name of the database for WordPress */
define('DB_NAME', '(#DB_NAME#)');

/** MySQL database username */
define('DB_USER', '(#DB_USER#)');

/** MySQL database password */
define('DB_PASSWORD', '(#DB_PASSWORD#)');

/** MySQL hostname */
define('DB_HOST', "(#DB_HOST#)");

/** Database Charset to use in creating database tables. */
define('DB_CHARSET', "(#DB_CHARSET|utf8mb4#)");

/** The Database Collate type. Don't change this if in doubt. */
define('DB_COLLATE', "(#DB_COLLATE|utf8_general_ci#)");

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix  = '(#DB_TABLE_PREFIX#)'; //Should not be wp_ for improved security.
