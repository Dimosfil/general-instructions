# Пользовательский обзор инструкций

Этот документ кратко объясняет, как агент должен работать в проектах, которые
используют эту библиотеку инструкций.

## Назначение библиотеки

- Здесь хранятся общие инструкции, шаблоны, playbook'и и правила для AI-агентов.
- Инструкции должны быть пригодны для разных проектов.
- Конкретика одного проекта хранится в его собственных `AGENTS.md`, runbook или
  `tools/project-memory/`.

## Старт работы агента

- В проекте агент сначала читает `AGENTS.md`.
- Затем смотрит последний handoff summary, а не все summary подряд.
- После этого использует только релевантные memory notes и точечный поиск.
- Если первое сообщение в новом чате похоже на название чата или проекта, агент
  должен восстановить контекст, остановиться и спросить, что делать дальше.
  Название не выполняется как задача.
- Для нового проекта лучше писать явную команду с canonical repo:
  `Connect shared instructions: https://github.com/Dimosfil/general-instructions.git`.
- Если агент уже загрузил эти общие правила, URL canonical repo
  `https://github.com/Dimosfil/general-instructions.git` тоже означает
  bootstrap: агент должен прочитать эти правила, создать или обновить локальный
  checkout/cache и развернуть локальный комплект инструкций в текущем проекте
  по шаблонам/checklist'у.
- Команды `инит https://github.com/Dimosfil/general-instructions.git`,
  `init https://github.com/Dimosfil/general-instructions.git` и
  `инициализируй https://github.com/Dimosfil/general-instructions.git` означают тот же
  bootstrap/startup для общей библиотеки инструкций. Агент не должен трактовать
  их как `git init`, настройку OpenCode, создание проекта, агента или навыка,
  если пользователь явно этого не попросил.
- Агент не должен ограничиваться тонким `AGENTS.md`, который только ссылается
  на общую библиотеку.
- Агент не должен добавлять общий repo или checkout как dependency, package,
  submodule, symlink или runtime-ссылку, если пользователь явно этого не
  попросил.

## Экономия токенов

- Не выводить полный `git diff`.
- Использовать `git diff --stat`, `git diff --check` и точечный `Select-String`.
- Не читать большие файлы целиком.
- Особенно избегать чтения целиком больших `index.html`, JS/CSS bundles, логов,
  lockfiles, generated files и build artifacts.
- Не печатать большие логи; использовать tail и поиск конкретных ошибок.
- HTML проверять программно: считать или запрашивать элементы, не выводить весь
  документ.
- Финальные ответы должны быть короткими: что изменилось, какие проверки были,
  какой текущий статус.

## Проверки и запуск

- Не запускать все проверки подряд без явного запроса.
- Не собирать zip-архивы без явного запроса.
- Приложения запускать в фоне, чтобы фокус не прыгал с текущего окна
  пользователя.
- Для веб-приложений UI проверяет пользователь вручную. Агент открывает,
  скриншотит или визуально инспектирует UI только по отдельному запросу.

## Git

- Агент может редактировать и проверять файлы.
- Пользователь ревьюит и коммитит, если явно не попросил агента сделать commit.
- Не откатывать пользовательские изменения без явного запроса.
- Dirty worktree считается нормальным рабочим состоянием.

## Project Memory

- В проектах рекомендуется папка `tools/project-memory/`.
- Важные findings нужно записывать локально, не только в чат.
- Handoff summary нужен для передачи состояния между сессиями.
- Долгоживущие знания хранятся в project memory notes.

## SQLite память агента

- SQLite используется как локальная память и индекс агента, не как база данных
  приложения.
- Рекомендуемый путь: `tools/project-memory/project_memory.sqlite`.
- `.sqlite` обычно является local/generated файлом и не коммитится.
- Коммитятся scripts, schema/docs и Markdown exports.
- В память можно сохранять verified facts, symbols, references, commands,
  failures и notes.
- Нельзя хранить secrets, токены, production data или private user data.
- SQLite нельзя дампить целиком в чат; использовать только targeted queries с
  `LIMIT`.

## Два слоя памяти

- Markdown остаётся human-reviewable слоем: короткие summaries, decisions,
  architecture notes и curated exports.
- SQLite становится searchable слоем агента: detailed findings, file/symbol
  indexes, references, commands, failures и notes с evidence paths.
- Не нужно слепо переносить весь Markdown в SQLite.
- Когда Markdown-память становится слишком большой для дешёвого чтения, нужно
  завести или пересобрать SQLite memory/index, а Markdown оставить кратким
  reviewable export.

## Шаблоны

- `templates/AGENTS.template.md`: стартовый `AGENTS.md` для проекта.
- `templates/AGENT_RUNBOOK.template.md`: runbook проекта.
- `templates/AGENT_WORKING_AGREEMENTS.template.md`: рабочие соглашения.
- `patterns/GIT_WORKFLOW.md`, `templates/git-preferences.template.json` и
  `templates/select-git-commit-languages.template.ps1`: политика Git и выбор
  языков для commit messages.
- `patterns/INSTRUCTION_KIT_MIGRATIONS.md`,
  `templates/check-instruction-kit-updates.template.ps1` и `migrations/`:
  обновление скопированных инструкций по принципу миграций.
- `patterns/SKILL_MODULES.md` и `templates/SKILL.template.md`: когда отдельную
  возможность лучше оформить как reusable skill.
- `templates/project-memory-README.template.md`: описание project memory.
- `templates/STUDY_PLAN.template.md`: план изучения проекта.

## Обновления из проектов

- `updates/` хранит датированные рекомендации, которые приходят из разных
  проектов, но эта папка нужна только для обслуживания самого репозитория
  `general-instructions`.
- Сторонние проекты, которые подключают эти общие инструкции, не должны читать
  `updates/` при startup или bootstrap.
- Эти файлы являются входящей очередью для обслуживания библиотеки, а не
  автоматическими правилами.
- Принятые рекомендации нужно переносить в основные инструкции, шаблоны или
  checklist'ы и запоминать через commit.
- По умолчанию не читать все update-файлы; оценивать только конкретный или
  последний релевантный файл.

## Главное правило

Агент должен помогать быстро и бережно: восстанавливать только нужный контекст,
не шуметь большими выводами, не делать дорогие действия без запроса и сохранять
проверенные знания так, чтобы следующая сессия не начинала с нуля.
