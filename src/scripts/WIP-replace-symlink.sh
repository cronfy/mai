#!/usr/bin/env bash


# TODO: нужно 
# 1. передавать старый/новый путь аргументами
# 2. Параметром определять, заменять ли относительные ссылки (../site2.ru/bitrix) или только абсолютные

#
# НАСТРОЙКИ
#
# старый путь и новый путь
# особое внимание нужно уделить слешу в конце: его либо у обоих не должно быть, либо должен быть и там и там
#

oldRoot="/var/www/user/data/www/site.ru"
newRoot="/var/www/user/data/www/site.ru/www"





# 
# Работаем
#

cd `dirname $0`

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


GO="$1"

#checkDocumentRoot "$oldRoot" || { echo " !! Root check failed, exiting" >&2 ;  exit 1 ; }
checkDocumentRoot "$newRoot" || { echo " !! Root check failed, exiting" >&2 ;  exit 1 ; }

find ./ -maxdepth 3 -mindepth 2 -type l | while read symlink ; do
	# тут нам надо посмотреть, куда показывает симлинк, а не куда он в итоге приходит, поэтому используем readlink, а не realpath
	real="`readlink "$symlink"`"

	# может, он уже поменян?
	relative="${real##$newRoot}"
	if [ "$relative" != "$real" ] ; then
		echo -e " -- Symlink $symlink => $real $relative --- already new"
		continue
	fi

	#
	# эти проверки больше для отладки, ну или для большей строгости
	#

	ok=false

	if [ "$real" = "$oldRoot/bitrix" ] ; then
		ok=true
	fi

	if [ "$real" = "$oldRoot/images" ] ; then
		ok=true
	fi

	if [ "$real" = "$oldRoot/upload" ] ; then
		ok=true
	fi


	if [ "$real" = "$oldRoot/prays" ] ; then
		ok=true
	fi

	if [ "$real" = "$oldRoot/usloviya_rabot" ] ; then
		ok=true
	fi

	if [ "$real" = "$oldRoot/poleznaya-informatsiya" ] ; then
		ok=true
	fi

	if [ "$real" = "$oldRoot/catalog" ] ; then
		ok=true
	fi

	if [ "$real" = "$oldRoot/prays-list" ] ; then
		ok=true
	fi

	if [ "$real" = "$oldRoot/brands" ] ; then
		ok=true
	fi

	if [ "$real" = "$oldRoot/uslugi-i-servis" ] ; then
		ok=true
	fi

	if [ "$real" = "$oldRoot/delivery" ] ; then
		ok=true
	fi

	if [ "$real" = "$oldRoot/prays-listy" ] ; then
		ok=true
	fi

	if [ "$real" = "$oldRoot/suppliers" ] ; then
		ok=true
	fi

	if [ "$real" = "$oldRoot/contacts" ] ; then
		ok=true
	fi

	if [ "$real" = "$oldRoot/faq" ] ; then
		ok=true
	fi

	if [ "$ok" != "true" ] ; then
		echo " ** Symlink $symlink => $real --- not recognized"
		continue
	fi

	relative="${real##$oldRoot}"

	if [ "$relative" = "$real" ] ; then
		echo " !! Failed to truncate old root, exiting." >&2
		exit 1
	fi

	newPath="${newRoot}${relative}"

	[ ! -d "$newPath" ] && {
		echo " !! $symlink -> $real -> $newPath --- MISS (target directory does not exist)"
		exit 1
	}
	
	if [ "$newPath" = "$real" ] ; then
		echo " !! $symlink -> $real -> $newPath --- NOTHING CHANGED!"
		exit 1
	fi

	if [ "$GO" = "go" ] ; then
		echo "$symlink -> $real -> $newPath --- CHANGING"

		ln -nfs "$newPath" "$symlink" || {
			echo 
		}
	else
		echo "$symlink -> $real -> $newPath --- (DEMO)"
	fi	


done

if [ "$GO" != "go" ] ; then
	echo
	echo " ** Это был демо-режим, для реальной работы запустите меня с аргументом 'go'" 
	echo
fi

