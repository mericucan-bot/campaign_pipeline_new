export function normalize(value) {
  return String(value || "")
    .replaceAll("yurtdışı", "yurt dışı")
    .replaceAll("yurtdisi", "yurt disi")
    .toLocaleLowerCase("tr-TR")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/ı/g, "i");
}

export function normalizeSearch(value) {
  return normalize(value).replace(/\s+/g, "");
}

export function slug(value) {
  return normalize(value).replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
}

export function shortenText(text, maxLength) {
  const clean = String(text || "").replace(/\s+/g, " ").trim();
  if (clean.length <= maxLength) return clean;
  return `${clean.slice(0, Math.max(0, maxLength - 3)).trim()}...`;
}

export function parseMoney(value) {
  if (value === null || value === undefined) return 0;
  if (typeof value === "number") return Number.isFinite(value) ? value : 0;
  const text = String(value).toLocaleLowerCase("tr-TR");
  const match = text.match(/(\d+(?:[.,]\d+)?)/);
  if (!match) return 0;
  const numeric = Number(match[1].replace(",", "."));
  if (!Number.isFinite(numeric)) return 0;
  if (/\b(bin|k)\b/.test(text) || /000/.test(text)) return numeric * (numeric < 1000 ? 1000 : 1);
  return numeric;
}

export function formatCurrency(value) {
  return `${Math.round(Number(value) || 0).toLocaleString("tr-TR")}₺`;
}
