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
      next unless segm.match(origin) && yield(segm)

      segm.merge!(target)
      consequence.call(segm) if consequence
    end
  end

  def slice_before
    super.collect do |sl|
      sl.inject(Dictum.new) do |dict, segm|
        dict << segm
      end
    end
  end

  def renumber # lousy hack
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
end

# A phonetic segment and its orthographic representation.
class Segment < Hash
  attr_accessor :dictum, :pos

  def initialize
    @dictum ||= Dictum.new(self)
    @pos ||= 0
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

  def phon
    fetch(:IPA, '')
  end

  def orth
    fetch(:orthography, '')
  end

  def delete
    @dictum.delete_at(@pos)

    @dictum.each_with_index do |segm, idx|
      segm.pos -= 1 if idx > @pos
    end
  end

  def match(segm)
    segm.all? do |k, _|
      self[k] == segm[k]
    end
  end

  def starts_with
    Segment[IPA: phon[0]]
  end

  def ends_with
    Segment[IPA: phon ? phon[-1] : '']
  end

  ### Linguistic functions
  def intervocalic?
    prev.vocalic? && nxt.vocalic?
  end

  def vocalic?
    is_vowel?(phon) || is_diphthong?(phon)
  end

  def initial?
    pos.zero? || nxt.phon == ' '
  end

  def consonantal?
    !vocalic?
  end

  def final?
    pos == @dictum.size - 1 || nxt.phon == ' '
  end

  def sonorant?
    %w(m ɱ ɲ ɳ n ɴ ŋ ʎ r l w j ɥ).include? phon
  end

  def sibilant?
    %w(ɕ ɧ ʑ ʐ ʂ ʒ z ʃ ʃʃ s).include? phon
  end

  def stressed?
    self[:stress]
  end

  def fricative?
    %w(h v f ç ʒ z ʃ ʃʃ s ʰ θ).include? phon
  end

  def stop?
    %w(p b t d k g c).include? phon
  end

  def affricate?
    %w(pf bv pɸ bβ dʑ tɕ cç ɟʝ dʒ dz tʃ ts tθ dð kx gɣ qχ ɢʁ ʡʢ).include? phon
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

  def in_onset?
    next_more_sonorous = ends_with.sonority < nxt.starts_with.sonority
    # We explicitly check for nxt.vocalic because of things like /erje/
    # (where /je/ is a diphthong).
    consonantal? && (initial? || next_more_sonorous || nxt.vocalic?)
  end
end

def ipa(dict)
  dict.join :IPA
end

def takes_stress_mark(segm)
  return true if segm.stressed?

  dictum = segm.dictum
  dictum[segm.pos...dictum.index(&:stressed?)].all?(&:in_onset?)
end

def full_ipa(ary)
  output = ""
  ary.renumber # Ugh

  ary.each_with_index do |segm, idx|
    # stress mark
    if ary.syllable_count > 1
      if takes_stress_mark(segm)
        output << 'ˈ' unless output =~ /ˈ\S*$/ || (segm.phon == " ") # don't add more than one
      end
    end

    output << (segm[:IPA] || '')
    output << "\u0320" if segm[:back]
    output << 'ʲ' if segm[:palatalized]

    # /o:w/, not /ow:/
    if segm[:long]
      output.sub!(/([jwɥ]*)$/, "ː\\1")
    end
  end

  output
end

# Upcase doesn't handle the macrons
def caps(string)
  string.tr("aābcdeéēfghiījklmnoōpqrstuũūvwxyȳz", "AĀBCDEÉĒFGHIĪJKLMNOŌPQRSTUŨŪVWXYȲZ")
end

def is_vowel?(phone)
  case phone
  when String
    phone.count("aeioõuyæɑɐəɛɔøœ") == 1 && phone.count("^aeioõuyæɑɐəɛɔøœ\u0303") == 0
#    %w{a e i o u y æ ɑ ɐ ə ɛ ɔ œ}.include? phone
  when Hash
    is_vowel? phone[:IPA]
  end
end

def is_diphthong?(phone)
  case phone
  when String
    (phone.count("aeiouyæɑɐəɛɔøœ") > 0 && phone.count("jwɥ\u032fː") > 0 && phone.count("^aeiouyæɑɐəɛɔøœjwɥ\u0303\u032fː") == 0) ||
    %w{au ae oe}.include?(phone)
#    %w{au ae oe oj   ɔj  ɛj  ej  jɛ  je  ɔɛ̯  ɑɛ̯  wɛ
#                ojw  ɔjw ɛjw ejw jɛw jew ɔɛ̯w ɑɛ̯w wɛw aw ɑw əw ɛw ew iw ɔw ow uw
#                ojw̃  ɔjw̃ ɛjw̃ ejw̃ jɛw̃ jew̃ ɔɛ̯w̃ ɑɛ̯w̃ wɛw̃ aw̃ ɑw̃ əw̃ ɛw̃ ew̃ iw̃ ɔw̃ ow̃ uw̃
#                ojww ɔjww ɛjww ejww jɛww jeww ɔɛ̯ww ɑɛ̯ww wɛww aww ɑww əww ɛww eww iww ɔww oww uww
#                ojw̃w ɔjw̃w ɛjw̃w ejw̃w jɛw̃w jew̃w ɔɛ̯w̃w ɑɛ̯w̃w wɛw̃w aw̃w ɑw̃w əw̃w ɛw̃w ew̃w iw̃w ɔw̃w ow̃w uw̃w }.include? phone #lol
  when Hash
    is_diphthong? phone[:IPA]
  end
end

# DEPRECATED: TODO: Use Segment.initial?
def is_initial?(pos)
  (pos == 0) || (@current[pos-1] && [' ', nil].include?(@current[pos-1][:IPA]))
end

# DEPRECATED: TODO: use Segment.final?
def is_final?(pos)
  @current[pos+1].nil? || [' ', nil].include?(@current[pos+1][:IPA])
end

def is_short?(segment)
  !segment[:long]
end

def is_dental?(segment)
  %w{dʑ tɕ t n d dʒ dz tʃ ts dz tθ dð θ ð l}.include? segment[:IPA]
end

def is_velar?(segment)
  %w{k g ɡ ɠ ŋ kx gɣ ɣ x ʟ}.include? segment[:IPA]
end

def is_nasal?(segment)
  %w{m ɱ ɲ ɳ n ɴ ŋ}.include? segment[:IPA]
end

def devoice!(segment)
  case segment[:IPA]
  when 'v' then segment[:IPA] = 'f'
  when 'ʒ' then segment[:IPA] = 'ʃ'
  when 'z' then segment[:IPA] = 's'
  when 'b' then segment[:IPA] = 'p'
  when 'd' then segment[:IPA] = 't'
  when 'g' then segment[:IPA] = 'k'
  end
end

def voice!(segment)
  case segment[:IPA]
  when 'f' then segment[:IPA] = 'v'
  when 'ç' then segment[:IPA] = 'ʝ'
  when 'ʃ' then segment[:IPA] = 'ʒ'
  when 'ʃʃ' then segment[:IPA] = 'ʒʒ'
  when 's' then segment[:IPA] = 'z'
  when 'p' then segment[:IPA] = 'b'
  when 't', 'θ' then segment[:IPA] = 'd'
  when 'k' then segment[:IPA] = 'g'
  end
end

def is_voiced?(segment)
  %w{w j m b ɲ ɟʝ n d dʒ g v ʎ ʒ z r l ʝ}.include?(segment[:IPA]) || segment.vocalic?
end

def is_voiceless?(segment)
  !is_voiced?(segment)
end

def is_front_vowel?(segment)
  %w{e i ae y æ ɛ œ ej}.include? segment.phon[0]
end

def is_back_vowel?(segment)
  %w{o u oe ɑ ɔ}.include? segment[:IPA]
end

def is_round?(segment)
  case segment
  when String
    %w{w ɥ ɔ o œ ø u ʊ y ʏ}.include? segment
  when Hash
    is_round? segment[:IPA]
  end
end

# Is labial consonant that turns to /w/ before a consonant per OIx4
def is_labial?(segment)
  %w{p m b v f}.include? segment[:IPA]
end

# use with long vowel test to determine heavy penult
def penult_cluster?(ary)
  vowels, consonants = 0, 0

  ary.reverse_each do |seg|
    vowels += 1 if is_vowel?(seg)
    consonants += 1 if vowels == 1 && !is_vowel?(seg)
  end

  consonants > 1 && vowels > 1
end

def respell_velars(ary)
  ary = ary.each_with_index do |segm, idx|
    if ary[idx+1] && %w{e i}.include?(ary[idx+1][:orthography][0])
      case segm[:IPA]
      when "k"
        segm[:orthography] = "qu"
        # segm[:palatalized] = true
      when "g"
        segm[:orthography] = "gu"
        # segm[:palatalized] = true
      end
    end
  end
end

# use with long vowel test to determine heavy ultima
def ultima_cluster?(ary)
  vowels, consonants = 0, 0

  ary.reverse_each do |seg|
    vowels += 1 if is_vowel?(seg)
    consonants += 1 if vowels == 0 && !is_vowel?(seg) && seg[:IPA]
  end

  consonants > 1
end

# break up input
def step_VL0(str)
  @current = str.scan(/[ao]e|[ae]u|[ey][ij]|qu|[ckprt]h|./i).inject(Dictum.new) do |memo, obj|
    supra = {}
    supra.merge!({ long: true }) if obj.match(/[āēīōūȳ]|ȳ/i)

    phon = case obj
           when /qu/i then "kw"
           when /x/i  then "ks"
           when /z/i  then "dʒ"
           when /ā|ă/i  then "a"
           when /ē|ĕ/i  then "e"
           when /ī|ĭ|ȳ|ȳ|y̆|y/i  then "i"
           when /ō|ŏ/i  then "o"
           when /ū|ŭ/i  then "u"
           when /c/i    then "k"
           when /ph/i   then 'f'
           else obj.dup.downcase
           end

    orth = case obj
           when /k/i then "c"
           when /z/i then "j"
           when /ȳ/i then "ī"
           when /y/i then "i"
           else obj.dup
           end

    memo << Segment[IPA: phon, orthography: orth].merge(supra)
  end

  # /gw/
  @current.change({IPA: "g"}, {IPA: "gw", orthography: "gu"}, ->(segm){segm.next.delete}) do |segm|
    segm.prev.phon == 'n' &&
    segm.next.phon == 'u' &&
    is_vowel?(segm.after_next)
  end

  # /nf/ acts like /mf/
  @current.change({IPA: "n"}, {IPA: "m"}) {|segm| segm.next.phon == "f"}

  # /Vns/ -> /V:s/
  @current = @current.each do |segm|
    if is_vowel?(segm) && segm.next.phon == "n" && segm.after_next.phon == "s"
      segm[:long] = true
      segm[:orthography] = segm[:orthography].tr("aeiouy", "āēīōūȳ")
      segm.next.delete
    end
  end

  # assign stress to each word
  @current.slice_before {|word| word[:IPA] == " " }.each do |word|
    vowels = word.find_all{|segment| segment.vocalic? }

    if word[-1][:orthography] == "!" # Manual override for final stress
      vowels[-1][:stress] = true
      word[-1][:IPA] = nil
      word[-1][:orthography] = nil
    elsif word[-1][:orthography] == "-" #Manual override for unstressed
      word[-1][:IPA] = nil
      word[-1][:orthography] = nil
    else
      modifier = 0
      if word[-1][:orthography] == ">" # stress to the right
        modifier = 1
        word[-1][:IPA] = nil
        word[-1][:orthography] = nil
      elsif word[-1][:orthography] == "<" # stress to the left
        modifier = -1
        word[-1][:IPA] = nil
        word[-1][:orthography] = nil
      end

      case vowels.length
      when 0, 1
        # no stress
      when 2
        vowels[-2][:stress] = true
      else
        (vowels[-2][:long] || penult_cluster?(word)) ? vowels[-2+modifier][:stress] = true : vowels[-3+modifier][:stress] = true
      end
    end
  end

  @current.compact
end

# Final /m/: to /n/ in monosyllables, to 0 elsewhere
def step_VL1(ary)
  phrase = ary.slice_before {|word| word[:IPA] == " " }.collect do |word|
    new_final = word.monosyllable? ? {IPA: "n", orthography: "n"} : {}

    word.change({IPA: 'm'}, new_final, word.monosyllable? ? nil : ->(segm){segm.delete}) do |segm|
      segm.final?
    end
  end

  Dictum.new(phrase.flatten)
end

# /m/ and /N/ before /n/ -> n
def step_VL2(ary)
  @current = ary.each do |segment|
    if %w{g m}.include?(segment[:IPA]) && segment.next.phon == 'n'
      segment[:IPA] = 'n'
      segment[:orthography] = 'n'
    end
  end
end

# drop final /t k d/
def step_VL3(ary)
  @current = ary.each_with_index do |segment, idx|
    if ['t', 'k', 'd'].include?(segment[:IPA]) && segment.final?
      segment[:IPA] = nil
      segment[:orthography] = nil
    end
  end

  @current.compact
end

# drop /h/
def step_VL4(ary)
  @current = ary.each do |segment|
    segment[:IPA].gsub!(/h/, '')
    segment[:orthography].gsub!(/h/, '')
  end

  @current.delete_if {|segment| segment[:IPA] == '' }
end

# { e, i }[-stress][+penult] > j / __V
# Changed to { e, i }[-stress][-initial_syllable] > j / __V
def step_VL5(ary)
  # each word
  ary.slice_before {|word| word[:IPA] == " " }.each do |word|
    # assign stress.
     syllables_from_end = word.syllable_count

    # 5.
    word.each do |segment|
      if syllables_from_end < word.syllable_count && # non-initial syllable
        %w{e i}.include?(segment[:IPA]) &&
        !segment.stressed? &&
        segment.next.vocalic?
          segment[:IPA] = "j"
          segment[:orthography] = "j"
      end

      if segment.vocalic? then syllables_from_end -= 1 end
    end
  end

  @current = ary
end

# V[-stress][+penult] > ∅
def step_VL6(ary)
  posttonic = false

  ary.slice_before {|word| word[:IPA] == " " }.each do |word|

    syllables_from_end = word.syllable_count

    word.each do |segment|
      if segment.vocalic?
         syllables_from_end -= 1
         posttonic = true if segment.stressed?
      end
      if syllables_from_end == 1 && !segment.stressed? && is_vowel?(segment) && posttonic
        if segment.before_prev.stop? && segment.prev.sonorant? && segment.next.consonantal?
          # putridum > puterdum
          segment[:IPA], segment.prev[:IPA] = segment.prev[:IPA], "e"
          segment[:orthography], segment.prev[:orthography] = segment.prev[:orthography], "e"
        else
          segment[:IPA] = nil
          segment[:orthography] = nil
        end

        # t'l > tr
        if segment.prev.phon == 't' && segment.next.phon == "l"
          segment.next[:IPA] = 'r'
          segment.next[:orthography] = 'r'
        end

        # some assimilation
        if is_voiceless?(segment.next) && is_voiced?(segment.prev)
          devoice! segment.prev
        end
      end
    end
  end

  @current = ary

  @current.compact
end

# tk |tc| > tS |ç|
def step_VL7(ary)
  @current = Dictum.new(ary).each do |segment|
    if segment.phon == 't' && segment.next.phon == 'k'
      segment[:IPA] = 'tʃ'
      segment.next[:IPA] = nil
      segment[:orthography] = 'ç'
      segment.next[:orthography] = nil
    end
  end

  @current.compact
end

# stressed vowels
def step_VL8(ary)
  @current = ary.each do |segment|
    if segment.stressed?
      case segment[:orthography]
      when 'a', 'ā'
        segment[:IPA] = 'ɑ'
        segment[:orthography] = 'a'
      when 'ae', 'e'
        segment[:IPA] = 'ɛ'
        segment[:orthography] = 'e'
      when 'ē', 'oe', 'i'
        segment[:IPA] = 'e'
        segment[:orthography] = 'é'
      when 'ī'
        segment[:IPA] = 'i'
        segment[:orthography] = 'i'
      when 'o'
        segment[:IPA] = 'ɔ'
      when 'u', 'ō', 'au'
        segment[:IPA] = 'o'
        segment[:orthography] = 'ó'
      when 'ū'
        segment[:IPA] = 'u'
        segment[:orthography] = 'u'
      end

      segment[:long] = false
    end
  end
end

# unstressed vowels
def step_VL9(ary)
  @current = ary.each do |segment|
    if !segment.stressed?
      case segment[:orthography]
      when 'a', 'ā'
        segment[:IPA] = 'ɑ'
        segment[:orthography] = 'a'
      when 'i', 'ē', 'e', 'oe', 'ae'
        segment[:IPA] = 'ɛ'
        segment[:orthography] = 'e'
      when 'ī'
        segment[:IPA] = 'i'
        segment[:orthography] = 'i'
      when 'u', 'ō', 'o', 'au'
        segment[:IPA] = 'ɔ'
        segment[:orthography] = 'o'
      when 'ū'
        segment[:IPA] = 'u'
        segment[:orthography] = 'u'
      end

      segment[:long] = false
    end
  end
end

def step_OI1(ary)
  # combine words
  @current = ary.each do |segm|
    if segm[:IPA] == ' '
      segm[:IPA] = nil
      segm[:orthography] = nil
    end
  end

  # assign stress when none
  if ary.count(&:stressed?).zero?
    # Monosyllables don't get stress till end of OI.
    # But monosyllables that combined, like 'de post', get final accent.
    ary.select {|segm| is_vowel?(segm) }.last[:stress] = true unless ary.monosyllable?
  end

  @current.compact!

  # { [+stop], [+fric] }[+voice]j > dʒ
  @current = ary.each do |segm|
    if (segm.stop? || segm.fricative?) && is_voiced?(segm) && segm.next.phon == 'j'
      segm[:IPA] = 'dʒ'
      segm.next[:IPA] = nil

      segm[:orthography] = 'j'
      segm.next[:orthography] = nil
    end
  end

  @current.compact
end

# { [+stop], [+fric] }[-voice]j > tʃ
def step_OI2(ary)
  @current = ary.each do |segm|
    if (segm.stop? || segm.fricative?) && !is_voiced?(segm) && segm.next.phon == 'j'
      # ssj -> tS also.  But not stj
      if segm.prev.phon == 's' && segm.phon == 's'
        segm.prev[:IPA] = nil
        segm.prev[:orthography] = nil
      end

      segm[:IPA] = 'tʃ'
      segm.next[:IPA] = nil

      segm[:orthography] = 'ç'
      segm.next[:orthography] = nil
    end
  end

  @current.compact
end

# j > dʒ / { #, V }__V
def step_OI3 ary
  @current = ary.each_with_index do |segm, idx|
    if (segm.initial? || segm.intervocalic?) && segm[:IPA] == 'j'
      segm[:IPA] = 'dʒ'
      segm[:orthography] = 'j'
    end
  end
end

# nn, nj > ɲ
def step_OI4 ary
  @current = ary.each do |segm|
    if segm[:IPA] == 'n' && %w{n j}.include?(segm.next.phon)
      segm[:IPA] = 'ɲ'
      segm.next[:IPA] = nil

      segm[:orthography] = 'nh'
      segm.next[:orthography] = nil
    end
  end

  @current.compact
end

# ll, lj > ʎ
def step_OI5 ary
  @current = ary.each do |segm|
    if segm[:IPA] == 'l' && %w{l j}.include?(segm.next.phon)
      segm[:IPA] = 'ʎ'
      segm.next[:IPA] = nil

      segm[:orthography] = 'll'
      segm.next[:orthography] = nil

      if segm.after_next.phon == 'j' # lli
        segm.after_next[:IPA] = 'ʎ'
        segm.after_next[:orthography] = 'i'
      end
    end
  end

  @current.compact
end

# { d, ɡ } > ∅ / V__V
def step_OI6 ary
  @current = ary.each_with_index do |segm, idx|
    if %w{d g ɡ}.include?(segm[:IPA]) && segm.intervocalic?
      segm[:IPA] = nil
      segm[:orthography] = nil
    end
  end

  @current.delete_if {|segment| segment[:IPA].nil? }
end

# b > v / V__V
def step_OI7 ary
  @current = ary.each_with_index do |segm, idx|
    if segm[:IPA] == "b" && segm.intervocalic?
      segm[:IPA] = "v"
      segm[:orthography] = "v"
    end
  end
end

# { ɑ, ɛ }{ i, ɛ }[-stress] > ɛj
def step_OI8 ary
  @current = ary.each do |segm|
    if %w{ɑ ɛ}.include?(segm[:IPA]) && %w{i ɛ}.include?(segm.next.phon) && !segm.next.stressed?
      segm[:IPA] = 'ɛj'
      segm.next[:IPA] = nil

      segm[:orthography] = 'ei'
      segm.next[:orthography] = nil
    end
  end

  @current.compact
end

# { ɛ, i }[-stress] > j / e__
def step_OI9 ary
  @current = ary.each do |segm|
    if segm[:IPA] == 'e' && %w{ɛ i}.include?(segm.next.phon) && !segm.next.stressed?
      segm[:IPA] = 'ej'
      segm.next[:IPA] = nil

      segm[:orthography] = 'éi'
      segm.next[:orthography] = nil
    end
  end

  @current.compact
end

# { i }[-stress] > j / { ɔ, o }__
def step_OI10 ary
  @current = ary.each do |segm|
    if %w{ɔ o}.include?(segm[:IPA]) && segm.next.phon == "i" && !segm.next.stressed?
      segm[:IPA] << 'j'
      segm.next[:IPA] = nil

      segm[:orthography] << 'i'
      segm.next[:orthography] = nil
    end
  end

  @current.delete_if {|segment| segment[:IPA].nil? }
end

# Velars before front vowels
def step_OI11 ary
  @current = ary.each do |segm|
    if is_front_vowel?(segm.next)
      case segm[:IPA]
      when 'k'
        segm[:IPA] = 'tʃ'
      when 'g'
        segm[:IPA] = 'dʒ'
      when 'kw'
        segm[:IPA] = 'k'
        segm[:palatalized] = true
      when 'gw'
        segm[:IPA] = 'g'
        segm[:palatalized] = true
      end
    end
  end
end

# Velars before back A
def step_OI12 ary
  @current = ary.each do |segm|
    if segm.next.phon == 'ɑ'
      case segm[:IPA]
      when 'k'
        segm[:palatalized] = true
      when 'g'
        segm[:palatalized] = true
      when 'kw'
        segm[:IPA] = 'k'
      when 'gw'
        segm[:IPA] = 'g'
      end
    end
  end
end

# Labiovelars before back vowels
def step_OI13 ary
  @current = ary.each do |segm|
    if is_back_vowel?(segm.next)
      case segm[:IPA]
      when 'kw'
        segm[:IPA] = 'k'
        segm[:back] = true
      when 'gw'
        segm[:IPA] = 'g'
        segm[:back] = true
      end
    end
  end
end

# Intervocalic consonants
def step_OI14 ary
  @current = ary.each_with_index do |segm, idx|
    if ary[idx+1] && segm.intervocalic?
      case segm[:IPA]
      when 'p'
        segm[:IPA] = 'b'
        segm[:orthography] = 'b'
      when 'f'
        segm[:IPA] = 'v'
        segm[:orthography] = 'v'
      when 'l'
        if segm.after_next.phon == 't' && segm.after_next.intervocalic?
          segm[:IPA] = 'd'
          segm[:orthography] = 'd'
        end
      when 't'
        if segm.before_prev.phon == 'l' && segm.before_prev.intervocalic? && segm.before_prev[:was_t]
          segm[:IPA] = 'd'
          segm[:orthography] = 'd'
        else
          segm[:IPA] = 'l'
          segm[:orthography] = 'l'
          segm[:was_t] = true
        end
      when 's'
        segm[:IPA] = 'z'
      when 'k'
        segm[:IPA] = 'g'
        segm[:back] ? segm[:orthography] = 'gu' : segm[:orthography] = 'g'
      end
    end
  end
end

# stops before liquids
def step_OI15 ary
  @current = ary.each_with_index do |segm, idx|
    if %w{r l}.include?(segm.next.phon) && idx > 0 && is_vowel?(segm.prev)
      case segm[:IPA]
      when 'p'
        segm[:IPA] = 'b'
        segm[:orthography] = 'b'
      when 't'
        segm[:IPA] = 'd'
        segm[:orthography] = 'd'
      when 'k'
        segm[:IPA] = 'g'
        segm[:orthography] = 'g'
      end
    end
  end
end

# f before liquids
def step_OI16 ary
  @current = ary.each do |segm|
    if segm[:IPA] == 'f' && %w{r l}.include?(segm.next.phon)
      segm[:IPA] = 'v'
      segm[:orthography] = 'v'
    end
  end
end

# degemination
def step_OI17 ary
  @current = ary.each do |segm|
    if segm.next.phon == segm[:IPA]
      case segm[:IPA]
      when 'p', 't', 'k', 'r'
        segm.next[:IPA] = nil
        segm.next[:orthography] = nil
        segm[:palatalized] = segm.next[:palatalized]
      when 's'
        segm.next[:IPA] = nil
        segm.next[:orthography] = nil
        segm[:orthography] = 'ss'
      end
    end
  end

  @current.compact
end

# Clusters
def step_OI18 ary
  @current = ary.each do |segm|
    if is_vowel?(segm) && segm.stressed? && # stressed vowel
        %w{k g l}.include?(segm.next.phon) &&  # next segment is c g l
        # next is L or dental stop or nasal
        ((segm.after_next.phon == 'l') ||
          ((segm.after_next.stop? || segm.after_next.affricate?) && (is_dental?(segm.after_next))) ||
          is_nasal?(segm.after_next)) &&
        !(segm.next.phon == 'l' && segm.after_next.phon == 'l')  # next two are not both L
      case segm[:IPA]
      when 'a', 'ɑ'
        segm[:IPA] = 'ɑɛ̯'
        segm[:orthography] = 'ae'
      when 'e', 'ɛ'
        segm[:IPA] = 'ɛj'
        segm[:orthography] = 'ei'
      when 'i'
        segm[:IPA] = 'ej'
        segm[:orthography] = 'éi'
      when 'o', 'ɔ'
        segm[:IPA] = 'ɔɛ̯'
        segm[:orthography] = 'oe'
      when 'u'
        segm[:IPA] = 'oj'
        segm[:orthography] = 'ói'
      end

      segm.next[:IPA] = nil
      segm.next[:orthography] = nil
    end
  end

  @current.compact
end

# Clusters pt 2 (in two parts)
def step_OI19 ary
  # 19: stressed vowels
  @current = ary.each do |segm|
    if is_vowel?(segm) && segm.stressed? && # stressed vowel with two subsequent segments
      # x or dental/velar + sibilant
      (segm.next.phon == 'ks' ||
        ((is_dental?(segm.next) || is_velar?(segm.next)) && segm.after_next.sibilant?) ||
        segm.next.affricate?)

      case segm[:IPA]
      when 'a', 'ɑ'
        segm[:IPA] = 'ɑɛ̯'
        segm[:orthography] = 'ae'
      when 'e', 'ɛ'
        segm[:IPA] = 'ɛj'
        segm[:orthography] = 'ei'
      when 'o', 'ɔ'
        segm[:IPA] = 'ɔɛ̯'
        segm[:orthography] = 'oe'
      end

      if %w{i u}.include?(segm[:IPA])
        case segm.next.phon
        when 'ks'
          segm.next[:IPA] = 'ss'
          segm.next[:orthography] = is_vowel?(segm.after_next) ? 'ss' : 's'
        when 'dʒ', 'tʃ'
          segm.next[:IPA] = "#{segm.next.phon[1]}#{segm.next.phon[1]}"
          segm.next[:orthography] = "s#{segm.next.orth}"
        else
          segm.next[:IPA] = segm.after_next.phon
          segm.next[:orthography] = 's'
        end
      else
        case segm.next.phon
        when 'ks'
          segm.next[:IPA] = 's'
          segm.next[:orthography] = is_vowel?(segm.after_next) ? 'ss' : 's'
        when 'dʒ', 'tʃ'
          segm.next[:IPA] = "#{segm.next.phon[1]}"
          #ary[idx+1][:orthography] = "s#{ary[idx+1][:orthography]}"
        else
          segm.next[:IPA] = nil
          segm.next[:orthography] = nil
        end
      end
    end
  end

  # 19b: unstressed vowels
  @current = ary.each_with_index do |segm, idx|
    if idx > 0 && is_vowel?(segm.prev) && !segm.stressed?
      if is_velar?(segm) && (is_dental?(segm.next) || is_nasal?(segm.next))
        segm[:IPA] = segm.next.final? ? nil : segm.next.phon[0]
        segm[:orthography] = segm.next.final? ? nil : segm.next.orth[0]
      elsif (is_dental?(segm) || is_velar?(segm)) && segm.next.sibilant?
        segm[:IPA] = segm.next.final? ? nil : segm.next.phon[0]
        segm[:orthography] = segm.next.final? ? nil : 's'
      elsif segm[:IPA] == 'ks'
        segm[:IPA] = 'ss'
        segm[:orthography] = is_vowel?(segm.next) ? 'ss' : 's'
      elsif segm.affricate?
        segm[:IPA] = "#{segm[:IPA][1] * 2}"
        segm[:orthography] = "s#{segm[:orthography]}"
      end
    end
  end

  @current.delete_if {|segment| segment[:IPA].nil? }
end

# vowel fronting
def step_OI20 ary
  @current = ary.each do |segm|
    if is_vowel?(segm) && !segm.stressed? && !is_vowel?(segm.next) && segm.next.phon.size == 1 && is_front_vowel?(segm.after_next)
      case segm[:IPA]
      when 'ɔ'
        segm[:IPA] = 'a'
        segm[:orthography] = 'à'
      when 'u'
        segm[:IPA] = 'œ'
        segm[:orthography] = 'eu'
        if %w{k g}.include?(segm.prev.phon)
          case segm.prev.phon
          when 'k'
            segm.prev[:orthography] = 'qu'
          when 'g'
            segm.prev[:orthography] = 'gu'
          end
        end
      end
    end
  end
end

# vowel fronting: palatal consonants
def step_OI21 ary
  @current = ary.each do |segm|
    if is_vowel?(segm) && %w{ɲ ʎ}.include?(segm.next.phon)
      case segm[:IPA]
      when 'ɑ'
        segm[:IPA] = 'a'
        segm[:orthography] = 'à'
      when 'ɛ', 'e'
        segm[:IPA] = 'i'
        segm[:orthography] = 'i'
      when 'ɔ', 'o'
        segm[:IPA] = 'œ'
        segm[:orthography] = 'eu'
        if %w{k g}.include?(segm.prev.phon)
          case segm.prev.phon
          when 'k'
            segm.prev[:orthography] = 'qu'
          when 'g'
            segm.prev[:orthography] = 'gu'
          end
        end
      end
    end
  end
end

# vowel fronting: umlaut
def step_OI22 ary
  @current = ary.each do |segm|
    if is_vowel?(segm) && segm.next.phon == 'r' && segm.after_next.phon == 'j'
      case segm[:IPA]
      when 'ɑ', 'a'
        segm[:IPA] = 'a'
        segm[:long] = true
        segm[:orthography] = 'ài'
        segm.after_next[:IPA] = nil
        segm.after_next[:orthography] = nil
      when 'ɛ', 'e'
        segm[:IPA] = 'ɛ'
        segm[:long] = true
        segm[:orthography] = 'ei'
        segm.after_next[:IPA] = nil
        segm.after_next[:orthography] = nil
      when 'ɔ', 'o'
        segm[:IPA] = 'œ'
        segm[:long] = true
        segm[:orthography] = 'eu'
        segm.after_next[:IPA] = nil
        segm.after_next[:orthography] = nil
        if %w{k g}.include?(segm.prev.phon)
          case segm.prev.phon
          when 'k'
            segm.prev[:orthography] = 'qu'
          when 'g'
            segm.prev[:orthography] = 'gu'
          end
        end
      end
    end
  end

  @current.delete_if {|segment| segment[:IPA].nil? }
end

# vowel fronting: r
def step_OI23 ary
  @current = ary.each_with_index do |segm, idx|
    if idx > 0 && segm.prev.phon == 'r' && segm[:IPA] == 'ɑ' &&
      !(segm.next.phon == 'r' || is_velar?(segm.next))
        segm[:IPA] = 'a'
        segm[:orthography] = 'à'
    end
  end
end

# diphthongize
def step_OI24 ary
  @current = ary.each_with_index do |segm, idx|
    if segm.stressed? && !segm[:long]
      case segm[:IPA]
      when 'ɛ', 'e'
        unless idx > 0 && (segm.prev.sibilant? || segm.prev.affricate? || segm.prev[:palatalized] || %w{ʎ j i}.include?(segm.prev.phon[-1]))
          segm[:IPA] = "j#{segm[:IPA]}"
          segm[:orthography] = "i#{segm[:orthography]}"
        end
      when 'ɔ'
        if segm.next.sonorant? && (segm.next.final? || !is_vowel?(segm.after_next))
          segm[:IPA] = 'wɛ'
          segm[:orthography] = 'ue'
        else
          segm[:IPA] = 'ɔj'
          segm[:orthography] = 'oi'
        end
      when 'o'
        if segm.final? || # Final
            segm.next.vocalic? || # Before a vowel
            (!is_vowel?(segm.next) && is_vowel?(segm.after_next)) || # Before single cons
            (segm.next.phon == 's' && !is_vowel?(segm.after_next) && is_vowel?(segm.next.after_next))
          segm[:IPA] = 'u'
          segm[:long] = true
          segm.prev[:orthography][-1] = '' if segm.prev[:orthography][-1] == "u"   # no quuo
          segm.prev[:orthography][-1] = 'c' if segm.prev[:orthography][-1] == "q"  # no quo /ku/
          segm[:orthography] = 'uo'
        end
      end
    end
  end
end

# f > h before round vowels
def step_OI25 ary
  @current = ary.each do |segm|
    if segm[:IPA] == 'f' && is_round?(segm.next)
      segm[:IPA] = "h"
      segm[:orthography] = "h"
    end
  end
end

# drop unstressed final vowels except /A/
def step_OI26 ary
  @current = ary.each_with_index do |segm, idx|
    if !segm.stressed? && is_vowel?(segm) && !(segm[:IPA] == 'ɑ') &&  # unstressed, not A
        (is_final?(idx) || (segm.next.phon == 's' && segm.next.final?)) && # is final or behind final S
        (idx > 0) # not if it's also the initial vowel

      # assume sonority hierarchy will be C?V
      stop_cluster = (segm.before_prev.stop? || (segm.before_prev.fricative? && segm.before_prev.phon != "s") || segm.before_prev.affricate? ||
        (is_nasal?(segm.before_prev) && !(segm.prev.stop? || segm.prev.affricate?) ) ||
        segm.before_prev.phon == "s" && (segm.prev.sonorant? || segm.prev.affricate?)) ||
        (segm.next.phon == "s")

      # So precedent shows that /SSV/ reduces to /SS@/, not /SS/.  /ZZ/ for symmetry.
      fricative_cluster = %w{ʃʃ ʒʒ}.include?(segm.prev.phon)

      if (segm.prev.consonantal? && segm.before_prev.consonantal? &&
          stop_cluster) &&
          !segm.prev.ends_with.vocalic? || # drop a vowel after a vowel
          ary.monosyllable? || # don't drop our only vowel
          fricative_cluster ||
          (segm.next.phon == 's' && segm.prev.sibilant?)
        segm[:IPA] = "ə"
        segm[:orthography] = "e"

        if %w{ʃ ʒ g k}.include?(segm.prev.phon[-1])
          case segm.prev.phon[-1]
          when 'ʃ'
            segm.prev[:orthography][-1] = 'c'
          when 'ʒ'
            segm.prev[:orthography][-1] = 'j'
          when 'g' # gu
            segm.prev[:orthography] = 'gu'
          when 'k' # qu
            segm.prev[:orthography] = 'qu'
          end
        end
      else
        segm[:IPA] = nil
        segm[:orthography] = nil

        if %w{ʃ ʒ g k}.include?(segm.prev.phon[-1])
          case segm.prev.phon[-1]
          when 'ʃ'
            segm.prev[:orthography][-1] = 'ç'
          when 'ʒ'
            segm.prev[:orthography][-1] = 'z'
          when 'g' # gu
            segm.prev[:orthography] = 'g'
          when 'k' # qu
            segm.prev[:orthography] = 'c'
          end
        end
      end
    end
  end

  @current.compact
end

# A > @
def step_OI27 ary
  @current = ary.each_with_index do |segm, idx|
    if segm[:IPA] == 'ɑ' && !segm.stressed? && segm.final? && !ary.monosyllable?
      segm[:IPA] = 'ə'
      segm[:orthography] = 'e'

      if %w{ʃ ʒ g k}.include?(segm.prev.phon[-1])
        case segm.prev[:IPA][-1]
#        when 'ʃ', 'ç'
#          ary[idx-1][:orthography][-1] = 'c'
#        when 'ʒ'
#          ary[idx-1][:orthography][-1] = 'c'
        when 'g' # gu
          segm.prev[:orthography] = 'gu'
        when 'k' # qu
          segm.prev[:orthography] = 'qu'
        end
      end
    end
  end
end

# A > @ (unless it's the only syllable)
def step_OI28 ary
  syllable = 0

  @current = ary.each do |segm|
    if segm.vocalic?
      syllable +=1

      if syllable > 1 && !segm.stressed? && segm[:IPA] == 'ɑ'
        segm[:IPA] = 'ə'
        segm[:orthography] = 'e'
      end
    end
  end
end

# reduce unstressed medial syllables
def step_OI29 ary
  syllable = 0

  @current = ary.each do |segm|
    if segm.vocalic?
      syllable += 1

      # if is not initial, and is not final, and is unstressed
      if syllable > 1 && syllable < ary.syllable_count && !segm.stressed? &&
        segm[:IPA] != 'ə' # these come from #28 which we're working in parallel with
        # one consonant or less to either side
        if (segm.prev.vocalic? ||
            (segm.prev.consonantal? && segm.before_prev.vocalic?)) &&
            ((segm.next.vocalic?) ||
            (segm.next.consonantal? && segm.after_next.vocalic?)) &&
            (segm.next.vocalic? || segm.next.phon.nil? ? 0 : segm.next.phon.length) + (segm.prev.vocalic? || segm.prev.phon.nil? ? 0 : segm.prev.phon.length) <= 2 # Longs count to this total too.
          segm[:IPA] = nil
          segm[:orthography] = nil


          if %w{ʃ ʒ ç k g}.include?(segm.prev.phon[-1]) &&
              segm.next.phon && !%w{i y e é}.include?(segm.next.orth[0])
            case segm.prev.phon[-1]
            when 'ʃ', 'ç'
              segm.prev[:orthography][-1] = 'ç'
            when 'ʒ'
              segm.prev[:orthography][-1] = 'ç'
            when 'g' # gu
              segm.prev[:orthography] = 'g'
            when 'k' # qu
              segm.prev[:orthography] = 'c'
            end
          end
        else
          segm[:IPA] = 'ə'
          segm[:orthography] = 'e'

          if %w{ʃ ʒ ç k g}.include?(segm.prev.phon[-1]) &&
              segm.next.orth && !%w{a à o ó u}.include?(segm.next.orth[0])
            case segm.prev.phon[-1]
            when 'ʃ', 'ç'
              segm.prev[:orthography][-1] = 'c'
            when 'ʒ'
              segm.prev[:orthography][-1] = 'c'
            when 'g' # gu
              segm.prev[:orthography] = 'gu'
            when 'k' # qu
              segm.prev[:orthography] = 'qu'
            end
          end
        end
      end
    end
  end

  @current.compact
=begin
  @current = ary.each_with_index do |segm, idx|
    if %w{ʃ ʒ ç k g}.include?(segm[:IPA][-1]) &&
        ary[idx+1] && %w{a à o ó u}.include?(ary[idx+1][:orthography][0])
      case segm[:IPA][-1]
      when 'ʃ', 'ç'
        segm[:orthography][-1] = 'ç'
      when 'ʒ'
        segm[:orthography][-1] = 'ç'
      when 'g' # gu
        segm[:orthography] = 'g'
      when 'k' # qu
        segm[:orthography] = 'c'
      end
    end

    if %w{ʃ ʒ ç k g}.include?(segm[:IPA][-1]) &&
        ary[idx+1] && !%w{a à o ó u}.include?(ary[idx+1][:orthography][0])
      case segm[:IPA][-1]
      when 'ʃ', 'ç'
        segm[:orthography][-1] = 'c'
      when 'ʒ'
        segm[:orthography][-1] = 'c'
      when 'g' # gu
        segm[:orthography] = 'gu'
      when 'k' # qu
        segm[:orthography] = 'qu'
      end
    end
  end
=end
end

# plural /Os As/ to /@s/
def step_OIx1 ary
  if @plural
    ary << (Segment[IPA: 'ə', orthography: 'e']) unless ary[-1][:IPA][-1] == 'ə'
    ary << (Segment[IPA: 's', orthography: 's'])
  end

  @current = ary # This is not something we would feed in here without marking it's plural or a noun to be declined.
end

# loss of initial unstressed /E/ and /i/
def step_OIx2 ary
  # Initial letter is E or i && is unstressed && is not the only syllable && sonority
  if %w{ɛ i}.include?(ary.first[:IPA]) && !ary.first.stressed? && !ary.monosyllable?
    if !(ary[1] && ary[2] && ary[1].consonantal? && !(%w{s ss}.include?(ary[1][:IPA])) && (ary[2].stop? || is_nasal?(ary[2]) || ary[2].fricative? || ary[2].affricate?))
      ary.first[:IPA] = nil
      ary.first[:orthography] = nil

      ary[1][:IPA] = 's' if ary[1] && ary[1][:IPA] == 'ss'
      ary[1][:orthography] = 's' if ary[1] && ary[1][:orthography] == 'ss'
    else
      ary.first[:IPA] = 'ə'
      ary.first[:orthography] = 'e'
    end
  end

  @current = ary

  @current.delete_if {|segment| segment[:IPA].nil? }
end

# /m/ > /w~/ before consonants/finally
def step_OIx3 ary
  @current = ary.each_with_index do |segm, idx|
    if segm.vocalic? && segm.next.phon == 'm' && # Tried assimilating /n/ to labial, don't like.
        (segm.after_next.starts_with.consonantal? || segm.next.final?)

        (is_diphthong?(segm) && segm[:orthography][-1] == 'i') ? segm[:orthography][-1] = "yũ" : segm[:orthography] << 'ũ'
        segm[:IPA] << 'w̃'
#        segm[:orthography] << 'ũ'
        segm.next[:IPA] = nil
        segm.next[:orthography] = nil
      elsif segm.vocalic? &&  # VRLC, VRL# > VwRC, VwR#
            segm.next.sonorant? &&
            segm.after_next.phon == 'm' &&
            (segm.next.after_next.starts_with.consonantal? || segm.after_next.final?)
        ary[idx+1], ary[idx+2] = ary[idx+2], ary[idx+1]

        (is_diphthong?(segm) && segm[:orthography][-1] == 'i') ? segm[:orthography][-1] = "yũ" : segm[:orthography] << 'ũ'
        segm[:IPA] << 'w̃'
        #segm[:orthography] << 'ũ'
        segm.next[:IPA] = nil
        segm.next[:orthography] = nil
    end
  end

  @current.delete_if {|segment| segment[:IPA].nil? }
end

# labials & L > /w/ before consonants/finally
def step_OIx4 ary
  @current = ary.each_with_index do |segm, idx|
    if segm.vocalic? &&
        (segm.next.phon == 'l' || is_labial?(segm.next)) &&
        (segm.after_next.starts_with.consonantal? || segm.next.final?)

      (is_diphthong?(segm) && segm[:orthography][-1] == 'i') ? segm[:orthography][-1] = "yu" : segm[:orthography] << 'u'
      segm[:IPA] << 'w'
      segm.next[:IPA] = nil
      segm.next[:orthography] = nil
    elsif segm.vocalic? &&  # VRLC, VRL# > VwRC, VwR#
          segm.next.sonorant? &&
          (segm.after_next.phon == 'l' || is_labial?(segm.after_next)) &&
          (segm.next.after_next.consonantal? || segm.after_next.final?)
      ary[idx+1], ary[idx+2] = ary[idx+2], ary[idx+1]

      (is_diphthong?(segm) && segm[:orthography][-1] == 'i') ? segm[:orthography][-1] = "yu" : segm[:orthography] << 'u'
      segm[:IPA] << 'w'
      segm.next[:IPA] = nil
      segm.next[:orthography] = nil
    end
  end

  @current.delete_if {|segment| segment[:IPA].nil? }
end

# resolution of diphthongs in /a A @ V/
def step_OIx5 ary
  @current = ary.each do |segm|
    if segm.vocalic? && segm[:IPA][-1] == 'w' && %w{a ɑ ə}.include?(segm[:IPA][-2])
        segm[:IPA][-2..-1] = 'o'
        segm[:long] = true
    end

    # if the diphthong ends with combining tilde
    if segm.vocalic? && segm[:IPA][-1] == "\u0303" && %w{a ɑ ə}.include?(segm[:IPA][-3])
        segm[:IPA][-3..-1] = 'õ'
        segm[:long] = true
    end
  end
end

# resolution of diphthongs in /E e i/
def step_OIx6 ary
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
def step_OIx7 ary
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
  @current = ary.each_with_index do |segm, idx|
    if segm.vocalic? && !%w{j w ɥ œ̯}.include?(segm[:IPA][-1]) &&
        ary[idx+1] && %w{m n ŋ}.include?(segm.next.phon) &&
        (segm.after_next.phon && segm.after_next.starts_with.consonantal? || is_final?(idx+1))

      segm[:IPA] << "\u0303"
      segm[:orthography] << case #'n'#ary[idx+1][:orthography]
                            when segm.next.final? then segm.next.orth
                            when is_labial?(segm.after_next) then 'm'
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
  ary.reverse!

  @current = ary.each_with_index do |segm, idx|
    if segm.fricative?
      case
      when is_initial?(idx) #reverse final
        devoice!(segm)
      when ary[idx-1] && is_voiceless?(ary[idx-1])
        devoice!(segm)
      when ary[idx-1] && is_voiced?(ary[idx-1])
        voice!(segm)

        segm[:orthography] = "d" if segm[:orthography] == "th"
      end
    end
  end

  @current = ary.reverse!
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
    if segm.phon[0] == 'i' && is_vowel?(segm.prev.phon[-1])
      segm[:IPA][0] = "ji"
    end
  end

  # initial |i, u| or in a new syllable after a (non-diphthong) vowel become |y, w|
  @current = ary.each_with_index do |segm, idx|
    if segm[:orthography][0] == "i" &&
      ((idx == 0 && is_diphthong?(segm)) || is_vowel?(segm.prev))
      #  && ((is_vowel?(segm[:IPA][1]) && segm[:orthography].length > 1) || (segm[:IPA] == "j" && ary[idx+1] && is_vowel?(ary[idx+1][:IPA][0])))
      segm[:orthography][0] = "y"
    end
  end

  @current = ary.each_with_index do |segm, idx|
    if segm[:orthography][0] == "u" && segm[:orthography][0..1] != "uo" && # don't do 'uo'/ů
      ((idx == 0 && is_diphthong?(segm)) ||
      (idx > 0 && is_vowel?(segm.prev)))
      # (idx == 0 || (ary[idx-1] && is_vowel?(ary[idx-1])))
      # && (is_vowel?(segm[:IPA][1]) || (segm[:IPA] == "w" && ary[idx+1] && is_vowel?(ary[idx+1][:IPA][0])))
      segm[:orthography][0] = "w"
    end
  end

end

#############
# õ ã > u~ 6~
def step_RI1 ary
  @current = ary.each do |segm|
    segm[:IPA].gsub!(/o\u0303/, "u\u0303")
    segm[:IPA].gsub!(/a\u0303/, "ɐ\u0303")
  end
end

# syll-initial /j/
def step_RI2 ary
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
      (is_vowel?(segm[:IPA][1]) ||   # front of diphthong
      (!segm[:IPA][1] && is_vowel?(segm.next.phon[0]))) && # isolated segment
      !(idx > 0 && !(is_dental?(segm.prev) || (segm.prev.phon == 'r' && segm.before_prev.vocalic?) || segm.prev.vocalic?)) &&
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
      segm[:IPA][-2] && is_vowel?(segm[:IPA][-1]) &&   # end of diphthong
      (ary[idx+1] && is_vowel?(ary[idx+1][:IPA][0]))
      # segm[:IPA][0] = 'ʝ'
      ary.insert(idx+1, Segment[IPA: 'ʝ', orthography: ''])
      segm[:IPA][-1] = ''
    end
  end

  @current = ary.delete_if {|segment| segment[:IPA] == '' }
end

# assimilation of /s/
def step_RI3 ary
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
def step_RI4 ary
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
def step_RI5 ary
  @current = ary.each do |segm|
    if segm[:IPA] == "w" && is_round?(segm.next.phon[0])
      segm.next[:orthography] = segm[:orthography] << segm.next.orth

      segm[:IPA] = nil
      segm[:orthography] = nil
    elsif segm[:IPA][-1] == 'w' && is_round?(segm.next.phon[0])
      segm[:IPA][-1] = ''
    elsif segm[:IPA][0] == 'w' && segm[:IPA][1] && is_round?(segm[:IPA][1])
      segm[:IPA][0] = ''
    end
  end
  @current.compact
end

# k_j g_j > tS dZ
def step_RI6 ary
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
def step_RI7 ary
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
def step_RI8 ary
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
def step_RI9 ary
  devoice!(ary.last) if ary.last.stop?

  @current = ary
end

# lose final schwa
def step_RI10 ary
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
def step_RI11 ary
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
def step_RI12 ary
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
def step_RI13 ary
  @current = ary.each do |segm, idx|
    if segm[:IPA].include?('ej')
      segm[:IPA].gsub!(/ej/, 'ɛj')
    end
  end
end

# oj Oj OH EH > œj
def step_RI14 ary
  @current = ary.each do |segm|
    if segm[:IPA].include?('ɔj') || segm[:IPA].include?('oj')
      segm[:IPA].gsub!(/[oɔ]j/, 'œj')
    end

    segm[:IPA].gsub!(/[oɔɛe]ɥ/, 'œj')
  end
end

# rough, cleanup
def cyrillize ary
  cyrl = full_ipa(ary).tr("ɑbvgdɛfʒzeijklmn\u0303ɲɔœøprstuwɥyoʃəɐaʰː", "абвгдевжзиіјклмннњоөөпрстууүүѡшъъя’\u0304")
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
  cyrl = full_ipa(ary).tr("ɑbvdʒzelmn\u0303ɲɔœprsʰtuyfoʃəøaɐ", "абвджзилмннњоөпрсстуүфѡшыюяя")
  cyrl.gsub!(/\u0304/, '')
  cyrl.gsub!(/тш/, "ч")
  cyrl.gsub!(/дж/, "џ")
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

#############
# i~ o~ y~ > E~ O~ œ~
def step_PI1 ary
  @current = ary.each do |segm|
    segm[:IPA].gsub!(/i\u0303/, "ɛ\u0303")
    segm[:IPA].gsub!(/o\u0303/, "ɔ\u0303")
    segm[:IPA].gsub!(/y\u0303/, "œ\u0303")
  end
end

# a a~ > æ æ~
def step_PI2 ary
  @current = ary.each do |segm|
    segm[:IPA].gsub!(/a/, "æ")
  end
end

# assimilation of /s/
def step_PI3 ary
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
        else
          segm.prev[:orthography] << "\u0302"
        end
    end
  end

  @current = ary.compact
end

# je wo wø > i u y in closed syllables
def step_PI4 ary
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
def step_PI5 ary
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
        segm[:long] = true if segm[:IPA][-1] == "ɥ" || segm[:IPA][-2..-1] == "œ̯" || (ary[idx+1] && is_vowel?(segm.next) && !segm.next.stressed?)

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
          vowel_pos = is_vowel?(segm[:IPA][0]) ? 0 : 1
          segm[:IPA][vowel_pos] = 'ə'
          if posttonic && segm[:orthography] != 'ă'
            segm[:orthography][vowel_pos] = (any_breve ? 'a' : 'ă')
            segm[:orthography].gsub!(/ă\u0302/, "ă")  # no ă̂
            any_breve = true
          end

          if %w{ʃ ʒ ç k g}.include?(segm.prev.phon[-1]) &&
              %w{a à o ó u ă}.include?(segm[:orthography][0]) &&
              !%w{i j}.include?(segm.prev.orth[-1]) # LL |tiV|; pluvia > plusja
            case segm.prev.phon[-1]
            when 'ʃ', 'ç'
              segm.prev.orth[-1] = 'ç'
            when 'ʒ'
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
def step_PI6 ary
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
def step_PI7 ary
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
def step_PI8 ary
  @current = ary.each do |segm|
    if segm[:IPA].include?("ɑɛ̯\u0303") || segm[:IPA].include?("ɔɛ̯\u0303")
      segm[:IPA].gsub!(/ɑɛ̯\u0303/, 'æ')
      segm[:IPA].gsub!(/ɔɛ̯\u0303/, 'ɔ')

      segm[:long] = true
    end
  end
end

# OE oj AE > Oj Oj Aj
def step_PI9 ary
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
def step_PI10 ary
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
    if is_front_vowel?(segm.next)
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
      segm[:IPA] = is_voiced?(segm.next) ? 'g' : 'k'
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
      if !segm[:long] && !is_diphthong?(segm) && segm[:IPA] != 'ə'
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

        if segm.prev && %w{e i é}.include?(@current[idx][:orthography])
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

  @current
end

# INCOMPLETE
def convert_LL str
  @current = str.scan(/[aeé]u|i?.ũ|iéu?|[aoi]e|[ey][ij]|qu|[ckprtg]h|ss|./i).inject(Dictum.new) do |memo, obj|
    supra = {}
    supra.merge!({ long: true }) if obj.match(/aũ|éũ|eũ|éu|eu|iũ/i)
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
           when /th/      then 'θ'
          #when /ng/i     then 'ng'
           when /j/       then 'ʝ'
           else obj.dup.downcase
           end

    orth = case obj
           when /k/i  then "c"
           when /ī/i  then "i"
           when /y/i  then "i"
           when /ph/i then 'f'
           else obj.dup
           end

    memo << Segment[IPA: phon, orthography: orth].merge(supra)
  end

  @current = @current.each_with_index do |segment, idx|
    # /gw/
    if segment[:IPA] == 'g' &&
      segment.next.phon == 'u' &&
      is_vowel?(segment.after_next) &&
      idx > 0 && segm.prev.phon == 'n'
        segment[:IPA] = 'gw'
        segment[:orthography] = 'gu'
        segment.next.phon = nil
        segment.next.orth = nil
    end

    # |tiV|
    if %w{t s}.include?(segment[:IPA]) &&
      segment.next.phon == 'i' &&
      is_vowel?(segment.after_next)
        # do the thing
        segment[:IPA] = 'ʃʃ'
        segment[:orthography] << "i"
        segment.next[:IPA] = nil
        segment.next[:orthography] = nil
    end
  end

  @current.compact!

  # assign stress to each word
  @current.slice_before {|word| word[:IPA] == " " }.each do |word|
    vowels = word.find_all{|segment| segment.vocalic? }

    if word[-1][:orthography] == "!" # Manual override for final stress
      vowels[-1][:stress] = true
      word[-1][:IPA] = nil
      word[-1][:orthography] = nil
    elsif word[-1][:orthography] == ">" # Move stress one syllable towards the end
      word[-1][:IPA] = nil
      word[-1][:orthography] = nil

      case vowels.length
      when 0
        # no stress
      when 1
        vowels[-1][:stress] = true
      else
        (vowels[-1][:long] || ultima_cluster?(word)) ? vowels[-1][:stress] = true : vowels[-2][:stress] = true
      end
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
  end

  @current.compact!

  # Endings
  case @current.join
  when /alis|alem$/
    @current.pop(4)
    @current << Segment[IPA: "o", orthography: "au", stress: true, long: true]
  when /āre$/
    @current.pop(3)
    @current << Segment[IPA: "ɑ", orthography: "a", stress: true, long: false] << Segment[IPA: "r", orthography: "r", long: false]
  when /as$/
    @current.pop(2)
    @current << Segment[:IPA=>"ə", :orthography=>"e", :long=>false] << Segment[:IPA=>"s", :orthography=>"s", :long=>false]
  when /atio$/
    @current.pop(3)
    @current << Segment[:IPA=>"ɑ", :orthography=>"a", :long=>false] << Segment[:IPA=>"ʒʒ", :orthography=>"sç", :long=>false] << Segment[:IPA=>"ũ", :orthography=>"uon", :long=>true, :stress=>true]
  when /illum$/
    @current.pop(3)
    @current << Segment[IPA: "i", orthography: "ill", stress: true, long: true]
  when /illa$/
    @current.pop(4)
    @current << Segment[IPA: "i", orthography: "i", stress: true] << Segment[IPA: "j", orthography: "ll"] << Segment[IPA: "ə", orthography: "e"]
  when /a$/
    @current.pop
    @current << Segment[:IPA=>"ə", :orthography=>"e", :long=>false]
    respell_velars(@current)
  when /ēre$/
    @current.pop(3)
    @current << Segment[:IPA=>"je", :orthography=>"ié", :stress=>true, :long=>false] << Segment[:IPA=>"r", :orthography=>"r", :long=>false]
  when /(énsem|énsis)$/
    @current.pop(5)
    @current << Segment[:IPA=>"e", :orthography=>"é", :stress=>true, :long=>false] << Segment[:IPA=>"s", :orthography=>"s", :long=>false]
  when /(sin|sis)$/
    @current.pop(3)
    @current << Segment[:IPA=>"s", :orthography=>"s", :long=>false]
  when /um$/ # not us
    @current.pop(1)
    @current = step_OI26(@current)
  end

  # duplicate stresses after endings
  @current.select(&:stressed?)[0..-2].each{|s| s[:stress] = false} if @current.count(&:stressed?) > 1

  @current = step_CI2(@current)
  @current = step_CI3(@current)
  @current = step_CI4(@current)
  @current = step_CI8(@current)

  posttonic = false

  @current = @current.each_with_index do |segm, idx|
    case segm[:IPA]
    when "k"
      if @current[idx+1] && is_front_vowel?(segm.next) && segm.next[:orthography] != "u" # /y/ is a front vowel
        if segm[:orthography] == "ch"
          segm[:orthography] = "qu"
          segm[:palatalized] = true
        else
          segm[:IPA] = "ç"
        end
      end
    when "g"
      if is_front_vowel?(segm.next) && segm.next[:orthography] != "u"
        if segm[:orthography] == "gh"
          segm[:orthography] = "gu"
          segm[:palatalized] = true
        else
          segm[:IPA] = "ʝ"
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
    @steps[0] = deep_dup step_VL0(str)
    @steps[1] = step_VL1(deep_dup @steps[0])
    @steps[2] = step_VL2(deep_dup @steps[1])
    @steps[3] = step_VL3(deep_dup @steps[2])
    @steps[4] = step_VL4(deep_dup @steps[3])
    @steps[5] = step_VL5(deep_dup @steps[4])
    @steps[6] = step_VL6(deep_dup @steps[5])
    @steps[7] = step_VL7(deep_dup @steps[6])
    @steps[8] = step_VL8(deep_dup @steps[7])
    @steps[9] = step_VL9(deep_dup @steps[8])

    @steps[10] = step_OI1(deep_dup @steps[9])
    @steps[11] = step_OI2(deep_dup @steps[10])
    @steps[12] = step_OI3(deep_dup @steps[11])
    @steps[13] = step_OI4(deep_dup @steps[12])
    @steps[14] = step_OI5(deep_dup @steps[13])
    @steps[15] = step_OI6(deep_dup @steps[14])
    @steps[16] = step_OI7(deep_dup @steps[15])
    @steps[17] = step_OI8(deep_dup @steps[16])
    @steps[18] = step_OI9(deep_dup @steps[17])
    @steps[19] = step_OI10(deep_dup @steps[18])
    @steps[20] = step_OI11(deep_dup @steps[19])
    @steps[21] = step_OI12(deep_dup @steps[20])
    @steps[22] = step_OI13(deep_dup @steps[21])
    @steps[23] = step_OI14(deep_dup @steps[22])
    @steps[24] = step_OI15(deep_dup @steps[23])
    @steps[25] = step_OI16(deep_dup @steps[24])
    @steps[26] = step_OI17(deep_dup @steps[25])
    @steps[27] = step_OI18(deep_dup @steps[26])
    @steps[28] = step_OI19(deep_dup @steps[27])
    @steps[29] = step_OI20(deep_dup @steps[28])
    @steps[30] = step_OI21(deep_dup @steps[29])
    @steps[31] = step_OI22(deep_dup @steps[30])
    @steps[32] = step_OI23(deep_dup @steps[31])
    @steps[33] = step_OI24(deep_dup @steps[32])
    @steps[34] = step_OI25(deep_dup @steps[33])
    @steps[35] = step_OI26(deep_dup @steps[34])
    @steps[36] = step_OI27(deep_dup @steps[35])
    @steps[37] = step_OI28(deep_dup @steps[36])
    @steps[38] = step_OI29(deep_dup @steps[37])
  end

  if ["OLF", "L"].include?(since)
    @steps[38] = convert_OLF(str) if since == "OLF"
    @steps[39] = step_OIx1(deep_dup @steps[38])
    @steps[40] = step_OIx2(deep_dup @steps[39])
    @steps[41] = step_OIx3(deep_dup @steps[40])
    @steps[42] = step_OIx4(deep_dup @steps[41])
    @steps[43] = step_OIx5(deep_dup @steps[42])
    @steps[44] = step_OIx6(deep_dup @steps[43])
    @steps[45] = step_OIx7(deep_dup @steps[44])

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

    @roesan_steps[0] = step_RI1(deep_dup @steps[53])
    @roesan_steps[1] = step_RI2(deep_dup @roesan_steps[0])
    @roesan_steps[2] = step_RI3(deep_dup @roesan_steps[1])
    @roesan_steps[3] = step_RI4(deep_dup @roesan_steps[2])
    @roesan_steps[4] = step_RI5(deep_dup @roesan_steps[3])
    @roesan_steps[5] = step_RI6(deep_dup @roesan_steps[4])
    @roesan_steps[6] = step_RI7(deep_dup @roesan_steps[5])
    @roesan_steps[7] = step_RI8(deep_dup @roesan_steps[6])
    @roesan_steps[8] = step_RI9(deep_dup @roesan_steps[7])
    @roesan_steps[9] = step_RI10(deep_dup @roesan_steps[8])
    @roesan_steps[10] = step_RI11(deep_dup @roesan_steps[9])
    @roesan_steps[11] = step_RI12(deep_dup @roesan_steps[10])
    @roesan_steps[12] = step_RI13(deep_dup @roesan_steps[11])
    @roesan_steps[13] = step_RI14(deep_dup @roesan_steps[12])

    @paysan_steps[0] = step_PI1(deep_dup @steps[53])
    @paysan_steps[1] = step_PI2(deep_dup @paysan_steps[0])
    @paysan_steps[2] = step_PI3(deep_dup @paysan_steps[1])
    @paysan_steps[3] = step_PI4(deep_dup @paysan_steps[2])
    @paysan_steps[4] = step_PI5(deep_dup @paysan_steps[3])
    @paysan_steps[5] = step_PI6(deep_dup @paysan_steps[4])
    @paysan_steps[6] = step_PI7(deep_dup @paysan_steps[5])
    @paysan_steps[7] = step_PI8(deep_dup @paysan_steps[6])
    @paysan_steps[8] = step_PI9(deep_dup @paysan_steps[7])
    @paysan_steps[9] = step_PI10(deep_dup @paysan_steps[8])
  end

  [@steps[53], @roesan_steps[-1], @paysan_steps[-1]]
end