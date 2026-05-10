/** Popup script — communicates with the background service worker. */

const urlInput = document.getElementById("url-input");
const engineSelect = document.getElementById("engine-select");
const submitBtn = document.getElementById("submit-btn");
const jobList = document.getElementById("job-list");
const jobCount = document.getElementById("job-count");
const openOptions = document.getElementById("open-options");

// ── Utilities ─────────────────────────────────────────────────────────────────

function formatBytes(bytes) {
  if (!bytes) return "—";
  const units = ["B", "KB", "MB", "GB"];
  let i = 0;
  while (bytes >= 1024 && i < units.length - 1) { bytes /= 1024; i++; }
  return `${bytes.toFixed(1)} ${units[i]}`;
}

function formatSpeed(bps) {
  if (!bps) return "";
  return `${formatBytes(bps)}/s`;
}

function formatEta(seconds) {
  if (!seconds) return "";
  if (seconds < 60) return `${seconds}s`;
  const m = Math.floor(seconds / 60), s = seconds % 60;
  return `${m}m ${s}s`;
}

function shortUrl(url) {
  try {
    const u = new URL(url);
    return u.hostname + (u.pathname.length > 30
      ? u.pathname.slice(0, 27) + "…"
      : u.pathname);
  } catch {
    return url.slice(0, 50);
  }
}

// ── Render ────────────────────────────────────────────────────────────────────

function renderJobs(jobs) {
  const active = jobs.filter(j =>
    ["queued", "downloading", "completed", "failed", "cancelled"].includes(j.status)
  );

  jobCount.textContent = active.filter(j =>
    j.status === "queued" || j.status === "downloading"
  ).length;

  if (active.length === 0) {
    jobList.innerHTML = '<li class="empty-state">No downloads yet.</li>';
    return;
  }

  // Sort: active first, then by created_at desc
  const sorted = [...active].sort((a, b) => {
    const order = { downloading: 0, queued: 1, completed: 2, failed: 3, cancelled: 4 };
    return (order[a.status] ?? 5) - (order[b.status] ?? 5) ||
      new Date(b.created_at) - new Date(a.created_at);
  });

  jobList.innerHTML = "";
  for (const job of sorted) {
    jobList.appendChild(buildJobCard(job));
  }
}

function buildJobCard(job) {
  const p = job.progress || {};
  const pct = p.percent ?? 0;
  const isActive = job.status === "queued" || job.status === "downloading";

  const li = document.createElement("li");
  li.className = "job-card";
  li.dataset.id = job.id;

  li.innerHTML = `
    <div class="job-top">
      <span class="job-url" title="${escHtml(job.url)}">${escHtml(shortUrl(job.url))}</span>
      <span class="job-status status-${job.status}">${job.status}</span>
    </div>
    <div class="progress-bar-wrap">
      <div class="progress-bar-fill" style="width:${pct.toFixed(1)}%"></div>
    </div>
    <div class="job-meta">
      <span>${formatBytes(p.downloaded_bytes)}${p.total_bytes ? " / " + formatBytes(p.total_bytes) : ""}</span>
      <span>${formatSpeed(p.speed_bps)} ${formatEta(p.eta_seconds)}</span>
    </div>
    ${isActive ? `<div class="job-actions"><button class="cancel-btn" data-id="${escHtml(job.id)}">Cancel</button></div>` : ""}
    ${job.error ? `<div class="job-meta" style="color:var(--danger)">${escHtml(job.error)}</div>` : ""}
  `;

  if (isActive) {
    li.querySelector(".cancel-btn").addEventListener("click", () => {
      chrome.runtime.sendMessage({ type: "cancel-job", jobId: job.id });
    });
  }

  return li;
}

function escHtml(str) {
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

// ── Event handlers ────────────────────────────────────────────────────────────

submitBtn.addEventListener("click", () => {
  const url = urlInput.value.trim();
  if (!url) return;
  submitBtn.disabled = true;
  chrome.runtime.sendMessage(
    { type: "post-job", url, engine: engineSelect.value },
    () => {
      urlInput.value = "";
      submitBtn.disabled = false;
    }
  );
});

urlInput.addEventListener("keydown", (e) => {
  if (e.key === "Enter") submitBtn.click();
});

openOptions.addEventListener("click", () => {
  chrome.runtime.openOptionsPage();
});

// ── Live updates from background ──────────────────────────────────────────────

chrome.runtime.onMessage.addListener((msg) => {
  if (msg.type === "jobs-update") {
    renderJobs(msg.jobs);
  }
});

// ── Initial load ──────────────────────────────────────────────────────────────

chrome.runtime.sendMessage({ type: "get-jobs" }, (resp) => {
  if (resp?.jobs) renderJobs(resp.jobs);
});
