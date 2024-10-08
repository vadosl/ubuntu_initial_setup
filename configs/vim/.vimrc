colo desert
syntax on
"Настроим кол-во символов пробелов, которые будут заменять 
set tabstop=4
set shiftwidth=4
set smarttab
set expandtab "Ставим табы пробелами
set softtabstop=4 "4 пробела в табе

" Автоотступ
set autoindent

" Подсвечиваем все что можно подсвечивать
let python_highlight_all = 1
" Включаем 256 цветов в терминале, мы ведь работаем из иксов?

" Нужно во многих терминалах, например в gnome-terminal
set t_Co=256

" включим автозамену по умолчанию
set et
" попросим Vim переносить длинные строки
set wrap
"включим автоотступы для новых строк
set ai
"включим отступы в стиле Си
set cin

syntax on "Включить подсветку синтаксиса

"Далее настроим поиск и подсветку результатов поиска и совпадения скобок
set showmatch
set hlsearch
set incsearch
set ignorecase
" ленивая перерисовка экрана при выполнении скриптов
set lz

"Показываем табы в начале строки точками
set listchars=tab:··
set list

" set nu "Включаем нумерацию строк
set mousehide "Спрятать курсор мыши когда набираем текст
set mouse=a "Включить поддержку мыши
set termencoding=utf-8 "Кодировка терминала
set novisualbell "Не мигать 

" Вырубаем .swp и ~ (резервные) файлы
set nobackup
set noswapfile
set encoding=utf-8 " Кодировка файлов по умолчанию
set fileencodings=utf8,cp1251

set clipboard=unnamed
set ruler

"Порядок применения кодировок и формата файлов
set ffs=unix,dos,mac
set fencs=utf-8,cp1251,koi8-r,ucs-2,cp866

"Взаимодействие и элементы интерфейса

"Я часто выделяю мышкой содержимое экрана в Putty, но перехват мышки в Vim мне иногда мешает. Отключаем функционал вне графического режима:
if !has('gui_running')
set mouse=
endif

"Избавляемся от меню и тулбара:
set guioptions-=T
set guioptions-=m

"В разных графических системах используем разные шрифты:
if has('gui')
colorscheme darkblue
if has('win32')
set guifont=Lucida_Console:h12:cRUSSIAN::
else
set guifont=Terminus\ 14
endif
endif

"Пытаемся занять максимально большое пространство на экране. Как водится, по-разному на разных системах:
if has('gui')
if has('win32')
au GUIEnter * call libcallnr('maximize', 'Maximize', 1)
elseif has('gui_gtk2')
au GUIEnter * :set lines=99999 columns=99999
endif
endif

"Опять же, системы сборки для разных платформ могут быть переопределены:
if has('win32')
set makeprg=nmake
compiler msvc
else
set makeprg=make
compiler gcc
endif 
" Нумерация строк
set number

