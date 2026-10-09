"""Run the SystemVerilog testbenches with Icarus: python rtl/sim/run_tests.py."""

from pathlib import Path
import shutil
import subprocess
import tempfile


def main():
    rtl = Path(__file__).resolve().parents[1]
    compiler = shutil.which("iverilog")
    runtime = shutil.which("vvp")
    if not compiler or not runtime:
        raise SystemExit("Install Icarus Verilog and add iverilog and vvp to PATH.")
    sources = sorted(rtl.glob("*.sv"))
    tests = sorted((rtl / "verif").glob("tb_*.sv"))
    if not sources or not tests:
        raise SystemExit("Missing RTL sources or testbenches.")
    failures = []
    with tempfile.TemporaryDirectory(prefix="foc-sim-") as directory:
        for test in tests:
            executable = Path(directory) / (test.stem + ".vvp")
            try:
                subprocess.run(
                    [compiler, "-g2012", "-s", test.stem, "-o", str(executable),
                     *map(str, sources), str(test)],
                    cwd=directory, check=True, timeout=60,
                )
                result = subprocess.run(
                    [runtime, "-N", str(executable)], cwd=directory,
                    check=True, timeout=60, capture_output=True, text=True,
                )
                print(result.stdout, end="")
                if result.stderr:
                    print(result.stderr, end="")
                if "PASS:" not in result.stdout:
                    raise RuntimeError("Testbench exited without its PASS marker.")
            except (subprocess.CalledProcessError, subprocess.TimeoutExpired, RuntimeError) as error:
                print(f"FAIL: {test.stem}: {error}")
                if getattr(error, "stdout", None):
                    print(error.stdout)
                if getattr(error, "stderr", None):
                    print(error.stderr)
                failures.append(test.stem)
    print(f"{len(tests) - len(failures)}/{len(tests)} testbenches passed")
    return bool(failures)


if __name__ == "__main__":
    raise SystemExit(main())
