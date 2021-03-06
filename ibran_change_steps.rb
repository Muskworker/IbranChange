# frozen_string_literal: true

require 'forwardable'

# Dictum: A word or series of segments.
class Dictum < Array
  attr_accessor :features

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

  def initialize(segments = [], features = {})
    @features = features
    segments.inject(self) do |dict, seg|
      dict << seg
    end
  end

  # TODO: maybe add an ability to change substrings instead of entire matches
  def change(origin, target, consequence = nil)
    each do |segm|
      next unless segm.match(origin) && (block_given? ? yield(segm) : true)

      segm.merge!(target)
      consequence&.call(segm)
    end
  end

  def retro_change(origin, target, consequence = nil)
    reverse_each do |segm|
      next unless segm.match(origin) && (block_given? ? yield(segm) : true)

      segm.merge!(target)
      consequence&.call(segm)
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
    inject(String.new) do |memo, obj|
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
        output += 'ˈ' unless output =~ /ˈ\S*$/ # Don't add more than one
      end

      output + segm.to_ipa
    end
  end

  # Remove spaces
  def combine_words
    change(' ', {}, ->(s) { s.delete })
  end
end

# Determine the properties of a segment that depend on its surroundings.
module PhoneticEnvironment
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

  def intervocalic?
    prev.vocalic? && nxt.vocalic?
  end

  def initial?
    pos.zero? || nxt.phon == ' '
  end

  def penultimate?
    pos == @dictum.size - 2 || (nxt.phon != ' ' && nxt.phon == ' ')
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

  def pretonic?
    @dictum[pos + 1...@dictum.size].any?(&:stressed?)
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
    vowels = 'aeioõuũyæɑɐəɛɔøœ'
    neither_vowel_nor_modifier = "^aeioõuũyæɑɐəɛɔøœ\u0303"
    count(vowels) == 1 && count(neither_vowel_nor_modifier).zero?
  end

  def diphthong?
    return true if %w[au ae oe].include?(self)

    vowel_count = count('aeiouyæɑɐəɛɔøœ')
    modifier_count = count("jwɥ\u032fː")
    neither_count = count("^aeiouyæɑɐəɛɔøœjwɥ\u0303\u032fː")
    vowel_count.positive? && modifier_count.positive? && neither_count.zero?
  end

  def rising_diphthong?
    diphthong? && self[0].consonantal?
  end

  def falling_diphthong?
    diphthong? && self[-1].consonantal?
  end

  def nucleus
    chars.max_by(&:sonority)
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
    @dictum = Dictum.new(self)
    @pos = 0

    return unless args.any?

    update(IPA: (args[0] || '').dup, orthography: (args[1] || args[0]).dup)
  end

  def replace!(args)
    update(IPA: args[0].dup, orthography: (args[1] || args[0]).dup)
  end

  # TODO: Don't ever set this to nil.
  def phon
    fetch(:IPA, String.new) || String.new
  end

  def orth
    fetch(:orthography, String.new) || String.new
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
    when Symbol then parse_sym(segm)
    when String then phon == segm
    when Array then segm.any? { |s| match(s) }
    when Proc then segm.call(self)
    else phon =~ segm
    end
  end
  alias =~ match

  # TODO: This doesn't belong here
  def parse_sym(feat)
    return send("#{feat}?") unless feat =~ /_with_/

    feat = feat.to_s.partition('_with_')

    target = case feat[0]
             when 'starts' then starts_with
             when 'ends' then ends_with
             end

    target.send("#{feat[-1]}?")
  end

  def [](feat)
    fetch(feat) do
      begin
        parse_sym(feat)
      rescue NoMethodError
        default
      end
    end
  end

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
    # self.phon.concat(phon)
    # self.orth.concat(orth)
    update(IPA: self.phon + phon, orthography: self.orth + orth)
  end

  def prepend(phon, orth = phon)
    self.phon.prepend(phon)
    self.orth.prepend(orth)
  end

  def to_ipa
    output = "#{phon}#{"\u0320" if self[:back]}#{'ʲ' if self[:palatalized]}"
    # /o:w/, not /ow:/
    output = output.sub(/([jwɥ]*)$/, 'ː\1') if self[:long]
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
    update(IPA: phon.tr('vʒzbdg', 'fʃsptk')) if target.voiceless?
    phon
  end

  def voice!
    update(IPA: phon.tr('fçʃsptθk', 'vʝʒzbddg'))
    phon
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
  DIGRAPHS = /[ao]e|[ae]u|[ey][ij]|qu|[ckprt]h|./i.freeze

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

    word.last.merge!(IPA: nil, orthography: nil) if %w[! - > <].include? exception

    if exception == '!'
      vowels[-1][:stress] = true
    elsif vowels.length > 1 && exception != '-'
      modifier = { '>' => 1, '<' => -1 }.fetch(exception, 0)
      vowels[Latin.stressed_syllable(word) + modifier][:stress] = true
    end
  end
end

# Complex Ibran conditions
class OldIbran
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
    || segm.between?(:sibilant, :sibilant)
  end

  def self.between_single_consonants?(segm)
    segm.between?(%i[vocalic intervocalic], %i[vocalic intervocalic]) \
    && (segm.next.vocalic? ? 0 : segm.next.phon.length)               \
     + (segm.prev.vocalic? ? 0 : segm.prev.phon.length) <= 2
  end

  # Test for Vm#, VmC; VRm#, VRmC as used in oix3
  def self.takes_m_change?(segm)
    segm.sonorant? && [segm, segm.next].any? do |s|
      s =~ 'm' && (s.next.starts_with.consonantal? || s.final?)
    end
  end

  def self.takes_l_change?(segm)
    after_next = segm.after_next

    (segm.next =~ [:labial, 'l']                     \
    && after_next.starts_with =~ [:consonantal, '']) \
    || (after_next =~ [:labial, 'l']                 \
    && after_next.between?(:sonorant, [:consonantal, '']))
  end

  def self.borrow_old_dutch(word)
    ary = OldDutch.to_dictum(word)

    # Practically all of this belongs in an Ibran class,
    # as these are not this language's transformations
    OldDutch.front_velars(ary)
    OldDutch.postvocalic_h(ary)
    OldDutch.endings(ary)
    OldDutch.assign_stress(ary)
    OldDutch.vowel_reduction(ary)
  end
end

# Complex exceptions to regular Ibran changes
class OldIbranChange
  # Outcomes of vowels before /k g l/ before dentals  and nasals
  def self.uncluster!(segm)
    ipa = segm.phon
    orig = %w[a ɑ e ɛ o ɔ i u]
    phon = %w[ɑɛ̯ ɑɛ̯ ɛj ɛj ɔɛ̯ ɔɛ̯ ej oj]
    orth = %w[ae ae ei ei oe oe éi ói]
    outcomes = Hash[orig.zip(phon.zip(orth))]

    segm.replace!(outcomes[ipa])
  end

  # Outcome of clusters following stressed vowels
  def self.post_stress_uncluster!(segm)
    prv = segm.prev
    nxt = segm.next
    orth = segm.orth

    prv =~ %w[i u] ? gemn = segm.ends_with.phon : OldIbranChange.uncluster!(prv)

    outcomes = { 'ks' => %W[#{gemn}s #{nxt.vowel? ? 'ss' : 's'}],
                 'dʒ' => %W[#{gemn}ʒ #{'s' if gemn}#{orth}],
                 'tʃ' => %W[#{gemn}ʃ #{'s' if gemn}#{orth}] }

    outcomes.default = %W[#{nxt.phon if gemn} #{gemn}]

    segm.replace!(outcomes[segm.phon])
  end

  def self.unstressed_uncluster!(segm)
    return unless (segm.velar? && segm.before?(%i[dental nasal])) \
                  || (segm =~ %i[dental velar] && segm.before?(:sibilant))

    segm.update(segm.next.starts_with)
    segm[:orthography] = 's' if segm.before?(final: true, sibilant: true)
  end

  def self.unstressed_deaffricate!(segm)
    return unless segm =~ ['ks', :affricate]

    segm[:orthography] = "s#{(segm.orth unless segm =~ 'ks') \
                             || ('s' if segm.before?(:vowel))}"
    segm[:IPA] = segm.ends_with.phon * 2
  end

  # Intervocalic T becomes L, generally.
  # But original VtVtV becomes VlVdV, and original VlVtV becomes VdVlV.
  # (In other words, T becomes D after intervocalic T
  # and L becomes D before intervocalic T.)
  def self.lateralize_t!(word)
    word.change('t', Segment.new('l'), lambda do |t|
      { 't' => t.after_next, 'l' => t.before_prev }.each do |match, cons|
        cons.update(Segment.new('d')) if cons.match_all(match, :intervocalic)
      end
    end, &:intervocalic?)
  end

  def self.diphthongize_e!(segm)
    return if segm.after?([:sibilant, :affricate, { palatalized: true }]) \
           || segm.prev.ends_with =~ %w[ʎ j i]

    segm[:IPA] = "j#{segm[:IPA]}"
    segm[:orthography] = "i#{segm[:orthography]}"
  end

  def self.diphthongize_open_o!(segm)
    if segm.before?(:sonorant) \
    && (segm.before?(:final) || segm.after_next.consonantal?)
      segm[:IPA] = 'wɛ'
      segm[:orthography] = 'ue'
    else
      segm[:IPA] = 'ɔj'
      segm[:orthography] = 'oi'
    end
  end

  def self.diphthongize_closed_o!(segm)
    return unless segm.final?                                        \
               || segm.before?(%i[vocalic intervocalic])             \
               || (segm.before?('s') && segm.after_next.consonantal? \
                   && segm.next.after_next.vowel?)

    segm.update(IPA: 'u', orthography: 'uo', long: true)
    segm.prev.orth.sub!(/q?u$/, 'u' => '', 'qu' => 'c')
  end

  def self.umlaut!(segm)
    outcomes = { 'ɑ' => %w[a ài], 'a' => %w[a ài], 'ɛ' => %w[ɛ ei],
                 'e' => %w[ɛ ei], 'ɔ' => %w[œ eu], 'o' => %w[œ eu],
                 'u' => %w[y ui] }

    segm.replace!(outcomes[segm.phon])
  end

  def self.dediphthongize!(word)
    word.change(/[ɔouw]w\u0303?\Z/, { long: true }, lambda do |segm|
      outcomes = { 'ɔw' => 'o', 'ow' => 'o', 'uw' => 'u',
                   'ɔw̃' => 'õ', 'ow̃' => 'õ', 'uw̃' => 'ũ' }
      segm[:IPA] = segm.phon.gsub(/[ɔouw]w\u0303?/, outcomes)
    end)

    word.change(/w\u0303?w/, Segment.new, lambda do |segm|
      segm[:IPA].chop!
      segm[:orthography].sub!(/uu|ũu/, 'uu' => 'w', 'ũu' => 'w̃')
    end)
  end
end

# Complex conditions in Common Ibran
class CommonIbran
  # VNC / VN#
  def self.nasalizes(segm)
    segm.ends_with.vowel? && segm.next.ends_with =~ %w[m n ŋ] \
      && (segm.after_next.starts_with.consonantal? || segm.next.final?)
  end

  def self.affricate_change(segm)
    outcomes = { 'tʃ' => 'ç', 'dʒ' => 'ʝ', 'ts' => 's', 'dz' => 'z' }

    if segm.prev =~ %w[t d]
      segm[:orthography] = "#{segm.prev.orth}#{segm[:orthography]}"
      segm.prev.delete
    else
      segm[:IPA] = outcomes[segm.phon]
    end
  end

  U_TO_BE_W = lambda do |segm|
    segm.starts_with.orth == 'u' &&
      segm[:orthography][0..1] != 'uo' &&
      (segm.match_all(:initial, :diphthong) || segm.prev.vowel?)
  end

  I_TO_BE_Y = lambda do |segm|
    segm.starts_with.orth == 'i' &&
      (segm.match_all(:initial, :diphthong) || segm.prev.vowel?)
  end
end

# Complex conditions in Paysan Ibran
class PaysanIbran
  def self.s_drop!(ess)
    prev = ess.prev
    prev_long = prev[:long]
    outcomes = if prev_long then { 'e' => 'eî', 'o' => 'oû', 'æ' => 'àî' }
               else { 'e' => 'ê', 'o' => 'ô', 'æ' => 'àî' }
               end

    prev[:orthography] \
      = prev.orth.gsub(/(#{'.?' if prev_long}.)\Z/,
                       (outcomes[prev.ends_with.phon] || "\\1\u0302"))
    prev[:IPA] = prev.phon.tr('eo', 'ɛɔ')

    ess.delete
  end

  def self.close_diphthong(segm)
    outcomes = { 'je' => %w[i i], 'jẽ' => %w[ĩ in], 'e' => %w[i i],
                 'ẽ' => %w[ĩ in], 'wo' => %w[u uo], 'wõ' => %w[ũ uon],
                 'o' => %w[u uo], 'õ' => %w[ũ uon], 'wø' => %w[y u],
                 'wø̃' => %w[ỹ un], 'ø' => %w[y u], 'ø̃' => %w[ỹ un] }

    outcome = outcomes[segm.phon]
    outcome[1] = outcome[1].tr('i', 'y') if segm.after?([:vocalic, { IPA: 'j', intervocalic: true }])

    outcome
  end

  def self.break_semivowels(ary)
    ary.change(/(ɥ|œ̯)\Z/, {}, lambda do |segm|
      segm[:IPA] = segm.phon.sub(/(ɥ|œ̯)\Z/) do |match|
        stress = segm.stressed?

        segm[:long] = true unless stress
        ary.insert(segm.pos + 1,
                   Segment[IPA: 'ə', orthography: stress ? 'ă' : 'a'])
        segm[:orthography][-(stress ? 2 : match.length)..-1] = '' # also IPA ''
      end
    end)
  end

  def self.resolve_hiatus(ary)
    ary.change(:unstressed, {}, lambda do |segm|
      ## Lengthen vowels before pretonic vowels in hiatus before unstressed
      segm[:long] = true if segm.next.match_all(:vowel, :unstressed) && segm.pretonic?

      if segm.before?(:vowel) && segm.match_all(:posttonic, %w[i ɛ je])
        segm.next.prepend('j', segm.orth)
        segm.delete
        next
      end
    end)
  end

  # make sure the spelling of the previous segment matches the given vowel
  def self.respell_velars(segm)
    prev = segm.prev

    return unless %w[a à o ó u ă].include?(segm.starts_with.orth) \
               && !%w[i j h].include?(prev.ends_with.orth)        \
               && prev.ends_with =~ %w[ʃ ç ʒ ʝ g k s]

    outcomes = { 'g' => 'g', 'k' => 'c', 'ʒʒ' => 'sç',
                 's' => prev[:intervocalic] ? 'ss' : 's' }

    prev[:orthography] = outcomes[prev.phon] || 'ç'
  end

  # Shorten and apply breves
  def self.reduce_unstressed(segm)
    vowel_pos = segm.starts_with.vowel? ? 0 : 1
    segm[:IPA] = segm[:IPA].dup # why is this frozen
    segm[:IPA][vowel_pos] = 'ə'
    if segm.posttonic? && segm[:orthography] != 'ă'
      # The check for \u0302 is to get rid of "ă̂"
      # The "main" vowel may not exist, e.g. if the orth is |y| [jV]
      outcome = segm.dictum.join =~ /ă/ ? '\\1a' : '\\1ă'
      segm[:orthography] = segm.orth.sub(/(.{#{vowel_pos}})(.\u0302?)?/,
                                         outcome)
    end

    PaysanIbran.respell_velars(segm)
  end

  def self.respell_q(ary)
    ary.change({ IPA: 'kw', orthography: 'qu' }, orthography: 'cu')

    ary.change({ orthography: 'qu' }, orthography: 'c') do |iff|
      %w[a à o ó u].include?(iff.next.orth[0])
    end
  end

  def self.respell_y_after_jot(ary)
    ary.change(->(s) { s.orth =~ /i/ }, {}, lambda do |segm|
      segm[:orthography] = segm.orth.gsub(/i/, 'y')
    end) { |iff| iff.after?('j') }
  end

  def self.drop_breves_after_accents(ary)
    ary.change(->(s) { s.orth =~ /ă/ }, {}, lambda do |segm|
      segm[:orthography] = segm.orth.gsub(/ă/, 'a')
    end) { |iff| %w[é ó].include?(iff.prev.orth[-1]) }
  end

  def self.respell_vowels(ary)
    outcomes = { 'll' => 'y', 'iy' => 'y', 'ũ' => 'u',
                 'w̃' => 'w', 'uou' => 'uo', 'àu' => 'au' }

    # Orthography changes
    ary.change([:vocalic, 'j'], {}, lambda do |segm|
      # several changes happening in 'order'
      outcomes.each_key do |key|
        segm[:orthography] = segm.orth.gsub(/#{key}/, outcomes)
      end
    end)
  end

  def self.orthographic_changes(ary)
    ary.change('l', orthography: 'l') # |gl| /ll/
    ary.change('ji', orthography: 'y')
    respell_q(ary)
    respell_y_after_jot(ary)
    drop_breves_after_accents(ary)
    respell_vowels(ary)
  end
end

# Complex conditions in Roesan Ibran
class RoesanIbran
  def self.jot_to_harden?(segm)
    not_lj = !segm.after?('l')
    prevocalic = (segm.rising_diphthong? ||
                  segm.match_all(:consonantal, ->(s) { s.before?(:vocalic) }))
    after_appropriate = (segm.initial? ||
                        segm.after?([:dental, :vocalic, lambda do |s|
                          s.match_all('r', :intervocalic)
                        end]) &&
                        segm.vowels_before.positive?)

    not_lj && prevocalic && after_appropriate
  end

  def self.jotate_dentals(ary)
    outcomes = { 'd' => 'ɟʝ', 't' => 'cç', 's' => 'ç' }

    ary.change(outcomes.keys, {}, lambda do |segm|
      segm[:IPA] = outcomes[segm.phon]
      segm.next[:IPA][0] = ''
    end) { |iff| iff.before?(/\Aj/) }
  end

  def self.harden_prevocalic_jot(ary)
    ary.change(/\Aj/, {}, lambda do |segm|
      if segm.rising_diphthong?
        ary.insert(segm.pos, Segment[IPA: 'ʝ', orthography: ''])
        segm[:IPA][0] = ''
      else
        segm[:IPA] = 'ʝ'
      end
    end) { |segm| RoesanIbran.jot_to_harden?(segm) }
  end
end

# Operations for Old French words
class OldFrench
  def self.assign_stress(ary)
    # assign stress
    final_stress = ary[-1] =~ '!'

    ary.change(:vocalic, { stress: true }, lambda do |_|
      ary[-1].delete if final_stress
    end) do |iff|
      (final_stress || iff !~ 'ə') \
      && iff.dictum[iff.pos + 1...-1].all?(&:consonantal?)
    end
  end

  # This isn't properly separated.
  def self.to_ipa(word)
    outcomes = { 'ch' => 'tʃ', 'j' => 'dʒ', 'c' => 'k', 'qu' => 'k',
                 'ou' => 'u',  'eu' => 'ew', 'u' => 'y', 'o' => 'ɔ',
                 'z' => 'dz', 'y' => 'j', 'ai' => 'aj' }

    word.scan(/ch|[eoq]u|ai|./).inject(Dictum.new) do |memo, obj|
      memo << Segment[IPA: outcomes.fetch(obj, obj).dup.downcase,
                      orthography: obj.dup]
    end
  end

  def self.to_dictum(word)
    # Raw IPA convert
    ary = OldFrench.to_ipa(word)

    # c before front vowels
    ary.change({ IPA: 'k', orthography: 'c' }, IPA: 'ts') do |iff|
      iff.next.orth =~ /^(i|e)/
    end

    ary.change('g', IPA: 'dʒ') { |iff| iff.next.orth =~ /^(i|e)/ }

    # final schwa
    ary.change('e', IPA: 'ə', &:final?)

    # TODO: open vs closed /e/ (what? at this era?)

    # final dz
    ary.change('dz', IPA: 'ts', &:final?)

    OldFrench.assign_stress(ary)
  end
end

# Operations for Old Dutch words
class OldDutch
  def self.vowel_reduces?(segm)
    segm.vowels_before.positive? && segm.match_all(:vocalic, :unstressed) \
    && !segm[:long] && segm !~ [:diphthong, 'ə']
  end

  def self.naive_ipa(str)
    orth = %w[qu ch th aũ au eu ā a ié ie ei ē e iw īw ī uo ou o ō ū c ng ph nj]
    phon = %w[kw k θ o o œ ɑ ɑ je jɛ ɛj e ɛ iw iw i u ɔw ɔ o u k ŋ f ɲ]
    search = str.downcase

    Hash[orth.zip(phon)].fetch(search, search).dup
  end

  # velar before front vowels
  def self.front_velars(ary)
    ary.change(%w[k g], { palatalized: true }, lambda do |segm|
      segm[:orthography] = segm.voiced? ? 'gu' : 'qu'
    end) { |iff| iff.next.starts_with =~ [:front_vowel, 'j'] }
  end

  # post-vocalic H
  def self.postvocalic_h(ary)
    ary.change('h', { orthography: 'gh' }, lambda do |segm|
      segm[:IPA] = segm.before?(:voiced) ? 'g' : 'k'
    end) { |iff| iff.between?(:vocalic, :consonantal) || iff.final? }
  end

  def self.endings(ary)
    # Endings
    case ary.join
    when /are$/
      ary.pop(3)
      ary << Segment[IPA: 'ɑ', orthography: 'a', long: false, stress: true] \
          << Segment[IPA: 'r', orthography: 'r', long: false]
    when /ariu(m|s)$/ # ariam, arium
      ary.pop(5)
      ary << Segment[IPA: 'a', orthography: 'ài', long: true, stress: true] \
          << Segment[IPA: 'r', orthography: 'r', long: false]
    end
  end

  # assign stress
  # This is not even close to universally true
  # but will work for our initial case
  def self.assign_stress(ary)
    vowels = ary.find_all(&:vocalic?)

    case ary[-1][:orthography]
    when '!'
      vowels[-1][:stress] = true
    when '>'
      vowels[1][:stress] = true unless ary.stressed? || vowels.length < 2
    else
      vowels[0][:stress] = true unless ary.stressed?
    end

    ary.change(%w[! >], {}, ->(s) { s.delete })
  end

  def self.vowel_reduction(ary)
    ary.change(:vocalic, Segment.new('ə', 'e'), lambda do |segm|
      # metathesis of @C > C@
      if segm.between?(:intervocalic, final: true, consonantal: true)
        outcomes = { 'qu' => 'c', 'gu' => 'g' }
        segm.prev[:orthography] = outcomes.fetch(segm.prev.orth, segm.prev.orth)

        segm.metathesize(segm.next)
      end
    end) { |iff| OldDutch.vowel_reduces?(iff) }

    OldDutch.respell_velars(ary)
  end

  def self.respell_velars(ary)
    ary.change(%w[k g], {}, lambda do |segm|
      segm[:orthography] = segm =~ 'k' ? 'qu' : 'gu'
    end) { |iff| %w[e i é].include?(iff.next.orth) }
  end

  # INCOMPLETE
  def self.to_dictum(word)
    maps = { 'k' => 'c', 'y' => 'i', 'ā' => 'a', 'ē' => 'éi', 'īw' => 'iu',
             'iw' => 'iu', 'ī' => 'i', 'ō' => 'ó', 'ū' => 'u', 'nj' => 'nh',
             'j' => 'y' }

    word.scan(/[ct]h|qu|kw|ei|eu|uo|[iī]w|ou|ng|i[ée]|aũ|au|nj|./i).inject(Dictum.new) do |memo, obj|
      long = obj =~ /[āēīōūȳ]|uo|aũ|au|eu/i
      phon = OldDutch.naive_ipa(obj)
      orth = maps.fetch(obj.downcase, obj.dup)

      memo << Segment[IPA: phon, orthography: orth, long: long]
    end
  end
end

# Operations for late-borrowed Latin words
class LateLatin
  def self.to_dictum(str)
    ary = str.scan(/[aeé]u|i?.ũ|iéu?|[aoi]e|[ey][ij]|qu|[ckprtg]h|ss|[ln]j|./i).inject(Dictum.new) do |memo, obj|
      supra = {}
      supra.merge!(long: true) if obj.match(/aũ|éũ|eũ|éu|eu|iũ/i)
      supra.merge!(was_k: true) if obj.match(/k|ch/)

      phon = case obj
             when /qu/i          then 'kw'
             when /x/i           then 'ks'
             when /ss/i          then 's'
             when /aũ|au/i       then 'o'
             when /iéũ|iéũ|iéu/i then 'jø'
             when /ié/i          then 'je'
             when /ie/i          then 'jɛ'
             when /éũ|éu/i       then 'ø'
             when /eũ|eu/i       then 'œ'
             when /iũ|iu/i       then 'y'
             when /ae/i          then 'ɑɛ̯'
             when /ā|ă|a/i       then 'ɑ'
             when /ē|ĕ|e/i       then 'ɛ'
             when /ī|ĭ|ȳ|y̆|y/i   then 'i'
             when /ō|ŏ|o/i       then 'ɔ'
             when /ū|ŭ/i         then 'u'
             when /c/i           then 'k'
             when /z/i           then 'ʃ'
             when /ph/i          then 'f'
             when /rh/i          then 'r'
             when /th/           then 'θ'
             when /lj/           then 'ʎ'
             when /nj/           then 'ɲ'
             # when /ng/i          then 'ng'
             when /j/            then 'ʝ'
             else obj.dup.downcase
             end

      orth = case obj
             # when /k/i  then "c"
             when /ī/i  then 'i'
             when /y/i  then 'i'
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
    end) { |iff| iff.between?('n', 'u') && iff.after_next.starts_with.vowel? }

    # /gw/ in LL verb forms
    ary.change('g', {}, lambda do |segm|
      segm[:orthography] = 'gu' unless segm.after_next =~ '>'
      segm.next.delete
    end) { |iff| iff.between?('n', 'u') && iff.after_next.starts_with =~ ['>', 'j'] }

    # jot
    ary.change(%w[t s ks], { IPA: 'ʃʃ' }, lambda do |segm|
      segm[:orthography] << 'i'
      segm.next.delete
    end) { |iff| iff.before?('i') && iff.after_next.vowel? }

    # assign stress to each word
    ary.change(:final, {}, lambda do |mark|
      initial = ary[0...mark.pos].reverse_each.find { |s| s =~ :initial }
      word = ary[initial.pos..mark.pos]
      vowels = word.find_all(&:vocalic?)

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

      if vowels[-2]&.stressed? && %w[ɛ ɔ].include?(vowels[-2][:IPA])
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
      initial = ary[0...segm.pos].reverse_each.find { |s| s =~ :initial }
      word = ary[initial.pos..segm.pos]

      # TODO: correctly get this working for multiple words
      # TODO: get 'pop' working
      case word.join
      when /alis|alem$/
        segm.before_prev.prev.update(IPA: 'o', orthography: 'au', stress: true, long: true)
        segm.dictum[-3].delete # l
        segm.dictum.renumber   # argh
        segm.dictum[-2].delete # i/e
        segm.dictum.renumber   # argh
        segm.delete            # s/m
      when /āre$/
        segm.before_prev.update(orthography: 'a', stress: true)
        segm.delete # e
      when /ariu(m|s)$/ #ariam, arium
        segm.before_prev.before_prev.update(IPA: 'a', orthography: 'ài', long: true, stress: true)
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
        respell_velars(word)
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
      when /onem$/
        segm.before_prev.prev.update(IPA: 'ũ', orthography: 'uon', long: true, stress: true)
        segm.dictum[-3].delete # n
        segm.dictum.renumber   # argh
        segm.dictum[-2].delete # e
        segm.dictum.renumber   # argh
        segm.delete            # m
      when /tórem$/
        segm.before_prev.prev.update(IPA: 'u', orthography: 'uo', long: true, stress: true)
        segm.dictum[-2].delete # e
        segm.dictum.renumber   # argh
        segm.delete            # m
      when /ium$/
        # segm.before_prev.replace!(%w[j i]) if segm.before_prev =~ 'i'
        segm.prev.replace!(%w[ə e])         # u
        segm.delete                         # m
      when /(e|u)m$/ # not us
        segm.delete # m
        step_oi26(ary)
      end
    end)

    ary.change('i', {}, lambda do |segm|
      ary.insert(segm.pos + 1, Segment.new('j', '')) # segm.append('j', '')
    end) { |iff| iff.pretonic? && iff.next.vocalic?  }

    @current = ary
    # duplicate stresses after endings
    @current.select(&:stressed?)[0..-2].each{|s| s[:stress] = false} if @current.count(&:stressed?) > 1

    @current = step_oix1(@current)
    @current = step_ci2(@current)
    @current = step_ci3(@current)
    @current = step_ci4(@current)
    @current = step_ci5(@current)
    @current = step_ci8(@current)

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
        if (segm.next.starts_with.front_vowel? || segm.next.starts_with =~ 'j' ) && segm.next[:orthography] != "u"
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

      segm[:orthography] = segm[:orthography].gsub(/ch/, "c")

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
end

def takes_stress_mark(segm)
  return true if segm.stressed?

  dictum = segm.dictum
  stressed = dictum.index(&:stressed?)

  # False unless stress happens anywhere after this segment.
  return false unless stressed && stressed > segm.pos

  # Is everything from here to the stressed segment
  # in [the same] syllable onset?
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
  when 'ʃ', 'ʒ'
    segm[:orthography] = segm[:orthography].chop + res[prec][front]
  when 'k', 'g'
    segm[:orthography] = res[prec][front]
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
  lemma.change({ IPA: 'n' }, IPA: 'm') { |segm| segm.next =~ 'f' }

  # /ps/ and /pt/ act like /ks/ and /kt/
  lemma.change({ IPA: 'p' }, IPA: 'k') { |segm| segm.next =~ %w[s t] }

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
    segment[:IPA] = segment[:IPA].delete 'h'
    unless segment.orth == 'ph'
      segment[:orthography] = segment[:orthography].delete 'h'
    end
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
    nxt.update(IPA: 'r', orthography: 'r') if seg.between? %w[t f d], %w[l n]

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
  OldIbranChange.lateralize_t!(ary)

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
    OldIbranChange.uncluster!(s)
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
      OldIbranChange.unstressed_uncluster!(nxt)
      OldIbranChange.unstressed_deaffricate!(nxt)
    elsif segm.before?(['ks', :affricate]) \
       || (segm.before?(%i[dental velar]) && segm.after_next.sibilant?)
      OldIbranChange.post_stress_uncluster!(nxt)
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
  ary.change(%w[ɑ a ɛ e ɔ o u], { long: true }, lambda do |segm|
    anxt = segm.after_next

    OldIbranChange.umlaut!(segm)
    (anxt =~ 'j' ? anxt : anxt.next).delete
  end) do |iff|
    anxt = iff.after_next

    (iff.before?('r') && anxt =~ 'j') ||
      (iff.before?(:stop) && anxt =~ 'r' && anxt.before?('j'))
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
    when 'ɛ', 'e' then OldIbranChange.diphthongize_e!(segm)
    when 'ɔ'      then OldIbranChange.diphthongize_open_o!(segm)
    when 'o'      then OldIbranChange.diphthongize_closed_o!(segm)
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

  respell_velars(ary)
end

# reduce unstressed medial syllables
def step_oi29(ary)
  ary.change(:vocalic, {}, lambda do |segm|
    if OldIbran.between_single_consonants?(segm) then segm.delete
    else segm.replace!(%w[ə e])
    end

    respell_palatal(segm.prev)
  end) do |segm|
    segm.vowels_before.positive? && segm.vowels_after.positive? \
    && segm !~ [:stressed, 'ə']
  end
end

# plural /Os As/ to /@s/
def step_oix1(ary)
  if ary.features[:plural]
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
  end) { |iff| OldIbran.takes_m_change?(iff.next) }
end

# labials & L > /w/ before consonants/finally
def step_oix4(ary)
  ary.change(:vocalic, {}, lambda do |segm|
    nxt = segm.next
    nxt.metathesize(segm.after_next) if nxt !~ [:labial, 'l']

    segm[:orthography] = segm[:orthography].sub(/(.)i$/, '\1y')
    segm.append('w', 'u')
    nxt.delete
  end) { |iff| OldIbran.takes_l_change?(iff) }
end

# resolution of diphthongs in /a A @ V/
def step_oix5(ary)
  ary.change(:diphthong, { long: true }, lambda do |segm|
    # \u0303 is combining tilde
    segm[:IPA] = segm.ends_with =~ "\u0303" ? 'õ' : 'o'
  end) { |iff| iff.phon =~ /[aɑə]w?[w\u0303]$/ }
end

# resolution of diphthongs in /E e i/
def step_oix6(ary)
  ary.change(/j?[ɛeiy]w\u0303?$/, { long: true }, lambda do |segm|
    outcomes = { 'ɛw' => 'œ', 'ew' => 'ø', 'iw' => 'y', 'yw' => 'y' }
    segm[:IPA] = segm.phon.sub(/ɛw|ew|iw|yw/, outcomes)
  end)

  ary.change(:diphthong, {}, lambda do |segm|
    segm[:IPA] = segm.phon.sub(/jw/, 'ɥ')
    segm[:IPA] = segm.phon.sub(/ɛ̯w/, 'œ̯')
  end)
end

# resolution of diphthongs in /O o u/
def step_oix7(ary)
  OldIbranChange.dediphthongize!(ary)

  # Assign stress if there are multiple
  ary.change(:stressed, { stress: false }, nil, &:pretonic?)

  # Assign stress to the first syllable if there isn't any
  ary.change(:vocalic, stress: true) { |iff| !iff.dictum.stressed? }
end

# now lose all those precious nasals
def step_ci1(ary)
  outcomes = { 'w̃' => 'w', 'ũ' => 'u', 'õ' => 'o', 'œ̃' => 'œ',
               'œ̯̃' => 'œ̯', 'ø̃' => 'ø', 'ỹ' => 'y', 'ɥ̃' => 'ɥ' }

  ary.change(:vocalic, {}, lambda do |segm|
    segm[:IPA] = segm.phon.gsub(/(w̃|ũ|õ|œ̃|œ̯̃|ø̃|ỹ|ɥ̃)/, outcomes)
  end) { |iff| iff.orth =~ /ũ|w̃/ }
end

# New nasals from /n/ before consonants/finally
def step_ci2(ary)
  ary.change(:vocalic, {}, lambda do |segm|
    segm[:IPA] += "\u0303"
    segm[:orthography] += if segm.next.final? then segm.next.orth
                          elsif segm.after_next.labial? then 'm'
                          else 'n'
                          end

    segm.next.delete
  end) { |segm| CommonIbran.nasalizes(segm) }
end

# Neutralization of voicing in fricatives
def step_ci3(ary)
  ary.retro_change(:fricative, {}, lambda do |segm|
    if segm.next.voiceless? || segm.final?
      segm.devoice!
    else
      segm.voice!

      segm[:orthography] = 'd' if segm.orth == 'th'
    end
  end)
end

# short u(~) > y
def step_ci4(ary)
  ary.change(/u/, {}, lambda do |s|
    s[:IPA] = s[:IPA].tr('u', 'y')

    # French ou -> iu, which is already /y/
    s[:orthography] = s[:orthography].tr('o', 'i')
  end) { |iff| !iff[:long] }
end

# ʎ > j / iʎ -> i: finally or before consonants
def step_ci5(ary)
  ary.change(/i\Z/, { long: true }, lambda do |segm|
    segm[:orthography] += 'll'
    segm.next.delete
  end) do |iff|
    iff.next =~ 'ʎ' \
    && (iff.after_next =~ %i[rising_diphthong consonantal] || iff.next.final?)
  end

  ary.change('ʎ', IPA: 'j')
end

# gl > ll
def step_ci6(ary)
  ary.change('g', IPA: 'l', palatalized: false) do |iff|
    !iff.initial? && iff.next =~ 'l'
  end
end

# reduce affricates
def step_ci7(ary)
  ary.change(:affricate, {}, ->(s) { CommonIbran.affricate_change(s) })
end

# i > ji after hiatus
def step_ci8(ary)
  ary.change('i', IPA: 'ji') { |iff| iff.prev.ends_with.vowel? }

  ary.change(CommonIbran::I_TO_BE_Y, {}, lambda do |segm|
    segm[:orthography] = 'y' + segm[:orthography][1..-1]
  end)

  ary.change(CommonIbran::U_TO_BE_W, {}, lambda do |segm|
    segm[:orthography][0] = 'w'
  end)
end

#############
# õ ã > u~ 6~
def step_ri1(ary)
  ary.change(/o\u0303/, IPA: "u\u0303")
  ary.change(/a\u0303/, IPA: "ɐ\u0303")
end

# syll-initial /j/
def step_ri2(ary)
  RoesanIbran.jotate_dentals(ary)
  RoesanIbran.harden_prevocalic_jot(ary)

  ary.change(:falling_diphthong, {}, lambda do |segm|
    ary.insert(segm.pos + 1, Segment[IPA: 'ʝ', orthography: ''])
    segm[:IPA].chop!
  end) { |iff| iff.next.starts_with.vowel? }
end

# assimilation of /s/
def step_ri3(ary)
  ary.change('s', {}, lambda do |segm|
    segm[:IPA] = segm =~ %i[final initial] ? 'ʰ' : segm.next.phon[0]
  end) do |iff|
    !iff[:long] &&
      ((iff.after?(:vocalic) || iff.initial?) &&
       (iff.before?(:consonantal) || iff.final?))
  end
end

# je wo wø > ji u y in closed syllables
def step_ri4(ary)
  ary.change('je', IPA: 'ji') { |iff| iff.before?(:consonantal) }
  ary.change('wo', IPA: 'u') { |iff| iff.before?(:consonantal) }
  ary.change('wø', IPA: 'y') { |iff| iff.before?(:consonantal) }
end

# w > 0 before round vowels
def step_ri5(ary)
  # TODO: accepting 'starts_with_round?' for 'starts_with.round?'
  #       would simplify so much
  ary.change(/w/, {}, lambda do |segm|
    return segm.phon.delete!('w') if segm.vocalic?

    segm.next.prepend('', segm.orth)
    segm.delete
  end) do |iff|
    iff.next =~ :starts_with_round \
    || (iff.rising_diphthong? && iff.nucleus.round?)
  end
end

# k_j g_j > tS dZ
def step_ri6(ary)
  outcomes = { 'k' => 'tʃ', 'g' => 'dʒ' }

  ary.change(%w[k g], {}, lambda do |segm|
    segm.prev[:IPA] = outcomes.fetch(segm.prev[:IPA], [])[0] \
                      || segm.prev.phon
    segm[:IPA] = outcomes[segm[:IPA]]
    segm[:palatalized] = false
  end) { |iff| iff[:palatalized] }
end

# k g > k_j g_j
def step_ri7(ary)
  ary.change(%w[k g], palatalized: true) { |iff| !iff[:back] }
end

# k- g- > k g
def step_ri8(ary)
  ary.change(%w[k g], back: false) { |iff| iff[:back] }
end

# Devoice final stops
def step_ri9(ary)
  ary.change(:final, {}, ->(s) { s.devoice! }, &:stop?)
end

# Lose final schwa.
def step_ri10(ary)
  ary.change(/ə/, {}, lambda do |segm|
    prev = segm.prev
    nxt = segm.next
    prev[:final_n] = prev[:IPA] == 'n' # To distinguish from final nasal later
    # prev[:orthography] <<= segm[:orthography] <<= nxt.orth
    prev[:orthography] = "#{prev[:orthography]}#{segm[:orthography]}#{nxt.orth}"

    [nxt, segm].each(&:delete)
  end) do |iff|
    iff.final? || (iff.next =~ 'ʰ' && iff.match_all(:penultimate, :unstressed))
  end
end

# lose /h/
def step_ri11(ary)
  ary.change('h', {}, lambda do |segm|
    nxt = segm.next
    nxt[:orthography] = segm[:orthography] << nxt.orth

    if segm.after?(/\u0303/) # Nasalized /~h/ > /n/
      segm.update(IPA: 'n', orthography: 'n')
      %i[phon orth].each { |s| segm.prev.send(s).chop! }
    else
      segm.delete
    end
  end)
end

# OE AE > O: a:
def step_ri12(ary)
  # TODO: allow 'change' to handle hashes like this directly
  outcomes = { /ɑɛ̯/ => 'a', /ɔɛ̯/ => 'ɔ', /œ̯/ => '' }

  ary.change(outcomes.keys, { long: true }, lambda do |segm|
    outcomes.each_pair { |i, o| segm[:IPA] = segm[:IPA].gsub(i, o) }
  end)
end

# ej > Ej
def step_ri13(ary)
  ary.change('ej', IPA: 'ɛj')
end

# oj Oj OH EH > œj
def step_ri14(ary)
  ary.change(['ɔj', 'oj', /[oɔɛe]ɥ/], IPA: 'œj')
end

# rough, cleanup
def cyrillize(ary)
  cyrl = ary.to_ipa.tr("ɑbvgdɛfʒzeijklmn\u0303ɲɔœøprstθuwɥyoʃəɐaʰː",
                       "абвгдевжзиіјклмннњоөөпрсттууүүѡшъъя’\u0304")

  output = { /н\u0304/ => "\u0304н", /н’/ => '’н', /тш/ => 'ч',
             /дж/ => 'џ', /[ˈʲ]/ => '', /ccç/ => 'ттј',
             /cç/ => 'тј', /ɟɟʝ/ => 'ддј', /ɟʝ/ => 'дј',
             /ʝ/ => 'ж', /ŋ/ => 'нг', /ç/ => 'ш' }

  output.each { |int, out| cyrl = cyrl.gsub int, out }

  # no need for нн' or н' solo
  cyrl.sub!(/н$/, 'н’') if ary[-1][:final_n] && cyrl != 'н' \
    && %W[а е и і ј о ө у ү ѡ ъ я \u0304].include?(cyrl[-2])

  cyrl
end

def neocyrillize(ary)
  cyrl = ary.to_ipa.tr("ɑbvdʒzelmn\u0303ɲɔœprsʰtuyfoʃəøaɐcɟ",
                       'абвджзилмннњоөпрсстуүфѡшыюяятд')

  { /\u0304/ => '', /тш/ => 'ч', /дж/ => 'џ', /θ/ => 'ћ', /gʲ/ => 'г',
    /kʲ/ => 'к', /g/ => 'гъ', /k/ => 'къ', /ç/ => 'с́', /ŋ/ => 'нг',
    /үː/ => 'ӱ', /уː/ => 'у́', /ү/ => 'у', /[jʝ]ɛ/ => 'є', /[jʝ][ei]/ => 'ї',
    /ʝ$/ => 'јъ', 'ʝ' => 'ј', 'ɛ' => 'е', 'i' => 'і',
    /([аиоөуүѡыюєяїеі])j([^аиоөуүѡыюєяїеі])/ => '\1й\2',
    /([аиоөуүѡыюєяїеі])w([^аиоөуүѡыюєяїеі])/ => '\1ў\2',
    'j' => 'ј', 'w' => 'в', /[ˈː]/ => '' }.each { |i, o| cyrl = cyrl.gsub i, o }

  cyrl
end

#############
# i~ o~ y~ > E~ O~ œ~
def step_pi1(ary)
  ary.change(/[ioy]\u0303/, {}, ->(s) { s[:IPA] = s[:IPA].tr('ioy', 'ɛɔœ') })
end

# a a~ > æ æ~
def step_pi2(ary)
  ary.change(/a/, {}, ->(s) { s[:IPA] = s[:IPA].tr('a', 'æ') })
end

# assimilation of /s/
def step_pi3(ary)
  ary.change('s', {}, ->(segm) { PaysanIbran.s_drop!(segm) }) do |iff|
    !iff[:long] && iff.between?(:vocalic, :consonantal)
  end
end

# je wo wø > i u y in closed syllables
def step_pi4(ary)
  ary.change(/\A(j?(e|ẽ)|w?(o|õ|ø|ø̃))\Z/, {}, lambda do |segm|
    rising = segm.rising_diphthong?
    segm.replace!(PaysanIbran.close_diphthong(segm))
    segm.prev.delete unless rising
  end) do |iff|
    iff =~ [:rising_diphthong,
            ->(s) { s.prev =~ %w[j w] && s =~ :starts_with_vocalic }] \
    && iff.before?(consonantal: true, intervocalic: false)
  end
end

# reduce unstressed vowels
def step_pi5(ary)
  PaysanIbran.break_semivowels(ary)
  PaysanIbran.resolve_hiatus(ary)

  ary.change(:unstressed, {}, lambda do |segm|
    PaysanIbran.reduce_unstressed(segm)
  end) { |iff| iff.rising_diphthong? || !iff[:long] }
end

# k_j g_j > tS dZ
def step_pi6(ary)
  ary.change(%w[k g], { palatalized: false }, lambda do |segm|
    case segm[:IPA]
    when 'k'
      segm.replace!(%w[tʃ ch])
    when 'g'
      segm.replace!(%w[dʒ dj])
    end
  end) { |iff| iff[:palatalized] }
end

# k- g- > k g
def step_pi7(ary)
  ary.change({ back: true }, back: false)
end

# OE~ AE~ > O:~ a:~
def step_pi8(ary)
  ary.change(/[ɑɔ]ɛ̯\u0303/, { long: true }, lambda do |segm|
    segm[:IPA] = segm[:IPA].gsub(/ɑɛ̯\u0303/, 'æ')
    segm[:IPA] = segm[:IPA].gsub(/ɔɛ̯\u0303/, 'ɔ')
  end)
end

# OE oj AE > Oj Oj Aj
def step_pi9(ary)
  ary.change(/[ɑɔ]ɛ̯|oj/, {}, lambda do |segm|
    segm[:IPA] = segm[:IPA].gsub(/ɑɛ̯/, 'ɑj')
    segm[:IPA] = segm[:IPA].gsub(/ɔɛ̯/, 'ɔj')
    segm[:IPA] = segm[:IPA].gsub(/oj/, 'ɔj')
    segm[:orthography] = segm[:orthography].gsub(/ói/, 'oi')
  end)
end

# g > x
def step_pi10(ary)
  ary.change('g', IPA: 'x')
  PaysanIbran.orthographic_changes(ary)
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

  if since == "L"
    @steps[0] = deep_dup step_vl0(str)
    @steps[1] = step_vl1(deep_dup(@steps[0]))
    @steps[2] = step_vl2(deep_dup(@steps[1]))
    @steps[3] = step_vl3(deep_dup(@steps[2]))
    @steps[4] = step_vl4(deep_dup(@steps[3]))
    @steps[5] = step_vl5(deep_dup(@steps[4]))
    @steps[6] = step_vl6(deep_dup(@steps[5]))
    @steps[7] = step_vl7(deep_dup(@steps[6]))
    @steps[8] = step_vl8(deep_dup(@steps[7]))
    @steps[9] = step_vl9(deep_dup(@steps[8]))

    @steps[10] = step_oi1(deep_dup(@steps[9]))
    @steps[11] = step_oi2(deep_dup(@steps[10]))
    @steps[12] = step_oi3(deep_dup(@steps[11]))
    @steps[13] = step_oi4(deep_dup(@steps[12]))
    @steps[14] = step_oi5(deep_dup(@steps[13]))
    @steps[15] = step_oi6(deep_dup(@steps[14]))
    @steps[16] = step_oi7(deep_dup(@steps[15]))
    @steps[17] = step_oi8(deep_dup(@steps[16]))
    @steps[18] = step_oi9(deep_dup(@steps[17]))
    @steps[19] = step_oi10(deep_dup(@steps[18]))
    @steps[20] = step_oi11(deep_dup(@steps[19]))
    @steps[21] = step_oi12(deep_dup(@steps[20]))
    @steps[22] = step_oi13(deep_dup(@steps[21]))
    @steps[23] = step_oi14(deep_dup(@steps[22]))
    @steps[24] = step_oi15(deep_dup(@steps[23]))
    @steps[25] = step_oi16(deep_dup(@steps[24]))
    @steps[26] = step_oi17(deep_dup(@steps[25]))
    @steps[27] = step_oi18(deep_dup(@steps[26]))
    @steps[28] = step_oi19(deep_dup(@steps[27]))
    @steps[29] = step_oi20(deep_dup(@steps[28]))
    @steps[30] = step_oi21(deep_dup(@steps[29]))
    @steps[31] = step_oi22(deep_dup(@steps[30]))
    @steps[32] = step_oi23(deep_dup(@steps[31]))
    @steps[33] = step_oi24(deep_dup(@steps[32]))
    @steps[34] = step_oi25(deep_dup(@steps[33]))
    @steps[35] = step_oi26(deep_dup(@steps[34]))
    @steps[36] = step_oi27(deep_dup(@steps[35]))
    @steps[37] = step_oi28(deep_dup(@steps[36]))
    @steps[38] = step_oi29(deep_dup(@steps[37]))
  end

  if ["OLF", "FRO", "L"].include?(since)
    @steps[38] = OldIbran.borrow_old_dutch(str) if since == "OLF"
    @steps[38] = OldFrench.to_dictum(str) if since == "FRO"
    @steps[38].features.merge!(plural: plural)
    
    @steps[39] = step_oix1(deep_dup(@steps[38]))
    @steps[40] = step_oix2(deep_dup(@steps[39]))
    @steps[41] = step_oix3(deep_dup(@steps[40]))
    @steps[42] = step_oix4(deep_dup(@steps[41]))
    @steps[43] = step_oix5(deep_dup(@steps[42]))
    @steps[44] = step_oix6(deep_dup(@steps[43]))
    @steps[45] = step_oix7(deep_dup(@steps[44]))

    @steps[46] = step_ci1(deep_dup(@steps[45]))
    @steps[47] = step_ci2(deep_dup(@steps[46]))
    @steps[48] = step_ci3(deep_dup(@steps[47]))
    @steps[49] = step_ci4(deep_dup(@steps[48]))
    @steps[50] = step_ci5(deep_dup(@steps[49]))
    @steps[51] = step_ci6(deep_dup(@steps[50]))
    @steps[52] = step_ci7(deep_dup(@steps[51]))
    @steps[53] = step_ci8(deep_dup(@steps[52]))
  end

  if ["LL", "OLF", "FRO", "L"].include?(since)
    @steps[53] = LateLatin.to_dictum(str) if since == "LL"

    @roesan_steps[0] = step_ri1(deep_dup(@steps[53]))
    @roesan_steps[1] = step_ri2(deep_dup(@roesan_steps[0]))
    @roesan_steps[2] = step_ri3(deep_dup(@roesan_steps[1]))
    @roesan_steps[3] = step_ri4(deep_dup(@roesan_steps[2]))
    @roesan_steps[4] = step_ri5(deep_dup(@roesan_steps[3]))
    @roesan_steps[5] = step_ri6(deep_dup(@roesan_steps[4]))
    @roesan_steps[6] = step_ri7(deep_dup(@roesan_steps[5]))
    @roesan_steps[7] = step_ri8(deep_dup(@roesan_steps[6]))
    @roesan_steps[8] = step_ri9(deep_dup(@roesan_steps[7]))
    @roesan_steps[9] = step_ri10(deep_dup(@roesan_steps[8]))
    @roesan_steps[10] = step_ri11(deep_dup(@roesan_steps[9]))
    @roesan_steps[11] = step_ri12(deep_dup(@roesan_steps[10]))
    @roesan_steps[12] = step_ri13(deep_dup(@roesan_steps[11]))
    @roesan_steps[13] = step_ri14(deep_dup(@roesan_steps[12]))

    @paysan_steps[0] = step_pi1(deep_dup(@steps[53]))
    @paysan_steps[1] = step_pi2(deep_dup(@paysan_steps[0]))
    @paysan_steps[2] = step_pi3(deep_dup(@paysan_steps[1]))
    @paysan_steps[3] = step_pi4(deep_dup(@paysan_steps[2]))
    @paysan_steps[4] = step_pi5(deep_dup(@paysan_steps[3]))
    @paysan_steps[5] = step_pi6(deep_dup(@paysan_steps[4]))
    @paysan_steps[6] = step_pi7(deep_dup(@paysan_steps[5]))
    @paysan_steps[7] = step_pi8(deep_dup(@paysan_steps[6]))
    @paysan_steps[8] = step_pi9(deep_dup(@paysan_steps[7]))
    @paysan_steps[9] = step_pi10(deep_dup(@paysan_steps[8]))
  end

  [@steps[53], @roesan_steps[-1], @paysan_steps[-1]]
end

# IDEAL TO KEEP:
# 1.  THE CHANGED ORTHOGRAPHY WITH THE CHANGED PRONUNCIATION.           [Pólo => polo]
# 2.  THE CONSERVATIVE ORTHOGRAPHY WITH THE SPELLING PRONUNCIATION.     [Paulo => paulo]
#     THIS LATTER IS NOT TRIVIAL, AS IT MAY NOT MATCH THE CONSERVATIVE PRONUNCIATION.
def interactive_process(steps, first_step)
  steps.each_with_index do |step, i|
    @outcomes.concat(@outcomes.collect.with_index do |prior, j|
      send(step, deep_dup(prior))
    end)

    @outcomes = @outcomes.compact.reverse.uniq { |oc| "|#{oc.join}| /#{oc.to_ipa}/" }.reverse

    if @outcomes.size != @prior_outcome_size
      puts "-----"
      @outcomes.keep_if.with_index do |oc, j|
        if j == @outcomes.size - 1
          true
        else
          puts "#{step} (#{j + 1}/#{@outcomes.size - 1}) - natural outcome |#{@outcomes.last.join}| /#{@outcomes.last.to_ipa}/
          Additional outcomes:
                #{@outcomes[0...-1].collect { |ocx| "|#{ocx.join}| /#{ocx.to_ipa}/" }}"
          puts "Keep |#{oc.join}| /#{oc.to_ipa}/? (Y/n)"
          !(STDIN.gets =~ /^n/i)
        end
      end
    end

    @prior_outcome_size = @outcomes.size

    @steps[i + first_step] = @outcomes.last # for show
  end
end

## TODO: INCREDIBLY INCOMPLETE
def name_transform(str, since = "L", plural = false)
  @steps = []
  @current = []
  @roesan_steps = []
  @paysan_steps = []
  @outcomes = []
  @prior_outcome_size = 1

  if since == "L"
    @steps[0] = deep_dup step_vl0(str)
    steps = %i[step_vl1 step_vl2 step_vl3 step_vl4 step_vl5 step_vl6 step_vl7 step_vl8 step_vl9
               step_oi1 step_oi2 step_oi3 step_oi4 step_oi5 step_oi6 step_oi7 step_oi8 step_oi9 step_oi10
               step_oi11 step_oi12 step_oi13 step_oi14 step_oi15 step_oi16 step_oi17 step_oi18 step_oi19 step_oi20
               step_oi21 step_oi22 step_oi23 step_oi24 step_oi25 step_oi26 step_oi27 step_oi28 step_oi29]
    @outcomes << deep_dup(@steps[0])

    interactive_process(steps, 1)
  end

  if ["OLF", "FRO", "L"].include?(since)
    @outcomes = [@steps[38] = OldIbran.borrow_old_dutch(str)] if since == "OLF"
    @outcomes = [@steps[38] = OldFrench.to_dictum(str)] if since == "FRO"
    @steps[38].features.merge!(plural: plural)
    steps = %i[step_oix1 step_oix2 step_oix3 step_oix4 step_oix5 step_oix6 step_oix7
               step_ci1 step_ci2 step_ci3 step_ci4 step_ci5 step_ci6 step_ci7 step_ci8]

    interactive_process(steps, 39)
  end

  if ["LL", "OLF", "FRO", "L"].include?(since)
    @outcomes = [@steps[53] = LateLatin.to_dictum(str)] if since == "LL"

    @outcomes.each do |oc|
      @roesan_steps[0] = step_ri1(deep_dup(oc))
      @roesan_steps[1] = step_ri2(deep_dup(@roesan_steps[0]))
      @roesan_steps[2] = step_ri3(deep_dup(@roesan_steps[1]))
      @roesan_steps[3] = step_ri4(deep_dup(@roesan_steps[2]))
      @roesan_steps[4] = step_ri5(deep_dup(@roesan_steps[3]))
      @roesan_steps[5] = step_ri6(deep_dup(@roesan_steps[4]))
      @roesan_steps[6] = step_ri7(deep_dup(@roesan_steps[5]))
      @roesan_steps[7] = step_ri8(deep_dup(@roesan_steps[6]))
      @roesan_steps[8] = step_ri9(deep_dup(@roesan_steps[7]))
      @roesan_steps[9] = step_ri10(deep_dup(@roesan_steps[8]))
      @roesan_steps[10] = step_ri11(deep_dup(@roesan_steps[9]))
      @roesan_steps[11] = step_ri12(deep_dup(@roesan_steps[10]))
      @roesan_steps[12] = step_ri13(deep_dup(@roesan_steps[11]))
      @roesan_steps[13] = step_ri14(deep_dup(@roesan_steps[12]))

      @paysan_steps[0] = step_pi1(deep_dup(oc))
      @paysan_steps[1] = step_pi2(deep_dup(@paysan_steps[0]))
      @paysan_steps[2] = step_pi3(deep_dup(@paysan_steps[1]))
      @paysan_steps[3] = step_pi4(deep_dup(@paysan_steps[2]))
      @paysan_steps[4] = step_pi5(deep_dup(@paysan_steps[3]))
      @paysan_steps[5] = step_pi6(deep_dup(@paysan_steps[4]))
      @paysan_steps[6] = step_pi7(deep_dup(@paysan_steps[5]))
      @paysan_steps[7] = step_pi8(deep_dup(@paysan_steps[6]))
      @paysan_steps[8] = step_pi9(deep_dup(@paysan_steps[7]))
      @paysan_steps[9] = step_pi10(deep_dup(@paysan_steps[8]))

      puts "###{ " " << since unless since == "L"} #{caps(str)} > PI #{@paysan_steps[-1].join} [#{@paysan_steps[-1].to_ipa}], RI #{cyrillize(@roesan_steps[-1])} / #{@roesan_steps[-1].join} [#{@roesan_steps[-1].to_ipa}]"
    end
  end

  [@steps[53], @roesan_steps[-1], @paysan_steps[-1]]
end
