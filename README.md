# Описание

Инструмент для обмена файлами `1С` => `Битрикс`.

* `XML` файлы - стандартный механизм обмена CommerceML
* `JSON`, `CSV` - необходима доработка PHP-скриптов (см ниже)

Создан на основе [этого репо](https://github.com/dbfun/bitrix-import).

# Запуск

## Сборка образа

```
docker build --tag 1c-bitrix-exchange .
```

## Конфигурация

Параметры можно передавать через командную строку, но через файл конфигурации это делать удобнее.

В этом случае нужно скопировать `.env.dist` в `.env` и поправить конфигурацию.

## Запуск

Если файл для импорта находится в `data/offers.xml`, команда выглядит так:

```
docker run -e FILE_NAME=offers.xml -e SITE=test.site.ru --env-file .env --dns=10.0.1.1 -it --rm -v $(pwd)/data/offers.xml:/scripts/data/import-file "1c-bitrix-exchange:latest"
```

В этом примере:

* `FILE_NAME=offers.xml` - указано имя загружаемоего файла (будет передано через GET)
* `--env-file .env` - настройки
* `SITE=test.site.ru` - дополнительно переопределен сайт
* `--dns=10.0.1.1` - указан собственный DNS (ошибка `Could not resolve host`)

# Суть доработки стандартного обмена

Для добавления своих обработчиков, например `JSON` и `CSV`, следует доработать стандартный обмен, при этом сохранится стандартный механизм.

1. Заменить компонента в файле `./bitrix/admin/1c_exchange.php`: `$APPLICATION->IncludeComponent("bitrix:catalog.import.1c"` => `$APPLICATION->IncludeComponent("vendor:catalog.import.1c"`.
2. Скопировать компонент `bitrix:catalog.import.1c`, создав `vendor:catalog.import.1c`.
3. Сниппет с изменениями - в файле `snippets/vendor:catalog.import.1c/component.php`.
