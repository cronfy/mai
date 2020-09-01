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
mkdir -p "$BACKUP_PATH/files"
# В коммент поместим всю имеющуюся информацию, даже если она дублиется. Лучше пусть дублируется, чем её не будет.
echo -e "Created `date` by $0\nSource: `realpath "$SOURCE_PATH"`\nTarget: $BACKUP_PATH\nName: $BACKUP_NAME" > "$BACKUP_PATH/readme-auto.txt"

echo -e "\n -- Creating files backup\n\n"
rsync -av --delete --delete-excluded --exclude bitrix/backup --exclude upload/resize_cache --exclude bitrix/cache --exclude bitrix/managed_cache --exclude bitrix/stack_cache --exclude bitrix/html_pages  "$SOURCE_PATH/" "$BACKUP_PATH/files" 

lastcommandstatus="$?"

if [ "$lastcommandstatus" != 0 ] ; then
	echo " !! Ошибка создания копии файлов ($lastcommandstatus), выхожу." >&2
	exit 1
fi

echo " -- Получилось!"

