# Cloudberry Multi-Test Runner

The Cloudberry Multi-Test Runner is a Python script designed to execute both SQL test files and Shell scripts concurrently. It provides robust logging, minimal console output, and generates comprehensive JSON and HTML reports.

## Features

  * **Concurrent SQL Execution:** Uses a thread pool to execute multiple SQL files simultaneously, significantly reducing test suite runtime.
  * **Full `psql` Support:** Executes SQL files via `psql -f`, fully supporting `psql` meta-commands (like `\c` for switching databases).
  * **Minimal Console Output:** Provides clear success/failure summaries to the console while directing detailed output to a log file.
  * **Detailed Logging:** Captures all `psql` and `bash` STDOUT and STDERR into a single, time-stamped log file.
  * **Comprehensive Reporting:** Generates detailed JSON and user-friendly HTML reports summarizing the test suite execution.
  * **Selective Execution:** Allows running only SQL or only Shell tests, or specifying a single file for execution.

## Prerequisites

1.  **Python 3:** The script requires Python 3.6 or newer.
2.  **`psql` Client:** The PostgreSQL command-line client must be installed and accessible in your system's `PATH`.
3.  **Jinja2 Library:** Required for generating the HTML report.

### Installation of Python Dependencies

```bash
python3 -m pip install jinja2
```

## Project Structure

You should organize your test files and template as follows:

```
/
├── test_runner.py          # The main execution script
├── /sql_tests              # Default directory for SQL files (*.sql)
│   ├── 01_setup.sql
│   ├── 02_range_test.sql
│   └── ...
├── /bash_tests             # Default directory for Shell files (*.sh)
│   ├── test_data_load.sh
│   └── ...
└── /templates              # Required for HTML report generation
    └── report_template.html  # (You need to provide this template file)
```

## Usage

The script is executed via the command line, requiring connection details for the database and supporting several optional arguments for customization.

### Execution Syntax

```bash
python3 test_runner.py [options]
```

### Required Arguments

| Argument | Description |
| :--- | :--- |
| `--host` | Database hostname/IP. |
| `--port` | Database port (default: `5432`). |
| `--user` | Database username. |
| `--password` | Database password. |
| `--dbname` | Initial database name to connect to. |

### Optional Arguments

| Argument | Default | Description |
| :--- | :--- | :--- |
| `--sql-dir` | `sql_tests` | Directory containing SQL test scripts. |
| `--bash-dir` | `bash_tests` | Directory containing Shell test scripts. |
| `--report-prefix` | `test_run` | Prefix for generated log and report files. |
| `--only {sql, shell}` | None | Execute only SQL tests or only Shell tests. |
| `--file-sql` | None | Execute only the specified SQL filename (e.g., `test_1.sql`). |
| `--file-bash` | None | Execute only the specified Shell filename (e.g., `setup.sh`). |
| `--concurrency` | CPU Count (or 4) | **(SQL ONLY)** Number of SQL files to execute in parallel. |

### Example 1: Standard Concurrent Run

Run all tests in the default directories with 5 parallel SQL executions:

```bash
python3 test_runner.py \
    --host 192.168.1.10 \
    --port 5432 \
    --user gpadmin \
    --password mypass \
    --dbname testdb \
    --concurrency 5
```

### Example 2: Running a Single SQL File

Execute only `03_list_partition.sql` sequentially:

```bash
python3 test_runner.py \
    --host 192.168.1.10 \
    --user gpadmin \
    --password mypass \
    --dbname testdb \
    --only sql \
    --file-sql 03_list_partition.sql
```

## Output and Reporting

After execution, a new directory `test_report/` will be created (if it doesn't exist) containing the output files.

### Console Output Example (Summary)

```
[INFO] Starting test execution. Detailed log: test_report/test_run_20251107_101458.log

=== Cloudberry SQL Test Runner (psql -f) ===
...
[SQL OK] 01_setup.sql (1.234s)
[SQL FAIL] 02_concurrent_write.sql (5.101s)
[SQL OK] 03_list_partition.sql (0.987s)

=== Shell Script Test Runner ===
...
[BASH OK] test_data_load.sh (15.540s)

=== Test Completed Summary ===
Total: 4, Success: 3, Failed: 1
HTML reports saved to /path/to/test_report/test_run_20251107_101458.html
JSON reports saved to /path/to/test_report/test_run_20251107_101458.json
```

### Output Files

| File | Description |
| :--- | :--- |
| `test_report/test_run_YYYYMMDD_HHMMSS.log` | **Detailed Log:** Contains all execution messages, full STDOUT/STDERR from `psql` and `bash`, and timestamps. |
| `test_report/test_run_YYYYMMDD_HHMMSS.json` | **Structured Report:** A machine-readable JSON file with the full test results, durations, and error messages. |
| `test_report/test_run_YYYYMMDD_HHMMSS.html` | **Visual Report:** An easily readable summary of the test suite (requires a Jinja2 template). |
