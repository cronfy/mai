#!/usr/bin/env bash

SCRIPT_DIR="`dirname $0`"

BACKUP_ROOT="$HOME/backup"

SOURCE_PATH="$1"
BACKUP_NAME="$2"

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
	echo "Syntax: `basename $0` <source_document_root> <backup_name>" >&2
	exit 1
}

[ -z "$BACKUP_NAME" ] && {
	echo "Syntax: `basename $0` <source_document_root> <backup_name>" >&2
	exit 1
}


checkDocumentRoot "$SOURCE_PATH" || {
	echo " !! Failed to check source document root, exiting." >&2
	exit 1
}

BACKUP_PATH="$BACKUP_ROOT/$BACKUP_NAME"

[ -e "$BACKUP_PATH" ] && {
	answer=""
	while true ; do
		read -p " ** Папка $BACKUP_PATH уже существует. Файлы в ней будут перезаписаны. Продолжить (y/n)? " answer
		
		[ "$answer" == "n" ] && echo " !! Ok, выхожу." && exit 1
		[ "$answer" == "y" ] && break
	done

}

#rm -rf "$BACKUP_PATH"
mkdir -p "$BACKUP_PATH"

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

# В коммент поместим всю имеющуюся информацию, даже если она дублиется. Лучше пусть дублируется, чем её не будет.
echo -e "Created `date` by $0\nSource: `realpath "$SOURCE_PATH"`\nTarget: $BACKUP_PATH\nName: $BACKUP_NAME" > "$BACKUP_PATH/readme-db-auto.txt"

echo -e "\n -- Creating database backup\n\n"
mysqldump -u "$username" -p"$password" -h "$host" "$dbname"  | gzip > "$BACKUP_PATH/db.sql.gz"

# не разделять не несколько строк, а то перестанет работать!
dumpstatus="${PIPESTATUS[0]}" lastcommandstatus="$?"

if [ "$lastcommandstatus" != 0 ] || [ "$dumpstatus" != "0" ] ; then
	echo " !! Ошибка создания дампа Mysql ($lastcommandstatus) ($dumpstatus), выхожу." >&2
	exit 1
fi

echo " -- Получилось!"

