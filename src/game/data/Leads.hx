package game.data;

enum LeadTier {
  TierS;
  TierA;
  TierB;
  TierC;
  TierF;
}

final leadLoHi = [TierC, TierB, TierA, TierS];
final leadHiLo = [TierS, TierA, TierB, TierC];

final leadChance = [
  TierS => 0.5,
  TierA => 0.25,
  TierB => 0.166,
  TierC => 0.1,
  TierF => 0.05,
];
