#!/usr/bin/ruby -w
require './ibran_change_steps.rb'
require './ibran_verb_presenter.rb'

input = ARGV[-1] # STDIN.read

if ARGV.include?("--LL")
  since = "LL"
elsif ARGV.include?("--OLF")
  since = "OLF"
else
  since = "L"
end

plural = ARGV.include? '--pl'

transform input, since, plural

puts "###{ " " << since unless since == "L"} #{caps(input)} > PI #{@paysan_steps[-1].join} [#{full_ipa(@paysan_steps[-1])}], RI #{cyrillize(@roesan_steps[-1])} / #{@roesan_steps[-1].join} [#{full_ipa(@roesan_steps[-1])}]"

len = [*@steps, *@roesan_steps, *@paysan_steps].compact.inject(0) do |memo, step|
  memo = [memo, full_ipa(step).length].max
end

if since == "L"
  @steps[0..9].each_with_index do |step, idx|
    puts "#{(idx.to_s << ".").ljust(3)} | #{full_ipa(step).ljust(len)} | #{step.join}" unless full_ipa(@steps[idx-1]) == full_ipa(step)
  end

  puts "#{'-' * (9 + len * 2)} VL #{@steps[9].join}"

  @steps[10..38].each_with_index do |step, idx|
    puts "#{((idx + 1).to_s << ".").ljust(3)} | #{full_ipa(step).ljust(len + full_ipa(step).count("\u032f\u0303\u0320"))} | #{step.join}" unless full_ipa(@steps[idx+10-1]) == full_ipa(step)
  end
end

puts "0.  | #{full_ipa(@steps[38]).ljust(len + full_ipa(@steps[38]).count("\u032f\u0303"))} | #{@steps[38].join}" if since == "OLF"

if ["OLF", "L"].include?(since)
  @steps[39..45].each_with_index do |step, idx|
    puts "x#{((idx + 1).to_s << ".").ljust(2)} | #{full_ipa(step).ljust(len + full_ipa(step).count("\u032f\u0303\u0320"))} | #{step.join}" unless full_ipa(@steps[idx+39-1]) == full_ipa(step)
  end

  puts "#{'-' * (9 + len * 2)} OI #{@steps[45].join}"

  @steps[46..53].each_with_index do |step, idx|
    puts "#{((idx + 1).to_s << ".").ljust(3)} | #{full_ipa(step).ljust(len + full_ipa(step).count("\u032f\u0303\u0320"))} | #{step.join}" unless full_ipa(@steps[idx+46-1]) == full_ipa(step)
  end
end

puts "0.  | #{full_ipa(@steps[53]).ljust(len + full_ipa(@steps[53]).count("\u032f\u0303"))} | #{@steps[53].join}" if since == "LL"

if ["OLF", "LL", "L"].include?(since)
  puts "#{'-' * (9 + len * 2)} CI #{@steps[53].join}"

  puts "RI"

  @roesan_steps.each_with_index do |step, idx|
    puts "#{((idx + 1).to_s << ".").ljust(3)} | #{full_ipa(step).ljust(len + full_ipa(step).count("\u032f\u0303\u0320"))} | #{step.join}" unless full_ipa(idx == 0 ? @steps[53] : @roesan_steps[idx-1]) == full_ipa(step)
  end

  puts "#{'-' * (9 + len * 2)} RI #{cyrillize(@roesan_steps[-1])} / #{@roesan_steps[-1].join}"

  puts "PI"

  @paysan_steps.each_with_index do |step, idx|
    puts "#{((idx + 1).to_s << ".").ljust(3)} | #{full_ipa(step).ljust(len + full_ipa(step).count("\u032f\u0303\u0320"))} | #{step.join}" unless full_ipa(idx == 0 ? @steps[53] : @paysan_steps[idx-1]) == full_ipa(step)
  end
  
  puts "#{'-' * (9 + len * 2)} PI #{@paysan_steps[-1].join}"
end

if ARGV.include?("-v")
  stem = input[0..-4]
  conj = input[-3..-1]
  
  present = { "L" => {
    "āre" => [ "ō", "ās", "at", "āmus", "ātis", "ant"],
    "ēre" => [ARGV.include?("-io") ? "eō" : "ō", "ēs", "et", "ēmus", "ētis", "ent"],
    "īre" => ["iō", "īs", "it", "īmus", "ītis", "iunt"]
  }, "OLF" => {
    "āre" => [ ">", "s>", ">", "ams!", "als!", "an"],  #need a verb override otherwise /verban/ becomes /verbna/
    "ēre" => [ ">", "s>", ">", "iéms!", "iéls!", "en"],
    "īre" => [ ">", "s>", ">", "ims!", "ils!", "ion"]
  }, "LL" => {
    "āre" => [ ">", "s>", ">", "aũs!", "aus!", "an"],
    "ēre" => [ ">", "s>", ">", "iéũs!", "iéus!", "en"],
    "īre" => [ ">", "s>", ">", "iũs!", "ius!", "ion"]
  }}
  
  imperfect = { "L" => {
    "āre" => [ "a!", "ās!", "at!", "āmus", "ātis", "ant!"],
    "ēre" => ["ēa", "ēas", "ēa", "ēāmus", "ēātis", "ēant"],
    "īre" => ["jēa", "jēas", "jēa", "jēāmus", "jēātis", "jēant"]
  }, "OLF" => {
    "āre" => [ "a!", "as!", "a!", "aũs!", "aus!", "an!"],
    "ēre" => ["iée", "iées", "iée", "aũs!", "aus!", "iéen"],
    "īre" => ["iée", "iées", "iée", "aũs!", "aus!", "iéen"]
  }, "LL" => {
    "āre" => [ "a!", "as!", "a!", "aũs!", "aus!", "an!"],
    "ēre" => ["iée", "iées", "iée", "aũs!", "aus!", "iéen"],
    "īre" => ["iée", "iées", "iée", "aũs!", "aus!", "iéen"]
  }}
  
  preterite = { "L" => {
    "āre" => [ "āi", "āstī", "āi", "āmus", "āstis", "ārunt"],
    "ēre" => [ "i", "ēstī", "e", "īmus", "īstis", "ērunt"],
    "īre" => [ "ī!", "īstī", "īi", "īmus", "īstis", "īērunt"]
  }, "OLF" => {
    "āre" => [ "ei!", "ast!", "ei!", "aũs!", "astes", "aron"],
    "ēre" => [ ">", "iést!", ">", "iũs!", "istes", "iéron"],
    "īre" => [ "i!", "ist!", "i!", "iũs!", "istes", "iéron"]
  }, "LL" => {
    "āre" => [ "ei!", "ast!", "ei!", "aũs!", "astes", "aron"],
    "ēre" => [ ">", "iést!", ">", "iũs!", "istes", "iéron"],
    "īre" => [ "i!", "ist!", "i!", "iũs!", "istes", "iéron"]
  }}
  
  present_subj = { "L" => {
    "āre" => ["e", "es", "e", "ēmus", "ētis", "ent"],
    "ēre" => ["a", "as", "a", "āmus", "ātis", "ant"],
    "īre" => ["ja", "jas", "ja", "jāmus", "jātis", "jant"]
  }, "OLF" => {
    "āre" => [">", "s>", ">", "iéũs!", "iéus!", "en"],
    "ēre" => ["e", "es", "e", "aũs!", "aus!", "en"],
    "īre" => ["ie", "ies", "ie", "iaũs!", "iaus!", "ien"]
  }, "LL" => {
    "āre" => [">", "s>", ">", "iéũs!", "iéus!", "en"],
    "ēre" => ["e", "es", "e", "aũs!", "aus!", "en"],
    "īre" => ["ie", "ies", "ie", "iaũs!", "iaus!", "ien"]
  }}
  
  imperfect_subj = { "L" => {
    "āre" => ["āsse", "āsses", "āsse", "āssēmus", "āssētis", "āssent"],
    "ēre" => ["ēsse", "ēsses", "ēsse", "ēssēmus", "ēssētis", "ēssent"],
    "īre" => ["īsse", "īsses", "īsse", "īssēmus", "īssētis", "īssent"]
  }, "OLF" => {
    "āre" => ["ass!", "asses", "ass!", "esséũs!", "esséus!", "assen"],
    "ēre" => ["iéss!", "iésses", "iéss!", "séũs!", "séus!", "iéssen"],
    "īre" => ["iss!", "isses", "iss!", "séũs!", "séus", "issen"]
  }, "LL" => {
    "āre" => ["ass!", "āsses", "ass!", "esséũs!", "esséus!", "assen"],
    "ēre" => ["iéss!", "iésses", "iéss!", "séũs!", "séus!", "iéssen"],
    "īre" => ["iss!", "isses", "iss!", "séũs!", "séus!", "issen"]
  }}

  conditional = { "L" => {
    "āre" => ["āre habēa", "āre habēas", "āre habēa", "āre habēāmus", "āre habēātis", "āre habēant"],
    "ēre" => ["ēre habēa", "ēre habēas", "ēre habēa", "ēre habēāmus", "ēre habēātis", "ēre habēant"],
    "īre" => ["īre habēa", "īre habēas", "īre habēa", "īre habēāmus", "īre habēātis", "īre habēant"]
  }, "OLF" => {
    "āre" => ["areviée>", "areviées>", "areviée>", "arevams!", "arevals!", "areviéen>"],
    "ēre" => ["iéreviée>", "iéreviées>", "iéreviée>", "iérevams!", "iérevals!", "iéreviéen>"],
    "īre" => ["ireviée>", "ireviées>", "ireviée>", "irevams!", "irevals!", "ireviéen>"]
  }, "LL" => {
    "āre" => ["areuiée>", "areuiées>", "areuiée>", "arevaũs!", "arevaus!", "areuiéen>"],
    "ēre" => ["iéreuiée>", "iéreuiées>", "iéreuiée>", "iérevaũs!", "iérevaus!", "iéreuiéen>"],
    "īre" => ["ireuiée>", "ireuiées>", "ireuiée>", "irevaũs!", "irevaus!", "ireuiéen>"]
  }}
  
  future = { "L" => {
    "āre" => ["āre habeō", "āre habēs", "āre habet", "āre habēmus", "āre habētis", "āre habent"],
    "ēre" => ["ēre habeō", "ēre habēs", "ēre habet", "ēre habēmus", "ēre habētis", "ēre habent"],
    "īre" => ["īre habeō", "īre habēs", "īre habet", "īre habēmus", "īre habētis", "īre habent"]
  }, "OLF" => {
    "āre" => ["araez!", "araus!", "arav!", "areviéms!", "areviéls!", "araven>"],
    "ēre" => ["iéraez!", "iéraus!", "iérav!", "iéreviéms!", "iéreviéls!", "iéraven>"],
    "īre" => ["iraez!", "iraus!", "irav!", "ireviéms!", "ireviéls!", "iraven>"]
  }, "LL" => {
    "āre" => ["araez!", "araus!", "arau!", "areuiéũs!", "areuiéus!", "araven>"],
    "ēre" => ["iéraez!", "iéraus!", "iérau!", "iéreuiéũs!", "iéreuiéus!", "iéraven>"],
    "īre" => ["iraez!", "iraus!", "irau!", "ireuiéũs!", "ireuiéus!", "iraven>"]
  }}
  
  inf = { PI: @paysan_steps[-1].join, RIL: @roesan_steps[-1].join, RIC: cyrillize(@roesan_steps[-1]), 
      PIPA: full_ipa(@paysan_steps[-1]), RIPA: full_ipa(@roesan_steps[-1]) }

  gerund = { "L"  => { "āre" => "andum", "ēre" => "endum", "īre" => "jendum" },
            "OLF" => { "āre" => "and!", "ēre" => "iend!", "īre" => "iend!" },
             "LL" => { "āre" => "and!", "ēre" => "iend!", "īre" => "iend!" }}
  
  past_participle = { "L" => { "āre" => "ātum", "ēre" => ARGV.include?("-io") ? "itum" : "tum", "īre" => "ītum" },
                    "OLF" => { "āre" => "al!", "ēre" => "t>", "īre" => "il!" },
                     "LL" => { "āre" => "au!", "ēre" => "t>", "īre" => "iu!" }}

  imperative = { "L" => {
    "āre" => ["ā", "āte"],
    "ēre" => ["ē", ARGV.include?("-io") ? "ēte" : "ite"],
    "īre" => ["ī", "īte"]
  }, "OLF" => {
    "āre" => ["e", "al!"],
    "ēre" => [">", "t>"],
    "īre" => [">", "il!"]
  }, "LL" => {
    "āre" => ["e", "au!"],
    "ēre" => [">", "t>"],
    "īre" => [">", "iu!"]
  }}

  pres = (0..5).collect do |person|
    transform (stem + present[since][conj][person]), since
    { PI: @paysan_steps[-1].join, RIL: @roesan_steps[-1].join, RIC: cyrillize(@roesan_steps[-1]), 
      PIPA: full_ipa(@paysan_steps[-1]), RIPA: full_ipa(@roesan_steps[-1]) }
  end

  impf = (0..5).collect do |person|
    transform (stem + imperfect[since][conj][person]), since
    { PI: @paysan_steps[-1].join, RIL: @roesan_steps[-1].join, RIC: cyrillize(@roesan_steps[-1]), 
      PIPA: full_ipa(@paysan_steps[-1]), RIPA: full_ipa(@roesan_steps[-1]) }
  end
  
  pret = (0..5).collect do |person|
    transform (stem + preterite[since][conj][person]), since
    { PI: @paysan_steps[-1].join, RIL: @roesan_steps[-1].join, RIC: cyrillize(@roesan_steps[-1]), 
      PIPA: full_ipa(@paysan_steps[-1]), RIPA: full_ipa(@roesan_steps[-1]) }
  end
  
  psubj = (0..5).collect do |person|
    transform (stem + present_subj[since][conj][person]), since
    { PI: @paysan_steps[-1].join, RIL: @roesan_steps[-1].join, RIC: cyrillize(@roesan_steps[-1]), 
      PIPA: full_ipa(@paysan_steps[-1]), RIPA: full_ipa(@roesan_steps[-1]) }
  end
  
  isubj = (0..5).collect do |person|
    transform (stem + imperfect_subj[since][conj][person]), since
    { PI: @paysan_steps[-1].join, RIL: @roesan_steps[-1].join, RIC: cyrillize(@roesan_steps[-1]), 
      PIPA: full_ipa(@paysan_steps[-1]), RIPA: full_ipa(@roesan_steps[-1]) }
  end
  
  cond = (0..5).collect do |person|
    transform (stem + conditional[since][conj][person]), since
    { PI: @paysan_steps[-1].join, RIL: @roesan_steps[-1].join, RIC: cyrillize(@roesan_steps[-1]), 
      PIPA: full_ipa(@paysan_steps[-1]), RIPA: full_ipa(@roesan_steps[-1]) }
  end
  
  fut = (0..5).collect do |person|
    transform (stem + future[since][conj][person]), since
    { PI: @paysan_steps[-1].join, RIL: @roesan_steps[-1].join, RIC: cyrillize(@roesan_steps[-1]), 
      PIPA: full_ipa(@paysan_steps[-1]), RIPA: full_ipa(@roesan_steps[-1]) }
  end
  
  longest = [*pres, *impf, *pret, *psubj, *isubj, *cond, *fut].compact.inject(0) do |memo, step|
    memo = [memo, step[:PI].length, step[:RIL].length, step[:RIC].length, 
            step[:PIPA].length, step[:RIPA].length].max
  end
  
  # Gerund
  transform (stem + gerund[since][conj]), since
  ger = { PI: @paysan_steps[-1].join, RIL: @roesan_steps[-1].join, RIC: cyrillize(@roesan_steps[-1]), 
      PIPA: full_ipa(@paysan_steps[-1]), RIPA: full_ipa(@roesan_steps[-1]) }
      
  # Past Participle
  transform (stem + past_participle[since][conj]), since
  ppl = { PI: @paysan_steps[-1].join, RIL: @roesan_steps[-1].join, RIC: cyrillize(@roesan_steps[-1]), 
      PIPA: full_ipa(@paysan_steps[-1]), RIPA: full_ipa(@roesan_steps[-1]) }
    
  # Imperatives
  imv = (0..1).collect do |person|
    transform (stem + imperative[since][conj][person]), since
    { PI: @paysan_steps[-1].join, RIL: @roesan_steps[-1].join, RIC: cyrillize(@roesan_steps[-1]), 
      PIPA: full_ipa(@paysan_steps[-1]), RIPA: full_ipa(@roesan_steps[-1]) }
  end
  
  IbranVerbPresenter.mono_single("Infinitive", inf)
  IbranVerbPresenter.monospace("Present", pres, longest)
  IbranVerbPresenter.monospace("Imperfect", impf, longest)
  IbranVerbPresenter.monospace("Preterite", pret, longest)
  IbranVerbPresenter.monospace("Present Subjunctive", psubj, longest)
  IbranVerbPresenter.monospace("Imperfect Subjunctive", isubj, longest)
  IbranVerbPresenter.monospace("Conditional", cond, longest)
  IbranVerbPresenter.monospace("Future", fut, longest)
  IbranVerbPresenter.mono_double("Imperative", imv)
  IbranVerbPresenter.mono_single("Gerund", ger)
  IbranVerbPresenter.mono_single("Past Participle", ppl)
  
end

if ARGV.include?("-t")
  puts "{ w: \"#{input}\", RI_IPA: \"#{full_ipa(@roesan_steps[-1])}\", RI_Cyrl: \"#{cyrillize(@roesan_steps[-1])}\", RI_Latn: \"#{@roesan_steps[-1].join}\", PI_IPA: \"#{full_ipa(@paysan_steps[-1])}\", PI: \"#{@paysan_steps[-1].join}\" },"
end

p "Neocyrillic: #{neocyrillize(@roesan_steps[-1])}"