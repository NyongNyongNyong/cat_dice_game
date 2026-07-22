(() => {
  const catalogEl = document.getElementById("catalog");
  const tocEl = document.getElementById("toc");
  const metaEl = document.getElementById("meta");
  const modal = document.getElementById("modal");
  const modalTitle = document.getElementById("modal-title");
  const modalBody = document.getElementById("modal-body");
  const modalGithub = document.getElementById("modal-github");
  const btnClose = document.getElementById("modal-close");

  function escapeHtml(text) {
    return String(text)
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;");
  }

  function renderInline(text) {
    let s = escapeHtml(text);
    s = s.replace(/`([^`]+)`/g, "<code>$1</code>");
    s = s.replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>");
    s = s.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" target="_blank" rel="noopener">$1</a>');
    return s;
  }

  function renderMarkdown(md) {
    const lines = md.replace(/\r\n/g, "\n").split("\n");
    const out = [];
    let i = 0;
    let inCode = false;
    let codeLang = "";
    let codeLines = [];
    let inUl = false;
    let inOl = false;
    let inTable = false;
    let tableRows = [];

    const closeLists = () => {
      if (inUl) { out.push("</ul>"); inUl = false; }
      if (inOl) { out.push("</ol>"); inOl = false; }
    };

    const flushTable = () => {
      if (!inTable) return;
      out.push("<table>");
      tableRows.forEach((row, idx) => {
        const cells = row.split("|").slice(1, -1).map((c) => c.trim());
        if (idx === 1 && cells.every((c) => /^:?-+:?$/.test(c))) return;
        const tag = idx === 0 ? "th" : "td";
        out.push("<tr>" + cells.map((c) => `<${tag}>${renderInline(c)}</${tag}>`).join("") + "</tr>");
      });
      out.push("</table>");
      inTable = false;
      tableRows = [];
    };

    while (i < lines.length) {
      const line = lines[i];

      if (line.startsWith("```")) {
        closeLists();
        flushTable();
        if (!inCode) {
          inCode = true;
          codeLang = line.slice(3).trim();
          codeLines = [];
        } else {
          out.push(`<pre><code class="language-${escapeHtml(codeLang)}">${escapeHtml(codeLines.join("\n"))}</code></pre>`);
          inCode = false;
        }
        i += 1;
        continue;
      }

      if (inCode) {
        codeLines.push(line);
        i += 1;
        continue;
      }

      if (line.trim().startsWith("|") && line.trim().endsWith("|")) {
        closeLists();
        if (!inTable) inTable = true;
        tableRows.push(line.trim());
        i += 1;
        continue;
      } else {
        flushTable();
      }

      if (/^---+$/.test(line.trim())) {
        closeLists();
        out.push("<hr />");
        i += 1;
        continue;
      }

      const heading = /^(#{1,3})\s+(.*)$/.exec(line);
      if (heading) {
        closeLists();
        const level = heading[1].length;
        out.push(`<h${level}>${renderInline(heading[2])}</h${level}>`);
        i += 1;
        continue;
      }

      if (/^>\s?/.test(line)) {
        closeLists();
        const quote = [];
        while (i < lines.length && /^>\s?/.test(lines[i])) {
          quote.push(lines[i].replace(/^>\s?/, ""));
          i += 1;
        }
        out.push(`<blockquote><p>${renderInline(quote.join(" "))}</p></blockquote>`);
        continue;
      }

      if (/^[-*]\s+/.test(line)) {
        if (inOl) { out.push("</ol>"); inOl = false; }
        if (!inUl) { out.push("<ul>"); inUl = true; }
        out.push(`<li>${renderInline(line.replace(/^[-*]\s+/, ""))}</li>`);
        i += 1;
        continue;
      }

      if (/^\d+\.\s+/.test(line)) {
        if (inUl) { out.push("</ul>"); inUl = false; }
        if (!inOl) { out.push("<ol>"); inOl = true; }
        out.push(`<li>${renderInline(line.replace(/^\d+\.\s+/, ""))}</li>`);
        i += 1;
        continue;
      }

      if (line.trim() === "") {
        closeLists();
        i += 1;
        continue;
      }

      closeLists();
      out.push(`<p>${renderInline(line)}</p>`);
      i += 1;
    }

    closeLists();
    flushTable();
    if (inCode) {
      out.push(`<pre><code>${escapeHtml(codeLines.join("\n"))}</code></pre>`);
    }
    return out.join("\n");
  }

  function tagClass(tag) {
    if (tag === "정본") return "tag canonical";
    if (tag === "레거시") return "tag legacy";
    return "tag";
  }

  function openModal(item) {
    modalTitle.textContent = item.title;
    modalGithub.href = item.github || "#";
    modalGithub.hidden = !item.github;
    modalBody.innerHTML = '<p class="loading">불러오는 중…</p>';
    modal.hidden = false;
    document.body.style.overflow = "hidden";

    fetch(item.path)
      .then((res) => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return res.text();
      })
      .then((md) => {
        modalBody.innerHTML = renderMarkdown(md);
        modalBody.scrollTop = 0;
      })
      .catch((err) => {
        modalBody.innerHTML =
          `<p class="error">본문을 불러오지 못했습니다 (${escapeHtml(err.message)}).</p>` +
          (item.github
            ? `<p><a href="${escapeHtml(item.github)}" target="_blank" rel="noopener">GitHub에서 보기</a></p>`
            : "");
      });
  }

  function closeModal() {
    modal.hidden = true;
    document.body.style.overflow = "";
  }

  function renderCatalog(data) {
    metaEl.textContent = data.updated ? `갱신 ${data.updated}` : "";
    tocEl.innerHTML = "";
    catalogEl.innerHTML = "";

    data.categories.forEach((cat) => {
      const tocLink = document.createElement("a");
      tocLink.href = `#cat-${cat.id}`;
      tocLink.textContent = cat.title;
      tocEl.appendChild(tocLink);

      const section = document.createElement("section");
      section.className = "category";
      section.id = `cat-${cat.id}`;

      const head = document.createElement("div");
      head.className = "category-head";
      head.innerHTML = `<h2>${escapeHtml(cat.title)}</h2><span class="hint">${escapeHtml(cat.hint || "")}</span>`;
      section.appendChild(head);

      const grid = document.createElement("div");
      grid.className = "grid";

      (cat.items || []).forEach((item) => {
        const btn = document.createElement("button");
        btn.type = "button";
        btn.className = "card";
        btn.innerHTML =
          `<h3>${escapeHtml(item.title)}</h3>` +
          `<p>${escapeHtml(item.summary || "")}</p>` +
          `<div class="tags">${(item.tags || [])
            .map((t) => `<span class="${tagClass(t)}">${escapeHtml(t)}</span>`)
            .join("")}</div>`;
        btn.addEventListener("click", () => openModal(item));
        grid.appendChild(btn);
      });

      section.appendChild(grid);
      catalogEl.appendChild(section);
    });
  }

  btnClose.addEventListener("click", closeModal);
  modal.addEventListener("click", (e) => {
    if (e.target && e.target.dataset && e.target.dataset.close === "1") closeModal();
  });
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape" && !modal.hidden) closeModal();
  });

  fetch("catalog.json")
    .then((res) => {
      if (!res.ok) throw new Error(`catalog.json HTTP ${res.status}`);
      return res.json();
    })
    .then(renderCatalog)
    .catch((err) => {
      catalogEl.innerHTML = `<p class="error">카탈로그를 불러오지 못했습니다: ${escapeHtml(err.message)}</p>`;
    });
})();
