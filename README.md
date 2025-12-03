# 🧩 Process Monitoring Mini-Tasks

All commands below were executed on a Linux VM as user `akbaralievich` (RHEL/CentOS-like system).  
This README documents how each task was performed so it can be reproduced later.

---

## ✅ Task 1 – Find Zombie Processes

**Goal:** Detect zombie processes (state `Z`) in the system.

### Command

```bash
# Show all processes whose STAT column starts with "Z" (zombie)
ps aux | awk '$8 ~ /^Z/ { print }'
```

### Explanation

- `ps aux` – list all processes with detailed info.  
- `$8` – the `STAT` column in `ps aux` output.  
- `/^Z/` – status starting with `Z` → zombie process.  
- `{ print }` – print the full line for every match.

### Result (current run)

In our run, the command produced **no output**, which means there are **no zombie processes** on the system at the moment.

---

## ✅ Task 2 – List Top CPU-Consuming Processes

**Goal:** See which processes are using the most CPU right now.

### Command (Top 10 by CPU)

```bash
ps aux | sort -k3 -rn | head -10
```

### Explanation

- `%CPU` is the **3rd column** in `ps aux` output.  
- `sort -k3 -rn` – sort by the 3rd column, numeric, reverse (highest first).  
- `head -10` – show only the first 10 lines (top 10 processes).

> Note: To view top 10 processes by **memory usage**, we can sort by column 4:
>
> ```bash
> ps aux | sort -k4 -rn | head -10
> ```
>
> Here `%MEM` is the 4th column.

---

## ✅ Task 3 – Identify & Kill All Browser Processes (Chrome/Firefox)

**Goal:** Find and terminate any running browser processes (`chrome` / `firefox`).

### Step 1 – Check if browsers are running

```bash
# Look for Chrome processes
pgrep -l chrome

# Look for Firefox processes
pgrep -l firefox
```

- `pgrep -l` prints matching PIDs and process names.  
- If nothing is printed → no such processes are running.

In our run, both commands returned **no output**, so no Chrome/Firefox processes were active.

### Step 2 – Kill all browser processes (if any)

```bash
# Kill all Firefox processes
pkill firefox

# Kill all Chrome processes
pkill chrome
```

- `pkill <name>` sends `SIGTERM` to all processes whose name matches `<name>`.  
- If there are no such processes, `pkill` simply does nothing visible.

### Step 3 – Verify that browsers are gone

```bash
pgrep -l chrome
pgrep -l firefox
```

If both commands return **no output**, there are no remaining browser processes.

---

## ℹ️ Notes

- These commands require typical user privileges; some processes may belong to `root` or system services and are listed but should **not** be killed unless you know what they do.
- This README is not final. More monitoring, troubleshooting and automation tasks will be added later as the project grows.

---

### 4. Playing with `nice` and `renice` (CPU throttling)

Goal: see how changing the *nice* value affects process scheduling.

#### Steps

```bash
# 1) Start a CPU-bound process with default nice (0)
yes > /dev/null &

# 2) Start a second CPU-bound process
yes > /dev/null &

# 3) Check their PIDs and current nice values
ps -C yes -o pid,ni,cmd

# 4) Lower the priority of one of them (example PID 30412)
renice -n 5 -p 30412

# 5) Observe both processes in top
top

