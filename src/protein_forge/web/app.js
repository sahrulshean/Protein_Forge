const $ = (selector) => document.querySelector(selector);
const screens = [$("#welcome-screen"), $("#game-screen"), $("#result-screen")];
const bestScoreKey = "protein-forge-best-score";
const state = { questions: [], index: 0, score: 0, firstTry: 0, attempted: false, answered: false, chain: [], loading: false };
let codonEntries = null;
let referenceLoading = false;

function node(tag, className, text) {
  const item = document.createElement(tag);
  if (className) item.className = className;
  if (text !== undefined) item.textContent = text;
  return item;
}

function readBestScore() {
  try {
    const saved = Number(localStorage.getItem(bestScoreKey));
    return Number.isInteger(saved) && saved >= 0 && saved <= 600 ? saved : 0;
  } catch {
    return 0;
  }
}

function storeBestScore(score) {
  try {
    localStorage.setItem(bestScoreKey, String(score));
  } catch {
    // The game remains playable when browser storage is unavailable.
  }
}

async function fetchData(path) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 10000);
  try {
    const response = await fetch(path, { signal: controller.signal });
    if (!response.ok) throw new Error("Permintaan tidak berhasil.");
    return await response.json();
  } finally {
    clearTimeout(timeout);
  }
}

function showScreen(screen) {
  screens.forEach((item) => { item.hidden = item !== screen; });
  window.scrollTo(0, 0);
}

async function startGame(button, errorElement) {
  if (state.loading) return;
  state.loading = true;
  errorElement.hidden = true;
  const originalLabel = button.innerHTML;
  button.textContent = "Menyiapkan eksperimen…";
  button.disabled = true;
  try {
    const data = await fetchData("/api/game");
    if (!Array.isArray(data.questions) || data.questions.length !== 6) {
      throw new Error("Data eksperimen tidak lengkap.");
    }
    Object.assign(state, { questions: data.questions, index: 0, score: 0, firstTry: 0, attempted: false, answered: false, chain: [] });
    showScreen($("#game-screen"));
    renderRound();
    $("#game-title").focus();
  } catch {
    errorElement.textContent = "Eksperimen belum berhasil dimuat. Periksa koneksi ke server, lalu coba lagi melalui tombol yang sama.";
    errorElement.hidden = false;
  } finally {
    state.loading = false;
    button.disabled = false;
    button.innerHTML = originalLabel;
  }
}

function renderRound() {
  const question = state.questions[state.index];
  state.attempted = false;
  state.answered = false;
  $("#round-label").textContent = `KODON ${state.index + 1} / ${state.questions.length}`;
  $("#codon-track").replaceChildren(...state.questions.map((entry, index) => {
    const chip = node("span", "codon-chip", entry.codon);
    if (index < state.index) chip.classList.add("is-complete");
    if (index === state.index) {
      chip.classList.add("is-active");
      chip.setAttribute("aria-current", "step");
    }
    chip.setAttribute("aria-label", `Kodon ${index + 1}: ${entry.codon}`);
    return chip;
  }));
  const codon = $("#current-codon");
  codon.setAttribute("aria-label", `Kodon ${question.codon.split("").join(" ")}`);
  codon.replaceChildren(...question.codon.split("").map((base) => {
    const letter = node("span", "codon-letter", base);
    letter.dataset.base = base;
    letter.setAttribute("aria-hidden", "true");
    return letter;
  }));
  $("#question-prompt").textContent = "Pilih asam amino atau sinyal yang tepat.";
  $("#answer-options").replaceChildren(...question.options.map((option, index) => {
    const button = node("button", "answer-button");
    button.type = "button";
    button.dataset.code = option.code;
    button.setAttribute("aria-label", `${index + 1}. ${option.name}, ${option.code === "*" ? "sinyal stop" : option.code}`);
    button.append(node("span", "answer-index", index + 1), node("span", "answer-code", option.code === "*" ? "STOP" : option.code), node("span", "answer-name", option.name));
    button.addEventListener("click", () => chooseAnswer(option, button));
    return button;
  }));
  const feedback = $("#feedback");
  feedback.className = "feedback";
  feedback.replaceChildren(node("span", "", "Setiap jawaban adalah kesempatan belajar."));
  $("#next-button").hidden = true;
  updateSidebar();
}

function chooseAnswer(option, button) {
  if (state.answered || button.disabled) return;
  const question = state.questions[state.index];
  const feedback = $("#feedback");
  if (option.code !== question.answer) {
    state.attempted = true;
    button.classList.add("is-wrong");
    button.disabled = true;
    feedback.className = "feedback is-error";
    feedback.replaceChildren(node("strong", "", "Belum tepat. Coba sekali lagi."), node("p", "", "Cocokkan tiga basa ini dengan tabel kodon. Jawaban yang tepat masih bernilai 50 poin."));
    return;
  }

  state.answered = true;
  const points = state.attempted ? 50 : 100;
  state.score += points;
  if (!state.attempted) state.firstTry += 1;
  if (option.code !== "*") state.chain.push({ code: option.code, name: option.name });
  button.classList.add("is-correct");
  $("#answer-options").querySelectorAll("button").forEach((item) => { item.disabled = true; });
  feedback.className = "feedback is-success";
  feedback.replaceChildren(node("strong", "", `Tepat! +${points} poin`), node("p", "", question.explanation));
  const next = $("#next-button");
  next.replaceChildren(document.createTextNode(state.index === state.questions.length - 1 ? "Lihat hasil " : "Kodon berikutnya "), node("span", "", "→"));
  next.hidden = false;
  updateSidebar();
  next.focus({ preventScroll: true });
}

function updateSidebar() {
  $("#score-value").textContent = String(state.score).padStart(3, "0");
  $("#best-score-value").textContent = readBestScore();
  $("#chain-count").textContent = `${state.chain.length} / 5`;
  $("#peptide-chain").replaceChildren(...Array.from({ length: 5 }, (_, index) => {
    const residue = state.chain[index];
    const item = node("div", `chain-node${residue ? " is-filled" : ""}`);
    item.append(node("span", "chain-letter", residue ? residue.code : "·"), node("span", "chain-name", residue ? residue.name : `Asam amino ${index + 1}`));
    return item;
  }));
}

function finishGame() {
  const previousBest = readBestScore();
  if (state.score > previousBest) storeBestScore(state.score);
  $("#final-score").replaceChildren(document.createTextNode(`${state.score} `), node("span", "", "/ 600"));
  $("#final-accuracy").replaceChildren(document.createTextNode(`${state.firstTry} `), node("span", "", "/ 6 kodon"));
  $("#record-message").textContent = state.score > previousBest ? "Rekor baru. Catatan kecil untuk penemuan berikutnya!" : "Pemahaman tumbuh bersama setiap percobaan.";
  $("#final-chain").replaceChildren(...state.chain.map((residue) => {
    const item = node("div", "result-residue");
    item.append(node("strong", "", residue.code), node("span", "", residue.name));
    return item;
  }));
  showScreen($("#result-screen"));
  $("#result-title").focus();
}

function nextRound() {
  if (!state.answered || $("#game-screen").hidden) return;
  if (state.index === state.questions.length - 1) {
    finishGame();
    return;
  }
  state.index += 1;
  renderRound();
  $("#answer-options button").focus({ preventScroll: true });
}

function renderReference() {
  if (!codonEntries) return;
  const query = $("#codon-search").value.trim().toLocaleLowerCase("id");
  const matches = codonEntries.filter((entry) => `${entry.codon} ${entry.code} ${entry.name}`.toLocaleLowerCase("id").includes(query));
  $("#codon-table-body").replaceChildren(...matches.map((entry) => {
    const row = node("tr", entry.code === "*" ? "stop-row" : "");
    row.append(node("td", "table-codon", entry.codon), node("td", "table-code", entry.code === "*" ? "STOP" : entry.code), node("td", "", entry.name));
    return row;
  }));
  $("#reference-status").textContent = matches.length ? `${matches.length} dari ${codonEntries.length} kodon` : "Tidak ada kodon yang cocok. Coba kata lain.";
}

async function loadReference() {
  if (referenceLoading) return;
  if (codonEntries) {
    renderReference();
    return;
  }
  referenceLoading = true;
  $("#reference-status").textContent = "Memuat tabel kodon…";
  $("#reference-retry").hidden = true;
  try {
    const data = await fetchData("/api/codons");
    if (!Array.isArray(data.entries) || data.entries.length !== 64) throw new Error("Tabel tidak lengkap.");
    codonEntries = data.entries;
    renderReference();
  } catch {
    $("#reference-status").textContent = "Tabel belum berhasil dimuat. Kamu bisa mencoba lagi.";
    $("#reference-retry").hidden = false;
  } finally {
    referenceLoading = false;
  }
}

function openReference() {
  const dialog = $("#reference-dialog");
  if (!dialog.open) dialog.showModal();
  $("#codon-search").focus();
  loadReference();
}

$("#start-button").addEventListener("click", () => startGame($("#start-button"), $("#start-error")));
$("#restart-button").addEventListener("click", () => startGame($("#restart-button"), $("#restart-error")));
$("#next-button").addEventListener("click", nextRound);
document.querySelectorAll("[data-open-reference]").forEach((button) => button.addEventListener("click", openReference));
$("#reference-retry").addEventListener("click", loadReference);
$("#codon-search").addEventListener("input", renderReference);
$("#help-button").addEventListener("click", () => $("#help-dialog").showModal());
document.querySelectorAll("[data-close-dialog]").forEach((button) => button.addEventListener("click", () => button.closest("dialog").close()));
document.addEventListener("keydown", (event) => {
  const openDialog = document.querySelector("dialog[open]");
  if (event.key === "Escape" && openDialog) {
    event.preventDefault();
    openDialog.close();
    return;
  }
  if ($("#game-screen").hidden || openDialog || state.answered || event.ctrlKey || event.metaKey || event.altKey) return;
  if (event.target instanceof HTMLElement && (event.target.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(event.target.tagName))) return;
  if (/^[1-4]$/.test(event.key)) {
    event.preventDefault();
    $("#answer-options").children[Number(event.key) - 1]?.click();
  }
}, { capture: true });
