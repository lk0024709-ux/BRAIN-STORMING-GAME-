import 'dart:math';

enum BanterEvent {
  intro,
  fast,
  sharp,
  good,
  solved,
  wrong,
  hint,
  fifty,
  chance,
  home,
}

class BanterPair {
  const BanterPair(this.hero, this.rival);

  final String hero;
  final String rival;
}

class BanterService {
  BanterService({Random? random}) : _random = random ?? Random();

  final Random _random;

  BanterPair line(BanterEvent event, int age) {
    final pool = age < 10
        ? _kids
        : age < 17
            ? _teens
            : _adults;
    final lines = pool[event] ?? pool[BanterEvent.intro]!;
    return lines[_random.nextInt(lines.length)];
  }
}

const Map<BanterEvent, List<BanterPair>> _kids = {
  BanterEvent.home: [
    BanterPair('Ready to count super fast?', 'I already know the answer!'),
    BanterPair('One cloud. One try. You got this.', 'Hehe, don\'t mess up!'),
    BanterPair('Eyes on the cloud, hero.', 'I\'ll race you!'),
  ],
  BanterEvent.intro: [
    BanterPair('Let\'s solve this one together.', 'I bet I know it!'),
    BanterPair('Look at the cloud. Take your time.', 'Too slow and I win!'),
    BanterPair('Numbers, don\'t be shy.', 'Easy peasy... maybe.'),
  ],
  BanterEvent.fast: [
    BanterPair('Whoa, lightning fingers!', 'Okay okay, that was fast.'),
    BanterPair('Blink and you missed it.', 'Rematch. Right now.'),
  ],
  BanterEvent.sharp: [
    BanterPair('Sharp and steady.', 'Hmph. Not bad.'),
    BanterPair('That\'s a clean solve.', 'I was just about to say it.'),
  ],
  BanterEvent.good: [
    BanterPair('Good work. Keep the streak.', 'I still think I\'m faster.'),
    BanterPair('Solved! The cloud is happy.', 'Took you long enough.'),
  ],
  BanterEvent.solved: [
    BanterPair('You got there. That counts.', 'Next one, no daydreaming.'),
    BanterPair('Brains over hurry.', 'I yawned twice.'),
  ],
  BanterEvent.wrong: [
    BanterPair('Miss! Second chance?', 'I knew that one!'),
    BanterPair('Not that one. Look again.', 'The cloud is giggling.'),
  ],
  BanterEvent.hint: [
    BanterPair('Hint unlocked. Read the banner.', 'Cheater... kidding.'),
    BanterPair('A little help is still thinking.', 'I didn\'t need it.'),
  ],
  BanterEvent.fifty: [
    BanterPair('Two traps gone. Pick clean.', 'Now it\'s too easy.'),
    BanterPair('Half the noise, double the focus.', 'Fine. Your move.'),
  ],
  BanterEvent.chance: [
    BanterPair('Second chance is live. Go.', 'Don\'t waste it.'),
    BanterPair('The cloud forgives you. Once.', 'I\'m watching.'),
  ],
};

const Map<BanterEvent, List<BanterPair>> _teens = {
  BanterEvent.home: [
    BanterPair('Rival\'s talking big again.', 'Bring a real question.'),
    BanterPair('BODMAS doesn\'t care about ego.', 'Then stop stalling.'),
    BanterPair('Warm-up\'s over. Start the round.', 'I\'ll lap you.'),
  ],
  BanterEvent.intro: [
    BanterPair('Read it once. Then commit.', 'I already see it.'),
    BanterPair('Order of operations. No panic.', 'Panic looks good on you.'),
    BanterPair('Cloud\'s up. Your move.', 'Tick tock.'),
  ],
  BanterEvent.fast: [
    BanterPair('Lightning fast. Respect.', 'Tch. Lucky streak.'),
    BanterPair('That was filthy quick.', 'Again. I blinked.'),
  ],
  BanterEvent.sharp: [
    BanterPair('Sharp brain. Clean path.', 'Acceptable. Barely.'),
    BanterPair('You cut straight through it.', 'I had the same number.'),
  ],
  BanterEvent.good: [
    BanterPair('Solid solve. Stay loose.', 'I would have been faster.'),
    BanterPair('Good work. Next cloud.', 'Don\'t get comfortable.'),
  ],
  BanterEvent.solved: [
    BanterPair('Solved. Speed comes later.', 'That was a stroll.'),
    BanterPair('Correct is still correct.', 'My grandma is undefeated.'),
  ],
  BanterEvent.wrong: [
    BanterPair('Wrong panel. Second chance?', 'Called it.'),
    BanterPair('That trap had your name on it.', 'Read slower. Or don\'t.'),
  ],
  BanterEvent.hint: [
    BanterPair('Yellow banner. Use it.', 'Hints are a crutch.'),
    BanterPair('First step is on the cloud.', 'I didn\'t peek. Much.'),
  ],
  BanterEvent.fifty: [
    BanterPair('Two fakes disabled.', 'Now you have no excuse.'),
    BanterPair('50/50 locked in.', 'Coward\'s tool. Effective though.'),
  ],
  BanterEvent.chance: [
    BanterPair('Shield up. One more pick.', 'Don\'t fumble it twice.'),
    BanterPair('Second chance spent. Focus.', 'The timer is still running.'),
  ],
};

const Map<BanterEvent, List<BanterPair>> _adults = {
  BanterEvent.home: [
    BanterPair('No countdown. Just nerve.', 'Then stop posing and start.'),
    BanterPair('Decimals, series, BODMAS. Pick a poison.', 'I don\'t miss.'),
    BanterPair('The dojo is open.', 'Try to keep up, hero.'),
  ],
  BanterEvent.intro: [
    BanterPair('One formula. No flinching.', 'I\'ll take this in my sleep.'),
    BanterPair('Parse it. Then strike.', 'Already parsed.'),
    BanterPair('Cloud\'s loaded. Don\'t blink.', 'Blink and I win.'),
  ],
  BanterEvent.fast: [
    BanterPair('Lightning. That\'s the rank path.', 'Annoying. Do it again.'),
    BanterPair('Sub-five. Rival\'s quiet.', '...rematch.'),
  ],
  BanterEvent.sharp: [
    BanterPair('Sharp brain. That\'s the zone.', 'You got lucky with the order.'),
    BanterPair('Clean under twelve.', 'I was composing a speech.'),
  ],
  BanterEvent.good: [
    BanterPair('Good work. Don\'t drift.', 'Drift is all I saw.'),
    BanterPair('Correct. Tighten the next one.', 'Tighten? I\'m bored.'),
  ],
  BanterEvent.solved: [
    BanterPair('Solved. The clock was generous.', 'Generous is a kind word.'),
    BanterPair('You finished. Now finish faster.', 'I aged a year.'),
  ],
  BanterEvent.wrong: [
    BanterPair('Miss. Buy the shield or walk.', 'Walk of shame looks likely.'),
    BanterPair('That was the decoy. Own it.', 'I left that trap on purpose.'),
  ],
  BanterEvent.hint: [
    BanterPair('Banner\'s up. First operation only.', 'Still need a hint?'),
    BanterPair('Use the step. Don\'t skip it.', 'I solved it cold.'),
  ],
  BanterEvent.fifty: [
    BanterPair('Two wrongs erased.', 'The remaining one is meaner.'),
    BanterPair('50/50. Choose like you mean it.', 'Coin well spent. Maybe.'),
  ],
  BanterEvent.chance: [
    BanterPair('Shield paid. Timer didn\'t stop.', 'Pressure stays on.'),
    BanterPair('Second chance. No third.', 'Make it count.'),
  ],
};
