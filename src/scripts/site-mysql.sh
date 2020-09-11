#!/usr/bin/env bash

SCRIPT_DIR="`dirname $0`"

SOURCE_PATH="$1"
[ -z "$SOURCE_PATH" ] && {
	echo "Syntax: `basename $0` <document_root>" >&2
	exit 1
}

shift

SHOW_INFO=false
[ "-i" = "$1" ] && {
	shift
	SHOW_INFO=true
}

function checkDocumentRoot() {
        local path="$1"

        [ ! -d "$path" ] && {
                echo " ** Root $path is not an existing directory"
                return 1
        }

        [ ! -d "$path/bitrix" ] && {
                echo " ** Root $path does not contain bitrix/"
                return 1
        }

        return 0
}

[ -z "$SOURCE_PATH" ] && {
	echo "Syntax: `basename $0` <source_document_root>" >&2
	exit 1
}


checkDocumentRoot "$SOURCE_PATH" || {
	echo " !! Failed to check source document root, exiting." >&2
	exit 1
}

mysqlArgs="`php "$SCRIPT_DIR/get-mysql-command-args.php" "$SOURCE_PATH"`"

[ -z "$mysqlArgs" ] && {
	echo " !! Failed to get Mysql credentials, exiting." >&2
	exit 1
}

eval set -- $mysqlArgs "$@"

username="$1"
password="$2"
host="$3"
dbname="$4"

credFile=`mktemp`
echo "$credFile"

if [ "$SHOW_INFO" = "true" ] ; then
	echo "mysql -u \"$username\" -p\"$password\" -h \"$host\" \"$dbname\""
	exit
fi

# удалим файл как только подключимся к mysql
(sleep 5 ; rm -f "$credFile") &

echo "
[mysql]
host=\"$host\"
database=\"$dbname\"
password=\"$password\"
user=\"$username\"
" > "$credFile"

shift 4

mysql --defaults-extra-file="$credFile" "$@" 
# и на всякий случай еще раз удалим
rm -f "$credFile"


