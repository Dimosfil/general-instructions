# General Instructions Commands

Command examples for working with the shared `general-instructions` kit.

For full policies, see `AGENTS.md`, `patterns/GIT_WORKFLOW.md`, and
`patterns/FIRST_MESSAGE_HANDLING.md`.

## Команды Для Чата С Агентом

Префикс `gi` — короткая команда для локального instruction kit. Не
переименовывай в `GAI`. `gi` = `general-instructions`, не `git`.

```text
gi обновись
gi init D:\AI\general-instructions\
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
gi install
gi инсталл
ги инсталл
gi старт спринт
gi гит-обзор
gi git summary
gi тест-план
gi test plan
gi tm
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

После успешного `gi обновить` / `gi обновись` агент коммитит и пушит изменения
instruction kit, если это git repository с настроенным remote и изменения
касаются только instruction kit. Без remote, при конфликте или unrelated
changes — остановиться и объяснить блокер.

### Новый Проект

```text
Connect shared instructions: D:\AI\general-instructions\
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

### Получить GI Config

```text
gi config
gi конфиг
ги конфиг
```

Агент получает bootstrap-конфиг сервиса конфигов, а не ищет runtime-конфиги в
папках соседних проектов. Сначала читать project-local override, если он явно
задан локальными инструкциями, затем `D:\AI\general-instructions\config\gi-main.json`
или путь из `GENERAL_INSTRUCTIONS_HOME`. Из GI main config взять
`configServiceUrl` и проверить сам config-service через его `/health` или
документированный discovery endpoint.

Если GI main config или config-service недоступен, остановиться с коротким
блокером. Не подбирать порты, не сканировать `D:\AI\*`, не читать другие
project roots и не использовать старые task-manager записи как замену
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
конфига без опоры на проект. После сборки кратко сообщает артефакты, путь к
инсталлятору и выполненные проверки.

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
Обновись из D:\AI\general-instructions\
```

Если локального kit ещё нет — bootstrap/init. Если уже есть — применить
только недостающие миграции. Использовать `VERSION.md`, `CHANGELOG.md` и
`migrations/`, не читать `updates/`.

`gi обновить` тихий по умолчанию: без прогресс-нарратива, без широких чтений,
без повторяющихся статусов. Только компактный результат: версии до/после,
количество миграций, ID применённых, изменённые файлы, проверки, commit/push.

Если после обновления впервые стал доступен task-manager plan sync, но
`tools/project-memory/task-managers.json` отсутствует или не содержит
включенных менеджеров, сразу предложить numbered Markdown checklist с
доступными адаптерами и `none`. Не подключать WorkNest или другой менеджер
автоматически.

Если сохранённый shared library path недоступен — использовать путь из
команды, `GENERAL_INSTRUCTIONS_HOME` или спросить.

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
ответы, уточняющие вопросы и пользовательские объяснения. Агент обновляет
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
обязательные поля. `base_url` — API endpoint для операций, не UI URL.

### Test Current Task Manager

```text
gi manager test
gi tm test
gi манагер тест
gi менеджер тест
```

The agent tests the configured task manager end to end in the current project:
create a disposable no-op task, load/read it back, take it in work when the
adapter supports that lifecycle step, complete it as `done`, read the final
status, and report the manager id, endpoint, task id or URL, completed lifecycle
steps, and any missing capability. The test must not edit repository files,
touch secrets, perform destructive actions, or use another project folder.

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

## PowerShell Commands

For when you want to run helpers yourself from a bootstrapped project root.

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
