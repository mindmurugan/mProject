const serverUrlInput = document.getElementById("server-url");
const apiKeyInput = document.getElementById("api-key");
const form = document.getElementById("settings-form");
const testBtn = document.getElementById("test-btn");
const statusMsg = document.getElementById("status-msg");

// ── Load saved settings ───────────────────────────────────────────────────────

async function loadSettings() {
  const stored = await chrome.storage.sync.get(["serverUrl", "apiKey"]);
  serverUrlInput.value = stored.serverUrl || "http://127.0.0.1:8765";
  apiKeyInput.value = stored.apiKey || "";
}

loadSettings();

// ── Save ──────────────────────────────────────────────────────────────────────

form.addEventListener("submit", async (e) => {
  e.preventDefault();
  const serverUrl = serverUrlInput.value.trim().replace(/\/$/, "");
  const apiKey = apiKeyInput.value.trim();

  await chrome.storage.sync.set({ serverUrl, apiKey });
  showStatus("Saved!", "ok");
});

// ── Test connection ───────────────────────────────────────────────────────────

testBtn.addEventListener("click", async () => {
  const serverUrl = serverUrlInput.value.trim().replace(/\/$/, "");
  const apiKey = apiKeyInput.value.trim();

  testBtn.disabled = true;
  showStatus("Testing…", "");

  try {
    const resp = await fetch(`${serverUrl}/health`, {
      headers: { "X-API-Key": apiKey },
      signal: AbortSignal.timeout(5000),
    });
    if (resp.ok) {
      showStatus("Connected!", "ok");
    } else {
      showStatus(`Error ${resp.status}`, "err");
    }
  } catch (err) {
    showStatus(`Failed: ${err.message}`, "err");
  } finally {
    testBtn.disabled = false;
  }
});

function showStatus(msg, cls) {
  statusMsg.textContent = msg;
  statusMsg.className = cls;
  if (cls) {
    setTimeout(() => {
      statusMsg.textContent = "";
      statusMsg.className = "";
    }, 4000);
  }
}
