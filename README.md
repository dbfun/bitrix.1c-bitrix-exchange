# Инструмент для эмуляции обмена файлами 1С => Битрикс

Этот инструмент полностью эмулирует работу обмена файлами между 1С и Битрикс. Предусмотрены следующие способы обмена:

* [Стандартный механизм обмена](#generic) `CommerceML` - файлы `import.xml` и `offers.xml`
* [Доработанный механизм обмена на основе стандартного](#custom) - любые файлы, например `JSON`, `CSV`
* [Получение необработанных заказов](#getorders)
* [Простая отправка данных POST запросом на свой обработчик в Битрикс](#post)

Демонстрация стандартного обмена:

![XML обмен файлами 1С Битрикс offers.xml](https://raw.githubusercontent.com/dbfun/1c-bitrix-exchange/master/assets/offers.xml.gif)

Минимальный пример запуска через [Docker](https://www.docker.com/):

```
docker  run -it --rm \
        -e SITE=http://site.ru \
        -e AUTH_LOGIN=1c_exchange@site.ru \
        -e AUTH_PASS=password \
        -e FILE_NAME=offers.xml \
        -v $(pwd)/data/offers.xml:/src \
        required/1c-bitrix-exchange:latest
```

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
docker build --tag required/1c-bitrix-exchange 1c-bitrix-exchange
```

# Конфигурация

## Описание параметров

| Параметр      | Обязательный | Пример значения     | Значение по-умолчанию | Описание                                                                                                                   |
|---------------|--------------|---------------------|-----------------------|----------------------------------------------------------------------------------------------------------------------------|
| SITE          | +            | http://site.ru      |                       | Адрес сайта с протоколом, если хост не резолвится, следует добавить `--dns=IP-вашего-DNS-сервера` в параметры `docker run` |
| AUTH_LOGIN    | +            | 1c_exchange@site.ru |                       | Логин служебной учетной записи стандартного обмена                                                                         |
| AUTH_PASS     | +            | password            |                       | Пароль служебной учетной записи стандартного обмена                                                                        |
| CHARSET_IN    |              |                     | utf-8                 | Кодировка сайта                                                                                                            |
| CHARSET_OUT   |              |                     | utf-8                 | Кодировка консоли                                                                                                          |
| FILE_NAME     |              | offers.xml          |                       | Название файла, будет передано как GET-параметр `filename`                                                                 |
| ZIP           |              | 1                   |                       | Передаваемый файл является архивом, необходимо обработать все файлы из него (указать `1`)                                  |

## Файл конфигурации

Параметры в скрипт обмена можно передавать через командную строку, но при многократном использовании это делать удобнее через файл конфигурации.

В таком случае нужно скопировать [`.env.dist`](https://raw.githubusercontent.com/dbfun/1c-bitrix-exchange/master/.env.dist) в `.env` и поправить в нем базовую конфигурацию (адрес сайта, логин-пароль, кодировку).

Тогда запуск обмена станет еще короче:

```
docker  run -it --rm \
        --env-file .env \
        -e FILE_NAME=offers.xml \
        -v $(pwd)/data/offers.xml:/src \
        required/1c-bitrix-exchange:latest
```

# Использование

## Стандартный механизм обмена<a name="generic"></a>

Если файл для импорта находится в `data/offers.xml`, команда выглядит так:

```
docker  run -it --rm \
        --env-file .env \
        -e FILE_NAME=offers.xml \
        -e SITE=test.site.ru \
        --dns=10.0.1.1 \
        -v $(pwd)/data/offers.xml:/src \
        -v $(pwd)/log/:/var/log/ \
        required/1c-bitrix-exchange:latest
```

В этом расширенном примере (полужирным - обязательные настройки):

* **`--env-file .env`** - базовые настройки (также настройки можно передать через `-e ПАРАМЕТР=значение`)
* **`-e FILE_NAME=offers.xml`** - имя загружаемоего файла (будет передано в Битрикс как GET-параметр)
* `-e SITE=test.site.ru` - переопределен сайт, указанный в базовых настройках `.env` файла
* `--dns=10.0.1.1` - указан собственный DNS (указывать в случае ошибки `Could not resolve host` для локальных сайтов)
* **`-v $(pwd)/data/offers.xml:/src`** - подмонтировать файл `data/offers.xml` в контейнер для импорта, имя файла может быть любым, но название для обмена нужно указать через `FILE_NAME`
* `-v $(pwd)/log/:/var/log/` - подмонтировать каталог `log/` в контейнер, в нем будут созданы логи обмена (полезно при отладке)

Полученные из файла данные будут загружены на сайт тем же путем, как это делает 1С.

## Доработанный механизм обмена на основе стандартного<a name="custom"></a>

Для импорта `JSON`, `CSV` и других типов файлов (в свои отдельные таблицы БД, например) нужно добавить свои кастомные обработчики в стандартный обмен. При этом сохранится стандартный механизм обмена, и появится возможность обработки произвольных файлов.

### 1. Создать собственный компонент

Создадим собственный компонент обмена, для чего скопируем и доработаем стандартный `bitrix:catalog.import.1c`. Переходим в корень сайта и вводим:

```bash
mkdir -p local/components/vendor/
cp -r bitrix/components/bitrix/catalog.import.1c local/components/vendor/
```

Теперь следует поправить скопированный файл `local/components/vendor/catalog.import.1c/component.php`, сниппет с изменениями находится в файле этого репозитория: [`snippets/vendor:catalog.import.1c/component.php`](https://raw.githubusercontent.com/dbfun/1c-bitrix-exchange/master/snippets/vendor%3Acatalog.import.1c/component.php).

При вызове можно указать в GET-параметре вместо стандартного режима `mode=import` другое значение, например `mode=report`, и использовать в качестве условия в собственном обработчике: `if(($_GET["..."] == "report")) { /* свой обработчик */ }`.

### 2. Заменить стандартный компонент

В файле `bitrix/admin/1c_exchange.php` необходимо заменить стандартный компонент на собственный:

```
// заменить
$APPLICATION->IncludeComponent("bitrix:catalog.import.1c"
// на
$APPLICATION->IncludeComponent("vendor:catalog.import.1c"
```

### 3. Запуск нового обмена

В `docker run` нужно использовать дополнительный параметр `-e GET_STEP_MODE=custom_mode`, где `custom_mode` - параметр, который будет передан в `$_GET['mode']`. Например, обмен отчетами `report` будет выглядеть так:

```
docker  run -it --rm \
        -e FILE_NAME=report.zip \
        -e ZIP=1 \
        -e GET_STEP_MODE=report \
        --env-file .env \
        -v $(pwd)/data/report.zip:/src \
        required/1c-bitrix-exchange:latest
```


## Получение необработанных заказов<a name="getorders"></a>

Для получения необработанных заказов необходимо подмонтировать в `/var/log/` каталог, в который будет записан файл с заказами `02-get-orders.xml`.

```
docker  run -it --rm \
        --env-file .env \
        -v $(pwd)/log/:/var/log/ \
        required/1c-bitrix-exchange:latest \
        getorders
```


## Простая отправка данных POST запросом на свой обработчик в Битрикс<a name="post"></a>

Простая отправка данных POST из файла на выделенный URI сайта. Дополнительные параметры:

| Параметр      | Обязательный | Пример значения          | Значение по-умолчанию | Описание                                                       |
|---------------|--------------|--------------------------|-----------------------|----------------------------------------------------------------|
| URI           | +            | /lk/ws/orders/           |                       | Относительный адрес, куда необходимо отправить данные из файла |
| CONTENT_TYPE  |              | application/octet-stream | application/json      | Заголовок `Content-Type`                                       |

Вариант использования:

```
docker  run -it --rm \
        -e URI="/lk/ws/orders/" \
        --env-file .env \
        -v $(pwd)/data/orders.json:/src \
        required/1c-bitrix-exchange:latest \
        post
```
