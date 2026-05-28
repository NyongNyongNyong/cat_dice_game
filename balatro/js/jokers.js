/**
 * All 150 Balatro jokers (v1.0.1o) — scoring & hand-mod effects wired;
 * economy/tarot/planet-only jokers are registered but no-op in this skeleton.
 */
import { rankVal, isFace, isEvenRank, isOddRank } from "./poker.js";

/** @typedef {{ chips:number, mult:number, xmult:number, money:number, log:string[] }} ScoreCtx */
/** @typedef {{ hand, played, scoring, held, jokers, state, joker, jokerIndex }} JokerCtx */

function def(id, name, rarity, cost, desc, hooks = {}) {
  return { id, name, rarity, cost, desc, ...hooks };
}

/** Stateful joker instance */
export function createJokerInstance(defId, registry) {
  const d = registry[defId];
  if (!d) return null;
  return {
    defId,
    name: d.name,
    sell: Math.max(1, Math.floor(d.cost / 2)),
    state: structuredClone(d.initialState || {}),
  };
}

export const JOKER_DEFS = {};

function reg(j) {
  JOKER_DEFS[j.id] = j;
}

// ─── 1–16 Common independents / on-scored suits ─────────────────────────────
reg(def("joker", "Joker", "common", 2, "+4 Mult", {
  independent(c) { c.mult += 4; },
}));
reg(def("greedy", "Greedy Joker", "common", 5, "Diamonds scored: +3 Mult each", {
  onScored(card, c) { if (card.suit === "D") c.mult += 3; },
}));
reg(def("lusty", "Lusty Joker", "common", 5, "Hearts scored: +3 Mult each", {
  onScored(card, c) { if (card.suit === "H") c.mult += 3; },
}));
reg(def("wrathful", "Wrathful Joker", "common", 5, "Spades scored: +3 Mult each", {
  onScored(card, c) { if (card.suit === "S") c.mult += 3; },
}));
reg(def("gluttonous", "Gluttonous Joker", "common", 5, "Clubs scored: +3 Mult each", {
  onScored(card, c) { if (card.suit === "C") c.mult += 3; },
}));
reg(def("jolly", "Jolly Joker", "common", 3, "+8 Mult if contains Pair", {
  independent(c, ctx) { if (ctx.hand.containsType("pair")) c.mult += 8; },
}));
reg(def("zany", "Zany Joker", "common", 4, "+12 Mult if contains Three of a Kind", {
  independent(c, ctx) { if (ctx.hand.containsType("three_kind")) c.mult += 12; },
}));
reg(def("mad", "Mad Joker", "common", 4, "+10 Mult if contains Two Pair", {
  independent(c, ctx) { if (ctx.hand.containsType("two_pair")) c.mult += 10; },
}));
reg(def("crazy", "Crazy Joker", "common", 4, "+12 Mult if contains Straight", {
  independent(c, ctx) { if (ctx.hand.containsType("straight")) c.mult += 12; },
}));
reg(def("droll", "Droll Joker", "common", 4, "+10 Mult if contains Flush", {
  independent(c, ctx) { if (ctx.hand.containsType("flush")) c.mult += 10; },
}));
reg(def("sly", "Sly Joker", "common", 3, "+50 Chips if contains Pair", {
  independent(c, ctx) { if (ctx.hand.containsType("pair")) c.chips += 50; },
}));
reg(def("wily", "Wily Joker", "common", 4, "+100 Chips if contains Three of a Kind", {
  independent(c, ctx) { if (ctx.hand.containsType("three_kind")) c.chips += 100; },
}));
reg(def("clever", "Clever Joker", "common", 4, "+80 Chips if contains Two Pair", {
  independent(c, ctx) { if (ctx.hand.containsType("two_pair")) c.chips += 80; },
}));
reg(def("devious", "Devious Joker", "common", 4, "+100 Chips if contains Straight", {
  independent(c, ctx) { if (ctx.hand.containsType("straight")) c.chips += 100; },
}));
reg(def("crafty", "Crafty Joker", "common", 4, "+80 Chips if contains Flush", {
  independent(c, ctx) { if (ctx.hand.containsType("flush")) c.chips += 80; },
}));
reg(def("half", "Half Joker", "common", 5, "+20 Mult if ≤3 cards played", {
  independent(c, ctx) { if (ctx.played.length <= 3) c.mult += 20; },
}));

// ─── 17–40 ───────────────────────────────────────────────────────────────────
reg(def("stencil", "Joker Stencil", "uncommon", 8, "X1 Mult per empty Joker slot (incl. self)", {
  independent(c, ctx) {
    const empty = 5 - ctx.jokers.length;
    c.xmult *= Math.max(1, empty);
  },
}));
reg(def("four_fingers", "Four Fingers", "uncommon", 7, "Flushes/Straights need 4 cards", {
  passive: { fourFingers: true },
}));
reg(def("mime", "Mime", "uncommon", 5, "Retrigger held-in-hand abilities", {
  passive: { mime: true },
}));
reg(def("credit_card", "Credit Card", "common", 1, "Go up to -$20 debt", { passive: { creditCard: true } }));
reg(def("ceremonial", "Ceremonial Dagger", "uncommon", 6, "On blind: destroy right joker, +2× sell to Mult", {
  initialState: { bonusMult: 0 },
  onBlindSelect(ctx) {
    const idx = ctx.jokerIndex;
    const right = ctx.jokers[idx + 1];
    if (right) {
      ctx.jokers.splice(idx + 1, 1);
      ctx.joker.state.bonusMult += right.sell * 2;
    }
  },
  independent(c, ctx) { c.mult += ctx.joker.state.bonusMult || 0; },
}));
reg(def("banner", "Banner", "common", 5, "+30 Chips per discard remaining", {
  independent(c, ctx) { c.chips += 30 * ctx.state.discardsLeft; },
}));
reg(def("mystic_summit", "Mystic Summit", "common", 5, "+15 Mult when 0 discards left", {
  independent(c, ctx) { if (ctx.state.discardsLeft === 0) c.mult += 15; },
}));
reg(def("marble", "Marble Joker", "uncommon", 6, "Adds Stone card on blind (skeleton: +1 stone in deck)", {
  onBlindSelect(ctx) { ctx.state.deckMods.push({ type: "stone" }); },
}));
reg(def("loyalty", "Loyalty Card", "uncommon", 5, "X4 Mult every 6 hands", {
  initialState: { counter: 0 },
  independent(c, ctx) {
    const j = ctx.joker;
    j.state.counter = (j.state.counter + 1) % 6;
    if (j.state.counter === 0) c.xmult *= 4;
  },
}));
reg(def("eight_ball", "8 Ball", "common", 5, "1/4: 8 scored creates Tarot (no-op in skeleton)", {}));
reg(def("misprint", "Misprint", "common", 4, "+0–23 Mult", {
  independent(c) { c.mult += Math.floor(Math.random() * 24); },
}));
reg(def("dusk", "Dusk", "uncommon", 5, "Retrigger all cards on final hand", {
  passive: { dusk: true },
}));
reg(def("raised_fist", "Raised Fist", "common", 5, "+2× rank of lowest held card to Mult", {
  onHeld(c, ctx) {
    if (!ctx.held.length) return;
    const low = ctx.held.reduce((a, b) => (rankVal(a.rank) < rankVal(b.rank) ? a : b));
    c.mult += rankVal(low.rank) * 2;
  },
}));
reg(def("chaos", "Chaos the Clown", "common", 4, "1 free shop reroll (skeleton: no shop reroll cost)", {
  passive: { freeReroll: true },
}));
reg(def("fibonacci", "Fibonacci", "uncommon", 8, "A,2,3,5,8 scored: +8 Mult each", {
  onScored(card, c) {
    if (["A","2","3","5","8"].includes(card.rank)) c.mult += 8;
  },
}));
reg(def("steel_joker", "Steel Joker", "uncommon", 7, "X0.2 Mult per Steel card in deck", {
  independent(c, ctx) {
    const n = ctx.state.fullDeck.filter(x => x.enhancement === "steel").length;
    c.xmult *= 1 + n * 0.2;
  },
}));
reg(def("scary_face", "Scary Face", "common", 4, "Face cards scored: +30 Chips", {
  onScored(card, c, ctx) {
    if (isFace(card.rank, ctx.state.pareidolia)) c.chips += 30;
  },
}));
reg(def("abstract", "Abstract Joker", "common", 4, "+3 Mult per Joker", {
  independent(c, ctx) { c.mult += 3 * ctx.jokers.length; },
}));
reg(def("delayed", "Delayed Gratification", "common", 4, "$2 per unused discard (end round)", {
  onRoundEnd(ctx) {
    if (ctx.state.discardsLeft > 0) ctx.state.money += ctx.state.discardsLeft * 2;
  },
}));
reg(def("hack", "Hack", "uncommon", 6, "Retrigger 2,3,4,5 scored", {
  onScored(card, c, ctx) {
    if (!ctx.isRetrigger && ["2","3","4","5"].includes(card.rank)) {
      ctx.state.retriggerScored.push(card);
    }
  },
}));
reg(def("pareidolia", "Pareidolia", "uncommon", 5, "All cards count as face cards", {
  passive: { pareidolia: true },
}));
reg(def("gros_michel", "Gros Michel", "common", 5, "+15 Mult", {
  independent(c) { c.mult += 15; },
}));
reg(def("even_steven", "Even Steven", "common", 4, "Even ranks scored: +4 Mult", {
  onScored(card, c) { if (isEvenRank(card.rank)) c.mult += 4; },
}));
reg(def("odd_todd", "Odd Todd", "common", 4, "Odd ranks scored: +31 Chips", {
  onScored(card, c) { if (isOddRank(card.rank)) c.chips += 31; },
}));
reg(def("scholar", "Scholar", "common", 4, "Aces scored: +20 Chips, +4 Mult", {
  onScored(card, c) { if (card.rank === "A") { c.chips += 20; c.mult += 4; } },
}));
reg(def("business", "Business Card", "common", 4, "1/2: face scored earns $2", {
  onScored(card, c, ctx) {
    if (isFace(card.rank, ctx.state.pareidolia) && Math.random() < 0.5) ctx.state.money += 2;
  },
}));
reg(def("supernova", "Supernova", "common", 5, "+Mult = times this hand played this run", {
  independent(c, ctx) {
    const n = ctx.state.handPlayCounts[ctx.hand.type] || 0;
    c.mult += n;
  },
}));
reg(def("ride_bus", "Ride the Bus", "common", 6, "+1 Mult per hand without scoring face; resets on face", {
  initialState: { streak: 0 },
  beforeIndependent(ctx) {
    const j = ctx.joker;
    const hadFace = ctx.scoring.some(c => isFace(c.rank, ctx.state.pareidolia));
    if (hadFace) j.state.streak = 0;
    else j.state.streak++;
  },
  independent(c, ctx) { c.mult += ctx.joker.state.streak; },
}));
reg(def("space", "Space Joker", "uncommon", 5, "1/4: level up played hand", {
  onAfterPlay(ctx) {
    if (Math.random() < 0.25) {
      const lv = ctx.state.handLevels[ctx.hand.type] || 1;
      ctx.state.handLevels[ctx.hand.type] = lv + 1;
    }
  },
}));
reg(def("egg", "Egg", "common", 4, "+$3 sell value end of round", {
  onRoundEnd(ctx) { ctx.joker.sell += 3; },
}));
reg(def("burglar", "Burglar", "uncommon", 6, "On blind: +3 Hands, lose discards", {
  onBlindSelect(ctx) { ctx.state.handsLeft += 3; ctx.state.discardsLeft = 0; },
}));
reg(def("blackboard", "Blackboard", "uncommon", 6, "X3 Mult if all held are ♠ or ♣", {
  independent(c, ctx) {
    if (ctx.held.length && ctx.held.every(x => x.suit === "S" || x.suit === "C")) c.xmult *= 3;
  },
}));
reg(def("runner", "Runner", "common", 5, "+15 Chips if contains Straight (stacks)", {
  initialState: { chips: 0 },
  independent(c, ctx) {
    if (ctx.hand.containsType("straight")) ctx.joker.state.chips += 15;
    c.chips += ctx.joker.state.chips;
  },
}));
reg(def("ice_cream", "Ice Cream", "common", 5, "+100 Chips, -5 per hand played", {
  initialState: { chips: 100 },
  independent(c, ctx) {
    c.chips += ctx.joker.state.chips;
    ctx.joker.state.chips = Math.max(0, ctx.joker.state.chips - 5);
  },
}));
reg(def("dna", "DNA", "rare", 8, "First hand 1 card: copy to deck (skeleton: skip)", {}));
reg(def("splash", "Splash", "common", 3, "All played cards score", { passive: { splash: true } }));
reg(def("blue", "Blue Joker", "common", 5, "+2 Chips per card left in deck", {
  independent(c, ctx) { c.chips += 2 * ctx.state.deckRemaining; },
}));
reg(def("sixth_sense", "Sixth Sense", "uncommon", 6, "First hand single 6: destroy & spectral (skip)", {}));
reg(def("constellation", "Constellation", "uncommon", 6, "X0.1 Mult per planet used (skip)", {
  initialState: { x: 1 },
  independent(c, ctx) { c.xmult *= ctx.joker.state.x || 1; },
}));
reg(def("hiker", "Hiker", "uncommon", 5, "Scored cards permanently +5 Chips", {
  onScored(card) { card.bonusChips = (card.bonusChips || 0) + 5; },
}));
reg(def("faceless", "Faceless Joker", "common", 4, "$5 if 3+ face discarded together", {
  onDiscard(ctx, cards) {
    const n = cards.filter(c => isFace(c.rank, ctx.state.pareidolia)).length;
    if (n >= 3) ctx.state.money += 5;
  },
}));
reg(def("green", "Green Joker", "common", 4, "+1 Mult per hand, -1 per discard", {
  initialState: { mult: 0 },
  onHandPlayed(ctx) { ctx.joker.state.mult++; },
  onDiscardAction(ctx) { ctx.joker.state.mult = Math.max(0, ctx.joker.state.mult - 1); },
  independent(c, ctx) { c.mult += ctx.joker.state.mult; },
}));
reg(def("superposition", "Superposition", "common", 4, "Ace+Straight: create Tarot (skip)", {}));
reg(def("todo", "To Do List", "common", 4, "$4 if hand is target type (random)", {
  initialState: { target: "pair" },
  onHandPlayed(ctx) {
    if (ctx.hand.is(ctx.joker.state.target)) ctx.state.money += 4;
  },
}));
reg(def("cavendish", "Cavendish", "common", 4, "X3 Mult", { independent(c) { c.xmult *= 3; } }));
reg(def("card_sharp", "Card Sharp", "uncommon", 6, "X3 Mult if hand type already played this round", {
  independent(c, ctx) {
    const played = ctx.state.handsPlayedThisRound[ctx.hand.type] || 0;
    if (played > 0) c.xmult *= 3;
  },
}));
reg(def("red_card", "Red Card", "common", 5, "+3 Mult when pack skipped (skip)", { initialState: { m: 0 } }));
reg(def("madness", "Madness", "uncommon", 7, "On small/big blind: X0.5 Mult, destroy random joker", {
  initialState: { x: 1 },
  onBlindSelect(ctx) {
    ctx.joker.state.x = (ctx.joker.state.x || 1) * 1.5;
    if (ctx.jokers.length > 1) {
      const others = ctx.jokers.filter(j => j !== ctx.joker);
      const victim = others[Math.floor(Math.random() * others.length)];
      const i = ctx.jokers.indexOf(victim);
      if (i >= 0) ctx.jokers.splice(i, 1);
    }
  },
  independent(c, ctx) { c.xmult *= ctx.joker.state.x || 1; },
}));
reg(def("square", "Square Joker", "common", 4, "+4 Chips if exactly 4 cards played (stacks)", {
  initialState: { chips: 0 },
  independent(c, ctx) {
    if (ctx.played.length === 4) ctx.joker.state.chips += 4;
    c.chips += ctx.joker.state.chips;
  },
}));
reg(def("seance", "Séance", "uncommon", 6, "Straight Flush: create Spectral (skip)", {}));
reg(def("riff_raff", "Riff-Raff", "common", 6, "On blind: create 2 Common Jokers", {
  onBlindSelect(ctx) {
    for (let i = 0; i < 2 && ctx.jokers.length < 5; i++) {
      ctx.state.pendingJokers.push("common");
    }
  },
}));
reg(def("vampire", "Vampire", "uncommon", 7, "X0.1 per enhanced scored; removes enhancement", {
  initialState: { x: 1 },
  onScored(card, c, ctx) {
    if (card.enhancement) {
      ctx.joker.state.x = (ctx.joker.state.x || 1) + 0.1;
      card.enhancement = null;
    }
  },
  independent(c, ctx) { c.xmult *= ctx.joker.state.x || 1; },
}));
reg(def("shortcut", "Shortcut", "uncommon", 7, "Straights may have gaps of 1", { passive: { shortcut: true } }));
reg(def("hologram", "Hologram", "uncommon", 7, "X0.25 Mult per card added to deck", {
  initialState: { x: 1 },
  independent(c, ctx) { c.xmult *= ctx.joker.state.x || 1; },
}));
reg(def("vagabond", "Vagabond", "rare", 8, "≤$4: create Tarot (skip)", {}));
reg(def("baron", "Baron", "rare", 8, "Each King held: X1.5 Mult", {
  onHeld(c, ctx) {
    const kings = ctx.held.filter(x => x.rank === "K").length;
    for (let i = 0; i < kings; i++) c.xmult *= 1.5;
  },
}));
reg(def("cloud9", "Cloud 9", "uncommon", 7, "$1 per 9 in deck end of round", {
  onRoundEnd(ctx) {
    const n = ctx.state.fullDeck.filter(c => c.rank === "9").length;
    ctx.state.money += n;
  },
}));
reg(def("rocket", "Rocket", "uncommon", 6, "+$1 end of round (+$2 per boss)", {
  initialState: { payout: 1 },
  onRoundEnd(ctx) { ctx.state.money += ctx.joker.state.payout; },
  onBossDefeated(ctx) { ctx.joker.state.payout += 2; },
}));
reg(def("obelisk", "Obelisk", "rare", 8, "X0.2 Mult per hand not playing most-played hand", {
  initialState: { x: 1, streak: 0 },
  beforeIndependent(ctx) {
    const top = ctx.state.mostPlayedHand;
    if (top && ctx.hand.type !== top) ctx.joker.state.streak++;
    else ctx.joker.state.streak = 0;
    ctx.joker.state.x = 1 + ctx.joker.state.streak * 0.2;
  },
  independent(c, ctx) { c.xmult *= ctx.joker.state.x || 1; },
}));
reg(def("midas", "Midas Mask", "uncommon", 7, "Played face → Gold when scored (skeleton: +$1)", {
  onScored(card, c, ctx) {
    if (isFace(card.rank, ctx.state.pareidolia)) ctx.state.money += 1;
  },
}));
reg(def("luchador", "Luchador", "uncommon", 5, "Sell: disable boss blind (skip)", {}));
reg(def("photograph", "Photograph", "common", 5, "First face scored: X2 Mult", {
  initialState: { used: false },
  onScored(card, c, ctx) {
    if (!ctx.joker.state.used && isFace(card.rank, ctx.state.pareidolia)) {
      c.xmult *= 2;
      ctx.joker.state.used = true;
    }
  },
  onHandPlayed(ctx) { ctx.joker.state.used = false; },
}));
reg(def("gift", "Gift Card", "uncommon", 6, "+$1 sell all jokers end round", {
  onRoundEnd(ctx) { for (const j of ctx.jokers) j.sell++; },
}));
reg(def("turtle", "Turtle Bean", "uncommon", 6, "+5 hand size, -1 per round", {
  passive: { handSizeBonus: 5, handSizeDecay: true },
}));
reg(def("erosion", "Erosion", "uncommon", 6, "+4 Mult per card below 52 in deck", {
  independent(c, ctx) {
    const missing = 52 - ctx.state.fullDeck.length;
    c.mult += 4 * missing;
  },
}));
reg(def("reserved", "Reserved Parking", "common", 6, "1/2: held face gives $1", {
  onHeld(ctx) {
    for (const card of ctx.held) {
      if (isFace(card.rank, ctx.state.pareidolia) && Math.random() < 0.5) ctx.state.money += 1;
    }
  },
}));
reg(def("mail", "Mail-In Rebate", "common", 4, "$5 per discard of target rank", {
  initialState: { rank: "A" },
  onDiscard(ctx, cards) {
    const n = cards.filter(c => c.rank === ctx.joker.state.rank).length;
    ctx.state.money += n * 5;
  },
}));
reg(def("to_the_moon", "To the Moon", "uncommon", 5, "Extra interest (skip)", {}));
reg(def("hallucination", "Hallucination", "common", 4, "1/2 Tarot on pack (skip)", {}));
reg(def("fortune", "Fortune Teller", "common", 6, "+1 Mult per tarot used (skip)", { initialState: { m: 0 } }));
reg(def("juggler", "Juggler", "common", 4, "+1 hand size", { passive: { handSizeBonus: 1 } }));
reg(def("drunkard", "Drunkard", "common", 4, "+1 discard", { passive: { discardsBonus: 1 } }));
reg(def("stone_joker", "Stone Joker", "uncommon", 6, "+25 Chips per Stone in deck", {
  independent(c, ctx) {
    const n = ctx.state.fullDeck.filter(x => x.enhancement === "stone").length;
    c.chips += 25 * n;
  },
}));
reg(def("golden", "Golden Joker", "common", 6, "+$4 end of round", {
  onRoundEnd(ctx) { ctx.state.money += 4; },
}));
reg(def("lucky_cat", "Lucky Cat", "uncommon", 6, "X0.25 per lucky trigger", { initialState: { x: 1 } }));
reg(def("baseball", "Baseball Card", "rare", 8, "Uncommon jokers: X1.5 Mult each", {
  onOtherJoker(c, other) {
    const d = JOKER_DEFS[other.defId];
    if (d && d.rarity === "uncommon") c.xmult *= 1.5;
  },
}));
reg(def("bull", "Bull", "uncommon", 6, "+2 Chips per $1", {
  independent(c, ctx) { c.chips += 2 * Math.max(0, ctx.state.money); },
}));
reg(def("diet_cola", "Diet Cola", "uncommon", 6, "Sell: Double Tag (skip)", {}));
reg(def("trading", "Trading Card", "uncommon", 6, "First discard 1 card: destroy, +$3", {
  initialState: { used: false },
  onDiscard(ctx, cards) {
    if (!ctx.joker.state.used && cards.length === 1) {
      ctx.joker.state.used = true;
      ctx.state.money += 3;
    }
  },
  onRoundEnd(ctx) { ctx.joker.state.used = false; },
}));
reg(def("flash", "Flash Card", "uncommon", 5, "+2 Mult per shop reroll", { initialState: { m: 0 } }));
reg(def("popcorn", "Popcorn", "common", 5, "+20 Mult, -4 per round", {
  initialState: { mult: 20, round: 0 },
  independent(c, ctx) {
    c.mult += Math.max(0, ctx.joker.state.mult - ctx.joker.state.round * 4);
  },
  onRoundEnd(ctx) { ctx.joker.state.round++; },
}));
reg(def("spare_trousers", "Spare Trousers", "uncommon", 6, "+2 Mult if contains Two Pair (stacks)", {
  initialState: { mult: 0 },
  independent(c, ctx) {
    if (ctx.hand.containsType("two_pair")) ctx.joker.state.mult += 2;
    c.mult += ctx.joker.state.mult;
  },
}));
reg(def("ancient", "Ancient Joker", "rare", 8, "Scored [suit]: X1.5 Mult", {
  initialState: { suit: "H" },
  onScored(card, c, ctx) { if (card.suit === ctx.joker.state.suit) c.xmult *= 1.5; },
}));
reg(def("ramen", "Ramen", "uncommon", 6, "X2 Mult, -0.01 per discard", {
  initialState: { x: 2 },
  onDiscardAction(ctx) { ctx.joker.state.x = Math.max(1, (ctx.joker.state.x || 2) - 0.01 * ctx.state.lastDiscardCount); },
  independent(c, ctx) { c.xmult *= ctx.joker.state.x || 1; },
}));
reg(def("walkie", "Walkie Talkie", "common", 4, "10 or 4 scored: +10 Chips, +4 Mult", {
  onScored(card, c) { if (card.rank === "10" || card.rank === "4") { c.chips += 10; c.mult += 4; } },
}));
reg(def("seltzer", "Seltzer", "uncommon", 6, "Retrigger all played next 10 hands", {
  initialState: { left: 10 },
  onScored(card, c, ctx) {
    if (!ctx.isRetrigger && ctx.joker.state.left > 0) ctx.state.retriggerScored.push(card);
  },
  onHandPlayed(ctx) { if (ctx.joker.state.left > 0) ctx.joker.state.left--; },
}));
reg(def("castle", "Castle", "uncommon", 6, "+3 Chips per discarded [suit] (stacks)", {
  initialState: { suit: "H", chips: 0 },
  onDiscard(ctx, cards) {
    const n = cards.filter(c => c.suit === ctx.joker.state.suit).length;
    ctx.joker.state.chips += n * 3;
  },
  independent(c, ctx) { c.chips += ctx.joker.state.chips; },
}));
reg(def("smiley", "Smiley Face", "common", 4, "Face scored: +5 Mult", {
  onScored(card, c, ctx) { if (isFace(card.rank, ctx.state.pareidolia)) c.mult += 5; },
}));
reg(def("campfire", "Campfire", "rare", 9, "X0.25 per card sold (resets on boss)", {
  initialState: { x: 1 },
  independent(c, ctx) { c.xmult *= ctx.joker.state.x || 1; },
}));
reg(def("golden_ticket", "Golden Ticket", "common", 5, "Gold cards scored: +$4", {
  onScored(card, ctx) { if (card.enhancement === "gold") ctx.state.money += 4; },
}));
reg(def("mr_bones", "Mr. Bones", "uncommon", 5, "Prevent death at 25% score once", { passive: { mrBones: true } }));
reg(def("acrobat", "Acrobat", "uncommon", 6, "X3 Mult on final hand of round", {
  independent(c, ctx) { if (ctx.state.handsLeft === 0) c.xmult *= 3; },
}));
reg(def("sock_buskin", "Sock and Buskin", "uncommon", 6, "Retrigger face cards scored", {
  onScored(card, c, ctx) {
    if (!ctx.isRetrigger && isFace(card.rank, ctx.state.pareidolia)) {
      ctx.state.retriggerScored.push(card);
    }
  },
}));
reg(def("swashbuckler", "Swashbuckler", "common", 4, "+Mult = sum other jokers' sell", {
  independent(c, ctx) {
    const sum = ctx.jokers.filter(j => j !== ctx.joker).reduce((s, j) => s + j.sell, 0);
    c.mult += sum;
  },
}));
reg(def("troubadour", "Troubadour", "uncommon", 6, "+2 hand size, -1 hand per round", {
  passive: { handSizeBonus: 2, handsPenalty: 1 },
}));
reg(def("certificate", "Certificate", "uncommon", 6, "Round start: random sealed card (skip)", {}));
reg(def("smeared", "Smeared Joker", "uncommon", 7, "♥=♦, ♠=♣ for scoring", { passive: { smeared: true } }));
reg(def("throwback", "Throwback", "uncommon", 6, "X0.25 per blind skipped", {
  initialState: { skips: 0 },
  independent(c, ctx) { c.xmult *= 1 + (ctx.joker.state.skips || 0) * 0.25; },
}));
reg(def("hanging_chad", "Hanging Chad", "common", 4, "Retrigger first scoring card 2×", {
  onAfterScoring(ctx) {
    if (ctx.scoring[0]) {
      ctx.state.retriggerScored.push(ctx.scoring[0], ctx.scoring[0]);
    }
  },
}));
reg(def("rough_gem", "Rough Gem", "uncommon", 7, "Diamonds scored: +$1", {
  onScored(card, ctx) { if (card.suit === "D") ctx.state.money += 1; },
}));
reg(def("bloodstone", "Bloodstone", "uncommon", 7, "1/2: Hearts scored X1.5 Mult", {
  onScored(card, c) { if (card.suit === "H" && Math.random() < 0.5) c.xmult *= 1.5; },
}));
reg(def("arrowhead", "Arrowhead", "uncommon", 7, "Spades scored: +50 Chips", {
  onScored(card, c) { if (card.suit === "S") c.chips += 50; },
}));
reg(def("onyx", "Onyx Agate", "uncommon", 7, "Clubs scored: +7 Mult", {
  onScored(card, c) { if (card.suit === "C") c.mult += 7; },
}));
reg(def("glass_joker", "Glass Joker", "uncommon", 6, "X0.75 per Glass destroyed", {
  initialState: { x: 1 },
  independent(c, ctx) { c.xmult *= ctx.joker.state.x || 1; },
}));
reg(def("showman", "Showman", "uncommon", 5, "Duplicates allowed in shop (passive flag)", { passive: { showman: true } }));
reg(def("flower_pot", "Flower Pot", "uncommon", 6, "X3 if ♦♣♥♠ all in scoring", {
  independent(c, ctx) {
    const suits = new Set(ctx.scoring.map(x => x.suit));
    if (["D","C","H","S"].every(s => suits.has(s))) c.xmult *= 3;
  },
}));
reg(def("blueprint", "Blueprint", "rare", 10, "Copy joker to the right", {
  copyRight: true,
}));
reg(def("wee", "Wee Joker", "rare", 8, "+8 Chips per 2 scored (stacks)", {
  initialState: { chips: 0 },
  onScored(card, c, ctx) {
    if (card.rank === "2") ctx.joker.state.chips += 8;
    c.chips += ctx.joker.state.chips;
  },
}));
reg(def("merry_andy", "Merry Andy", "uncommon", 7, "+3 discards, -1 hand size", {
  passive: { discardsBonus: 3, handSizeBonus: -1 },
}));
reg(def("oops", "Oops! All 6s", "uncommon", 4, "Double probabilities", { passive: { oops: true } }));
reg(def("idol", "The Idol", "uncommon", 6, "[rank] of [suit] scored: X2 Mult", {
  initialState: { rank: "7", suit: "C" },
  onScored(card, c, ctx) {
    if (card.rank === ctx.joker.state.rank && card.suit === ctx.joker.state.suit) c.xmult *= 2;
  },
}));
reg(def("seeing_double", "Seeing Double", "uncommon", 6, "X2 if scoring Club + other suit", {
  independent(c, ctx) {
    const suits = new Set(ctx.scoring.map(x => x.suit));
    if (suits.has("C") && [...suits].some(s => s !== "C")) c.xmult *= 2;
  },
}));
reg(def("matador", "Matador", "uncommon", 7, "$8 if boss ability triggers (skip)", {}));
reg(def("hit_road", "Hit the Road", "rare", 8, "X0.5 per Jack discarded this round", {
  initialState: { x: 1 },
  onDiscard(ctx, cards) {
    const n = cards.filter(c => c.rank === "J").length;
    ctx.joker.state.x = (ctx.joker.state.x || 1) + n * 0.5;
  },
  independent(c, ctx) { c.xmult *= ctx.joker.state.x || 1; },
  onRoundEnd(ctx) { ctx.joker.state.x = 1; },
}));
reg(def("duo", "The Duo", "rare", 8, "X2 if contains Pair", {
  independent(c, ctx) { if (ctx.hand.containsType("pair")) c.xmult *= 2; },
}));
reg(def("trio", "The Trio", "rare", 8, "X3 if contains Three of a Kind", {
  independent(c, ctx) { if (ctx.hand.containsType("three_kind")) c.xmult *= 3; },
}));
reg(def("family", "The Family", "rare", 8, "X4 if contains Four of a Kind", {
  independent(c, ctx) { if (ctx.hand.containsType("four_kind")) c.xmult *= 4; },
}));
reg(def("order", "The Order", "rare", 8, "X3 if contains Straight", {
  independent(c, ctx) { if (ctx.hand.containsType("straight")) c.xmult *= 3; },
}));
reg(def("tribe", "The Tribe", "rare", 8, "X2 if contains Flush", {
  independent(c, ctx) { if (ctx.hand.containsType("flush")) c.xmult *= 2; },
}));
reg(def("stuntman", "Stuntman", "rare", 7, "+250 Chips, -2 hand size", {
  passive: { handSizeBonus: -2 },
  independent(c) { c.chips += 250; },
}));
reg(def("invisible", "Invisible Joker", "rare", 8, "After 2 rounds sell to duplicate joker (skip)", { initialState: { rounds: 0 } }));
reg(def("brainstorm", "Brainstorm", "rare", 10, "Copy leftmost joker", { copyLeft: true }));
reg(def("satellite", "Satellite", "uncommon", 6, "$1 per unique planet used (skip)", {}));
reg(def("shoot_moon", "Shoot the Moon", "common", 5, "Each Queen held: +13 Mult", {
  onHeld(c, ctx) { c.mult += 13 * ctx.held.filter(x => x.rank === "Q").length; },
}));
reg(def("drivers", "Driver's License", "rare", 7, "X3 if 16+ enhanced in deck", {
  independent(c, ctx) {
    const n = ctx.state.fullDeck.filter(x => x.enhancement).length;
    if (n >= 16) c.xmult *= 3;
  },
}));
reg(def("cartomancer", "Cartomancer", "uncommon", 6, "Create Tarot on blind (skip)", {}));
reg(def("astronomer", "Astronomer", "uncommon", 8, "Planets free (skip)", {}));
reg(def("burnt", "Burnt Joker", "rare", 8, "Level up first discard hand (skip)", {}));
reg(def("bootstraps", "Bootstraps", "uncommon", 7, "+2 Mult per $5", {
  independent(c, ctx) { c.mult += Math.floor(ctx.state.money / 5) * 2; },
}));
reg(def("canio", "Canio", "legendary", 0, "X1 per face destroyed (stacks)", {
  initialState: { x: 1 },
  independent(c, ctx) { c.xmult *= ctx.joker.state.x || 1; },
}));
reg(def("triboulet", "Triboulet", "legendary", 0, "Kings & Queens scored: X2 Mult", {
  onScored(card, c) { if (card.rank === "K" || card.rank === "Q") c.xmult *= 2; },
}));
reg(def("yorick", "Yorick", "legendary", 0, "X1 per 23 discards", {
  initialState: { discards: 0, x: 1 },
  onDiscardAction(ctx) {
    ctx.joker.state.discards += ctx.state.lastDiscardCount;
    while (ctx.joker.state.discards >= 23) {
      ctx.joker.state.discards -= 23;
      ctx.joker.state.x = (ctx.joker.state.x || 1) + 1;
    }
  },
  independent(c, ctx) { c.xmult *= ctx.joker.state.x || 1; },
}));
reg(def("chicot", "Chicot", "legendary", 0, "Disable boss blind (skip)", { passive: { chicot: true } }));
reg(def("perkeo", "Perkeo", "legendary", 0, "Negative copy consumable (skip)", {}));

export const JOKER_IDS = Object.keys(JOKER_DEFS);

export function getPassiveFlags(jokers) {
  const f = {
    fourFingers: false, shortcut: false, splash: false, pareidolia: false,
    smeared: false, handSizeBonus: 0, discardsBonus: 0, handsPenalty: 0,
    handSizeDecay: false, mime: false, dusk: false, mrBones: false, showman: false,
  };
  for (const j of jokers) {
    const d = JOKER_DEFS[j.defId];
    if (!d?.passive) continue;
    const p = d.passive;
    if (p.fourFingers) f.fourFingers = true;
    if (p.shortcut) f.shortcut = true;
    if (p.splash) f.splash = true;
    if (p.pareidolia) f.pareidolia = true;
    if (p.smeared) f.smeared = true;
    if (p.mime) f.mime = true;
    if (p.dusk) f.dusk = true;
    if (p.mrBones) f.mrBones = true;
    if (p.showman) f.showman = true;
    if (p.handSizeDecay) f.handSizeDecay = true;
    f.handSizeBonus += p.handSizeBonus || 0;
    f.discardsBonus += p.discardsBonus || 0;
    f.handsPenalty += p.handsPenalty || 0;
  }
  return f;
}

function resolveJokerDef(joker, jokers, index) {
  const d = JOKER_DEFS[joker.defId];
  if (!d) return null;
  if (d.copyRight && jokers[index + 1]) return JOKER_DEFS[jokers[index + 1].defId];
  if (d.copyLeft && jokers[0]) return JOKER_DEFS[jokers[0].defId];
  return d;
}

export function applyJokerPipeline(phase, baseCtx) {
  const { jokers, state } = baseCtx;
  const score = { chips: 0, mult: 0, xmult: 1, money: 0, log: [] };

  for (let i = 0; i < jokers.length; i++) {
    const joker = jokers[i];
    const def = resolveJokerDef(joker, jokers, i);
    if (!def) continue;
    const ctx = { ...baseCtx, joker, jokerIndex: i, def };

    if (phase === "beforeIndependent" && def.beforeIndependent) def.beforeIndependent(ctx);
    if (phase === "independent" && def.independent) {
      const snap = { chips: score.chips, mult: score.mult };
      def.independent(score, ctx);
      if (score.chips !== snap.chips || score.mult !== snap.mult) {
        score.log.push(`${joker.name}: +${score.chips - snap.chips} chips, +${score.mult - snap.mult} mult`);
      }
    }
    if (phase === "onScored" && def.onScored) {
      for (const card of baseCtx.scoring) {
        def.onScored(card, score, ctx);
      }
    }
    if (phase === "onHeld" && def.onHeld) def.onHeld(score, ctx);
    if (phase === "afterScoring" && def.onAfterScoring) def.onAfterScoring(ctx);
  }
  return score;
}

export function pickShopJokers(n, owned, showman = false) {
  const pool = JOKER_IDS.filter(id => showman || !owned.includes(id));
  const out = [];
  for (let i = 0; i < n && pool.length; i++) {
    const idx = Math.floor(Math.random() * pool.length);
    out.push(pool.splice(idx, 1)[0]);
  }
  return out;
}

export function rarityWeight() {
  const r = Math.random();
  if (r < 0.05) return "rare";
  if (r < 0.30) return "uncommon";
  return "common";
}

export function randomJokerId(filterRarity = null) {
  let pool = JOKER_IDS.filter(id => JOKER_DEFS[id].cost > 0 || filterRarity === "legendary");
  if (filterRarity) pool = pool.filter(id => JOKER_DEFS[id].rarity === filterRarity);
  return pool[Math.floor(Math.random() * pool.length)];
}
