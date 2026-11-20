// The DQ52 cartridge builder's worker: Pyodide (Python in WebAssembly) runs
// the project's own build (tools/native/build.py) on the ROM the page hands
// it, in memory, and hands back the cartridge. Nothing is sent anywhere: the
// only fetches are Pyodide itself and engine.zip (this site's copy of the
// engine's sources and tools, with the Ophis assembler).

let pyodide = null;

function post(type, extra) { self.postMessage(Object.assign({ type }, extra)); }

async function init(base) {
  importScripts(base + "pyodide.js");
  post("progress", { text: "Loading Python…" });
  pyodide = await loadPyodide({ indexURL: base });
  post("progress", { text: "Loading the engine…" });
  const zip = await (await fetch("engine.zip")).arrayBuffer();
  pyodide.unpackArchive(zip, "zip", { extractDir: "/dq" });
  pyodide.runPython(`
import sys
sys.path[:0] = ["/dq", "/dq/tools/native"]
sys.setrecursionlimit(5000)
`);
  post("ready");
}

async function build(rom) {
  const t0 = performance.now();
  post("progress", { text: "Building the cartridge (this takes a little while)…" });
  pyodide.FS.writeFile("/rom.nes", new Uint8Array(rom));
  pyodide.globals.set("say", (s) => post("log", { text: s }));
  const outcome = pyodide.runPython(`
import contextlib, io, os, shutil, sys
log = io.StringIO()
shutil.rmtree("/out", ignore_errors=True)
sys.argv = ["build.py", "/rom.nes", "/out"]
error = None
try:
    import build
    with contextlib.redirect_stdout(log):
        build.main()
except SystemExit as e:
    if e.code not in (None, 0):
        error = str(e.code)
except Exception as e:
    error = f"{type(e).__name__}: {e}"
finally:
    os.remove("/rom.nes")
for line in log.getvalue().splitlines():
    say(line)
error
`);
  if (outcome) {
    post("error", { text: friendly(outcome) });
    return;
  }
  const cart = pyodide.FS.readFile("/out/dwnative.bin");
  pyodide.runPython(`import shutil; shutil.rmtree("/out", ignore_errors=True)`);
  const buf = cart.buffer.slice(cart.byteOffset, cart.byteOffset + cart.byteLength);
  post("done", { cart: buf, seconds: (performance.now() - t0) / 1000 });
}

function friendly(message) {
  if (message.includes("not a Dragon Warrior ROM") || message.includes("not a known Dragon Warrior ROM")) {
    return "That file isn't a ROM this builder knows. It needs Dragon Warrior for the NES, the USA release (rev0 or rev1), as a .nes file.";
  }
  return "The build stopped: " + message;
}

self.onmessage = (e) => {
  const m = e.data;
  if (m.type === "init") {
    init(m.pyodide).catch((err) => post("error", { text: "The builder could not load: " + err }));
  } else if (m.type === "build") {
    build(m.rom).catch((err) => post("error", { text: "The build stopped: " + err }));
  }
};
