#!/usr/bin/ruby -w
# frozen_string_literal: true

require './ibran_change_steps.rb'
require './ibran_verb_presenter.rb'

DIACRITICS = "\u032f\u0303\u0320"

input = ARGV[-1] # STDIN.read

since = if ARGV.include?('--LL')
          'LL'
        elsif ARGV.include?('--OLF')
          'OLF'
        elsif ARGV.include?('--FRO')
          'FRO'
        else
          'L'
        end

plural = ARGV.include? '--pl'
io_verb = ARGV.include? '-io'

if ARGV.include? '--name'
  name_transform input, since, plural
else
  transform input, since, plural
end

puts "###{' '.dup << since unless since == 'L'} #{caps(input)}"           \
     " > PI #{@paysan_steps[-1].join} [#{@paysan_steps[-1].to_ipa}]," \
     " RI #{cyrillize(@roesan_steps[-1])} /"                          \
     " #{@roesan_steps[-1].join} [#{@roesan_steps[-1].to_ipa}]"

len = [*@steps, *@roesan_steps, *@paysan_steps].compact.group_by do |s|
  s.to_ipa.length
end.max[0]

if since == 'L'
  @steps[0..9].each_with_index do |step, idx|
    next if @steps[idx - 1].to_ipa == step.to_ipa # Don't print unchanged.

    puts "#{(idx.to_s << '.').ljust(3)} | " \
         "#{step.to_ipa.ljust(len)} | "     \
         "#{step.join}"
  end

  puts "#{'-' * (9 + len * 2)} VL #{@steps[9].join}"

  @steps[10..38].each_with_index do |step, idx|
    next if @steps[idx + 10 - 1].to_ipa == step.to_ipa

    puts "#{((idx + 1).to_s << '.').ljust(3)} | "                              \
         "#{step.to_ipa.ljust(len + step.to_ipa.count(DIACRITICS))}" \
         " | #{step.join}"
  end
end

if %w[OLF FRO].include? since
  original_ipa = @steps[38].to_ipa

  puts "0.  | #{original_ipa.ljust(len + original_ipa.count("\u032f\u0303"))}" \
       " | #{@steps[38].join}"
end

if %w[FRO OLF L].include?(since)
  @steps[39..45].each_with_index do |step, idx|
    next if @steps[idx + 39 - 1].to_ipa == step.to_ipa

    puts "x#{((idx + 1).to_s << '.').ljust(2)} | "                   \
         "#{step.to_ipa.ljust(len + step.to_ipa.count(DIACRITICS))}" \
         " | #{step.join}"
  end

  puts "#{'-' * (9 + len * 2)} OI #{@steps[45].join}"

  @steps[46..53].each_with_index do |step, idx|
    next if @steps[idx + 46 - 1].to_ipa == step.to_ipa

    puts "#{((idx + 1).to_s << '.').ljust(3)} | "                    \
         "#{step.to_ipa.ljust(len + step.to_ipa.count(DIACRITICS))}" \
         " | #{step.join}"
  end
end

if since == 'LL'
  original_ipa = @steps[53].to_ipa

  puts "0.  | #{original_ipa.ljust(len + original_ipa.count("\u032f\u0303"))}" \
       " | #{@steps[53].join}"
end

if %w[FRO OLF LL L].include?(since)
  puts "#{'-' * (9 + len * 2)} CI #{@steps[53].join}"

  puts 'RI'

  @roesan_steps.each_with_index do |step, idx|
    previous_step = idx.zero? ? @steps[53] : @roesan_steps[idx - 1]
    next if previous_step.to_ipa == step.to_ipa

    puts "#{((idx + 1).to_s << '.').ljust(3)} | "\
         "#{step.to_ipa.ljust(len + step.to_ipa.count(DIACRITICS))}" \
         " | #{step.join}"
  end

  puts "#{'-' * (9 + len * 2)} "            \
       "RI #{cyrillize(@roesan_steps[-1])}" \
       " / #{@roesan_steps[-1].join}"

  puts 'PI'

  @paysan_steps.each_with_index do |step, idx|
    previous_step = idx.zero? ? @steps[53] : @paysan_steps[idx - 1]
    next if previous_step.to_ipa == step.to_ipa

    puts "#{((idx + 1).to_s << '.').ljust(3)}"                          \
         " | #{step.to_ipa.ljust(len + step.to_ipa.count(DIACRITICS))}" \
         " | #{step.join}"
  end

  puts "#{'-' * (9 + len * 2)} PI #{@paysan_steps[-1].join}"
end

if ARGV.include?('-v')
  stem = input[0..-4]
  conj = input[-3..-1]

  present = { 'L' => {
    'āre' => %w[ō ās at āmus ātis ant],
    'ēre' => [io_verb ? 'eō' : 'ō', 'ēs', 'et', 'ēmus', 'ētis', 'ent'],
    'īre' => %w[iō īs it īmus ītis iunt]
  }, 'OLF' => {
    # TODO: need a verb override otherwise /verban/ becomes /verbna/
    # (actually verbāre now produces 'verban', but still have 'verbārna')
    'āre' => ['>', 's>', '>', 'ams!', 'als!', 'an'],
    'ēre' => ['>', 's>', '>', 'iéms!', 'iéls!', 'en'],
    'īre' => ['>', 's>', '>', 'ims!', 'ils!', 'ion']
  }, 'LL' => {
    'āre' => ['>', 's>', '>', 'aũs!', 'aus!', 'an'],
    'ēre' => ['>', 's>', '>', 'iéũs!', 'iéus!', 'en'],
    'īre' => ['>', 's>', '>', 'iũs!', 'ius!', 'ion']
  } }

  imperfect = { 'L' => {
    'āre' => ['a!', 'ās!', 'at!', 'āmus', 'ātis', 'ant!'],
    'ēre' => %w[ēa ēas ēa ēāmus ēātis ēant],
    'īre' => %w[jēa jēas jēa jēāmus jēātis jēant]
  }, 'OLF' => {
    'āre' => ['a!', 'as!', 'a!', 'aũs!', 'aus!', 'an!'],
    'ēre' => ['iée', 'iées', 'iée', 'aũs!', 'aus!', 'iéen'],
    'īre' => ['iée', 'iées', 'iée', 'aũs!', 'aus!', 'iéen']
  }, 'LL' => {
    'āre' => ['a!', 'as!', 'a!', 'aũs!', 'aus!', 'an!'],
    'ēre' => ['iée', 'iées', 'iée', 'aũs!', 'aus!', 'iéen'],
    'īre' => ['iée', 'iées', 'iée', 'aũs!', 'aus!', 'iéen']
  } }

  preterite = { 'L' => {
    'āre' => %w[āi āstī āi āmus āstis ārunt],
    'ēre' => %w[i ēstī e īmus īstis ērunt],
    'īre' => ['ī!', 'īstī', 'īi', 'īmus', 'īstis', 'īērunt']
  }, 'OLF' => {
    'āre' => ['ei!', 'ast!', 'ei!', 'aũs!', 'astes', 'aron'],
    'ēre' => ['>', 'iést!', '>', 'iũs!', 'istes', 'iéron'],
    'īre' => ['i!', 'ist!', 'i!', 'iũs!', 'istes', 'iéron']
  }, 'LL' => {
    'āre' => ['ei!', 'ast!', 'ei!', 'aũs!', 'astes', 'aron'],
    'ēre' => ['>', 'iést!', '>', 'iũs!', 'istes', 'iéron'],
    'īre' => ['i!', 'ist!', 'i!', 'iũs!', 'istes', 'iéron']
  } }

  present_subj = { 'L' => {
    'āre' => %w[e es e ēmus ētis ent],
    'ēre' => %w[a as a āmus ātis ant],
    'īre' => %w[ja jas ja jāmus jātis jant]
  }, 'OLF' => {
    'āre' => ['>', 's>', '>', 'iéũs!', 'iéus!', 'en'],
    'ēre' => ['e', 'es', 'e', 'aũs!', 'aus!', 'en'],
    'īre' => ['ie', 'ies', 'ie', 'iaũs!', 'iaus!', 'ien']
  }, 'LL' => {
    'āre' => ['>', 's>', '>', 'iéũs!', 'iéus!', 'en'],
    'ēre' => ['e', 'es', 'e', 'aũs!', 'aus!', 'en'],
    'īre' => ['ie', 'ies', 'ie', 'iaũs!', 'iaus!', 'ien']
  } }

  imperfect_subj = { 'L' => {
    'āre' => %w[āsse āsses āsse āssēmus āssētis āssent],
    'ēre' => %w[ēsse ēsses ēsse ēssēmus ēssētis ēssent],
    'īre' => %w[īsse īsses īsse īssēmus īssētis īssent]
  }, 'OLF' => {
    'āre' => ['ass!', 'asses', 'ass!', 'esséũs!', 'esséus!', 'assen'],
    'ēre' => ['iéss!', 'iésses', 'iéss!', 'séũs!', 'séus!', 'iéssen'],
    'īre' => ['iss!', 'isses', 'iss!', 'séũs!', 'séus', 'issen']
  }, 'LL' => {
    'āre' => ['ass!', 'āsses', 'ass!', 'esséũs!', 'esséus!', 'assen'],
    'ēre' => ['iéss!', 'iésses', 'iéss!', 'séũs!', 'séus!', 'iéssen'],
    'īre' => ['iss!', 'isses', 'iss!', 'séũs!', 'séus!', 'issen']
  } }

  conditional = { 'L' => {
    'āre' => ['āre habēa', 'āre habēas', 'āre habēa',
              'āre habēāmus', 'āre habēātis', 'āre habēant'],
    'ēre' => ['ēre habēa', 'ēre habēas', 'ēre habēa',
              'ēre habēāmus', 'ēre habēātis', 'ēre habēant'],
    'īre' => ['īre habēa', 'īre habēas', 'īre habēa',
              'īre habēāmus', 'īre habēātis', 'īre habēant']
  }, 'OLF' => {
    'āre' => ['areviée>', 'areviées>', 'areviée>',
              'arevams!', 'arevals!', 'areviéen>'],
    'ēre' => ['iéreviée>', 'iéreviées>', 'iéreviée>',
              'iérevams!', 'iérevals!', 'iéreviéen>'],
    'īre' => ['ireviée>', 'ireviées>', 'ireviée>',
              'irevams!', 'irevals!', 'ireviéen>']
  }, 'LL' => {
    'āre' => ['areuiée>', 'areuiées>', 'areuiée>',
              'arevaũs!', 'arevaus!', 'areuiéen>'],
    'ēre' => ['iéreuiée>', 'iéreuiées>', 'iéreuiée>',
              'iérevaũs!', 'iérevaus!', 'iéreuiéen>'],
    'īre' => ['ireuiée>', 'ireuiées>', 'ireuiée>',
              'irevaũs!', 'irevaus!', 'ireuiéen>']
  } }

  future = { 'L' => {
    'āre' => ['āre habeō', 'āre habēs', 'āre habet',
              'āre habēmus', 'āre habētis', 'āre habent'],
    'ēre' => ['ēre habeō', 'ēre habēs', 'ēre habet',
              'ēre habēmus', 'ēre habētis', 'ēre habent'],
    'īre' => ['īre habeō', 'īre habēs', 'īre habet',
              'īre habēmus', 'īre habētis', 'īre habent']
  }, 'OLF' => {
    'āre' => ['araez!', 'araus!', 'arav!',
              'areviéms!', 'areviéls!', 'araven>'],
    'ēre' => ['iéraez!', 'iéraus!', 'iérav!',
              'iéreviéms!', 'iéreviéls!', 'iéraven>'],
    'īre' => ['iraez!', 'iraus!', 'irav!',
              'ireviéms!', 'ireviéls!', 'iraven>']
  }, 'LL' => {
    'āre' => ['araez!', 'araus!', 'arau!',
              'areuiéũs!', 'areuiéus!', 'araven>'],
    'ēre' => ['iéraez!', 'iéraus!', 'iérau!',
              'iéreuiéũs!', 'iéreuiéus!', 'iéraven>'],
    'īre' => ['iraez!', 'iraus!', 'irau!',
              'ireuiéũs!', 'ireuiéus!', 'iraven>']
  } }

  inf = { PI: @paysan_steps[-1].join,
          RIL: @roesan_steps[-1].join,
          RIC: cyrillize(@roesan_steps[-1]),
          PIPA: @paysan_steps[-1].to_ipa,
          RIPA: @roesan_steps[-1].to_ipa }

  gerund = { 'L' => { 'āre' => 'andum', 'ēre' => 'endum', 'īre' => 'jendum' },
             'OLF' => { 'āre' => 'and!', 'ēre' => 'iend!', 'īre' => 'iend!' },
             'LL' => { 'āre' => 'and!', 'ēre' => 'iend!', 'īre' => 'iend!' } }

  past_participle = { 'L' => { 'āre' => 'ātum',
                               'ēre' => io_verb ? 'itum' : 'tum',
                               'īre' => 'ītum' },
                      'OLF' => { 'āre' => 'al!',
                                 'ēre' => 't>',
                                 'īre' => 'il!' },
                      'LL' => { 'āre' => 'au!',
                                'ēre' => 't>',
                                'īre' => 'iu!' } }

  imperative = { 'L' => {
    'āre' => %w[ā āte],
    'ēre' => ['ē', io_verb ? 'ēte' : 'ite'],
    'īre' => %w[ī īte]
  }, 'OLF' => {
    'āre' => ['e', 'al!'],
    'ēre' => ['>', 't>'],
    'īre' => ['>', 'il!']
  }, 'LL' => {
    'āre' => ['e', 'au!'],
    'ēre' => ['>', 't>'],
    'īre' => ['>', 'iu!']
  } }

  pres = (0..5).collect do |person|
    transform (stem + present[since][conj][person]), since
    { PI: @paysan_steps[-1].join,
      RIL: @roesan_steps[-1].join,
      RIC: cyrillize(@roesan_steps[-1]),
      PIPA: @paysan_steps[-1].to_ipa,
      RIPA: @roesan_steps[-1].to_ipa }
  end

  impf = (0..5).collect do |person|
    transform (stem + imperfect[since][conj][person]), since
    { PI: @paysan_steps[-1].join,
      RIL: @roesan_steps[-1].join,
      RIC: cyrillize(@roesan_steps[-1]),
      PIPA: @paysan_steps[-1].to_ipa,
      RIPA: @roesan_steps[-1].to_ipa }
  end

  pret = (0..5).collect do |person|
    transform (stem + preterite[since][conj][person]), since
    { PI: @paysan_steps[-1].join,
      RIL: @roesan_steps[-1].join,
      RIC: cyrillize(@roesan_steps[-1]),
      PIPA: @paysan_steps[-1].to_ipa,
      RIPA: @roesan_steps[-1].to_ipa }
  end

  psubj = (0..5).collect do |person|
    transform (stem + present_subj[since][conj][person]), since
    { PI: @paysan_steps[-1].join,
      RIL: @roesan_steps[-1].join,
      RIC: cyrillize(@roesan_steps[-1]),
      PIPA: @paysan_steps[-1].to_ipa,
      RIPA: @roesan_steps[-1].to_ipa }
  end

  isubj = (0..5).collect do |person|
    transform (stem + imperfect_subj[since][conj][person]), since
    { PI: @paysan_steps[-1].join,
      RIL: @roesan_steps[-1].join,
      RIC: cyrillize(@roesan_steps[-1]),
      PIPA: @paysan_steps[-1].to_ipa,
      RIPA: @roesan_steps[-1].to_ipa }
  end

  cond = (0..5).collect do |person|
    transform (stem + conditional[since][conj][person]), since
    { PI: @paysan_steps[-1].join,
      RIL: @roesan_steps[-1].join,
      RIC: cyrillize(@roesan_steps[-1]),
      PIPA: @paysan_steps[-1].to_ipa,
      RIPA: @roesan_steps[-1].to_ipa }
  end

  fut = (0..5).collect do |person|
    transform (stem + future[since][conj][person]), since
    { PI: @paysan_steps[-1].join,
      RIL: @roesan_steps[-1].join,
      RIC: cyrillize(@roesan_steps[-1]),
      PIPA: @paysan_steps[-1].to_ipa,
      RIPA: @roesan_steps[-1].to_ipa }
  end

  verb_forms = [*pres, *impf, *pret, *psubj, *isubj, *cond, *fut]
  longest = verb_forms.compact.inject(0) do |memo, step|
    [memo, step[:PI].length, step[:RIL].length, step[:RIC].length,
     step[:PIPA].length, step[:RIPA].length].max
  end

  # Gerund
  transform (stem + gerund[since][conj]), since
  ger = { PI: @paysan_steps[-1].join,
          RIL: @roesan_steps[-1].join,
          RIC: cyrillize(@roesan_steps[-1]),
          PIPA: @paysan_steps[-1].to_ipa,
          RIPA: @roesan_steps[-1].to_ipa }

  # Past Participle
  transform (stem + past_participle[since][conj]), since
  ppl = { PI: @paysan_steps[-1].join,
          RIL: @roesan_steps[-1].join,
          RIC: cyrillize(@roesan_steps[-1]),
          PIPA: @paysan_steps[-1].to_ipa,
          RIPA: @roesan_steps[-1].to_ipa }

  # Imperatives
  imv = (0..1).collect do |person|
    transform (stem + imperative[since][conj][person]), since
    { PI: @paysan_steps[-1].join,
      RIL: @roesan_steps[-1].join,
      RIC: cyrillize(@roesan_steps[-1]),
      PIPA: @paysan_steps[-1].to_ipa,
      RIPA: @roesan_steps[-1].to_ipa }
  end

  IbranVerbPresenter.mono_single('Infinitive', inf)
  IbranVerbPresenter.monospace('Present', pres, longest)
  IbranVerbPresenter.monospace('Imperfect', impf, longest)
  IbranVerbPresenter.monospace('Preterite', pret, longest)
  IbranVerbPresenter.monospace('Present Subjunctive', psubj, longest)
  IbranVerbPresenter.monospace('Imperfect Subjunctive', isubj, longest)
  IbranVerbPresenter.monospace('Conditional', cond, longest)
  IbranVerbPresenter.monospace('Future', fut, longest)
  IbranVerbPresenter.mono_double('Imperative', imv)
  IbranVerbPresenter.mono_single('Gerund', ger)
  IbranVerbPresenter.mono_single('Past Participle', ppl)

end

final_roesan = @roesan_steps[-1].join
final_paysan = @paysan_steps[-1].join

if ARGV.include?('-t')
  puts "{ w: \"#{input}\", "                            \
       "RI_IPA: \"#{@roesan_steps[-1].to_ipa}\", "      \
       "RI_Cyrl: \"#{cyrillize(@roesan_steps[-1])}\", " \
       "RI_Latn: \"#{@roesan_steps[-1].join}\", "       \
       "PI_IPA: \"#{@paysan_steps[-1].to_ipa}\", "      \
       "PI: \"#{@paysan_steps[-1].join}\" },"
end

puts "NeoRI: #{neocyrillize(@roesan_steps[-1])}"

# HTML for Lexicon.html
puts
puts "<dt><dfn class=\"paysan\">#{@paysan_steps[-1].join}</dfn>, " \
     "<dfn class=\"roesan\">#{cyrillize(@roesan_steps[-1])}"       \
     "#{" (#{final_roesan})" if final_roesan != final_paysan}</dfn></dt>"
if @paysan_steps[-1].to_ipa != @roesan_steps[-1].to_ipa
  puts '<dd class="pronunciation">'                                   \
       "<span class=\"paysan\">/#{@paysan_steps[-1].to_ipa}/</span> " \
       "<span class=\"roesan\">/#{@roesan_steps[-1].to_ipa}/</span></dd>"
else
  puts "<dd class=\"pronunciation\">/#{@roesan_steps[-1].to_ipa}/</dd>"
end
puts '<dd class="part-of-speech"><!-- PART OF SPEECH --></dd>'
puts '<dd class="definition"><!-- DEFINITION --></dd>'
lang = case since
       when 'OLF' then 'Old Dutch'
       when 'FRO' then 'Old French'
       else 'Latin'
       end
puts "<dd class=\"etymology\">#{lang} <i>#{input}</i>.</dd>"

# CSV for Anki
puts
puts [@paysan_steps[-1].join,
      cyrillize(@roesan_steps[-1]),
      @roesan_steps[-1].join,
      @paysan_steps[-1].to_ipa,
      @roesan_steps[-1].to_ipa,
      'DEFINITION'].join(';')
