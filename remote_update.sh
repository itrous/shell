#!/bin/bash

# Проверяем, передан ли параметр
if [ -z "$1" ]; then
  echo "Пожалуйста, укажите путь к установочному файлу."
  exit 1
fi

# Проверяем, передано ли имя сервера
if [ -z "$2" ]; then
  echo "Пожалуйста, укажите имя сервера."
  exit 1
fi

# Получаем путь к установочному файлу из параметра
installer_path="$1"

# Получаем имя сервера из второго параметра
server_name="$2"

# Копируем установочный файл и скрипт на удаленный сервер
scp "$installer_path" ubuntu@"$server_name":~/
scp 1c-install.sh ubuntu@"$server_name":~/

# Выполняем скрипт на удаленном сервере, передавая путь к установочному файлу
ssh ubuntu@"$server_name" "sudo bash ~/1c-install.sh ~/$(basename "$installer_path")"
