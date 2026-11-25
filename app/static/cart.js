(() => {
  const catalog = document.querySelector("#catalog");
  const cart = document.querySelector("#cart");
  if (!catalog || !cart) return;

  const body = cart.querySelector("tbody");
  const footer = cart.querySelector(".table-footer");
  const message = cart.querySelector(".cart-message");
  const storageKey = "pharmastock-cart";
  const maximumQuantity = 1000000;
  let items = [];

  try {
    const saved = JSON.parse(sessionStorage.getItem(storageKey) || "[]");
    if (Array.isArray(saved)) {
      items = saved.filter(
        (item) =>
          item &&
          typeof item.barcode === "string" &&
          typeof item.name === "string" &&
          typeof item.packaging === "string" &&
          Number.isSafeInteger(item.priceCents) &&
          item.priceCents >= 0 &&
          Number.isSafeInteger(item.quantity) &&
          item.quantity > 0 &&
          item.quantity <= maximumQuantity,
      );
    }
  } catch (_) {
    message.textContent =
      "Cart storage is unavailable; changes may not survive a reload.";
  }

  function save() {
    try {
      sessionStorage.setItem(storageKey, JSON.stringify(items));
      return true;
    } catch (_) {
      message.textContent =
        "Cart storage is unavailable; changes may not survive a reload.";
      return false;
    }
  }

  function render() {
    body.replaceChildren();
    if (!items.length) {
      const row = body.insertRow();
      const cell = row.insertCell();
      cell.colSpan = 6;
      cell.className = "empty";
      cell.textContent = "Your cart is empty.";
    }
    let total = 0;
    for (const item of items) {
      const row = body.insertRow();
      const subtotal = item.priceCents * item.quantity;
      total += subtotal;
      for (const value of [
        item.name,
        item.packaging,
        `${item.quantity} packages`,
        `€${(item.priceCents / 100).toFixed(2)}`,
        `€${(subtotal / 100).toFixed(2)}`,
      ]) {
        row.insertCell().textContent = value;
      }
      const remove = document.createElement("button");
      remove.type = "button";
      remove.className = "cart-remove";
      remove.textContent = "Remove";
      remove.setAttribute("aria-label", `Remove ${item.name} from cart`);
      remove.addEventListener("click", () => {
        items = items.filter((entry) => entry.barcode !== item.barcode);
        if (save()) message.textContent = `${item.name} removed from cart.`;
        render();
      });
      row.insertCell().append(remove);
    }
    footer.textContent = `Total: €${(total / 100).toFixed(2)}`;
  }

  catalog.addEventListener("input", (event) => {
    if (event.target.matches('.cart-add input[type="number"]')) {
      event.target.style.setProperty(
        "--quantity-digits",
        Math.max(1, event.target.value.length),
      );
    }
  });

  catalog.addEventListener("click", (event) => {
    const button = event.target.closest(".cart-add-button");
    if (!button) return;
    const row = button.closest("[data-barcode]");
    const quantityInput = row.querySelector('input[type="number"]');
    if (!quantityInput.reportValidity()) return;
    const quantity = Number(quantityInput.value);
    const existing = items.find((item) => item.barcode === row.dataset.barcode);
    if (existing && existing.quantity + quantity > maximumQuantity) {
      message.textContent = `The maximum cart quantity for ${row.dataset.medicineName} is ${maximumQuantity} packages.`;
      return;
    }
    if (existing) {
      existing.quantity += quantity;
    } else {
      items.push({
        barcode: row.dataset.barcode,
        name: row.dataset.medicineName,
        packaging: row.dataset.packaging,
        priceCents: Math.round(Number(row.dataset.price) * 100),
        quantity,
      });
    }
    if (save())
      message.textContent = `Added ${quantity} package${quantity === 1 ? "" : "s"} of ${row.dataset.medicineName} to your cart.`;
    render();
  });

  render();
})();
