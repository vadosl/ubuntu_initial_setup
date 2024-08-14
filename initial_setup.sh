#!/usr/bin/env bash

# Цветной фон
back_red="\e[41m"
back_green="\e[42m"
back_brown="\e[43m"
back_blue="\e[44m"
back_purple="\e[45m"
back_cyan="\e[46m"

# Цветной текст
red="\e[31m"
green="\e[32m"
brown="\e[33m"
blue="\e[34m"
purple="\e[35m"
cyan="\e[36m"

# Завершение вывода цвета
end="\e[0m"

 

# Данные о системе
os=`lsb_release -a | grep "Description" | awk '{$1=""; print $0}'`
cpu=`lscpu | grep "CPU MHz" | awk '{print $3}'`
cores=`grep -o "processor" <<< "$(cat /proc/cpuinfo)" | wc -l`
kern=`uname -r | sed -e "s/-/ /" | awk '{print $1}'`
kn=`lsb_release -cs`
mem=`free -m | grep "Mem" | awk '{print $2}'`
hdd=`df -m | awk '(NR == 2)' | awk '{print $2}'`

function run() {
  # Печать информации о выполнении новой команды
  echo -e "${brown}[RUN] ${1}...${end}"
}

function check() {
  # Проверка состояния вызова команды
  temp=$?
  echo "Status code of the executed command: ${temp}"
  if [[ temp -eq 0 ]]; then
  echo -en "${cyan}[SUCCESS] Команда успешно выполнена${end}\n\n"
  else
  echo -e "${back_red}[ERROR]${end} ${red}Ошибка выполнения команды${end}"
  echo -en "\n${green}Продолжить выполнение скрипта? [Y/n]: ${end}"
  answer; if [[ $? -ne 0 ]]; then close; fi
  fi
}

function answer() {
  # Соглашение пользователя на продолжение
  temp=""
  read temp
  temp=$(echo ${temp^^})
  echo -e "${end}"
  if [[ "$temp" != "Y" && "$temp" != "YES" ]]; then return 255; fi
}

function close() {
  # Завершение работы скрипта + перезагрузка
  echo -en "${brown}Нажмите любую клавишу, чтобы продолжить...${end}"
  read -s -n 1
  clear
  if [[ "$1" == "reboot" ]]; then shutdown -r now; else exit 0; fi
}

function execAsUser() {
    #Execute a command as a certain user
    # Нужен, когда необходимо создать файлы/каталоги от имени юзера
    #Arguments:
       #Account Username
       #Command to be executed
    local username=${1}
    local exec_command=${2}
    sudo -u "${username}" -H bash -c "${exec_command}"
}

function addSSHKey() {
    local username=${1}
    local sshKey=${2}

      "mkdir -p ~/.ssh; chmod 700 ~/.ssh; touch ~/.ssh/authorized_keys"
      "echo \"${sshKey}\" | sudo tee -a ~/.ssh/authorized_keys"
      "chmod 600 ~/.ssh/authorized_keys"
}


# Вывод информации о скрипте
clear
clr=$(echo -e "${red}*${green}*${brown}*${blue}*${purple}*${cyan}*${brown}")
echo -en "$brown"
echo "┌─────────────────────────────────────────────┐"
echo "│       ${clr}   SETUP.SH  v0.0.1             │"
echo "├─────────────────────────────────────────────┤"
echo "│ Данный скрипт выполняет первичную настройку │"
echo "│ сервера VDS 'VADOS' на базе Ubuntu 22.04  │"
echo "└─────────────────────────────────────────────┘"
echo -en "$end"

# Вывод информации о системе
echo -e "$red"
echo "  Дистрибутив:${os}"
echo "  Версия ядра: ${kern} (${kn})"
echo "          CPU: ${cores} x ${cpu} MHz"
echo "          RAM: ${mem} Mb"
echo "          HDD: ${hdd} Mb"
echo -en "$end"

# Подготовка необходимых данных
port_ssh=22

echo -en "\n${cyan}Введите имя нового пользователя: ${end}"; read username
echo -en "${cyan}Введите пароль нового пользователя: ${end}"; read -r password



# Запрос разрешения на запуск скрипта
echo -en "\n${green}Подтвердите запуск скрипта [Y/n]: ${end}"
answer; if [[ $? -ne 0 ]]; then close; fi



# === Создание нового пользователя === #
run "Создание пользователя ${username}"
  groupadd ${username}
  # Add sudo user and grant privileges
  useradd -g ${username} -G sudo -s /bin/bash -m ${username} -p $(openssl passwd -1 ${password})
check


# === ОБНОВЛЕНИЕ СИСТЕМНЫХ ПАКЕТОВ === #
run "Обновление системных пакетов"
  apt update && \
  apt upgrade -y && \
  apt dist-upgrade -y
check

# === НАСТРОЙКА ЧАСОВОГО ПОЯСА === #

run "Настройка часового пояса"
  ln -fs /usr/share/zoneinfo/Europe/Moscow /etc/localtime  && \
    apt install -y tzdata  && \
    dpkg-reconfigure --frontend noninteractive tzdata  && \
    apt install -y ntp
   # force NTP to sync
    service ntp stop
    ntpd -gq
    service ntp start
check

# === НАСТРОЙКА ЯЗЫКА И РЕГИОНАЛЬНЫХ СТАНДАРТОВ === #

run "Настройка языка и региональных стандартов"
    apt install -y language-pack-ru
    locale-gen ru_RU && \
  locale-gen ru_RU.UTF-8 && \
  update-locale LANG=ru_RU.UTF-8 && \
  dpkg-reconfigure --frontend noninteractive locales
check


# === НАСТРОЙКА ЗАЩИТЫ ОТ ПЕРЕБОРА ПАРОЛЕЙ === #

run "Установка утилиты fail2ban"
  apt install -y fail2ban
  cp ./configs/fail2ban/fail2ban.conf  /etc/fail2ban/jail.local
  systemctl enable fail2ban
  systemctl start fail2ban
  fail2ban-client status sshd
check

# === НАСТРОЙКА FIREWALL === #

run "Установка и настройка утилиты ufw"
  apt install -y ufw && \
  ufw default deny incoming && \
  ufw default allow outgoing && \
  ufw allow http && \
  ufw allow 443/tcp && \
  ufw allow ${port_ssh} && \
check

run "Выключение ufw"
  yes | ufw disable
check

run "Проверка статуса ufw"
    ufw status
check



# === НАСТРОЙКА SSH === #

run "Настройка параметров SSH"
  apt install -y sed && \
  sed -i "/^Port/s/^/# /" /etc/ssh/sshd_config && \
  sed -i "/^PermitRootLogin/s/^/# /" /etc/ssh/sshd_config && \
  sed -i "/^AllowUsers/s/^/# /" /etc/ssh/sshd_config && \
  sed -i "/^PermitEmptyPasswords/s/^/# /" /etc/ssh/sshd_config && \
  {
    echo "Port ${port_ssh}"
    echo "Port 445"
    echo "Port 8088"
    echo "Port 8843"
    echo "Port 1025"
    echo "PermitRootLogin yes"
    echo "AllowUsers ${username}"
    echo "PermitEmptyPasswords no"
  } >> /etc/ssh/sshd_config
  # Перезапуск демона, в старых версиях  убунту может быть другой синтаксис
  systemctl&nbsp;restart&nbsp;ssh.service
check

# === УСТАНОВКА ПРОГРАММ === #

run "Установка и настройка утилиты mc"
    apt install -y mc && \
  {
    echo "[Midnight-Commander]"
    echo "use_internal_view=true"
    echo "use_internal_edit=true"
    echo "editor_syntax_highlighting=true"
    echo "skin=modarin256"
    echo "[Layout]"
    echo "message_visible=0"
    echo "xterm_title=0"
    echo "command_prompt=0"
    echo "[Panels]"
    echo "show_mini_info=false"
  } > /etc/mc/mc.ini
check

run "Установка утилиты curl"
    apt install -y curl
check

run "Установка утилиты wget"
    apt install -y wget
check

run "Установка утилиты git"
    apt install -y git
check

run "Установка утилиты net-tools"
    apt install -y net-tools
check

run "Установка утилиты hstr удобного поиска в командной строке"
    apt install -y hstr
    hstr --show-configuration >> ~/.bashrc
check


run "Установка других полезных пакетов"
    apt install -y screen telnet nmap netcat htop
check

run "Скачиваем репозиторий установки"

check


run "Установка bash aliases"
check 

run "Установка tmux"
# Использеум конфигурацию настройки от 

check 





# === УСТАНОВКА DOCKER === #


# Run the following command to uninstall all conflicting packages:
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do    apt remove $pkg; done

run "Установка пакетов для использования хранилища поверх HTTPS"
     apt install -y apt-transport-https ca-certificates gnupg-agent software-properties-common curl 
check

run "Установка официального ключа GPG Docker"
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg |   apt-key add -
check

run "Добавление репозитория Docker"
     add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
  apt update
  # Убедитесь, что установка будет выполняться из репозитория Docker, а не из репозитория Ubuntu по умолчанию:
    apt-cache policy docker-ce
check

run "Установка Docker Engine - Community и containerd"
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
check

run "Настройка прав доступа для запуска Docker"
    usermod -aG docker ${username}
check




run "Docker должен быть установлен, демон-процесс запущен, а для процесса активирован запуск при загрузке. Проверьте, что он запущен:"
  systemctl status docker
check

# === СОЗДАНИЕ СТРУКТУРЫ СЕРВЕРА === #




# === ОЧИСТКА ПЕРЕД ЗАВЕРШЕНИЕМ === #

run "Очистка пакетного менеджера"
    apt autoremove -y && \
  apt autoclean -y
check

# === ЗАВЕРШЕНИЕ РАБОТЫ СКРИПТА === #

ip=$(wget -qO- ifconfig.co)

echo -e "${clr}${clr}${clr}${clr}${clr}${clr}${end}\n"

echo -e "${green}  Пользователь: ${cyan}${username}${end}"
echo -e "${green}        Пароль: ${cyan}${password}${end}"
echo -e "${green}      Порт SSH: ${cyan}${port_ssh}${end}"
echo -e "${green}    Внешний IP: ${cyan}${ip}${end}"

echo -e "\n${cyan}  ssh ${username}@${ip} -p ${port_ssh}${end}"
echo -e "${cyan}  sh://${username}@${ip}:${port_ssh}/${end}"


echo -e "\n${clr}${clr}${clr}${clr}${clr}${clr}${end}"

echo -e "\n${red}[ВНИМАНИЕ] Система будет перезагружена!${end}"
echo -e "${red}Сохраните данные указанные выше!${end}\n"

#close "reboot"

# todo logrotate поставить настроить
