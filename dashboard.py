#!/usr/bin/env python3
"""
code-harness dashboard — read-only visualization of harness state.
Usage: python dashboard.py /path/to/project [--port 5000]
"""

import csv
import io
import re
import glob as globmod
import argparse
from pathlib import Path
from flask import Flask, jsonify, Response

app = Flask(__name__)
PROJECT = Path(".")


def parse_tasks():
    """Parse .harness/tasks.md into structured task list."""
    path = PROJECT / ".harness" / "tasks.md"
    if not path.exists():
        return {"active": [], "backlog": [], "done": [], "summary": {}}

    text = path.read_text()
    tasks = []
    current_section = "active"

    section_re = re.compile(r"^##\s+(Active|Backlog|Done)", re.IGNORECASE)
    task_re = re.compile(
        r"^- \[(?P<check>[ x~])\]\s+(?P<id>T\d+):\s+(?P<title>.+?)(?:\s+\[(?P<meta>[^\]]+)\])*\s*$"
    )
    backlog_re = re.compile(
        r"^- (?P<id>T\d+):\s+(?P<title>.+?)(?:\s+\[(?P<meta>[^\]]+)\])*\s*$"
    )

    for line in text.splitlines():
        sm = section_re.match(line)
        if sm:
            current_section = sm.group(1).lower()
            continue

        tm = task_re.match(line)
        if not tm:
            tm = backlog_re.match(line)
            if tm:
                # Backlog items have no checkbox
                task = {
                    "id": tm.group("id"),
                    "title": tm.group("title").strip(),
                    "status": "backlog",
                    "section": current_section,
                    "mode": None,
                    "claimed_by": None,
                    "blocked_by": None,
                    "owns": None,
                }
                # Parse meta from rest of title
                meta_str = line[line.index(tm.group("id")):]
                _parse_meta(task, meta_str)
                tasks.append(task)
            continue

        check = tm.group("check")
        status = {"x": "done", "~": "claimed", " ": "pending"}[check]

        task = {
            "id": tm.group("id"),
            "title": tm.group("title").strip(),
            "status": status,
            "section": current_section,
            "mode": None,
            "claimed_by": None,
            "blocked_by": None,
            "owns": None,
            "done_by": None,
        }

        # Parse inline metadata
        meta_str = line[line.index(tm.group("id")):]
        _parse_meta(task, meta_str)

        # blocked overrides pending
        if task["blocked_by"] and status == "pending":
            task["status"] = "blocked"

        tasks.append(task)

    active = [t for t in tasks if t["section"] == "active"]
    backlog = [t for t in tasks if t["section"] == "backlog"]
    done = [t for t in tasks if t["section"] == "done"]

    summary = {
        "pending": sum(1 for t in tasks if t["status"] == "pending"),
        "claimed": sum(1 for t in tasks if t["status"] == "claimed"),
        "done": sum(1 for t in tasks if t["status"] == "done"),
        "blocked": sum(1 for t in tasks if t["status"] == "blocked"),
        "backlog": len(backlog),
    }

    return {"active": active, "backlog": backlog, "done": done, "summary": summary}


def _parse_meta(task, text):
    """Extract mode, claimed, blocked, done, owns from inline metadata."""
    mode_m = re.search(r"mode:\s*(\w+)", text)
    if mode_m:
        task["mode"] = mode_m.group(1)

    claimed_m = re.search(r"claimed:\s*(\w+)", text)
    if claimed_m:
        task["claimed_by"] = claimed_m.group(1)

    blocked_m = re.search(r"blocked by (D\d+)", text)
    if blocked_m:
        task["blocked_by"] = blocked_m.group(1)

    done_m = re.search(r"done:\s*(\w+)", text)
    if done_m:
        task["done_by"] = done_m.group(1)

    owns_m = re.search(r"owns:\s*(.+?)(?:\]|$)", text)
    if owns_m:
        task["owns"] = owns_m.group(1).strip()


def parse_decisions():
    """Parse .harness/decisions.md into pending/resolved lists."""
    path = PROJECT / ".harness" / "decisions.md"
    if not path.exists():
        return {"pending": [], "resolved": []}

    text = path.read_text()
    decisions = []
    section = "pending"

    # Split by ### D<id> headers
    parts = re.split(r"(?=^### D\d+)", text, flags=re.MULTILINE)

    for part in parts:
        header_m = re.match(
            r"^### (D\d+)\s+\[(\w+)\]\s+(\S+)(?:\s+→\s+resolved\s+(\S+))?",
            part,
        )
        if not header_m:
            if "## Pending" in part:
                section = "pending"
            elif "## Resolved" in part:
                section = "resolved"
            continue

        did = header_m.group(1)
        category = header_m.group(2)
        created = header_m.group(3)
        resolved_at = header_m.group(4)

        lines = part.strip().splitlines()
        question = lines[1].strip() if len(lines) > 1 else ""
        blocks_m = re.search(r"Blocks:\s*(T\d+(?:,\s*T\d+)*)", part)
        blocks = blocks_m.group(1) if blocks_m else None

        status = "resolved" if resolved_at else section

        decisions.append({
            "id": did,
            "category": category,
            "created": created,
            "resolved_at": resolved_at,
            "question": question[:120],
            "blocks": blocks,
            "status": status,
        })

    pending = [d for d in decisions if d["status"] == "pending"]
    resolved = [d for d in decisions if d["status"] == "resolved"]
    return {"pending": pending, "resolved": resolved}


def parse_log():
    """Parse .harness/log.tsv into entries and stats."""
    path = PROJECT / ".harness" / "log.tsv"
    if not path.exists():
        return {"entries": [], "stats": {}}

    text = path.read_text().strip()
    if not text:
        return {"entries": [], "stats": {}}

    reader = csv.DictReader(io.StringIO(text), delimiter="\t")
    entries = []
    fail_counts = {}
    missed_counts = {}
    total = 0
    passes = 0
    fails = 0

    for row in reader:
        entries.append(row)
        total += 1
        cf = row.get("criteria_fail", "").strip()
        cm = row.get("criteria_missed", "").strip()
        status = row.get("status", "").strip()

        if status == "pass" or (not cf and not cm):
            passes += 1
        else:
            fails += 1

        if cf and cf != "-":
            for std in cf.split(","):
                std = std.strip()
                fail_counts[std] = fail_counts.get(std, 0) + 1
        if cm and cm != "-":
            for std in cm.split(","):
                std = std.strip()
                missed_counts[std] = missed_counts.get(std, 0) + 1

    top_failures = sorted(fail_counts.items(), key=lambda x: -x[1])[:5]
    top_missed = sorted(missed_counts.items(), key=lambda x: -x[1])[:5]

    return {
        "entries": entries[-50:],  # last 50
        "stats": {
            "total": total,
            "passes": passes,
            "fails": fails,
            "pass_rate": f"{passes / total * 100:.0f}%" if total else "N/A",
            "top_failures": [{"id": k, "count": v} for k, v in top_failures],
            "top_missed": [{"id": k, "count": v} for k, v in top_missed],
        },
    }


def parse_standards():
    """Parse .claude/rules/*.md and .harness/inbox.md for standards."""
    rules_dir = PROJECT / ".claude" / "rules"
    files = []

    if rules_dir.exists():
        for f in sorted(rules_dir.glob("*.md")):
            if f.name == "playbook.md":
                continue
            text = f.read_text()
            # Strip HTML comments to avoid matching commented-out standards
            text = re.sub(r"<!--.*?-->", "", text, flags=re.DOTALL)
            standards = []
            for m in re.finditer(
                r"^## ([A-Z]\d+):\s*(.+?)$", text, re.MULTILINE
            ):
                sid = m.group(1)
                title = m.group(2).strip()
                # Find weight and source after this header
                block_start = m.end()
                next_header = re.search(r"^## ", text[block_start:], re.MULTILINE)
                block = text[block_start: block_start + next_header.start()] if next_header else text[block_start:]
                weight_m = re.search(r"weight:\s*(\w+)", block)
                source_m = re.search(r"source:\s*(.+)", block)
                standards.append({
                    "id": sid,
                    "title": title,
                    "weight": weight_m.group(1) if weight_m else "medium",
                    "source": source_m.group(1).strip() if source_m else "base",
                })
            files.append({"name": f.name, "standards": standards})

    # Parse inbox drafts
    drafts = []
    inbox = PROJECT / ".harness" / "inbox.md"
    if inbox.exists():
        text = inbox.read_text()
        for m in re.finditer(
            r"^## (DRAFT-[A-Z]\d+):\s*(.+?)$", text, re.MULTILINE
        ):
            drafts.append({"id": m.group(1), "title": m.group(2).strip()})

    return {"files": files, "drafts": drafts}


def parse_machines(tasks_data):
    """Extract multi-machine status from parsed tasks."""
    machines = {}
    for section in ("active", "done"):
        for t in tasks_data.get(section, []):
            mid = t.get("claimed_by") or t.get("done_by")
            if not mid:
                continue
            if mid not in machines:
                machines[mid] = {"id": mid, "current_task": None, "tasks_done": 0, "last_active": None}
            if t["status"] == "claimed":
                machines[mid]["current_task"] = t["id"]
            if t["status"] == "done":
                machines[mid]["tasks_done"] += 1
    return list(machines.values())


# ── HTML ──

HTML = """<!DOCTYPE html>
<html lang="zh">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>code-harness dashboard</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
         background: #0d1117; color: #e6edf3; min-height: 100vh; display: flex; flex-direction: column; }

  .header { padding: 14px 28px; border-bottom: 1px solid #21262d; flex-shrink: 0;
            display: flex; align-items: center; justify-content: space-between; }
  .header h1 { font-size: 16px; font-weight: 600; }
  .header .project-name { color: #58a6ff; margin-left: 8px; }
  .header .updated { font-size: 12px; color: #7d8590; }
  .refresh-btn { background: #21262d; border: 1px solid #30363d; color: #e6edf3;
                 padding: 5px 12px; border-radius: 6px; cursor: pointer; font-size: 12px; }
  .refresh-btn:hover { background: #30363d; }

  .stats-bar { display: grid; grid-template-columns: repeat(6, 1fr); gap: 12px;
               padding: 16px 28px; border-bottom: 1px solid #21262d; flex-shrink: 0; }
  @media (max-width: 1100px) { .stats-bar { grid-template-columns: repeat(3, 1fr); } }
  @media (max-width: 600px)  { .stats-bar { grid-template-columns: repeat(2, 1fr); padding: 12px 16px; gap: 8px; } }
  .stat-card { background: #161b22; border: 1px solid #21262d; border-radius: 8px; padding: 12px 16px; }
  .stat-card .label { font-size: 11px; color: #7d8590; margin-bottom: 6px; text-transform: uppercase; letter-spacing: .5px; }
  .stat-card .value { font-size: 24px; font-weight: 700; }
  .stat-card .value.green  { color: #3fb950; }
  .stat-card .value.yellow { color: #d29922; }
  .stat-card .value.red    { color: #f85149; }
  .stat-card .value.blue   { color: #58a6ff; }
  .stat-card .value.muted  { font-size: 14px; color: #7d8590; padding-top: 4px; }

  .main { display: flex; flex: 1; overflow: hidden; }
  .sidebar { width: 320px; flex-shrink: 0; border-right: 1px solid #21262d;
             overflow-y: auto; padding: 16px; display: flex; flex-direction: column; gap: 14px; }
  .content { flex: 1; overflow-y: auto; padding: 16px 20px; display: flex; flex-direction: column; gap: 14px; }
  @media (max-width: 900px) {
    .main { flex-direction: column; overflow: auto; }
    .sidebar { width: 100%; border-right: none; border-bottom: 1px solid #21262d;
               overflow-y: visible; padding: 12px 16px; }
    .content { overflow-y: visible; padding: 12px 16px; }
  }

  .section { background: #161b22; border: 1px solid #21262d; border-radius: 8px; padding: 16px; }
  .section h2 { font-size: 13px; font-weight: 600; margin-bottom: 12px;
                padding-bottom: 10px; border-bottom: 1px solid #21262d;
                text-transform: uppercase; letter-spacing: .5px; color: #7d8590; }

  .machine-card { background: #0d1117; border: 1px solid #21262d; border-radius: 6px;
                  padding: 12px; margin-bottom: 8px; }
  .machine-card:last-child { margin-bottom: 0; }
  .machine-card.active { border-color: #3fb950; }
  .machine-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 8px; }
  .machine-name { font-size: 13px; font-weight: 600; }
  .machine-dot { width: 7px; height: 7px; border-radius: 50%; }
  .machine-dot.active { background: #3fb950; box-shadow: 0 0 5px #3fb950; animation: pulse 1.5s infinite; }
  .machine-dot.idle   { background: #7d8590; }
  @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:.4} }
  .kv { display: flex; justify-content: space-between; font-size: 11px; padding: 3px 0; border-bottom: 1px solid #21262d; }
  .kv:last-child { border-bottom: none; }
  .kv .k { color: #7d8590; }
  .kv .v { color: #e6edf3; }

  .std-file { margin-bottom: 10px; }
  .std-file .fname { font-size: 12px; color: #58a6ff; margin-bottom: 4px; }
  .std-list { font-size: 11px; color: #7d8590; line-height: 1.8; }
  .std-list .sid { color: #e6edf3; font-weight: 600; margin-right: 4px; }
  .std-list .w-high { color: #f85149; }
  .std-list .w-medium { color: #d29922; }
  .std-list .w-low { color: #7d8590; }

  .table-wrap { overflow-x: auto; -webkit-overflow-scrolling: touch; }
  table { width: 100%; border-collapse: collapse; font-size: 13px; min-width: 480px; }
  th { text-align: left; padding: 8px 12px; color: #7d8590; font-weight: 500;
       font-size: 12px; border-bottom: 1px solid #21262d; white-space: nowrap; }
  td { padding: 10px 12px; border-bottom: 1px solid #161b22; vertical-align: middle; }
  tr:last-child td { border-bottom: none; }
  tr:hover td { background: #1c2128; }
  .badge { display: inline-block; padding: 2px 8px; border-radius: 12px; font-size: 11px; font-weight: 600; }
  .badge-pending  { background: #388bfd26; color: #58a6ff; }
  .badge-claimed  { background: #d2992226; color: #d29922; }
  .badge-done     { background: #3fb95026; color: #3fb950; }
  .badge-blocked  { background: #f8514926; color: #f85149; }
  .badge-backlog  { background: #21262d; color: #7d8590; }
  .badge-resolved { background: #3fb95026; color: #3fb950; }
  .badge-pass     { background: #3fb95026; color: #3fb950; }
  .badge-fail     { background: #f8514926; color: #f85149; }
  .badge-single   { background: #21262d; color: #7d8590; }
  .badge-parallel { background: #8957e526; color: #bc8cff; }
  .badge-team     { background: #388bfd26; color: #58a6ff; }
  .badge-swarm    { background: #d2992226; color: #d29922; }
  .heatmap { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 8px; }
  .heat-item { padding: 4px 8px; border-radius: 4px; font-size: 11px; font-weight: 600; }
  .heat-1 { background: #f8514920; color: #f85149; }
  .heat-2 { background: #f8514940; color: #f85149; }
  .heat-3 { background: #f8514960; color: #f85149; }
  .none-tip { color: #7d8590; font-size: 13px; text-align: center; padding: 24px; }
  a { color: #58a6ff; text-decoration: none; }
  a:hover { text-decoration: underline; }
</style>
</head>
<body>
<div class="header">
  <h1>code-harness<span class="project-name" id="project-name"></span></h1>
  <div style="display:flex;align-items:center;gap:12px;">
    <span class="updated" id="ts"></span>
    <button class="refresh-btn" onclick="loadAll()">&#8635; refresh</button>
  </div>
</div>
<div class="stats-bar" id="stats"></div>
<div class="main">
  <div class="sidebar">
    <div class="section">
      <h2>Machines</h2>
      <div id="machines-wrap"></div>
    </div>
    <div class="section">
      <h2>Standards</h2>
      <div id="standards-wrap"></div>
    </div>
  </div>
  <div class="content">
    <div class="section">
      <h2>Tasks</h2>
      <div id="tasks-wrap"></div>
    </div>
    <div class="section">
      <h2>Decisions</h2>
      <div id="decisions-wrap"></div>
    </div>
    <div class="section">
      <h2>Evaluator Log</h2>
      <div id="log-wrap"></div>
    </div>
  </div>
</div>

<script>
function esc(s) { return String(s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }
function badge(cls, text) { return `<span class="badge badge-${cls}">${esc(text)}</span>`; }

async function loadAll() {
  document.getElementById('ts').textContent = 'updated ' + new Date().toLocaleTimeString();
  const [tasks, decisions, log, standards, machines] = await Promise.all([
    fetch('/api/tasks').then(r=>r.json()),
    fetch('/api/decisions').then(r=>r.json()),
    fetch('/api/log').then(r=>r.json()),
    fetch('/api/standards').then(r=>r.json()),
    fetch('/api/machines').then(r=>r.json()),
  ]);
  renderStats(tasks.summary, decisions, log.stats);
  renderMachines(machines);
  renderStandards(standards);
  renderTasks(tasks);
  renderDecisions(decisions);
  renderLog(log);
}

function renderStats(s, d, ls) {
  document.getElementById('stats').innerHTML = `
    <div class="stat-card"><div class="label">Pending</div><div class="value blue">${s.pending||0}</div></div>
    <div class="stat-card"><div class="label">In Progress</div><div class="value yellow">${s.claimed||0}</div></div>
    <div class="stat-card"><div class="label">Done</div><div class="value green">${s.done||0}</div></div>
    <div class="stat-card"><div class="label">Blocked</div><div class="value red">${s.blocked||0}</div></div>
    <div class="stat-card"><div class="label">Pending Decisions</div><div class="value red">${d.pending?.length||0}</div></div>
    <div class="stat-card"><div class="label">Pass Rate</div><div class="value green">${ls.pass_rate||'N/A'}</div></div>
  `;
}

function renderMachines(machines) {
  const wrap = document.getElementById('machines-wrap');
  if (!machines.length) { wrap.innerHTML = '<p class="none-tip">Single machine (no MACHINE_ID)</p>'; return; }
  wrap.innerHTML = machines.map(m => `
    <div class="machine-card ${m.current_task ? 'active' : ''}">
      <div class="machine-header">
        <span class="machine-name">Machine ${esc(m.id)}</span>
        <span class="machine-dot ${m.current_task ? 'active' : 'idle'}"></span>
      </div>
      <div class="kv"><span class="k">Current</span><span class="v">${m.current_task || 'idle'}</span></div>
      <div class="kv"><span class="k">Completed</span><span class="v">${m.tasks_done}</span></div>
    </div>`).join('');
}

function renderStandards(data) {
  const wrap = document.getElementById('standards-wrap');
  let html = '';
  data.files.forEach(f => {
    html += `<div class="std-file"><div class="fname">${esc(f.name)}</div><div class="std-list">`;
    f.standards.forEach(s => {
      html += `<div><span class="sid">${esc(s.id)}</span> <span class="w-${s.weight}">[${s.weight}]</span> ${esc(s.title)}</div>`;
    });
    html += '</div></div>';
  });
  if (data.drafts.length) {
    html += '<div class="std-file"><div class="fname">inbox (drafts)</div><div class="std-list">';
    data.drafts.forEach(d => {
      html += `<div><span class="sid">${esc(d.id)}</span> ${esc(d.title)}</div>`;
    });
    html += '</div></div>';
  }
  wrap.innerHTML = html || '<p class="none-tip">No standards found</p>';
}

function renderTasks(data) {
  const all = [...data.active, ...data.backlog, ...data.done];
  if (!all.length) { document.getElementById('tasks-wrap').innerHTML = '<p class="none-tip">No tasks</p>'; return; }
  const rows = all.map(t => `
    <tr>
      <td><strong>${esc(t.id)}</strong></td>
      <td>${esc(t.title)}</td>
      <td>${t.mode ? badge(t.mode, t.mode) : ''}</td>
      <td>${badge(t.status, t.status)}</td>
      <td>${t.claimed_by || t.done_by || ''}</td>
      <td>${t.blocked_by || ''}</td>
    </tr>`).join('');
  document.getElementById('tasks-wrap').innerHTML = `
    <div class="table-wrap"><table><thead><tr>
      <th>ID</th><th>Title</th><th>Mode</th><th>Status</th><th>Machine</th><th>Blocked By</th>
    </tr></thead><tbody>${rows}</tbody></table></div>`;
}

function renderDecisions(data) {
  const all = [...data.pending, ...data.resolved];
  if (!all.length) { document.getElementById('decisions-wrap').innerHTML = '<p class="none-tip">No decisions</p>'; return; }
  const rows = all.map(d => `
    <tr>
      <td><strong>${esc(d.id)}</strong></td>
      <td>${badge(d.category, d.category)}</td>
      <td>${esc(d.question)}</td>
      <td>${badge(d.status, d.status)}</td>
      <td>${d.blocks || ''}</td>
    </tr>`).join('');
  document.getElementById('decisions-wrap').innerHTML = `
    <div class="table-wrap"><table><thead><tr>
      <th>ID</th><th>Category</th><th>Question</th><th>Status</th><th>Blocks</th>
    </tr></thead><tbody>${rows}</tbody></table></div>`;
}

function renderLog(data) {
  const wrap = document.getElementById('log-wrap');
  const entries = data.entries || [];
  const stats = data.stats || {};

  let html = '';

  // Heatmap of top failures
  if (stats.top_failures?.length) {
    html += '<div style="margin-bottom:12px"><span style="font-size:12px;color:#7d8590">Top failures:</span><div class="heatmap">';
    stats.top_failures.forEach(f => {
      const cls = f.count >= 5 ? 'heat-3' : f.count >= 3 ? 'heat-2' : 'heat-1';
      html += `<span class="heat-item ${cls}">${esc(f.id)} (${f.count})</span>`;
    });
    html += '</div></div>';
  }

  if (!entries.length) { wrap.innerHTML = html + '<p class="none-tip">No evaluator log entries</p>'; return; }

  const rows = entries.slice(-20).reverse().map(e => `
    <tr>
      <td>${esc(e.date)}</td>
      <td>${esc(e.task)}</td>
      <td>${e.criteria_pass && e.criteria_pass !== '-' ? esc(e.criteria_pass) : ''}</td>
      <td>${e.criteria_fail && e.criteria_fail !== '-' ? esc(e.criteria_fail) : ''}</td>
      <td>${badge(e.status === 'pass' ? 'pass' : 'fail', e.status)}</td>
    </tr>`).join('');
  html += `<div class="table-wrap"><table><thead><tr>
    <th>Date</th><th>Task</th><th>Pass</th><th>Fail</th><th>Status</th>
  </tr></thead><tbody>${rows}</tbody></table></div>`;
  wrap.innerHTML = html;
}

document.getElementById('project-name').textContent = ' — ' + (new URLSearchParams(location.search).get('p') || '""PROJ_NAME""');
loadAll();
setInterval(loadAll, 15000);
</script>
</body>
</html>
"""


@app.route("/")
def index():
    html = HTML.replace('""PROJ_NAME""', str(PROJECT.resolve().name))
    return Response(html, mimetype="text/html")


@app.route("/api/tasks")
def api_tasks():
    return jsonify(parse_tasks())


@app.route("/api/decisions")
def api_decisions():
    return jsonify(parse_decisions())


@app.route("/api/log")
def api_log():
    return jsonify(parse_log())


@app.route("/api/standards")
def api_standards():
    return jsonify(parse_standards())


@app.route("/api/machines")
def api_machines():
    tasks_data = parse_tasks()
    return jsonify(parse_machines(tasks_data))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="code-harness dashboard")
    parser.add_argument("project", nargs="?", default=".", help="Path to project with code-harness installed")
    parser.add_argument("--port", type=int, default=5000)
    parser.add_argument("--host", default="0.0.0.0")
    args = parser.parse_args()

    PROJECT = Path(args.project).resolve()
    if not (PROJECT / ".harness").exists():
        print(f"Error: {PROJECT} does not have .harness/ directory")
        exit(1)

    print(f"code-harness dashboard: http://{args.host}:{args.port}")
    print(f"Project: {PROJECT}")
    app.run(host=args.host, port=args.port, debug=False)
