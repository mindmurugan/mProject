/**
 * Background service worker (MV3).
 * Responsibilities:
 *   - Register context menu item
 *   - POST download jobs to daemon
 *   - Maintain a WebSocket connection for real-time progress
 *   - Relay job state updates to the popup via chrome.runtime messages
 *   - Fire Chrome notifications on job completion/failure
 */

const DEFAULT_SERVER_URL = "http://127.0.0.1:8765";
const ALARM_NAME = "ws-reconnect";
const RECONNECT_DELAY_MINUTES = 0.5; // 30 s

// In-memory job cache (rebuilt from daemon on WS connect)
const jobs = new Map(); // id → job object
let ws = null;
let serverUrl = DEFAULT_SERVER_URL;
let apiKey = "";

// ── Initialisation ────────────────────────────────────────────────────────────

async function loadSettings() {
  const stored = await chrome.storage.sync.get(["serverUrl", "apiKey"]);
  serverUrl = stored.serverUrl || DEFAULT_SERVER_URL;
  apiKey = stored.apiKey || "";
}

async function init() {
  await loadSettings();
  registerContextMenu();
  connectWebSocket();
}

chrome.runtime.onInstalled.addListener(init);
chrome.runtime.onStartup.addListener(init);

// Re-init when settings change
chrome.storage.onChanged.addListener(async (changes, area) => {
  if (area !== "sync") return;
  await loadSettings();
  reconnectWebSocket();
});

// ── Context menu ──────────────────────────────────────────────────────────────

function registerContextMenu() {
  chrome.contextMenus.removeAll(() => {
    chrome.contextMenus.create({
      id: "download-to-server",
      title: "Download to Server",
      contexts: ["link"],
    });
  });
}

chrome.contextMenus.onClicked.addListener((info) => {
  if (info.menuItemId === "download-to-server" && info.linkUrl) {
    postJob(info.linkUrl);
  }
});

// ── Job submission ────────────────────────────────────────────────────────────

async function postJob(url, engine = "auto", filename = null) {
  if (!apiKey) {
    showNotification("config-error", "Configuration required",
      "Set your server URL and API key in the extension options.");
    return;
  }

  const body = { url, engine };
  if (filename) body.filename = filename;

  try {
    const resp = await fetch(`${serverUrl}/jobs`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-API-Key": apiKey,
      },
      body: JSON.stringify(body),
    });

    if (!resp.ok) {
      const text = await resp.text();
      showNotification(`err-${Date.now()}`, "Submit failed",
        `Server returned ${resp.status}: ${text}`);
      return;
    }

    const job = await resp.json();
    jobs.set(job.id, job);
    broadcastToPopup({ type: "jobs-update", jobs: [...jobs.values()] });
  } catch (err) {
    showNotification(`err-${Date.now()}`, "Connection error", err.message);
  }
}

// ── WebSocket ─────────────────────────────────────────────────────────────────

function wsUrl() {
  const base = serverUrl.replace(/^http/, "ws");
  return `${base}/ws?api_key=${encodeURIComponent(apiKey)}`;
}

function connectWebSocket() {
  if (!apiKey) return;

  if (ws) {
    try { ws.close(); } catch (_) {}
    ws = null;
  }

  ws = new WebSocket(wsUrl());

  ws.addEventListener("open", () => {
    chrome.alarms.clear(ALARM_NAME);
  });

  ws.addEventListener("message", (ev) => {
    let msg;
    try { msg = JSON.parse(ev.data); } catch (_) { return; }

    if (msg.event === "progress" && msg.job) {
      const job = msg.job;
      const prev = jobs.get(job.id);
      jobs.set(job.id, job);

      broadcastToPopup({ type: "jobs-update", jobs: [...jobs.values()] });

      // Notify on terminal state transitions
      const terminal = ["completed", "failed", "cancelled"];
      if (terminal.includes(job.status) && (!prev || prev.status !== job.status)) {
        handleTerminalJob(job);
      }
    }
  });

  ws.addEventListener("close", () => {
    ws = null;
    scheduleReconnect();
  });

  ws.addEventListener("error", () => {
    ws = null;
    scheduleReconnect();
  });
}

function reconnectWebSocket() {
  chrome.alarms.clear(ALARM_NAME);
  connectWebSocket();
}

function scheduleReconnect() {
  chrome.alarms.create(ALARM_NAME, { delayInMinutes: RECONNECT_DELAY_MINUTES });
}

chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === ALARM_NAME) connectWebSocket();
});

// ── Notifications ─────────────────────────────────────────────────────────────

function handleTerminalJob(job) {
  if (job.status === "completed") {
    const name = job.output_path
      ? job.output_path.split(/[\\/]/).pop()
      : job.url;
    showNotification(job.id, "Download complete", name);
  } else if (job.status === "failed") {
    showNotification(job.id, "Download failed", job.error || job.url);
  }
}

function showNotification(id, title, message) {
  chrome.notifications.create(id, {
    type: "basic",
    iconUrl: "../icons/icon48.png",
    title,
    message,
  });
}

// ── Popup communication ───────────────────────────────────────────────────────

function broadcastToPopup(msg) {
  chrome.runtime.sendMessage(msg).catch(() => {
    // Popup may not be open — ignore
  });
}

// Handle popup requesting current state or submitting a job
chrome.runtime.onMessage.addListener((msg, _sender, sendResponse) => {
  if (msg.type === "get-jobs") {
    sendResponse({ jobs: [...jobs.values()] });
    return true;
  }
  if (msg.type === "post-job") {
    postJob(msg.url, msg.engine, msg.filename);
    sendResponse({ ok: true });
    return true;
  }
  if (msg.type === "cancel-job") {
    cancelJob(msg.jobId);
    sendResponse({ ok: true });
    return true;
  }
});

async function cancelJob(jobId) {
  try {
    await fetch(`${serverUrl}/jobs/${jobId}`, {
      method: "DELETE",
      headers: { "X-API-Key": apiKey },
    });
  } catch (_) {}
}
