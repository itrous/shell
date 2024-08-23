#!/bin/bash

# Проверяем, передан ли параметр
if [ -z "$1" ]; then
  echo "Пожалуйста, укажите путь к установочному файлу."
  exit 1
fi

# Проверяем, передано ли имя сервера
if [ -z "$2" ]; then
  echo "Пожалуйста, укажите одно или несколько имен серверов через запятую."
  exit 1
fi

# Получаем путь к установочному файлу из параметра
installer_path="$1"

# Получаем список серверов из второго параметра
server_list="$2"

# Проверяем, передан ли параметр -debug
debug_flag=""
if [[ "$3" == "-debug" ]]; then
  debug_flag="-debug"
fi

# Извлекаем версию из имени файла
NEW_VERSION=$(basename "$installer_path" | grep -oP '\d+\.\d+\.\d+\.\d+')

if [ -z "$NEW_VERSION" ]; then
  echo "Не удалось определить версию из имени файла $installer_path"
  exit 1
fi

# Разбиваем список серверов на массив
IFS=',' read -ra SERVERS <<< "$server_list"

# Проходим по каждому серверу и выполняем обновление
for server_name in "${SERVERS[@]}"; do
  echo "Обновление сервера: $server_name"

  # Копируем установочный файл и скрипт на удаленный сервер
  scp "$installer_path" ubuntu@"$server_name":~/
  scp 1c-install.sh ubuntu@"$server_name":~/

  # Выполняем скрипт на удаленном сервере, передавая путь к установочному файлу и флаг отладки, если он есть
  ssh ubuntu@"$server_name" "sudo bash ~/1c-install.sh ~/$(basename "$installer_path") $debug_flag"

  echo "Обновление сервера $server_name завершено."
done
