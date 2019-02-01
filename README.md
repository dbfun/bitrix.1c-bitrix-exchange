# Описание

Инструмент для обмена файлами `1С` => `Битрикс`:

* `XML` файлы - стандартный механизм обмена `CommerceML`
* `JSON`, `CSV` - в стандартном механизме не предусмотрен, поэтому необходима доработка PHP-скриптов (см ниже)

Скрипт создан на основе [этого репозитория](https://github.com/dbfun/bitrix-import).

# Установка

## Из реестра Docker Hub

Чтобы получить образ из [реестра Docker Hub](https://hub.docker.com/r/required/1c-bitrix-exchange), откройте командную строку и введите:

```
docker pull required/1c-bitrix-exchange
```

## Из репозитория GitHub

Чтобы собрать образ из репозитория GitHub, введите в терминале:

```
git clone https://github.com/dbfun/1c-bitrix-exchange.git
cd 1c-bitrix-exchange
docker build --tag required/1c-bitrix-exchange .
```

# Конфигурация

Параметры в скрипт обмена можно передавать через командную строку, но при многократном использовании это делать удобнее через файл конфигурации.

В таком случае нужно скопировать `.env.dist` в `.env` и поправить в нем базовую конфигурацию (адрес сайта, логин-пароль, кодировка).

# Использование

Каталог `data` создан для удобства хранения файлов для импорта.

Если файл для импорта находится в `data/offers.xml`, команда выглядит так:

```
docker  run -it --rm \
        --env-file .env \
        -e FILE_NAME=offers.xml \
        -e SITE=test.site.ru \
        --dns=10.0.1.1 \
        -v $(pwd)/data/offers.xml:/scripts/data/import-file \
        -v $(pwd)/log/:/scripts/data/log/ \
        required/1c-bitrix-exchange:latest
```

В этом примере (полужирным - обязательные настройки):

* **`--env-file .env`** - базовые настройки (также настройки можно передать через `-e ПАРАМЕТР=значение`)
* **`-e FILE_NAME=offers.xml`** - имя загружаемоего файла (будет передано в Битрикс как GET-параметр)
* `-e SITE=test.site.ru` - переопределен сайт, указанный в базовых настройках `.env` файла
* `--dns=10.0.1.1` - указан собственный DNS (указывать в случае ошибки `Could not resolve host` для локальных сайтов)
* **`-v $(pwd)/data/offers.xml:/scripts/data/import-file`** - подмонтировать файл `data/offers.xml` в контейнер для импорта, имя файла может быть любым, но его необходимо указать через `FILE_NAME`
* `-v $(pwd)/log/:/scripts/data/log/` - подмонтировать каталог `log/` в контейнер, в нем будут созданы логи обмена (полезно при отладке)

# Доработка стандартного обмена

Для импорта `JSON`, `CSV` и других типов файлов (в свои отдельные таблицы БД, например) нужно добавить свои обработчики в стандартный обмен. При этом сохранится стандартный механизм обмена, но появится возможность обработки произвольных файлов.

1. Заменить компонент в файле `bitrix/admin/1c_exchange.php`:
`$APPLICATION->IncludeComponent("bitrix:catalog.import.1c"` =>
`$APPLICATION->IncludeComponent("vendor:catalog.import.1c"`
2. Скопировать компонент `bitrix:catalog.import.1c` в `vendor:catalog.import.1c`:
`bitrix/components/bitrix/catalog.import.1c/` =>
`local/components/vendor/catalog.import.1c`
3. Поправить скопированный файл `component.php`, сниппет с изменениями - в файле `snippets/vendor:catalog.import.1c/component.php`.
4. Использовать `-e GET_STEP_MODE=custom_mode`, где `custom_mode` - параметр, который будет передан в `$_GET['mode']`
