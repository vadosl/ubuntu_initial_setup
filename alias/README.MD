Для удобства стоит разбить aliases на несколько файлов. После редактирования любого из файлов надо перегрузить alias дать команду `source ~/.bashrc` 


Точка входа всех alias находится в файле `~/.bashrc`,  куда добавляем ссылки на другие файлы alias:

```sh
# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

for file in ~/.bash_alias*
do
    if [ -f ${file} ]; then
    echo $file
    . ${file}

    fi
done


```
