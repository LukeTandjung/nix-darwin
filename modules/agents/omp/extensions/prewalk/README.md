# Prewalk

Vendored unchanged from `architect-eng/nightshade`, commit
`60bc55946331c82248bf7ad0e23b626f907da77e`, `.pi/extensions/prewalk/`.

`/prewalk` opens the searchable implementation-model picker.
`/prewalk provider/model` selects a target explicitly; `/prewalk off` cancels.
The current model plans and makes the first successful edit/write, then hands
execution to the selected model (after the todo gate, when todo is active).

Autolith's adapter lives in `../../../autolith/prewalk.lisp` and uses its native
searchable model picker, `plan.update`, and `resource.edit`. Neither interactive
command silently chooses a fixed executor. Autolith's non-interactive startup
uses `AUTOLITH_PREWALK_INTO=MODEL`; Pi supports `--prewalk-into provider/model`.
