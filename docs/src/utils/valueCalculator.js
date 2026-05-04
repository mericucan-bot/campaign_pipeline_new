export function calculateEffectiveReturn(campaign, spendAmount) {
  const spend = Number(spendAmount || 0);
  const rewardRate = Number(campaign?.rewardRate || 0);
  const maxRewardValue = Number(campaign?.maxReward || 0);
  const maxReward = maxRewardValue > 0 ? maxRewardValue : Infinity;

  if (!Number.isFinite(spend) || spend <= 0 || !Number.isFinite(rewardRate) || rewardRate <= 0) {
    return { reward: 0, effectiveRate: 0 };
  }

  const reward = Math.min(spend * rewardRate, maxReward);
  return {
    reward,
    effectiveRate: reward / spend,
  };
}
