#!/bin/bash

# Проверяем, передан ли путь к установочному файлу
if [ -z "$1" ]; then
  echo "Пожалуйста, укажите путь к установочному файлу."
  exit 1
fi

# Проверяем, передан ли список серверов
if [ -z "$2" ]; then
  echo "Пожалуйста, укажите одно или несколько имен серверов через запятую."
  exit 1
fi

# Получаем путь к установочному файлу из параметра
installer_path="$1"

# Получаем список серверов из второго параметра
server_list="$2"

# Инициализируем флаги
web_mode=false
debug_flag=""

# Обрабатываем дополнительные параметры
for arg in "$@"; do
  if [[ "$arg" == "-web" ]]; then
    web_mode=true
  elif [[ "$arg" == "-debug" ]]; then
    debug_flag="-debug"
  fi
done

# Извлекаем версию из имени файла
NEW_VERSION=$(basename "$installer_path" | grep -oP '\d+\.\d+\.\d+\.\d+')

if [ -z "$NEW_VERSION" ]; then
  echo "Не удалось определить версию из имени файла $installer_path"
  exit 1
fi

# Разбиваем список серверов на массив
IFS=',' read -ra SERVERS <<< "$server_list"

# Проходим по каждому серверу и выполняем соответствующее обновление
for server in "${SERVERS[@]}"; do
  if $web_mode; then
    echo "Обновление веб-сервера: $server"

    # Копируем установочный файл на веб-сервер
    scp "$installer_path" ubuntu@"$server":~/docker/web/

    # Устанавливаем права на выполнение
    ssh ubuntu@"$server" "chmod 751 ~/docker/web/$(basename "$installer_path")"

    # Выполняем команды на веб-сервере
    ssh ubuntu@"$server" "
      cd ~/docker/web/ &&
      sed -i 's|LoadModule _1cws_module \"/opt/1cv8/x86_64/.*/wsap24.so\"|LoadModule _1cws_module \"/opt/1cv8/x86_64/$NEW_VERSION/wsap24.so\"|' httpd.conf &&
      docker compose build &&
      docker compose up -d
    "

    # Удаляем установочный файл после использования
    ssh ubuntu@"$server" "rm -f ~/docker/web/$(basename "$installer_path")"

    echo "Обновление веб-сервера $server завершено."
  else
    echo "Обновление сервера: $server"

    # Копируем установочный файл и скрипт на удаленный сервер
    scp "$installer_path" ubuntu@"$server":~/
    scp 1c-install.sh ubuntu@"$server":~/

    # Выполняем скрипт на удаленном сервере, передавая путь к установочному файлу и флаг отладки, если он есть
    ssh ubuntu@"$server" "sudo bash ~/1c-install.sh ~/$(basename "$installer_path") $debug_flag"

    echo "Обновление сервера $server завершено."
  fi
done
