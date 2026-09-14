<?php

/**
 * Search configuration for Algolia Index.
 *
 * You may implement whatever search engine you want.
 * Below is a example of how you may configure Algolia.
 *
 * This is the recommended default search engine.
 * It requires a subscription, visit: algolia.com.
 */

/**
 * Search index provider configuration
 */
define('SEARCH_INDEX_PROVIDER', '(#optional:SEARCH_INDEX_PROVIDER#)');

/**
 * Typesense configuration
 */
define('SEARCH_INDEX_TYPESENSE_API_URL', '(#optional:SEARCH_INDEX_TYPESENSE_API_URL#)');
define('SEARCH_INDEX_TYPESENSE_API_KEY', '(#optional:SEARCH_INDEX_TYPESENSE_API_KEY#)');
define('SEARCH_INDEX_TYPESENSE_PUBLIC_API_KEY', '(#optional:SEARCH_INDEX_TYPESENSE_PUBLIC_API_KEY#)');
define('SEARCH_INDEX_TYPESENSE_COLLECTION_NAME', '(#optional:SEARCH_INDEX_TYPESENSE_COLLECTION_NAME#)');

/**
 * Algolia configuration
 */
define('SEARCH_INDEX_ALGOLIA_APPLICATION_ID', '(#optional:SEARCH_INDEX_ALGOLIA_APPLICATION_ID#)');
define('SEARCH_INDEX_ALGOLIA_API_KEY', '(#optional:SEARCH_INDEX_ALGOLIA_API_KEY#)');
define('SEARCH_INDEX_ALGOLIA_PUBLIC_API_KEY', '(#optional:SEARCH_INDEX_ALGOLIA_PUBLIC_API_KEY#)');
define('SEARCH_INDEX_ALGOLIA_INDEX_NAME', '(#optional:SEARCH_INDEX_ALGOLIA_INDEX_NAME#)');