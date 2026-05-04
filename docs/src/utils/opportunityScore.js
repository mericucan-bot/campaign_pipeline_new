export function calculateOpportunityScore(campaign) {
  const rewardRate = Number(campaign?.rewardRate || 0);
  const maxReward = Number(campaign?.maxReward || 0);
  const numberOfConditions = Array.isArray(campaign?.conditions) ? campaign.conditions.length : 0;
  return (rewardRate * 100) + (maxReward / 10) - (numberOfConditions * 2);
}

export function opportunityLabel(score) {
  if (score > 80) return { text: "🔥 Great", className: "opportunity-great" };
  if (score > 50) return { text: "👍 Good", className: "opportunity-good" };
  return { text: "🗑 Weak", className: "opportunity-weak" };
}
