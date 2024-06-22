scp /путь/к/файлу/setup-full-$NEW_VERSION-x86_64.run ubuntu@dev:~/
scp update_service.sh ubuntu@dev:~/
ssh ubuntu@dev 'sudo bash ~/update_service.sh true true'
