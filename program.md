# Agentloop

This is an experiment to have the LLM do its own research.

## Setup

To set up a new experiment, work with the user to:

1. **Agree on a run tag**: propose a tag based on today's date (for example `mar25`). The branch `agentloop/<tag>` must not already exist.
2. **Create the branch**: `git checkout -b agentloop/<tag>` from current `main`.
3. **Read the in-scope files**: the repo is intentionally small. Read these files for full context:
   - `README.md`
   - `prepare.py`
   - `train.py`
   - `program.md`
4. **Verify data exists**: check that `~/.cache/autoresearch/` contains the dataset and tokenizer. If not, run `.\scripts\setup.ps1` or `uv run prepare.py`.
5. **Initialize results.tsv if needed**: if `results.tsv` does not exist yet, create it with the header row. If it already exists, append to it.
6. **Confirm and go**: confirm that setup looks healthy, then kick off the experimentation loop.

Once you get confirmation, kick off the experimentation.

## Experimentation

Each experiment runs on a single GPU. The training script runs for a **fixed time budget of 5 minutes** (wall clock training time, excluding startup and evaluation overhead). You launch it simply as:

```powershell
uv run train.py
```

**What you CAN do:**

- Modify `train.py`. This is the only file you edit during experiments. Everything inside it is fair game: architecture, optimizer, hyperparameters, training loop, batch size, model size, and so on.

**What you CANNOT do:**

- Modify `prepare.py`. It is read-only. It contains the fixed evaluation, data loading, tokenizer, and training constants.
- Install new packages or add dependencies. You can only use what is already in `pyproject.toml`.
- Modify the evaluation harness. The `evaluate_bpb` function in `prepare.py` is the ground truth metric.

**The goal is simple: get the lowest `val_bpb`.**

Since the time budget is fixed, you do not need to optimize for total wall time. Everything is judged on the same 5-minute budget.

**VRAM** is a soft constraint. Some increase is acceptable for meaningful `val_bpb` gains, but it should not blow up dramatically.

**Simplicity criterion**: all else being equal, simpler is better. A tiny improvement that adds a lot of ugly complexity is usually not worth it.

**The first run**: your very first run should establish the baseline. Run the training script exactly as-is before trying changes.

## Output format

Once the script finishes it prints a summary like this:

```text
---
val_bpb:          0.997900
training_seconds: 300.1
total_seconds:    325.9
peak_vram_mb:     45060.2
mfu_percent:      39.80
total_tokens_M:   499.6
num_steps:        953
num_params_M:     50.3
depth:            8
```

You can extract the key metrics from the log file with:

```powershell
Select-String -Path run.log -Pattern "^val_bpb:|^peak_vram_mb:"
```

## Logging results

When an experiment is done, log it to `results.tsv` using tabs, not commas.

The TSV has a header row and five columns:

```text
commit	val_bpb	memory_gb	status	description
```

1. Git commit hash (short, 7 chars)
2. `val_bpb` achieved (for crashes, use `0.000000`)
3. Peak memory in GB, rounded to one decimal place (for crashes, use `0.0`)
4. Status: `keep`, `discard`, or `crash`
5. Short text description of what the experiment tried

Example:

```text
commit	val_bpb	memory_gb	status	description
a1b2c3d	0.997900	44.0	keep	baseline
b2c3d4e	0.993200	44.2	keep	increase LR to 0.04
c3d4e5f	1.005000	44.0	discard	switch to GeLU activation
d4e5f6g	0.000000	0.0	crash	double model width (OOM)
```

## The experiment loop

The experiment runs on a dedicated branch, for example `agentloop/mar25`.

LOOP FOREVER:

1. Look at the current git state: branch and commit.
2. Tune `train.py` with one concrete experimental idea.
3. Commit the change.
4. Run the experiment: `uv run train.py *> run.log`
5. Read out the results: `Select-String -Path run.log -Pattern "^val_bpb:|^peak_vram_mb:"`
6. If no metrics appear, the run crashed. Read the tail of the log with `Get-Content run.log -Tail 50`, fix easy mistakes, and retry if appropriate.
7. Record the result in `results.tsv`.
8. If `val_bpb` improved, keep the commit and continue from there.
9. If `val_bpb` got worse or stayed flat, discard the idea and go back to the last good state.

**Timeout**: each experiment should take about 5 minutes total, plus a little overhead. If a run exceeds 10 minutes, kill it and treat it as a failed attempt.

**Crashes**: if a run crashes because of a typo or other easy fix, fix it and re-run. If the idea itself is fundamentally broken, log it as `crash` and move on.

**Never stop on your own**: once the experiment loop begins, do not pause to ask the human whether you should continue. Keep iterating until the human explicitly interrupts you.
