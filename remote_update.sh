#!/bin/bash

# Получаем путь к установочному файлу из параметра
installer_path="$1"

# Извлекаем версию из имени файла
NEW_VERSION=$(basename "$installer_path" | grep -oP '\d+\.\d+\.\d+\.\d+')

scp $installer_path ubuntu@dev:~/
scp 1c-install.sh ubuntu@dev:~/
ssh ubuntu@dev 'sudo bash ~/1c-install.sh ~/installer_path'
