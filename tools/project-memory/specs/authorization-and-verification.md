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

Trusted native Codex hooks call `tools/get-gi-context.ps1` before work and on
Stop, independently of the agent; compacted sessions restore the Work rules.
Entrypoints keep manual Work/Complete fallback for hosts without active hooks;
GI commands add their exact text via `-CommandText`. They carry a reminder of
whole-task verification, honest gaps, and prior complexity agreement.
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

Completion mapping: request -> entrypoint invocation -> builder reads the live
module 03 -> untruncated mandatory prefix -> bounded route/startup remainder.
The Complete phase rereads the same source and returns its full text plus a
completion instruction, without update checks, routing, Git inspection, or
service startup. The optional final-review preference never suppresses it.
Missing/incomplete rules or a budget too small for the protected prefix fail
before any packet is emitted. No thresholds are raised, new approval record is
required, or form/checklist added. Module 15 still owns proportionate checks.

Verification covers every route, phase-only Work and Complete, optional review
Off, oversized context, missing/incomplete/oversized rules, too-small budgets,
LF/CRLF, and the installed public helper. Repeat these checks on a checkout of
the actual published commit, not an unrelated dirty working tree. Native hooks
own automatic invocation, including a real CLI omission test. The Stop receipt
is tied to the rules and work fingerprint and only permits an unchanged automatic
continuation with passing checks. See `docs/gi-lifecycle-hooks.md` for trust,
failure, privacy, and verification limits; copying files is not host activation.

Visible-review mapping: Stop -> shared lifecycle engine -> short `reason` ->
native continuation. Work/compaction remain the full-rule delivery owners;
Complete still validates and fingerprints current rules. Do not embed that
full context in the visible reason or use unsupported suppression to bypass
review. Preserve automatic continuation, stale-receipt rejection, failed-check
blocking and bounded retries. Protocol tests bound the reminder below 700
characters and exercise policy changes as well as work changes. Native UI
delivery must be reported separately from fixture verification.

Desktop service mapping: outgoing create/send -> native sender PreToolUse ->
builder Work/MandatoryOnly -> updatedInput.prompt -> actual delegated input ->
recipient Stop. UserPromptSubmit does not cover these service inputs. Preserve
the original task and all destination fields; forward only shared mandatory
policy, not sender preferences. Explicitly deny on unavailable rules. Record only
tool name and added/reused action, never message content. Verify both native
Desktop service paths with a freshly loaded trusted sender, exact incoming text,
zero recipient tools/manual helper calls, and correlated native audit events.

Связь завершения: входной файл -> вызов сборщика -> чтение актуального модуля 03
-> полный защищённый блок -> обрезаемый остаток контекста. Перед финалом фаза
Complete повторно читает правила без запуска команд, обновлений и сервисов.
Проверка Off не отключает обязательный блок. При нехватке места или правил
частичный пакет не выдаётся. В доверенном Codex вызов сборщика выполняют native
hooks, включая автоматическое продолжение при пропуске Complete агентом.
Без активных hooks ручной fallback не обеспечивает независимого контроля.

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
