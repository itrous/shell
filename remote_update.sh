#!/bin/bash

# Параметры версий
NEW_VERSION="8.3.25.1286"

scp ./setup-full-$NEW_VERSION-x86_64.run ubuntu@dev:~/
scp update_service.sh ubuntu@dev:~/
ssh ubuntu@dev 'sudo bash ~/update_service.sh true true'
