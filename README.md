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

The command produced **no output**, which means there were **no zombie processes** on the system at that moment.

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

> To view the top 10 processes by **memory usage**, sort by column 4:
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

In my run, both commands returned **no output**, so no Chrome/Firefox processes were active.

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

## ✅ Task 4 – Play with `nice` and `renice` (CPU Throttling)

**Goal:** Observe how changing the *nice* value affects process scheduling and CPU usage.

### Steps

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
```

### Observations

Example `top` snippet:

```text
PID    USER      PR  NI  %CPU  COMMAND
30410  akbaral+  20   0  99.0  yes
30412  akbaral+  25   5  97.7  yes
```

- The first `yes` process is running with **NI = 0** (default).  
- The second `yes` process was changed with `renice` to **NI = 5**, so its **PR** (scheduler priority) increased from 20 to 25 (higher PR = lower priority).  
- Linux uses nice values in the range **-20..19**:  
  - Lower NI (e.g. 0, -5) → higher priority, more CPU time on contention.  
  - Higher NI (e.g. 5, 19) → “polite” process, gets CPU time after higher‑priority tasks.

On this VM there are multiple CPU cores, so both `yes` processes can still reach ~100% CPU when the system is otherwise idle.  
When the CPU is busy, the kernel prefers the process with **NI = 0 (PR 20)** over the one with **NI = 5 (PR 25)**, demonstrating how `nice`/`renice` influence scheduling.

---

## ✅ Task 5 – `/proc` Investigation

For this task I started a `sleep 1000` process and explored its entry under `/proc`.

### `/proc/<pid>/cmdline`

```bash
# Find the PID of sleep
ps aux | grep "sleep 1000"

# Example PID: 30747
cd /proc/30747
cat cmdline
```

Example output:

```text
sleep1000
```

`cmdline` contains the **exact command line** used to start the process, including its arguments.  
For `sleep 1000` it shows `sleep1000` (arguments are stored without spaces, separated by NUL characters internally).

---

### `/proc/<pid>/status`

```bash
cat status
```

Snippet of the output:

```text
Name:   sleep
State:  S (sleeping)
Pid:    30747
PPid:   28945
Uid:    1000   1000   1000   1000
Gid:    1005   1005   1005   1005
VmSize: 5400 kB
VmRSS:  1992 kB
Threads: 1
voluntary_ctxt_switches: 2
nonvoluntary_ctxt_switches: 1
...
```

`status` is a human‑readable summary of the process. It shows:

- Identity (`Name`, `Pid`, `PPid`)  
- Current state (`S` = sleeping)  
- User/group IDs  
- Memory usage (`VmSize`, `VmRSS`, etc.)  
- Number of threads and context‑switch statistics

---

### `/proc/<pid>/fd/`

```bash
cd fd
ls
ls -l
```

Example output:

```text
0  1  2

0 -> /dev/pts/0
1 -> /dev/pts/0
2 -> /dev/pts/0
```

`fd/` is a directory of **open file descriptors**:

- `0` = stdin  
- `1` = stdout  
- `2` = stderr  

All three pointed to my terminal (`/dev/pts/0`), which shows that the terminal is just another file device that processes read from and write to.

---

### Extra observation: exploring `/proc` and PID 1

```bash
cd /proc
ls          # shows many PIDs plus files like cpuinfo, meminfo, uptime

cd /proc/1
ls
```

For PID 1 (systemd) I saw messages like:

```text
ls: cannot read symbolic link 'cwd': Permission denied
ls: cannot read symbolic link 'root': Permission denied
ls: cannot read symbolic link 'exe': Permission denied
```

This shows that `/proc` exposes detailed information about processes, but **access to some data for system processes is restricted** unless you are root.

---

### Summary for Task 5

- `cmdline` → launch command and arguments.  
- `status` → detailed process state (IDs, memory, threads, context switches).  
- `fd/` → all open file descriptors (stdin/stdout/stderr, etc.).  
- `/proc` is a virtual filesystem representing live process and kernel state, with permissions enforced for sensitive entries.

---

## ✅ Task 6 – Job Control: Foreground, Background and Stopped Jobs

### 🎯 Task Description

In this task I practiced:

- Starting a long‑running command in the **foreground**  
- Suspending it with `Ctrl+Z` so it becomes a **stopped job**  
- Listing background jobs with `jobs`  
- Resuming a stopped job in the **background** with `bg`  
- Bringing a job back to the **foreground** with `fg`  

All commands were run in a Bash shell on Linux.

---

### 1. Start a foreground command

I started a command that runs for a while, for example:

```bash
sleep 100
```

or

```bash
yes > /dev/null
```

This command initially runs in the **foreground**, blocking the terminal prompt.

---

### 2. Suspend the command (send it to the background as stopped)

While the command was running in the foreground, I pressed:

```text
Ctrl+Z
```

The shell showed something like:

```text
^Z
[1]+  Stopped                 sleep 100
```

Now this command is registered as **job 1** in a *stopped* state.

---

### 3. List current jobs

I checked the list of jobs with:

```bash
jobs -l
```

Example output:

```text
[1]+  31695 Stopped            sleep 100
```

- `[1]` – job number.  
- `31695` – process ID (PID).  
- `Stopped` – current state.  
- `sleep 100` – original command.

---

### 4. Resume the job in the background

To continue the stopped job **in the background**, I ran:

```bash
bg %1
```

Here:

- `bg` means **background**.  
- `%1` refers to job number 1.

After that, `jobs -l` showed the job as running:

```text
[1]+  31695 Running            sleep 100 &
```

The `&` at the end indicates that it is now running in the background, and my shell prompt is free again.

---

### 5. Bring the job back to the foreground

To bring the same job from the background back to the **foreground**, I used:

```bash
fg %1
```

- `fg` means **foreground**.  
- `%1` again refers to job number 1.

After this command, the terminal attached to that job, and I no longer saw the shell prompt until the job finished (or I interrupted it).

---

### 6. Stop the job completely (optional)

For commands that do not end quickly (like `yes > /dev/null`), I did the following to terminate them:

1. Bring the job to the foreground (if it was in the background):

   ```bash
   fg %1
   ```

2. Then stop it with:

   ```text
   Ctrl+C
   ```

This sends `SIGINT` and terminates the process.

---

### 🔍 What I Demonstrated in Task 6

I showed that I can:

- Use `Ctrl+Z` to suspend a foreground process.  
- Use `jobs` / `jobs -l` to inspect current jobs.  
- Use `bg %n` to resume a job in the background.  
- Use `fg %n` to bring a job back to the foreground.  
- Understand the difference between **foreground**, **background**, and **stopped** jobs.

---

## ✅ Task 7 – Graceful Ctrl+C (SIGINT) Handling

### Goal

Create a Bash script that simulates a long‑running process and **cleans up gracefully** when the user presses `Ctrl+C` (SIGINT).  
When SIGINT is received, the script must print:

> `Caught SIGINT, cleaning up…`

and then exit cleanly.

---

### Script: `long_process.sh`

```bash
#!/bin/bash

cleanup() {
    echo "Caught Ctrl+C (SIGINT), performing cleanup..."
    # Add your cleanup commands here
    echo "Cleanup finished."
    exit 0
}

# Trap the SIGINT signal (Ctrl+C)
trap 'cleanup' SIGINT

echo "Process running. Press Ctrl+C to stop gracefully."

# Example long‑running task
while true; do
    sleep 1
done
```

---

### How I ran and tested it

1. Created/edited the file in `vim` and pasted the script:

   ```bash
   vim long_process.sh
   ```

2. Made the script executable:

   ```bash
   chmod +x long_process.sh
   ```

3. Started the script in the foreground:

   ```bash
   ./long_process.sh
   ```

4. While it was running, pressed `Ctrl+C`.

   Example output:

   ```text
   Process running. Press Ctrl+C to stop gracefully.
   ^CCaught Ctrl+C (SIGINT), performing cleanup...
   Cleanup finished.
   ```

The script exits **only after** the `cleanup` function finishes, so any temporary files or background work can be safely handled in that function.

---

### What this demonstrates

- Using a **signal handler** in Bash with `trap`.  
- Handling `SIGINT` (`Ctrl+C`) so the script can:  
  - Show a clear message to the user.  
  - Run custom cleanup logic.  
  - Exit with status `0` after finishing cleanup.

