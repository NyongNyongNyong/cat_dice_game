/** Balatro-style poker evaluation (level 1 base values) */
export const HAND_DEFS = {
  high_card:      { name: "High Card",       chips: 5,   mult: 1 },
  pair:           { name: "Pair",            chips: 10,  mult: 2 },
  two_pair:       { name: "Two Pair",        chips: 20,  mult: 2 },
  three_kind:     { name: "Three of a Kind", chips: 30,  mult: 3 },
  straight:       { name: "Straight",        chips: 30,  mult: 4 },
  flush:          { name: "Flush",           chips: 35,  mult: 4 },
  full_house:     { name: "Full House",      chips: 40,  mult: 4 },
  four_kind:      { name: "Four of a Kind",  chips: 60,  mult: 7 },
  straight_flush: { name: "Straight Flush",  chips: 100, mult: 8 },
};

/** "Contains" hierarchy — higher hands include lower patterns */
export const CONTAINS = {
  high_card:      ["high_card"],
  pair:           ["high_card", "pair"],
  two_pair:       ["high_card", "pair", "two_pair"],
  three_kind:     ["high_card", "pair", "three_kind"],
  straight:       ["high_card", "straight"],
  flush:          ["high_card", "flush"],
  full_house:     ["high_card", "pair", "three_kind", "full_house"],
  four_kind:      ["high_card", "pair", "three_kind", "four_kind"],
  straight_flush: ["high_card", "straight", "flush", "straight_flush"],
};

export const SUITS = ["H", "D", "C", "S"];
export const SUIT_SYM = { H: "♥", D: "♦", C: "♣", S: "♠" };
export const RANKS = ["2","3","4","5","6","7","8","9","10","J","Q","K","A"];

export function rankVal(r) {
  if (r === "A") return 11;
  if (r === "K" || r === "Q" || r === "J") return 10;
  return parseInt(r, 10);
}

export function rankOrd(r) {
  if (r === "A") return 14;
  if (r === "K") return 13;
  if (r === "Q") return 12;
  if (r === "J") return 11;
  return parseInt(r, 10);
}

export function isFace(r, pareidolia = false) {
  if (pareidolia) return true;
  return r === "J" || r === "Q" || r === "K";
}

export function isEvenRank(r) {
  return ["2","4","6","8","10"].includes(r);
}

export function isOddRank(r) {
  return ["A","3","5","7","9"].includes(r);
}

function countByRank(cards) {
  const m = {};
  for (const c of cards) {
    m[c.rank] = (m[c.rank] || 0) + 1;
  }
  return m;
}

function countBySuit(cards) {
  const m = {};
  for (const c of cards) {
    m[c.suit] = (m[c.suit] || 0) + 1;
  }
  return m;
}

function isFlush(cards, min = 5) {
  const m = countBySuit(cards);
  return Object.values(m).some(n => n >= min);
}

function isStraightOrds(ords, minLen, allowGap = false) {
  const u = [...new Set(ords)].sort((a, b) => a - b);
  if (u.length < minLen) return false;
  if (!allowGap) {
    for (let i = 0; i <= u.length - minLen; i++) {
      let ok = true;
      for (let j = 1; j < minLen; j++) {
        if (u[i + j] !== u[i] + j) { ok = false; break; }
      }
      if (ok) return true;
    }
    if (minLen <= 5 && u.includes(14)) {
      const low = u.filter(x => x !== 14).concat([1]);
      low.sort((a, b) => a - b);
      for (let i = 0; i <= low.length - minLen; i++) {
        let ok = true;
        for (let j = 1; j < minLen; j++) {
          if (low[i + j] !== low[i] + j) { ok = false; break; }
        }
        if (ok) return true;
      }
    }
    return false;
  }
  // Shortcut: gaps of 1 allowed
  for (let start = 0; start < u.length; start++) {
    let run = [u[start]];
    for (let i = start + 1; i < u.length && run.length < minLen; i++) {
      const diff = u[i] - run[run.length - 1];
      if (diff === 1 || diff === 2) run.push(u[i]);
    }
    if (run.length >= minLen) return true;
  }
  return false;
}

function bestStraightFlush(cards, minCards) {
  for (const suit of SUITS) {
    const suited = cards.filter(c => c.suit === suit);
    if (suited.length < minCards) continue;
    const ords = suited.map(c => rankOrd(c.rank));
    if (isStraightOrds(ords, minCards, false)) return { type: "straight_flush", cards: suited };
  }
  return null;
}

export function evaluatePlayed(cards, opts = {}) {
  const { fourFingers = false, shortcut = false, smeared = false } = opts;
  const n = cards.length;
  if (n === 0) return null;

  const minStraight = fourFingers ? 4 : 5;
  const minFlush = fourFingers ? 4 : 5;

  const rc = countByRank(cards);
  const freqs = Object.values(rc).sort((a, b) => b - a);
  const ords = cards.map(c => rankOrd(c.rank));

  let type = "high_card";
  const flush = n >= minFlush && isFlush(cards, minFlush);
  const straight = n >= minStraight && isStraightOrds(ords, minStraight, shortcut);

  if (n >= 5) {
    const sf = bestStraightFlush(cards, minStraight);
    if (sf) type = "straight_flush";
    else if (freqs[0] >= 4) type = "four_kind";
    else if (freqs[0] >= 3 && freqs[1] >= 2) type = "full_house";
    else if (flush && straight) type = "straight_flush";
    else if (flush) type = "flush";
    else if (straight) type = "straight";
    else if (freqs[0] >= 3) type = "three_kind";
    else if (freqs[0] >= 2 && freqs[1] >= 2) type = "two_pair";
    else if (freqs[0] >= 2) type = "pair";
  } else if (n === 4 && fourFingers) {
    if (freqs[0] >= 4) type = "four_kind";
    else if (freqs[0] >= 3) type = "three_kind";
    else if (freqs[0] >= 2 && freqs[1] >= 2) type = "two_pair";
    else if (flush && straight) type = "straight_flush";
    else if (flush) type = "flush";
    else if (straight) type = "straight";
    else if (freqs[0] >= 2) type = "pair";
  } else {
    if (freqs[0] >= 4) type = "four_kind";
    else if (freqs[0] >= 3) type = "three_kind";
    else if (freqs[0] >= 2 && freqs[1] >= 2) type = "two_pair";
    else if (freqs[0] >= 2) type = "pair";
  }

  return {
    type,
    name: HAND_DEFS[type].name,
    contains: CONTAINS[type],
    is: (t) => type === t,
    containsType: (t) => CONTAINS[type].includes(t),
  };
}

/** Which played cards contribute chip values to the hand */
export function getScoringCards(played, hand, splash = false) {
  if (splash) return [...played];
  const rc = countByRank(played);
  const type = hand.type;

  if (type === "high_card") {
    const best = [...played].sort((a, b) => rankVal(b.rank) - rankVal(a.rank))[0];
    return best ? [best] : [];
  }
  if (type === "pair" || type === "two_pair" || type === "three_kind" || type === "four_kind") {
    const out = [];
    for (const [rank, count] of Object.entries(rc)) {
      const need = type === "pair" ? 2 : type === "two_pair" ? 2 : type === "three_kind" ? 3 : 4;
      if (count >= need) {
        out.push(...played.filter(c => c.rank === rank).slice(0, need));
      }
    }
    if (type === "two_pair") {
      const pairs = Object.entries(rc).filter(([, c]) => c >= 2).map(([r]) => r);
      if (pairs.length >= 2) {
        return pairs.slice(0, 2).flatMap(r => played.filter(c => c.rank === r).slice(0, 2));
      }
    }
    return out.length ? out : played;
  }
  if (type === "straight" || type === "flush" || type === "straight_flush" || type === "full_house") {
    return [...played];
  }
  return [...played];
}

export function createDeck() {
  const deck = [];
  let id = 0;
  for (const suit of SUITS) {
    for (const rank of RANKS) {
      deck.push({ id: id++, rank, suit, enhancement: null, seal: null, bonusChips: 0 });
    }
  }
  return deck;
}

export function shuffle(arr) {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

export function cardLabel(c) {
  return `${c.rank}${SUIT_SYM[c.suit]}`;
}
