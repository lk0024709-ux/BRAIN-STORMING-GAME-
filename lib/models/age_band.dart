enum AgeBand { kids, teens, adults }

AgeBand ageBandFor(int age) {
  if (age < 13) return AgeBand.kids;
  if (age < 18) return AgeBand.teens;
  return AgeBand.adults;
}

extension AgeBandCopy on AgeBand {
  String get label => switch (this) {
        AgeBand.kids => 'KIDS',
        AgeBand.teens => 'TEENS',
        AgeBand.adults => 'ADULTS',
      };

  String get blurb => switch (this) {
        AgeBand.kids => 'Addition and subtraction',
        AgeBand.teens => 'Multiplication, BODMAS, series',
        AgeBand.adults => 'Complex BODMAS, series, decimals',
      };
}
