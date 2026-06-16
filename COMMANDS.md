# General Instructions Commands

Command examples for working with the shared `general-instructions` kit.

For full policies, see `AGENTS.md`, `patterns/GIT_WORKFLOW.md`, and
`patterns/FIRST_MESSAGE_HANDLING.md`.

## Команды Для Чата С Агентом

Префикс `gi` — короткая команда для локального instruction kit. Не
переименовывай в `GAI`. `gi` = `general-instructions`, не `git`.
Это команды для чата с агентом, не команды PowerShell. Если пользователь хочет
именно терминальную PowerShell-команду, он пишет `PS` или получает реальную
команду/путь к скрипту, например `.\tools\agent-start.ps1`.

```text
gi обновись
gi init https://github.com/Dimosfil/general-instructions.git
инит https://github.com/Dimosfil/general-instructions.git
init https://github.com/Dimosfil/general-instructions.git
gi язык
ги язык
gi язык: 2 1
ги язык: 2 1
gi language: Russian English
gi проект язык: Russian
ги проект язык: Russian
gi project language: Russian
gi язык проекта: Russian
gi коммит язык: Russian
ги коммит язык: Russian
gi язык коммита: Russian
gi язык коммита: English only
gi систем язык: Russian
ги систем язык: Russian
gi саммари
gi старт
gi restore
gi config
gi config service
gi config service url=http://127.0.0.1:4100
gi config service on
gi config service off
gi ftp config
gi ftp
ги фтп конфиг
ги фтп
ги конфиг сервис on
ги конфиг сервис off
gi reboot
gi restart
ги ребут
ги рестарт
ги конфиг сервис урл=http://127.0.0.1:4100
gi install
gi инсталл
ги инсталл
gi старт спринт
gi гит-обзор
gi git summary
gi тест-план
gi test plan
gi tm
gi active task
gi next task
gi add sprint
gi create sprint
gi добавить спринт
gi manager test
gi tm test
gi план
gi post plan
gi пуш
gi коммит
gi только пуш
gi коммит пуш
gi пул
```

Если команда неполная, агент уточняет недостающий параметр.

Ответ на `gi` команду ограничен этой командой; агент не возвращается к
предыдущей задаче без явной просьбы.

Прогресс-апдейты должны быть по фазам, а не после каждого батча команд. Агент
не пишет счётчики вроде "выполнено 4 команды" и не ведёт live-blog каждой
промежуточной гипотезы. Сообщать стоит при смене фазы, значимом выводе,
блокере или долгой паузе.

Автоматические счётчики tool calls, которые показывает UI чата, не считаются
прогресс-апдейтами агента; агент не должен дублировать их текстом.

`gi` команда выполняется в текущем project root. Shared library читается
только как источник `VERSION.md`, `CHANGELOG.md`, `INDEX.md`, `migrations/` и
шаблонов. Отсутствие `.git` не блокирует проверку/применение GI-обновлений,
только commit/push.

`apps.txt`, планы, summary и записи task manager не дают разрешение читать
приватные локальные источники вне project root. Для анализаторов логов агент
использует mock/sample data или спрашивает явное разрешение на конкретный путь
и действие перед чтением `.codex`, `.cursor`, IDE logs, browser profiles, shell
history, SQLite databases или app logs.

Если нужный файл, skill, config, script, endpoint, task или другая сущность не
найдена, агент сначала перечитывает локальные инструкции, runbook, project
memory и принятые instruction-kit artifacts для текущей команды. Если после
этого сущность всё ещё отсутствует, агент задаёт один короткий вопрос
пользователю. Нельзя использовать другой проект или shared library как runtime
fallback без явного пути и действия от пользователя.

После успешного `gi обновить` / `gi обновись` агент коммитит и пушит только те
изменения instruction kit, которые создал сам update-flow, если это git
repository с настроенным remote и изменения касаются только instruction kit.
Команда не является просьбой пушить уже существующие локальные коммиты, синкать
feature branch, продолжать старый план или делать общее Git-обслуживание. Без
remote, при конфликте или unrelated changes — остановиться и объяснить блокер.

### Новый Проект

```text
Connect shared instructions: https://github.com/Dimosfil/general-instructions.git
```

Агент:
- читает общие правила и нужные шаблоны
- создаёт локальные `AGENTS.md`, `tools/AGENT_WORKING_AGREEMENTS.md`,
  `tools/AGENT_RUNBOOK.md`, `tools/agent-start.ps1` и project memory files
- не добавляет shared library как dependency, submodule или symlink
- не спрашивает про языки коммитов при bootstrap
- останавливается после setup и спрашивает, что делать дальше

### Восстановить Контекст Проекта

```text
gi старт
gi restore
```

Также: `gi start`, `gi восстанови`, `gi восстановить контекст`.

Агент восстанавливает контекст из `AGENTS.md`, последнего handoff summary и
`tools/agent-start.ps1`, затем кратко говорит статус и спрашивает, что делать
дальше. Не продолжает старую задачу автоматически.

Старые планы, фазы рефакторинга, заметки из памяти и локальные коммиты впереди
remote можно упомянуть только как компактный контекст. Нельзя превращать их в
предлагаемое следующее действие, если пользователь явно не попросил продолжить,
запустить, дописать или запушить именно это.

### Получить GI Config

```text
gi config
gi конфиг
ги конфиг
gi config service
ги конфиг сервис
gi config service url=http://127.0.0.1:4100
ги конфиг сервис url=http://127.0.0.1:4100
ги конфиг сервис урл=http://127.0.0.1:4100
```

Агент получает bootstrap-конфиг сервиса конфигов, а не ищет runtime-конфиги в
папках соседних проектов. Сначала читать project-local override, если он явно
задан локальными инструкциями, затем `config/gi-main.json` из checkout/cache
канонического source repo `https://github.com/Dimosfil/general-instructions.git`,
текущего checkout shared instructions или пути из `GENERAL_INSTRUCTIONS_HOME`.
Из GI main config взять `configServiceUrl` и проверить сам config-service через
его `/health` или документированный discovery endpoint.

`gi config service` / `ги конфиг сервис` — явное имя того же сценария. Для
runtime-адресов локальных приложений и task manager агент берёт из локального
проекта только имя или service id, затем запрашивает `GET /services/{serviceId}`
в config-service. После этого он использует `endpoints.availability` для
проверки доступности, `endpoints.guide` для агентского onboarding, когда этот
endpoint есть, `endpoints.contract` для актуального протокола и `endpoints.api`
для операций. Если guide и contract расходятся по endpoint, ownership или
permissions, агент останавливается и сообщает mismatch вместо догадок по
старой памяти, dashboard URL, filesystem paths или raw receipts.

`gi config service url=<url>` / `ги конфиг сервис url=<url>` /
`ги конфиг сервис урл=<url>` задаёт canonical URL config-service для текущего
окружения, например
`http://127.0.0.1:4100`. В shared instruction library агент обновляет
`config/gi-main.json`; в проекте с явным local override обновляет только этот
override. Все локальные сервисы используют этот URL, чтобы регистрироваться в
config-service и читать discovery. URL должен быть полным `http://` или
`https://` адресом без секретов, токенов, query string и fragment.

Если GI main config или config-service недоступен, остановиться с коротким
блокером. Не подбирать порты, не сканировать sibling workspace roots, не читать
другие project roots и не использовать старые task-manager записи как замену
config-service.

### Собрать Билд И Инсталлятор

```text
gi install
gi инсталл
ги инсталл
gi install Inno Setup
gi инсталл Inno Setup
gi инсталл <программа>
```

Также распознавать очевидные опечатки вроде `gi иснтлл`, если намерение
собрать installer ясно из контекста.

Агент собирает production build и установочный файл для текущего проекта.
Если программа не указана, по умолчанию использовать Inno Setup: найти
project-local build/package инструкции, скрипты и `.iss` файл, затем собрать
приложение и installer. Если после команды указана программа, использовать её
как предпочитаемый packaging/installer tool вместо Inno Setup.

Перед packaging агент определяет версию приложения из project-local metadata:
manifests, package files, assembly attributes, release files или installer
configs. Агент обновляет версию в production build, installer metadata и имени
installer-файла или installer-артефакта, если локальные инструменты это
поддерживают. Если versioning contract отсутствует или неоднозначен, агент
задаёт один короткий уточняющий вопрос вместо изобретения версии.

Перед сборкой агент проверяет локальные инструкции, README, manifests и
существующие packaging scripts/configs. Если build или installer contract не
найден, агент задаёт короткий уточняющий вопрос вместо изобретения installer
конфига без опоры на проект. `restore`, dependency install, build и test
являются только предварительными проверками: они не завершают `gi install`,
пока packaging command не выполнена и текущий installer artifact не создан или
явно не проверен. Если агент выполнил только проверки, он сообщает именно это
и не называет проект установленным/восстановленным. После успешного packaging
агент кратко сообщает версию, путь к инсталлятору и выполненные проверки.

### Взять Активный Sprint В Работу

```text
gi старт спринт
```

Также: `gi start sprint`, `gi sprint start`, `gi активный спринт`,
`gi work sprint`.

Агент восстанавливает контекст, затем через настроенный task manager находит
активный sprint и выполняет задачи по порядку. Если sprint'ов 0 или >1 —
показать варианты и спросить.

Before starting sprint workflow, verify that the configured manager API endpoint
supports active sprint lookup, next-task lookup, and task completion for the
selected workflow. If only generic health works, stop before executing tasks.

### Проверить Обновления Инструкций

```text
Обновись из https://github.com/Dimosfil/general-instructions.git
```

Если локального kit ещё нет — bootstrap/init. Если уже есть — применить
только недостающие миграции. Использовать `VERSION.md`, `CHANGELOG.md` и
`migrations/`, не читать `updates/`.

`gi обновить` тихий по умолчанию: без прогресс-нарратива, без широких чтений,
без повторяющихся статусов. Только компактный результат: версии до/после,
количество миграций, ID применённых, изменённые файлы, проверки, commit/push.

`gi обновить` применяет принятые instruction-kit миграции. Не предлагать пушить
локальные коммиты, которые существовали до обновления, и не подменять команду
git-синхронизацией проекта.

Если после обновления впервые стал доступен task-manager plan sync, но
`tools/project-memory/task-managers.json` отсутствует или не содержит
включенных менеджеров, сразу предложить numbered Markdown checklist с
доступными адаптерами и `none`. Не подключать WorkNest или другой менеджер
автоматически.

Если локальный checkout/cache path недоступен — использовать `source_repo` из
metadata, URL из команды, текущий checkout/cache shared instructions или
`GENERAL_INSTRUCTIONS_HOME`. Локальный путь хранить только как cache/checkout,
а канонический источник брать из GitHub repo.

### Настроить Язык Проекта

```text
gi язык
ги язык
gi язык: 2 1
ги язык: 2 1
gi language: Russian English
gi проект язык: Russian
ги проект язык: Russian
gi project language: Russian
gi язык проекта: Russian
ги язык проекта: Russian
```

Это основной способ выбрать языки проекта. Команда задаёт три выбора с одним и
тем же списком языков:

1. Project working environment: общение, progress updates, финальные ответы,
   уточняющие вопросы, планы и checklists.
2. Commit messages.
3. Tasks: task titles, task descriptions и task-manager updates.

В каждом выборе можно указать один или несколько языков; порядок важен. Первый
выбранный язык становится основным для этой поверхности, второй — вторым
языком, и так далее. Агент обновляет
`tools/project-memory/system-preferences.json` и
`tools/project-memory/git-preferences.json`.

Если команда пришла без выбора, агент показывает три последовательных выбора.
Если язык указан сразу после команды, агент использует этот порядок для всех
трёх поверхностей, пока пользователь не задаст отдельные значения.

В чатовой форме каждый из трёх выборов показывается как короткий нумерованный
Markdown checklist с одним и тем же списком языков и текущими отметками.
Пользователь может ответить номерами или названиями языков. Если пользователь
отвечает только числами, например `1 2`, агент применяет их к последнему
показанному списку и сохраняет этот порядок для текущего этапа, не уточняя
повторно, какие языки соответствуют числам.
Перед первым выбором агент показывает короткий блок текущих настроек для всех
трёх поверхностей. В каждый список добавляется вариант `Cancel / Отмена`; если
пользователь выбирает его или отвечает `cancel`/`отмена`, агент завершает
настройку без изменения файлов предпочтений.

Пример первого этапа:

```markdown
Current settings:
- Project working environment: match_user
- Commit messages: English
- Tasks: English

1/3. Project working environment language order

Reply with numbers or language names in priority order, or choose cancel.

- [ ] 1. English
- [x] 2. Russian
- [ ] 3. Spanish
- [ ] 4. German
- [ ] 5. French
- [ ] 6. Cancel / Отмена
```

Настройка не переводит уже существующий текст задач, код, команды, логи,
цитаты или язык, который пользователь явно попросил для конкретного ответа.
Если пользователь не называет язык, агент показывает короткий Markdown
checklist с доступными языками и текущим выбором.

Если пользователь явно хочет настроить язык проекта вручную, можно запустить:

```powershell
.\tools\select-project-language.ps1
```

или:

```powershell
.\tools\agent-start.ps1 -ConfigureProjectLanguage
```

### Настроить Языки Коммитов

```text
gi коммит язык: Russian
ги коммит язык: Russian
gi commit language: Russian
gi язык коммита: Russian
gi язык коммита: English only
```

Это старая настройка языка commit-сообщений. По умолчанию `English` без
дополнительных языков. Агент обновляет
`tools/project-memory/git-preferences.json` сам и кратко подтверждает. Если
пользователь не называет языки, агент показывает Markdown checklist с текущим
выбором и пояснением, что `English` обязателен.

### Настроить Системный Язык Агента

```text
gi систем язык: Russian
ги систем язык: Russian
gi system language: Russian
```

Это настройка языка работы агента в проекте: progress updates, финальные
ответы, уточняющие вопросы, пользовательские объяснения, task titles, task
descriptions, task-manager updates, планы и checklists. Агент обновляет
`tools/project-memory/system-preferences.json` сам и кратко подтверждает. Эта
настройка не меняет язык commit-сообщений, код, команды, логи, цитаты или язык,
который пользователь явно попросил для конкретного ответа.

### Git Finish Commands

```text
gi пуш            # commit + push
gi коммит          # commit только
gi только пуш      # push без commit
gi коммит пуш      # commit + push (алиас gi пуш)
gi пул            # fetch + pull текущей ветки
```

Перед любым commit/push агент проверяет `git status --short`, staged/unstaged
changes, remote и ветку. Коммитит только изменения текущей задачи или
явно указанного scope. При блокерах — кратко объясняет.

Для `gi пул` агент проверяет состояние рабочей копии, текущую ветку и upstream,
затем делает `git fetch` и подтягивает текущую ветку. Если появляются
конфликты, агент сначала оценивает их по затронутым файлам и решает только
очевидные, низкорисковые конфликты, сохраняя пользовательские изменения. Если
конфликт требует продуктового решения, затрагивает чужие или секретные файлы,
или его нельзя решить уверенно, агент останавливается и обращается к
пользователю с кратким описанием вариантов.

### Записать Handoff Summary

```text
gi саммари
```

Создаёт `tools/summary/YYYY-MM-DD_HH-mm-ss_AGENT_WORK_SUMMARY.md` по
структуре из `templates/SUMMARY.template.md`.

### Собрать Обзор Последнего Git-Коммита

```text
gi гит-обзор
gi git summary
```

Агент показывает hash, дату, автора, тему, изменённые файлы (компактно),
предполагаемый смысл и заметные риски. Без полного diff, без создания
summary-файла, без commit/push.

### Составить План Тестирования

```text
gi тест-план
gi test plan
```

Агент изучает локальные инструкции, скрипты и тестовую структуру, выдаёт
компактную "лестницу проверок": syntax checks → unit → integration → smoke →
manual → regression. По умолчанию планирует без запуска, если пользователь не
просит запустить.

Для новой фичи: expected behavior, failure paths, edge cases, rollback, что
проверено, что требует ручной проверки.

### Настроить Task-Manager Plan Sync

```text
gi tm
```

Агент проверяет `tools/project-memory/task-managers.json`. Если менеджеры уже
есть — обновляет skill/config из shared kit. Если нет — показывает checklist
доступных адаптеров и `none`. После выбора создаёт конфиг и заполняет
обязательные поля. В конфиге task manager хранится имя или service id менеджера
и project-local preferences; runtime URL агент получает через config-service по
этому service id.

Task-manager commands are routine sync/execution commands once the user has
provided the sprint/task content or selected the workflow. They are suitable for
fast or weaker models only if the model still follows the manager guide and
contract exactly: resolve service id, verify capabilities, send the documented
payload, read back lifecycle identifiers, and stop with the exact blocker when
that cannot be done. Do not replace the manager operation with
`project-memory`, pending-task notes, raw intake receipts, guessed commands,
local checklists, or a request for the user to provide the exact manager
command.

### Test Current Task Manager

```text
gi manager test
gi tm test
gi манагер тест
gi менеджер тест
```

The agent tests the configured task manager end to end in the current project:
resolve the manager service id through config-service, read the manager contract,
create a disposable no-op task through the documented API entry point, load/read
it back, take it in work when the adapter supports that lifecycle step, complete
it as `done`, read the final status, and report the manager id, resolved service
endpoint, task id or URL, completed lifecycle steps, and any missing capability.
The test must not edit repository files, touch secrets, perform destructive
actions, or use another project folder.

### Get Active Task From Task Manager

```text
gi active task
gi next task
gi get task
```

The agent gets executable work from the configured task manager, not from raw
intake receipts or guessed UI routes. It resolves the manager through
config-service, reads the contract, requests the active task first when
supported, otherwise requests the next task through the documented operation,
marks it in progress when supported, executes the task, and sends progress,
blocker, or completion notes back to the manager.

For WorkNest, external agents use `/agent-intake/...` API operations. They do
not move Markdown files, edit internal statuses, archive tasks, or rely on an
old local URL instead of resolving `service_id: worknest` through config-service.

If the manager cannot return lifecycle identifiers, cannot update status, or
the requested object type is blocked by auth/permissions, the agent stops and
reports the exact blocker. It must not create a different object type, raw
intake record, or local checklist note as a substitute for the requested
manager object.

### Add Sprint To Task Manager

```text
gi add sprint
gi create sprint
gi добавить спринт
```

The agent creates a visible executable Sprint/Cycle in the configured task
manager. It resolves the manager through config-service, reads the contract, and
uses only the documented sprint/cycle creation operation or the adapter's
documented executable plan payload. After creation it reads the sprint/cycle
back and reports the lifecycle identifiers or URL.

If the manager only accepts raw intake, or the sprint/cycle endpoint returns an
auth, permission, schema, routing, or object-type error, the agent stops and
reports the blocker. It must not create a Work Item, raw receipt, local
checklist, or one-task plan as a substitute for the requested Sprint/Cycle.

### Отправить План В Task Manager

```text
gi план
gi post plan
```

Агент отправляет текущий план в подключенный task manager. Если менеджер не
настроен — сначала выполняет setup flow как `gi tm`. Если план не дан в
сообщении и не найден в контексте — спрашивает.

Для WorkNest: `POST /agent-intake/raw`. Ответ intake — квитанция, не
подтверждение создания карточки. Before sending, verify raw intake capability,
not only `/health`.

## PS PowerShell Commands

For when you want to run helpers yourself from a bootstrapped project root.
Only commands in this section are meant to be run literally in PowerShell.

### Startup

```text
.\tools\agent-start.ps1
.\tools\agent-start.ps1 -ConfigureGitCommitLanguages
.\tools\agent-start.ps1 -ConfigureSystemLanguage
```

### Configure Commit Languages

```text
.\tools\select-git-commit-languages.ps1
```

### Configure Agent System Language

```text
.\tools\select-system-language.ps1
```

### Check Instruction Updates

```text
.\tools\check-instruction-kit-updates.ps1
.\tools\check-instruction-kit-updates.ps1 -VerboseOutput
.\tools\check-instruction-kit-updates.ps1 -RecordApplied   # только после применения и верификации
```

`-Apply` не является metadata-only shortcut. Применяй файлы миграций до
записи metadata.

### Maintain This Library

```powershell
git diff --check
git diff --stat
git status --short
```

## Команды Для Чата С Агентом: Runtime

### FTP Deploy

```text
gi ftp config
gi ftp service
gi ftp folder
gi ftp push
gi ftp
ги фтп конфиг
ги фтп сервис
ги фтп папка
ги фтп пуш
ги фтп
gi upload ftp
gi deploy ftp
gi zaley na ftp
gi залей на фтп
```

`gi ftp config` / `ги фтп конфиг` creates, inspects, or updates the current
project's FTP/SFTP config without uploading. Use a separate project-local file:
`tools/deploy/ftp.local.json`. Prefer secrets through environment variables or
private keys; do not commit real hostnames, usernames, passwords, tokens,
private keys, or private remote paths unless project policy explicitly marks
them non-secret.

`gi ftp service` / `ги фтп сервис` manually registers, inspects, or selects an
FTP/FTPS/SFTP service record in config-service without uploading. When a project
needs FTP and no local `serviceId` is selected, agents query config-service for
FTP-capable services first. If one exists, they verify its contract and use it;
if several exist, they ask the user to choose with the same numbered Markdown
checkbox style used by language selection. Store only non-secret discovery
metadata and secret reference names in config-service, never raw credentials or
private remote paths.

`gi ftp folder` / `ги фтп папка` inspects, chooses, or updates the remote upload
folder (`remotePath`) without uploading. If credentials and a selected FTP
service are available, the agent may list remote directories and ask the user to
choose with numbered Markdown checkboxes; otherwise it asks for the destination
path and saves it in `tools/deploy/ftp.local.json`.

`gi ftp push` / `ги фтп пуш` is the explicit upload command. `gi ftp` /
`ги фтп` remains a shorter alias. The agent first reads project-local deploy
instructions and
`tools/deploy/ftp.local.json`, builds the configured `localPath` when needed,
then uploads to `remotePath`. If the config is missing, use the redacted
template shape from `templates/ftp.local.template.json` or
`tools/deploy/ftp.local.example.json` and ask only for missing required values.
Do not print secrets or full credential-bearing commands.

`gi config service on` / `gi config service off` sets the current application's
project-local config-service self-registration flag in the same documented
local config area as its config-service URL. `on` is for web-facing apps that
expose a port, HTTP API, web UI, task-manager service, or local daemon endpoint:
on startup they must contact config-service and read their own `service_id`
startup/service record before binding any port. The port to bind and neighboring
service endpoints come from config-service. If config-service is missing,
unreachable, has no record for the app, or returns incomplete startup config,
startup reports the blocker and waits for config-service to be configured,
repaired, or started; it does not guess, scan, or use stale fallback ports.
`off` means the app must not publish or refresh its own service record. Desktop
apps, CLI tools, libraries, scripts, and other non-web apps should not query or
publish to config-service during normal startup unless local instructions
explicitly define a discoverable web/API runtime. If the flag is being set to
`on` and no config-service URL is configured, stop and tell the user to set
`gi config service url=<url>` first. Do not reinterpret `on`/`off` as starting
or stopping the config-service process.

`gi reboot` / `gi restart` starts or restarts the current application using
project-local run instructions. If it is already running, restart it; otherwise
start it in the background.
