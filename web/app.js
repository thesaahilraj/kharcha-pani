// ==========================================================================
// Kharcha Pani — Interactive Web Engine & Local Parser Simulator
// Mirroring TransactionParser.swift & TransactionFileManager.swift
// ==========================================================================

// State Store
const state = {
  rawLines: [],
  parsedTransactions: [],
  customRules: [
    { id: "r1", pattern: "(?:Swiggy|SWG)\\s*([A-Za-z0-9_]+)", mappedMerchant: "Swiggy Food & Instamart", targetCategory: "Food & Dining", isEnabled: true },
    { id: "r2", pattern: "(?:Petrol|Fuel|HPCL|IOCL|BPCL)\\s*([A-Za-z0-9_\\s]+)", mappedMerchant: "Fuel Pump Station", targetCategory: "Transport", isEnabled: true }
  ],
  selectedFilter: "all",
  searchQuery: "",
  isInitialized: false
};

// Default Sample Lines Generator
const sampleJSONLines = [
  { date: "2026-07-16T10:15:30Z", sender: "DZ-HDFCBK", body: "Alert: Spent Rs.450.00 via UPI to Swiggy@HDFC on 16-07-26. Not you? Call bank." },
  { date: "2026-07-15T18:45:00Z", sender: "AX-AxisBk", body: "Txn: Rs.2100.00 debited from card ending 4321 at Petrol Pump Patna." },
  { date: "2026-07-15T12:10:00Z", sender: "VK-ICICIB", body: "Debit: INR 1299.00 paid for Swiggy Order via UPI VPA swiggy@icici." },
  { date: "2026-07-14T14:30:00Z", sender: "AD-SBIINB", body: "Dear Customer, your A/C XXXXX1234 has been debited by Rs 3499.00 on 14-Jul-26 info: Flipkart Internet." },
  { date: "2026-07-13T20:20:00Z", sender: "DZ-HDFCBK", body: "Alert: Spent Rs.380.00 via UPI to Uber Rides on 13-07-26." },
  { date: "2026-07-12T16:05:00Z", sender: "AX-AxisBk", body: "Txn: Rs.650.00 debited from Credit Card ending 8812 at Blinkit Commerce." },
  { date: "2026-07-11T11:40:00Z", sender: "VK-ICICIB", body: "Spent Rs.6800.00 on ICICI Bank Credit Card ending 9011 at Myntra Fashion." }
];

// Parser Engine Logic (Mirroring TransactionParser.swift)
class LocalTransactionParser {
  static parse(rawLine, customRules = []) {
    const text = rawLine.body || "";
    if (!text.trim()) return null;

    // Deduplication Key (Base64 hash of Date + Text Body)
    const uniqueString = `${rawLine.date}_${text}`;
    const id = btoa(unescape(encodeURIComponent(uniqueString)));

    // Check Custom User Rules First
    for (const rule of customRules) {
      if (rule.isEnabled && rule.pattern) {
        try {
          const rx = new RegExp(rule.pattern, "i");
          const m = text.match(rx);
          if (m && m[1]) {
            const amount = this.extractAmount(text);
            if (!amount) continue;
            return {
              id,
              date: new Date(rawLine.date),
              institution: rawLine.sender,
              amount,
              merchant: rule.mappedMerchant || m[1],
              type: this.classifyAccountType(text),
              category: rule.targetCategory || this.autoCategorize(m[1]),
              rawSender: rawLine.sender,
              rawBody: text
            };
          }
        } catch (e) {}
      }
    }

    // Amount Extraction
    const amount = this.extractAmount(text);
    if (!amount || amount <= 0) return null;

    // Merchant Extraction
    const merchantMatch = text.match(/(?:to|at|vpa|spent on|info:)\s+([^\s,.]+([\s][^\s,.])?)/i);
    let rawMerchant = merchantMatch ? merchantMatch[1] : this.fallbackMerchant(text, rawLine.sender);
    const cleanMerchant = this.cleanMerchantName(rawMerchant);

    // Account Classification & Category
    const type = this.classifyAccountType(text);
    const category = this.autoCategorize(cleanMerchant);

    return {
      id,
      date: new Date(rawLine.date),
      institution: rawLine.sender,
      amount,
      merchant: cleanMerchant,
      type,
      category,
      rawSender: rawLine.sender,
      rawBody: text
    };
  }

  static extractAmount(text) {
    const patterns = [
      /(?:Rs\.|INR|Rs|debited by|spent|paid)\s*([\d,]+\.?\d*)/i,
      /(?:amount of)\s*([\d,]+\.?\d*)/i
    ];
    for (const p of patterns) {
      const match = text.match(p);
      if (match && match[1]) {
        const val = parseFloat(match[1].replace(/,/g, ""));
        if (!isNaN(val)) return val;
      }
    }
    return null;
  }

  static cleanMerchantName(raw) {
    let clean = raw.trim();
    if (clean.toLowerCase().endsWith(" on")) clean = clean.slice(0, -3);
    if (clean.toLowerCase().endsWith(" via")) clean = clean.slice(0, -4);
    clean = clean.replace(/[.,]$/, "");
    if (clean.includes("@")) {
      clean = clean.split("@")[0];
    }
    clean = clean.charAt(0).toUpperCase() + clean.slice(1);
    return clean || "Merchant";
  }

  static classifyAccountType(text) {
    const lower = text.toLowerCase();
    if (lower.includes("upi") || lower.includes("vpa")) return "UPI";
    if (lower.includes("credit") || lower.includes("cc")) return "Credit Card";
    if (lower.includes("debit") || lower.includes("dc") || lower.includes("card ending")) return "Debit Card";
    return "Account";
  }

  static autoCategorize(merchant) {
    const lower = merchant.toLowerCase();
    if (lower.includes("swiggy") || lower.includes("zomato") || lower.includes("blinkit") || lower.includes("restaurant") || lower.includes("food")) {
      return "Food & Dining";
    }
    if (lower.includes("uber") || lower.includes("ola") || lower.includes("petrol") || lower.includes("fuel") || lower.includes("rapido")) {
      return "Transport";
    }
    if (lower.includes("amazon") || lower.includes("flipkart") || lower.includes("myntra") || lower.includes("nykaa")) {
      return "Shopping";
    }
    return "Miscellaneous";
  }

  static fallbackMerchant(text, sender) {
    const lower = text.toLowerCase();
    if (lower.includes("swiggy")) return "Swiggy";
    if (lower.includes("uber")) return "Uber";
    if (lower.includes("flipkart")) return "Flipkart";
    if (lower.includes("blinkit")) return "Blinkit";
    if (lower.includes("myntra")) return "Myntra";
    return sender.split("-").pop() || "Merchant";
  }
}

// UI Controllers
document.addEventListener("DOMContentLoaded", () => {
  drawCanvasLogo();
  bindEvents();
});

function drawCanvasLogo() {
  const canvas = document.getElementById("logo-canvas");
  if (!canvas) return;
  const ctx = canvas.getContext("2d");
  const w = canvas.width, h = canvas.height;
  const center = w / 2;
  const radius = w * 0.35;

  ctx.clearRect(0, 0, w, h);
  ctx.strokeStyle = "rgba(139, 148, 158, 0.4)";
  ctx.lineWidth = 1.5;
  ctx.beginPath();
  ctx.arc(center, center, radius, 0, Math.PI * 2);
  ctx.stroke();

  ctx.strokeStyle = "rgba(139, 148, 158, 0.8)";
  const tick = 6;
  ctx.beginPath();
  ctx.moveTo(center, center - radius); ctx.lineTo(center, center - radius + tick);
  ctx.moveTo(center, center + radius); ctx.lineTo(center, center + radius - tick);
  ctx.moveTo(center - radius, center); ctx.lineTo(center - radius + tick, center);
  ctx.moveTo(center + radius, center); ctx.lineTo(center + radius - tick, center);
  ctx.stroke();
}

function bindEvents() {
  // Splash Sandbox Init
  document.getElementById("btn-init-sandbox").addEventListener("click", () => {
    state.rawLines = [...sampleJSONLines];
    processLedger();
    state.isInitialized = true;
    
    const badge = document.getElementById("splash-status-badge");
    badge.classList.remove("hidden");
    
    setTimeout(() => {
      switchTab("screen-onboarding");
    }, 600);
  });

  // Onboarding Carousel Navigation
  function setOnboardingStep(idx) {
    [0, 1, 2].forEach(i => {
      const cardEl = document.getElementById(`card-${i}`);
      const dotEl = document.getElementById(`dot-${i}`);
      if (cardEl) cardEl.classList.toggle("active", i === idx);
      if (dotEl) dotEl.classList.toggle("active", i === idx);
    });
  }

  [0, 1, 2].forEach(stepIdx => {
    const dot = document.getElementById(`dot-${stepIdx}`);
    if (dot) {
      dot.addEventListener("click", () => setOnboardingStep(stepIdx));
    }
    const card = document.getElementById(`card-${stepIdx}`);
    if (card) {
      card.addEventListener("click", () => setOnboardingStep((stepIdx + 1) % 3));
    }
  });

  // Onboarding Mandatory Shortcut Addition Handlers
  window.handleShortcutStepClick = function(stepIdx) {
    state.isShortcutAdded = true;
    const payload = `Kharcha Pani Personal Automation Payload:\nLine Format: {"date":"shortcut_date","sender":"shortcut_sender","body":"shortcut_body"}\nTarget File: On My iPhone/KharchaPani/transactional.jsonl`;
    if (navigator.clipboard) {
      navigator.clipboard.writeText(payload);
    }
    
    const banner = document.getElementById("shortcut-added-status");
    if (banner) {
      banner.className = "shortcut-status-banner unlocked";
      banner.textContent = "✓ iOS Shortcut Added & Payload Copied!";
    }
    
    const copyText = document.getElementById("copy-btn-text");
    if (copyText) copyText.textContent = "✓ Copied & Opened Shortcuts!";

    // Deep link attempt to launch native Shortcuts App
    try {
      window.location.href = "shortcuts://";
    } catch(e) {}
  };

  window.handleEnterAppClick = function() {
    if (!state.isShortcutAdded) {
      alert("⚠️ Adding the iOS Shortcut is required!\n\nPlease click any step tile or the 'Copy & Open iOS Shortcuts' button to configure your automation first.");
      const banner = document.getElementById("shortcut-added-status");
      if (banner) banner.classList.add("shake");
      return;
    }
    switchTab("screen-dashboard");
  };

  // Search & Filters in Master Ledger
  document.getElementById("ledger-search-input").addEventListener("input", (e) => {
    state.searchQuery = e.target.value;
    renderLedger();
  });

  document.querySelectorAll(".filter-pills-row .pill").forEach(btn => {
    btn.addEventListener("click", () => {
      document.querySelectorAll(".filter-pills-row .pill").forEach(p => p.classList.remove("active"));
      btn.classList.add("active");
      state.selectedFilter = btn.dataset.filter;
      renderLedger();
    });
  });

  // Regex Live Playground Tester
  document.getElementById("btn-run-regex-test").addEventListener("click", runLiveRegexTest);

  // Add Rule Modal
  document.getElementById("btn-open-add-rule").addEventListener("click", () => {
    document.getElementById("modal-add-rule").classList.remove("hidden");
  });

  document.getElementById("btn-save-new-rule").addEventListener("click", () => {
    const pattern = document.getElementById("new-rule-pattern").value;
    const merchant = document.getElementById("new-rule-merchant").value;
    const category = document.getElementById("new-rule-category").value;

    if (pattern && merchant) {
      state.customRules.push({
        id: "r_" + Date.now(),
        pattern,
        mappedMerchant: merchant,
        targetCategory: category,
        isEnabled: true
      });
      document.getElementById("new-rule-pattern").value = "";
      document.getElementById("new-rule-merchant").value = "";
      closeModal("modal-add-rule");
      processLedger();
      renderRulesList();
    }
  });

  // Settings Actions
  document.getElementById("btn-resync-ledger").addEventListener("click", () => {
    processLedger();
    alert("✓ Local ledger re-synced from transactional.jsonl");
  });

  document.getElementById("btn-export-backup").addEventListener("click", () => {
    const jsonlText = state.rawLines.map(l => JSON.stringify(l)).join("\n");
    const blob = new Blob([jsonlText], { type: "text/plain" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "transactional.jsonl";
    a.click();
  });

  document.getElementById("btn-reopen-onboarding").addEventListener("click", () => {
    switchTab("screen-onboarding");
  });
}

function switchTab(screenId) {
  document.querySelectorAll(".screen-view").forEach(s => s.classList.remove("active"));
  document.querySelectorAll(".tab-item").forEach(t => t.classList.remove("active"));

  const targetScreen = document.getElementById(screenId);
  if (targetScreen) targetScreen.classList.add("active");

  const tabIndexMap = {
    "screen-dashboard": 0,
    "screen-analytics": 1,
    "screen-ledger": 2,
    "screen-settings": 3
  };

  const idx = tabIndexMap[screenId];
  if (idx !== undefined) {
    const tabs = document.querySelectorAll(".tab-item");
    if (tabs[idx]) tabs[idx].classList.add("active");
    
    const pill = document.getElementById("glass-tab-pill");
    if (pill) {
      pill.style.transform = `translateX(${idx * 100}%)`;
    }
  }

  // Refresh view contents
  if (screenId === "screen-dashboard") renderDashboard();
  if (screenId === "screen-analytics") renderAnalytics();
  if (screenId === "screen-ledger") renderLedger();
  if (screenId === "screen-settings") {
    renderRulesList();
    renderSettings();
  }
}

function processLedger() {
  const set = new Set();
  const valid = [];
  for (const line of state.rawLines) {
    const parsed = LocalTransactionParser.parse(line, state.customRules);
    if (parsed && !set.has(parsed.id)) {
      set.add(parsed.id);
      valid.push(parsed);
    }
  }
  state.parsedTransactions = valid.sort((a, b) => b.date - a.date);
}

function renderDashboard() {
  const total = state.parsedTransactions.reduce((acc, t) => acc + t.amount, 0);
  document.getElementById("dash-total-outflow").textContent = `₹${total.toFixed(2)}`;
  document.getElementById("dash-count-chip").textContent = `${state.parsedTransactions.length} Txns`;

  // Categories Breakdown
  const catTotals = { "Food & Dining": 0, "Transport": 0, "Shopping": 0, "Miscellaneous": 0 };
  state.parsedTransactions.forEach(t => { catTotals[t.category] = (catTotals[t.category] || 0) + t.amount; });

  const maxTotal = total > 0 ? total : 1;
  document.getElementById("cat-amt-food").textContent = `₹${(catTotals["Food & Dining"] || 0).toFixed(2)}`;
  document.getElementById("bar-food").style.width = `${((catTotals["Food & Dining"] || 0) / maxTotal) * 100}%`;

  document.getElementById("cat-amt-transport").textContent = `₹${(catTotals["Transport"] || 0).toFixed(2)}`;
  document.getElementById("bar-transport").style.width = `${((catTotals["Transport"] || 0) / maxTotal) * 100}%`;

  document.getElementById("cat-amt-shopping").textContent = `₹${(catTotals["Shopping"] || 0).toFixed(2)}`;
  document.getElementById("bar-shopping").style.width = `${((catTotals["Shopping"] || 0) / maxTotal) * 100}%`;

  document.getElementById("cat-amt-misc").textContent = `₹${(catTotals["Miscellaneous"] || 0).toFixed(2)}`;
  document.getElementById("bar-misc").style.width = `${((catTotals["Miscellaneous"] || 0) / maxTotal) * 100}%`;

  // Recent 5 list
  const listContainer = document.getElementById("dashboard-txns-list");
  listContainer.innerHTML = "";

  state.parsedTransactions.slice(0, 5).forEach(txn => {
    listContainer.appendChild(createTxnCardElement(txn));
  });
}

function createTxnCardElement(txn) {
  const div = document.createElement("div");
  div.className = "txn-card-item";
  div.style.marginBottom = "20px";
  div.style.display = "flex";
  div.innerHTML = `
    <div class="type-circle">${getTypeIcon(txn.type)}</div>
    <div class="txn-info">
      <span class="txn-merchant">${escapeHtml(txn.merchant)}</span>
      <span class="txn-meta">${escapeHtml(txn.type)} • ${escapeHtml(txn.institution)}</span>
    </div>
    <div class="txn-amount-col">
      <span class="txn-amount">-₹${txn.amount.toFixed(2)}</span>
      <span class="txn-cat-tag">${escapeHtml(txn.category)}</span>
    </div>
  `;
  div.addEventListener("click", () => openTxnInspector(txn));
  return div;
}

function renderAnalytics() {
  const total = state.parsedTransactions.reduce((acc, t) => acc + t.amount, 0);
  const uniqueDays = new Set(state.parsedTransactions.map(t => t.date.toDateString())).size;
  const avg = uniqueDays > 0 ? total / uniqueDays : 0;

  document.getElementById("metric-daily-avg").textContent = `₹${avg.toFixed(2)}`;
  document.getElementById("metric-total-logged").textContent = `₹${total.toFixed(2)}`;
  document.getElementById("metric-count-sub").textContent = `${state.parsedTransactions.length} parsed items`;

  // Render Bar Chart
  const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  const dayTotals = { Mon: 0, Tue: 0, Wed: 0, Thu: 0, Fri: 0, Sat: 0, Sun: 0 };

  state.parsedTransactions.forEach(t => {
    const dStr = days[(t.date.getDay() + 6) % 7];
    dayTotals[dStr] = (dayTotals[dStr] || 0) + t.amount;
  });

  const maxVal = Math.max(...Object.values(dayTotals), 1);
  const chartContainer = document.getElementById("bar-chart-container");
  chartContainer.innerHTML = "";

  days.forEach(d => {
    const val = dayTotals[d];
    const pct = Math.max(6, (val / maxVal) * 100);
    const col = document.createElement("div");
    col.className = "chart-bar-col";
    col.innerHTML = `
      <div class="chart-bar-fill" style="height:${pct}%"></div>
      <span class="chart-day-label">${d}</span>
    `;
    chartContainer.appendChild(col);
  });

  // Top Merchants
  const merchantMap = {};
  state.parsedTransactions.forEach(t => {
    if (!merchantMap[t.merchant]) merchantMap[t.merchant] = { total: 0, count: 0 };
    merchantMap[t.merchant].total += t.amount;
    merchantMap[t.merchant].count += 1;
  });

  const sortedMerchants = Object.keys(merchantMap)
    .map(m => ({ merchant: m, total: merchantMap[m].total, count: merchantMap[m].count }))
    .sort((a, b) => b.total - a.total);

  const rankingsContainer = document.getElementById("top-merchants-list");
  rankingsContainer.innerHTML = "";

  sortedMerchants.slice(0, 5).forEach((m, idx) => {
    const row = document.createElement("div");
    row.className = "ranking-item";
    row.innerHTML = `
      <span class="chart-tag">#${idx + 1}</span>
      <div style="flex:1; margin: 0 10px;">
        <strong>${escapeHtml(m.merchant)}</strong>
        <div class="subtext">${m.count} orders tracked</div>
      </div>
      <strong>₹${m.total.toFixed(2)}</strong>
    `;
    rankingsContainer.appendChild(row);
  });
}

function renderLedger() {
  const filtered = state.parsedTransactions.filter(t => {
    const matchesSearch = !state.searchQuery ||
      t.merchant.toLowerCase().includes(state.searchQuery.toLowerCase()) ||
      t.institution.toLowerCase().includes(state.searchQuery.toLowerCase()) ||
      t.category.toLowerCase().includes(state.searchQuery.toLowerCase());

    const matchesFilter = state.selectedFilter === "all" || t.type === state.selectedFilter;
    return matchesSearch && matchesFilter;
  });

  document.getElementById("ledger-subtitle").textContent = `${filtered.length} of ${state.parsedTransactions.length} records`;

  const container = document.getElementById("master-ledger-list");
  container.innerHTML = "";

  filtered.forEach(txn => {
    container.appendChild(createTxnCardElement(txn));
  });
}

function renderRulesList() {
  const container = document.getElementById("rules-list-container");
  container.innerHTML = "";

  state.customRules.forEach(rule => {
    const div = document.createElement("div");
    div.className = "ranking-item";
    div.style.flexDirection = "column";
    div.style.alignItems = "flex-start";
    div.style.gap = "6px";
    div.innerHTML = `
      <div style="display:flex; justify-content:space-between; width:100%;">
        <strong>${escapeHtml(rule.mappedMerchant)}</strong>
        <span class="subtext">${rule.targetCategory}</span>
      </div>
      <div class="code" style="color:var(--accent-blue); font-size:11px;">PATTERN: ${escapeHtml(rule.pattern)}</div>
    `;
    container.appendChild(div);
  });
}

function renderSettings() {
  const sizeKB = (state.rawLines.length * 120 / 1024).toFixed(1);
  document.getElementById("settings-file-size").textContent = `${sizeKB} KB`;
  document.getElementById("settings-line-count").textContent = `${state.rawLines.length} JSON lines`;
}

function runLiveRegexTest() {
  const text = document.getElementById("test-sms-text").value;
  const pattern = document.getElementById("test-regex-pattern").value;
  const resultBox = document.getElementById("test-result-box");

  try {
    const rx = new RegExp(pattern, "i");
    const match = text.match(rx);
    if (match && match[1]) {
      resultBox.style.color = "var(--accent-green)";
      resultBox.textContent = `Extracted Match: "${match[1]}"`;
    } else {
      resultBox.style.color = "var(--accent-outflow)";
      resultBox.textContent = "No capture group match found.";
    }
  } catch (e) {
    resultBox.style.color = "var(--accent-outflow)";
    resultBox.textContent = `Invalid Regex: ${e.message}`;
  }
}

function openTxnInspector(txn) {
  const body = document.getElementById("modal-detail-body");
  body.innerHTML = `
    <div style="display:flex; flex-direction:column; gap:10px;">
      <div><span class="chart-tag">PARSED MERCHANT</span><div><strong>${escapeHtml(txn.merchant)}</strong></div></div>
      <div><span class="chart-tag">AMOUNT</span><div><strong>₹${txn.amount.toFixed(2)}</strong></div></div>
      <div><span class="chart-tag">ACCOUNT CLASSIFICATION</span><div>${escapeHtml(txn.type)} (${escapeHtml(txn.institution)})</div></div>
      <div><span class="chart-tag">RAW SMS SENDER</span><div><code>${escapeHtml(txn.rawSender)}</code></div></div>
      <div>
        <span class="chart-tag">RAW SMS TEXT BODY</span>
        <div class="code-box" style="margin-top:4px;">${escapeHtml(txn.rawBody)}</div>
      </div>
    </div>
  `;
  document.getElementById("modal-detail").classList.remove("hidden");
}

function closeModal(modalId) {
  document.getElementById(modalId).classList.add("hidden");
}

function getTypeIcon(type) {
  switch (type) {
    case "UPI": return "📱";
    case "Debit Card": return "💳";
    case "Credit Card": return "💳";
    default: return "🏛️";
  }
}

function escapeHtml(str) {
  return String(str || "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}
