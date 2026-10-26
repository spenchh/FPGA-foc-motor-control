"""Run one existing directed test and save a VCD without editing its source."""

import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("test", nargs="?", default="tb_pi_controller_q15",
                        help="An existing tb_* module name, without .sv")
    parser.add_argument("--output", type=Path, default=Path("build/waves"))
    args = parser.parse_args()
    rtl = Path(__file__).resolve().parents[1]
    tests = {path.stem: path for path in (rtl / "verif").glob("tb_*.sv")}
    if args.test not in tests:
        parser.error("Choose one of: " + ", ".join(sorted(tests)))
    compiler, runtime = shutil.which("iverilog"), shutil.which("vvp")
    if not compiler or not runtime:
        parser.error("Install Icarus Verilog and put iverilog and vvp on PATH.")
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    waveform = output / (args.test + ".vcd")
    with tempfile.TemporaryDirectory(prefix="foc-trace-") as directory:
        directory = Path(directory)
        harness = directory / "trace_harness.sv"
        # The selected name comes only from known test files, not arbitrary HDL.
        harness.write_text(
            "`timescale 1ns/1ps\nmodule trace_harness;\n"
            f"  {args.test} test();\n"
            "  initial begin\n"
            f'    $dumpfile("{args.test}.vcd");\n'
            "    $dumpvars(0, test);\n  end\nendmodule\n",
            encoding="utf-8",
        )
        executable = directory / "trace.vvp"
        subprocess.run(
            [compiler, "-g2012", "-s", "trace_harness", "-o", str(executable),
             *map(str, sorted((rtl / "design").glob("*.sv"))),
             str(tests[args.test]), str(harness)], check=True, timeout=60,
        )
        result = subprocess.run([runtime, "-N", str(executable)], cwd=output,
                                check=True, timeout=60, capture_output=True, text=True)
        print(result.stdout, end="")
        if result.stderr:
            print(result.stderr, end="")
        if "PASS:" not in result.stdout or not waveform.is_file() or waveform.stat().st_size == 0:
            raise SystemExit("Trace did not complete with a PASS marker and a nonempty VCD.")
    print(f"Waveform: {waveform}")


if __name__ == "__main__":
    main()
