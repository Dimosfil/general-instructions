# Authorization And Verification Contract

## Purpose / Назначение

Keep clear tasks moving while preserving explicit approval boundaries and
required verification. / Выполнять понятные задачи без лишних пауз, сохраняя
обязательные согласования и проверки.

## Authoritative Rules / Основные правила

- `patterns/AGENTS_RUNTIME/03-rule-precedence.md`: task authorization, material
  clarification, advance agreement for material complexity, preparation before
  approval, operation-scoped blockers, whole-task completion, and honest gap
  reporting, independent of optional final review.
- `patterns/AGENTS_RUNTIME/07-startup.md`: derive a bounded task goal
  without requiring a separate confirmation.
- `patterns/AGENTS_RUNTIME/15-verification.md`: sufficient checks, required gates,
  the reference to module 03's completion gate, and evidence-based reasons to
  repeat or expand verification.
- `patterns/AGENTS_RUNTIME/09-runtime-and-defaults.md`: advance notice before
  direct or indirect third-party service launches, separate from approval.

Root and copied-project entrypoints route approval decisions to module 03.
Migration `2026.09.05.1__scope_approval_and_verification_gates` propagates this
contract without replacing project-owned safety requirements.

Migration `2026.10.24.1__require_whole_task_completion_and_complexity_agreement`
adds mandatory completion and advance complexity agreement to both entrypoints.
Use the existing request, plan, and evidence; no new form or approval of routine
choices is required. / Миграция добавляет обязательную проверку всей задачи и
согласование существенных усложнений заранее, без новых форм и согласования
обычных рабочих шагов.

Корневой файл и шаблон направляют решения о согласованиях в модуль 03.
Миграция распространяет правила, сохраняя локальные требования безопасности.

## Decision Cases / Контрольные случаи

| Case / Случай | Expected behavior / Ожидаемое поведение |
| --- | --- |
| Clear bounded edit / Понятная правка | Derive success criteria and execute / Определить критерии и выполнить |
| Same approved action and target / Уже согласованное действие | Continue without repeated approval / Продолжить без повторного вопроса |
| Authorized third-party service launch / Разрешённый запуск стороннего сервиса | Warn before launch; preserve authorization / Предупредить до запуска; использовать существующее разрешение |
| Script or container command starts a dependency / Скрипт или команда контейнера запускает зависимость | Identify the service and warn before the command / Назвать сервис и предупредить до команды |
| Query an already-running service / Запрос к работающему сервису | No launch notice needed / Предупреждение о запуске не требуется |
| Material target or effect change / Изменение цели или последствий | Reassess authorization before dependent work / Проверить разрешение до зависимых шагов |
| Required unknown parameter / Неизвестный обязательный параметр | Ask after checking context and defaults / Уточнить после проверки контекста |
| One blocked operation / Заблокирован один шаг | Continue independent work, report gap / Продолжить независимые шаги, сообщить пробел |
| Sufficient checks pass / Достаточные проверки успешны | Finish unless new evidence or mandatory gate / Завершить при отсутствии новых оснований |
| Explicit full test / Явно запрошен полный тест | Complete the required workflow / Выполнить обязательный сценарий |
| One subtask passes, integration missing / Проверена часть без интеграции | Continue required work; do not claim whole-task completion / Доделать обязательную часть, не объявлять всю задачу готовой |
| Build or mocks pass, real path unchecked / Сборка или моки успешны, рабочий путь не проверен | Report the verification limit and its effect / Указать границу проверки и влияние на результат |
| Required check unavailable / Обязательная проверка недоступна | Deliver independent work with an explicit unverified remainder / Выполнить независимые шаги и явно назвать непроверенный остаток |
| Optional final review off / Дополнительная финальная проверка выключена | Whole-task completion and truthful reporting remain mandatory / Проверка всей задачи и честный отчёт обязательны |
| Material complexity beyond agreement / Существенное усложнение сверх договорённости | Explain need and impact; obtain agreement before implementation / Объяснить необходимость и последствия, согласовать до реализации |
| Necessary local fix within agreed scope / Необходимое локальное исправление в согласованном объёме | Execute without another approval or new document / Выполнить без нового согласования и документа |

## Evidence / Основания

Completion mapping: request -> entrypoints load modules 03/15 -> module 03 owns
scope, complexity agreement, whole-task evidence and gap reporting -> module 15
references the gate and owns proportionate checks -> decision-case review
and installed-kit delivery check. These are agent instructions, not a runtime
validator or a guarantee that future agents obey them.

Связь завершения: запрос -> загрузка модулей 03/15 -> согласование усложнения и
проверка всей задачи -> правила, шаблон и миграция -> контрольные случаи и
проверка доставки. Это инструкции агенту, а не программная блокировка завершения.

Service-launch mapping: launch decision -> entrypoint safety routing -> runtime
module owns advance notice -> source and copied-project entrypoints plus
accepted migration -> decision-case review and bootstrap propagation check.
Launch permission and required approvals remain owned by module 03.

Связь запуска: решение о запуске -> маршрутизация в основном файле -> правило
предупреждения в модуле запуска -> основные файлы и миграция -> проверка
контрольных случаев и bootstrap. Разрешения остаются в модуле 03.

Behavioral guidance reviewed from the official documentation:
https://developers.openai.com/api/docs/guides/latest-model#prompting-best-practices

Use this URL as design provenance, not a runtime dependency or a source of
model-specific settings for GI. / Ссылка служит обоснованием принципов, а не
зависимостью GI или источником настроек конкретной модели.

Verification: review the decision cases above, inspect changed rule consistency,
run the documented bootstrap contract check, and validate metadata and whitespace.
Проверка: контрольные случаи, согласованность правил, существующий тест bootstrap,
корректность metadata и отсутствие ошибок пробелов.
