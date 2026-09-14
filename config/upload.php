<?php

/**
* Allow unfiltered uploads.
* This should not be used in production.
*/

define('ALLOW_UNFILTERED_UPLOADS', "(#ALLOW_UNFILTERED_UPLOADS|false#)");

/**
* Set upload max file size. This may
* also be changed in configuration of the machine.
*/
define('UPLOAD_MAX_FILESIZE', "(#UPLOAD_MAX_FILESIZE|64M#)");