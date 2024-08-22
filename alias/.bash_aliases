# Alias definitions.
# You may want to put all your additions into a separate files like
# ~/.bash_aliases*, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

for file in ~/.bash_aliases_*
do
    if [ -f ${file} ]; then
    echo $file
    . ${file}

    fi
done