# Authorization And Verification Contract

## Purpose / Назначение

Keep clear tasks moving while preserving explicit approval boundaries and
required verification. / Выполнять понятные задачи без лишних пауз, сохраняя
обязательные согласования и проверки.

## Authoritative Rules / Основные правила

- `patterns/AGENTS_RUNTIME/03-rule-precedence.md`: task authorization, material
  clarification, preparation before approval, and operation-scoped blockers.
- `patterns/AGENTS_RUNTIME/07-startup-and-scope.md`: derive a bounded task goal
  without requiring a separate confirmation.
- `patterns/AGENTS_RUNTIME/15-verification.md`: sufficient checks, required gates,
  and evidence-based reasons to repeat or expand verification.

Root and copied-project entrypoints route approval decisions to module 03.
Migration `2026.09.05.1__scope_approval_and_verification_gates` propagates this
contract without replacing project-owned safety requirements.

Корневой файл и шаблон направляют решения о согласованиях в модуль 03.
Миграция распространяет правила, сохраняя локальные требования безопасности.

## Decision Cases / Контрольные случаи

| Case / Случай | Expected behavior / Ожидаемое поведение |
| --- | --- |
| Clear bounded edit / Понятная правка | Derive success criteria and execute / Определить критерии и выполнить |
| Same approved action and target / Уже согласованное действие | Continue without repeated approval / Продолжить без повторного вопроса |
| Material target or effect change / Изменение цели или последствий | Reassess authorization before dependent work / Проверить разрешение до зависимых шагов |
| Required unknown parameter / Неизвестный обязательный параметр | Ask after checking context and defaults / Уточнить после проверки контекста |
| One blocked operation / Заблокирован один шаг | Continue independent work, report gap / Продолжить независимые шаги, сообщить пробел |
| Sufficient checks pass / Достаточные проверки успешны | Finish unless new evidence or mandatory gate / Завершить при отсутствии новых оснований |
| Explicit full test / Явно запрошен полный тест | Complete the required workflow / Выполнить обязательный сценарий |

## Evidence / Основания

Behavioral guidance reviewed from the official documentation:
https://developers.openai.com/api/docs/guides/latest-model#prompting-best-practices

Use this URL as design provenance, not a runtime dependency or a source of
model-specific settings for GI. / Ссылка служит обоснованием принципов, а не
зависимостью GI или источником настроек конкретной модели.

Verification: review the decision cases above, inspect changed rule consistency,
run the documented bootstrap contract check, and validate metadata and whitespace.
Проверка: контрольные случаи, согласованность правил, существующий тест bootstrap,
корректность metadata и отсутствие ошибок пробелов.
