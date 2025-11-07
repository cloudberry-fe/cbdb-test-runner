#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Cloudberry Multi-Test Runner (SQL and Shell)
"""

import os
import sys
import json
import argparse
import subprocess
import re
from datetime import datetime
from jinja2 import Environment, FileSystemLoader
from concurrent.futures import ThreadPoolExecutor, as_completed

# --- Configuration Constant ---
REPORT_DIR = "test_report"
# ------------------------------


# --- Global Helper for Dual Logging ---
def _log(message, file_handle=None, is_error=False, is_summary=False):
    """
    Logs a message. 
    - Writes all messages to the file handle.
    - Only prints messages to the console if is_summary is True.
    """
    message = message.strip()
    timestamp_str = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    
    # 1. Write to log file (All messages are written)
    if file_handle:
        try:
            file_handle.write(f"{timestamp_str} - {message}\n")
            file_handle.flush()
        except Exception as e:
            # Fallback if writing to file fails
            print(f"[{timestamp_str} LOG ERROR] Failed to write to file: {e}", file=sys.stderr)
            
    # 2. Print to console (Only if is_summary=True)
    if is_summary:
        if is_error:
            print(message, file=sys.stderr)
        else:
            print(message)
# --------------------------------------


class BaseTestRunner:
    """Base class for test runners to handle common functionality like reporting."""
    def __init__(self, report_json_path, report_html_path, output_file_handle=None):
        self.results = []
        self.output_file_handle = output_file_handle
        self.report_json = report_json_path
        self.report_html = report_html_path

    def _print_log(self, message, is_error=False, is_summary=False):
        _log(message, self.output_file_handle, is_error, is_summary)

    def _generate_reports(self, start_time, end_time):
        """Generate both JSON and HTML reports"""
        
        self._print_log("\n--- Generating Reports ---") 
        
        summary = {
            "total": len(self.results),
            "success": sum(1 for r in self.results if r["status"] == "SUCCESS"),
            "failed": sum(1 for r in self.results if r["status"] == "FAILED"),
            "skipped": sum(1 for r in self.results if r["status"] == "SKIPPED"), 
        }

        report_data = {
            "start_time": str(start_time),
            "end_time": str(end_time),
            "duration": str(end_time - start_time),
            "summary": summary,
            "results": self.results,
        }

        # Save JSON report
        try:
            with open(self.report_json, "w", encoding="utf-8") as f:
                json.dump(report_data, f, indent=4, ensure_ascii=False)
            self._print_log(f"[INFO] JSON report saved to {self.report_json}")
        except Exception as e:
            self._print_log(f"[ERROR] Failed to save JSON report to {self.report_json}: {e}", is_error=True)

        # Save HTML report
        self._generate_html_report(report_data)
        self._print_log(f"[INFO] HTML report saved to {self.report_html}")

    def _generate_html_report(self, report_data):
        """Render HTML report using Jinja2"""
        # Note: Assumes 'templates/report_template.html' exists in a 'templates' subdirectory
        script_dir = os.path.dirname(os.path.abspath(__file__))
        template_dir = os.path.join(script_dir, "templates")

        if not os.path.exists(template_dir):
            self._print_log(f"[WARNING] HTML template directory not found at {template_dir}. Skipping HTML report.")
            return

        try:
            env = Environment(loader=FileSystemLoader(template_dir))
            template = env.get_template("report_template.html")
            html_content = template.render(report=report_data)

            with open(self.report_html, "w", encoding="utf-8") as f:
                f.write(html_content)
        except Exception as e:
             self._print_log(f"[ERROR] Failed to render HTML report: {e}", is_error=True)


class SQLTestRunner(BaseTestRunner):
    """
    Executes SQL files using 'psql -f' command via subprocess.
    Supports parallel execution using ThreadPoolExecutor.
    """
    def __init__(self, db_config, sql_dir, specific_file, report_json_path, report_html_path, output_file_handle, concurrency):
        super().__init__(report_json_path, report_html_path, output_file_handle)
        self.db_config = db_config
        self.sql_dir = sql_dir
        self.specific_file = specific_file 
        self.test_type = "SQL (psql)"
        self.concurrency = concurrency # <--- NEW: Concurrency level
        # Ignores "ERROR: role "XXX" does not exist"
        self.IGNORED_ERROR_MESSAGE_PATTERN = "ERROR:  role \".*\" does not exist" 

    def _get_files(self):
        """List all SQL files or the specific file sorted by name"""
        if not os.path.exists(self.sql_dir):
            self._print_log(f"[WARNING] SQL directory '{self.sql_dir}' not found. Skipping SQL tests.")
            return []

        if self.specific_file:
            fpath = os.path.join(self.sql_dir, self.specific_file)
            if os.path.isfile(fpath) and fpath.endswith(".sql"):
                self._print_log(f"[INFO] Executing specified SQL file: {self.specific_file}")
                return [(fpath, os.path.basename(fpath))]
            else:
                self._print_log(f"[ERROR] Specified SQL file '{self.specific_file}' not found or is not a .sql file in '{self.sql_dir}'.", is_error=True)
                return []
        
        files = [f for f in os.listdir(self.sql_dir) if f.endswith(".sql")]
        files.sort()
        return [(os.path.join(self.sql_dir, f), f) for f in files]

    def _execute_test(self, file_path, file_name):
        """Execute a single SQL file using psql -f (designed to run in a thread)"""
        start = datetime.now()
        
        # Log to file, but do not summarize to console immediately
        self._print_log(f"\n--- Executing SQL File (psql -f): {file_name} ---")

        # 1. Build the psql command
        psql_command = [
            'psql',
            '-a',
            '-X', 
            '-h', self.db_config['host'],
            '-p', str(self.db_config['port']),
            '-U', self.db_config['user'],
            '-d', self.db_config['dbname'], 
            '-f', file_path,
            '-w', 
        ]

        # 2. Set PGPASSWORD environment variable
        env = os.environ.copy()
        env['PGPASSWORD'] = self.db_config['password']

        status = "SUCCESS"
        error_message = None
        psql_output = ""
        psql_error = ""
        return_code = 0

        try:
            # 3. Execute psql command
            result = subprocess.run(
                psql_command,
                check=False, 
                capture_output=True,
                text=True,
                env=env,
                timeout=600 
            )
            
            psql_output = result.stdout.strip()
            psql_error = result.stderr.strip()
            return_code = result.returncode

            # 4. Check exit code and error messages
            if return_code != 0:
                is_ignorable_error = False
                if psql_error:
                    if re.search(self.IGNORED_ERROR_MESSAGE_PATTERN, psql_error, re.IGNORECASE):
                        is_ignorable_error = True
                        
                if is_ignorable_error:
                    status = "SUCCESS"
                    error_message = f"Execution successful with ignored error(s). Exit Code: {return_code}. Check log for details."
                    self._print_log(f"[SQL WARN] {file_name}: Finished with ignored errors. Status: SUCCESS.", is_error=False, is_summary=False)
                else:
                    status = "FAILED"
                    error_message = f"psql execution failed. Exit Code: {return_code}. Error: {psql_error.splitlines()[0] if psql_error else 'Unknown error.'}"

        except subprocess.TimeoutExpired:
            status = "FAILED"
            error_message = "psql execution timed out after 600 seconds."
        except Exception as e:
            status = "FAILED"
            error_message = f"Execution subprocess error: {str(e)}"

        duration = (datetime.now() - start).total_seconds()
        
        # 5. Log details
        self._print_log(f"psql STDOUT:\n{psql_output}", is_error=False, is_summary=False)
        self._print_log(f"psql STDERR:\n{psql_error}", is_error=True, is_summary=False)
        self._print_log(f"Execution Return Code: {return_code}", is_error=False, is_summary=False)
        
        # Return the result dictionary for collection
        return {
            "file": file_name, 
            "status": status, 
            "error": error_message, 
            "duration": duration, 
            "type": self.test_type
        }


    def run(self):
        """Main SQL logic with concurrent execution"""
        self._print_log("\n=== Cloudberry SQL Test Runner (psql -f) ===")
        self._print_log(f"SQL directory: {self.sql_dir}")
        self._print_log(f"Concurrency level: {self.concurrency}") # <--- NEW: Log concurrency

        files = self._get_files()
        
        start_time = datetime.now()
        
        if not files:
            self._print_log(f"[INFO] No SQL files found to execute.")
            return start_time, datetime.now(), self.results

        # Use ThreadPoolExecutor for concurrent execution
        with ThreadPoolExecutor(max_workers=self.concurrency) as executor:
            future_to_file = {
                executor.submit(self._execute_test, fpath, fname): fname
                for fpath, fname in files
            }
            
            # Collect results as they complete
            for future in as_completed(future_to_file):
                result = future.result()
                file_name = result['file']
                
                # 7. Print summary to console for completed task
                if result["status"] == "SUCCESS":
                    self._print_log(f"[SQL OK] {file_name} ({result['duration']:.3f}s)", is_summary=True)
                else:
                    self._print_log(f"[SQL FAIL] {file_name} ({result['duration']:.3f}s)", is_error=True, is_summary=True)
                    # The detailed failure message is already in the file log from _execute_test

                self.results.append(result)

        end_time = datetime.now()
        return start_time, end_time, self.results 


class ShellTestRunner(BaseTestRunner):
    """
    Executes Shell scripts using bash via subprocess.
    """
    def __init__(self, bash_dir, specific_file, report_json_path, report_html_path, output_file_handle):
        super().__init__(report_json_path, report_html_path, output_file_handle)
        self.bash_dir = bash_dir
        self.specific_file = specific_file 
        self.test_type = "SHELL"

    def _get_files(self):
        """List all Shell files (.sh) or the specific file sorted by name"""
        if not os.path.exists(self.bash_dir):
            self._print_log(f"[WARNING] Shell directory '{self.bash_dir}' not found. Skipping Shell tests.")
            return []

        if self.specific_file:
            fpath = os.path.join(self.bash_dir, self.specific_file)
            if os.path.isfile(fpath) and fpath.endswith(".sh"):
                self._print_log(f"[INFO] Executing specified Shell file: {self.specific_file}")
                return [fpath]
            else:
                self._print_log(f"[ERROR] Specified Shell file '{self.specific_file}' not found or is not a .sh file in '{self.bash_dir}'.", is_error=True)
                return []

        files = [f for f in os.listdir(self.bash_dir) if f.endswith(".sh")]
        files.sort()
        return [os.path.join(self.bash_dir, f) for f in files]

    def _execute_test(self, file_path, file_name):
        """Execute a single Shell script"""
        start = datetime.now()
        
        self._print_log(f"\n--- Executing SHELL: {file_name} ---")

        # Check for execution permission
        if not os.access(file_path, os.X_OK):
            duration = (datetime.now() - start).total_seconds()
            error_message = "Execution permission denied. Use 'chmod +x' on the file."
            
            self._print_log(f"[BASH SKIP] {file_name}: {error_message}", is_error=True) 
            self._print_log(f"[BASH SKIP] {file_name} ({duration:.3f}s)", is_error=True, is_summary=True)

            self.results.append({
                "file": file_name, "status": "SKIPPED", "error": error_message,
                "duration": duration, "type": self.test_type
            })
            return

        try:
            # Execute script using bash
            result = subprocess.run(
                ['bash', file_path],
                check=True, # Raises CalledProcessError on non-zero exit code
                capture_output=True,
                text=True,
                timeout=300
            )
            duration = (datetime.now() - start).total_seconds()
            
            # Detailed log to file
            self._print_log(f"Script STDOUT:\n{result.stdout.strip()}")
            self._print_log(f"Script STDERR:\n{result.stderr.strip()}")
            
            # Summary output to console
            self._print_log(f"[BASH OK] {file_name} ({duration:.3f}s)", is_summary=True)

            self.results.append({
                "file": file_name, "status": "SUCCESS", "error": None,
                "duration": duration, "type": self.test_type
            })

        except subprocess.CalledProcessError as e:
            duration = (datetime.now() - start).total_seconds()
            error_msg = f"Exit Code {e.returncode}. Stderr: {e.stderr.strip()}"
            
            # Detailed log to file
            self._print_log(f"Script STDOUT:\n{e.stdout.strip()}")
            self._print_log(f"[BASH FAIL] {file_name}: Execution failed. {error_msg}", is_error=True)

            # Summary output to console
            self._print_log(f"[BASH FAIL] {file_name} ({duration:.3f}s)", is_error=True, is_summary=True)

            self.results.append({
                "file": file_name, "status": "FAILED", "error": error_msg,
                "duration": duration, "type": self.test_type
            })

        except (subprocess.TimeoutExpired, Exception) as e:
            duration = (datetime.now() - start).total_seconds()
            error_msg = str(e)
            
            # Detailed log to file
            self._print_log(f"[BASH FAIL] {file_name}: Error: {error_msg}", is_error=True)

            # Summary output to console
            self._print_log(f"[BASH FAIL] {file_name} ({duration:.3f}s)", is_error=True, is_summary=True)

            self.results.append({
                "file": file_name, "status": "FAILED", "error": error_msg,
                "duration": duration, "type": self.test_type
            })
        
    def run(self):
        """Main Shell logic (Sequential execution)"""
        self._print_log("\n=== Shell Script Test Runner ===")
        self._print_log(f"Shell directory: {self.bash_dir}")

        files = self._get_files()
        
        start_time = datetime.now()
        for fpath in files:
            self._execute_test(fpath, os.path.basename(fpath))
        
        end_time = datetime.now()
        return start_time, end_time, self.results


def main():
    parser = argparse.ArgumentParser(description="Cloudberry Multi-Test Runner (SQL and Shell)")
    # DB arguments
    parser.add_argument("--host", required=True)
    parser.add_argument("--port", default=5432, type=int)
    parser.add_argument("--user", required=True)
    parser.add_argument("--password", required=True)
    parser.add_argument("--dbname", required=True)
    # Directory arguments
    parser.add_argument("--sql-dir", default="sql_tests", help="Directory containing SQL test scripts.")
    parser.add_argument("--bash-dir", default="bash_tests", help="Directory containing Shell test scripts.")
    # Report arguments
    parser.add_argument("--report-prefix", default="test_run", help="Prefix for the generated report and log files (e.g., 'test_run_20251104_...').")
    # Selective Type Execution
    parser.add_argument(
        "--only", choices=["sql", "shell"], default=None, help="Execute only 'sql' tests or only 'shell' tests."
    )
    # Single File Execution
    parser.add_argument(
        "--file-sql", default=None, help="Specify the exact filename (e.g., 'test_1.sql') to execute only that file."
    )
    parser.add_argument(
        "--file-bash", default=None, help="Specify the exact filename (e.g., 'setup.sh') to execute only that file."
    )
    # --- NEW CONCURRENCY PARAMETER ---
    parser.add_argument(
        "--concurrency", type=int, default=os.cpu_count() or 4, 
        help="Number of parallel SQL test files to execute (default: CPU count or 4)."
    )
    # ---------------------------------

    args = parser.parse_args()

    # --- 1. File Naming and Directory Setup ---
    suite_start_time = datetime.now() 
    timestamp = suite_start_time.strftime("%Y%m%d_%H%M%S")
    
    if not os.path.exists(REPORT_DIR):
        try:
            os.makedirs(REPORT_DIR)
            print(f"[INFO] Created report directory: {REPORT_DIR}") 
        except OSError as e:
            print(f"[FATAL ERROR] Failed to create directory {REPORT_DIR}: {e}", file=sys.stderr)
            return

    file_name_base = f"{args.report_prefix}_{timestamp}"
    log_file_path = os.path.join(REPORT_DIR, f"{file_name_base}.log")
    json_report_path = os.path.join(REPORT_DIR, f"{file_name_base}.json")
    html_report_path = os.path.join(REPORT_DIR, f"{file_name_base}.html")

    # --- 2. Initialize Logging ---
    try:
        output_file_handle = open(log_file_path, 'w', encoding='utf-8')
        _log(f"--- Test Suite Started at {suite_start_time} ---", output_file_handle)
        print(f"[INFO] Starting test execution. Detailed log: {log_file_path}") 
    except Exception as e:
        print(f"[FATAL ERROR] Could not open output file {log_file_path}: {e}", file=sys.stderr)
        return

    # --- 3. Prepare Configuration ---
    db_config = {
        "host": args.host, "port": args.port, "user": args.user,
        "password": args.password, "dbname": args.dbname,
    }
    
    all_results = []
    suite_end_time = suite_start_time 

    # --- 4. Selective Execution Logic ---

    # Run SQL Tests
    if args.only is None or args.only == "sql":
        sql_runner = SQLTestRunner(
            db_config, args.sql_dir, args.file_sql, 
            json_report_path, html_report_path, output_file_handle, 
            args.concurrency # <--- NEW: Pass concurrency
        )
        _, suite_end_time, sql_results = sql_runner.run()
        all_results.extend(sql_results)
    else:
        _log("\n[INFO] Skipping SQL Test Runner due to '--only' selection.", output_file_handle)

    # Run Shell Tests
    if args.only is None or args.only == "shell":
        shell_runner = ShellTestRunner(
            args.bash_dir, args.file_bash, 
            json_report_path, html_report_path, output_file_handle
        )
        _, suite_end_time, shell_results = shell_runner.run()
        all_results.extend(shell_results)
    else:
        _log("\n[INFO] Skipping Shell Test Runner due to '--only' selection.", output_file_handle)
        
    # --- 5. Generate Unified Reports ---
    if not all_results:
        suite_end_time = datetime.now()
        _log("\n[WARNING] No tests were executed. Report generation skipped.", output_file_handle)
        print(f"\n[WARNING] No tests were executed. Total duration: {suite_end_time - suite_start_time}")
    else:
        # Use a BaseTestRunner instance to handle unified report generation
        report_generator = BaseTestRunner(json_report_path, html_report_path, output_file_handle)
        report_generator.results = all_results 
        report_generator._generate_reports(suite_start_time, suite_end_time)
        
        final_summary = report_generator.results
        total = len(final_summary)
        success = sum(1 for r in final_summary if r["status"] == "SUCCESS")
        failed = sum(1 for r in final_summary if r["status"] == "FAILED")
        
        print(f"\n=== Test Completed Summary ===")
        print(f"Total: {total}, Success: {success}, Failed: {failed}")
        print(f"HTML reports saved to {os.path.abspath(html_report_path)}")
        print(f"JSON reports saved to {os.path.abspath(json_report_path)}")

    _log("\n=== All Selected Tests Completed ===", output_file_handle)

    # --- 6. Final Cleanup ---
    output_file_handle.close() 

if __name__ == "__main__":
    main()