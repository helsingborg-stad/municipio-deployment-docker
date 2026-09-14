<?php

if (!function_exists('env')) {
    require_once __DIR__ . '/env.php';
}

/**
 * Allows for custom configuration overrides.
 */
if (!defined('FORCE_SSL_ADMIN')) {
    define('FORCE_SSL_ADMIN', env('FORCE_SSL_ADMIN', false));
}