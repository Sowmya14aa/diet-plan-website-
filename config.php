<?php
// Database configuration
define('DB_HOST', 'localhost');
define('DB_NAME', 'diet_plan_db');
define('DB_USER', 'root');
define('DB_PASS', '');

// For production, use environment variables
if (isset($_ENV['DATABASE_URL'])) {
    $db_url = parse_url($_ENV['DATABASE_URL']);
    define('DB_HOST', $db_url['host']);
    define('DB_NAME', ltrim($db_url['path'], '/'));
    define('DB_USER', $db_url['user']);
    define('DB_PASS', $db_url['pass']);
}
?>