<?php

/**
* Memcache/Redis key salt
* @var string
*/
define('WP_CACHE_KEY_SALT', md5(NONCE_KEY));

/**
 * Use redis.
 * @var bool
 */
define('WP_REDIS_DISABLED', "(#WP_REDIS_DISABLED|false#)");

/**
 * Redis hostname.
 * @var string
 */
define('WP_REDIS_HOST', '(#optional:REDIS_HOST#)');

/**
 * Use memcached.
 * @var bool
 */
define('WP_USE_MEMCACHED', "(#WP_USE_MEMCACHED|false#)");
