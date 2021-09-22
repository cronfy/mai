#!/usr/bin/env php
<?php

/*
Использование: в текущей директории (в которой находятся сайты) нужно создать файл .maintenance.plan,
перечислить там сайты, которые нужно переключать, после чего запустить скрипт.
*/

set_error_handler(
    function ($code, $message, $file = '', $line = 0) {
            if (error_reporting() === 0) {
                // Это либо экранирование через @.
                // Либо в настройках сервера указано error_reporting === 0 (или где-то
                // в скриптах установлено через error_reporting(0)).
                //
                // В первом случае мы обязаны не обрабатывать эту ошибку.

                // Но отличить первое от второго возможности нет.

                // Поэтому вы в любом случае должны эту ошибку проигнорировать.
		// false передает ошибку внутреннему обработчику ошибок
		return false;
            }

	throw new \Exception("Error code $code: $message, $file:$line");
    },
    E_ALL
);

class Maintenancer {

	protected function getFolders() {
		$plan = file(getcwd() . '/.maintenance.plan');

		$result = [];
		foreach ($plan as $line) {
			// удаляем комментарии
			$line = preg_replace('/^(\s*#.*)/', '', $line);
			// удаляем пустоту
			$line = trim($line);
			if (!$line) {
				continue;
			}

			$dir = $line;

			if (!is_dir(getcwd() . '/' . $dir)) {
				throw new \Exception("Directory $dir from maintenance.plan not found.");
			}

			$result[] = $line;
		}

		return $result;
	}

	protected function isSiteCanBeSwitched($dir) {
		// должны быть папки: папка сайта и папка либо .maint, либо .prod

		if (is_dir(getcwd() . "/$dir") && is_dir(getcwd() . "/$dir.maint")) {
			return true;
		}
		if (is_dir(getcwd() . "/$dir") && is_dir(getcwd() . "/$dir.prod")) {
			return true;
		}
		return false; // can not switch
	}


	protected function checkAllSwitchable() {
		$ok = true;
		foreach ($this->getFolders() as $dir) {
			if (!$this->isSiteCanBeSwitched($dir)) {
				echo " !! Site $dir can not be switched\n";
				$ok = false;
			}
		}

		return $ok;
	}

	protected function showSyntax() {
		global $argv;

		echo "Syntax: " . basename($argv[0]) . " check|enable|disable\n";
	}

	protected function enableMaintenanceOnSite($dir) {
		if (is_dir(getcwd() . "/$dir.prod") && is_dir(getcwd() . "/$dir")) {
			echo " -- Site $dir -- ALREADY on maintenance\n";
			return;
		}

		if (is_dir(getcwd() . "/$dir.maint") && is_dir(getcwd() . "/$dir")) {
			rename($dir, $dir . ".prod");
			rename($dir . ".maint", $dir);
			echo " -- Site $dir -- site DISABLED\n";
			return;
		}

		throw new \Exception("Failed to disable site on $dir");
	}

	protected function disableMaintenanceOnSite($dir) {
		if (is_dir(getcwd() . "/$dir.maint") && is_dir(getcwd() . "/$dir")) {
			echo " -- Site $dir -- ALREADY on prod\n";
			return;
		}

		if (is_dir(getcwd() . "/$dir.prod") && is_dir(getcwd() . "/$dir")) {
			rename($dir, $dir . ".maint");
			rename($dir . ".prod", $dir);
			echo " -- Site $dir -- site ENABLED\n";
			return;
		}

		throw new \Exception("Failed to enable site on $dir");
	}

	public function run() {
		global $argv;

		if (!$action = @$argv[1])	{
			$this->showSyntax();
			exit(1);
		}

			$ok = $this->checkAllSwitchable();

		switch ($action) {
		case 'check':
			if ($ok) {
				echo " -- All sites in plan can be switched:\n\n";
				foreach ($this->getFolders() as $dir) {
					echo "    $dir\n";
				}
				echo "\n";
				exit(0);
			}

			echo "\n !! Not all sites can be switched!\n\n";
			exit(1);
			break;
		case 'disable':
			if (!$ok) {
				echo " !! Some sites can not be switched, exiting.\n";
				exit(1);
			}
			foreach ($this->getFolders() as $dir) {
				$this->enableMaintenanceOnSite($dir);
			}
			echo "\n -- All done\n";
			exit(0);
			break;
		case 'enable':
			if (!$ok) {
				echo " !! Some sites can not be switched, exiting.\n";
				exit(1);
			}
			foreach ($this->getFolders() as $dir) {
				$this->disableMaintenanceOnSite($dir);
			}
			echo "\n -- All done\n";
			exit(0);
			break;
		default:
			echo " !! Unknown action $action\n";
			$this->showSyntax();
			exit(1);

		}
	}
}


$maintenancer = new Maintenancer();

$maintenancer->run();


