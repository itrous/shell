#!/bin/bash

# Параметры версий
OLD_VERSION="8.3.23.2040"
NEW_VERSION="8.3.25.1286"

# Параметры для управления службами и отладкой
USE_RAS=${1:-false}  # Использовать службу ras (по умолчанию false)
DEBUG=${2:-false}    # Включить отладку (по умолчанию false)

# Остановка и отключение старых сервисов
systemctl stop srv1cv8-$OLD_VERSION@service.service &&
systemctl disable srv1cv8-$OLD_VERSION@service.service &&

if [ "$USE_RAS" = true ]; then
  systemctl stop ras-$OLD_VERSION.service &&
  systemctl disable ras-$OLD_VERSION.service &&
fi

# Удаление старой версии
/opt/1cv8/x86_64/$OLD_VERSION/uninstaller-full &&

# Установка новой версии
chmod 751 ~/setup-full-$NEW_VERSION-x86_64.run &&
~/setup-full-$NEW_VERSION-x86_64.run --mode unattended --enable-components server,server_admin,ru &&

# Изменение параметра Environment=SRV1CV8_DEBUG если DEBUG включен
if [ "$DEBUG" = true ]; then
  sed -i 's/^#\?Environment=SRV1CV8_DEBUG=.*$/Environment=SRV1CV8_DEBUG="-debug -http"/' /opt/1cv8/x86_64/$NEW_VERSION/srv1cv8-$NEW_VERSION@.service &&
fi

# Связывание новых сервисов с systemd
systemctl link /opt/1cv8/x86_64/$NEW_VERSION/srv1cv8-$NEW_VERSION@.service &&

if [ "$USE_RAS" = true ]; then
  systemctl link /opt/1cv8/x86_64/$NEW_VERSION/ras-$NEW_VERSION.service &&
fi

# Перезагрузка конфигурации systemd
systemctl daemon-reload &&

# Включение и запуск новых сервисов
if [ "$USE_RAS" = true ]; then
  systemctl enable ras-$NEW_VERSION.service &&
  systemctl start ras-$NEW_VERSION.service &&
fi

systemctl enable srv1cv8-$NEW_VERSION@service &&
systemctl start srv1cv8-$NEW_VERSION@service.service &&

# Проверка статуса нового сервиса
systemctl status srv1cv8-$NEW_VERSION@service.service

if [ "$USE_RAS" = true ]; then
  systemctl status ras-$NEW_VERSION.service
fi
