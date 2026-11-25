(() => {
  const catalog = document.querySelector("#catalog");
  if (!catalog) return;

  const form = catalog.querySelector(".search");
  const input = form.querySelector("input");
  const clear = form.querySelector(".search-clear");
  const body = catalog.querySelector("tbody");
  const count = catalog.querySelector(".count");
  const footer = catalog.querySelector(".table-footer");
  const empty = body.querySelector(".search-empty");
  const error = catalog.querySelector(".search-error");

  // A subsequence match allows omitted letters as well as ordinary substrings.
  function matches(text, term) {
    let position = 0;
    for (const character of text) {
      if (character === term[position]) position++;
      if (position === term.length) return true;
    }
    return false;
  }

  function filter() {
    const terms = input.value
      .toLocaleLowerCase()
      .trim()
      .split(/\s+/)
      .filter(Boolean);
    const rows = [...body.querySelectorAll("[data-medicine-name]")];
    let visible = 0;
    for (const row of rows) {
      const name = row.dataset.medicineName.toLocaleLowerCase();
      const barcode = row.dataset.barcode.toLocaleLowerCase();
      const match = terms.every(
        (term) => matches(name, term) || matches(barcode, term),
      );
      row.hidden = !match;
      if (match) visible++;
    }
    const catalogEmpty = body.querySelector(".catalog-empty");
    if (catalogEmpty) catalogEmpty.hidden = terms.length > 0 || rows.length > 0;
    empty.hidden = visible > 0 || terms.length === 0;
    count.textContent = visible;
    footer.textContent = `Showing ${visible} medicine${visible === 1 ? "" : "s"}`;
    clear.hidden = !input.value;
  }

  form.addEventListener("submit", (event) => event.preventDefault());
  input.addEventListener("input", filter);
  clear.addEventListener("click", () => {
    input.value = "";
    filter();
    input.focus();
  });

  // A server-rendered ?q= page contains only matches; load all rows once so
  // editing or clearing that initial search can find the entire catalog.
  if (new URLSearchParams(window.location.search).has("q")) {
    input.disabled = true;
    fetch(window.location.pathname)
      .then((response) => {
        if (!response.ok) throw new Error("Catalog request failed");
        return response.text();
      })
      .then((html) => {
        const documentCopy = new DOMParser().parseFromString(html, "text/html");
        const fullBody = documentCopy.querySelector("#catalog tbody");
        if (!fullBody) throw new Error("Catalog missing from response");
        body.replaceChildren(
          ...fullBody.querySelectorAll("[data-medicine-name], .catalog-empty"),
          empty,
        );
        input.disabled = false;
        filter();
      })
      .catch(() => {
        error.hidden = false;
      });
  } else {
    filter();
  }
})();
