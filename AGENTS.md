# Mistral Code Game Studios — Vibe edition

Ported from [Claude Code Game Studios](https://github.com/donchitos/claude-code-game-studios) to Mistral Vibe.

- **Skills**: `.vibe/skills/<name>/SKILL.md` — user-invocable via `/<name>` (e.g. `/prototype`)
- **Subagents**: `.vibe/agents/*.toml` — spawn via the `agents_spawn` tool with `config_name`
- **Hooks**: `.vibe/hooks.toml` — original CCGS hooks run through `.vibe/hooks/cc-adapter.sh`
- **Guards**: `.vibe/config.toml` — bash/file denylists mirror the deny rules of `.claude/settings.json`
- The original `.claude/` tree stays in the repo for Claude Code users; skills and docs reference it.

---

# Vibe Game Studios -- Game Studio Agent Architecture

Indie game development managed through 49 coordinated Vibe subagents.
Each agent owns a specific domain, enforcing separation of concerns and quality.

## Technology Stack

- **Engine**: [CHOOSE: Web / Godot 4 / Unity / Unreal Engine 5]
- **Language**: [CHOOSE: TypeScript / GDScript / C# / C++ / Blueprint]
- **Version Control**: Git with trunk-based development
- **Build System**: [SPECIFY after choosing engine]
- **Asset Pipeline**: [SPECIFY after choosing engine]

> **Note**: Engine-specialist agents exist for Godot, Unity, and Unreal with
> dedicated sub-specialists. Use the set matching your engine.

## Project Structure

Read `.claude/docs/directory-structure.md` on demand.
## Engine Version Reference

<!-- ENGINE-REFERENCE-IMPORT: the line under this comment is engine-specific,
     and there is none until an engine is set. /setup-engine, the grow's record
     step and /project-settings (engine.name) write
     @docs/engine-reference/<engine>/VERSION.md here for the chosen engine. Skills
     that need the pinned version read that file on demand either way. -->


## Technical Preferences

`project.yaml` at the repo root is the primary config store — engine, specialists,
naming, platform, performance, modes. Skills resolve it via `resolve_config`
(see `.claude/docs/config-resolution.md`).

`.claude/docs/technical-preferences.md` is the **legacy fallback**, read on demand
when a key is absent from `project.yaml`. It is not imported here: before
`/setup-engine` runs it is almost entirely `[TO BE CONFIGURED]` placeholders, and
after it runs `project.yaml` holds the real values.

## Coordination Rules

Read `.claude/docs/coordination-rules.md` on demand.
## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
  (exempt: `active.md` appends, agent memory, a subagent's new file at the path
  its orchestrating skill named; see `.claude/rules/agent-memory.md`)
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction
- A skipped or dismissed question is not an answer: act on nothing, re-ask in
  plain text and wait
- Started outside this file's folder? Warn first: hooks, deny rules and the
  ask-first mode load only when Vibe starts here

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for full protocol and examples.

> **First session?** Say "make me a game" (`/prototype`), or run `/start` to begin
> the guided onboarding flow.

## Coding Standards

Read `.claude/docs/coding-standards.md` on demand.
## Context Management

Read `.claude/docs/context-management.md` on demand — it is a reference, not
session context. Two of its conventions are load-bearing and cited by name
elsewhere in the repo, so they are restated here rather than lost:

- **`production/session-state/active.md` is the session checkpoint.** The file is
  the memory, not the conversation. Read it first after any compaction, crash, or
  `/clear`.
- **Helpers in `.claude/scripts/` emit observations, never verdicts.** A script
  that scores or judges will eventually contradict a mode or override it cannot
  see. (Cited by `artifact-check.sh` and `adr-dep-graph.sh`.)


# Path-scoped rules (from .claude/rules/)

## Rule: agent-memory (applies to: `.claude/agent-memory/**`)

# Agent Memory Rules

**Agent memory is one of three writes that need no "May I write?"** The other two
are named in `CLAUDE.md`:

- **Appends to `production/session-state/active.md`** — the session checkpoint
  the hooks and the next session rely on. An append, never a rewrite of what is
  already there.
- **A subagent's new file at the path its orchestrating skill named.** Only a
  new file under `production/`, `docs/` or `tests/`, only at a path the skill's
  prompt names (never one you chose), and only inside a phase the user approved.

`.claude/agent-memory/` is gitignored, per-agent, and never ships. Its exemption
exists because the memory is the agent's own working notes about how to do its
job, not a project artifact.

None of the three extends anywhere else. The Collaboration Protocol still governs
every other write under the code root (`src/`, `Assets/` or `Source/`),
`design/`, `docs/`, `production/` and `assets/`: ask first, naming the path.
Writing a memory is never a substitute for asking, and a memory must never be
used to record something the user declined to have written.

## Never record a temporary absence as a durable fact

This is the failure this file exists to prevent, and this repo is unusually
exposed to it.

**Claude Code Game Studios ships as a template the user clones *as their game*.** So on day one every
agent observes the same things — no game code, no GDDs, no engine configured, no
`tests/performance/` — and every one of those observations is **guaranteed to
stop being true**. A memory reading *"this repo is the framework, not a game;
perf requests have no target"* is accurate when written and actively harmful two
weeks later, when it tells a future run to return BLOCKED on a project that now
has a build. The agent will not re-derive it; that is what memory is for.

So:

- **Prefer recording a method over a state.** "Confirm an engine project and a
  captured profile exist before profiling; return BLOCKED naming what is missing
  rather than estimating" is durable. "There is no game here" is a timestamp.
- **If you must record a state, state what invalidates it**, on the same line:
  `INVALIDATED WHEN: project.yaml declares an engine, or the code root (src/, Assets/ or Source/) contains game code.`
  A reader with no other context must be able to tell whether the note still
  holds.
- **Never record absence of a game, of assets, of tests or of config as a
  settled property of the project.** Those are the states Claude Code Game Studios exists to move a
  user out of.

## Disclose the write

Say in your response that you recorded a memory and where. An unmentioned write
is indistinguishable from no write, and the user cannot correct a note they do
not know exists — the same reason a skipped check has to announce itself
(`.claude/rules/skill-authoring.md`, obligation 3).

## Verify before you trust

A recalled memory reflects what was true when it was written. If it names a file,
a path, a setting or a count, **check that it still holds before acting on it**.
Memory is a starting point for investigation, never evidence.


## Rule: ai-code (applies to: `src/ai/**`, `Assets/**/{AI,Ai,ai}/**/*.cs`, `Source/**/{AI,Ai,ai}/**/*.{h,cpp}`)

# AI Code Rules

- AI update budget: 2ms per frame maximum — profile to verify
- All AI parameters must be tunable from data files (behavior tree weights, perception ranges, timers)
- AI must be debuggable: implement visualization hooks for all AI state (paths, perception cones, decision trees)
- AI should telegraph intentions — players need time to read and react
- Prefer utility-based or behavior tree approaches over hard-coded if/else chains
- Group AI must support formation, flanking, and role assignment from data
- All AI state machines must log transitions for debugging
- Never trust AI input from the network without validation


## Rule: data-files (applies to: `assets/data/**/*.json`, `data/**/*.json`, `Assets/**/{Data,data}/**/*.json`, `Content/**/{Data,data}/**/*.json`)

# Data File Rules

- All JSON files must be valid JSON — broken JSON blocks the entire build pipeline
- File naming (Godot and Web data): lowercase with underscores only, following `[system]_[name].json` pattern.
  Unity and Unreal data keep the engine's PascalCase; `validate-assets.sh` checks names only in `assets/`.
  On Web, `data/config.json` keeps its name: the game and its tweak panel read that file, and
  each tuning value in it is an object of `value`, `min`, `max` and `step`
- Every data file must have a documented schema (either JSON Schema or documented in the corresponding design doc)
- Numeric values must include comments or companion docs explaining what the numbers mean
- Use consistent key naming: **`snake_case` for keys within JSON files**, matching
  the `[system]_[name].json` file convention one line above and the engine idiom
  every other standard in this repo uses.

  > **On Unity and Unreal this costs you a mapping layer — budget for it rather
  > than changing the keys.** `JsonUtility` binds by *exact field name*, and C#
  > fields are `camelCase` per `naming.variables`, so a snake_case file cannot bind
  > directly to the type that consumes it. Use a private nested DTO whose fields
  > are the wire format and which maps once into your real type, or take a
  > dependency that supports a naming policy (Newtonsoft `SnakeCaseNamingStrategy`,
  > `System.Text.Json` `JsonNamingPolicy`). Do **not** switch the file to camelCase
  > to avoid the DTO: keys are the cross-engine contract. Write the DTO and
  > document it as a wire-format boundary — that is the intended shape.
- No orphaned data entries — every entry must be referenced by code or another data file
- Version data files when making breaking schema changes
- Include sensible defaults for all optional fields

## Examples

**Correct** naming and structure (`combat_enemies.json`):

```json
{
  "goblin": {
    "base_health": 50,
    "base_damage": 8,
    "move_speed": 3.5,
    "loot_table": "loot_goblin_common"
  },
  "goblin_chief": {
    "base_health": 150,
    "base_damage": 20,
    "move_speed": 2.8,
    "loot_table": "loot_goblin_rare"
  }
}
```

**Incorrect** (`EnemyData.json`):

```json
{
  "Goblin": { "hp": 50 }
}
```

Violations: uppercase filename, uppercase key, no `[system]_[name]` pattern, missing required fields.


## Rule: design-docs (applies to: `design/gdd/**`)

# Design Document Rules

- The 8 GDD sections are: Overview, Player Fantasy, Detailed Rules, Formulas, Edge Cases, Dependencies, Tuning Knobs, Acceptance Criteria
- **How many are required depends on `modes.workflow`** — all 8 at `full`, 5 (+ Formulas when the system **defines numeric rules**: rates, curves, thresholds, costs, damage, drop weights — anything a balance pass would tune) at `standard`, none at `minimal` (the design record there is `design/game-brief.md`). Resolve the tier before flagging a section as missing; see `.claude/docs/workflow-modes.md`
- **The Formulas test is what the system defines, not what it is called.** A system's `Category` in `systems-index.md` is a hint — `Gameplay`, `Economy` and `Progression` almost always qualify — never the test. Do not gate Formulas on a category token: the categories `/map-systems` writes (`Core · Gameplay · Progression · Economy · Persistence · UI · Audio · Narrative · Meta`) do not include `combat` or `AI`, which are example systems *within* `Gameplay`. Every site stating this rule must state the same test.
- **Section-name alias**: The GDD template and `/design-system` author this section as `## Detailed Design`; the design standard calls it **Detailed Rules**. These are the SAME required section — accept either heading and never rewrite one into the other.
- Formulas must include variable definitions, expected value ranges, and example calculations
- Edge cases must explicitly state what happens, not just "handle gracefully"
- Dependencies must be bidirectional — if system A depends on B, B's doc must mention A
- Tuning knobs must specify safe ranges and what gameplay aspect they affect
- Acceptance criteria must be testable — a QA tester must be able to verify pass/fail
- No hand-waving: "the system should feel good" is not a valid specification
- Balance values must link to their source formula or rationale
- Design documents MUST be written incrementally: create skeleton first, then fill
  each section one at a time with user approval between sections. Write each
  approved section to the file immediately to persist decisions and manage context


## Rule: engine-code (applies to: `src/core/**`, `Assets/**/{Core,core}/**/*.cs`, `Source/**/{Core,core}/**/*.{h,cpp}`)

# Engine Code Rules

- ZERO allocations in hot paths (update loops, rendering, physics) — pre-allocate, pool, reuse
- All engine APIs must be thread-safe OR explicitly documented as single-thread-only
- Profile before AND after every optimization — document the measured numbers
- Engine code must NEVER depend on gameplay code (strict dependency direction: engine <- gameplay)
- Every public API must have usage examples in its doc comment
- Changes to public interfaces require a deprecation period and migration guide
- Use RAII / deterministic cleanup for all resources
- All engine systems must support graceful degradation
- Before writing engine API code, consult `docs/engine-reference/` for the current engine version and verify APIs against the reference docs

## Examples

**Correct** (zero-alloc hot path) — Godot:

```gdscript
# Pre-allocated array reused each frame
var _nearby_cache: Array[Node3D] = []

func _physics_process(delta: float) -> void:
    _nearby_cache.clear()  # Reuse, don't reallocate
    _spatial_grid.query_radius(position, radius, _nearby_cache)
```

Unity:

```csharp
private readonly Collider[] _nearbyCache = new Collider[64];  // allocated once

void FixedUpdate()
{
    int count = Physics.OverlapSphereNonAlloc(transform.position, radius, _nearbyCache);
}
```

Unreal:

```cpp
// TArray member, reserved once; Reset() keeps the allocation
void UProximityComponent::TickComponent(float DeltaTime, ELevelTick TickType,
                                        FActorComponentTickFunction* ThisTickFunction)
{
    NearbyCache.Reset();
    SpatialGrid->QueryRadius(GetComponentLocation(), Radius, NearbyCache);
}
```

**Incorrect** (allocating in hot path):

```gdscript
func _physics_process(delta: float) -> void:
    var nearby: Array[Node3D] = []  # VIOLATION: allocates every frame
    nearby = get_tree().get_nodes_in_group("enemies")  # VIOLATION: tree query every frame
```


## Rule: gameplay-code (applies to: `src/gameplay/**`, `src/game/**`, `Assets/**/{Gameplay,gameplay}/**/*.cs`, `Source/**/{Gameplay,gameplay}/**/*.{h,cpp}`)

# Gameplay Code Rules

- ALL gameplay values MUST come from external config/data files, NEVER hardcoded
- Use delta time for ALL time-dependent calculations (frame-rate independence)
- NO direct references to UI code — use events for cross-system communication
  (Godot signals, C# events, Unreal delegates)
- Every gameplay system must implement a clear interface
- State machines must have explicit transition tables with documented states
- Write unit tests for all gameplay logic — separate logic from presentation
- Document which design doc each feature implements in code comments
- No static singletons for game state — use dependency injection

## Examples

**Correct** (data-driven) — Godot:

```gdscript
var damage: float = config.get_value("combat", "base_damage", 10.0)
var speed: float = stats_resource.movement_speed * delta
```

Unity (values from a ScriptableObject):

```csharp
float damage = combatConfig.BaseDamage;
float speed = stats.MovementSpeed * Time.deltaTime;
```

Unreal (values from a data asset):

```cpp
const float Damage = CombatConfig->BaseDamage;
const float Speed = Stats->MovementSpeed * DeltaTime;
```

**Incorrect** (hardcoded):

```gdscript
var damage: float = 25.0   # VIOLATION: hardcoded gameplay value
var speed: float = 5.0      # VIOLATION: not from config, not using delta
```


## Rule: narrative (applies to: `design/narrative/**`)

# Narrative Rules

- All new lore must be cross-referenced against existing lore for contradictions
- Every lore entry must specify canon level: Established / Provisional / Under Review
- Character dialogue must match the voice profile defined for that character
- World rules (what is possible/impossible) must be explicitly documented and consistent
- Mysteries must have documented "true answers" even if players never learn them
- Faction motivations, relationships, and power structures must be internally logical
- All narrative text must be localization-ready: no idioms that don't translate, named placeholders for variables
- No line of dialogue should exceed 120 characters for dialogue box constraints


## Rule: network-code (applies to: `src/networking/**`, `Assets/**/{Networking,networking,Network,network}/**/*.cs`, `Source/**/{Networking,networking,Network,network}/**/*.{h,cpp}`)

# Network Code Rules

- Server is AUTHORITATIVE for all gameplay-critical state — never trust the client
- All network messages must be versioned for forward/backward compatibility
- Client predicts locally, reconciles with server — implement rollback for mispredictions
- Handle disconnection, reconnection, and host migration gracefully
- Rate-limit all network logging to prevent log flooding
- All networked values must specify replication strategy: reliable/unreliable, frequency, interpolation
- Bandwidth budget: define and track per-message-type bandwidth usage
- Security: validate all incoming packet sizes and field ranges


## Rule: prototype-code (applies to: `prototypes/**`)

# Prototype Code Standards

Two kinds of prototype live under `prototypes/`, with different rules. A **one-shot**
(`prototypes/<name>/` with `index.html` and `config.js`, built by `/prototype` in the browser) is
the start of a game the person may keep. An **engine or paper prototype**
(`prototypes/[name]-concept/`, `-spike-`, `-vertical-slice/`) is throwaway code that answers one
question.

## Every prototype
- Each prototype lives in its own subdirectory: `prototypes/[name]/`
- Each file that can hold a comment starts with the PROTOTYPE - NOT FOR PRODUCTION header
- No production code may reference or import from `prototypes/`
- An engine or paper prototype must not modify files outside `prototypes/`, and is never
  deployed or shipped as it is
- A one-shot may also write `design/game-brief.md` and save pasted images to `references/`;
  it is shared from its `dist/` copy (`one-shot-share.sh`), never from its working folder

## One-shots
- Every tuning value lives in `config.js` (`window.CONFIG`), each with value, min, max and step,
  plus `seed`; the game reads them live and never hardcodes them
- Gameplay randomness goes through the seeded `rng()`, never `Math.random`
- It plays offline: libraries in `vendor/`, no requests to the network while it runs
- Every file in `assets/` and `vendor/` has an entry in `assets/provenance.yaml`; a placeholder
  carries `placeholder: true` and `_ph` before its extension
- `brief.md` (a copy of `design/game-brief.md`) takes the place of a README
- Polish belongs to it: title, game over and restart, sound and mute where the brief calls for
  them
- On PROCEED it may grow into the project root (`/prototype`'s grow step); `prototypes/<name>/`
  itself is never edited by growing

## Engine and paper prototypes

Standards are intentionally relaxed to maximize iteration speed. The goal is learning, not
production quality.

### What's Allowed
- Hardcoded values (no need for data-driven config)
- Minimal or no doc comments
- Simple architecture (no dependency injection required)
- Singletons and global state
- Copy-pasted code (no need for abstraction)
- Debug output left in place
- Placeholder art and audio
- Quick-and-dirty solutions

### What's Still Required
- Every engine or paper prototype has a `README.md` with:
  - What hypothesis is being tested
  - How to run the prototype
  - Current status (in-progress / concluded)
  - Findings (updated when prototype concludes)

### When an engine or paper prototype succeeds
If a prototype validates a concept and the feature moves to production:
1. The prototype code is NOT migrated directly — it is rewritten to production standards
2. The prototype `README.md` findings inform the production design document
3. The prototype directory is preserved for reference but never extended

### Cleanup
Concluded prototypes should be archived or deleted after findings are captured.
Never let engine or paper prototype code grow into production code through incremental
"cleanup." A one-shot grows only through `/prototype`'s grow step, which copies it into the
project root and leaves `prototypes/<name>/` untouched.


## Rule: scene-files (applies to: `**/*.tscn`, `**/*.tres`, `**/*.unity`, `**/*.prefab`, `Assets/**/*.asset`)

# Scene and Asset File Rules

The engine's editor writes these files. A hand edit that breaks one can stop a
scene loading, or drop references without an error. Change them in the editor
when you can.

## Godot (`.tscn`, `.tres`, `.uid`)

When you edit the text by hand:

- Never change the `format=` value in the `[gd_scene]` or `[gd_resource]` header.
- Never reuse an `id`: every `[ext_resource]` and `[sub_resource]` id is unique in its file.
- Never copy a node block with its `unique_id=` (Godot 4.6+). Drop it from the copy.
- Never invent a `uid://` value. Leave `uid=` off a new reference and let the
  editor or `godot --headless --path . --import` assign it.
- Never hand-edit TileMapLayer or GridMap cell data. It is encoded, so change it in the editor.
- Never edit or delete a `.uid` file, and commit it with its script or shader.
  Godot 4.4+ writes one beside each; when you move or rename the script or
  shader outside the editor, move its `.uid` with it.
- After a hand edit, run `godot --headless --path . --import` and open or run
  the scene once to confirm it loads without errors.

## Unity (`.unity`, `.prefab`, `.asset`)

- Never hand-edit `.unity`, `.prefab` or `.asset` YAML while a Unity Editor is
  reachable: open on this project, or reachable through its command-line or MCP
  tools. The Editor holds its own copy, and its next save can overwrite or
  conflict with the edit. Make the change through the Editor, or hand the user
  the steps. If you cannot tell whether an Editor is reachable, treat it as reachable.
- With no Editor reachable, keep every `fileID` and `guid` reference intact,
  never invent a GUID, never edit or delete a `.meta` file, and open the scene
  in the Editor afterwards to confirm it loads.


## Rule: shader-code (applies to: `assets/shaders/**`, `**/*.gdshader`, `Assets/**/*.{shader,hlsl,cginc,compute,shadergraph}`, `Shaders/**`, `**/*.{usf,ush}`)

# Shader Code Standards

All shader files, in every engine, must follow these standards to maintain
visual quality, performance, and cross-platform compatibility.

## Naming Conventions
- File naming: `[type]_[category]_[name].[ext]`
  - `spatial_env_water.gdshader` (Godot)
  - `SG_Env_Water` (Unity Shader Graph)
  - `M_Env_Water` (Unreal Material)
- Use descriptive names that indicate the material purpose
- Prefix with the engine's shader type — Godot `spatial_`, `canvas_`, `particles_`,
  `post_`; Unity `SG_` (Shader Graph); Unreal `M_`, `MI_` (instance), `MF_` (function)

## Code Quality
- All uniforms/parameters must have descriptive names and appropriate hints
- Group related parameters (Godot: `group_uniforms`, Unity: `[Header]`, Unreal: Category)
- Comment non-obvious calculations (especially math-heavy sections)
- No magic numbers — use named constants or documented uniform values
- Include authorship and purpose comment at the top of each shader file

## Performance Requirements
- Document the target platform and complexity budget for each shader
- Use appropriate precision: `half`/`mediump` on mobile where full precision isn't needed
- Minimize texture samples in fragment shaders
- Avoid dynamic branching in fragment shaders — use `step()`, `smoothstep()` and
  `mix()` (Godot, GLSL) or `lerp()` (HLSL: Unity, Unreal)
- No texture reads inside loops
- Two-pass approach for blur effects (horizontal then vertical)

## Cross-Platform
- Test shaders on minimum spec target hardware
- Provide fallback/simplified versions for lower quality tiers
- Document which render pipeline the shader targets (Forward/Deferred, URP/HDRP, Forward+/Mobile/Compatibility)
- Do not mix shaders from different render pipelines in the same directory

## Variant Management
- Minimize shader variants — each variant is a separate compiled shader
- Document all keywords/variants and their purpose
- Use feature stripping where possible to reduce build size
- Log and monitor total variant count per shader


## Rule: skill-authoring (applies to: `.claude/skills/**`, `.claude/agents/**`)

# Skill and Gate Authoring

**A check that cannot report that it did not run is not a check.**

The same shape recurs across unrelated subsystems, so treat it as the default
risk in any check you write, not as an unusual mistake.

The failure is always the same trade: a step that could not run produces output
indistinguishable from a step that ran and found nothing. Nobody reading the
output can tell which happened, and the permissive reading is the one that gets
believed, because it is the one that lets work proceed.

## The five obligations

### 1. Every gating verdict needs a "could not assess" value

If a skill emits a verdict something else depends on, its vocabulary must include
one — `NOT ASSESSED`, or the local equivalent — and the report must say *which*
of the reasons applied. A vocabulary of three confident verdicts forces every
unknown into a claim.

**Rank it deliberately.** It must outrank the pass value: a run that could not
assess part of its scope has not established that the scope is good. It must
**not** outrank the failure values: a known problem is more actionable than an
unknown, and demoting a real failure behind an access problem buries it.

**`NOT ASSESSED` is not a gentler failure verdict.** "I looked and found nothing"
and "I could not look" have different fixes — one needs work done, the other
needs access granted or an input classified. Collapsing them sends the reader to
the wrong fix.

### 2. An absent value may not default to the permissive one

Especially when **nothing in the framework writes that key**. Before defaulting,
check who sets it: a key with a reader and no writer takes its default branch on
every project that ever runs, so that branch is not an edge case — it is the
behaviour.

Over-running a check costs minutes. Under-running one ships the category unrun.

### 3. A skipped step announces itself

In the output, not only in the source. If a phase, category, or agent did not run
— wrong engine, missing config, unavailable input, a `team.size` that collapses
the pipeline — the artifact must say so by name. A silent skip and a successful
one are the same artifact.

A rule enforced in the body and never surfaced in the output is, to the reader,
identical to no rule at all.

### 4. Never assert what you cannot source — and wire the gap to the verdict

Where the project pins external facts (`docs/engine-reference/**`), do not fill a
gap from training data. Write the gap down instead: `NOT SOURCEABLE — <what> is
not covered by <path>`.

**Flagging alone is not enough.** A named gap that does not reach the verdict is
just a comment. Wire it: a category with no sourced inputs must force obligation
1's value, so the gap makes the pass unreachable rather than sitting beside it.

A confidently wrong pattern list is worse than an absent one — it produces a scan
that looks thorough, finds nothing, and reads as a pass.

### 5. Gates derive their covered set; they do not enumerate it

An allowlist pins what was known when it was written and is silent about
everything added since. Derive the set from what the repo actually contains, so a
new skill or agent cannot ship outside coverage by simply not being on a list.

**If the category is not mechanically crisp, say so in the gate and keep the
list.** A gate that fires on forty files does not get fixed, it gets muted — and
a muted gate is worse than a narrow one, because it reads as coverage. When you
keep a list, record *why* derivation failed and state the obligation to extend it.

Two further gate rules:

- **Assert something that cannot be true by accident.** A check for the word
  "unity" is satisfied by a file path, and case-insensitively by "community".
  Assert a distinctive token instead.
- **A gate you have not watched fail is not a gate.** Break the thing it guards,
  confirm it fails, then restore it.

## The test to apply

Before shipping a skill or gate, ask: **if this step silently did not run, what
would the output look like?**

If the answer is "the same", it is not finished.


## Rule: test-standards (applies to: `tests/**`, `Assets/Tests/**/*.cs`, `Source/**/Tests/**/*.{h,cpp}`)

# Test Standards

- Test naming follows the engine's language — every name says the scenario and
  the expected result:
  - **Godot (gdUnit4):** file `[system]_[feature]_test.gd`, function
    `test_[scenario]_[expected]`
  - **Unity (NUnit):** class `[System]Tests` in a file of the same name, method
    `[Scenario]_[Expected]` in PascalCase
  - **Unreal (Automation):** class `F[System][Scenario]Test` — one per test:
    each `IMPLEMENT_SIMPLE_AUTOMATION_TEST` defines its class, so a second test
    reusing a name fails to link — test name
    `<Project>.[System].[Scenario]` — the project's test command,
    `Automation RunTests <Project>.`, runs every test whose name contains
    `<Project>.` (a substring match, not a prefix). `<Project>.` is the root
    that filter in `commands.test` uses: the project name, or the distinct root
    `/setup-engine` chose when the project's name is also an engine area
    (`Audio`, `Core`, `Input`, …) — name tests under whichever it is
  - **Web (Vitest, Playwright):** file `[module].test.ts` under `tests/unit/`
    (Vitest) or `[system].spec.ts` under `tests/integration/` (Playwright),
    test `'[scenario] [expected]'` in plain words —
    `it('keeps the square inside the field')`
- Every test must have a clear arrange/act/assert structure
- Unit tests must not depend on external state (filesystem, network, database)
- Integration tests must clean up after themselves
- Performance tests must specify acceptable thresholds and fail if exceeded
- Test data must be defined in the test or in dedicated fixtures, never shared mutable state
- Mock external dependencies — tests should be fast and deterministic
- Every bug fix must have a regression test that would have caught the original bug —
  and **you must watch it fail before you trust it.** Run the new test against the
  unfixed code, confirm it fails, then apply the fix and confirm it passes. A
  regression test that has only ever been seen passing is not known to test anything.

  > This is `.claude/rules/skill-authoring.md`'s "a gate you have not watched fail
  > is not a gate", applied to tests. It is written out here because stating the
  > *goal* is not enough. A regression test for an iteration-order defect can use
  > a fixture where no cell takes part in two transfers per tick — it then passes
  > against the very bug it was written for, and looks authoritative doing it. The
  > fixture, not the assertion, is what makes it useless, and only running it
  > against the unfixed code exposes that.

## Examples

**Correct** (proper naming + Arrange/Act/Assert) — Godot, gdUnit4:

```gdscript
extends GdUnitTestSuite

func test_take_damage_reduces_health() -> void:
    # Arrange — auto_free: a Node left alive is an orphan (gdUnit4 exit 101)
    var health: HealthComponent = auto_free(HealthComponent.new())
    health.max_health = 100
    health.current_health = 100

    # Act
    health.take_damage(25)

    # Assert
    assert_int(health.current_health).is_equal(75)
```

Unity, NUnit (`Assets/Tests/EditMode/HealthTests.cs`):

```csharp
using NUnit.Framework;

public class HealthTests
{
    [Test]
    public void TakeDamage_ReducesHealth()
    {
        // Arrange
        var health = new Health(maxHealth: 100);

        // Act
        health.TakeDamage(25);

        // Assert
        Assert.AreEqual(75, health.Current);
    }
}
```

Unreal, Automation (`Source/<Module>/Private/Tests/HealthTest.cpp`):

```cpp
#include "Misc/AutomationTest.h"

#if WITH_DEV_AUTOMATION_TESTS

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FHealthTakeDamageTest, "<Project>.Health.TakeDamageReducesHealth",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::ProductFilter)

bool FHealthTakeDamageTest::RunTest(const FString& Parameters)
{
    // Arrange
    FHealthPool Health(100);

    // Act
    Health.TakeDamage(25);

    // Assert
    TestEqual(TEXT("health after 25 damage"), Health.GetCurrent(), 75);
    return true;
}

#endif
```

**Incorrect**:

```gdscript
func test1() -> void:  # VIOLATION: no descriptive name
    var h := HealthComponent.new()
    h.take_damage(25)  # VIOLATION: no arrange step, no clear assert
    assert_bool(h.current_health < 100).is_true()  # VIOLATION: imprecise assertion
```


## Rule: ui-code (applies to: `src/ui/**`, `Assets/**/{UI,Ui,ui}/**/*.cs`, `Source/**/{UI,Ui,ui}/**/*.{h,cpp}`)

# UI Code Rules

- UI must NEVER own or directly modify game state — display only, use commands/events to request changes
- All UI text must go through the localization system — no hardcoded user-facing strings
- Support both keyboard/mouse AND gamepad input for all interactive elements
- All animations must be skippable and respect user motion/accessibility preferences
- UI sounds trigger through the audio event system, not directly
- UI must never block the game thread
- Scalable text and colorblind modes are mandatory, not optional
- Test all screens at minimum and maximum supported resolutions
