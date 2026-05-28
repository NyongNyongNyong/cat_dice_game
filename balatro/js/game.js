import {
  HAND_DEFS, createDeck, shuffle, evaluatePlayed, getScoringCards,
  rankVal, cardLabel, SUIT_SYM,
} from "./poker.js";
import {
  JOKER_DEFS, createJokerInstance, getPassiveFlags, applyJokerPipeline,
  pickShopJokers, randomJokerId,
} from "./jokers.js";

const HAND_SIZE_BASE = 8;
const HANDS_BASE = 4;
const DISCARDS_BASE = 3;
const MAX_JOKERS = 5;
const TARGET_BASE = 300;
const TARGET_STEP = 150;

export function newRun() {
  return {
    ante: 1,
    money: 4,
    jokers: [],
    deck: [],
    hand: [],
    discardPile: [],
    playedThisRound: [],
    roundScore: 0,
    targetScore: TARGET_BASE,
    handsLeft: HANDS_BASE,
    discardsLeft: DISCARDS_BASE,
    handSize: HAND_SIZE_BASE,
    selected: new Set(),
    phase: "play", // play | shop | gameover | win
    handLevels: {},
    handPlayCounts: {},
    handsPlayedThisRound: {},
    mostPlayedHand: null,
    handPlayTotal: {},
    fullDeck: [],
    deckRemaining: 0,
    pareidolia: false,
    log: [],
    shopOffers: [],
    pendingJokers: [],
    lastDiscardCount: 0,
    retriggerScored: [],
    deckMods: [],
    discardsThisRound: 0,
    handsPlayedCount: 0,
  };
}

function handLevelDef(type, levels) {
  const lv = levels[type] || 1;
  const base = HAND_DEFS[type];
  return {
    chips: base.chips + (lv - 1) * 10,
    mult: base.mult + (lv - 1),
    level: lv,
  };
}

export function startRound(state) {
  state.deck = shuffle([...state.fullDeck]);
  state.hand = [];
  state.discardPile = [];
  state.playedThisRound = [];
  state.roundScore = 0;
  state.selected = new Set();
  state.handsPlayedThisRound = {};
  state.retriggerScored = [];
  state.discardsThisRound = 0;
  state.handsPlayedCount = 0;
  state.targetScore = TARGET_BASE + (state.ante - 1) * TARGET_STEP;

  const pass = getPassiveFlags(state.jokers);
  state.handSize = HAND_SIZE_BASE + (pass.handSizeBonus || 0);
  state.handsLeft = Math.max(1, HANDS_BASE - (pass.handsPenalty || 0));
  state.discardsLeft = DISCARDS_BASE + (pass.discardsBonus || 0);

  if (pass.handSizeDecay && state._turtleRounds) {
    state.handSize = Math.max(1, state.handSize - state._turtleRounds);
  }

  for (const j of state.jokers) {
    const d = JOKER_DEFS[j.defId];
    if (d?.onBlindSelect) {
      d.onBlindSelect({ jokers: state.jokers, joker: j, jokerIndex: state.jokers.indexOf(j), state });
    }
  }

  while (state.pendingJokers.length && state.jokers.length < MAX_JOKERS) {
    const rarity = state.pendingJokers.shift();
    const id = randomJokerId(rarity === "common" ? "common" : null);
    state.jokers.push(createJokerInstance(id, JOKER_DEFS));
  }

  drawToHandSize(state);
  state.deckRemaining = state.deck.length;
  log(state, `── Ante ${state.ante} · 목표 ${state.targetScore} ──`);
}

export function initFullDeck(state) {
  state.fullDeck = createDeck();
  for (const mod of state.deckMods || []) {
    if (mod.type === "stone") {
      state.fullDeck.push({
        id: state.fullDeck.length, rank: "9", suit: "S",
        enhancement: "stone", seal: null, bonusChips: 0,
      });
    }
  }
}

function drawToHandSize(state) {
  while (state.hand.length < state.handSize && state.deck.length) {
    state.hand.push(state.deck.pop());
  }
  state.deckRemaining = state.deck.length;
}

function playCtx(state, hand, played, scoring, held) {
  const pass = getPassiveFlags(state.jokers);
  return {
    state,
    hand,
    played,
    scoring,
    held,
    jokers: state.jokers,
    pass,
  };
}

export function scorePlay(state, playedCards) {
  const pass = getPassiveFlags(state.jokers);
  state.pareidolia = pass.pareidolia;

  const hand = evaluatePlayed(playedCards, {
    fourFingers: pass.fourFingers,
    shortcut: pass.shortcut,
  });
  if (!hand) return null;

  const scoring = getScoringCards(playedCards, hand, pass.splash);
  const held = state.hand.filter(c => !playedCards.includes(c));

  const lv = handLevelDef(hand.type, state.handLevels);
  let chips = lv.chips;
  let mult = lv.mult;

  const cardChipLines = [];
  for (const c of scoring) {
    chips += rankVal(c.rank) + (c.bonusChips || 0);
    cardChipLines.push(`${cardLabel(c)} +${rankVal(c.rank)}`);
  }

  const baseCtx = playCtx(state, hand, playedCards, scoring, held);
  state.retriggerScored = [];

  let xmult = 1;
  const applyScored = (card, isRetrigger = false) => {
    const s = runOnScored(state, baseCtx, card, isRetrigger);
    chips += s.chips;
    mult += s.mult;
    xmult *= s.xmult;
  };

  for (const c of scoring) {
    applyScored(c, false);
    let guard = 0;
    while (state.retriggerScored.length && guard++ < 20) {
      const extra = state.retriggerScored.splice(0);
      for (const card of extra) applyScored(card, true);
    }
  }

  if (pass.dusk && state.handsLeft === 0) {
    for (const c of scoring) applyScored(c, true);
  }

  // Held in hand
  const heldScore = applyJokerPipeline("onHeld", baseCtx);
  mult += heldScore.mult;
  for (const j of state.jokers) {
    const d = JOKER_DEFS[j.defId];
    if (d?.onHeld) {
      const s = { chips: 0, mult: 0, xmult: 1 };
      d.onHeld(s, { ...baseCtx, joker: j, jokerIndex: state.jokers.indexOf(j) });
      mult += s.mult;
      chips += s.chips;
    }
  }

  // Mime: retrigger held abilities (simplified: Baron/Shoot the Moon again)
  if (pass.mime) {
    const s2 = { chips: 0, mult: 0, xmult: 1 };
    for (const j of state.jokers) {
      const d = JOKER_DEFS[j.defId];
      if (d?.onHeld) d.onHeld(s2, { ...baseCtx, joker: j, jokerIndex: state.jokers.indexOf(j) });
    }
    mult += s2.mult;
    chips += s2.chips;
  }

  applyJokerPipeline("beforeIndependent", baseCtx);

  for (let i = 0; i < state.jokers.length; i++) {
    const joker = state.jokers[i];
    const def = JOKER_DEFS[joker.defId];
    const resolved = def?.copyRight ? JOKER_DEFS[state.jokers[i + 1]?.defId] :
      def?.copyLeft ? JOKER_DEFS[state.jokers[0]?.defId] : def;
    if (!resolved?.independent) continue;
    const s = { chips: 0, mult: 0, xmult: 1 };
    resolved.independent(s, { ...baseCtx, joker, jokerIndex: i, def: resolved });
    chips += s.chips;
    mult += s.mult;
    xmult *= s.xmult;

    if (resolved.onOtherJoker) {
      for (let k = 0; k < state.jokers.length; k++) {
        if (k === i) continue;
        const ox = { xmult: 1 };
        resolved.onOtherJoker(ox, state.jokers[k]);
        xmult *= ox.xmult;
      }
    }
  }

  for (let i = 0; i < state.jokers.length; i++) {
    const joker = state.jokers[i];
    const def = JOKER_DEFS[joker.defId];
    if (def?.onAfterScoring) def.onAfterScoring({ ...baseCtx, joker, jokerIndex: i });
    let guard = 0;
    while (state.retriggerScored.length && guard++ < 20) {
      const extra = state.retriggerScored.splice(0);
      for (const card of extra) applyScored(card, true);
    }
  }

  const total = Math.floor(chips * mult * xmult);
  state.roundScore += total;

  state.handPlayCounts[hand.type] = (state.handPlayCounts[hand.type] || 0) + 1;
  state.handsPlayedThisRound[hand.type] = (state.handsPlayedThisRound[hand.type] || 0) + 1;
  state.handPlayTotal[hand.type] = (state.handPlayTotal[hand.type] || 0) + 1;
  state.mostPlayedHand = Object.entries(state.handPlayTotal)
    .sort((a, b) => b[1] - a[1])[0]?.[0] || hand.type;

  for (const j of state.jokers) {
    const d = JOKER_DEFS[j.defId];
    if (d?.onHandPlayed) d.onHandPlayed({ ...baseCtx, joker: j, jokerIndex: state.jokers.indexOf(j) });
    if (d?.onAfterPlay) d.onAfterPlay({ ...baseCtx, joker: j, jokerIndex: state.jokers.indexOf(j) });
  }

  state.handsPlayedCount++;
  const breakdown = {
    handName: hand.name,
    handType: hand.type,
    level: lv.level,
    chips, mult, xmult, total,
    cards: cardChipLines,
  };

  log(state, `<b>${hand.name}</b> Lv${lv.level} → ${chips} × ${mult} × ${xmult.toFixed(2)} = <span class="sc">+${total}</span> (누적 ${state.roundScore})`);
  return breakdown;
}

function runOnScored(state, baseCtx, card, isRetrigger = false) {
  const s = { chips: 0, mult: 0, xmult: 1 };
  for (let i = 0; i < state.jokers.length; i++) {
    const joker = state.jokers[i];
    let def = JOKER_DEFS[joker.defId];
    if (def?.copyRight && state.jokers[i + 1]) def = JOKER_DEFS[state.jokers[i + 1].defId];
    if (def?.copyLeft && state.jokers[0]) def = JOKER_DEFS[state.jokers[0].defId];
    if (def?.onScored) def.onScored(card, s, { ...baseCtx, joker, jokerIndex: i, isRetrigger });
  }
  return s;
}

export function playHand(state) {
  if (state.handsLeft <= 0) return { error: "핸드 없음" };
  const sel = [...state.selected].map(i => state.hand[i]).filter(Boolean);
  if (!sel.length) return { error: "카드를 선택하세요" };

  const breakdown = scorePlay(state, sel);
  if (!breakdown) return { error: "족보 판정 실패" };

  state.handsLeft--;
  state.hand = state.hand.filter(c => !sel.includes(c));
  state.discardPile.push(...sel);
  state.selected = new Set();
  drawToHandSize(state);

  if (state.roundScore >= state.targetScore) {
    endRoundWin(state);
    return { breakdown, won: true };
  }
  if (state.handsLeft <= 0) {
    const pass = getPassiveFlags(state.jokers);
    if (pass.mrBones && state.roundScore >= state.targetScore * 0.25) {
      log(state, "Mr. Bones: 25% 달성으로 생존 (스켈레톤)");
      endRoundWin(state);
      return { breakdown, won: true };
    }
    state.phase = "gameover";
    log(state, `<span class="bad">실패</span> ${state.roundScore} / ${state.targetScore}`);
    return { breakdown, lost: true };
  }
  return { breakdown };
}

export function discardSelected(state) {
  if (state.discardsLeft <= 0) return { error: "버림 없음" };
  const sel = [...state.selected].map(i => state.hand[i]).filter(Boolean);
  if (!sel.length) return { error: "카드를 선택하세요" };

  state.lastDiscardCount = sel.length;
  state.hand = state.hand.filter(c => !sel.includes(c));
  state.discardPile.push(...sel);
  state.discardsLeft--;
  state.discardsThisRound++;
  state.selected = new Set();

  for (const j of state.jokers) {
    const d = JOKER_DEFS[j.defId];
    if (d?.onDiscard) d.onDiscard({ state, joker: j, jokers: state.jokers }, sel);
    if (d?.onDiscardAction) d.onDiscardAction({ state, joker: j, jokers: state.jokers });
  }

  drawToHandSize(state);
  log(state, `버림 ${sel.length}장`);
  return { ok: true };
}

function endRoundWin(state) {
  state.money += state.handsLeft;
  for (const j of state.jokers) {
    const d = JOKER_DEFS[j.defId];
    if (d?.onRoundEnd) d.onRoundEnd({ state, joker: j, jokers: state.jokers });
  }
  if (state._turtleRounds !== undefined) state._turtleRounds++;
  else state._turtleRounds = 1;

  state.phase = "shop";
  const owned = state.jokers.map(j => j.defId);
  state.shopOffers = pickShopJokers(3, owned, getPassiveFlags(state.jokers).showman);
  log(state, `<span class="sc">블라인드 클리어!</span> 상점으로`);
}

export function buyJoker(state, defId) {
  const def = JOKER_DEFS[defId];
  if (!def) return { error: "없는 조커" };
  if (state.jokers.length >= MAX_JOKERS) return { error: "조커 슬롯 가득" };
  if (state.money < def.cost) return { error: "돈 부족" };
  state.money -= def.cost;
  state.jokers.push(createJokerInstance(defId, JOKER_DEFS));
  log(state, `구매: ${def.name}`);
  return { ok: true };
}

export function leaveShop(state) {
  state.ante++;
  state.phase = "play";
  initFullDeck(state);
  startRound(state);
}

export function toggleSelect(state, index) {
  if (state.selected.has(index)) state.selected.delete(index);
  else {
    if (state.selected.size >= 5) return;
    state.selected.add(index);
  }
}

function log(state, html) {
  state.log.unshift(html);
  if (state.log.length > 50) state.log.pop();
}

export function formatCard(c) {
  const red = c.suit === "H" || c.suit === "D";
  return { label: cardLabel(c), red, suit: SUIT_SYM[c.suit] };
}
