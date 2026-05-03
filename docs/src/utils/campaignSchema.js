import { normalize, parseMoney, slug } from "./format.js";

const REWARD_TYPES = new Set(["cashback", "points", "installment"]);

export function normalizeCampaignPayload(payload) {
  const generatedAt = payload?.generated_at || new Date().toISOString();
  return {
    ...payload,
    campaigns: (payload?.campaigns || []).map((campaign, index) => normalizeCampaign(campaign, { generatedAt, index })),
  };
}

export function normalizeCampaign(campaign = {}, context = {}) {
  const title = cleanText(campaign.title || campaign.baslik || campaign.name || "");
  const description = cleanText(campaign.description || campaign.aciklama || "");
  const rewardType = normalizeRewardType(campaign);
  const rewardRate = normalizeRewardRate(campaign, rewardType);
  const validFrom = normalizeDate(campaign.validFrom || campaign.valid_from || campaign.first_seen || campaign.created_at || context.generatedAt);
  const validTo = normalizeDate(campaign.validTo || campaign.valid_to || campaign.deadline || campaign.bitis_tarihi);
  const bank = cleanText(campaign.bank || campaign.banka || "Kampanya");
  const id = String(campaign.id || campaign.external_id || campaign.url || `${slug(bank)}-${slug(title)}-${context.index || 0}`);

  return {
    id,
    bank,
    title: title || "Kampanya",
    category: cleanText(campaign.category || campaign.kategori || "Genel") || "Genel",
    rewardType,
    rewardRate,
    minSpend: parseMoney(campaign.minSpend ?? campaign.min_spend ?? campaign.min_harcama ?? 0),
    maxReward: parseMoney(campaign.maxReward ?? campaign.max_reward ?? campaign.max_kazanim ?? 0),
    validFrom,
    validTo,
    conditions: normalizeConditions(campaign),
    isStackable: Boolean(campaign.isStackable ?? campaign.is_stackable ?? false),

    sourceUrl: campaign.sourceUrl || campaign.source_url || campaign.kaynak_url || campaign.url || campaign.external_id || "",
    imageUrl: campaign.imageUrl || campaign.image_url || campaign.gorsel_url || "",
    isActive: campaign.isActive ?? campaign.is_active ?? campaign.aktif ?? true,
    sourceDate: String(campaign.last_seen || campaign.first_seen || context.generatedAt || "").slice(0, 10) || "Tarih yok",
    brandCode: campaign.brandCode || campaign.brand_code || "",
    bankLabel: campaign.bankLabel || campaign.bank_label || "",
    highlight: cleanText(campaign.highlight || campaign.kazanim || campaign.reward || ""),
    description,
  };
}

function normalizeRewardType(campaign) {
  const explicit = String(campaign.rewardType || campaign.reward_type || campaign.kazanim_turu || "").toLowerCase();
  if (REWARD_TYPES.has(explicit)) return explicit;

  const text = normalize(`${explicit} ${campaign.highlight || ""} ${campaign.title || ""} ${campaign.description || ""}`);
  if (/taksit|vade/.test(text)) return "installment";
  if (/puan|bonus|chip|worldpuan|bankkart lira|mil/.test(text)) return "points";
  return "cashback";
}

function normalizeRewardRate(campaign, rewardType) {
  const direct = Number(campaign.rewardRate ?? campaign.reward_rate);
  if (Number.isFinite(direct) && direct > 0) return direct;

  const text = `${campaign.kazanim || ""} ${campaign.highlight || ""} ${campaign.title || ""} ${campaign.description || ""}`;
  const percent = text.match(/% ?(\d+(?:[.,]\d+)?)/);
  if (percent) return Number(percent[1].replace(",", "."));

  const money = parseMoney(text);
  if (money > 0) return money;

  const number = text.match(/(\d+(?:[.,]\d+)?)/);
  if (!number) return 0;
  const parsed = Number(number[1].replace(",", "."));
  return Number.isFinite(parsed) ? parsed : 0;
}

function normalizeConditions(campaign) {
  if (Array.isArray(campaign.conditions)) return campaign.conditions.map(cleanText).filter(Boolean);
  const values = [campaign.condition, campaign.terms, campaign.description || campaign.aciklama].map(cleanText).filter(Boolean);
  return values;
}

function normalizeDate(value) {
  if (!value) return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  return date.toISOString();
}

function cleanText(value) {
  return String(value || "").replace(/\s+/g, " ").trim();
}
