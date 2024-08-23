#!/bin/bash

# Проверяем, передан ли параметр
if [ -z "$1" ]; then
  echo "Пожалуйста, укажите путь к установочному файлу."
  exit 1
fi

# Проверяем, передан ли параметр -debug
debug_mode=false
for arg in "$@"; do
  if [ "$arg" == "-debug" ]; then
    debug_mode=true
    break
  fi
done

# Получаем путь к установочному файлу из параметра
installer_path="$1"

# Извлекаем версию из имени файла
new_version=$(basename "$installer_path" | grep -oP '\d+\.\d+\.\d+\.\d+')

if [ -z "$new_version" ]; then
  echo "Не удалось определить версию из имени файла $installer_path"
  exit 1
fi

echo "Установка новой версии: $new_version"

# Определяем путь к директории с установленными версиями
install_dir="/opt/1cv8/x86_64/"

# Ищем текущую установленную версию
current_version=$(ls $install_dir | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n 1)

if [ -z "$current_version" ]; then
  echo "Не найдена установленная версия в $install_dir"
  exit 1
fi

echo "Текущая установленная версия: $current_version"

# Останавливаем и отключаем старые сервисы
systemctl stop srv1cv8-$current_version@service.service
systemctl disable srv1cv8-$current_version@service.service
systemctl stop ras-$current_version.service
systemctl disable ras-$current_version.service

# Удаляем старую версию
uninstaller_path="$install_dir/$current_version/uninstaller-full"
if [ -f "$uninstaller_path" ]; then
  $uninstaller_path
else
  echo "Не найден деинсталлятор для версии $current_version"
  exit 1
fi

# Устанавливаем новую версию
chmod 751 "$installer_path"
"$installer_path" --mode unattended --enable-components server,server_admin,ru

# Настраиваем новые сервисы

# Если параметр -debug передан, выполняем команду sed
if $debug_mode; then
  sed -i 's/^#\?Environment=SRV1CV8_DEBUG=.*$/Environment=SRV1CV8_DEBUG="-debug -http"/' /opt/1cv8/x86_64/$new_version/srv1cv8-$new_version@.service
  echo "Режим отладки включен."
else
  echo "Режим отладки не включен."
fi

systemctl link /opt/1cv8/x86_64/$new_version/srv1cv8-$new_version@.service
systemctl link /opt/1cv8/x86_64/$new_version/ras-$new_version.service

systemctl daemon-reload

systemctl enable ras-$new_version.service
systemctl start ras-$new_version.service

systemctl enable srv1cv8-$new_version@service
systemctl start srv1cv8-$new_version@service.service

systemctl status srv1cv8-$new_version@service.service

# Удаляем установочный файл после завершения установки
rm -f "$installer_path"
echo "Установочный файл удален: $installer_path"