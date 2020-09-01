<?php

/*
Использование в bash:

mysqlArgs="`php "$SCRIPT_DIR/get-mysql-command-args.php" "$SOURCE_PATH"`"

[ -z "$mysqlArgs" ] && {
        echo " !! Failed to get Mysql credentials, exiting." >&2
        exit 1
}

eval set -- $mysqlArgs

username="$1"
password="$2"
host="$3"
dbname="$4"

echo -e "\n -- Creating database backup\n\n"
mysqldump -u "$username" -p"$password" -h "$host" "$dbname"  | gzip > "$BACKUP_PATH/db.sql.gz"

 */
$bitrixPath = @$argv[1];

if (!$bitrixPath) {
	echo "Syntax: {$srgv[0]} <bitrix_document_root>\n";
	exit(1);
}

$settings = require "$bitrixPath/bitrix/.settings.php";

$dbSettings = $settings['connections']['value']['default'];

$vars = [
	'login' => $dbSettings['login'],
 	'password' => $dbSettings['password'],
	'host' => $dbSettings['host'],
	'database' => $dbSettings['database'],
];

foreach ($vars as $name => $arg) {
	if (!preg_match('/^[a-zA-Z0-9_.@#$%^-]*$/', $arg)) {
		throw new \Exception("Maybe wrong characters in $name: $arg");
	}
}

// выводим здесь только переменные в одинарных кавычках, чтобы можно было раскрыть в bash через 
// eval set -- $vars
$mysqlArgs = "'{$vars['login']}' '{$vars['password']}' '{$vars['host']}' '{$vars['database']}'";

echo $mysqlArgs . "\n";


