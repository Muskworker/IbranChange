require 'forwardable'

# Dictum: A word or series of segments.
class Dictum < Array
  def <<(segm)
    segm.dictum = self
    segm.pos = size

    super(segm)
  end

  def insert(idx, *segm)
    super(idx, *segm)

    segm.each { |s| s.dictum = self }
    renumber
  end

  def initialize(segments = [])
    segments.inject(self) do |dict, seg|
      dict << seg
    end
  end

  def change(origin, target, consequence = nil)
    each do |segm|
      next unless segm.match(origin) && (block_given? ? yield(segm) : true)

      segm.merge!(target)
      consequence.call(segm) if consequence
    end
  end

  def slice_before
    super.collect do |sl|
      Dictum.new(sl)
    end
  end

  def renumber
    # HACK: Should this be necessary?
    each_with_index do |segm, idx|
      segm.pos = idx
    end
  end

  def join(type = :orthography)
    inject('') do |memo, obj|
      memo << (obj[type] || '')
    end
  end

  # TODO: Replace all the delete_if with this
  def compact
    Dictum.new(self - [Segment[IPA: nil, orthography: nil]])
  end

  def compact!
    self if delete(Segment[IPA: nil, orthography: nil])
  end

  ### Linguistic functions
  # Number of syllables
  def syllable_count
    count(&:vocalic?)
  end

  def monosyllable?
    syllable_count == 1
  end

  def stressed?
    any?(&:stressed?)
  end

  def to_ipa
    renumber # Ugh

    inject('') do |output, segm|
      if syllable_count > 1 && takes_stress_mark(segm)
        output << 'ˈ' unless output =~ /ˈ\S*$/ # Don't add more than one
      end

      output << segm.to_ipa
    end
  end

  # Remove spaces
  def combine_words
    change(' ', {}, ->(s) { s.delete })
  end
end

# Determine the properties of a segment that depend on its surroundings.
module PhoneticEnvironment
  def intervocalic?
    prev.vocalic? && nxt.vocalic?
  end

  def initial?
    pos.zero? || nxt.phon == ' '
  end

  def final?
    pos == @dictum.size - 1 || nxt.phon == ' '
  end

  # TODO: replace most of the nxt & prev with this
  def before?(segm)
    nxt.match(segm)
  end

  def after?(segm)
    prev.match(segm)
  end

  def between?(fore, aft)
    prev.match(fore) && nxt.match(aft)
  end

  # TODO: Make sure this is appropriate for multi-word dictums
  def posttonic?
    @dictum[0...pos].any?(&:stressed?)
  end

  def in_onset?
    next_more_sonorous = ends_with.sonority < nxt.starts_with.sonority
    # We explicitly check for nxt.vocalic because of things like /erje/
    # (where /je/ is a diphthong).
    consonantal? && (initial? || next_more_sonorous || nxt.vocalic?)
  end

  def vowels_before
    @dictum[0...pos].count(&:vocalic?)
  end

  def vowels_after
    @dictum[pos + 1...-1].count(&:vocalic?)
  end

  def in_penult?
    final = @dictum[pos + 1...@dictum.size].find(&:final?) || @dictum.last
    vowels_from_end = @dictum[pos + 1..final.pos].count(&:vocalic?)

    # [CV]CVC - two vowels from end if onset consonant, one vowel otherwise
    vowels_from_end == (in_onset? ? 2 : 1)
  end
end

# Determine if a string has certain linguistic features.
module PhoneticFeature
  def vowel?
    vowels = 'aeioõuyæɑɐəɛɔøœ'
    neither_vowel_nor_modifier = "^aeioõuyæɑɐəɛɔøœ\u0303"
    count(vowels) == 1 && count(neither_vowel_nor_modifier).zero?
  end

  def diphthong?
    return true if %w[au ae oe].include?(self)

    vowel_count = count('aeiouyæɑɐəɛɔøœ')
    modifier_count = count("jwɥ\u032fː")
    neither_count = count("^aeiouyæɑɐəɛɔøœjwɥ\u0303\u032fː")
    vowel_count > 0 && modifier_count > 0 && neither_count.zero?
  end

  def vocalic?
    vowel? || diphthong?
  end

  def consonantal?
    !empty? && !vocalic?
  end

  def sonorant?
    %w[m ɱ ɲ ɳ n ɴ ŋ ʎ r l w j ɥ].include? self
  end

  def sibilant?
    %w[ɕ ɧ ʑ ʐ ʂ ʒ z ʃ ʃʃ s].include? self
  end

  def fricative?
    %w[h v f ç ʒ z ʃ ʃʃ s ʰ θ].include? self
  end

  def stop?
    %w[p b t d k g c].include? self
  end

  def affricate?
    %w[pf bv pɸ bβ dʑ tɕ cç ɟʝ dʒ dz tʃ ts tθ dð kx gɣ qχ ɢʁ ʡʢ].include? self
  end

  def dental?
    %w[dʑ tɕ t n d dʒ dz tʃ ts dz tθ dð θ ð l].include? self
  end

  def velar?
    %w[k g ɡ ɠ ŋ kx gɣ ɣ x ʟ].include? self
  end

  def nasal?
    %w[m ɱ ɲ ɳ n ɴ ŋ].include? self
  end

  def voiced?
    %w[w j m b ɲ ɟʝ n d dʒ g v ʎ ʒ z r l ʝ].include?(self) || vocalic?
  end

  def voiceless?
    !voiced?
  end

  def front_vowel?
    %w[e i ae y æ ɛ œ ej é].include? self
  end

  def back_vowel?
    %w[o u oe ɑ ɔ].include? self
  end

  def round?
    %w[w ɥ ɔ o œ ø u ʊ y ʏ].include? self
  end

  # Is labial consonant that turns to /w/ before a consonant per OIx4
  def labial?
    %w[p m b v f].include? self
  end

  def sonority
    if vocalic? then 6
    elsif sonorant? then 4
    elsif fricative? then 3
    elsif affricate? then 2
    elsif stop? then 1
    else 0
    end
  end
end

# PhoneticFeatures pertain to strings
class String
  include PhoneticFeature
end

# A phonetic segment and its orthographic representation.
class Segment < Hash
  include PhoneticEnvironment
  extend Forwardable
  def_delegators :phon, *PhoneticFeature.instance_methods

  attr_accessor :dictum, :pos

  def initialize(*args)
    @dictum ||= Dictum.new(self)
    @pos ||= 0
    update(IPA: args[0] || '', orthography: args[1] || args[0].dup) if args.any?
  end

  def replace!(args)
    update(IPA: args[0], orthography: args[1] || args[0].dup)
  end

  def prev
    @dictum.renumber
    @pos.zero? ? Segment.new : @dictum.fetch(@pos - 1, Segment.new)
  end

  def next
    @dictum.renumber
    @dictum.fetch(@pos + 1, Segment.new)
  end
  alias nxt next # 'next' is the best name, but it's a keyword

  def before_prev
    prev.prev
  end

  def after_next
    nxt.nxt
  end

  # TODO: Don't ever set this to nil.
  def phon
    fetch(:IPA, '') || ''
  end

  def orth
    fetch(:orthography, '')
    # @orth
  end

  def delete
    @dictum.delete_at(@pos)

    @dictum.each_with_index do |segm, idx|
      segm.pos -= 1 if idx > @pos
    end
  end

  def match(segm)
    case segm
    when Hash then segm.all? { |k, _| self[k] == segm[k] }
    when Symbol then send "#{segm}?"
    when String then phon == segm
    when Array then segm.any? { |s| match(s) }
    when Proc then segm.call(self)
    end
  end
  alias =~ match

  def match_all(*ary)
    ary.all? { |criterion| match(criterion) }
  end

  def starts_with
    Segment[IPA: phon[0], orthography: (orth || '').chars.fetch(0, '')]
  end

  def ends_with
    Segment[IPA: phon ? phon[-1] : '', orthography: orth ? orth[-1] : '']
  end

  def append(phon, orth = phon)
    self.phon << phon
    self.orth << orth
  end

  def to_ipa
    output = "#{phon}#{"\u0320" if self[:back]}#{'ʲ' if self[:palatalized]}"
    # /o:w/, not /ow:/
    output.sub!(/([jwɥ]*)$/, 'ː\1') if self[:long]
    output
  end

  ### Linguistic functions
  def stressed?
    self[:stress]
  end

  def unstressed?
    vocalic? && !self[:stress]
  end

  # Devoice a segment.  If +target+ is given, only devoice if +target+ is also
  # voiceless.
  def devoice!(target = '')
    phon.tr!('vʒzbdg', 'fʃsptk') if target.voiceless?
  end

  def voice!
    phon.tr!('fçʃsptθk', 'vʝʒzbddg')
  end

  # Set the value of this segment to another,
  # and set the value of the other segment to this
  # (or to +new_other+ if specified)
  def metathesize(other, new_other = dup)
    update(other)
    other.update(new_other)
  end
end

# Methods for converting Latin input into data
class Latin
  DIGRAPHS = /[ao]e|[ae]u|[ey][ij]|qu|[ckprt]h|./i

  # Convert Latin character to IPA
  def self.to_ipa(str)
    orth = %w[qu x z ā ă ē ĕ ī ĭ ȳ ȳ y̆ y ō ŏ ū ŭ c ch ph]
    phon = %w[kw ks dʒ a a e e i i i i i i o o u u k kh f]
    search = str.downcase

    Hash[orth.zip(phon)].fetch(search, search)
  end

  # Convert /Vns/ -> /V:s/
  def self.lengthen_before_ns_cluster(word)
    word.change(:vowel, { long: true }, lambda do |segm|
      segm.orth.tr('aeiouy', 'āēīōūȳ')
      segm.next.delete
    end) { |segm| segm.next.phon == 'n' && segm.after_next.phon == 's' }
  end

  # Convert /nguV/ sequences to /ngwV/.
  # For words like sanguis, unguis, anguilla, etc.
  def self.gu_to_gw(word)
    g = { IPA: 'g' }
    gw = { IPA: 'gw', orthography: 'gu' }

    word.change(g, gw, ->(segm) { segm.next.delete }) do |segm|
      segm.prev.phon == 'n' && segm.next.phon == 'u' && segm.after_next.vowel?
    end
  end

  def self.to_dictum(word)
    dictum = word.scan(DIGRAPHS).inject(Dictum.new) do |memo, obj|
      supra = {}
      supra[:long] = true if obj =~ /[āēīōūȳ]|ȳ/i

      phon = Latin.to_ipa(obj)
      orth = obj.tr('kzȳy', 'cjīi')

      memo << Segment[IPA: phon, orthography: orth].merge(supra)
    end

    Latin.gu_to_gw(lengthen_before_ns_cluster(dictum))
  end

  def self.stressed_syllable(word)
    vowels = word.find_all(&:vocalic?)
    vowels[-2][:long] || penult_cluster?(word) || vowels.length == 2 ? -2 : -3
  end

  # Assign Latin stress to +word+.
  # Exceptions:
  # '-' - don't assign stress
  # '!' - force final stress
  # '<' - move stress one syllable left
  # '>' - move stress one syllable right
  def self.assign_stress(word, exception = nil)
    vowels = word.find_all(&:vocalic?)

    if %w[! - > <].include? exception
      word.last.merge!(IPA: nil, orthography: nil)
    end

    if exception == '!'
      vowels[-1][:stress] = true
    elsif vowels.length > 1 && exception != '-'
      modifier = { '>' => 1, '<' => -1 }.fetch(exception, 0)
      vowels[Latin.stressed_syllable(word) + modifier][:stress] = true
    end
  end
end

# Complex exceptions to regular Ibran changes
class OldIbran
  # Outcomes of vowels before /k g l/ before dentals and nasals
  def self.cluster_change(segm)
    ipa = segm.phon
    orig = %w[a ɑ e ɛ o ɔ i u]
    phon = %w[ɑɛ̯ ɑɛ̯ ɛj ɛj ɔɛ̯ ɔɛ̯ ej oj]
    orth = %w[ae ae ei ei oe oe éi ói]
    outcomes = Hash[orig.zip(phon.zip(orth))]

    segm.replace!(outcomes[ipa])
  end

  # Outcome of clusters following stressed vowels
  def self.post_stress_cluster_changes(segm)
    prev = segm.prev
    nxt = segm.next

    if prev =~ %w[i u] then assim = segm.ends_with.phon
    else OldIbran.cluster_change(prev)
    end

    outcomes = { 'ks' => %W[#{assim}s #{nxt.vowel? ? 'ss' : 's'}],
                 'dʒ' => %W[#{assim}ʒ #{'s' if assim}#{segm.orth}],
                 'tʃ' => %W[#{assim}ʃ #{'s' if assim}#{segm.orth}] }

    outcomes.default = %W[#{nxt.phon if assim} #{assim}]

    segm.replace!(outcomes[segm.phon])
  end

  def self.unstressed_cluster_changes(segm)
    return unless (segm.velar? && segm.before?(%i[dental nasal])) \
                  || (segm =~ %i[dental velar] && segm.before?(:sibilant))

    segm.update(segm.next.starts_with)
    segm[:orthography] = 's' if segm.before?(final: true, sibilant: true)
  end

  def self.unstressed_affricate_changes(segm)
    return unless segm =~ ['ks', :affricate]

    segm[:orthography] = "s#{(segm.orth unless segm =~ 'ks') \
                             || ('s' if segm.before?(:vowel))}"
    segm[:IPA] = segm.ends_with.phon * 2
  end

  # Intervocalic T becomes L, generally.
  # But original VtVtV becomes VlVdV, and original VlVtV becomes VdVlV.
  # (In other words, T becomes D after intervocalic T
  # and L becomes D before intervocalic T.)
  def self.intervocalic_t_changes(word)
    word.change('t', Segment.new('l'), lambda do |t|
      { 't' => t.after_next, 'l' => t.before_prev }.each do |match, cons|
        cons.update(Segment.new('d')) if cons.match_all(match, :intervocalic)
      end
    end, &:intervocalic?)
  end

  def self.diphthongize_e(segm)
    return if segm.after?([:sibilant, :affricate, { palatalized: true }]) \
           || segm.prev.ends_with =~ %w[ʎ j i]

    segm[:IPA] = "j#{segm[:IPA]}"
    segm[:orthography] = "i#{segm[:orthography]}"
  end

  def self.diphthongize_open_o(segm)
    if segm.before?(:sonorant) \
    && (segm.before?(:final) || segm.after_next.consonantal?)
      segm[:IPA] = 'wɛ'
      segm[:orthography] = 'ue'
    else
      segm[:IPA] = 'ɔj'
      segm[:orthography] = 'oi'
    end
  end

  def self.diphthongize_closed_o(segm)
    return unless segm.final?                                        \
               || segm.before?(%i[vocalic intervocalic])             \
               || (segm.before?('s') && segm.after_next.consonantal? \
                   && segm.next.after_next.vowel?)

    segm.update(IPA: 'u', orthography: 'uo', long: true)
    segm.prev.orth.sub!(/q?u$/, 'u' => '', 'qu' => 'c')
  end

  # For the purpose of unstressed vowel dropping,
  # these environments prevent that from happening.
  def self.in_stop_cluster?(segm)
    segm.prev.after?(%i[stop fricative affricate]) && segm.before_prev !~ 's' \
    || segm.before_prev.nasal? && !segm.after?(%i[stop affricate])            \
    || segm.before_prev =~ 's' && (segm.after? %i[sonorant affricate])
  end

  def self.keep_unstressed_schwa?(segm)
    (segm.prev.ends_with.consonantal? && segm.before_prev.consonantal? \
    && (OldIbran.in_stop_cluster?(segm) || segm.before?('s')))         \
    || segm.after?(%w[ʃʃ ʒʒ])                                          \
    || segm.between?('s', :sibilant)
  end

  def self.between_single_consonants?(segm)
    segm.between?(%i[vocalic intervocalic], %i[vocalic intervocalic]) \
    && (segm.next.vocalic? ? 0 : segm.next.phon.length)               \
     + (segm.prev.vocalic? ? 0 : segm.prev.phon.length) <= 2
  end

  # Test for Vm#, VmC; VRm#, VRmC as used in oix3
  def self.takes_m_change(segm)
    segm.sonorant? && [segm, segm.next].any? do |s|
      s =~ 'm' && (s.next.starts_with.consonantal? || s.final?)
    end
  end

  def self.takes_l_change(segm)
    after_next = segm.after_next

    (segm.next =~ [:labial, 'l']                     \
    && after_next.starts_with =~ [:consonantal, '']) \
    || (after_next =~ [:labial, 'l']                 \
    && after_next.between?(:sonorant, [:consonantal, '']))
  end
end

def ipa(dict)
  dict.join :IPA
end

def takes_stress_mark(segm)
  return true if segm.stressed?

  dictum = segm.dictum
  stressed = dictum.index(&:stressed?)

  return false unless stressed && stressed > segm.pos
  dictum[segm.pos...stressed].all?(&:in_onset?)
end

# Upcase doesn't handle the macrons
# Theoretically 2.4 can do this correctly?
def caps(string)
  lc = 'aābcdeéēfghiījklmnoōpqrstuũūvwxyȳz'
  uc = 'AĀBCDEÉĒFGHIĪJKLMNOŌPQRSTUŨŪVWXYȲZ'
  string.tr(lc, uc)
end

# use with long vowel test to determine heavy penult
def penult_cluster?(ary)
  vowels = 0
  consonants = 0

  ary.reverse_each do |seg|
    vowels += 1 if seg.vowel?
    consonants += 1 if vowels == 1 && seg.consonantal?
  end

  consonants > 1 && vowels > 1
end

def respell_velars(ary)
  ary.each do |segm|
    next unless %w[e i].include?(segm.next.starts_with.orth)

    case segm[:IPA]
    when 'k' then segm[:orthography] = 'qu'
    when 'ç' then segm[:orthography] = 'c'
    when 'g' then segm[:orthography] = 'gu'
    when 'ʝ' then segm[:orthography] = 'g'
    end
  end
end

def respell_palatal(segm)
  # Some older calls to similar functions used
  # ʒ => c ç, ç => c ç
  # Removing it passed tests, but there may be legacy variants
  res = { 'ʃ' => %w[c ç], 'ʒ' => %w[j z], 'k' => %w[qu c], 'g' => %w[gu g] }
  front = %w[e i é].include?(segm.next.starts_with.orth) ? 0 : 1
  prec = segm.phon[-1]

  case prec
  when 'ʃ', 'ʒ' then segm[:orthography][-1] = res[prec][front]
  when 'k', 'g' then segm[:orthography] = res[prec][front]
  end
end

# use with long vowel test to determine heavy ultima
def ultima_cluster?(ary)
  vowels = 0
  consonants = 0

  ary.reverse_each do |seg|
    vowels += 1 if seg.vowel?
    consonants += 1 if vowels.zero? && seg.consonantal? && seg[:IPA]
  end

  consonants > 1
end

# break up input
def step_vl0(lemma)
  lemma = Latin.to_dictum(lemma)

  # /nf/ acts like /mf/
  lemma.change({ IPA: 'n' }, IPA: 'm') { |segm| segm.next.phon == 'f' }

  # assign stress to each word
  lemma.slice_before { |word| word[:IPA] == ' ' }.each do |word|
    Latin.assign_stress(word, word.last.orth)
  end

  lemma.compact
end

# Final /m/: to /n/ in monosyllables, to 0 elsewhere
def step_vl1(lemma)
  ary = lemma.slice_before { |word| word[:IPA] == ' ' }.flat_map do |word|
    new_final = word.monosyllable? ? { IPA: 'n', orthography: 'n' } : {}

    word.change({ IPA: 'm' },
                new_final,
                word.monosyllable? ? nil : ->(segm) { segm.delete },
                &:final?)
  end

  Dictum.new(ary)
end

# /m/ and /N/ before /n/ -> n
def step_vl2(ary)
  ary.each do |segment|
    if %w[g m].include?(segment[:IPA]) && segment.next.phon == 'n'
      segment[:IPA] = 'n'
      segment[:orthography] = 'n'
    end
  end
end

# drop final /t k d/
def step_vl3(ary)
  ary.each do |segment|
    if %w[t k d].include?(segment[:IPA]) && segment.final?
      segment[:IPA] = nil
      segment[:orthography] = nil
    end
  end.compact
end

# drop /h/
def step_vl4(ary)
  ary.each do |segment|
    segment[:IPA].delete! 'h'
    segment[:orthography].delete! 'h'
  end

  ary.delete_if { |segment| segment[:IPA] == '' }
end

# { e, i }[-stress][+penult] > j / __V
# Changed to { e, i }[-stress][-initial_syllable] > j / __V
def step_vl5(lemma)
  lemma.slice_before { |word| word[:IPA] == ' ' }.each do |word|
    word.change(%w[e i], IPA: 'j', orthography: 'j') do |segm|
      prior_vowel = word[0...segm.pos].find(&:vocalic?)
      !segm.stressed? && !segm[:long] && segm.next.vocalic? && prior_vowel
    end
  end

  lemma
end

# V[-stress][+penult] > 0
def step_vl6(lemma)
  lemma.change(:vowel, { IPA: nil, orthography: nil }, lambda do |seg|
    prev = seg.prev
    nxt = seg.next

    # putridum > puterdum
    if seg.between?(:sonorant, :consonantal) && seg.before_prev.stop?
      seg.metathesize(prev, IPA: 'e', orthography: 'e')
    end

    # t'l > tr
    nxt.update(IPA: 'r', orthography: 'r') if seg.between? 't', 'l'

    # Devoice previous if the next is voiceless
    prev.devoice!(nxt)
  end) { |s| s.posttonic? && s.in_penult? }

  lemma.compact
end

# tk |tc| > tS |c-cedilla|
def step_vl7(ary)
  ary.change('t', Segment.new('tʃ', 'ç'), ->(s) { s.next.delete }) do |segm|
    segm.next.phon == 'k'
  end
end

# stressed vowels
def step_vl8(ary)
  e_acute = Segment.new('e', 'é')
  o_acute = Segment.new('o', 'ó')

  outcomes = { 'ā' => Segment.new('ɑ', 'a'), 'a' => { IPA: 'ɑ' },
               'ae' => Segment.new('ɛ', 'e'), 'e' => { IPA: 'ɛ' },
               'ē' => e_acute, 'oe' => e_acute, 'i' => e_acute,
               'ī' => Segment.new('i', 'i'), 'o' => { IPA: 'ɔ' },
               'u' => o_acute, 'ō' => o_acute, 'au' => o_acute,
               'ū' => Segment.new('u', 'u') }

  ary.change(:stressed, { long: false }, ->(s) { s.update(outcomes[s.orth]) })
end

# unstressed vowels
def step_vl9(ary)
  e = Segment.new('ɛ', 'e')
  o = Segment.new('ɔ', 'o')

  outcome = { 'i' => e, 'ē' => e, 'e' => e, 'oe' => e, 'ae' => e, 'ou' => o,
              'ō' => o, 'o' => o, 'u' => o, 'au' => o, 'a' => { IPA: 'ɑ' },
              'ī' => Segment.new('i'), 'ū' => Segment.new('u'),
              'ā' => Segment.new('ɑ', 'a') }

  ary.change(:unstressed, { long: false }, ->(s) { s.update(outcome[s.orth]) })
end

def step_oi1(ary)
  # combine words
  ary.combine_words

  # Assign stress when none
  # Monosyllables don't get stress till end of OI.
  # But monosyllables that combined, like 'de post', get final accent.
  unless ary.stressed? || ary.monosyllable?
    ary.select(&:vocalic?).last[:stress] = true
  end

  # { [+stop], [+fric] }[+voice]j > dZ
  yod = Segment.new('dʒ', 'j')
  ary.change(%i[stop fricative], yod, ->(s) { s.next.delete }) do |segm|
    segm.voiced? && segm.next.phon == 'j'
  end
end

# { [+stop], [+fric] }[-voice]j > tS
def step_oi2(ary)
  ary.each do |segm|
    prev = segm.prev
    nxt = segm.next

    next unless (segm.sonority <= 3) && segm.voiceless? && nxt.phon == 'j'

    # ssj -> tS also.  But not stj
    prev.delete if [prev, segm].all? { |s| s.phon == 's' }

    segm.update(IPA: 'tʃ', orthography: 'ç')
    nxt.delete
  end
end

# j > dʒ / { #, V }__V
def step_oi3(ary)
  ary.change(->(s) { (s.initial? || s.intervocalic?) && s.phon == 'j' },
             Segment.new('dʒ', 'j'))
end

# nn, nj > ɲ
def step_oi4(ary)
  delete_following = ->(s) { s.next.delete while s.next =~ %w[n j] }

  ary.change('n', Segment.new('ɲ', 'nh'), delete_following) do |s|
    %w[n j].include? s.next.phon
  end
end

# ll, lj > ʎ
def step_oi5(ary)
  delete_next_and_handle_lli = lambda do |s|
    s.next.delete
    s.next.update(IPA: 'ʎ', orthography: 'i') if s.next.phon == 'j'
  end

  ary.change('l', Segment.new('ʎ', 'll'), delete_next_and_handle_lli) do |s|
    %w[l j].include? s.next.phon
  end
end

# { d, ɡ } > ∅ / V__V
def step_oi6(ary)
  ary.change(%w[d g ɡ], {}, ->(s) { s.delete }, &:intervocalic?)
end

# b > v / V__V
def step_oi7(ary)
  ary.change('b', Segment.new('v'), nil, &:intervocalic?)
end

# { ɑ, ɛ }{ i, ɛ }[-stress] > ɛj
def step_oi8(ary)
  ary.change(%w[ɑ ɛ], Segment.new('ɛj', 'ei'), ->(s) { s.next.delete }) do |s|
    s.next.match(%w[i ɛ]) && s.next.unstressed?
  end
end

# { ɛ, i }[-stress] > j / e__
def step_oi9(ary)
  ary.change('e', Segment.new('ej', 'éi'), ->(s) { s.next.delete }) do |s|
    s.next.match(%w[ɛ i]) && s.next.unstressed?
  end
end

# { i }[-stress] > j / { ɔ, o }__
def step_oi10(ary)
  yod = lambda do |s|
    s.append('j', 'i')
    s.next.delete
  end

  ary.change(%w[ɔ o], {}, yod) { |s| s.next.phon == 'i' && s.next.unstressed? }
end

# Velars before front vowels
def step_oi11(ary)
  outcomes = { 'k' => { IPA: 'tʃ' },
               'g' => { IPA: 'dʒ' },
               'kw' => { IPA: 'k', palatalized: true },
               'gw' => { IPA: 'g', palatalized: true } }

  outcomes.each do |prior, post|
    ary.change(prior, post) { |s| s.next.starts_with.front_vowel? }
  end

  ary
end

# Velars before back A
def step_oi12(ary)
  outcomes = { %w[k g] => { palatalized: true },
               'kw' => { IPA: 'k' },
               'gw' => { IPA: 'g' } }

  outcomes.each do |prior, post|
    ary.change(prior, post) { |s| s.next.match 'ɑ' }
  end

  ary
end

# Labiovelars before back vowels
def step_oi13(ary)
  outcomes = { 'kw' => { IPA: 'k', back: true },
               'gw' => { IPA: 'g', back: true } }

  outcomes.each do |prior, post|
    ary.change(prior, post) { |s| s.next.starts_with.back_vowel? }
  end

  ary
end

# Intervocalic consonants
def step_oi14(ary)
  OldIbran.intervocalic_t_changes(ary)

  ary.change('s', IPA: 'z', &:intervocalic?)
  ary.change({ back: true }, { IPA: 'g', orthography: 'gu' }, &:intervocalic?)
  ary.change(%w[p f k], {}, lambda do |s|
    s.update(Segment.new(s.voice!))
  end, &:intervocalic?)
end

# stops before liquids
def step_oi15(ary)
  ary.change(%w[p t k], {}, ->(s) { s.update(Segment.new(s.voice!)) }) do |s|
    s.next =~ %w[r l] && !s.initial? && s.prev.vowel?
  end
end

# f before liquids
def step_oi16(ary)
  ary.change('f', Segment.new('v')) { |s| s.next =~ %w[r l] }
end

# degemination
def step_oi17(ary)
  ary.change(%w[p t k r s], {}, lambda do |s|
    s[:palatalized] = s.next[:palatalized]
    s.next.delete

    s[:orthography] = 'ss' if s =~ 's'
  end) { |s| s.next =~ s.phon }
end

# Clusters
def step_oi18(ary)
  ary.change(:stressed, {}, lambda do |s|
    OldIbran.cluster_change(s)
    s.next.delete
  end) do |s|
    nxt = s.next
    after_next = s.after_next

    nxt =~ %w[k g l]                      \
        && after_next =~ %i[dental nasal] \
        && nxt !~ after_next
  end
end

# Clusters pt 2
def step_oi19(ary)
  ary.change(:vowel, {}, lambda do |segm|
    nxt = segm.next

    if segm.unstressed?
      OldIbran.unstressed_cluster_changes(nxt)
      OldIbran.unstressed_affricate_changes(nxt)
    elsif segm.before?(['ks', :affricate]) \
       || (segm.before?(%i[dental velar]) && segm.after_next.sibilant?)
      OldIbran.post_stress_cluster_changes(nxt)
    end
  end)
end

# vowel fronting
def step_oi20(ary)
  ary.change([{ IPA: 'ɔ', stress: nil }, { IPA: 'u', stress: nil }], {},
             ->(s) { s.replace!(s =~ 'ɔ' ? %w[a à] : %w[œ eu]) }) do |segm|
    segm.next.consonantal? && segm.next.phon.size == 1 \
    && segm.after_next.starts_with.front_vowel?
  end

  respell_velars(ary)
end

# vowel fronting: palatal consonants
def step_oi21(ary)
  outcomes = { 'ɑ' => %w[a à], 'ɛ' => %w[i i], 'e' => %w[i i],
               'ɔ' => %w[œ eu], 'o' => %w[œ eu] }

  ary.change(%w[ɑ ɛ e ɔ o], {}, ->(s) { s.replace!(outcomes[s.phon]) }) do |iff|
    iff.before?(%w[ɲ ʎ])
  end

  respell_velars(ary)
end

# vowel fronting: umlaut
def step_oi22(ary)
  outcomes = { 'ɑ' => %w[a ài], 'a' => %w[a ài], 'ɛ' => %w[ɛ ei],
               'e' => %w[ɛ ei], 'ɔ' => %w[œ eu], 'o' => %w[œ eu] }

  ary.change(%w[ɑ a ɛ e ɔ o], { long: true }, lambda do |segm|
    segm.replace!(outcomes[segm.phon])
    segm.after_next.delete
  end) do |iff|
    iff.before?('r') && iff.after_next =~ 'j'
  end

  respell_velars(ary)
end

# vowel fronting: r
def step_oi23(ary)
  ary.change('ɑ', IPA: 'a', orthography: 'à') do |iff|
    !iff.before?(['r', :velar]) && iff.after?('r')
  end
end

# diphthongize
def step_oi24(ary)
  ary.change(%w[ɛ e ɔ o], {}, lambda do |segm|
    case segm[:IPA]
    when 'ɛ', 'e' then OldIbran.diphthongize_e(segm)
    when 'ɔ'      then OldIbran.diphthongize_open_o(segm)
    when 'o'      then OldIbran.diphthongize_closed_o(segm)
    end
  end) { |iff| iff.stressed? && !iff[:long] }
end

# f > h before round vowels
def step_oi25(ary)
  ary.change('f', IPA: 'h', orthography: 'h') { |iff| iff.before? :round }
end

# drop unstressed final vowels except /A/
def step_oi26(ary)
  ary.change(:vowel, {}, lambda do |segm|
    if OldIbran.keep_unstressed_schwa?(segm) || ary.monosyllable?
      segm.replace! %w[ə e]
    else segm.delete
    end

    respell_palatal(segm.prev)
  end) do |iff|
    iff !~ ['ɑ', :initial, :stressed] \
    && (iff.final? || iff.next.match_all(:final, 's'))
  end
end

# A > @
def step_oi27(ary)
  ary.change('ɑ', { IPA: 'ə', orthography: 'e' }, lambda do |segm|
    respell_palatal(segm.prev) unless %w[ʃ ç ʒ].include?(segm.prev.phon[-1])
  end) { |iff| iff.match_all(:unstressed, :final) && !ary.monosyllable? }
end

# A > @ in non-initial syllables (unless it's the only syllable)
def step_oi28(ary)
  ary.change('ɑ', IPA: 'ə', orthography: 'e') do |iff|
    iff.unstressed? && ary[0..iff.pos].syllable_count > 1
  end
end

# reduce unstressed medial syllables
def step_oi29(ary)
  ary.change(:vocalic, {}, lambda do |segm|
    if OldIbran.between_single_consonants?(segm) then segm.delete
    else segm.replace!(%w[ə e])
    end

    respell_palatal(segm.prev)
  end) do |segm|
    segm.vowels_before > 0 && segm.vowels_after > 0 \
    && segm !~ [:stressed, 'ə']
  end
end

# plural /Os As/ to /@s/
def step_oix1(ary)
  if @plural
    ary << Segment.new('ə', 'e') unless ary.last.ends_with =~ 'ə'
    ary << Segment.new('s')
  end

  ary
end

# loss of initial unstressed /E/ and /i/
def step_oix2(ary)
  ary.change(%w[ɛ i], { IPA: 'ə', orthography: 'e' }, lambda do |segm|
    if segm.before?([:in_onset, 's', 'ss'])
      segm.next[:IPA] = 's' if segm.next =~ 'ss'
      segm.next[:orthography] = 's' if segm.next.orth == 'ss'

      segm.delete
    end
  end) { |iff| iff.match_all(:unstressed, :initial) && !ary.monosyllable? }
end

# /m/ > /w~/ before consonants/finally
def step_oix3(ary)
  ary.change(:vocalic, {}, lambda do |segm|
    nxt = segm.next
    after_next = segm.after_next

    nxt.metathesize(after_next) if after_next =~ 'm'
    segm[:orthography][-1] = 'y' if segm.orth =~ /.i$/

    segm.append('w̃', 'ũ')
    nxt.delete
  end) { |iff| OldIbran.takes_m_change(iff.next) }
end

# labials & L > /w/ before consonants/finally
def step_oix4(ary)
  ary.change(:vocalic, {}, lambda do |segm|
    nxt = segm.next
    nxt.metathesize(segm.after_next) if nxt !~ [:labial, 'l']

    segm[:orthography].sub!(/(.)i$/, '\1y')
    segm.append('w', 'u')
    nxt.delete
  end) { |iff| OldIbran.takes_l_change(iff) }
end

# resolution of diphthongs in /a A @ V/
def step_oix5(ary)
  ary.change(:diphthong, { long: true }, lambda do |segm|
    # \u0303 is combining tilde
    segm[:IPA] = segm.ends_with =~ "\u0303" ? 'õ' : 'o'
  end) { |iff| iff.phon =~ /[aɑə]w?[w\u0303]$/ }
end

# resolution of diphthongs in /E e i/
def step_oix6 ary
  @current = ary.each do |segm|
    if segm.vocalic? && segm[:IPA][-1] == 'w' && %w{ɛ e i}.include?(segm[:IPA][-2])
        segm[:IPA][-2..-1] = case segm[:IPA][-2]
                             when 'ɛ' then 'œ'
                             when 'e' then 'ø'
                             when 'i' then 'y'
                             end
        segm[:long] = true
    end

    # if the diphthong ends with combining tilde
    if segm.vocalic? && segm[:IPA][-1] == "\u0303" && %w{ɛ e i}.include?(segm[:IPA][-3])
        segm[:IPA][-3..-1] = case segm[:IPA][-3]
                             when 'ɛ' then 'œ̃'
                             when 'e' then 'ø̃'
                             when 'i' then 'ỹ'
                             when 'j' then "ɥ̃"
                             end
        segm[:long] = true
    end

    # jw
    segm[:IPA][-2..-1] = "ɥ" if segm.vocalic? && segm[:IPA][-2..-1] == "jw"

    # jw̃
    segm[:IPA][-3..-1] = "ɥ̃" if segm.vocalic? && segm[:IPA][-3..-1] == "jw̃"

    # ɛ̯w
    segm[:IPA][-3..-1] = "œ̯" if segm.vocalic? && segm[:IPA][-3..-1] == "ɛ̯w"

    # ɛ̯w̃
    segm[:IPA][-4..-1] = "œ̯̃" if segm.vocalic? && segm[:IPA][-4..-1] == "ɛ̯w̃"
  end
end

# resolution of diphthongs in /O o u/
def step_oix7 ary
  @current = ary.each do |segm|
    if segm.vocalic? && segm[:IPA][-1] == 'w' && %w{ɔ o u w}.include?(segm[:IPA][-2])
        segm[:IPA][-2..-1] = case segm[:IPA][-2]
                             when 'ɔ' then 'o'
                             when 'o' then 'o'
                             when 'u' then 'u'
                             end
        segm[:long] = true
    end

    # if the diphthong ends with combining tilde
    if segm.vocalic? && segm[:IPA] && segm[:IPA][-1] == "\u0303" && %w{ɔ o u w}.include?(segm[:IPA][-3])
        segm[:IPA][-3..-1] = case segm[:IPA][-3]
                             when 'ɔ' then 'õ'
                             when 'o' then 'õ'
                             when 'u' then 'ũ'
                             end || segm[:IPA][-3..-1]
        segm[:long] = true
    end

    # ww
    if segm.vocalic? && segm[:IPA][-2..-1] == "ww"
      segm[:IPA][-2..-1] = "w"
      segm[:orthography][-2..-1] = "w"
    end

    # w̃w
    if segm.vocalic? && segm[:IPA][-3..-1] == "w̃w"
      segm[:IPA][-3..-1] = "w̃"
      segm[:orthography][-2..-1] = "w̃"
    end

    # Assign stress if there isn't any
    if segm.vocalic? && ary.count(&:stressed?) == 0
      segm[:stress] = true
    end
  end

  # Assign stress if there are multiple
  ary.select(&:stressed?)[0..-2].each{|segm| segm[:stress] = false}
  @current = ary
end

# now lose all those precious nasals
def step_CI1 ary
  @current = ary.each do |segm|
    if segm[:orthography].include?("ũ") || segm[:orthography].include?("w̃")
      segm[:IPA].gsub!(/w̃/, 'w')
      segm[:IPA].gsub!(/ũ/, 'u')
      segm[:IPA].gsub!(/õ/, 'o')
      segm[:IPA].gsub!(/œ̃/, 'œ')
      segm[:IPA].gsub!(/œ̯̃/, 'œ̯')
      segm[:IPA].gsub!(/ø̃/, 'ø')
      segm[:IPA].gsub!(/ỹ/, 'y')
      segm[:IPA].gsub!(/ɥ̃/, 'ɥ')
    end
  end
end

# New nasals from /n/ before consonants/finally
def step_CI2 ary
  @current.compact
  @current = ary.each_with_index do |segm, idx|
    if segm.vocalic? && !%w{j w ɥ œ̯}.include?(segm[:IPA][-1]) &&
        ary[idx+1] && %w{m n ŋ}.include?(segm.next.phon) &&
        (segm.after_next.phon && segm.after_next.starts_with.consonantal? || segm.next.final?)

      segm[:IPA] += "\u0303"
      segm[:orthography] += case #'n'#ary[idx+1][:orthography]
                            when segm.next.final? then segm.next.orth
                            when segm.after_next.labial? then 'm'
                            else 'n'
                            end
      segm.next[:IPA] = nil
      segm.next[:orthography] = nil
    end
  end

  @current.delete_if {|segment| segment[:IPA].nil? }
end

# Neutralization of voicing in fricatives
def step_CI3 ary
  @current = ary.reverse_each.with_index do |segm, idx|
    if segm.fricative?
      case
      when segm.next.voiceless? || segm.final?
        segm.devoice!
      when segm.next.voiced?
        segm.voice!

        segm[:orthography] = "d" if segm.orth == "th"
      end
    end
  end

  @current = ary
end

# short u(~) > y
def step_CI4 ary
  @current = ary.each do |segm|
    segm[:IPA].gsub!(/u/, 'y') unless segm[:long]
  end
end

# ʎ > j / iʎ -> i: finally or before consonants
def step_CI5 ary
  @current = ary.each_with_index do |segm, idx|
    if segm[:IPA] && segm[:IPA][-1] == 'i' && segm.next.phon == 'ʎ' &&
        (segm.after_next.starts_with.consonantal? || segm.next.final?)
      segm[:long] = true
      segm[:orthography] << "ll"
      segm.next[:IPA] = nil
      segm.next[:orthography] = nil
    end

    segm[:IPA].gsub!(/ʎ/, 'j') if segm[:IPA]
  end

  @current.compact
end

# gl > ll
def step_CI6 ary
  @current = ary.each_with_index do |segm, idx|
    if idx > 0 && segm[:IPA] == 'g' && segm.next.phon == 'l'
      segm[:IPA] = "l"
      segm[:palatalized] = false
    end
  end
end

# reduce affricates
def step_CI7 ary
  @current = ary.each do |segm|
    if segm.affricate?
      case segm[:IPA]
      when "tʃ"
        if segm.prev.phon == 't'
          segm[:IPA] = "tʃ"
          segm[:orthography] = "#{segm.prev.orth}#{segm[:orthography]}"
          segm.prev[:IPA] = nil
          segm.prev[:orthography] = nil
        else
          segm[:IPA] = "ç"
        end
      when "dʒ"
        if segm.prev.phon == 'd'
          segm[:IPA] = "dʒ"
          segm[:orthography] = "#{segm.prev.orth}#{segm[:orthography]}"
          segm.prev[:IPA] = nil
          segm.prev[:orthography] = nil
        else
          segm[:IPA] = "ʝ"
        end
      end
    end
  end

  @current.delete_if {|segment| segment[:IPA].nil? }
end

# i > ji after hiatus
def step_CI8 ary
  @current = ary.each do |segm|
    if segm.phon[0] == 'i' && segm.prev.ends_with.vowel?
      segm[:IPA][0] = "ji"
    end
  end

  # initial |i, u| or in a new syllable after a (non-diphthong) vowel become |y, w|
  @current = ary.each_with_index do |segm, idx|
    if segm[:orthography][0] == "i" &&
      ((idx == 0 && segm.diphthong?) || segm.prev.vowel?)
      segm[:orthography][0] = "y"
    end
  end

  @current = ary.each_with_index do |segm, idx|
    if segm[:orthography][0] == "u" && segm[:orthography][0..1] != "uo" && # don't do 'uo'/ů
      ((idx == 0 && segm.diphthong?) ||
      (idx > 0 && segm.prev.vowel?))
      segm[:orthography][0] = "w"
    end
  end

end

#############
# õ ã > u~ 6~
def step_ri1 ary
  @current = ary.each do |segm|
    segm[:IPA].gsub!(/o\u0303/, "u\u0303")
    segm[:IPA].gsub!(/a\u0303/, "ɐ\u0303")
  end
end

# syll-initial /j/
def step_ri2 ary
  @current = ary.each_with_index do |segm, idx|
    if %w{d t s}.include?(segm[:IPA]) && ary[idx+1] && ary[idx+1][:IPA][0] == "j"
      case segm[:IPA]
      when 'd'
        segm[:IPA] = 'ɟʝ'
        ary[idx+1][:IPA][0] = ''
      when 't'
        segm[:IPA] = 'cç'
        ary[idx+1][:IPA][0] = ''
      when 's'
        segm[:IPA] = 'ç'
        ary[idx+1][:IPA][0] = ''
      end
    end

    if segm[:IPA][0] == "j" &&
      (Segment[IPA: segm[:IPA][1]].vowel? ||   # front of diphthong
      (!segm[:IPA][1] && segm.next.starts_with.vowel?)) && # isolated segment
      !(idx > 0 && !(segm.prev.dental? || (segm.prev.phon == 'r' && segm.before_prev.vocalic?) || segm.prev.vocalic?)) &&
      !(idx > 0 && segm.prev.phon == 'l') &&
      !(idx > 0 && ary[0...idx].all?(&:consonantal?))
      # segm[:IPA][0] = 'ʝ'

      if segm[:IPA][1] # part of a diphthong
        ary.insert(idx, Segment[IPA: 'ʝ', orthography: '' ])
        segm[:IPA][0] = ''
      else # by itself
        segm[:IPA] = 'ʝ'
      end
    end

    if segm[:IPA][-1] == "j" &&
      segm[:IPA][-2] && segm.ends_with.vowel? &&   # end of diphthong
      segm.next.starts_with.vowel?
      # segm[:IPA][0] = 'ʝ'
      ary.insert(idx+1, Segment[IPA: 'ʝ', orthography: ''])
      segm[:IPA][-1] = ''
    end
  end

  @current = ary.delete_if {|segment| segment[:IPA] == '' }
end

# assimilation of /s/
def step_ri3 ary
  @current = ary.each_with_index do |segm, idx|
    if segm[:IPA] == 's' && !segm[:long] && idx > 0 && segm.prev.vocalic?
      case
      when segm.final?
        segm[:IPA] = 'ʰ'
      when segm.next.consonantal?
        segm[:IPA] = segm.next.phon[0]
      end
    end

    if idx == 0 && segm[:IPA] == 's' && segm.next.consonantal?
      segm[:IPA] = 'ʰ'
    end
  end
end

# je wo wø > ji u y in closed syllables
def step_ri4 ary
  @current = ary.each_with_index do |segm, idx|
    if %w{je wo wø}.include?(segm[:IPA]) && segm.next.consonantal? &&
        (segm.next.final? || (ary[idx+2] && segm.next.consonantal?))
      case segm[:IPA]
      when "je"
        segm[:IPA] = 'ji'
      when "wo"
        segm[:IPA] = 'u'
      when "wø"
        segm[:IPA] = 'y'
      end
    end
  end
end

# w > 0 before round vowels
def step_ri5 ary
  @current = ary.each do |segm|
    if segm[:IPA] == "w" && segm.next.starts_with.round?
      segm.next[:orthography] = segm[:orthography] << segm.next.orth

      segm[:IPA] = nil
      segm[:orthography] = nil
    elsif segm[:IPA][-1] == 'w' && segm.next.starts_with.round?
      segm[:IPA][-1] = ''
    elsif segm[:IPA][0] == 'w' && segm[:IPA][1] && segm[:IPA][1].round?
      segm[:IPA][0] = ''
    end
  end
  @current.compact
end

# k_j g_j > tS dZ
def step_ri6 ary
  @current = ary.each_with_index do |segm, idx|
    if ary[idx+1] && ary[idx+1][:palatalized]
      segm[:IPA] = 't' if segm[:IPA] == 'k' && segm.next.phon == 'k'
      segm[:IPA] = 'd' if segm[:IPA] == 'g' && segm.next.phon == 'g'
    end

    if segm[:palatalized]
      case segm[:IPA]
      when 'k'
        segm[:IPA] = 'tʃ'
        segm[:palatalized] = false
      when 'g'
        segm[:IPA] = 'dʒ'
        segm[:palatalized] = false
      end
    end
  end
end

# k g > k_j g_j
def step_ri7 ary
  @current = ary.each do |segm|
    if !segm[:back]
      case segm[:IPA]
      when 'k'
        segm[:palatalized] = true
      when 'g'
        segm[:palatalized] = true
      end
    end
  end
end

# k- g- > k g
def step_ri8 ary
  @current = ary.each do |segm|
    if segm[:back]
      case segm[:IPA]
      when 'k'
        segm[:back] = false
      when 'g'
        segm[:back] = false
      end
    end
  end
end

# Devoice final stops
def step_ri9 ary
  ary.last.devoice! if ary.last.stop?

  @current = ary
end

# lose final schwa
def step_ri10 ary
  # We can have words of one character like ч.
  # But don't lose our only segment.
  if (ary.size > 1 && %W{ə ə\u0303}.include?(ary.last[:IPA])) || (ary[-2] && !ary[-2].stressed? && ary.last[:IPA] == "ʰ" && ary[-2][:IPA] == "ə")
    case ary.last[:IPA]
    when "ə", "ə\u0303"
      ary[-2][:final_n] = true if ary[-2][:IPA] == "n" #to distinguish from final nasal later
      ary[-2][:orthography] = ary[-2][:orthography] << ary[-1][:orthography]

      ary[-1][:IPA] = nil
      ary[-1][:orthography] = nil
    when "ʰ"
      ary[-3][:final_n] = true if ary[-3][:IPA] == "n" #to distinguish from final nasal later
      ary[-3][:orthography] = ary[-3][:orthography] << ary[-2][:orthography] << ary[-1][:orthography]

      ary[-2][:IPA] = nil
      ary[-2][:orthography] = nil
      ary[-1][:IPA] = nil
      ary[-1][:orthography] = nil
    end
  end

  @current = ary.compact
end

# lose /h/
def step_ri11 ary
  @current = ary.each_with_index do |segm, idx|
    if segm[:IPA] == 'h'
      if ary[idx+1]
        segm.next[:orthography] = segm[:orthography] << segm.next.orth
      end

      if idx > 0 && segm.prev.phon[-1] == "\u0303"
        segm[:IPA] = 'n'
        segm.prev.phon[-1] = ''
        segm[:orthography] = 'n'
        segm.prev.orth[-1] = ''
      else
        segm[:IPA] = nil
        segm[:orthography] = nil
      end
    end
  end

  @current = ary.delete_if {|segment| segment[:IPA].nil? }
end

# OE AE > O: a:
def step_ri12 ary
  @current = ary.each do |segm|
    if segm[:IPA].include?('ɑɛ̯') || segm[:IPA].include?('ɔɛ̯') || segm[:IPA].include?('œ̯')
      segm[:IPA].gsub!(/ɑɛ̯/, 'a')
      segm[:IPA].gsub!(/ɔɛ̯/, 'ɔ')
      segm[:IPA].gsub!(/(.*)œ̯/, '\1')

      segm[:long] = true
    end
  end
end

# ej > Ej
def step_ri13 ary
  @current = ary.each do |segm, idx|
    if segm[:IPA].include?('ej')
      segm[:IPA].gsub!(/ej/, 'ɛj')
    end
  end
end

# oj Oj OH EH > œj
def step_ri14 ary
  @current = ary.each do |segm|
    if segm[:IPA].include?('ɔj') || segm[:IPA].include?('oj')
      segm[:IPA].gsub!(/[oɔ]j/, 'œj')
    end

    segm[:IPA].gsub!(/[oɔɛe]ɥ/, 'œj')
  end
end

# rough, cleanup
def cyrillize ary
  cyrl = ary.to_ipa.tr("ɑbvgdɛfʒzeijklmn\u0303ɲɔœøprstθuwɥyoʃəɐaʰː", "абвгдевжзиіјклмннњоөөпрсттууүүѡшъъя’\u0304")
  cyrl.gsub!(/н\u0304/, "\u0304н")  # ũː > ун̄ > ӯн
  cyrl.gsub!(/н’/, "’н")            # w̃ʰ > н’ > ’н
  cyrl.sub!(/н$/, 'н’') if ary[-1][:final_n] && cyrl != "н" && %W{а е и і ј о ө у ү ѡ ъ я \u0304}.include?(cyrl[-2]) # && !(cyrl[-2] == "н") # no need for нн' or н' solo
  cyrl.gsub!(/тш/, 'ч')
  cyrl.gsub!(/дж/, 'џ')
  cyrl.gsub!(/[ˈʲ]/, '')
  cyrl.gsub!(/ccç/, 'ттј')
  cyrl.gsub!(/cç/, 'тј')
  cyrl.gsub!(/ɟɟʝ/, 'ддј')
  cyrl.gsub!(/ɟʝ/, 'дј')
  cyrl.gsub!(/ʝ/, 'ж')
  cyrl.gsub!(/ŋ/, 'нг')
  cyrl.gsub(/ç/, 'ш')
end

def neocyrillize ary
  cyrl = ary.to_ipa.tr("ɑbvdʒzelmn\u0303ɲɔœprsʰtuyfoʃəøaɐcɟ", "абвджзилмннњоөпрсстуүфѡшыюяятд")
  cyrl.gsub!(/\u0304/, '')
  cyrl.gsub!(/тш/, "ч")
  cyrl.gsub!(/дж/, "џ")
  cyrl.gsub!(/θ/, "ћ")
  cyrl.gsub!(/gʲ/, "г")
  cyrl.gsub!(/kʲ/, "к")
  cyrl.gsub!(/g/, "гъ")
  cyrl.gsub!(/k/, "къ")
  cyrl.gsub!(/ç/, 'с́')
  cyrl.gsub!(/ŋ/, 'нг')
  cyrl.gsub!(/үː/, 'ӱ')
  cyrl.gsub!(/уː/, 'у́')
  cyrl.gsub!(/ү/, 'у')
  cyrl.gsub!(/[jʝ]ɛ/, 'є')
  cyrl.gsub!(/[jʝ][ei]/, 'ї')
  cyrl.gsub!(/ʝ$/, "јъ")
  cyrl = cyrl.tr("ʝɛi", "јеі")
  cyrl.gsub!(/([аиоөуүѡыюєяїеі])j([^аиоөуүѡыюєяїеі])/, '\1й\2')
  cyrl.gsub!(/([аиоөуүѡыюєяїеі])w([^аиоөуүѡыюєяїеі])/, '\1ў\2')
  cyrl = cyrl.tr("jw", "јв")
  cyrl.gsub(/[ˈː]/, '')
end

# This doesn't really introduce any good changes other than ă$ > e
def neolatinize(ary)
  neo = deep_dup ary
  neo.change('ɑ', orthography: 'a') { |segm| !segm[:long] }
  neo.change('ɑj', orthography: 'ae')
  neo.change('b', orthography: 'b')
  neo.change('v', orthography: 'f') { |segm| segm.final? }
  neo.change('d', orthography: 'd')
  neo.change('ʒ', orthography: 'sç')
  neo.change('ʒ', orthography: 'sc') { |segm| segm.next.starts_with.orth.front_vowel? }
  neo.change('z', orthography: 's')
  neo.change('e', orthography: 'é') { |segm| !segm[:long] }
  neo.change('l', orthography: 'l')
  neo.change('m', orthography: 'm')
  neo.change('n', orthography: 'n')
  neo.change('ɲ', orthography: 'nh')
  neo.change('ɔ', orthography: 'o') { |segm| !segm[:long] }
  neo.change('ɔj', orthography: 'oe')
  neo.change('œ', orthography: 'eu') { |segm| !segm[:long] }
  neo.change('œ̃', orthography: 'un') { |segm| !segm[:long] }
  neo.change('p', orthography: 'p')
  neo.change('r', orthography: 'r')
  neo.change('s', orthography: 's')
  neo.change('t', orthography: 't')
  neo.change('u', orthography: 'uo') { |segm| segm[:long] }
  neo.change('y', orthography: 'u') { |segm| !segm[:long] }
  neo.change('y', orthography: 'iu') { |segm| segm[:long] }
  neo.change('f', orthography: 'f')
  neo.change('o', orthography: 'ó') { |segm| !segm[:long] }
  neo.change('ʃ', orthography: 'z')
  neo.change('ʃ', orthography: 'ç') { |segm| segm.final? }
  neo.change('ə', orthography: 'e') { |segm| segm.final? || (@plural && segm.next.final?) }
  neo.change('ə', orthography: 'ë') { |segm| segm.prev.vocalic? && (segm.final? || (@plural && segm.next.final?))}
  neo.change('ø', orthography: 'éu') { |segm| !segm[:long] }
  neo.change('a', orthography: 'à') { |segm| !segm[:long] }
  neo.change('ɐ', orthography: 'ă') { |segm| !segm[:long] }
  neo.change('tʃ', orthography: 'ch')
  neo.change('dʒ', orthography: 'dj')
  neo.change('x', orthography: 'g')
  neo.change('x', orthography: 'gu') { |segm| segm.next.starts_with.orth.front_vowel? }
  neo.change('k', orthography: 'c')
  neo.change('k', orthography: 'qu') { |segm| segm.next.starts_with.orth.front_vowel? }
  neo.change('ç', orthography: 'ç')
  neo.change('ç', orthography: 'z') { |segm| segm.final? }
  neo.change('ç', orthography: 'c') { |segm| segm.next.starts_with.orth.front_vowel? }
  neo.change('ŋ', orthography: 'ng')
  neo.change('jɛ', orthography: 'ye')
  neo.change('jɛ', orthography: 'ie') { |segm| segm.prev.consonantal? }
  neo.change('ʝɛ', orthography: 'ge')
  neo.change(['je', 'ji', 'ʝe', 'ʝi'], orthography: 'y')
  neo.change('ʝ', orthography: 'j')
  neo.change('ʝ', orthography: 'g') { |segm| segm.next.starts_with.orth.front_vowel? }
  neo.change('ɛ', orthography: 'e') { |segm| !segm[:long] }
  neo.change('i', orthography: 'i') { |segm| !segm[:long] }
  neo.change(:diphthong, {}, ->(segm) { segm[:orthography] = segm.orth[0..-2] << 'i' }) { |segm| segm.ends_with == 'j' }
  neo.change(:diphthong, {}, ->(segm) { segm[:orthography] = segm.orth[0..-2] << 'w' }) { |segm| segm.ends_with == 'w' }
  neo.change(:diphthong, {}, ->(segm) { segm[:orthography] = 'y' << segm.orth[1..-1] }) { |segm| segm.starts_with == 'j' }
  neo.change(:diphthong, {}, ->(segm) { segm[:orthography] = 'w' << segm.orth[1..-1] }) { |segm| segm.starts_with == 'w' }
  neo.change(:diphthong, {}, ->(segm) { segm[:orthography] = 'i' << segm.orth[1..-1] }) do |segm| 
    segm.starts_with == 'j' && segm.prev.consonantal? 
  end
  neo.change(:diphthong, {}, ->(segm) { segm[:orthography] = 'u' << segm.orth[1..-1] }) do |segm| 
    segm.starts_with == 'w' && segm.prev.consonantal? 
  end
  
  neo.join
#  ~ 
#  n 
end

#############
# i~ o~ y~ > E~ O~ œ~
def step_pi1 ary
  @current = ary.each do |segm|
    segm[:IPA].gsub!(/i\u0303/, "ɛ\u0303")
    segm[:IPA].gsub!(/o\u0303/, "ɔ\u0303")
    segm[:IPA].gsub!(/y\u0303/, "œ\u0303")
  end
end

# a a~ > æ æ~
def step_pi2 ary
  @current = ary.each do |segm|
    segm[:IPA].gsub!(/a/, "æ")
  end
end

# assimilation of /s/
def step_pi3 ary
  @current = ary.each_with_index do |segm, idx|
    if segm[:IPA] == 's' && !segm[:long] && idx > 0 && !segm.final? && segm.prev.vocalic? && segm.next.consonantal?
        segm[:IPA] = nil
        segm[:orthography] = nil

        case segm.prev.phon[-1]
        when 'e'
          segm.prev.phon[-1] = "ɛ"
          segm.prev[:long] ? segm.prev.orth[-([2, segm.prev.orth.length].min)..-1] = "eî" : segm.prev.orth[-1] = "ê"
        when 'o'
          segm.prev.phon[-1] = "ɔ"
          segm.prev[:long] ? segm.prev.orth[-([2, segm.prev.orth.length].min)..-1] = "oû" : segm.prev.orth[-1] = "ô"
        when 'æ' # avoid à̂
          segm.prev[:long] ? segm.prev.orth[-([2, segm.prev.orth.length].min)..-1] = "àî" : segm.prev.orth[-1] = "àî"
        else
          segm.prev[:orthography] << "\u0302"
        end
    end
  end

  @current = ary.compact
end

# je wo wø > i u y in closed syllables
def step_pi4 ary
  @current = ary.each_with_index do |segm, idx|
    if (%w{je jẽ wo wõ wø wø̃}.include?(segm[:IPA]) || ((segm.prev.phon == 'w' && (%w{o ø õ ø̃}.include?(segm[:IPA])) || (segm.prev.phon == 'j' && %w{e ẽ}.include?(segm[:IPA]))))) && ary[idx+1] && segm.next.consonantal? &&
        (segm.next.final? || segm.after_next.consonantal?)
      case segm[:IPA]
      when "je"
        segm[:IPA] = 'i'
        segm[:orthography] = segm.prev.vocalic? ? 'y' : 'i'
      when "jẽ"
        segm[:IPA] = 'ĩ'
        segm[:orthography] = segm.prev.vocalic? ? 'yn' : 'in'
      when "e"
        segm[:IPA] = 'i'
        segm[:orthography] = segm.before_prev.vocalic? ? 'y' : 'i'

        segm.prev[:IPA] = nil
        segm.prev[:orthography] = nil
      when "ẽ"
        segm[:IPA] = 'ĩ'
        segm[:orthography] = segm.before_prev.vocalic? ? 'yn' : 'in'

        segm.prev[:IPA] = nil
        segm.prev[:orthography] = nil
      when "wo"
        segm[:IPA] = 'u'
        segm[:orthography] = 'uo'
      when "wõ"
        segm[:IPA] = 'ũ'
        segm[:orthography] = 'uon'
      when "o"
        segm[:IPA] = 'u'
        segm[:orthography] = 'uo'

        segm.prev[:IPA] = nil
        segm.prev[:orthography] = nil
      when "õ"
        segm[:IPA] = 'ũ'
        segm[:orthography] = 'uon'

        segm.prev[:IPA] = nil
        segm.prev[:orthography] = nil
      when "wø"
        segm[:IPA] = 'y'
        segm[:orthography] = 'u'
      when "wø̃"
        segm[:IPA] = 'ỹ'
        segm[:orthography] = 'un'
      when "ø"
        segm[:IPA] = 'y'
        segm[:orthography] = 'u'

        segm.prev[:IPA] = nil
        segm.prev[:orthography] = nil
      when "ø̃"
        segm[:IPA] = 'ỹ'
        segm[:orthography] = 'un'

        segm.prev[:IPA] = nil
        segm.prev[:orthography] = nil
      end
    end
  end

  @current.delete_if {|segment| segment[:IPA].nil? }
end

# reduce unstressed vowels
def step_pi5 ary
  posttonic = ary.count(&:stressed?) == 0
  any_breve = false

  @current = ary.each_with_index do |segm, idx|
    if segm.vocalic?
      case segm.stressed?
      when true
        posttonic = true

        if segm[:IPA][-1] == "ɥ" || segm[:IPA][-2..-1] == "œ̯"
          ary.insert(idx+1, Segment[IPA: 'ə', orthography: 'ă'])
          any_breve = true
          case
          when segm[:IPA][-1] == "ɥ"
            segm[:IPA][-1] = ''
            segm[:orthography][-2..-1] = ''
          else
            segm[:IPA][-2..-1] = ''
            segm[:orthography][-2..-1] = ''
          end
        end
      else
        segm[:long] = true if segm[:IPA][-1] == "ɥ" || segm[:IPA][-2..-1] == "œ̯" || (segm.next.vowel? && !segm.next.stressed?)

        if segm[:IPA][-1] == "ɥ" || segm[:IPA][-2..-1] == "œ̯"
          ary.insert(idx+1, Segment[IPA: 'ə', orthography: 'a'])
          case
          when segm[:IPA][-1] == "ɥ"
            segm[:IPA][-1] = ''
            #segm[:orthography][-2..-1] = ''
            segm[:orthography][-1] = ''
          else
            segm[:IPA][-2..-1] = ''
            segm[:orthography][-2..-1] = ''
          end
        end

        if !segm[:long]  # I don't think this will catch /jV/ /wV/ diphthongs
          #segm[:IPA].include?("\u0303") ? segm[:IPA][0] = 'ə̃' :
          vowel_pos = segm.starts_with.vowel? ? 0 : 1
          segm[:IPA][vowel_pos] = 'ə'
          if posttonic && segm[:orthography] != 'ă'
            segm[:orthography][vowel_pos] = (any_breve ? 'a' : 'ă')
            segm[:orthography].gsub!(/ă\u0302/, "ă")  # no ă̂
            any_breve = true
          end

          if %w{ʃ ʒ ç ʝ k g}.include?(segm.prev.phon[-1]) &&
              %w{a à o ó u ă}.include?(segm[:orthography][0]) &&
              !%w{i j}.include?(segm.prev.orth[-1]) # LL |tiV|; pluvia > plusja
            case segm.prev.phon[-1]
            when 'ʃ', 'ç'
              segm.prev.orth[-1] = 'ç'
            when 'ʒ', 'ʝ'
              segm.prev.orth[-1] = 'ç'
            when 'g' # gu
              segm.prev[:orthography] = 'g'
            when 'k' # qu
              segm.prev[:orthography] = 'c'
            end
          end
        end
      end
    end
  end
end

# k_j g_j > tS dZ
def step_pi6 ary
  @current = ary.each do |segm|
    if segm[:palatalized]
      case segm[:IPA]
      when 'k'
        segm[:IPA] = 'tʃ'
        segm[:palatalized] = false
        segm[:orthography] = 'ch'
      when 'g'
        segm[:IPA] = 'dʒ'
        segm[:palatalized] = false
        segm[:orthography] = 'dj'
      end
    end
  end
end

# k- g- > k g
def step_pi7 ary
  @current = ary.each do |segm|
    if segm[:back]
      case segm[:IPA]
      when 'k'
        segm[:back] = false
      when 'g'
        segm[:back] = false
      end
    end
  end
end

# OE~ AE~ > O:~ a:~
def step_pi8 ary
  @current = ary.each do |segm|
    if segm[:IPA].include?("ɑɛ̯\u0303") || segm[:IPA].include?("ɔɛ̯\u0303")
      segm[:IPA].gsub!(/ɑɛ̯\u0303/, 'æ')
      segm[:IPA].gsub!(/ɔɛ̯\u0303/, 'ɔ')

      segm[:long] = true
    end
  end
end

# OE oj AE > Oj Oj Aj
def step_pi9 ary
  @current = ary.each do |segm|
    if segm[:IPA].include?('ɑɛ̯') || segm[:IPA].include?('ɔɛ̯') || segm[:IPA].include?('oj')
      segm[:IPA].gsub!(/ɑɛ̯/, 'ɑj')
      segm[:IPA].gsub!(/ɔɛ̯/, 'ɔj')
      segm[:IPA].gsub!(/oj/, 'ɔj')
      segm[:orthography].gsub!(/ói/, 'oi')
    end
  end
end

# g > x
def step_pi10 ary
  @current = ary.each do |segm|
    segm[:IPA].gsub!(/g/, 'x')
  end

  # Orthography changes
  @current = ary.each do |segm|
    segm[:orthography].gsub!(/i/, 'y') if segm.prev.phon == 'j'
    segm[:orthography].gsub!(/ll/, 'y')
    segm[:orthography].gsub!(/iy/, 'y')
    segm[:orthography].gsub!(/ũ/, 'u')
    segm[:orthography].gsub!(/w̃/, 'w')
    segm[:orthography].gsub!(/uou/, 'uo')
    segm[:orthography] = "l" if segm[:IPA] == "l" # |gl| /ll/
    segm[:orthography].gsub!(/ă/, 'a') if segm.prev.orth && %w{é ó}.include?(segm.prev.orth[-1])
    segm[:orthography].gsub!(/àu/, 'au')
    segm[:orthography] = "y" if segm[:IPA] == "ji"
    segm[:orthography] = "cu" if segm[:orthography] == "qu" && segm =~ "kw"    
    segm[:orthography] = "c" if segm[:orthography] == "qu" && %w{a à o ó u}.include?(segm.next.orth[0])
  end
end

# INCOMPLETE
def convert_OLF str
  @current = str.scan(/[ct]h|qu|kw|ei|eu|uo|[iī]w|ou|ng|i[ée]|aũ|au|nj|./i).inject(Dictum.new) do |memo, obj|
    supra = {}
    supra.merge!({ long: true }) if obj.match(/[āēīōūȳ]|uo|aũ|au|eu/i)

    phon = case obj
           when /qu/i then "kw"
           when /ch/i then "k"
           when /th/i then "θ"
           when /aũ|au/i then "o"
           when /eu/i   then "œ"
           when /ā|a/i  then "ɑ"
           when /ié/i   then "je"
           when /ie/i   then "jɛ"
           when /ei/    then "ɛj"
           when /ē/i    then "e"
           when /e/i    then "ɛ"
           when /[iī]w/i then "iw"
           when /ī/i    then "i"
           when /uo/i   then "u"
           when /ou/i   then "ɔw"
           when /o/i    then "ɔ"
           when /ō/i    then "o"
           when /ū/i    then "u"
           when /c/i    then "k"
           when /ng/i   then 'ŋ'
           when /ph/i   then 'f'
           when /nj/i   then 'ɲ'
           else obj.dup.downcase
           end

    orth = case obj
           when /k/i  then "c"
           when /y/i  then "i"
           when /ā/i  then "a"
           when /ē/i  then "éi"
           when /[īi]w/i  then "iu"
           when /ī/i  then "i"
           when /ō/i  then "ó"
           when /ū/i  then "u"
           when /nj/i then "nh"
           when /j/i  then "y" # revisit this as needed
           else obj.dup
           end

    memo << Segment[IPA: phon, orthography: orth].merge(supra)
  end

  # velar before front vowels
  @current = @current.each do |segm|
    if segm.next.starts_with.front_vowel? || segm.next.starts_with =~ 'j'
      case segm[:IPA]
      when "k"
        segm[:orthography] = "qu"
        segm[:palatalized] = true
      when "g"
        segm[:orthography] = "gu"
        segm[:palatalized] = true
      end
    end
  end

  # post-vocalic H
  @current = @current.each_with_index do |segm, idx|
    if ((segm.prev.vocalic? &&
        segm.next.consonantal?) || segm.final?) &&
        segm[:IPA] == 'h'
      segm[:orthography] = "gh"  # How's this?
      segm[:IPA] = segm.next.voiced? ? 'g' : 'k'
    end
  end

  # Endings
  case @current.join
  when /are$/
    @current.pop(3)
    @current << Segment[IPA: "ɑ", orthography: "a", long: false, stress: true] << Segment[IPA: "r", orthography: "r", long: false]
  when /ariu(m|s)$/ #ariam, arium
    @current.pop(5)
    @current << Segment[IPA: "a", orthography: "ài", long: true, stress: true] << Segment[IPA: "r", orthography: "r", long: false]
  end


  # assign stress
  # This is not even close to universally true but will work for our initial case
  vowels = @current.find_all{|segment| segment.vocalic?}
  if @current[-1][:orthography] == "!" # Manual override for final stress
    vowels[-1][:stress] = true
    @current[-1][:IPA] = nil
    @current[-1][:orthography] = nil
  elsif @current[-1][:orthography] == ">" # Move stress one syllable towards the end
    @current[-1][:IPA] = nil
    @current[-1][:orthography] = nil
    vowels[1][:stress] = true unless @current.count(&:stressed?) > 0 || vowels.length < 2  # Don't assign new stress if ending has.
  else
    vowels[0][:stress] = true unless @current.count(&:stressed?) > 0  # Don't assign new stress if ending has.
  end

  postinitial = false

  @current = @current.each_with_index do |segm, idx|
    # unstressed schwas - non-initial
    if segm.vocalic? && !segm.stressed? && postinitial
      if !segm[:long] && !segm.diphthong? && segm[:IPA] != 'ə'
        segm[:IPA] = 'ə'
        segm[:orthography] = 'e'

        # metathesis of @C > C@
        if segm.prev.intervocalic? && segm.next.final? && @current[idx+1] && segm.next.consonantal?
          segm.prev[:orthography] = case segm.prev.orth
                                    when "qu" then "c"
                                    when "gu" then "g"
                                    else segm.prev.orth
                                    end

          @current[idx], @current[idx+1] = @current[idx+1], @current[idx]
        end

        if segm.prev && %w{e i é}.include?(segm[:orthography])
          case segm.prev.phon
          when "k"
            segm.prev[:orthography] = "qu"
          when "g"
            segm.prev[:orthography] = "gu"
          end
        end
      end
    end

    postinitial = true if segm.vocalic?
  end

  @current.delete_if {|segment| segment[:IPA].nil? }
end

# INCOMPLETE
def convert_LL str
  ary = str.scan(/[aeé]u|i?.ũ|iéu?|[aoi]e|[ey][ij]|qu|[ckprtg]h|ss|[ln]j|./i).inject(Dictum.new) do |memo, obj|
    supra = {}
    supra.merge!({ long: true }) if obj.match(/aũ|éũ|eũ|éu|eu|iũ/i)
    supra.merge!({ was_k: true }) if obj.match(/k|ch/)
    #supra.merge!({ originally_long: true }) if obj.match(/[āēīōūȳ]/i)

    phon = case obj
           when /qu/i     then "kw"
           when /x/i      then "ks"
           when /ss/i     then "s"
           when /aũ|au/i  then "o"
           when /iéũ|iéũ|iéu/i  then "jø"
           when /ié/i     then "je"
           when /ie/i     then "jɛ"
           when /éũ|éu/i    then "ø"
           when /eũ|eu/i    then "œ"
           when /iũ|iu/i    then "y"
           when /ae/i       then "ɑɛ̯"
           when /ā|ă|a/i  then "ɑ"
           when /ē|ĕ|e/i  then "ɛ"
           when /ī|ĭ|ȳ|y̆|y/i  then "i"
           when /ō|ŏ|o/i  then "ɔ"
           when /ū|ŭ/i    then "u"
           when /c/i      then "k"
           when /z/i      then "ʃ"
           when /ph/i     then 'f'
           when /rh/i     then 'r'
           when /th/      then 'θ'
           when /lj/      then 'ʎ'
           when /nj/      then 'ɲ'
          #when /ng/i     then 'ng'
           when /j/       then 'ʝ'
           else obj.dup.downcase
           end

    orth = case obj
           #when /k/i  then "c"
           when /ī/i  then "i"
           when /y/i  then "i"
           when /lj/i then 'll'
           when /nj/i then 'nh'
           when /ph/i then 'f'
           else obj.dup
           end

    memo << Segment[IPA: phon, orthography: orth].merge(supra)
  end

  # /gw/
  ary.change('g', { IPA: 'gw', orthography: 'gu' }, lambda do |segm|
    segm.next.delete
  end) { |iff| iff.between?('n', 'u') && iff.after_next.vowel? } 

  ary.change(%w[t s ks], { IPA: 'ʃʃ' }, lambda do |segm|
    segm[:orthography] << 'i'
    segm.next.delete
  end) { |iff| iff.before?('i') && iff.after_next.vowel? }

  # assign stress to each word
  ary.change(:final, {}, lambda do |mark|
    initial = ary[0...mark.pos].reverse_each.find {|s| s =~ :initial }
    word = ary[initial.pos..mark.pos]
    vowels = word.find_all { |segm| segm.vocalic? }
    
    if mark =~ '!'
      vowels[-1][:stress] = true
      mark.delete
    elsif mark =~ '>'
      mark[:IPA] = '' # '>' is read as consonantal

      case vowels.length
      when 0
        # no stress
      when 1
        vowels[-1][:stress] = true
      else
        (vowels[-1][:long] || ultima_cluster?(word)) ? vowels[-1][:stress] = true : vowels[-2][:stress] = true
      end
      mark.delete
    else
      case vowels.length
      when 0, 1
        # no stress
      when 2
        vowels[-2][:stress] = true
      else
        (vowels[-2][:long] || penult_cluster?(word)) ? vowels[-2][:stress] = true : vowels[-3][:stress] = true
      end
    end
    
    if vowels[-2] && vowels[-2].stressed? && %w{ɛ ɔ}.include?(vowels[-2][:IPA])
      case vowels[-2][:IPA]
      when 'ɛ'
        vowels[-2][:IPA] = 'e'
        vowels[-2][:orthography] = 'é'
      when 'ɔ'
        vowels[-2][:IPA] = 'o'
        vowels[-2][:orthography] = 'ó'
      end
    end
  end)

  ary.change(:final, {}, lambda do |segm|
    initial = ary[0...segm.pos].reverse_each.find {|s| s =~ :initial }
    word = ary[initial.pos..segm.pos]

    # TODO: correctly get this working for multiple words
    # TODO: get 'pop' working
    case word.join
    when /alis|alem$/
      segm.before_prev.prev.update(IPA: "o", orthography: "au", stress: true, long: true)
      segm.dictum[-3].delete # l
      segm.dictum.renumber   # argh
      segm.dictum[-2].delete # i/e
      segm.dictum.renumber   # argh
      segm.delete            # s/m
    when /āre$/
      segm.before_prev.update(orthography: 'a', stress: true)
      segm.delete # e
    when /ariu(m|s)$/ #ariam, arium
      segm.before_prev.before_prev.update(IPA: "a", orthography: "ài", long: true, stress: true)
      segm.dictum[-3].delete # i
      segm.dictum.renumber   # argh
      segm.dictum[-2].delete # u
      segm.dictum.renumber   # argh
      segm.delete            # m/s
    when /as$/
      segm.prev.replace!(%w[ə e]) # a
    when /atio$/
      segm.prev.replace!(%w[ʒʒ sç])
      segm.update(IPA: 'ũ', orthography: 'uon', long: true, stress: true)
    when /ator$/
      segm.before_prev.prev.replace!(%w[ə e])
      segm.before_prev.replace!('l')
      segm.prev.update(IPA: 'u', orthography: 'uo', long: true, stress: true)
    when /atorium$/
      segm.dictum[-7].replace!(%w[ə e])
      segm.dictum[-6].replace!('l')
      segm.dictum[-5].update(IPA: 'œ', orthography: 'eu', long: true, stress: true)
      segm.dictum[-3].delete # i
      segm.dictum.renumber   # argh
      segm.dictum[-2].delete # u
      segm.dictum.renumber   # argh
      segm.delete            # m
    when /illum$/
      segm.dictum[-5].update(IPA: "i", orthography: "ill", stress: true, long: true)
      segm.dictum[-4].delete # l
      segm.dictum.renumber   # argh
      segm.dictum[-3].delete # l
      segm.dictum.renumber   # argh
      segm.dictum[-2].delete # u
      segm.dictum.renumber   # argh
      segm.delete            # m
    when /illa$/
      segm.dictum[-3].replace!(%w[j ll])
      segm.dictum[-2].delete
      segm.replace!(%w[ə e])
    when /a$/
      segm.replace!(%w[ə e])
      respell_velars(word)
    when /ēre$/
      segm.before_prev.update(IPA: 'je', orthography: 'ié', stress: true)
      segm.delete
    when /(énsem|énsis)$/
      segm.dictum[-4].delete # n
      segm.dictum[-2].delete # e/i
      segm.dictum.renumber   # argh
      segm.delete            # m/s
    when /(sin|sis)$/
      segm.prev.delete
      segm.dictum.renumber
      segm.delete
    when /(t|s)ionem$/
      segm.before_prev.before_prev.replace!(%w[ʒʒ sç])
      segm.before_prev.prev.update(IPA: 'ũ', orthography: 'uon', long: true, stress: true)
      segm.dictum[-3].delete # n
      segm.dictum.renumber   # argh
      segm.dictum[-2].delete # e
      segm.dictum.renumber   # argh
      segm.delete            # m
    when /(e|u)m$/ # not us
      segm.delete # m
      step_oi26(ary)
    end
  end)

  @current = ary
  # duplicate stresses after endings
  @current.select(&:stressed?)[0..-2].each{|s| s[:stress] = false} if @current.count(&:stressed?) > 1

  @current = step_CI2(@current)
  @current = step_CI3(@current)
  @current = step_CI4(@current)
  @current = step_CI5(@current)
  @current = step_CI8(@current)

  posttonic = false

  @current = @current.each_with_index do |segm, idx|
    case segm[:IPA]
    when "k"
      if @current[idx+1] && (segm.next.starts_with.front_vowel? || segm.next.starts_with =~ 'j' ) && segm.next[:orthography] != "u" # /y/ is a front vowel
        if segm[:orthography] == "ch"
          segm[:orthography] = "qu"
          segm[:palatalized] = true
        elsif !segm[:was_k]
          segm[:IPA] = "ç"
          respell_velars(@current)
        end
      end
    when "g"
      if segm.next.starts_with.front_vowel? && segm.next[:orthography] != "u"
        if segm[:orthography] == "gh"
          segm[:orthography] = "gu"
          segm[:palatalized] = true
        else
          segm[:IPA] = "ʝ"
          respell_velars(@current)
        end
      end
    when "œ"
      segm[:IPA] = 'o' if !segm.stressed?
    end

    segm[:orthography].gsub!(/ch/, "c")

    if segm.vocalic? && posttonic
      case segm[:orthography]
      when 'e'
        segm[:IPA] = 'ə'
     # when 'en'
    #    segm[:IPA] = 'ə̃'
      end
    end

    posttonic = true if segm.stressed?
  end

  @current.compact
end

# Ugh
def deep_dup ary
  Marshal.load(Marshal.dump(ary))
end

def transform(str, since = "L", plural = false)
  @steps = []
  @current = []
  @roesan_steps = []
  @paysan_steps = []
  @plural = plural

  if since == "L"
    @steps[0] = deep_dup step_vl0(str)
    @steps[1] = step_vl1(deep_dup @steps[0])
    @steps[2] = step_vl2(deep_dup @steps[1])
    @steps[3] = step_vl3(deep_dup @steps[2])
    @steps[4] = step_vl4(deep_dup @steps[3])
    @steps[5] = step_vl5(deep_dup @steps[4])
    @steps[6] = step_vl6(deep_dup @steps[5])
    @steps[7] = step_vl7(deep_dup @steps[6])
    @steps[8] = step_vl8(deep_dup @steps[7])
    @steps[9] = step_vl9(deep_dup @steps[8])

    @steps[10] = step_oi1(deep_dup @steps[9])
    @steps[11] = step_oi2(deep_dup @steps[10])
    @steps[12] = step_oi3(deep_dup @steps[11])
    @steps[13] = step_oi4(deep_dup @steps[12])
    @steps[14] = step_oi5(deep_dup @steps[13])
    @steps[15] = step_oi6(deep_dup @steps[14])
    @steps[16] = step_oi7(deep_dup @steps[15])
    @steps[17] = step_oi8(deep_dup @steps[16])
    @steps[18] = step_oi9(deep_dup @steps[17])
    @steps[19] = step_oi10(deep_dup @steps[18])
    @steps[20] = step_oi11(deep_dup @steps[19])
    @steps[21] = step_oi12(deep_dup @steps[20])
    @steps[22] = step_oi13(deep_dup @steps[21])
    @steps[23] = step_oi14(deep_dup @steps[22])
    @steps[24] = step_oi15(deep_dup @steps[23])
    @steps[25] = step_oi16(deep_dup @steps[24])
    @steps[26] = step_oi17(deep_dup @steps[25])
    @steps[27] = step_oi18(deep_dup @steps[26])
    @steps[28] = step_oi19(deep_dup @steps[27])
    @steps[29] = step_oi20(deep_dup @steps[28])
    @steps[30] = step_oi21(deep_dup @steps[29])
    @steps[31] = step_oi22(deep_dup @steps[30])
    @steps[32] = step_oi23(deep_dup @steps[31])
    @steps[33] = step_oi24(deep_dup @steps[32])
    @steps[34] = step_oi25(deep_dup @steps[33])
    @steps[35] = step_oi26(deep_dup @steps[34])
    @steps[36] = step_oi27(deep_dup @steps[35])
    @steps[37] = step_oi28(deep_dup @steps[36])
    @steps[38] = step_oi29(deep_dup @steps[37])
  end

  if ["OLF", "L"].include?(since)
    @steps[38] = convert_OLF(str) if since == "OLF"
    @steps[39] = step_oix1(deep_dup @steps[38])
    @steps[40] = step_oix2(deep_dup @steps[39])
    @steps[41] = step_oix3(deep_dup @steps[40])
    @steps[42] = step_oix4(deep_dup @steps[41])
    @steps[43] = step_oix5(deep_dup @steps[42])
    @steps[44] = step_oix6(deep_dup @steps[43])
    @steps[45] = step_oix7(deep_dup @steps[44])

    @steps[46] = step_CI1(deep_dup @steps[45])
    @steps[47] = step_CI2(deep_dup @steps[46])
    @steps[48] = step_CI3(deep_dup @steps[47])
    @steps[49] = step_CI4(deep_dup @steps[48])
    @steps[50] = step_CI5(deep_dup @steps[49])
    @steps[51] = step_CI6(deep_dup @steps[50])
    @steps[52] = step_CI7(deep_dup @steps[51])
    @steps[53] = step_CI8(deep_dup @steps[52])
  end

  if ["LL", "OLF", "L"].include?(since)
    @steps[53] = convert_LL(str) if since == "LL"

    @roesan_steps[0] = step_ri1(deep_dup @steps[53])
    @roesan_steps[1] = step_ri2(deep_dup @roesan_steps[0])
    @roesan_steps[2] = step_ri3(deep_dup @roesan_steps[1])
    @roesan_steps[3] = step_ri4(deep_dup @roesan_steps[2])
    @roesan_steps[4] = step_ri5(deep_dup @roesan_steps[3])
    @roesan_steps[5] = step_ri6(deep_dup @roesan_steps[4])
    @roesan_steps[6] = step_ri7(deep_dup @roesan_steps[5])
    @roesan_steps[7] = step_ri8(deep_dup @roesan_steps[6])
    @roesan_steps[8] = step_ri9(deep_dup @roesan_steps[7])
    @roesan_steps[9] = step_ri10(deep_dup @roesan_steps[8])
    @roesan_steps[10] = step_ri11(deep_dup @roesan_steps[9])
    @roesan_steps[11] = step_ri12(deep_dup @roesan_steps[10])
    @roesan_steps[12] = step_ri13(deep_dup @roesan_steps[11])
    @roesan_steps[13] = step_ri14(deep_dup @roesan_steps[12])

    @paysan_steps[0] = step_pi1(deep_dup @steps[53])
    @paysan_steps[1] = step_pi2(deep_dup @paysan_steps[0])
    @paysan_steps[2] = step_pi3(deep_dup @paysan_steps[1])
    @paysan_steps[3] = step_pi4(deep_dup @paysan_steps[2])
    @paysan_steps[4] = step_pi5(deep_dup @paysan_steps[3])
    @paysan_steps[5] = step_pi6(deep_dup @paysan_steps[4])
    @paysan_steps[6] = step_pi7(deep_dup @paysan_steps[5])
    @paysan_steps[7] = step_pi8(deep_dup @paysan_steps[6])
    @paysan_steps[8] = step_pi9(deep_dup @paysan_steps[7])
    @paysan_steps[9] = step_pi10(deep_dup @paysan_steps[8])
  end

  [@steps[53], @roesan_steps[-1], @paysan_steps[-1]]
end
