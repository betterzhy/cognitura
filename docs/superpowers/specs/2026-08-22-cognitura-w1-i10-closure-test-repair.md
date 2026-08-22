# W1-I10 Closure Test Repair

The fixed RED test commit correctly proved that the old verifier had no I10
closure route, but its rename negative used the post-rename exact projection
path list for staging. Git rejected the now-missing `README.md` path before the
production rename/copy guard could run.

Preserve the original RED commit. Append this single repair specification,
then one test-only commit that stages the rename fixture with `git add -A`.
The final verifier follows directly. The resulting fixed governance sequence is
therefore `spec -> RED test -> repair spec -> repaired test -> verifier`.

All other W1-I10 closure authority remains unchanged. The repaired test blob is
fixed evidence, product bytes remain frozen, and database writes, deployment,
push, I12 release, and any generic Harness remain unauthorized.
