#!/bin/bash
set -e  # Выход при любой ошибке

# Добавим цвета для удобства
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для обработки подтверждений
confirm() {
    local message="$1"
    local default="${2:-Y}"
    
    read -rp "$message [${default}/n] " answer
    case "${answer:-$default}" in
        [Yy]* ) return 0;;
        * ) return 1;;
    esac
}

# Обновление системы с прогресс-баром
echo -e "${GREEN}Обновление пакетов...${NC}"
sudo apt -qq update && sudo apt -o Dpkg::Progress-Fancy=1 upgrade -y

# Установка базовых утилит
echo -e "${GREEN}Установка основных пакетов...${NC}"
sudo apt install -y --no-install-recommends \
    htop \
    sqlite3 \
    wget \
    curl \
    zsh \
    git \
    vim \
    software-properties-common \
    apt-transport-https

# Настройка локалей (автоматическая)
echo -e "${GREEN}Настройка локалей...${NC}"
sudo sed -i 's/# ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen
sudo locale-gen ru_RU.UTF.8
sudo update-locale LANG=ru_RU.UTF-8 LC_MESSAGES=POSIX

# Установка Oh My Zsh (неинтерактивная)
echo -e "${GREEN}Установка Oh My Zsh...${NC}"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    sudo chsh -s $(which zsh)
fi

# Установка дополнительных компонентов
install_nginx=false
install_postgres=false
install_node=false
install_pm2=false
activate_ufw=false

confirm "Установить nginx?" && install_nginx=true
confirm "Установить PostgreSQL?" && install_postgres=true
confirm "Установить Node.js?" && install_node=true

if $install_node; then
    confirm "Установить PM2?" && install_pm2=true
fi

confirm "Активировать UFW?" && activate_ufw=true

# Вывод выбранных опций
echo -e "\n${YELLOW}Выбрано:${NC}"
echo "• Nginx:      $install_nginx"
echo "• PostgreSQL: $install_postgres"
echo "• Node.js:    $install_node"
echo "• PM2:        $install_pm2"
echo "• UFW:        $activate_ufw"
echo

# Установка Nginx
if $install_nginx; then
    echo -e "${GREEN}Установка Nginx...${NC}"
    sudo apt install -y nginx
fi

# Установка Node.js через NVM
if $install_node; then
    echo -e "${GREEN}Установка Node.js...${NC}"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
    export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
    echo -e "${GREEN}NVM установлен в ${NVM_DIR}.${NC}"
    \. "$NVM_DIR/nvm.sh" # This loads nvm

    nvm install --lts --latest-npm
fi

# Установка PM2
if $install_pm2; then
    echo -e "${GREEN}Установка PM2...${NC}"
    npm install -g npm@latest
    npm install -g pm2
fi

# Установка PostgreSQL
if $install_postgres; then
    echo -e "${GREEN}Установка PostgreSQL...${NC}"
    sudo apt install -y postgresql postgresql-contrib
    echo -e "${YELLOW}Не забудьте настроить пароль для пользователя postgres!${NC}"
fi

# Настройка UFW
if $activate_ufw; then
    echo -e "${GREEN}Настройка UFW...${NC}"
    sudo ufw allow OpenSSH
    if $install_nginx; then
        sudo ufw allow 'Nginx Full'
    fi
    echo "y" | sudo ufw enable
    sudo ufw status verbose
fi

echo -e "\n${GREEN}Установка завершена!${NC}"