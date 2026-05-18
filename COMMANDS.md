# General Instructions Commands

Copy-paste prompts and shell commands for working with this shared instruction
library and projects that copy its instruction kit.

## Команды Для Чата С Агентом

Пиши эти команды обычным сообщением в чат агента.

### Короткий Префикс

Команды с префиксом `gi` относятся к shared instruction kit
`general-instructions`, а не к продуктовой задаче проекта.

```text
gi обновись
```

```text
gi init D:\AI\general-instructions\
```

```text
gi язык коммита: Russian
```

```text
gi язык коммита: English only
```

```text
gi саммари
```

```text
gi гит-обзор
```

```text
gi git summary
```

```text
gi тест-план
```

```text
gi test plan
```

```text
gi tm
```

```text
gi пуш
```

```text
gi коммит
```

```text
gi только пуш
```

Если команда с `gi` неполная, агент должен уточнить недостающий параметр, а не
угадывать. Например, на `gi выбрать язык коммита` нужно спросить, какие
дополнительные языки включить, и показать короткий numbered Markdown checklist
с пояснением, что `English` является обязательным primary language.

Ответ на `gi` команду должен быть ограничен этой командой. После выполнения
агент не должен сам возвращаться к предыдущей продуктовой задаче или продолжать
старый вопрос, если пользователь явно этого не попросил.

`gi` команда выполняется в текущем project root. Агент не должен сам переходить
в другой репозиторий, в shared library или в путь из прошлой задачи. Shared
library можно читать только как источник `VERSION.md`, `CHANGELOG.md`, `INDEX.md`,
`migrations/` и шаблонов.

`gi` означает `general-instructions`, а не `git`. Отсутствие `.git` в текущем
проекте не означает, что instruction kit обновлять нечего. В папке без git агент
всё равно должен проверить и применить доступные GI-обновления к локальным
instruction files; пропускается только финальный commit/push.

После успешного `gi обновить` / `gi обновись` агент должен закоммитить и
запушить изменения instruction kit в текущем проекте, если это git repository с
настроенным remote. Коммит должен включать только изменения instruction kit. Если
есть unrelated/user changes, нет git или remote, push невозможен или есть
конфликт, агент должен остановиться и кратко объяснить, что нужно сделать.

Если после `gi обновить` / `gi обновись` впервые стала доступна task-manager
plan sync миграция, но `tools/project-memory/task-managers.json` отсутствует или
не содержит включенных менеджеров, агент должен сразу предложить выбрать
менеджеры. Для выбора нужно показать numbered Markdown checklist с checkbox'ами
по образцу выбора языков:

```markdown
Выбери task-manager adapters для plan sync:

1. [ ] WorkNest — отправлять планы в WorkNest raw intake.
2. [ ] none — ничего не подключать сейчас.
```

Пользователь может ответить номерами или названиями. Агент не должен
автоматически подключать WorkNest без ответа пользователя.

### Новый Проект

Разверни локальный комплект инструкций в новом проекте:

```text
Connect shared instructions: D:\AI\general-instructions\
```

Ожидаемое поведение агента:

- прочитать общие правила и нужные шаблоны;
- создать локальные `AGENTS.md`, `tools/AGENT_WORKING_AGREEMENTS.md`,
  `tools/AGENT_RUNBOOK.md`, `tools/agent-start.ps1` и project memory files;
- не добавлять `D:\AI\general-instructions\` как dependency, submodule или
  symlink;
- не спрашивать про языки коммитов при bootstrap;
- остановиться после setup и спросить, что делать дальше.

Если агент уже загрузил эти общие правила, голый путь тоже допустим:

```text
D:\AI\general-instructions\
```

### Восстановить Контекст Проекта

```text
Восстанови контекст проекта по AGENTS.md и tools/agent-start.ps1, затем кратко скажи текущий статус и спроси, что делать дальше.
```

### Проверить Обновления Инструкций

```text
Обновись из general-instructions.
```

Если проект ещё не подключал общий instruction kit, используй команду с путём:

```text
Обновись из D:\AI\general-instructions\
```

Ожидаемое поведение агента: проверить принятые обновления instruction kit из
`D:\AI\general-instructions\`. Если локального kit ещё нет, сначала выполнить
bootstrap/init из этого пути. Если kit уже есть, применить только недостающие
миграции. Использовать только `VERSION.md`, `CHANGELOG.md` и `migrations/`, не
читать `updates/`, сохранить проектные правки и кратко отчитаться. Если
сохранённый путь к shared library недоступен в текущей среде, агент должен
использовать путь из команды, `GENERAL_INSTRUCTIONS_HOME` или коротко попросить
актуальный путь.

### Настроить Языки Коммитов

```text
Настрой языки commit messages: English + Russian.
```

По умолчанию используется `English` без дополнительных языков. Эту настройку
нужно менять только по явной просьбе. Агент должен обновить
`tools/project-memory/git-preferences.json` сам и кратко подтвердить результат,
а не отвечать только PowerShell-командой. Если пользователь просит только
`выбрать язык коммита` и не называет языки, агент должен уточнить выбор, а не
угадывать по языку сообщения. Для уточнения нужно использовать numbered
Markdown checklist с текущим выбором и пояснением, что `English` всегда включен
как обязательный primary language. Пользователь может ответить номерами или
названиями языков.

### Git Finish Commands

```text
gi пуш
```

```text
gi коммит
```

```text
gi только пуш
```

```text
gi коммит пуш
```

`gi пуш` означает: подготовить scoped commit по текущим изменениям и затем
запушить текущую ветку. `gi коммит пуш` означает то же самое. Допустимые алиасы:
`gi commit push`, `gi commit and push`, `gi finish`.

`gi коммит` означает: сделать commit, но не push. Допустимый алиас: `gi commit`.

`gi только пуш` означает: выполнить только push уже существующих локальных
коммитов, не создавая новый commit. Допустимые алиасы: `gi push only`,
`gi just push`.

Перед любым commit/push агент должен проверить `git status --short`, staged и
unstaged changes, remote и текущую ветку. Если есть unrelated/user changes,
секреты, конфликт, нет git repository, нет remote, непонятно что включать в
commit, или push невозможен, агент должен остановиться и кратко объяснить
блокер. Коммитить нужно только изменения, относящиеся к текущей задаче или
явно указанному пользователем scope. Сообщение commit должно следовать
`tools/project-memory/git-preferences.json`, если файл есть.

### Записать Handoff Summary

```text
gi саммари
```

Ожидаемое поведение агента: создать `tools/summary/`, если папки нет, и записать
краткий handoff summary в файл
`tools/summary/YYYY-MM-DD_HH-mm-ss_AGENT_WORK_SUMMARY.md` по структуре из
`templates/SUMMARY.template.md`. Не ограничиваться ответом в чат.

### Собрать Обзор Последнего Git-Коммита

```text
gi гит-обзор
```

```text
gi git summary
```

Ожидаемое поведение агента: в текущем project root проверить, что доступен git
repository, найти последний коммит текущей ветки по дате коммита и кратко
собрать информацию по нему в чат. Допустимые русские варианты:

- `gi гит обновления`
- `gi гит-обновления`
- `gi обзор коммита`

Агент должен использовать компактные git-запросы, например:

```powershell
git log -1 --date=iso-strict --format=fuller
git show --stat --name-status --find-renames --find-copies --format=fuller HEAD
```

В отчете указать hash, дату, автора, тему/сообщение, измененные файлы, краткую
статистику, предполагаемый смысл изменения и заметные риски или проверки. Не
печатать полный diff по умолчанию. Не создавать summary-файл и не делать commit
или push для этой команды.

### Составить План Тестирования Проекта Или Фичи

```text
gi тест-план
```

```text
gi test plan
```

Допустимые варианты:

- `gi проверить фичу`
- `gi feature check`
- `gi план проверки`
- `gi test strategy`

Ожидаемое поведение агента: в текущем project root изучить локальные инструкции,
скрипты и тестовую структуру проекта, затем составить компактный план проверки.
Команда по умолчанию планирует проверки, но не запускает их автоматически,
если пользователь явно не попросил запуск.

Агент должен определить тип проекта и доступные проверки: `package.json`,
`pyproject.toml`, `.csproj`, CI configs, README, AGENTS/runbook, папки тестов и
локальные tool scripts. Затем выдать "лестницу проверок":

- быстрые syntax/static checks;
- focused automated tests для затронутой области;
- integration/API/UI smoke checks;
- manual checklist для пользовательских сценариев;
- regression areas;
- optional full suite перед релизом.

Для новой фичи отчет должен назвать expected behavior, failure paths, edge
cases, rollback/fallback behavior, что проверено автоматически, что требует
ручной проверки, и что осталось непроверенным. Для UI соблюдать локальные
правила проекта: если автоматический visual inspection не разрешен, дать manual
checklist вместо самостоятельных screenshot/browser checks.

Если пользователь просит сохранить план, создать файл на основе
`templates/FEATURE_TEST_PLAN.template.md` в project-local месте, например
`tools/project-memory/feature-test-plan.md` или в task-specific memory file.

### Настроить Или Обновить Task-Manager Plan Sync

```text
gi tm
```

Допустимые варианты:

- `gi task manager`
- `gi task managers`
- `gi менеджер задач`
- `gi таск-менеджер`

Ожидаемое поведение агента: остаться в текущем project root и проверить
`tools/project-memory/task-managers.json`.

Если подключенные менеджеры уже есть, агент должен проверить доступные
обновления task-manager skill/config из shared instruction kit, применить только
нужные безопасные обновления и кратко назвать подключенные менеджеры.

Если подключенных менеджеров нет, агент должен показать короткий numbered
Markdown checklist с checkbox'ами для доступных адаптеров из
`skills/task-manager-plans/references/managers/` и варианта `none`, затем
спросить, какие менеджеры подключить. После выбора создать или обновить
`tools/project-memory/task-managers.json` из
`templates/task-managers.template.json`.

Секреты, токены, cookies, пароли и private workspace data нельзя записывать в
task-manager config или shared instruction files.

## PowerShell Commands

Use these from a bootstrapped project root when you want to run the local helper
scripts yourself.

### Start A New Project

In a new project chat, use an explicit bootstrap request:

```text
Connect shared instructions: D:\AI\general-instructions\
```

If an agent has already loaded these shared rules, a bare path is also valid:

```text
D:\AI\general-instructions\
```

The agent should bootstrap local project instruction files from templates and
then stop to ask what to do next.

### Restore Project Context

From a bootstrapped project root:

```powershell
.\tools\agent-start.ps1
```

### Configure Commit Message Languages

From a bootstrapped project root:

```powershell
.\tools\select-git-commit-languages.ps1
```

or through startup:

```powershell
.\tools\agent-start.ps1 -ConfigureGitCommitLanguages
```

English is primary. Optional additional languages are Russian, Spanish, German,
and French.

### Check Instruction Updates

From a bootstrapped project root:

```powershell
.\tools\check-instruction-kit-updates.ps1
```

When ready to record applied migrations after an agent has applied the file
changes:

```powershell
.\tools\check-instruction-kit-updates.ps1 -Apply
```

The update workflow uses accepted release artifacts and `migrations/`. It must
not read `updates/`.

### Maintain This Library

Run documentation whitespace checks:

```powershell
git diff --check
```

Review changed-file summary:

```powershell
git diff --stat
```

Check status:

```powershell
git status --short
```

Commit only when explicitly requested:

```powershell
git add <files>
git commit -m "English summary" -m "Russian: TODO translated summary"
```

Push only when explicitly requested:

```powershell
git push origin main
```
