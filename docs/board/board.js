const STORAGE_KEY = "cat-dice-kanban-v1";
const CARDS_URL = "cards.json";

/** @type {{ updated?: string, source?: string, columns: Array<{id:string,title:string}>, cards: Array<object> }} */
let boardData = null;

const boardEl = document.getElementById("board");
const metaEl = document.getElementById("meta");

function toast(message) {
  let el = document.querySelector(".toast");
  if (!el) {
    el = document.createElement("div");
    el.className = "toast";
    document.body.appendChild(el);
  }
  el.textContent = message;
  el.classList.add("show");
  clearTimeout(toast._t);
  toast._t = setTimeout(() => el.classList.remove("show"), 1800);
}

function cloneData(data) {
  return JSON.parse(JSON.stringify(data));
}

function saveLocal() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(boardData));
}

function clearLocal() {
  localStorage.removeItem(STORAGE_KEY);
}

function loadLocal() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return null;
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

function exportPayload() {
  return {
    updated: new Date().toISOString().slice(0, 10),
    source: boardData.source || "docs/backlog.md",
    columns: boardData.columns,
    cards: boardData.cards,
  };
}

function updateMeta(fromLocal) {
  const n = boardData.cards.length;
  const stamp = boardData.updated || "—";
  metaEl.textContent = fromLocal
    ? `임시 저장 · ${n}장 · 원본 ${stamp}`
    : `저장소 JSON · ${n}장 · ${stamp}`;
}

function cardsInColumn(columnId) {
  return boardData.cards.filter((c) => c.column === columnId);
}

function render() {
  boardEl.innerHTML = "";
  for (const col of boardData.columns) {
    const cards = cardsInColumn(col.id);
    const column = document.createElement("section");
    column.className = "column";
    column.dataset.col = col.id;

    column.innerHTML = `
      <div class="column-head">
        <div class="column-title"><span class="dot" aria-hidden="true"></span>${escapeHtml(col.title)}</div>
        <span class="count">${cards.length}</span>
      </div>
      <div class="cards" data-column="${col.id}"></div>
    `;

    const list = column.querySelector(".cards");
    for (const card of cards) {
      list.appendChild(renderCard(card));
    }

    list.addEventListener("dragover", onDragOver);
    list.addEventListener("dragleave", onDragLeave);
    list.addEventListener("drop", onDrop);
    boardEl.appendChild(column);
  }
}

function renderCard(card) {
  const el = document.createElement("article");
  el.className = "card";
  el.draggable = true;
  el.dataset.id = card.id;

  const tags = (card.tags || [])
    .map((t) => `<span class="tag">${escapeHtml(t)}</span>`)
    .join("");

  el.innerHTML = `
    <h3 class="card-title">${escapeHtml(card.title)}</h3>
    ${card.body ? `<p class="card-body">${escapeHtml(card.body)}</p>` : ""}
    ${tags ? `<div class="tags">${tags}</div>` : ""}
  `;

  el.addEventListener("dragstart", onDragStart);
  el.addEventListener("dragend", onDragEnd);
  return el;
}

function escapeHtml(text) {
  return String(text)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

let dragId = null;

function onDragStart(e) {
  dragId = e.currentTarget.dataset.id;
  e.currentTarget.classList.add("dragging");
  e.dataTransfer.effectAllowed = "move";
  e.dataTransfer.setData("text/plain", dragId);
}

function onDragEnd(e) {
  e.currentTarget.classList.remove("dragging");
  dragId = null;
  document.querySelectorAll(".column.drag-over").forEach((c) => c.classList.remove("drag-over"));
}

function onDragOver(e) {
  e.preventDefault();
  e.dataTransfer.dropEffect = "move";
  e.currentTarget.closest(".column")?.classList.add("drag-over");
}

function onDragLeave(e) {
  if (!e.currentTarget.contains(e.relatedTarget)) {
    e.currentTarget.closest(".column")?.classList.remove("drag-over");
  }
}

function onDrop(e) {
  e.preventDefault();
  const column = e.currentTarget.closest(".column");
  column?.classList.remove("drag-over");
  const id = e.dataTransfer.getData("text/plain") || dragId;
  const nextCol = e.currentTarget.dataset.column;
  if (!id || !nextCol) return;

  const card = boardData.cards.find((c) => c.id === id);
  if (!card || card.column === nextCol) return;

  card.column = nextCol;
  saveLocal();
  updateMeta(true);
  render();
  toast(`「${card.title}」 → ${columnTitle(nextCol)}`);
}

function columnTitle(id) {
  return boardData.columns.find((c) => c.id === id)?.title || id;
}

async function copyJson() {
  const text = JSON.stringify(exportPayload(), null, 2);
  try {
    await navigator.clipboard.writeText(text);
    toast("JSON을 클립보드에 복사했습니다");
  } catch {
    prompt("복사할 JSON:", text);
  }
}

function downloadJson() {
  const blob = new Blob([JSON.stringify(exportPayload(), null, 2)], {
    type: "application/json",
  });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = "cards.json";
  a.click();
  URL.revokeObjectURL(url);
  toast("cards.json 다운로드");
}

async function boot() {
  const res = await fetch(CARDS_URL, { cache: "no-store" });
  if (!res.ok) throw new Error(`cards.json load failed: ${res.status}`);
  const remote = await res.json();
  const local = loadLocal();

  if (local && Array.isArray(local.cards) && Array.isArray(local.columns)) {
    boardData = local;
    updateMeta(true);
  } else {
    boardData = cloneData(remote);
    updateMeta(false);
  }

  render();
}

document.getElementById("btn-copy").addEventListener("click", copyJson);
document.getElementById("btn-download").addEventListener("click", downloadJson);
document.getElementById("btn-reset").addEventListener("click", async () => {
  clearLocal();
  const res = await fetch(CARDS_URL, { cache: "no-store" });
  boardData = cloneData(await res.json());
  updateMeta(false);
  render();
  toast("저장소 JSON으로 되돌렸습니다");
});

boot().catch((err) => {
  boardEl.innerHTML = `<p class="hint">보드를 불러오지 못했습니다: ${escapeHtml(err.message)}</p>`;
  console.error(err);
});
