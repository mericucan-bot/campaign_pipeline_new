import { normalizeCampaignPayload } from "../utils/campaignSchema.js";

export async function fetchCampaignPayload() {
  const dataUrl = new URL("../../data/campaigns.json", import.meta.url);
  const response = await fetch(dataUrl, { cache: "no-store" });
  if (!response.ok) {
    throw new Error(`Campaign data request failed with ${response.status}`);
  }
  return normalizeCampaignPayload(await response.json());
}
