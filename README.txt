2026-04-13 14:26 +08:00
- Focused on `/home/roger/WorkSpace/youtube-post-worker` after confirming there is no `youtube-post-watcher` repo in `WorkSpace`.
- Read `README.md`, `HANDOFF.md`, and `plan.md`.
- Verified baseline with `python3 -m unittest discover -s tests -v`: 5 tests passed before changes.
- Fixed safety issues:
- restricted live fetches to HTTPS YouTube community URLs only
- blocked obvious unsafe media download targets and added a 10 MiB download cap
- escaped scheduler installer values for cron and systemd generation
- added regression tests for invalid fetch targets and unsafe media URLs
- Re-ran `python3 -m unittest discover -s tests -v`: 10 tests passed.

2026-04-13 14:34 +08:00
- Rewrote `youtube-post-worker/README.md` into Chinese-oriented documentation.
- Expanded the usage section in Chinese with command-by-command explanations, expected behavior, and testing examples.
- Updated `youtube-post-worker/plan.md` to Chinese and synced milestone status with the latest safety hardening work.
- Updated `youtube-post-worker/HANDOFF.md` to Chinese and synchronized current status, risks, and resume commands.

2026-04-16 23:42 +08:00
- Focused on `/home/roger/WorkSpace/youtube-post-worker` and treated it as the active repo for this round.
- Confirmed repo status is clean on `main...origin/main`.
- Re-ran `python3 -m unittest discover -s /home/roger/WorkSpace/youtube-post-worker/tests -v`: 10 tests passed.
- Re-checked current safety posture:
- no obvious secrets or private keys found in tracked project files
- fetch path still rejects non-HTTPS, non-YouTube, and non-community URLs
- media downloader still blocks local/private targets and enforces a size cap
- confirmed the earlier `mock_file` compatibility gap is already fixed in `worker/cli.py`
- Did not modify `youtube-post-worker` in this round; only recorded focus and verification status here.

2026-04-16 23:49 +08:00
- Unified `/home/roger/WorkSpace/youtube-post-worker` remote URLs to SSH for both fetch and push.
- Created Git milestone tag `phase1-worker-hardened` at commit `2acb0f6`.
- This tag marks the repo after Phase 1 core worker capabilities, fetch-failure debug capture, and safety hardening were all in place, while `M7` validation/release hardening remains in progress.

2026-04-17 00:11 +08:00
- Updated `/home/roger/.codex/config.toml` to change global `sandbox_mode` from `workspace-write` to `danger-full-access`.
- Kept `approval_policy = "never"` unchanged.
- This affects new Codex sessions only; the current session still keeps its existing runtime sandbox state until restarted.

2026-04-17 00:35 +08:00
- Re-focused on `/home/roger/WorkSpace/youtube-post-worker` and treated it as the active repo context for this note.
- Recorded an operational finding for future runs: some command line behavior only takes effect when Codex is launched with `--dangerously-bypass-approvals-and-sandbox`.
- The symptom is easy to misread as a broken command, but the real cause is approval/sandbox enforcement in the normal launch mode.
- Usage note: this flag bypasses both approvals and sandbox protections, so it should be treated as a controlled troubleshooting or fully trusted-environment option.

2026-04-17 00:46 +08:00
- Added `/home/roger/WorkSpace/youtube-post-worker/AGENTS.md` so future work starts by checking `README.md`, `plan.md`, and `HANDOFF.md`.
- Synced repo docs after review: updated `README.md`, `HANDOFF.md`, and `plan.md` to reflect the current downloader safety boundary, including hostname-to-private-IP DNS resolution blocking.
- Corrected stale handoff status: the handoff now warns that the working tree may not be clean and that the current unit test count is 11 rather than 10.
- Continued using `/home/roger/WorkSpace/AI_Agent_minipc_log` as the session log target for `youtube-post-worker`.

2026-04-17 00:56 +08:00
- Continued focused development on `/home/roger/WorkSpace/youtube-post-worker` to close out `M7: Phase 1 release hardening`.
- Hardened `worker/downloader.py` further: added `image/*` content-type validation plus limited retry handling for transient download failures.
- Hardened `worker/parser.py` to report a specific error when YouTube returns a community-unavailable empty-state page instead of post data.
- Added regression coverage in `tests/test_safety.py` and `tests/test_parser.py`; full suite now passes with 14 tests.
- Live validation results:
- `https://www.youtube.com/@yutinghaofinance/community` still parses and emits 11 new posts on a fresh state DB.
- `https://www.youtube.com/channel/UC0lbAQVpenvfA2QqzsRtL_g/community` also parses to the same 11 posts.
- `run --download-media` successfully wrote 11 payload files and 11 local media files under `/tmp/youtube-post-worker-m7-media-fresh/`.
- Scheduler validation found a real portability bug: local `systemd-escape` does not support `--quote`, so `scripts/install_systemd.sh` was updated to use portable unit-safe escaping instead.

2026-04-17 21:00 +08:00
- Performed a deeper review of `/home/roger/WorkSpace/youtube-post-worker`, focusing on sender integration, fetch/downloader/scheduler safety boundaries, and current test coverage.
- Confirmed the full `youtube-post-worker` test suite passed with 18 tests after sender-related changes.
- Identified two concrete issues in the sender path:
- sender integration lacked dedicated tests
- partial delivery could resend already delivered posts on the next `run`
- Corrected this by adding a SQLite delivery journal and changing the CLI flow so new posts are persisted first, then only still-undelivered sender items are retried, with each successful delivery recorded immediately.
- Added sender/state/CLI regression tests covering sender config parsing, n8n webhook URL validation, and partial-delivery retry behavior.
- Updated `youtube-post-worker/.env.example` and `README.md` so sender usage matches the actual CLI behavior.
- Committed `d08f384 Add reliable sender delivery tracking` and tagged that state as `phase2-sender-reliable`.
- Replaced the previous untracked repo-root helper intent with a tracked `run.sh` wrapper, documented its usage, and verified:
- `bash -n run.sh scripts/run_once.sh scripts/install_cron.sh scripts/install_systemd.sh`
- No new concrete safety findings were introduced in this pass; remaining risks were still the known parser fragility and synchronous sender design.
- Opened `youtube-post-worker` draft PR `#5`: `[codex] Add reliable sender delivery tracking and root run helper`.
