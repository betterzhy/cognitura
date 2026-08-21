# Cognitura W1-I02 Database Gate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish the minimal, isolated PostgreSQL 18.4 admission Gate that fixes the W1-I02 physical Schema decision and releases only W1-I02 for implementation.

**Architecture:** Extend the existing append-only Wave 1 governance verifier with one fixed four-commit Gate chain rooted at the reviewed I06 closure correction. A focused Bash 3.2 contract exercises the real Git transition rules and launches a temporary Java probe that uses the Repository's Testcontainers dependency; after one fixed-candidate xhigh review, an exact ten-path receipt projection changes the task set from database-blocked to one READY card without authorizing a formal database or W1-I07.

**Tech Stack:** Bash 3.2, Git plumbing, Maven 3.9.16, JDK 21, Testcontainers 2.0.5, PostgreSQL 18.4, existing Markdown authority projections.

**Spec:** `docs/superpowers/specs/2026-08-21-cognitura-w1-i02-database-gate-design.md`

## Global Constraints

- `GateOriginSHA = 8175f340c4f3d116a7aa5bc1f6ee5f67b489dee6`.
- `PostgreSQLTestImage = postgres:18.4@sha256:3a82e1f56c8f0f5616a11103ac3d47e632c3938698946a7ad26da0df1334744a`.
- The database probe must use an invocation-owned Testcontainers instance, `withReuse(false)`, generated credentials and no host database URL or credentials.
- The Gate must record container identity, image identity, PostgreSQL server version, generated database name and proven removal; it must never print a password.
- The Gate does not execute `V1__create_source_intake.sql`; migration and persistence behavior belong to the later W1-I02 RED -> GREEN cycle.
- Before release the set remains `BLOCKED_BY_DATABASE_GATE`, I02 remains `QUEUED`, Active is `NONE`, and Ready count is `0`.
- The release projection changes exactly ten authority paths and releases only W1-I02.
- `FormalDatabaseWrite = NOT_AUTHORIZED`, `RemotePush = NOT_AUTHORIZED`, and W1-I07 remains `BLOCKED_BY_DEPENDENCY` throughout.
- Do not read or modify `raw/**` or `.idea/**`. Preserve unrelated worktree state. Do not reset, amend, rewrite, deploy or push.
- All governance commits are single-parent, nonempty, NUL-free, rename/copy-free, mode-stable and append-only.
- The final Gate uses one `deep_reviewer / gpt-5.6-sol / xhigh` review. Ultra is not run.

---

## File responsibility map

| Path | Responsibility |
|---|---|
| `docs/superpowers/specs/2026-08-21-cognitura-w1-i02-database-gate-design.md` | Fixed physical Schema and isolation authority; already committed as `97504c2` and must remain byte-identical. |
| `docs/superpowers/plans/2026-08-21-cognitura-w1-i02-database-gate.md` | This executable plan; the second fixed Gate-chain commit. |
| `tests/task-cards/verify-wave1-implementation-cards.sh` | Bash 3.2 focused real-Git contract, Testcontainers lifecycle probe, release positives and stable negative matrix. |
| `scripts/verify-wave1-implementation-cards` | Production static/transition verifier for the fixed Gate chain, review receipt, exact release projection and I02 descendants. |
| Ten release projection files listed in Task 5 | Atomic authoritative state transition from database-blocked to I02 READY. |

### Task 1: Fix the executable Gate plan

**Files:**
- Create: `docs/superpowers/plans/2026-08-21-cognitura-w1-i02-database-gate.md`
- Read: `docs/superpowers/specs/2026-08-21-cognitura-w1-i02-database-gate-design.md`

**Interfaces:**
- Consumes: fixed design commit `97504c2` whose parent is `8175f34`.
- Produces: a single-path plan commit whose full SHA is bound by Tasks 2 and 3.

- [ ] **Step 1: Verify the design identity and clean scope**

Run:

```bash
git rev-parse HEAD HEAD^ 'HEAD^{tree}'
git diff-tree --no-commit-id --name-status -r HEAD
git status --short
```

Expected: HEAD is `97504c2...`; the commit contains only the design spec; `.idea/` is the only unrelated untracked path.

- [ ] **Step 2: Self-review the plan against all seven design sections**

Run:

```bash
rg -n 'GateOriginSHA|PostgreSQLTestImage|Testcontainers|PENDING_REVIEW|deep_reviewer|W1-I07|FormalDatabaseWrite|RemotePush' \
  docs/superpowers/plans/2026-08-21-cognitura-w1-i02-database-gate.md
rg -n 'T[B]D|T[O]DO|implement la[t]er|fill i[n]|Similar to Tas[k]|appropriate error handlin[g]|write tests fo[r]' \
  docs/superpowers/plans/2026-08-21-cognitura-w1-i02-database-gate.md && exit 1 || true
git diff --check
```

Expected: every authority token is present; the placeholder scan prints nothing; `git diff --check` exits 0.

- [ ] **Step 3: Commit only the plan**

```bash
git add docs/superpowers/plans/2026-08-21-cognitura-w1-i02-database-gate.md
git diff --cached --name-status
git commit -m "docs: plan W1-I02 database gate"
```

Expected: one `A` path, mode `100644`, no other staged path.

### Task 2: Define the focused Gate contract (RED)

**Files:**
- Modify: `tests/task-cards/verify-wave1-implementation-cards.sh`
- Test: `tests/task-cards/verify-wave1-implementation-cards.sh`

**Interfaces:**
- Consumes: `gate_origin_sha`, design SHA `97504c2...`, the Task 1 plan SHA, existing `fail`, `assert_contains`, `set_field`, `set_table_status`, shared-clone and transition helpers.
- Produces: `--w1-i02-database-gate-contract-only`, `run_w1_i02_database_gate_contract`, `run_w1_i02_isolated_postgres_probe`, and stable `W1_I02_DATABASE_GATE_*` diagnostics expected from the production verifier.

- [ ] **Step 1: Add the focused CLI flag**

Add next to the existing I06 flags and dispatch:

```bash
w1_i02_database_gate_contract_only=0

--w1-i02-database-gate-contract-only)
  w1_i02_database_gate_contract_only=1
  ;;
```

Before the ordinary full suite, dispatch exactly:

```bash
if [[ "${w1_i02_database_gate_contract_only}" == 1 ]]; then
  run_w1_i02_database_gate_contract
  exit 0
fi
```

The full suite must also call `run_w1_i02_database_gate_contract` once.

- [ ] **Step 2: Add fixed identities and exact path arrays**

Immediately after Task 1, run `git rev-parse HEAD` and copy that printed 40-character value as the
literal `w1_i02_database_gate_plan_sha`; do not use a short SHA or compute it at test runtime.

```bash
w1_i02_database_gate_origin_sha="8175f340c4f3d116a7aa5bc1f6ee5f67b489dee6"
w1_i02_database_gate_design_sha="97504c281b61f6d15ca347c1e0d0369e44819110"
w1_i02_postgres_image="postgres:18.4@sha256:3a82e1f56c8f0f5616a11103ac3d47e632c3938698946a7ad26da0df1334744a"
w1_i02_database_gate_paths=(
  docs/superpowers/specs/2026-08-21-cognitura-w1-i02-database-gate-design.md
  docs/superpowers/plans/2026-08-21-cognitura-w1-i02-database-gate.md
  tests/task-cards/verify-wave1-implementation-cards.sh
  scripts/verify-wave1-implementation-cards
)
w1_i02_release_projection_paths=(
  AGENTS.md
  README.md
  docs/design/wave-1/README.md
  docs/engineering/cognitura-design-index.md
  docs/engineering/cognitura-wave-1-design-plan.md
  docs/engineering/cognitura-wave-1-design-acceptance.md
  docs/engineering/cognitura-wave-1-implementation-plan.md
  docs/task-cards/wave-1/README.md
  docs/task-cards/wave-1-implementation/README.md
  docs/task-cards/wave-1-implementation/W1-I02-source-persistence.md
)
```

Add `w1_i02_database_gate_plan_sha` immediately below the design SHA with the literal output captured
after Task 1. Assert both values with `git cat-file -e "${sha}^{commit}"` before building fixtures.

- [ ] **Step 3: Implement the invocation-owned Testcontainers probe**

`run_w1_i02_isolated_postgres_probe` must first reject every nonempty host input:

```bash
for variable_name in SPRING_DATASOURCE_URL JDBC_DATABASE_URL DATABASE_URL PGHOST PGPORT PGUSER PGPASSWORD; do
  variable_value="$(printenv "${variable_name}" 2>/dev/null || true)"
  [[ -z "${variable_value}" ]] || fail "W1_I02_DATABASE_GATE_HOST_DB_INPUT_FORBIDDEN:${variable_name}"
done
```

Build the test classpath into the existing test temporary root, then pass the Java probe directly to
JShell so the probe creates no source file:

```bash
probe_classpath_file="${test_tmp_root}/w1-i02-database-gate-classpath.txt"
./mvnw -q -f server/pom.xml test-compile dependency:build-classpath \
  -Dmdep.includeScope=test \
  -Dmdep.outputFile="${probe_classpath_file}"
probe_classpath="${repo_root}/server/target/test-classes:${repo_root}/server/target/classes:$(cat "${probe_classpath_file}")"
probe_output="$(jshell -q --class-path "${probe_classpath}" <<'JAVA'
// Java snippets below, followed by W1I02DatabaseGateProbe.main(new String[0]);
JAVA
)" || fail "W1_I02_DATABASE_GATE_PROBE_FAILED"
```

The JShell body is the following class definition and invocation:

```java
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.UUID;
import org.testcontainers.DockerClientFactory;
import org.testcontainers.postgresql.PostgreSQLContainer;
import org.testcontainers.utility.DockerImageName;

public final class W1I02DatabaseGateProbe {
  private static final String IMAGE =
      "postgres:18.4@sha256:3a82e1f56c8f0f5616a11103ac3d47e632c3938698946a7ad26da0df1334744a";

  public static void main(String[] args) throws Exception {
    String database = "cognitura_gate_" + UUID.randomUUID().toString().replace("-", "");
    String username = "gate_" + UUID.randomUUID().toString().replace("-", "");
    String password = UUID.randomUUID().toString() + UUID.randomUUID();
    String containerId;
    String imageId;
    String version;
    try (PostgreSQLContainer container = new PostgreSQLContainer(DockerImageName.parse(IMAGE))
        .withDatabaseName(database)
        .withUsername(username)
        .withPassword(password)
        .withReuse(false)) {
      container.start();
      containerId = container.getContainerId();
      var inspect = DockerClientFactory.instance().client()
          .inspectContainerCmd(containerId).exec();
      imageId = inspect.getImageId();
      try (Connection connection = DriverManager.getConnection(
               container.getJdbcUrl(), container.getUsername(), container.getPassword());
           Statement statement = connection.createStatement();
           ResultSet result = statement.executeQuery(
               "select current_setting('server_version_num'), current_database()")) {
        if (!result.next()) throw new IllegalStateException("version query returned no row");
        version = result.getString(1);
        if (!version.startsWith("18")) {
          throw new IllegalStateException("unexpected PostgreSQL major: " + version);
        }
        if (!database.equals(result.getString(2))) {
          throw new IllegalStateException("unexpected database identity");
        }
      }
      System.out.println("W1I02DatabaseGateContainerId = " + containerId);
      System.out.println("W1I02DatabaseGateImage = " + IMAGE);
      System.out.println("W1I02DatabaseGateImageId = " + imageId);
      System.out.println("W1I02DatabaseGateServerVersionNum = " + version);
      System.out.println("W1I02DatabaseGateDatabaseName = " + database);
    }
    try {
      DockerClientFactory.instance().client().inspectContainerCmd(containerId).exec();
      throw new IllegalStateException("container remains inspectable after close");
    } catch (com.github.dockerjava.api.exception.NotFoundException expected) {
      System.out.println("W1I02DatabaseGateContainerRemoval = PASS");
    }
  }
}
W1I02DatabaseGateProbe.main(new String[0]);
```

Assert all six public fields from `probe_output`. The Java code exposes no password field, and the
Bash function must not enable `set -x`, print the process environment or echo JShell input.

- [ ] **Step 4: Build real-Git positive fixtures**

Create a shared clone at the fixed origin, then materialize the fixed design and plan commits with
`git show "${commit_sha}:${path}"`, preserve modes and make one single-path commit per step. The test
commit and verifier candidate are materialized from the current Repository into the fixture as the
third and fourth single-path commits.

Positive assertions:

```text
1. exact four-path governance tip => PASS, TaskCardSetStatus=BLOCKED_BY_DATABASE_GATE,
   ActiveTaskCard=NONE, ReadyTaskCardCount=0, W1I02DatabaseGateStatus=PENDING_REVIEW
2. isolated PostgreSQL probe => container/image/version/database/removal evidence, exit 0
3. direct exact-ten-path admission receipt => W1I02DatabaseGateStatus=PASS,
   TaskCardSetStatus=READY_FOR_EXECUTION, ActiveTaskCard=W1-I02
4. static admission state => exactly one READY card, W1-I02
```

The admission fixture receipt must use the fixed candidate identity supplied by the test and must append this exact terminal block to the implementation plan:

```text
## 12. I02 Database Gate Admission Receipt

W1-I02DatabaseGate = PASS
ReviewedGateCandidate = ${candidate_sha}
ReviewedGateParent = ${parent_sha}
ReviewedGateTree = ${tree_sha}
ReviewLevel = L3
ReviewRoute = deep_reviewer
ReviewEffort = xhigh
ReviewMultiplicity = ONE
ReviewVerdict = GO
P0Findings = 0
P1Findings = 0
P2Findings = 0
Ultra = NOT_RUN
PostgreSQLTestImage = postgres:18.4@sha256:3a82e1f56c8f0f5616a11103ac3d47e632c3938698946a7ad26da0df1334744a
ExpectedPostgreSQLMajor = 18
IsolatedContainerLifecycle = PASS
ReleasedTaskCard = W1-I02
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

- [ ] **Step 5: Add the exact negative matrix**

Each mutation starts again from an immutable base and must assert the named diagnostic:

```text
1. host DB input                         W1_I02_DATABASE_GATE_HOST_DB_INPUT_FORBIDDEN
2. wrong/unpinned image                  W1_I02_DATABASE_GATE_IMAGE_MISMATCH
3. missing removal proof                 W1_I02_DATABASE_GATE_REMOVAL_REQUIRED
4. governance merge/empty/order/path     W1_I02_DATABASE_GATE_CHAIN_INVALID
5. governance mode/rename/copy/NUL        W1_I02_DATABASE_GATE_CHANGE_INVALID
6. wrong Candidate/Parent/Tree            W1_I02_DATABASE_GATE_REVIEW_IDENTITY_MISMATCH
7. nonzero finding/Ultra/nonterminal      W1_I02_DATABASE_GATE_REVIEW_RECEIPT_INVALID
8. missing/extra/non-direct projection    W1_I02_DATABASE_GATE_RELEASE_PROJECTION_INVALID
9. I02 auth or DB Gate not PASS           I02_READY_REQUIRES_DATABASE_GATE
10. I07 or second READY                   W1_I02_DATABASE_GATE_RELEASE_SCOPE_INVALID
11. I02 product changed during release    W1_I02_DATABASE_GATE_RELEASE_PROJECTION_INVALID
12. DB write/deploy/push drift             W1_I02_DATABASE_GATE_AUTHORIZATION_DRIFT
13. descendant outside allowed phase path W1_I02_DATABASE_GATE_DESCENDANT_OUTSIDE_WRITE_SET
```

For Git change detection use `git -c diff.renameLimit=0 diff-tree --no-commit-id --name-status -r -M -C --find-copies-harder`; reject every `R*` and `C*`. Do not make similarity scores part of a legal exception.

- [ ] **Step 6: Run RED and commit the test only**

```bash
bash -n tests/task-cards/verify-wave1-implementation-cards.sh
bash tests/task-cards/verify-wave1-implementation-cards.sh \
  --w1-i02-database-gate-contract-only
```

Expected: syntax exits 0; focused contract exits nonzero because the production verifier still rejects the first Gate successor after `8175f34`. Preserve the RED exit and diagnostic in the execution log.

```bash
git add tests/task-cards/verify-wave1-implementation-cards.sh
git diff --cached --name-status
git commit -m "test: define W1-I02 database gate contract"
```

Expected: exactly one modified executable test path.

### Task 3: Admit the fixed Gate chain in the production verifier (GREEN)

**Files:**
- Modify: `scripts/verify-wave1-implementation-cards`
- Test: `tests/task-cards/verify-wave1-implementation-cards.sh`

**Interfaces:**
- Consumes: fixed origin/design/plan/test full SHAs and the diagnostic/output vocabulary from Task 2.
- Produces: `validate_w1_i02_database_gate_governance`, `require_w1_i02_database_gate_review_receipt`, `validate_w1_i02_database_gate_release`, and phase-specific descendant validation.

- [ ] **Step 1: Add fixed constants and paths**

Copy the exact full SHA/path values from Task 2. Add the test commit full SHA after the RED commit. Add exactly the ten release paths and eight I02 product paths from the I02 card. Do not derive a fixed identity from current HEAD.

- [ ] **Step 2: Validate the four-commit Gate governance chain**

Implement `validate_w1_i02_database_gate_governance()` with one positional `gate_tip` argument and
these checks in order:

```text
commit 1 parent=8175f34... path=design spec mode=100644 sha=97504c2...
commit 2 parent=commit1      path=plan        mode=100644 sha=literal captured after Task 1
commit 3 parent=commit2      path=test        mode=100755 sha=literal captured after Task 2
commit 4 parent=commit3      path=verifier    mode=100755 candidate supplied by route
```

For each commit call existing single-parent, nonempty, no-NUL, path/mode and strict no-rename/copy helpers. Freeze the I06 reviewed product, I06 receipt projection and `8175f34` correction bytes. Reject any commit between the fixed steps or any extra path.

- [ ] **Step 3: Parse the terminal review receipt strictly**

Implement `require_w1_i02_database_gate_review_receipt()` with positional arguments `plan_path`,
`candidate`, `parent`, and `tree`. Compare the terminal block byte-for-byte against the block in
Task 2 after expanding only those three shell variables. Require exactly one heading and EOF
immediately after `RemotePush = NOT_AUTHORIZED`. Reject Ultra values other than `NOT_RUN` and any
nonzero P0/P1/P2.

- [ ] **Step 4: Validate the exact release transition**

Implement `validate_w1_i02_database_gate_release()` with positional arguments `receipt_sha` and
`gate_tip`:

```text
- receipt parent equals gate tip
- receipt is single-parent, nonempty, NUL-free, mode-stable and has no rename/copy
- changed paths equal the ten release paths as a sorted set, with no I02 product path
- every fixed candidate identity in the receipt equals gate tip/parent/tree
- all ten status projections agree
- I02 is READY, business authorization USER_AUTHORIZED, FormalDatabaseGate PASS
- I06 is DONE; I07..I13 remain BLOCKED_BY_DEPENDENCY
- ActiveTaskCard W1-I02 and ReadyTaskCardCount 1 everywhere
- FormalDatabaseWrite and RemotePush remain NOT_AUTHORIZED
```

Print only after success:

```text
W1I02DatabaseGateStatus = PASS
TaskCardSetStatus = READY_FOR_EXECUTION
ActiveTaskCard = W1-I02
ReadyTaskCardCount = 1
```

- [ ] **Step 5: Replace the one-correction terminal route with phase routing**

Retain validation of the existing `8175f34` correction, then route its descendants as follows:

```text
8175f34 itself                         existing database-blocked state
fixed Gate chain through verifier tip database-blocked + PENDING_REVIEW
direct exact release receipt          READY_FOR_EXECUTION + PASS
post-release commits                  only exact W1-I02 WriteSet paths
```

Before the receipt, any non-fixed descendant is rejected. After the receipt, call the existing exact I02 descendant predicate; never allow governance or release paths to change again. Do not release I07 or treat formal DB access as allowed.

- [ ] **Step 6: Run GREEN and the complete Wave gate**

```bash
bash -n scripts/verify-wave1-implementation-cards
bash tests/task-cards/verify-wave1-implementation-cards.sh \
  --w1-i02-database-gate-contract-only
bash tests/task-cards/verify-wave1-implementation-cards.sh
bash scripts/verify-wave1-implementation
git diff --check
```

Expected: every command exits 0; focused output includes four positive cases and all 13 negative classes; full output reaches its final summary rather than an interrupted prefix.

- [ ] **Step 7: Commit the verifier only**

```bash
git add scripts/verify-wave1-implementation-cards
git diff --cached --name-status
git commit -m "fix: admit W1-I02 database gate"
```

Expected: exactly one modified executable verifier path.

### Task 4: Bind and independently review the Gate candidate

**Files:**
- Read: fixed four-path Gate chain
- Modify only if a finding requires an append-only RED/GREEN correction within the same two script paths.

**Interfaces:**
- Consumes: completed Task 3 gate tip and complete local verification evidence.
- Produces: fixed Candidate/Parent/Tree and one xhigh `GO` with P0/P1/P2 all zero, or a fail-closed finding remediation cycle.

- [ ] **Step 1: Capture candidate identity and invariants**

```bash
candidate_sha="$(git rev-parse HEAD)"
parent_sha="$(git rev-parse HEAD^)"
tree_sha="$(git rev-parse 'HEAD^{tree}')"
git log --format='%H %P %T %s' --reverse 8175f340c4f3d116a7aa5bc1f6ee5f67b489dee6..HEAD
git status --short
```

Expected: a single-parent four-path append-only chain, no product or release paths, and only `.idea/` unrelated/untracked.

- [ ] **Step 2: Run one fixed-candidate deep review**

Provide the reviewer the exact Candidate/Parent/Tree, design, plan, RED/GREEN evidence, focused/full exit codes and scope constraints. Review questions are:

```text
1. Can any history not rooted at 8175f34 enter the Gate route?
2. Can host DB state, a mutable image, container reuse or failed removal count as PASS?
3. Can any release omit authorization/Gate PASS or release I07/formal DB/push?
4. Can a post-release descendant modify anything outside the exact I02 WriteSet?
5. Are all Git identities, path sets, modes and receipt bytes candidate-bound?
```

Expected: `ReviewVerdict=GO`, `P0=0`, `P1=0`, `P2=0`, `Ultra=NOT_RUN`. If any finding exists, do not project release state; add a failing focused test, commit it, implement the minimal verifier fix, rerun only affected gates then the complete Gate, and review the new fixed candidate once.

### Task 5: Atomically release W1-I02

**Files:**
- Modify: `AGENTS.md`
- Modify: `README.md`
- Modify: `docs/design/wave-1/README.md`
- Modify: `docs/engineering/cognitura-design-index.md`
- Modify: `docs/engineering/cognitura-wave-1-design-plan.md`
- Modify: `docs/engineering/cognitura-wave-1-design-acceptance.md`
- Modify: `docs/engineering/cognitura-wave-1-implementation-plan.md`
- Modify: `docs/task-cards/wave-1/README.md`
- Modify: `docs/task-cards/wave-1-implementation/README.md`
- Modify: `docs/task-cards/wave-1-implementation/W1-I02-source-persistence.md`

**Interfaces:**
- Consumes: reviewed Gate Candidate/Parent/Tree and zero-finding xhigh verdict.
- Produces: one direct exact-ten-path admission receipt commit and the sole READY card W1-I02.

- [ ] **Step 1: Apply the exact state vector**

Set every projection consistently:

```text
Wave1ImplementationTaskCardSet / TaskCardSetStatus = READY_FOR_EXECUTION
ActiveImplementationTaskCard / ActiveTaskCard = W1-I02
ActiveTaskCardStatus = READY where that field exists
ReadyTaskCardCount = 1
W1-I02 Status = READY
W1-I02 BusinessImplementationAuthorization = USER_AUTHORIZED
W1-I02 FormalDatabaseGate = PASS
W1-I06 Status = DONE
W1-I07 Status = BLOCKED_BY_DEPENDENCY
FormalDatabaseWrite = NOT_AUTHORIZED
RemotePush = NOT_AUTHORIZED
```

Change narratives only enough to say the independent isolated Database Gate passed, I02 alone is released, its implementation is not complete, and I07 remains blocked. Do not change I07's card.

- [ ] **Step 2: Append the terminal receipt**

Append the exact Task 2 receipt block as the final content of `docs/engineering/cognitura-wave-1-implementation-plan.md`, substituting the reviewed Gate Candidate/Parent/Tree. Ensure the preceding I06 receipt remains byte-identical and the I02 heading occurs once.

- [ ] **Step 3: Validate explicit transition before commit**

```bash
bash scripts/verify-wave1-implementation-cards \
  --transition "$(git rev-parse HEAD)" WORKTREE
bash scripts/verify-wave1-implementation-cards
git diff --check
git diff --name-only | LC_ALL=C sort
```

Expected: explicit and static validation exit 0; the sorted diff is exactly the ten release paths; output reports I02 PASS/READY and still reports formal DB/push not authorized.

- [ ] **Step 4: Commit the direct receipt**

```bash
git add AGENTS.md README.md \
  docs/design/wave-1/README.md \
  docs/engineering/cognitura-design-index.md \
  docs/engineering/cognitura-wave-1-design-plan.md \
  docs/engineering/cognitura-wave-1-design-acceptance.md \
  docs/engineering/cognitura-wave-1-implementation-plan.md \
  docs/task-cards/wave-1/README.md \
  docs/task-cards/wave-1-implementation/README.md \
  docs/task-cards/wave-1-implementation/W1-I02-source-persistence.md
git diff --cached --name-only | LC_ALL=C sort
git commit -m "docs: release W1-I02 after database gate"
```

Expected: exactly ten paths and the receipt commit's parent is the reviewed Gate candidate.

- [ ] **Step 5: Re-run public gates on the committed receipt**

```bash
bash tests/task-cards/verify-wave1-implementation-cards.sh \
  --w1-i02-database-gate-contract-only
bash tests/task-cards/verify-wave1-implementation-cards.sh
bash scripts/verify-wave1-implementation
git status --short
```

Expected: all commands exit 0 with final summaries; `.idea/` remains the only unrelated untracked path.

### Task 6: Hand off to the separate W1-I02 product cycle

**Files:**
- Read: `docs/task-cards/wave-1-implementation/W1-I02-source-persistence.md`
- Do not modify any I02 product path in this Gate plan.

**Interfaces:**
- Consumes: committed release receipt.
- Produces: evidence that W1-I02, and only W1-I02, may begin its own eight-path RED -> GREEN implementation plan.

- [ ] **Step 1: Verify admission without claiming product completion**

```bash
rg -n '^Status = READY$|^BusinessImplementationAuthorization = USER_AUTHORIZED$|^FormalDatabaseGate = PASS$|^RemotePush = NOT_AUTHORIZED$' \
  docs/task-cards/wave-1-implementation/W1-I02-source-persistence.md
rg -n '^ActiveTaskCard = W1-I02$|^ReadyTaskCardCount = 1$|W1-I07.*BLOCKED_BY_DEPENDENCY' \
  docs/task-cards/wave-1-implementation/README.md
git status --short
```

Expected: I02 is admitted, I07 is blocked, formal DB/push remain unauthorized, and no I02 production file exists yet because implementation begins only in the next plan/cycle.

---

## Completion boundary

This plan is complete only when the Gate governance candidate has one zero-finding xhigh review and the direct ten-path receipt is committed and green. It must not report W1-I02 implementation, migration, mapper or persistence behavior as complete. The next cycle owns the exact eight-path W1-I02 RED -> GREEN implementation, isolated migration tests, fixed product candidate review and eventual card closure.
