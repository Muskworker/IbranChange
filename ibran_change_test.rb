#!/usr/bin/ruby -w

#require 'test/unit'
require 'minitest/autorun'
require './ibran_change_steps.rb'

class IbranChangeTest < Minitest::Test  
  def test_zero
    # work at all
    quid = step_vl0('quid')
    
    assert_equal "kwid", ipa(quid)
    assert_equal "quid", quid.join
    
    # c = k
    facere = step_vl0('facēre')
    
    assert_equal "fakere", ipa(facere)
    
    # y = i
    hymnum = step_vl0('hymnum')
    assert_equal 'himnum', ipa(hymnum)
    assert_equal 'himnum', hymnum.join
  end
  
  def to_vl1 str
    step_vl1(step_vl0 str)
  end
  
  def test_one
    # Polysyllables
    causam = to_vl1('causam')
    
    assert_equal "kausa", ipa(causam)
    assert_equal "causa", causam.join
    
    # Monosyllables
    iam = to_vl1('jam')
    
    assert_equal "jan", ipa(iam)
    assert_equal "jan", iam.join
  end
  
  def to_vl2 str
    step_vl2(to_vl1 str)
  end
  
  def test_two
    cognoscere = to_vl2('cognoscēre')
    
    assert_equal "konnoskere", ipa(cognoscere)
    assert_equal "connoscēre", cognoscere.join
  end
  
  def to_vl3 str
    step_vl3(to_vl2 str)
  end
  
  def test_three
    potit = to_vl3('potit')
    
    assert_equal "poti", ipa(potit)
    assert_equal "poti", potit.join
  end
  
  def to_vl4 str
    step_vl4(to_vl3 str)
  end
  
  def test_four
    habere = to_vl4('habēre')
    
    assert_equal "abere", ipa(habere)
    assert_equal "abēre", habere.join

    chorda = to_vl4('chordam')
    
    assert_equal "korda", ipa(chorda)
    assert_equal "corda", chorda.join
  end
  
  def to_vl5 str
    step_vl5(to_vl4 str)
  end
  
  def test_five
    perdiu = to_vl5("perdiū")
    
    assert_equal "perdju", ipa(perdiu)
    assert_equal "perdjū", perdiu.join
  end
  
  def to_vl6 str
    step_vl6(to_vl5 str)
  end
  
  def test_six
    generem = to_vl6("generem")  # short penult
    assert_equal "genre", ipa(generem)
    assert_equal "genre", generem.join
        
    alteramente = to_vl6("alterā mente")  # heavy penult
    assert_equal "altra mente", ipa(alteramente)
    assert_equal "altrā mente", alteramente.join

    saeculum = to_vl6("saeculum")  # diphthong bug
    assert_equal "saeklu", ipa(saeculum)
    assert_equal "saeclu", saeculum.join
  end
  
  def to_vl7 str
    step_vl7(to_vl6 str)
  end
  
  def test_seven
    porticum = to_vl7("porticum")
    assert_equal "portʃu", ipa(porticum)
    assert_equal "porçu", porticum.join
  end
  
  def to_vl8 str
    step_vl8(to_vl7 str)
  end
  
  def test_eight
    test_words = [
      { w: "partem",  ipa: "pɑrte",  orth: "parte"  },
      { w: "gentem",  ipa: "gɛnte",  orth: "gente"  },
      { w: "caecum",  ipa: "kɛku",   orth: "cecu"   },
      { w: "spissum", ipa: "spessu", orth: "spéssu" },
      { w: "jacēre",  ipa: "jakere", orth: "jacére" },
      { w: "foedum",  ipa: "fedu",   orth: "fédu"   },
      { w: "audīre",  ipa: "audire", orth: "audire" },
      { w: "ovum",    ipa: "ɔvu",    orth: "ovu"    },
      { w: "muttum",  ipa: "mottu",  orth: "móttu"  },
      { w: "tōtum",   ipa: "totu",   orth: "tótu"   },
      { w: "paucum",  ipa: "poku",   orth: "pócu"   }, 
      { w: "ūnum",    ipa: "unu",    orth: "unu"    }
    ]
    
    test_words.each do |word|
      xform = to_vl8 word[:w]
      assert_equal word[:ipa], ipa(xform)
      assert_equal word[:orth], xform.join
    end
  end

  def to_vl9 str
    step_vl9(to_vl8 str)
  end
  
  def test_nine
    test_words = [
      { w: "marrītum", ipa: "mɑrritɔ", orth: "marrito" },
      { w: "bibēre",   ipa: "bɛberɛ",  orth: "bebére"  },
      { w: "fīcātum",  ipa: "fikɑtɔ",  orth: "ficato"  },
      { w: "audīre",   ipa: "ɔdirɛ",   orth: "odire"   },
      { w: "tūtāre",   ipa: "tutɑrɛ",  orth: "tutare"  }
    ]
    
    test_words.each do |word|
      xform = to_vl9 word[:w]
      assert_equal word[:ipa], ipa(xform)
      assert_equal word[:orth], xform.join
    end
  end
  
  def to_oi1 str
    step_oi1(to_vl9 str)
  end
  
  def test_oi_one
    perdiu = to_oi1("perdiū")
    assert_equal "pɛrdʒu", ipa(perdiu)
    assert_equal "perju", perdiu.join    
  end
  
  def to_oi2 str
    step_oi2(to_oi1 str)
  end
  
  def test_oi_two
    propium = to_oi2 "propium"
    assert_equal "prɔtʃɔ", ipa(propium)
    assert_equal "proço", propium.join
    
    grassia = to_oi2 "grassiam"
    assert_equal "grɑtʃɑ", ipa(grassia)
    assert_equal "graça", grassia.join

    bestiola = to_oi2 "bestjōlam"
    assert_equal "bɛstʃolɑ", ipa(bestiola)
    assert_equal "besçóla", bestiola.join
  end
  
  def to_oi3 str
    step_oi3(to_oi2 str)
  end
  
  def test_oi_three
    jocare = to_oi3 "jocāre"
    assert_equal "dʒɔkɑrɛ", ipa(jocare)
    assert_equal "jocare", jocare.join
  end
  
  def to_oi4 str
    step_oi4(to_oi3 str)
  end
  
  def test_oi_four
    cognoscere = to_oi4 "cognoscēre"
    assert_equal "kɔɲɔskerɛ", ipa(cognoscere)
    assert_equal "conhoscére", cognoscere.join
  end
  
  def to_oi5 str
    step_oi5(to_oi4 str)
  end
  
  def test_oi_five
    stella = to_oi5 "stella"
    assert_equal "stɛʎɑ", ipa(stella)
    assert_equal "stella", stella.join
  end
  
  def to_oi6 str
    step_oi6(to_oi5 str)
  end
  
  def test_oi_six
    videre = to_oi6 "vidēre"
    assert_equal "vɛerɛ", ipa(videre)
    assert_equal "veére", videre.join
    
    dicere = to_oi6 "dīcēre"  # was grabbing initial consonants
    assert_equal "dikerɛ", ipa(dicere)
    assert_equal "dicére", dicere.join
  end
  
  def to_oi7 str
    step_oi7(to_oi6 str)
  end
  
  def test_oi_seven
    habere = to_oi7 "habēre"
    assert_equal "ɑverɛ", ipa(habere)
    assert_equal "avére", habere.join
  end
  
  def to_oi8 str
    step_oi8(to_oi7 str)
  end
  
  def test_oi_eight
    pes = to_oi8 "pedem"
    assert_equal "pɛj", ipa(pes)
    assert_equal "pei", pes.join
  end
  
  def to_oi9 str
    step_oi9(to_oi8 str)
  end
  
  def test_oi_nine
    fides = to_oi9 "fidem"
    assert_equal "fej", ipa(fides)
    assert_equal "féi", fides.join
  end
  
  def to_oi10 str
    step_oi10(to_oi9 str)
  end
  
  def test_oi_ten
    audis = to_oi10 "audīs"
    assert_equal "ojs", ipa(audis)
    assert_equal "óis", audis.join 
  end
  
  def to_oi11 str
    step_oi11(to_oi10 str)
  end
  
  def test_oi_eleven
    test_words = [
      { w: "dīcēre",   ipa: "ditʃerɛ", orth: "dicére"   },
      { w: "gentem",   ipa: "dʒɛntɛ",  orth: "gente"    },
      { w: "por quid", ipa: "pɔrkɛ",   orth: "porque",   full_ipa: "pɔrˈkʲɛ"},
      { w: "anguilla", ipa: "ɑngeʎɑ",  orth: "anguélla", full_ipa: "ɑnˈgʲeʎɑ" }
    ]
    
    test_words.each do |word|
      xform = to_oi11 word[:w]
      assert_equal word[:ipa], ipa(xform)
      assert_equal word[:orth], xform.join
      assert_equal word[:full_ipa], xform.to_ipa if word[:full_ipa]
    end    
  end
  
  def to_oi12 str
    step_oi12(to_oi11 str)
  end
  
  def test_oi_twelve
    test_words = [
      { w: "locālem",  ipa: "lɔkɑlɛ",  orth: "locale"  },
      { w: "galbīnum", ipa: "gɑlbinɔ", orth: "galbino" },
      { w: "quām",     ipa: "kɑn",     orth: "quan"    },
      { w: "linguam",  ipa: "lengɑ",   orth: "léngua"  }
    ]
    
    test_words.each do |word|
      xform = to_oi12 word[:w]
      assert_equal word[:ipa], ipa(xform)
      assert_equal word[:orth], xform.join
    end    
  end  

  def to_oi13 str
    step_oi13(to_oi12 str)
  end
  
  def test_oi_thirteen
    quomodo = to_oi13 'quō modō'
    assert_equal "kɔmɔɔ", ipa(quomodo)
    assert_equal "quomoo", quomodo.join
    
    exstinguo = to_oi13 'extinguō'
    assert_equal "ɛkstengɔ", ipa(exstinguo)
    assert_equal "exténguo", exstinguo.join
  end
  
  def to_oi14 str
    step_oi14(to_oi13 str)
  end
  
  def test_oi_fourteen
    test_words = [
      { w: "sapēre",     ipa: "sɑberɛ",    orth: "sabére"   },
      { w: "prophētam",  ipa: "prɔvelɑ",   orth: "provéla"  },
      { w: "oblītāre",   ipa: "ɔblilɑrɛ",  orth: "oblilare" },  # This is -> obdilare in the table, doesn't match the RAW.
      { w: "veritātem",  ipa: "vɛrɛlɑdɛ",  orth: "verelade" },
      { w: "potem",      ipa: "pɔlɛ",      orth: "pole"     },
      { w: "causam",     ipa: "kozɑ",      orth: "cósa"     },
      { w: "verācum",    ipa: "vɛrɑgɔ",    orth: "verago"   },
      { w: "locālem",    ipa: "lɔgɑlɛ",    orth: "logale"   },
      { w: "misculātum", ipa: "mɛskɔdɑlɔ", orth: "mescodalo"},
      { w: "sequō",      ipa: "sɛgɔ",      orth: "seguo"    }
    ]
    
    test_words.each do |word|
      xform = to_oi14 word[:w]
      assert_equal word[:ipa], ipa(xform)
      assert_equal word[:orth], xform.join
    end    
  end  

  def to_oi15 str
    step_oi15(to_oi14 str)
  end
  
  def test_oi_fifteen
    test_words = [
      { w: "aprīlem", ipa: "ɑbrilɛ", orth: "abrile" },
      { w: "mātrem",  ipa: "mɑdrɛ",  orth: "madre"  },
      { w: "oculum",  ipa: "ɔglɔ",   orth: "oglo"   }
    ]
    
    test_words.each do |word|
      xform = to_oi15 word[:w]
      assert_equal word[:ipa], ipa(xform)
      assert_equal word[:orth], xform.join
    end    
  end  

  def to_oi16 str
    step_oi16(to_oi15 str)
  end
  
  def test_oi_sixteen
    flor = to_oi16 "flōrem"
    assert_equal "vlorɛ", ipa(flor)
    assert_equal "vlóre", flor.join 
  end
  
  def to_oi17 str
    step_oi17(to_oi16 str)
  end
  
  def test_oi_seventeen
    test_words = [
      { w: "scūppīre", ipa: "skupirɛ", orth: "scupire" },
      { w: "muttum",   ipa: "motɔ",    orth: "móto"    },
      { w: "toccāre",  ipa: "tɔkɑrɛ",  orth: "tocare"  },
      { w: "passāre",  ipa: "pɑsɑrɛ",  orth: "passare" },
      { w: "marrītum", ipa: "mɑrilɔ",  orth: "marilo"  }
    ]
    
    test_words.each do |word|
      xform = to_oi17 word[:w]
      assert_equal word[:ipa], ipa(xform)
      assert_equal word[:orth], xform.join
    end    
  end  
  
  def to_oi18 str
    step_oi18(to_oi17 str)
  end
  
  def test_oi_eighteen
    test_words = [
      { w: "factum",    ipa: "fɑɛ̯tɔ",   orth: "faeto"   },
      { w: "pectum",    ipa: "pɛjtɔ",   orth: "peito"   },
      { w: "cunīculum", ipa: "kɔnejlɔ", orth: "conéilo" },
      { w: "oculum",    ipa: "ɔɛ̯lɔ",    orth: "oelo"    },
      { w: "būculum",   ipa: "bojlɔ",   orth: "bóilo"   }
    ]
    
    test_words.each do |word|
      xform = to_oi18 word[:w]
      assert_equal word[:ipa], ipa(xform)
      assert_equal word[:orth], xform.join
    end    
  end  
  
  def to_oi19 str
    step_oi19(to_oi18 str)
  end
  
  def test_oi_nineteen
    test_words = [
      { w: "laxum",     ipa: "lɑɛ̯sɔ",    orth: "laesso"   },
      { w: "mixtum",    ipa: "mɛjstɔ",   orth: "meisto"   },
      { w: "salsīciam", ipa: "sɑssiʃʃɑ", orth: "sassisça" },
      { w: "coxam",     ipa: "kɔɛ̯sɑ",    orth: "coessa"   },
      { w: "dūcem",     ipa: "duʃʃɛ",    orth: "dusce"    },
      { w: "eccistum",  ipa: "ɛttʃestɔ", orth: "eccésto"  }
      #{ w: "pensāre",   ipa: "pɛssɑrɛ",  orth: "pessare"  }   # Pensare no longer a good example, becomes pēsare earlier
    ]
    
    test_words.each do |word|
      xform = to_oi19 word[:w]
      assert_equal word[:ipa], ipa(xform)
      assert_equal word[:orth], xform.join
    end    
  end  
  
  def to_oi20 str
    step_oi20(to_oi19 str)
  end
  
  def test_oi_twenty
    test_words = [
      { w: "volēre",   ipa: "valerɛ",  orth: "vàlére"   },
      { w: "aucellam", ipa: "ɔʃʃɛʎɑ",  orth: "oscella"   },
      { w: "scūppīre", ipa: "skœpirɛ", orth: "squeupire"   }
    ]
    
    test_words.each do |word|
      xform = to_oi20 word[:w]
      assert_equal word[:ipa], ipa(xform)
      assert_equal word[:orth], xform.join
    end    
  end  
  
  def to_oi21 str
    step_oi21(to_oi20 str)
  end
  
  def test_oi_twenty_one
    test_words = [
      { w: "montāneam", ipa: "mɔntaɲɑ", orth: "montànha" },
      { w: "illum",     ipa: "iʎɔ",     orth: "illo"     },
      { w: "collum",    ipa: "kœʎɔ",    orth: "queullo"  }
    ]
    
    test_words.each do |word|
      xform = to_oi21 word[:w]
      assert_equal word[:ipa], ipa(xform)
      assert_equal word[:orth], xform.join
    end    
  end  
  
  def to_oi22 str
    step_oi22(to_oi21 str)
  end
  
  def test_oi_twenty_two
    test_words = [
      { w: "caldāriam", ipa: "kɑldarɑ", orth: "caldàira" },
      { w: "imperium",  ipa: "ɛmpɛrɔ",  orth: "empeiro"  },
      { w: "glōria",    ipa: "glœrɑ",   orth: "gleura"  }
    ]
    
    test_words.each do |word|
      xform = to_oi22 word[:w]
      assert_equal word[:ipa], ipa(xform)
      assert_equal word[:orth], xform.join
    end    
  end  
  
  def to_oi23 str
    step_oi23(to_oi22 str)
  end
  
  def test_oi_twenty_three
    grandis = to_oi23 "grandem"
    assert_equal "grandɛ", ipa(grandis)
    assert_equal "grànde", grandis.join 
  end
  
  def to_oi24 str
    step_oi24(to_oi23 str)
  end
  
  def test_oi_twenty_four
    test_words = [
      { w: "tempus",   ipa: "tjɛmpɔs", orth: "tiempos" },
      { w: "sapēre",   ipa: "sɑbjerɛ", orth: "sabiére" },
      { w: "longum",   ipa: "lwɛngɔ",  orth: "luengo"  },
      { w: "dē post",  ipa: "dɛbɔjs",  orth: "debois"  },
      { w: "causam",   ipa: "kuzɑ",    orth: "cuosa"   },
      { w: "caecum",   ipa: "tʃɛgɔ",   orth: "cego"    },
      { w: "muljērem", ipa: "maʎerɛ",  orth: "màllére" },
      { w: "gustum",   ipa: "gustɔ",   orth: "guosto"  }
    ]
    
    test_words.each do |word|
      xform = to_oi24 word[:w]
      assert_equal word[:ipa], ipa(xform)
      assert_equal word[:orth], xform.join
    end    
  end  
  
  def to_oi25 str
    step_oi25(to_oi24 str)
  end
  
  def test_oi_twenty_five
    furnus = to_oi25 "furnum"
    assert_equal "hornɔ", ipa(furnus)
    assert_equal "hórno", furnus.join 
  end

  def to_oi26 str
    step_oi26(to_oi25 str)
  end
  
  def test_oi_twenty_six
    unus = to_oi26 "ūnum"
    assert_equal "un", ipa(unus)
    assert_equal "un", unus.join 

    radix = to_oi26 "rādīcem"
    assert_equal "raiʃʃə", ipa(radix)
    assert_equal "ràisce", radix.join 

    piscis = to_oi26 "piscem"
    assert_equal "pjestʃə", ipa(piscis)
    assert_equal "piésce", piscis.join 

    aut = to_oi26 "aut"
    assert_equal "ɔ", ipa(aut)
    assert_equal "o", aut.join 
  end

  def to_oi27 str
    step_oi27(to_oi26 str)
  end
  
  def test_oi_twenty_seven
    causa = to_oi27 "causam"
    assert_equal "kuzə", ipa(causa)
    assert_equal "cuose", causa.join 

    bucca = to_oi27 "buccam"
    assert_equal "bukə", ipa(bucca)
    assert_equal "buoque", bucca.join 
  end

  def to_oi28 str
    step_oi28(to_oi27 str)
  end
  
  def test_oi_twenty_eight
    ornamentum = to_oi28 "ornāmentum"
    assert_equal "ɔrnəmjɛnt", ipa(ornamentum)
    assert_equal "ornemient", ornamentum.join 
  end

  def to_oi29 str
    step_oi29(to_oi28 str)
  end
  
  def test_oi_twenty_nine
    veritas = to_oi29 "veritātem"
    assert_equal "vɛrlɑd", ipa(veritas)
    assert_equal "verlad", veritas.join 

    placeamus = to_oi29 "placēāmus"
    assert_equal "plɑʃʃɑms", ipa(placeamus)
    assert_equal "plasçams", placeamus.join 

    placessemus = to_oi29 "placēssēmus"
    assert_equal "plɑʃʃəsems", ipa(placessemus)
    assert_equal "plascesséms", placessemus.join 

    misculatus = to_oi29 "misculātum"
    assert_equal "mɛskədɑl", ipa(misculatus)
    assert_equal "mesquedal", misculatus.join 
  end

  def to_oix2 str
    step_oix2(to_oi29 str)  # skipping OIx1 for now
  end
  
  def test_oi_ecksty_two
    historia = to_oix2 "historiam"
    assert_equal "stœr", ipa(historia)
    assert_equal "steur", historia.join 

    infans = to_oix2 "infantem"
    assert_equal "əmfɑnt", ipa(infans)
    assert_equal "enfant", infans.join 
  end

  def to_oix3 str
    step_oix3(to_oix2 str)  
  end
  
  def test_oi_ecksty_three
    imperium = to_oix3 "imperium"
    assert_equal "əw̃pɛr", ipa(imperium)
    assert_equal "eũpeir", imperium.join 
  end

  def to_oix4 str
    step_oix4(to_oix3 str)  
  end
  
  def test_oi_ecksty_four
    caldaria = to_oix4 "caldāriam"
    assert_equal "kɑwdar", ipa(caldaria)
    assert_equal "caudàir", caldaria.join 

    arbor = to_oix4 "arborem"
    assert_equal "ɑwrrə", ipa(arbor)
    assert_equal "aurre", arbor.join 

    serpens = to_oix4 "serpentem"
    assert_equal "sɛrpjɛnt", ipa(serpens)
    assert_equal "serpient", serpens.join 
  end

  def to_oix5 str
    step_oix5(to_oix4 str)  
  end
  
  def test_oi_ecksty_five
    caldaria = to_oix5 "caldāriam"
    assert_equal "kodar", ipa(caldaria)
    assert_equal "caudàir", caldaria.join 
  end

  def to_oix6 str
    step_oix6(to_oix5 str)  
  end
  
  def test_oi_ecksty_six
    maritus = to_oix6 "marītum"
    assert_equal "mɑry", ipa(maritus)
    assert_equal "mariu", maritus.join 
  end

  def to_oix7 str
    step_oix7(to_oix6 str)  
  end
  
  def test_oi_ecksty_seven
    tempus = to_oix7 "tempum"
    assert_equal "tjɛw̃", ipa(tempus)
    assert_equal "tiew̃", tempus.join 
  end

  def to_CI1 str
    step_ci1(to_oix7 str)  
  end

  def to_CI2 str
    step_ci2(to_CI1 str)  
  end

  def to_CI3 str
    step_ci3(to_CI2 str)  
  end

  def test_CI3
    sanguis = to_CI3 "sanguem"
    assert_equal "zɑ̃g", ipa(sanguis)
    assert_equal "sang", sanguis.join     

    semen = to_CI3 "sēminem"
    assert_equal "zønə", ipa(semen)
    assert_equal "séũne", semen.join     

    vermis = to_CI3 "vermem"
    assert_equal "vjœr", ipa(vermis)
    assert_equal "vieũr", vermis.join     
  end

  def to_CI4 str
    step_ci4(to_CI3 str)  
  end

  def to_CI5 str
    step_ci5(to_CI4 str)  
  end

  def to_CI6 str
    step_ci6(to_CI5 str)  
  end

  def to_ci7 str
    step_ci7(to_CI6 str)  
  end

  def to_CI8 str
    step_ci8(to_ci7 str)  
  end
  
  def test_CI8
    herba = to_CI8 "herbam"
    assert_equal "jɛrbə", ipa(herba)
    assert_equal "yerbe", herba.join         
  end

  def to_ri1 str
    step_ri1(to_CI8 str)  
  end

  def to_ri2 str
    step_ri2(to_ri1 str)  
  end

  def test_ri2
    folia = to_ri2 "foliam"
    assert_equal "hœʝə", ipa(folia)
    assert_equal "heulle", folia.join         
  end

  def to_ri3 str
    step_ri3(to_ri2 str)  
  end

  def to_ri4 str
    step_ri4(to_ri3 str)  
  end

  def to_ri5 str
    step_ri5(to_ri4 str)  
  end

  def to_ri6 str
    step_ri6(to_ri5 str)  
  end

  def to_ri7 str
    step_ri7(to_ri6 str)  
  end

  def to_ri8 str
    step_ri8(to_ri7 str)  
  end

  def to_ri9 str
    step_ri9(to_ri8 str)  
  end

  def to_ri10 str
    step_ri10(to_ri9 str)  
  end
  
  def test_ri10
    placeant = to_ri10 "placēant"
    assert_equal "plɑʒʒe", ipa(placeant)
    assert_equal "plascéen", placeant.join  
  end

  def to_ri11 str
    step_ri11(to_ri10 str)  
  end

  def to_ri12 str
    step_ri12(to_ri11 str)  
  end

  def to_ri13 str
    step_ri13(to_ri12 str)  
  end

  def to_ri14 str
    step_ri14(to_ri13 str)  
  end

  def to_ri_cyrl str
    cyrillize(to_ri14 str)
  end
  
  def test_cyrillic
    que = to_ri_cyrl("quid")
    assert_equal "ч", que
  end

  def to_pi1 str
    step_pi1(to_CI8 str)  
  end

  def to_pi2 str
    step_pi2(to_pi1 str)  
  end

  def to_pi3 str
    step_pi3(to_pi2 str)  
  end
  
  def test_pi3 
    piscis = to_pi3 "piscem"
    assert_equal "pjɛçə", ipa(piscis)
    assert_equal "piêce", piscis.join
  end

  def to_pi4 str
    step_pi4(to_pi3 str)  
  end

  def test_pi4
    mulier = to_pi4 "muljērem"
    assert_equal "mæir", ipa(mulier)
    assert_equal "màyr", mulier.join
  end

  def to_pi5 str
    step_pi5(to_pi4 str)  
  end
  
  def test_pi5
    sentire = to_pi5 "sentīre"
    assert_equal "zə̃tir", ipa(sentire)
    assert_equal "sentir", sentire.join

    placessemus = to_pi5 "placēssēmus"
    assert_equal "pləʒʒəzøs", ipa(placessemus)
    assert_equal "plascesséũs", placessemus.join
  end  

  def to_pi6 str
    step_pi6(to_pi5 str)  
  end

  def test_pi6
    que = to_pi6 "quid"
    assert_equal "tʃə", ipa(que)
    assert_equal "che", que.join
  end

  def to_pi7 str
    step_pi7(to_pi6 str)  
  end

  def to_pi8 str
    step_pi8(to_pi7 str)  
  end

  def to_pi9 str
    step_pi9(to_pi8 str)  
  end
  
  def test_pi9
    fructus = to_pi9 "frūctum"
    assert_equal "vrɔjt", ipa(fructus)
    assert_equal "vroit", fructus.join
  end

  def to_pi10 str
    step_pi10(to_pi9 str)  
  end
  
  def test_consistency
    latin_words = [
      { w: "ab ante", RI_IPA: "ɑˈvɑ̃t", RI_Cyrl: "авант", RI_Latn: "avant", PI_IPA: "əˈvɑ̃t", PI: "avant" },
      { w: "ācrum", RI_IPA: "ɑgʲr", RI_Cyrl: "агр", RI_Latn: "agre", PI_IPA: "ˈɑxrə", PI: "agră" },
      { w: "acūtum", RI_IPA: "ɑˈgʲuː", RI_Cyrl: "агӯ", RI_Latn: "aguu", PI_IPA: "əˈxuː", PI: "aguu" },
      { w: "ad", RI_IPA: "ɑ", RI_Cyrl: "а", RI_Latn: "a", PI_IPA: "ɑ", PI: "a" },
      { w: "ad hōram", RI_IPA: "ɑˈuːr", RI_Cyrl: "аӯр", RI_Latn: "auor", PI_IPA: "əˈuːr", PI: "auor" },
      { w: "affīlātum", RI_IPA: "oːvəˈdoː", RI_Cyrl: "ѡ̄въдѡ̄", RI_Latn: "aufedau", PI_IPA: "oːvəˈdoː", PI: "aufedau" },
      { w: "ālam", RI_IPA: "ɑl", RI_Cyrl: "ал", RI_Latn: "ale", PI_IPA: "ˈɑlə", PI: "ală" },
      { w: "allium", RI_IPA: "ajj", RI_Cyrl: "яјј", RI_Latn: "àlli", PI_IPA: "æjj", PI: "àyy" },
      { w: "alēnāre", RI_IPA: "oːˈnɑr", RI_Cyrl: "ѡ̄нар", RI_Latn: "aunar", PI_IPA: "oːˈnɑr", PI: "aunar" },
      { w: "alterum", RI_IPA: "aːtr", RI_Cyrl: "я̄тр", RI_Latn: "aetre", PI_IPA: "ˈɑjtrə", PI: "aetră" },
      { w: "amāre", RI_IPA: "ɑˈmɑr", RI_Cyrl: "амар", RI_Latn: "amar", PI_IPA: "əˈmɑr", PI: "amar" },
      { w: "anellum", RI_IPA: "ɑˈniː", RI_Cyrl: "ані̄", RI_Latn: "anill", PI_IPA: "əˈniː", PI: "any" },
      { w: "anīsum", RI_IPA: "ɑˈniʰ", RI_Cyrl: "ані’", RI_Latn: "anis", PI_IPA: "əˈnis", PI: "anis" },
      { w: "annum", RI_IPA: "aɲ", RI_Cyrl: "яњ", RI_Latn: "ành", PI_IPA: "æɲ", PI: "ành" },
      { w: "aperīre", RI_IPA: "oːˈrir", RI_Cyrl: "ѡ̄рір", RI_Latn: "aurir", PI_IPA: "oːˈrir", PI: "aurir" },
      { w: "apertūram", RI_IPA: "ɑbərˈtyr", RI_Cyrl: "абъртүр", RI_Latn: "abertur", PI_IPA: "əbərˈtyr", PI: "abertur" },
      { w: "apicula", RI_IPA: "ɑˈbɛjl", RI_Cyrl: "абејл", RI_Latn: "abeile", PI_IPA: "əˈbɛjlə", PI: "abeilă" },
      { w: "aquam", RI_IPA: "ɑgʲ", RI_Cyrl: "аг", RI_Latn: "ague", PI_IPA: "ˈɑxə", PI: "agă" },
      { w: "arausiōnem", RI_IPA: "ɑrəˈʒʒũː", RI_Cyrl: "аръжжӯн", RI_Latn: "aresçuon", PI_IPA: "ərəˈʒʒũː", PI: "aresçuon" },
      { w: "aut", RI_IPA: "ɔ", RI_Cyrl: "о", RI_Latn: "o", PI_IPA: "ɔ", PI: "o" },
      { w: "animālem", RI_IPA: "ɑ̃ˈmoː", RI_Cyrl: "анмѡ̄", RI_Latn: "ammau", PI_IPA: "ə̃ˈmoː", PI: "ammau" },
      { w: "apostolum", RI_IPA: "ɑˈbœjttr", RI_Cyrl: "абөјттр", RI_Latn: "aboistre", PI_IPA: "əˈbɔjtrə", PI: "aboîtră" },
      { w: "arborem", RI_IPA: "oːrr", RI_Cyrl: "ѡ̄рр", RI_Latn: "aurre", PI_IPA: "ˈoːrrə", PI: "aurră" },
      { w: "arcum", RI_IPA: "ɑrkʲ", RI_Cyrl: "арк", RI_Latn: "arc", PI_IPA: "ɑrk", PI: "arc" },
      { w: "auca", RI_IPA: "uːdʒ", RI_Cyrl: "ӯџ", RI_Latn: "uogue", PI_IPA: "ˈuːdʒə", PI: "uodjă" },
      { w: "aucellam", RI_IPA: "ɔˈʒʒiʝ", RI_Cyrl: "ожжіж", RI_Latn: "oscille", PI_IPA: "əˈʒʒijə", PI: "osciyă" },
      { w: "audīre", RI_IPA: "ɔˈʝir", RI_Cyrl: "ожір", RI_Latn: "oyr", PI_IPA: "əˈjir", PI: "oyr" },
      { w: "auriculam", RI_IPA: "aˈrɛjl", RI_Cyrl: "ярејл", RI_Latn: "àreile", PI_IPA: "əˈrɛjlə", PI: "àreilă" }, #
      { w: "bastōnem", RI_IPA: "bɑtˈtũː", RI_Cyrl: "баттӯн", RI_Latn: "bastuon", PI_IPA: "bəˈtũː", PI: "bâtuon" },
      { w: "battēre", RI_IPA: "bɑˈcçer", RI_Cyrl: "батјир", RI_Latn: "batiér", PI_IPA: "bəˈtir", PI: "batir" },
      { w: "bestia", RI_IPA: "bjɛçç", RI_Cyrl: "бјешш", RI_Latn: "biesçe", PI_IPA: "ˈbjɛçə", PI: "biêçă" },
      { w: "bestjōla", RI_IPA: "bɛçˈçuːl", RI_Cyrl: "бешшӯл", RI_Latn: "besçuole", PI_IPA: "bəˈçuːlə", PI: "bêçuolă" },
      { w: "bibēre", RI_IPA: "bœːˈʝer", RI_Cyrl: "бө̄жир", RI_Latn: "beuyér", PI_IPA: "bœːˈir", PI: "beuyr" },
      { w: "blankum", RI_IPA: "blɑ̃kʲ", RI_Cyrl: "бланк", RI_Latn: "blanc", PI_IPA: "blɑ̃k", PI: "blanc" },
      { w: "bonum", RI_IPA: "bœjn", RI_Cyrl: "бөјн", RI_Latn: "boin", PI_IPA: "bɔjn", PI: "boin" },
      { w: "brāchium", RI_IPA: "braːʃ", RI_Cyrl: "бря̄ш", RI_Latn: "braeç", PI_IPA: "brɑjʃ", PI: "braeç" },
      { w: "brūmam", RI_IPA: "brym", RI_Cyrl: "брүм", RI_Latn: "brume", PI_IPA: "ˈbrymə", PI: "brumă" },
      { w: "buccam", RI_IPA: "buːtʃ", RI_Cyrl: "бӯч", RI_Latn: "buoque", PI_IPA: "ˈbuːtʃə", PI: "buochă" },
      { w: "būffāre", RI_IPA: "buːˈvɑr", RI_Cyrl: "бӯвар", RI_Latn: "buufar", PI_IPA: "buːˈvɑr", PI: "buufar" },
      { w: "buscum", RI_IPA: "buːkʲkʲ", RI_Cyrl: "бӯкк", RI_Latn: "buosc", PI_IPA: "buːk", PI: "buôc" },
      { w: "buttāre", RI_IPA: "bɔˈtɑr", RI_Cyrl: "ботар", RI_Latn: "botar", PI_IPA: "bəˈtɑr", PI: "botar" },
      { w: "caldāriam", RI_IPA: "tʃoːˈdaːr", RI_Cyrl: "чѡ̄дя̄р", RI_Latn: "caudàir", PI_IPA: "tʃoːˈdæːr", PI: "chaudàir" },
      { w: "calidum", RI_IPA: "tʃaːt", RI_Cyrl: "чя̄т", RI_Latn: "caed", PI_IPA: "tʃɑjd", PI: "chaed" },
      { w: "cambam", RI_IPA: "tʃoːb", RI_Cyrl: "чѡ̄б", RI_Latn: "caũbe", PI_IPA: "ˈtʃoːbə", PI: "chaubă" },
      { w: "cammīnum", RI_IPA: "tʃoːˈmĩ", RI_Cyrl: "чѡ̄мін", RI_Latn: "caũmin", PI_IPA: "tʃoːˈmɛ̃", PI: "chaumin" },
      { w: "cantjōnem", RI_IPA: "tʃɑ̃ˈçũː", RI_Cyrl: "чаншӯн", RI_Latn: "cançuon", PI_IPA: "tʃə̃ˈçũː", PI: "chançuon" },
      { w: "capparem", RI_IPA: "tʃoːr", RI_Cyrl: "чѡ̄р", RI_Latn: "caure", PI_IPA: "ˈtʃoːrə", PI: "chaură" },
      { w: "cappum", RI_IPA: "tʃoː", RI_Cyrl: "чѡ̄", RI_Latn: "cau", PI_IPA: "tʃoː", PI: "chau" },
      { w: "capillum", RI_IPA: "tʃɑˈbiː", RI_Cyrl: "чабі̄", RI_Latn: "cabill", PI_IPA: "tʃəˈbiː", PI: "chaby" },
      { w: "captjāre", RI_IPA: "tʃoːˈçɑr", RI_Cyrl: "чѡ̄шар", RI_Latn: "cauçar", PI_IPA: "tʃoːˈçɑr", PI: "chauçar" },
      { w: "carnem", RI_IPA: "tʃɑrn", RI_Cyrl: "чарн", RI_Latn: "carn", PI_IPA: "tʃɑrn", PI: "charn" },
      { w: "canem", RI_IPA: "tʃɑ̃", RI_Cyrl: "чан", RI_Latn: "can", PI_IPA: "tʃɑ̃", PI: "chan" },
      { w: "cantāre", RI_IPA: "tʃɑ̃ˈtɑr", RI_Cyrl: "чантар", RI_Latn: "cantar", PI_IPA: "tʃə̃ˈtɑr", PI: "chantar" },
      { w: "cattāria", RI_IPA: "tʃɑˈtaːr", RI_Cyrl: "чатя̄р", RI_Latn: "catàir", PI_IPA: "tʃəˈtæːr", PI: "chatàir" },
      { w: "cattum", RI_IPA: "tʃɑt", RI_Cyrl: "чат", RI_Latn: "cat", PI_IPA: "tʃɑt", PI: "chat" },
      { w: "caudam", RI_IPA: "kʲuː", RI_Cyrl: "кӯ", RI_Latn: "cuoe", PI_IPA: "ˈkuːə", PI: "cuoă" },
      { w: "causam", RI_IPA: "kʲuːz", RI_Cyrl: "кӯз", RI_Latn: "cuose", PI_IPA: "ˈkuːzə", PI: "cuosă" },
      { w: "cavāre", RI_IPA: "tʃɑˈvɑr", RI_Cyrl: "чавар", RI_Latn: "cavar", PI_IPA: "tʃəˈvɑr", PI: "chavar" },
      { w: "centum", RI_IPA: "çɛ̃t", RI_Cyrl: "шент", RI_Latn: "cent", PI_IPA: "çɛ̃t", PI: "cent" },
      { w: "cēpullitta", RI_IPA: "çœːˈʝet", RI_Cyrl: "шө̄жит", RI_Latn: "ceulléte", PI_IPA: "çœːˈjetə", PI: "ceuyétă" },
      { w: "chordam", RI_IPA: "kʲwɛrd", RI_Cyrl: "куерд", RI_Latn: "cuerde", PI_IPA: "ˈkwɛrdə", PI: "cuerdă" },
      { w: "cinerem", RI_IPA: "çẽr", RI_Cyrl: "шинр", RI_Latn: "cénre", PI_IPA: "ˈçẽrə", PI: "cénră" },
      { w: "cīnquāintā<", RI_IPA: "çĩˈkʲɑ̃t", RI_Cyrl: "шінкант", RI_Latn: "cinquante", PI_IPA: "çə̃ˈkɑ̃tə", PI: "cincantă" },
      { w: "cīnque", RI_IPA: "çĩtʃ", RI_Cyrl: "шінч", RI_Latn: "cinc", PI_IPA: "çɛ̃tʃ", PI: "cinch" },
      { w: "circulum", RI_IPA: "çerkʲl", RI_Cyrl: "ширкл", RI_Latn: "cércle", PI_IPA: "ˈçerklə", PI: "cérclă" },
      { w: "clāvum", RI_IPA: "kʲloː", RI_Cyrl: "клѡ̄", RI_Latn: "clau", PI_IPA: "kloː", PI: "clau" },
      { w: "coācticāre", RI_IPA: "kʲɔəttəˈdʒɑr", RI_Cyrl: "коъттъџар", RI_Latn: "coettegar", PI_IPA: "kɔːəttəˈdʒɑr", PI: "coettedjar" },
      { w: "cōlāre", RI_IPA: "kʲɔˈlɑr", RI_Cyrl: "колар", RI_Latn: "colar", PI_IPA: "kəˈlɑr", PI: "colar" },
      { w: "collum", RI_IPA: "kʲœj", RI_Cyrl: "көј", RI_Latn: "queull", PI_IPA: "kœj", PI: "queuy" },
      { w: "cognoscēre", RI_IPA: "kʲœɲəçˈçer", RI_Cyrl: "көњъшшир", RI_Latn: "queunhescér", PI_IPA: "kəɲəˈçer", PI: "queunhêcér" },
      { w: "comedēre", RI_IPA: "kʲoːˈʝer", RI_Cyrl: "кѡ̄жир", RI_Latn: "càũyér", PI_IPA: "koːˈir", PI: "cauyr" },
      { w: "comintjāre", RI_IPA: "kʲamə̃ˈçɑr", RI_Cyrl: "кямъншар", RI_Latn: "càmençar", PI_IPA: "kəmə̃ˈçɑr", PI: "càmençar" },
      { w: "conflāre", RI_IPA: "kʲɔwˈlɑr", RI_Cyrl: "коулар", RI_Latn: "cow̃lar", PI_IPA: "kəwˈlɑr", PI: "cowlar" },
      { w: "cōsēre", RI_IPA: "kʲaˈzer", RI_Cyrl: "кязир", RI_Latn: "càsér", PI_IPA: "kəˈzer", PI: "càsér" },
      { w: "contāre", RI_IPA: "kʲɔ̃ˈtɑr", RI_Cyrl: "контар", RI_Latn: "contar", PI_IPA: "kə̃ˈtɑr", PI: "contar" },
      { w: "cordem", RI_IPA: "kʲwɛrt", RI_Cyrl: "куерт", RI_Latn: "cuerd", PI_IPA: "kwɛrd", PI: "cuerd" },
      { w: "cornum", RI_IPA: "kʲwɛrn", RI_Cyrl: "куерн", RI_Latn: "cuern", PI_IPA: "kwɛrn", PI: "cuern" },
      { w: "corpum", RI_IPA: "kʲœːr", RI_Cyrl: "кө̄р", RI_Latn: "cueur", PI_IPA: "kwœːr", PI: "cueur" },
      { w: "correctum", RI_IPA: "kʲaˈrɛjt", RI_Cyrl: "кярејт", RI_Latn: "càreit", PI_IPA: "kəˈrɛjt", PI: "càreit" },
      { w: "corticem", RI_IPA: "kʲwɛrç", RI_Cyrl: "куерш", RI_Latn: "cuerç", PI_IPA: "kwɛrç", PI: "cuerç" },
      { w: "coxam", RI_IPA: "kʲɔːz", RI_Cyrl: "ко̄з", RI_Latn: "coesse", PI_IPA: "ˈkɔjzə", PI: "coessă" },
      { w: "cremāre", RI_IPA: "kʲrɛˈmɑr", RI_Cyrl: "кремар", RI_Latn: "cremar", PI_IPA: "krəˈmɑr", PI: "cremar" },
      { w: "cremēre", RI_IPA: "kʲrœːˈʝer", RI_Cyrl: "крө̄жир", RI_Latn: "creũyér", PI_IPA: "krœːˈir", PI: "creuyr" },
      { w: "crucem", RI_IPA: "kʲrɔːʃ", RI_Cyrl: "кро̄ш", RI_Latn: "croeç", PI_IPA: "krɔjʃ", PI: "croeç" },
      { w: "cubitum", RI_IPA: "kʲoːt", RI_Cyrl: "кѡ̄т", RI_Latn: "cóute", PI_IPA: "ˈkoːtə", PI: "cóută" },
      { w: "cumīnum", RI_IPA: "kʲaˈmĩ", RI_Cyrl: "кямін", RI_Latn: "càmin", PI_IPA: "kəˈmɛ̃", PI: "càmin" },
      { w: "curtum", RI_IPA: "kʲort", RI_Cyrl: "кѡрт", RI_Latn: "córt", PI_IPA: "kort", PI: "córt" },
      { w: "cȳgnum", RI_IPA: "çiɲ", RI_Cyrl: "шіњ", RI_Latn: "cinh", PI_IPA: "çiɲ", PI: "cinh" },
      { w: "dē", RI_IPA: "d", RI_Cyrl: "д", RI_Latn: "de", PI_IPA: "də", PI: "de" },
      { w: "dē apud", RI_IPA: "dɛˈoː", RI_Cyrl: "деѡ̄", RI_Latn: "deau", PI_IPA: "dəˈoː", PI: "deau" },
      { w: "dē bassiō", RI_IPA: "dɛˈvaːʃ", RI_Cyrl: "девя̄ш", RI_Latn: "devaeç", PI_IPA: "dəˈvɑjʃ", PI: "devaeç" },
      { w: "dē intrō", RI_IPA: "dɛˈʝẽtr", RI_Cyrl: "дежинтр", RI_Latn: "deyéntre", PI_IPA: "dəˈĩtrə", PI: "deyntră" },
      { w: "dē post", RI_IPA: "dɛˈbœjʰ", RI_Cyrl: "дебөј’", RI_Latn: "debois", PI_IPA: "dəˈbɔjs", PI: "debois" },
      { w: "dēbēre", RI_IPA: "dœːˈʝer", RI_Cyrl: "дө̄жир", RI_Latn: "deuyér", PI_IPA: "dœːˈir", PI: "deuyr" },
      { w: "decem", RI_IPA: "dɛjʃ", RI_Cyrl: "дејш", RI_Latn: "deiç", PI_IPA: "dɛjʃ", PI: "deiç" },
      { w: "decem novem", RI_IPA: "dɛjˈʒnœj", RI_Cyrl: "дејжнөј", RI_Latn: "deiçnoyu", PI_IPA: "dəjˈʒnɔə", PI: "deiçnoă" },
      { w: "decem octō", RI_IPA: "dɛjˈʒɔːt", RI_Cyrl: "дејжо̄т", RI_Latn: "deiçoet", PI_IPA: "dəjˈʒɔjt", PI: "deiçoet" },
      { w: "decem septem", RI_IPA: "dɛjʒˈzœːt", RI_Cyrl: "дејжзө̄т", RI_Latn: "deiçseute", PI_IPA: "dəjʒˈzœːtə", PI: "deiçseută" },
      { w: "decimum sextum", RI_IPA: "dœjˈzɛjtt", RI_Cyrl: "дөјзејтт", RI_Latn: "deyũseist", PI_IPA: "dɛːəˈzɛjt", PI: "deyaseît" },
      { w: "dehus", RI_IPA: "ɟʝɛʰ", RI_Cyrl: "дје’", RI_Latn: "dies", PI_IPA: "djɛs", PI: "dies" },
      { w: "dentem", RI_IPA: "ɟʝɛ̃t", RI_Cyrl: "дјент", RI_Latn: "dient", PI_IPA: "djɛ̃t", PI: "dient" },
      { w: "dērectam", RI_IPA: "dɛˈrɛjt", RI_Cyrl: "дерејт", RI_Latn: "dereite", PI_IPA: "dəˈrɛjtə", PI: "dereită" },
      { w: "dērectum", RI_IPA: "dɛˈrɛjt", RI_Cyrl: "дерејт", RI_Latn: "dereit", PI_IPA: "dəˈrɛjt", PI: "dereit" },
      { w: "dēsertāre", RI_IPA: "dɛzərˈtɑr", RI_Cyrl: "дезъртар", RI_Latn: "desertar", PI_IPA: "dəzərˈtɑr", PI: "desertar" },
      { w: "dīcēre", RI_IPA: "diˈʒʒer", RI_Cyrl: "діжжир", RI_Latn: "discér", PI_IPA: "dəˈʒʒer", PI: "discér" },
      { w: "digitum", RI_IPA: "dɛjt", RI_Cyrl: "дејт", RI_Latn: "deit", PI_IPA: "dɛjt", PI: "deit" },
      { w: "dīrectjōnem", RI_IPA: "dirəˈtʃũː", RI_Cyrl: "діръчӯн", RI_Latn: "direççuon", PI_IPA: "dərəˈtʃũː", PI: "direççuon" },
      { w: "djurnum", RI_IPA: "ʝorn", RI_Cyrl: "жѡрн", RI_Latn: "jórn", PI_IPA: "ʝorn", PI: "jórn" },
      { w: "dodecim", RI_IPA: "dɔːʃ", RI_Cyrl: "до̄ш", RI_Latn: "doeç", PI_IPA: "dɔjʃ", PI: "doeç" },
      { w: "dormīre", RI_IPA: "dɔrˈmir", RI_Cyrl: "дормір", RI_Latn: "dormir", PI_IPA: "dərˈmir", PI: "dormir" },
      { w: "dorsum", RI_IPA: "dwɛrs", RI_Cyrl: "дуерс", RI_Latn: "duers", PI_IPA: "dwɛrs", PI: "duers" },
      { w: "duōs", RI_IPA: "duːʰ", RI_Cyrl: "дӯ’", RI_Latn: "duos", PI_IPA: "duːs", PI: "duos" },
      { w: "ducem", RI_IPA: "dɔːʃ", RI_Cyrl: "до̄ш", RI_Latn: "doeç", PI_IPA: "dɔjʃ", PI: "doeç" },
      { w: "dulcem", RI_IPA: "dɔːç", RI_Cyrl: "до̄ш", RI_Latn: "doeç", PI_IPA: "dɔjç", PI: "doeç" },
      { w: "dūrandum", RI_IPA: "dyˈrɐ̃t", RI_Cyrl: "дүрънт", RI_Latn: "durànd", PI_IPA: "dəˈræ̃d", PI: "durànd" },
      { w: "dūrāre", RI_IPA: "dyˈrɑr", RI_Cyrl: "дүрар", RI_Latn: "durar", PI_IPA: "dəˈrɑr", PI: "durar" },
      { w: "ecc hīc", RI_IPA: "ʒʒi", RI_Cyrl: "жжі", RI_Latn: "sci", PI_IPA: "ʒʒi", PI: "sci" },
      { w: "ecc illum", RI_IPA: "ʒʒiː", RI_Cyrl: "жжі̄", RI_Latn: "scill", PI_IPA: "ʒʒiː", PI: "scy" },
      { w: "ecc istum", RI_IPA: "ʒʒett", RI_Cyrl: "жжитт", RI_Latn: "scést", PI_IPA: "ʒʒɛt", PI: "scêt" },
      { w: "egō", RI_IPA: "ʝɛ", RI_Cyrl: "же", RI_Latn: "ye", PI_IPA: "jɛ", PI: "ye" },
      { w: "essēre", RI_IPA: "zer", RI_Cyrl: "зир", RI_Latn: "sér", PI_IPA: "zer", PI: "sér" },
      { w: "et", RI_IPA: "ɛ", RI_Cyrl: "е", RI_Latn: "e", PI_IPA: "ɛ", PI: "e" },
      { w: "exhortāre", RI_IPA: "zərˈtɑr", RI_Cyrl: "зъртар", RI_Latn: "sertar", PI_IPA: "zərˈtɑr", PI: "sertar" },
      { w: "exmūttiātum", RI_IPA: "zməˈtʃoː", RI_Cyrl: "змъчѡ̄", RI_Latn: "smetçau", PI_IPA: "zməˈtʃoː", PI: "smetçau" },
      { w: "exūcāre", RI_IPA: "zəˈdʒɑr", RI_Cyrl: "зъџар", RI_Latn: "segar", PI_IPA: "zəˈdʒɑr", PI: "sedjar" },
      { w: "fābulāre", RI_IPA: "voːˈlɑr", RI_Cyrl: "вѡ̄лар", RI_Latn: "faular", PI_IPA: "voːˈlɑr", PI: "faular" },
      { w: "facēre", RI_IPA: "vɑˈʒʒer", RI_Cyrl: "важжир", RI_Latn: "fascér", PI_IPA: "vəˈʒʒer", PI: "fascér" },
      { w: "farīna", RI_IPA: "vɑˈrin", RI_Cyrl: "варін’", RI_Latn: "farine", PI_IPA: "vəˈrinə", PI: "farină" },
      { w: "fēlīcem", RI_IPA: "vɛˈliʒʒ", RI_Cyrl: "веліжж", RI_Latn: "felisce", PI_IPA: "vəˈliʒʒə", PI: "felisçă" },
      { w: "fēminam", RI_IPA: "vjøːn", RI_Cyrl: "вјө̄н’", RI_Latn: "fiéũne", PI_IPA: "ˈvjøːnə", PI: "fiéună" },
      { w: "fēnuculum", RI_IPA: "vɛˈnɔː", RI_Cyrl: "вено̄", RI_Latn: "fenoeu", PI_IPA: "vəˈnɔə", PI: "fenoă" },
      { w: "fīcātum", RI_IPA: "viˈdʒoː", RI_Cyrl: "віџѡ̄", RI_Latn: "figau", PI_IPA: "vəˈdʒoː", PI: "fidjau" },
      { w: "fīlium", RI_IPA: "viː", RI_Cyrl: "ві̄", RI_Latn: "fill", PI_IPA: "viː", PI: "fy" },
      { w: "fīlum", RI_IPA: "vyː", RI_Cyrl: "вү̄", RI_Latn: "fiu", PI_IPA: "vyː", PI: "fiu" },
      { w: "fīnālem", RI_IPA: "viˈnoː", RI_Cyrl: "вінѡ̄", RI_Latn: "finau", PI_IPA: "vəˈnoː", PI: "finau" },
      { w: "findēre", RI_IPA: "vɛ̃ˈɟʝer", RI_Cyrl: "вендјир", RI_Latn: "fendiér", PI_IPA: "və̃ˈdir", PI: "fendir" },
      { w: "fīnem", RI_IPA: "vĩ", RI_Cyrl: "він", RI_Latn: "fin", PI_IPA: "vɛ̃", PI: "fin" },
      { w: "flōrem", RI_IPA: "vluːr", RI_Cyrl: "влӯр", RI_Latn: "vluor", PI_IPA: "vluːr", PI: "vluor" },
      { w: "fluctāre", RI_IPA: "vlɔtˈtɑr", RI_Cyrl: "влоттар", RI_Latn: "vlottar", PI_IPA: "vlətˈtɑr", PI: "vlottar" },
      { w: "focum", RI_IPA: "vœjkʲ", RI_Cyrl: "вөјк", RI_Latn: "foig", PI_IPA: "vɔjx", PI: "foig" },
      { w: "foliam", RI_IPA: "œʝ", RI_Cyrl: "өж", RI_Latn: "heulle", PI_IPA: "ˈhœjə", PI: "heuyă" },
      { w: "forestam", RI_IPA: "varˈʝɛtt", RI_Cyrl: "вяржетт", RI_Latn: "fàrieste", PI_IPA: "vəˈrjɛtə", PI: "fàriêtă" },
      { w: "formam", RI_IPA: "vwɛrm", RI_Cyrl: "вуерм", RI_Latn: "fuerme", PI_IPA: "ˈvwɛrmə", PI: "fuermă" },
      { w: "fortem", RI_IPA: "vwɛrt", RI_Cyrl: "вуерт", RI_Latn: "fuert", PI_IPA: "vwɛrt", PI: "fuert" },
      { w: "frictāre", RI_IPA: "vrɛtˈtɑr", RI_Cyrl: "вреттар", RI_Latn: "vrettar", PI_IPA: "vrətˈtɑr", PI: "vrettar" },
      { w: "frīgidum", RI_IPA: "vrɛjt", RI_Cyrl: "врејт", RI_Latn: "vréid", PI_IPA: "vrejd", PI: "vréid" },
      { w: "frittāre", RI_IPA: "vrɛˈtɑr", RI_Cyrl: "вретар", RI_Latn: "vretar", PI_IPA: "vrəˈtɑr", PI: "vretar" },
      { w: "frūctum", RI_IPA: "vrœjt", RI_Cyrl: "врөјт", RI_Latn: "vróit", PI_IPA: "vrɔjt", PI: "vroit" },
      { w: "fūmum", RI_IPA: "uː", RI_Cyrl: "ӯ", RI_Latn: "huũ", PI_IPA: "huː", PI: "huu" },
      { w: "furnum", RI_IPA: "orn", RI_Cyrl: "ѡрн", RI_Latn: "hórn", PI_IPA: "horn", PI: "hórn" },
      { w: "galbinum", RI_IPA: "dʒoːbn", RI_Cyrl: "џѡ̄бн", RI_Latn: "gaubne", PI_IPA: "ˈdʒoːbnə", PI: "djaubnă" },
      { w: "gelāre", RI_IPA: "ʝɛˈlɑr", RI_Cyrl: "желар", RI_Latn: "gelar", PI_IPA: "ʝəˈlɑr", PI: "gelar" },
      { w: "generem", RI_IPA: "ʝɛ̃r", RI_Cyrl: "женр", RI_Latn: "genre", PI_IPA: "ˈʝɛ̃rə", PI: "genră" },
      { w: "gentem", RI_IPA: "ʝɛ̃t", RI_Cyrl: "жент", RI_Latn: "gent", PI_IPA: "ʝɛ̃t", PI: "gent" },
      { w: "genūculum", RI_IPA: "ʝɛˈnœj", RI_Cyrl: "женөј", RI_Latn: "genóyu", PI_IPA: "ʝəˈnoə", PI: "genóa" },
      { w: "glaciem", RI_IPA: "gʲlaːʃ", RI_Cyrl: "гля̄ш", RI_Latn: "glaeç", PI_IPA: "xlɑjʃ", PI: "glaeç" },
      { w: "glōriam", RI_IPA: "gʲlœːr", RI_Cyrl: "глө̄р", RI_Latn: "gleur", PI_IPA: "xlœːr", PI: "gleur" },
      { w: "grandem", RI_IPA: "gʲrɐ̃t", RI_Cyrl: "грънт", RI_Latn: "grànd", PI_IPA: "xræ̃d", PI: "grànd" },
      { w: "grassiam", RI_IPA: "gʲraːʒ", RI_Cyrl: "гря̄ж", RI_Latn: "graeçe", PI_IPA: "ˈxrɑjʒə", PI: "graeçă" },
      { w: "grassum", RI_IPA: "gʲraʰ", RI_Cyrl: "гря’", RI_Latn: "gràss", PI_IPA: "xræs", PI: "gràss" },
      { w: "gustāre", RI_IPA: "gʲɔtˈtɑr", RI_Cyrl: "готтар", RI_Latn: "gostar", PI_IPA: "xəˈtɑr", PI: "gôtar" },
      { w: "gustum", RI_IPA: "gʲuːtt", RI_Cyrl: "гӯтт", RI_Latn: "guost", PI_IPA: "xuːt", PI: "guôt" },
      { w: "guttam", RI_IPA: "gʲuːt", RI_Cyrl: "гӯт", RI_Latn: "guote", PI_IPA: "ˈxuːtə", PI: "guotă" },
      { w: "habēre", RI_IPA: "oːˈʝer", RI_Cyrl: "ѡ̄жир", RI_Latn: "auyér", PI_IPA: "oːˈir", PI: "auyr" },
      { w: "habet ibī", RI_IPA: "oːˈʝøː", RI_Cyrl: "ѡ̄жө̄", RI_Latn: "auyéu", PI_IPA: "oːˈjøː", PI: "auyéu" },
      { w: "herbam", RI_IPA: "ʝɛrb", RI_Cyrl: "жерб", RI_Latn: "yerbe", PI_IPA: "ˈjɛrbə", PI: "yerbă" },
      { w: "hominem", RI_IPA: "œːn", RI_Cyrl: "ө̄н’", RI_Latn: "weũne", PI_IPA: "ˈwœːnə", PI: "weună" },
      { w: "illāc!", RI_IPA: "ʝɑ", RI_Cyrl: "жа", RI_Latn: "lla", PI_IPA: "jɑ", PI: "ya" },
      { w: "illa", RI_IPA: "iʝ", RI_Cyrl: "іж", RI_Latn: "ille", PI_IPA: "ˈijə", PI: "iyă" },
      { w: "ille", RI_IPA: "iː", RI_Cyrl: "і̄", RI_Latn: "ill", PI_IPA: "iː", PI: "y" },
      { w: "illās alterās", RI_IPA: "iʝəˈzaːtr", RI_Cyrl: "іжъзя̄тр", RI_Latn: "illesaetres", PI_IPA: "əjəˈzɑjtrəs", PI: "iyesaetrăs" },
      { w: "illōs alterōs", RI_IPA: "iːˈzaːtr", RI_Cyrl: "і̄зя̄тр", RI_Latn: "illsaetres", PI_IPA: "iːˈzɑjtrəs", PI: "ysaetrăs" },
      { w: "imperium", RI_IPA: "oːˈpɛːr", RI_Cyrl: "ѡ̄пе̄р", RI_Latn: "eũpeir", PI_IPA: "oːˈpɛːr", PI: "eupeir" },
      { w: "in", RI_IPA: "ɛ̃", RI_Cyrl: "ен", RI_Latn: "en", PI_IPA: "ɛ̃", PI: "en" },
      { w: "infantem", RI_IPA: "oːˈvɑ̃t", RI_Cyrl: "ѡ̄вант", RI_Latn: "eũfant", PI_IPA: "oːˈvɑ̃t", PI: "eufant" },
      { w: "inflāre", RI_IPA: "əwˈlɑr", RI_Cyrl: "ъулар", RI_Latn: "ew̃lar", PI_IPA: "əwˈlɑr", PI: "ewlar" },
      { w: "īsulam", RI_IPA: "izl", RI_Cyrl: "ізл", RI_Latn: "isle", PI_IPA: "ˈizlə", PI: "islă" },
      { w: "jacēre", RI_IPA: "ʝɑˈʒʒer", RI_Cyrl: "жажжир", RI_Latn: "jascér", PI_IPA: "ʝəˈʒʒer", PI: "jascér" },
      { w: "jocāre", RI_IPA: "ʝɔˈdʒɑr", RI_Cyrl: "жоџар", RI_Latn: "jogar", PI_IPA: "ʝəˈdʒɑr", PI: "jodjar" },
      { w: "lacum", RI_IPA: "lɑkʲ", RI_Cyrl: "лак", RI_Latn: "lag", PI_IPA: "lɑx", PI: "lag" },
      { w: "lactem", RI_IPA: "laːt", RI_Cyrl: "ля̄т", RI_Latn: "laet", PI_IPA: "lɑjt", PI: "laet" },
      { w: "lanceāre", RI_IPA: "lɑ̃ˈçɑr", RI_Cyrl: "ланшар", RI_Latn: "lançar", PI_IPA: "lə̃ˈçɑr", PI: "lançar" },
      { w: "largum", RI_IPA: "lɑrkʲ", RI_Cyrl: "ларк", RI_Latn: "larg", PI_IPA: "lɑrx", PI: "larg" },
      { w: "latum", RI_IPA: "loː", RI_Cyrl: "лѡ̄", RI_Latn: "lau", PI_IPA: "loː", PI: "lau" },
      { w: "lavāre", RI_IPA: "lɑˈvɑr", RI_Cyrl: "лавар", RI_Latn: "lavar", PI_IPA: "ləˈvɑr", PI: "lavar" },
      { w: "leōnem", RI_IPA: "lɛˈũː", RI_Cyrl: "леӯн", RI_Latn: "leuon", PI_IPA: "ləˈũː", PI: "leuon" },
      { w: "librum", RI_IPA: "ljøːr", RI_Cyrl: "лјө̄р", RI_Latn: "liéure", PI_IPA: "ˈljøːrə", PI: "liéură" },
      { w: "ligāre", RI_IPA: "lɛˈɑr", RI_Cyrl: "леар", RI_Latn: "lear", PI_IPA: "ləˈɑr", PI: "lear" },
      { w: "līneam", RI_IPA: "liɲ", RI_Cyrl: "ліњ", RI_Latn: "linhe", PI_IPA: "ˈliɲə", PI: "linhă" },
      { w: "linguam", RI_IPA: "ljẽgʲ", RI_Cyrl: "лјинг", RI_Latn: "liéngue", PI_IPA: "ˈljẽxə", PI: "liéngă" },
      { w: "locālem", RI_IPA: "lɔˈdʒoː", RI_Cyrl: "лоџѡ̄", RI_Latn: "logau", PI_IPA: "ləˈdʒoː", PI: "lodjau" },
      { w: "longē", RI_IPA: "lwɛ̃ʝ", RI_Cyrl: "луенж", RI_Latn: "luenz", PI_IPA: "lwɛ̃ʝ", PI: "luenz" },
      { w: "longum", RI_IPA: "lwɛ̃kʲ", RI_Cyrl: "луенк", RI_Latn: "lueng", PI_IPA: "lwɛ̃x", PI: "lueng" },
      { w: "lūcem", RI_IPA: "lyʒʒ", RI_Cyrl: "лүжж", RI_Latn: "lusce", PI_IPA: "ˈlyʒʒə", PI: "lusçă" },
      { w: "lūnam", RI_IPA: "lyn", RI_Cyrl: "лүн’", RI_Latn: "lune", PI_IPA: "ˈlynə", PI: "lună" },
      { w: "lūridum", RI_IPA: "lyrt", RI_Cyrl: "лүрт", RI_Latn: "lurd", PI_IPA: "lyrd", PI: "lurd" },
      { w: "magis", RI_IPA: "mɛjʰ", RI_Cyrl: "меј’", RI_Latn: "meis", PI_IPA: "mɛjs", PI: "meis" },
      { w: "mandūcāre", RI_IPA: "mɑ̃dəˈdʒɑr", RI_Cyrl: "мандъџар", RI_Latn: "mandegar", PI_IPA: "mə̃dəˈdʒɑr", PI: "mandedjar" },
      { w: "manum", RI_IPA: "mɑ̃", RI_Cyrl: "ман", RI_Latn: "man", PI_IPA: "mɑ̃", PI: "man" },
      { w: "marem", RI_IPA: "mɑr", RI_Cyrl: "мар", RI_Latn: "mar", PI_IPA: "mɑr", PI: "mar" },
      { w: "marītum", RI_IPA: "mɑˈryː", RI_Cyrl: "марү̄", RI_Latn: "mariu", PI_IPA: "məˈryː", PI: "mariu" },
      { w: "markāre", RI_IPA: "mɑrˈtʃɑr", RI_Cyrl: "марчар", RI_Latn: "marcar", PI_IPA: "mərˈtʃɑr", PI: "marchar" },
      { w: "marrītum", RI_IPA: "mɑˈryː", RI_Cyrl: "марү̄", RI_Latn: "mariu", PI_IPA: "məˈryː", PI: "mariu" },
      { w: "mātrem", RI_IPA: "mɑdr", RI_Cyrl: "мадр", RI_Latn: "madre", PI_IPA: "ˈmɑdrə", PI: "madră" },
      { w: "mehum", RI_IPA: "mjɛ", RI_Cyrl: "мје", RI_Latn: "mie", PI_IPA: "mjɛ", PI: "mie" },
      { w: "melem", RI_IPA: "mjœː", RI_Cyrl: "мјө̄", RI_Latn: "mieu", PI_IPA: "mjœː", PI: "mieu" },
      { w: "metipsimum", RI_IPA: "mœːˈʝøːzm", RI_Cyrl: "мө̄жө̄зм", RI_Latn: "meuyéusme", PI_IPA: "mœːˈjøːzmə", PI: "meuyéusmă" },
      { w: "mīle", RI_IPA: "myː", RI_Cyrl: "мү̄", RI_Latn: "miu", PI_IPA: "myː", PI: "miu" },
      { w: "minta", RI_IPA: "mjẽt", RI_Cyrl: "мјинт", RI_Latn: "miénte", PI_IPA: "ˈmjẽtə", PI: "miéntă" },
      { w: "misculātum", RI_IPA: "mɛkʲkʲəˈdoː", RI_Cyrl: "меккъдѡ̄", RI_Latn: "mesquedau", PI_IPA: "məkəˈdoː", PI: "mêquedau" },
      { w: "mixtum", RI_IPA: "mɛjtt", RI_Cyrl: "мејтт", RI_Latn: "meist", PI_IPA: "mɛjt", PI: "meît" },
      { w: "molliātum", RI_IPA: "mœjˈjoː", RI_Cyrl: "мөјјѡ̄", RI_Latn: "meulliau", PI_IPA: "məjˈjoː", PI: "meuyyau" },
      { w: "mōmentum", RI_IPA: "moːˈʝɛ̃t", RI_Cyrl: "мѡ̄жент", RI_Latn: "màũyent", PI_IPA: "moːˈjɛ̃t", PI: "mauyent" },
      { w: "montāniam", RI_IPA: "mɔ̃ˈtaɲ", RI_Cyrl: "монтяњ", RI_Latn: "montànhe", PI_IPA: "mə̃ˈtæɲə", PI: "montànhă" },
      { w: "mordēre", RI_IPA: "mɔrˈɟʝer", RI_Cyrl: "мордјир", RI_Latn: "mordiér", PI_IPA: "mərˈdir", PI: "mordir" },
      { w: "morjendum", RI_IPA: "mœːrˈʝɛ̃t", RI_Cyrl: "мө̄ржент", RI_Latn: "meuriend", PI_IPA: "mœːˈrjɛ̃d", PI: "meuriend" },
      { w: "morīre", RI_IPA: "maˈrir", RI_Cyrl: "мярір", RI_Latn: "màrir", PI_IPA: "məˈrir", PI: "màrir" },
      { w: "movēre", RI_IPA: "moːˈʝer", RI_Cyrl: "мѡ̄жир", RI_Latn: "màuyér", PI_IPA: "moːˈir", PI: "mauyr" },
      { w: "muljērem", RI_IPA: "maˈʝer", RI_Cyrl: "мяжир", RI_Latn: "màllér", PI_IPA: "məˈir", PI: "màyr" },
      { w: "multum", RI_IPA: "mɔːt", RI_Cyrl: "мо̄т", RI_Latn: "moet", PI_IPA: "mɔjt", PI: "moet" },
      { w: "munniōnem", RI_IPA: "mœˈɲũː", RI_Cyrl: "мөњӯн", RI_Latn: "meunhuon", PI_IPA: "məˈɲũː", PI: "meunhuon" },
      { w: "natāre", RI_IPA: "nɑˈlɑr", RI_Cyrl: "налар", RI_Latn: "nalar", PI_IPA: "nəˈlɑr", PI: "nalar" },
      { w: "nāsum", RI_IPA: "nɑʰ", RI_Cyrl: "на’", RI_Latn: "nas", PI_IPA: "nɑs", PI: "nas" }, # 
      { w: "nec", RI_IPA: "n", RI_Cyrl: "н", RI_Latn: "ne", PI_IPA: "nə", PI: "ne" },
      { w: "nigrum", RI_IPA: "njigʲr", RI_Cyrl: "нјігр", RI_Latn: "niégre", PI_IPA: "ˈnixrə", PI: "nigră" },
      { w: "nivem", RI_IPA: "njøː", RI_Cyrl: "нјө̄", RI_Latn: "niéu", PI_IPA: "njøː", PI: "niéu" },
      { w: "noctem", RI_IPA: "nɔːt", RI_Cyrl: "но̄т", RI_Latn: "noet", PI_IPA: "nɔjt", PI: "noet" },
      { w: "nōn", RI_IPA: "nɔ̃", RI_Cyrl: "нон", RI_Latn: "non", PI_IPA: "nɔ̃", PI: "non" },
      { w: "nōs alterōs", RI_IPA: "nɔˈzaːtr", RI_Cyrl: "нозя̄тр", RI_Latn: "nosaetres", PI_IPA: "nəˈzɑjtrəs", PI: "nosaetrăs" },
      { w: "nostrum", RI_IPA: "nœjttr", RI_Cyrl: "нөјттр", RI_Latn: "noistre", PI_IPA: "ˈnɔjtrə", PI: "noîtră" },
      { w: "novem", RI_IPA: "nœj", RI_Cyrl: "нөј", RI_Latn: "noyu", PI_IPA: "ˈnɔə", PI: "noă" },
      { w: "novum", RI_IPA: "nœj", RI_Cyrl: "нөј", RI_Latn: "noyu", PI_IPA: "ˈnɔə", PI: "noă" },
      { w: "nūbem", RI_IPA: "nuː", RI_Cyrl: "нӯ", RI_Latn: "nuu", PI_IPA: "nuː", PI: "nuu" },
      { w: "nūbilum", RI_IPA: "nuːl", RI_Cyrl: "нӯл", RI_Latn: "nuule", PI_IPA: "ˈnuːlə", PI: "nuulă" },
      { w: "obscūrum", RI_IPA: "oːkʲˈkʲyr", RI_Cyrl: "ѡ̄ккүр", RI_Latn: "ouscur", PI_IPA: "ɔːˈkyr", PI: "oûcur" },
      { w: "octō", RI_IPA: "ɔːt", RI_Cyrl: "о̄т", RI_Latn: "oet", PI_IPA: "ɔjt", PI: "oet" },
      { w: "oculum", RI_IPA: "ɔː", RI_Cyrl: "о̄", RI_Latn: "oeu", PI_IPA: "ˈɔə", PI: "oă" },
      { w: "olōrāre", RI_IPA: "oːˈrɑr", RI_Cyrl: "ѡ̄рар", RI_Latn: "ourar", PI_IPA: "oːˈrɑr", PI: "ourar" },
      { w: "orientem", RI_IPA: "œːrˈʝɛ̃t", RI_Cyrl: "ө̄ржент", RI_Latn: "eurient", PI_IPA: "œːˈrjɛ̃t", PI: "eurient" },
      { w: "ornāmentum", RI_IPA: "ɔrnoːˈʝɛ̃t", RI_Cyrl: "орнѡ̄жент", RI_Latn: "orneũyent", PI_IPA: "ərnoːˈjɛ̃t", PI: "orneuyent" },
      { w: "ossem", RI_IPA: "œjʰ", RI_Cyrl: "өј’", RI_Latn: "oiss", PI_IPA: "ɔjs", PI: "oiss" },
      { w: "ōvālem", RI_IPA: "ɔˈvoː", RI_Cyrl: "овѡ̄", RI_Latn: "ovau", PI_IPA: "əˈvoː", PI: "ovau" },
      { w: "ovum", RI_IPA: "œj", RI_Cyrl: "өј", RI_Latn: "oyu", PI_IPA: "ˈɔə", PI: "oă" },
      { w: "pānem", RI_IPA: "pɑ̃", RI_Cyrl: "пан", RI_Latn: "pan", PI_IPA: "pɑ̃", PI: "pan" },
      { w: "partem", RI_IPA: "pɑrt", RI_Cyrl: "парт", RI_Latn: "part", PI_IPA: "pɑrt", PI: "part" },
      { w: "passāre", RI_IPA: "pɑˈzɑr", RI_Cyrl: "пазар", RI_Latn: "passar", PI_IPA: "pəˈzɑr", PI: "passar" },
      { w: "pastam", RI_IPA: "pɑtt", RI_Cyrl: "патт", RI_Latn: "paste", PI_IPA: "ˈpɑtə", PI: "pâtă" },
      { w: "patrem", RI_IPA: "pɑdr", RI_Cyrl: "падр", RI_Latn: "padre", PI_IPA: "ˈpɑdrə", PI: "padră" },
      { w: "paucum", RI_IPA: "puːkʲ", RI_Cyrl: "пӯк", RI_Latn: "puog", PI_IPA: "puːx", PI: "puog" },
      { w: "pectum", RI_IPA: "pɛjt", RI_Cyrl: "пејт", RI_Latn: "peit", PI_IPA: "pɛjt", PI: "peit" },
      { w: "pedem", RI_IPA: "pɛj", RI_Cyrl: "пеј", RI_Latn: "pei", PI_IPA: "pɛj", PI: "pei" },
      { w: "pedīculum", RI_IPA: "pɛˈœj", RI_Cyrl: "пеөј", RI_Latn: "peéyu", PI_IPA: "pəˈeə", PI: "peéa" },
      { w: "pedūculum", RI_IPA: "pɛˈœj", RI_Cyrl: "пеөј", RI_Latn: "peóyu", PI_IPA: "pəˈoə", PI: "peóa" },
      { w: "pellem", RI_IPA: "piː", RI_Cyrl: "пі̄", RI_Latn: "pill", PI_IPA: "piː", PI: "py" },
      { w: "perdiū", RI_IPA: "pjɛrʝ", RI_Cyrl: "пјерж", RI_Latn: "pierz", PI_IPA: "pjɛrʝ", PI: "pierz" },
      { w: "permissum", RI_IPA: "pœːrˈʝeʰ", RI_Cyrl: "пө̄ржи’", RI_Latn: "peũriéss", PI_IPA: "pœːˈris", PI: "peuriss" },
      { w: "persōnam", RI_IPA: "pɛrˈzuːn", RI_Cyrl: "перзӯн’", RI_Latn: "persuone", PI_IPA: "pərˈzuːnə", PI: "persuonă" },
      { w: "pēsātum", RI_IPA: "pɛˈzoː", RI_Cyrl: "пезѡ̄", RI_Latn: "pesau", PI_IPA: "pəˈzoː", PI: "pesau" },
      { w: "petram", RI_IPA: "pjɛdr", RI_Cyrl: "пједр", RI_Latn: "piedre", PI_IPA: "ˈpjɛdrə", PI: "piedră" },
      { w: "petrosilium", RI_IPA: "pɛdrəˈziː", RI_Cyrl: "педръзі̄", RI_Latn: "pedresill", PI_IPA: "pədrəˈziː", PI: "pedresy" },
      { w: "pilum", RI_IPA: "pjøː", RI_Cyrl: "пјө̄", RI_Latn: "piéu", PI_IPA: "pjøː", PI: "piéu" },
      { w: "piscem", RI_IPA: "pjiçç", RI_Cyrl: "пјішш", RI_Latn: "piésce", PI_IPA: "ˈpjɛçə", PI: "piêçă" },
      { w: "pittītum", RI_IPA: "pɛˈtyː", RI_Cyrl: "петү̄", RI_Latn: "petiu", PI_IPA: "pəˈtyː", PI: "petiu" },
      { w: "placēre", RI_IPA: "plɑˈʒʒer", RI_Cyrl: "плажжир", RI_Latn: "plascér", PI_IPA: "pləˈʒʒer", PI: "plascér" },
      { w: "planta", RI_IPA: "plɑ̃t", RI_Cyrl: "плант", RI_Latn: "plante", PI_IPA: "ˈplɑ̃tə", PI: "plantă" },
      { w: "plēnum", RI_IPA: "pljẽ", RI_Cyrl: "плјин", RI_Latn: "plién", PI_IPA: "pljẽ", PI: "plién" },
      { w: "plūmam", RI_IPA: "plym", RI_Cyrl: "плүм", RI_Latn: "plume", PI_IPA: "ˈplymə", PI: "plumă" },
      { w: "plūs", RI_IPA: "pləʰ", RI_Cyrl: "плъ’", RI_Latn: "ples", PI_IPA: "pləs", PI: "ples" },
      { w: "plūviam", RI_IPA: "plyʒʒ", RI_Cyrl: "плүжж", RI_Latn: "plusje", PI_IPA: "ˈplyʒʒə", PI: "plusjă" },
      { w: "plūviāre", RI_IPA: "plyˈʒʒɑr", RI_Cyrl: "плүжжар", RI_Latn: "plusjar", PI_IPA: "pləˈʒʒɑr", PI: "plusjar" },
      { w: "positum", RI_IPA: "pœjtt", RI_Cyrl: "пөјтт", RI_Latn: "poist", PI_IPA: "pɔjt", PI: "poît" },
      { w: "possidēre", RI_IPA: "paˈzjir", RI_Cyrl: "пязјір", RI_Latn: "pàssiér", PI_IPA: "pəˈzir", PI: "pàssir" },
      { w: "potēre", RI_IPA: "poːˈʝer", RI_Cyrl: "пѡ̄жир", RI_Latn: "pàuyér", PI_IPA: "poːˈir", PI: "pauyr" },
      { w: "premēre", RI_IPA: "prœːˈʝer", RI_Cyrl: "прө̄жир", RI_Latn: "preũyér", PI_IPA: "prœːˈir", PI: "preuyr" },
      { w: "prīmārium", RI_IPA: "priˈmaːr", RI_Cyrl: "прімя̄р", RI_Latn: "primàir", PI_IPA: "prəˈmæːr", PI: "primàir" },
      { w: "propium", RI_IPA: "prɔːʃ", RI_Cyrl: "про̄ш", RI_Latn: "proeç", PI_IPA: "prɔjʃ", PI: "proeç" },
      { w: "pulsāre", RI_IPA: "pɔzˈzɑr", RI_Cyrl: "поззар", RI_Latn: "possar", PI_IPA: "pəzˈzɑr", PI: "possar" },
      { w: "pulverem", RI_IPA: "poːvr", RI_Cyrl: "пѡ̄вр", RI_Latn: "póuvre", PI_IPA: "ˈpoːvrə", PI: "póuvră" },
      { w: "pūtridum", RI_IPA: "ˈpylɛrt", RI_Cyrl: "пүлерт", RI_Latn: "pulerd", PI_IPA: "ˈpylərd", PI: "pulărd" },
      { w: "quadrātum", RI_IPA: "kʲɑˈdroː", RI_Cyrl: "кадрѡ̄", RI_Latn: "quadràu", PI_IPA: "kəˈdroː", PI: "cadrau" },
      { w: "qualem quid", RI_IPA: "ˈkʲɑlɛdʒ", RI_Cyrl: "калеџ", RI_Latn: "qualeg", PI_IPA: "ˈkɑlədʒ", PI: "calădj" },
      { w: "quālencunque", RI_IPA: "kʲɑlə̃ˈkʲũtʃ", RI_Cyrl: "калънкунч", RI_Latn: "qualencónc", PI_IPA: "kələ̃ˈkɔ̃tʃ", PI: "calencónch" },
      { w: "quam", RI_IPA: "kʲɑ̃", RI_Cyrl: "кан", RI_Latn: "quan", PI_IPA: "kɑ̃", PI: "can" },
      { w: "quandō", RI_IPA: "kʲɑ̃t", RI_Cyrl: "кант", RI_Latn: "quand", PI_IPA: "kɑ̃d", PI: "cand" },
      { w: "quarrāintā<", RI_IPA: "kʲɑˈrɐ̃t", RI_Cyrl: "карънт", RI_Latn: "quarànte", PI_IPA: "kəˈræ̃tə", PI: "caràntă" },
      { w: "quattōrdecim", RI_IPA: "kʲɑˈtorç", RI_Cyrl: "катѡрш", RI_Latn: "quatórç", PI_IPA: "kəˈtorç", PI: "catórç" },
      { w: "quattrō", RI_IPA: "kʲɑtr", RI_Cyrl: "катр", RI_Latn: "quatre", PI_IPA: "ˈkɑtrə", PI: "catră" },
      { w: "quem", RI_IPA: "tʃɛ̃", RI_Cyrl: "чен", RI_Latn: "quen", PI_IPA: "tʃɛ̃", PI: "chen" },
      { w: "quid", RI_IPA: "tʃ", RI_Cyrl: "ч", RI_Latn: "que", PI_IPA: "tʃə", PI: "che" },
      { w: "quōmo", RI_IPA: "kuː", RI_Cyrl: "кӯ", RI_Latn: "cuoũ", PI_IPA: "kuː", PI: "cuo" },
      { w: "rādīcem", RI_IPA: "raˈʝiʒʒ", RI_Cyrl: "ряжіжж", RI_Latn: "ràysce", PI_IPA: "rəˈjiʒʒə", PI: "ràysçă" },
      { w: "rasicāre", RI_IPA: "razˈdʒɑr", RI_Cyrl: "рязџар", RI_Latn: "ràsgar", PI_IPA: "rəzˈdʒɑr", PI: "ràsdjar" },
      { w: "rastellum", RI_IPA: "ratˈtiː", RI_Cyrl: "рятті̄", RI_Latn: "ràstill", PI_IPA: "rəˈtiː", PI: "ràîty" },
      { w: "rhōdium", RI_IPA: "rɔːʃ", RI_Cyrl: "ро̄ш", RI_Latn: "roez", PI_IPA: "rɔjʃ", PI: "roez" },
      { w: "rīdēre", RI_IPA: "riˈer", RI_Cyrl: "ріир", RI_Latn: "riér", PI_IPA: "rəˈer", PI: "riér" },
      { w: "riquilitia", RI_IPA: "rɛlˈlɛjʒ", RI_Cyrl: "реллејж", RI_Latn: "regleiçe", PI_IPA: "rəlˈlɛjʒə", PI: "relleiçă" },
      { w: "rīvum", RI_IPA: "ryː", RI_Cyrl: "рү̄", RI_Latn: "riu", PI_IPA: "ryː", PI: "riu" },
      { w: "rosmarīnum", RI_IPA: "rɔzməˈrĩ", RI_Cyrl: "розмърін", RI_Latn: "rosmerin", PI_IPA: "rəzməˈrɛ̃", PI: "rosmerin" },
      { w: "rotundum", RI_IPA: "rɔˈlũt", RI_Cyrl: "ролунт", RI_Latn: "rolónd", PI_IPA: "rəˈlɔ̃d", PI: "rolónd" },
      { w: "rubehum", RI_IPA: "rɔːʃ", RI_Cyrl: "ро̄ш", RI_Latn: "roez", PI_IPA: "rɔjʃ", PI: "roez" },
      { w: "ruptam", RI_IPA: "roːt", RI_Cyrl: "рѡ̄т", RI_Latn: "róute", PI_IPA: "ˈroːtə", PI: "róută" },
      { w: "sablum", RI_IPA: "zoːl", RI_Cyrl: "зѡ̄л", RI_Latn: "saule", PI_IPA: "ˈzoːlə", PI: "saulă" },
      { w: "saeculum", RI_IPA: "zœj", RI_Cyrl: "зөј", RI_Latn: "seyu", PI_IPA: "ˈzɛə", PI: "seă" },
      { w: "salem", RI_IPA: "zoː", RI_Cyrl: "зѡ̄", RI_Latn: "sau", PI_IPA: "zoː", PI: "sau" },
      { w: "salsīciam", RI_IPA: "zɑzˈziʒʒ", RI_Cyrl: "заззіжж", RI_Latn: "sassisçe", PI_IPA: "zəzˈziʒʒə", PI: "sassisçă" },
      { w: "salvia", RI_IPA: "zaːʝ", RI_Cyrl: "зя̄ж", RI_Latn: "saeje", PI_IPA: "ˈzɑjʝə", PI: "saejă" },
      { w: "sapēre", RI_IPA: "zoːˈʝer", RI_Cyrl: "зѡ̄жир", RI_Latn: "sauyér", PI_IPA: "zoːˈir", PI: "sauyr" },
      { w: "sapōrem", RI_IPA: "zɑˈbuːr", RI_Cyrl: "забӯр", RI_Latn: "sabuor", PI_IPA: "zəˈbuːr", PI: "sabuor" },
      { w: "scūppīre", RI_IPA: "ʰkʲœˈpir", RI_Cyrl: "’көпір", RI_Latn: "squeupir", PI_IPA: "skəˈpir", PI: "squeupir" },
      { w: "sedēre", RI_IPA: "zɛˈʝer", RI_Cyrl: "зежир", RI_Latn: "seyér", PI_IPA: "zəˈir", PI: "seyr" },
      { w: "sēminem", RI_IPA: "zøːn", RI_Cyrl: "зө̄н’", RI_Latn: "séũne", PI_IPA: "ˈzøːnə", PI: "séună" },
      { w: "sentīre", RI_IPA: "zɛ̃ˈtir", RI_Cyrl: "зентір", RI_Latn: "sentir", PI_IPA: "zə̃ˈtir", PI: "sentir" },
      { w: "septem", RI_IPA: "zœːt", RI_Cyrl: "зө̄т", RI_Latn: "seute", PI_IPA: "ˈzœːtə", PI: "seută" },
      { w: "servum", RI_IPA: "zœːr", RI_Cyrl: "зө̄р", RI_Latn: "seur", PI_IPA: "zœːr", PI: "seur" },
      { w: "serpentem", RI_IPA: "zɛrˈpjɛ̃t", RI_Cyrl: "зерпјент", RI_Latn: "serpient", PI_IPA: "zərˈpjɛ̃t", PI: "serpient" },
      { w: "sex", RI_IPA: "zɛss", RI_Cyrl: "зесс", RI_Latn: "ses", PI_IPA: "zɛss", PI: "ses" },
      { w: "sexāintā<", RI_IPA: "zɛˈssɑ̃t", RI_Cyrl: "зессант", RI_Latn: "sessante", PI_IPA: "zəˈssɑ̃tə", PI: "sessantă" },
      { w: "sī", RI_IPA: "z", RI_Cyrl: "з", RI_Latn: "se", PI_IPA: "zə", PI: "se" },
      { w: "sīc nōn", RI_IPA: "zĩˈwɛ̃", RI_Cyrl: "зінуен", RI_Latn: "sinwen", PI_IPA: "zə̃ˈwɛ̃", PI: "sinwen" },
      { w: "siccum", RI_IPA: "zekʲ", RI_Cyrl: "зик", RI_Latn: "séc", PI_IPA: "zek", PI: "séc" },
      { w: "skīnam", RI_IPA: "ʰçin", RI_Cyrl: "’шін’", RI_Latn: "scine", PI_IPA: "ˈsçinə", PI: "scină" },
      { w: "solellum", RI_IPA: "zaˈliː", RI_Cyrl: "зялі̄", RI_Latn: "sàlill", PI_IPA: "zəˈliː", PI: "sàly" },
      { w: "sōlum", RI_IPA: "zuː", RI_Cyrl: "зӯ", RI_Latn: "suou", PI_IPA: "zuː", PI: "suo" },
      { w: "speciēm", RI_IPA: "ʰpɛjʃ", RI_Cyrl: "’пејш", RI_Latn: "speiç", PI_IPA: "spɛjʃ", PI: "speiç" },
      { w: "spissum", RI_IPA: "ʰpjiʰ", RI_Cyrl: "’пјі’", RI_Latn: "spiéss", PI_IPA: "spis", PI: "spiss" },
      { w: "spōsa", RI_IPA: "ʰpuːz", RI_Cyrl: "’пӯз", RI_Latn: "spuose", PI_IPA: "ˈspuːzə", PI: "spuosă" },
      { w: "stāre", RI_IPA: "ʰtɑr", RI_Cyrl: "’тар", RI_Latn: "star", PI_IPA: "stɑr", PI: "star" },
      { w: "stakāre", RI_IPA: "ʰtɑˈdʒɑr", RI_Cyrl: "’таџар", RI_Latn: "stagar", PI_IPA: "stəˈdʒɑr", PI: "stadjar" },
      { w: "stellam", RI_IPA: "ʰtiʝ", RI_Cyrl: "’тіж", RI_Latn: "stille", PI_IPA: "ˈstijə", PI: "stiyă" },
      { w: "stokāre", RI_IPA: "ʰtɔˈdʒɑr", RI_Cyrl: "’тоџар", RI_Latn: "stogar", PI_IPA: "stəˈdʒɑr", PI: "stodjar" },
      { w: "strīctum", RI_IPA: "ʰtrɛjt", RI_Cyrl: "’трејт", RI_Latn: "stréit", PI_IPA: "strejt", PI: "stréit" },
      { w: "sūccāre", RI_IPA: "zyˈtʃɑr", RI_Cyrl: "зүчар", RI_Latn: "sucar", PI_IPA: "zəˈtʃɑr", PI: "suchar" },
      { w: "sufflāre", RI_IPA: "zoːˈvlɑr", RI_Cyrl: "зѡ̄влар", RI_Latn: "souvlar", PI_IPA: "zoːˈvlɑr", PI: "souvlar" },
      { w: "suppam", RI_IPA: "zuːp", RI_Cyrl: "зӯп", RI_Latn: "suope", PI_IPA: "ˈzuːpə", PI: "suopă" },
      { w: "suum", RI_IPA: "zuː", RI_Cyrl: "зӯ", RI_Latn: "suo", PI_IPA: "zuː", PI: "suo" },
      { w: "tāleāre", RI_IPA: "taˈʝɑr", RI_Cyrl: "тяжар", RI_Latn: "tàllar", PI_IPA: "təˈjɑr", PI: "tàyar" },
      { w: "talōnem", RI_IPA: "tɑˈlũː", RI_Cyrl: "талӯн", RI_Latn: "taluon", PI_IPA: "təˈlũː", PI: "taluon" },
      { w: "tam perdiū", RI_IPA: "tɑ̃ˈpjɛrʝ", RI_Cyrl: "танпјерж", RI_Latn: "tampierz", PI_IPA: "tə̃ˈpjɛrʝ", PI: "tampierz" },
      { w: "tempum", RI_IPA: "cçɛw", RI_Cyrl: "тјеу", RI_Latn: "tiew̃", PI_IPA: "tjɛw", PI: "tiew" },
      { w: "tenēre", RI_IPA: "tɛ̃ˈʝer", RI_Cyrl: "тенжир", RI_Latn: "tenyér", PI_IPA: "tə̃ˈir", PI: "tenyr" },
      { w: "terram", RI_IPA: "cçɛr", RI_Cyrl: "тјер", RI_Latn: "tier", PI_IPA: "tjɛr", PI: "tier" },
      { w: "testam", RI_IPA: "cçɛtt", RI_Cyrl: "тјетт", RI_Latn: "tieste", PI_IPA: "ˈtjɛtə", PI: "tiêtă" },
      { w: "textōrem", RI_IPA: "tɛssˈtuːr", RI_Cyrl: "тесстӯр", RI_Latn: "testuor", PI_IPA: "təssˈtuːr", PI: "testuor" },
      { w: "tīrāre", RI_IPA: "tiˈrɑr", RI_Cyrl: "тірар", RI_Latn: "tirar", PI_IPA: "təˈrɑr", PI: "tirar" },
      { w: "toccāre", RI_IPA: "tɔˈtʃɑr", RI_Cyrl: "точар", RI_Latn: "tocar", PI_IPA: "təˈtʃɑr", PI: "tochar" },
      { w: "trās", RI_IPA: "trəʰ", RI_Cyrl: "тръ’", RI_Latn: "tres", PI_IPA: "trəs", PI: "tres" },
      { w: "trēs", RI_IPA: "trəʰ", RI_Cyrl: "тръ’", RI_Latn: "tres", PI_IPA: "trəs", PI: "tres" },
      { w: "trīgintā<", RI_IPA: "trɛjnt", RI_Cyrl: "трејнт", RI_Latn: "tréinte", PI_IPA: "ˈtrejntə", PI: "tréintă" },
      { w: "tripālium", RI_IPA: "trɛˈbaj", RI_Cyrl: "требяј", RI_Latn: "trebàll", PI_IPA: "trəˈbæj", PI: "trebày" },
      { w: "trīppam", RI_IPA: "trip", RI_Cyrl: "тріп", RI_Latn: "tripe", PI_IPA: "ˈtripə", PI: "tripă" },
      { w: "trūccāre", RI_IPA: "tryˈtʃɑr", RI_Cyrl: "трүчар", RI_Latn: "trucar", PI_IPA: "trəˈtʃɑr", PI: "truchar" },
      { w: "tū!", RI_IPA: "ty", RI_Cyrl: "тү", RI_Latn: "tu", PI_IPA: "ty", PI: "tu" },
      { w: "tumbāre", RI_IPA: "toːˈbɑr", RI_Cyrl: "тѡ̄бар", RI_Latn: "toũbar", PI_IPA: "toːˈbɑr", PI: "toubar" },
      { w: "Tungrōs", RI_IPA: "tũgʲr", RI_Cyrl: "тунгр", RI_Latn: "Tóngres", PI_IPA: "ˈtɔ̃xrəs", PI: "Tóngrăs" },
      { w: "turrem", RI_IPA: "tuːr", RI_Cyrl: "тӯр", RI_Latn: "tuor", PI_IPA: "tuːr", PI: "tuor" },
      { w: "tūtāre", RI_IPA: "tyˈlɑr", RI_Cyrl: "түлар", RI_Latn: "tular", PI_IPA: "təˈlɑr", PI: "tular" },
      { w: "unda", RI_IPA: "ũd", RI_Cyrl: "унд", RI_Latn: "ónde", PI_IPA: "ˈɔ̃də", PI: "óndă" },
      { w: "unde", RI_IPA: "ũt", RI_Cyrl: "унт", RI_Latn: "ónd", PI_IPA: "ɔ̃d", PI: "ónd" },
      { w: "undecim", RI_IPA: "ũç", RI_Cyrl: "унш", RI_Latn: "ónç", PI_IPA: "ɔ̃ç", PI: "ónç" },
      { w: "ungulam", RI_IPA: "ũll", RI_Cyrl: "унлл", RI_Latn: "óngle", PI_IPA: "ˈɔ̃llə", PI: "ónllă" }, # nll?!
      { w: "veculum", RI_IPA: "vœj", RI_Cyrl: "вөј", RI_Latn: "veyu", PI_IPA: "ˈvɛə", PI: "veă" },
      { w: "venīre", RI_IPA: "vɛˈnir", RI_Cyrl: "венір", RI_Latn: "venir", PI_IPA: "vəˈnir", PI: "venir" },
      { w: "ventrem", RI_IPA: "vjɛ̃tr", RI_Cyrl: "вјентр", RI_Latn: "vientre", PI_IPA: "ˈvjɛ̃trə", PI: "vientră" },
      { w: "ventum", RI_IPA: "vjɛ̃t", RI_Cyrl: "вјент", RI_Latn: "vient", PI_IPA: "vjɛ̃t", PI: "vient" },
      { w: "vērācum", RI_IPA: "vɛˈrɑkʲ", RI_Cyrl: "верак", RI_Latn: "verag", PI_IPA: "vəˈrɑx", PI: "verag" },
      { w: "vēritātem", RI_IPA: "vɛrˈlɑt", RI_Cyrl: "верлат", RI_Latn: "verlad", PI_IPA: "vərˈlɑd", PI: "verlad" },
      { w: "vermem", RI_IPA: "vjœːr", RI_Cyrl: "вјө̄р", RI_Latn: "vieũr", PI_IPA: "vjœːr", PI: "vieur" },
      { w: "vidēre", RI_IPA: "vɛˈʝer", RI_Cyrl: "вежир", RI_Latn: "veyér", PI_IPA: "vəˈir", PI: "veyr" },
      { w: "vīgintī<", RI_IPA: "vɛjnt", RI_Cyrl: "вејнт", RI_Latn: "véint", PI_IPA: "vejnt", PI: "véint" },
      { w: "vīnum", RI_IPA: "vĩ", RI_Cyrl: "він", RI_Latn: "vin", PI_IPA: "vɛ̃", PI: "vin" },
      { w: "vīnum ācrum", RI_IPA: "viˈnɑgʲr", RI_Cyrl: "вінагр", RI_Latn: "vinagre", PI_IPA: "vəˈnɑxrə", PI: "vinagră" },
      { w: "vīrāre", RI_IPA: "viˈrɑr", RI_Cyrl: "вірар", RI_Latn: "virar", PI_IPA: "vəˈrɑr", PI: "virar" },
      { w: "viridem", RI_IPA: "vjirt", RI_Cyrl: "вјірт", RI_Latn: "viérd", PI_IPA: "vird", PI: "vird" },
      { w: "vīvēre", RI_IPA: "vyːˈʝer", RI_Cyrl: "вү̄жир", RI_Latn: "viuyér", PI_IPA: "vyːˈir", PI: "viuyr" },
      { w: "volāre", RI_IPA: "vɔˈlɑr", RI_Cyrl: "волар", RI_Latn: "volar", PI_IPA: "vəˈlɑr", PI: "volar" },
      { w: "volēre", RI_IPA: "voːˈʝer", RI_Cyrl: "вѡ̄жир", RI_Latn: "vàuyér", PI_IPA: "voːˈir", PI: "vauyr" },
      { w: "vomēre", RI_IPA: "voːˈʝer", RI_Cyrl: "вѡ̄жир", RI_Latn: "vàũyér", PI_IPA: "voːˈir", PI: "vauyr" },
      { w: "vōs alterōs", RI_IPA: "vɔˈzaːtr", RI_Cyrl: "возя̄тр", RI_Latn: "vosaetres", PI_IPA: "vəˈzɑjtrəs", PI: "vosaetrăs" },
      { w: "zingiberem", RI_IPA: "ʝɛ̃ˈʝøːr", RI_Cyrl: "женжө̄р", RI_Latn: "jengéure", PI_IPA: "ʝə̃ˈʝøːrə", PI: "jengéură" }
    ]
    
    latin_words.each do |word|
      xform = transform word[:w]

      assert_equal word[:RI_IPA], xform[1].to_ipa
      assert_equal word[:RI_Cyrl], cyrillize(xform[1])
      assert_equal word[:RI_Latn], xform[1].join

      assert_equal word[:PI_IPA], xform[2].to_ipa
      assert_equal word[:PI], xform[2].join
    end

    olf_words = [
      { w: "ahtig", RI_IPA: "ˈɑkʲtəkʲ", RI_Cyrl: "актък", RI_Latn: "aghteg", PI_IPA: "ˈɑktəx", PI: "aghtăg" },
      { w: "antlutti", RI_IPA: "ˈɑ̃tlətt", RI_Cyrl: "антлътт", RI_Latn: "antlette", PI_IPA: "ˈɑ̃tləttə", PI: "antlătta" },
      { w: "antlūciéus!", RI_IPA: "ɑ̃tluːtʃjeˈyʰ", RI_Cyrl: "антлӯчјиү’", RI_Latn: "antluquiéus", PI_IPA: "ə̃tluːtʃjəˈys", PI: "antluchiéus" },
      { w: "armēnjarium", RI_IPA: "ɑrmeːˈɲaːr", RI_Cyrl: "армӣњя̄р", RI_Latn: "arméinhàir", PI_IPA: "ərmeːˈɲæːr", PI: "arméinhàir" },
      { w: "aska", RI_IPA: "ɑkʲkʲ", RI_Cyrl: "акк", RI_Latn: "asque", PI_IPA: "ˈɑkə", PI: "âcă" },
      { w: "bēn", RI_IPA: "bẽː", RI_Cyrl: "бӣн", RI_Latn: "béin", PI_IPA: "bẽː", PI: "béin" },
      { w: "bende", RI_IPA: "bɛ̃d", RI_Cyrl: "бенд", RI_Latn: "bende", PI_IPA: "ˈbɛ̃də", PI: "bendă" },
      { w: "bier", RI_IPA: "bjɛr", RI_Cyrl: "бјер", RI_Latn: "bier", PI_IPA: "bjɛr", PI: "bier" },
      { w: "bittar", RI_IPA: "ˈbittər", RI_Cyrl: "біттър", RI_Latn: "bitter", PI_IPA: "ˈbittər", PI: "bittăr" },
      { w: "blīthi", RI_IPA: "bliːd", RI_Cyrl: "блі̄д", RI_Latn: "blide", PI_IPA: "ˈbliːdə", PI: "blidă" },
      { w: "blok", RI_IPA: "blɔkʲ", RI_Cyrl: "блок", RI_Latn: "bloc", PI_IPA: "blɔk", PI: "bloc" },
      { w: "bōnakrūt", RI_IPA: "ˈboːnəkʲruːt", RI_Cyrl: "бѡ̄нъкрӯт", RI_Latn: "bónecrut", PI_IPA: "ˈboːnəkruːt", PI: "bónăcrut" },
      { w: "brantāre", RI_IPA: "brɑ̃ˈtɑr", RI_Cyrl: "брантар", RI_Latn: "brantar", PI_IPA: "brə̃ˈtɑr", PI: "brantar" },
      { w: "brēd", RI_IPA: "breːt", RI_Cyrl: "брӣт", RI_Latn: "bréid", PI_IPA: "breːd", PI: "bréid" },
      { w: "brēdau!", RI_IPA: "breːˈdoː", RI_Cyrl: "брӣдѡ̄", RI_Latn: "bréidau", PI_IPA: "breːˈdoː", PI: "bréidau" },
      { w: "brestāre", RI_IPA: "brɛtˈtɑr", RI_Cyrl: "бреттар", RI_Latn: "brestar", PI_IPA: "brəˈtɑr", PI: "brêtar" },
      { w: "breukelen", RI_IPA: "ˈbrœːtʃoːn", RI_Cyrl: "брө̄чѡ̄н’", RI_Latn: "breuqueune", PI_IPA: "ˈbrœːtʃoːnə", PI: "breucheună" },
      { w: "bronc", RI_IPA: "brɔ̃kʲ", RI_Cyrl: "бронк", RI_Latn: "bronc", PI_IPA: "brɔ̃k", PI: "bronc" },
      { w: "brust", RI_IPA: "brytt", RI_Cyrl: "брүтт", RI_Latn: "brust", PI_IPA: "bryt", PI: "brût" },
      { w: "bucle", RI_IPA: "bykʲl", RI_Cyrl: "бүкл", RI_Latn: "bucle", PI_IPA: "ˈbyklə", PI: "buclă" },
      { w: "bulto", RI_IPA: "buːt", RI_Cyrl: "бӯт", RI_Latn: "buute", PI_IPA: "ˈbuːtə", PI: "buută" },
      { w: "butera", RI_IPA: "ˈbytər", RI_Cyrl: "бүтър", RI_Latn: "butere", PI_IPA: "ˈbytərə", PI: "butăra" },
      { w: "butt", RI_IPA: "bytt", RI_Cyrl: "бүтт", RI_Latn: "butt", PI_IPA: "bytt", PI: "butt" },
      { w: "cūprehum", RI_IPA: "kʲyːr", RI_Cyrl: "кү̄р", RI_Latn: "cuyure", PI_IPA: "ˈkyːrə", PI: "cuyură" },
      { w: "dag", RI_IPA: "dɑkʲ", RI_Cyrl: "дак", RI_Latn: "dag", PI_IPA: "dɑx", PI: "dag" },
      { w: "dilli", RI_IPA: "dyːl", RI_Cyrl: "дү̄л", RI_Latn: "diule", PI_IPA: "ˈdyːlə", PI: "diulă" },
      { w: "dōdāre", RI_IPA: "doːˈdɑr", RI_Cyrl: "дѡ̄дар", RI_Latn: "dódar", PI_IPA: "doːˈdɑr", PI: "dódar" },
      { w: "drepāre", RI_IPA: "drɛˈpɑr", RI_Cyrl: "дрепар", RI_Latn: "drepar", PI_IPA: "drəˈpɑr", PI: "drepar" },
      { w: "enklow", RI_IPA: "ˈɛ̃kʲləw", RI_Cyrl: "енклъу", RI_Latn: "enclew", PI_IPA: "ˈɛ̃kləw", PI: "enclăw" },
      { w: "etan", RI_IPA: "ɛtn", RI_Cyrl: "етн", RI_Latn: "etne", PI_IPA: "ˈɛtnə", PI: "etnă" },
      { w: "ezkerra>", RI_IPA: "ətˈtʃɛrr", RI_Cyrl: "ътчерр", RI_Latn: "ezquerre", PI_IPA: "əˈtʃɛrrə", PI: "êcherră" }, #Basque
      { w: "fallāre", RI_IPA: "voːˈlɑr", RI_Cyrl: "вѡ̄лар", RI_Latn: "faular", PI_IPA: "voːˈlɑr", PI: "faular" },
      { w: "fehtāre", RI_IPA: "vɛkʲˈtɑr", RI_Cyrl: "вектар", RI_Latn: "feghtar", PI_IPA: "vəkˈtɑr", PI: "feghtar" },
      { w: "firdēlāre", RI_IPA: "virdeːˈlɑr", RI_Cyrl: "вірдӣлар", RI_Latn: "firdéilar", PI_IPA: "vərdeːˈlɑr", PI: "firdéilar" },
      { w: "flēsc", RI_IPA: "vleːkʲkʲ", RI_Cyrl: "влӣкк", RI_Latn: "fléisc", PI_IPA: "vlɛːk", PI: "fleîc" },
      { w: "fluojāre", RI_IPA: "vluːˈʝɑr", RI_Cyrl: "влӯжар", RI_Latn: "fluoyar", PI_IPA: "vluːˈjɑr", PI: "fluoyar" },
      { w: "flutāre", RI_IPA: "vlyˈtɑr", RI_Cyrl: "влүтар", RI_Latn: "flutar", PI_IPA: "vləˈtɑr", PI: "flutar" },
      { w: "fogal", RI_IPA: "vɔll", RI_Cyrl: "волл", RI_Latn: "fogle", PI_IPA: "ˈvɔllə", PI: "follă" },
      { w: "fora", RI_IPA: "vɔr", RI_Cyrl: "вор", RI_Latn: "fore", PI_IPA: "ˈvɔrə", PI: "foră" },
      { w: "frēsāre", RI_IPA: "vreːˈzɑr", RI_Cyrl: "врӣзар", RI_Latn: "fréisar", PI_IPA: "vreːˈzɑr", PI: "fréisar" },
      { w: "frouwe", RI_IPA: "vroːw", RI_Cyrl: "врѡ̄у", RI_Latn: "frouwe", PI_IPA: "ˈvroːwə", PI: "frouwă" },
      { w: "fūlitha", RI_IPA: "ˈvuːləd", RI_Cyrl: "вӯлъд", RI_Latn: "fulede", PI_IPA: "ˈvuːlədə", PI: "fulăda" },
      { w: "furh", RI_IPA: "vyrkʲ", RI_Cyrl: "вүрк", RI_Latn: "furgh", PI_IPA: "vyrk", PI: "furgh" },
      { w: "gelo", RI_IPA: "dʒɛl", RI_Cyrl: "џел", RI_Latn: "guele", PI_IPA: "ˈdʒɛlə", PI: "djelă" },
      { w: "geslahta>", RI_IPA: "dʒɛˈzlɑkʲt", RI_Cyrl: "џезлакт", RI_Latn: "gueslaghte", PI_IPA: "dʒəˈzlɑktə", PI: "djeslaghtă" },
      { w: "giftāre", RI_IPA: "dʒyːˈtɑr", RI_Cyrl: "џү̄тар", RI_Latn: "guiutar", PI_IPA: "dʒyːˈtɑr", PI: "djiutar" },
      { w: "glad", RI_IPA: "gʲlɑt", RI_Cyrl: "глат", RI_Latn: "glad", PI_IPA: "xlɑd", PI: "glad" },
      { w: "gravāre", RI_IPA: "gʲrɑˈvɑr", RI_Cyrl: "гравар", RI_Latn: "gravar", PI_IPA: "xrəˈvɑr", PI: "gravar" },
      { w: "gruonendalārium", RI_IPA: "gʲruːnə̃dəˈlaːr", RI_Cyrl: "грӯнъндъля̄р", RI_Latn: "gruonendelàir", PI_IPA: "xruːnə̃dəˈlæːr", PI: "gruonendelàir" },
      { w: "hama", RI_IPA: "ɑm", RI_Cyrl: "ам", RI_Latn: "hame", PI_IPA: "ˈhɑmə", PI: "hamă" },
      { w: "herta", RI_IPA: "ɛrt", RI_Cyrl: "ерт", RI_Latn: "herte", PI_IPA: "ˈhɛrtə", PI: "hertă" },
      { w: "hōrāre", RI_IPA: "oːˈrɑr", RI_Cyrl: "ѡ̄рар", RI_Latn: "hórar", PI_IPA: "hoːˈrɑr", PI: "hórar" },
      { w: "hol", RI_IPA: "oː", RI_Cyrl: "ѡ̄", RI_Latn: "hou", PI_IPA: "hoː", PI: "hou" },
      { w: "hōvit", RI_IPA: "oːt", RI_Cyrl: "ѡ̄т", RI_Latn: "hóute", PI_IPA: "ˈhoːtə", PI: "hóută" },
      { w: "hund", RI_IPA: "ỹt", RI_Cyrl: "үнт", RI_Latn: "hund", PI_IPA: "hœ̃d", PI: "hund" },
      { w: "īs", RI_IPA: "iːʰ", RI_Cyrl: "і̄’", RI_Latn: "is", PI_IPA: "iːs", PI: "is" },
      { w: "kāsi", RI_IPA: "kʲɑːz", RI_Cyrl: "ка̄з", RI_Latn: "case", PI_IPA: "ˈkɑːzə", PI: "casă" },
      { w: "kīn", RI_IPA: "tʃĩː", RI_Cyrl: "чі̄н", RI_Latn: "quin", PI_IPA: "tʃɛ̃ː", PI: "chin" },
      { w: "kint", RI_IPA: "tʃĩt", RI_Cyrl: "чінт", RI_Latn: "quint", PI_IPA: "tʃɛ̃t", PI: "chint" },
      { w: "klemmāre", RI_IPA: "kʲlœːˈmɑr", RI_Cyrl: "клө̄мар", RI_Latn: "cleũmar", PI_IPA: "klœːˈmɑr", PI: "cleumar" },
      { w: "knapo", RI_IPA: "kʲnɑp", RI_Cyrl: "кнап", RI_Latn: "cnape", PI_IPA: "ˈknɑpə", PI: "cnapă" },
      { w: "knio", RI_IPA: "kʲni", RI_Cyrl: "кні", RI_Latn: "cnie", PI_IPA: "ˈkniə", PI: "cniă" },
      { w: "knukil", RI_IPA: "kʲnytʃl", RI_Cyrl: "кнүчл", RI_Latn: "cnucle", PI_IPA: "ˈknytʃlə", PI: "cnuchlă" },
      { w: "krattāre", RI_IPA: "kʲrɑtˈtɑr", RI_Cyrl: "краттар", RI_Latn: "crattar", PI_IPA: "krətˈtɑr", PI: "crattar" },
      { w: "krattur>", RI_IPA: "kʲrɑtˈtyr", RI_Cyrl: "краттүр", RI_Latn: "crattur", PI_IPA: "krətˈtyr", PI: "crattur" },
      { w: "kressa", RI_IPA: "kʲrɛzz", RI_Cyrl: "крезз", RI_Latn: "cresse", PI_IPA: "ˈkrɛzzə", PI: "cressă" },
      { w: "lakan", RI_IPA: "lɑkʲn", RI_Cyrl: "лакн", RI_Latn: "lacne", PI_IPA: "ˈlɑknə", PI: "lacnă" },
      { w: "lāg", RI_IPA: "lɑːkʲ", RI_Cyrl: "ла̄к", RI_Latn: "lag", PI_IPA: "lɑːx", PI: "lag" },
      { w: "lam", RI_IPA: "loː", RI_Cyrl: "лѡ̄", RI_Latn: "laũ", PI_IPA: "loː", PI: "lau" },
      { w: "lang", RI_IPA: "lɑ̃", RI_Cyrl: "лан", RI_Latn: "lang", PI_IPA: "lɑ̃", PI: "lang" },
      { w: "larik", RI_IPA: "lɑrkʲ", RI_Cyrl: "ларк", RI_Latn: "larque", PI_IPA: "ˈlɑrkə", PI: "larcă" },
      { w: "lichamo", RI_IPA: "ˈlikʲəm", RI_Cyrl: "лікъм", RI_Latn: "liqueme", PI_IPA: "ˈlikəmə", PI: "licăma" },
      { w: "līht", RI_IPA: "liːkʲt", RI_Cyrl: "лі̄кт", RI_Latn: "light", PI_IPA: "liːkt", PI: "light" },
      { w: "linkiska", RI_IPA: "ˈlĩtʃəkʲkʲ", RI_Cyrl: "лінчъкк", RI_Latn: "linquesque", PI_IPA: "ˈlɛ̃tʃəkə", PI: "linchăca" },
      { w: "lisse", RI_IPA: "lizz", RI_Cyrl: "лізз", RI_Latn: "lisse", PI_IPA: "ˈlizzə", PI: "lissă" }, # OLF
      { w: "lōpāre", RI_IPA: "loːˈpɑr", RI_Cyrl: "лѡ̄пар", RI_Latn: "lópar", PI_IPA: "loːˈpɑr", PI: "lópar" },
      { w: "lofāre", RI_IPA: "lɔˈvɑr", RI_Cyrl: "ловар", RI_Latn: "lofar", PI_IPA: "ləˈvɑr", PI: "lofar" },
      { w: "manhattan>", RI_IPA: "mɑˈnɑtt", RI_Cyrl: "манатт", RI_Latn: "manhatten", PI_IPA: "mə̃ˈhɑttə̃", PI: "manhattăn" },
      { w: "marka", RI_IPA: "mɑrkʲ", RI_Cyrl: "марк", RI_Latn: "marque", PI_IPA: "ˈmɑrkə", PI: "marcă" },
      { w: "mēro", RI_IPA: "meːr", RI_Cyrl: "мӣр", RI_Latn: "méire", PI_IPA: "ˈmeːrə", PI: "méiră" },
      { w: "middi", RI_IPA: "midd", RI_Cyrl: "мідд", RI_Latn: "midde", PI_IPA: "ˈmiddə", PI: "middă" },
      { w: "mist", RI_IPA: "mitt", RI_Cyrl: "мітт", RI_Latn: "mist", PI_IPA: "mit", PI: "mît" },
      { w: "moda", RI_IPA: "mɔd", RI_Cyrl: "мод", RI_Latn: "mode", PI_IPA: "ˈmɔdə", PI: "modă" },
      { w: "niguntig", RI_IPA: "ˈnigʲə̃təkʲ", RI_Cyrl: "нігънтък", RI_Latn: "niguenteg", PI_IPA: "ˈnixə̃təx", PI: "nigăntag" },
      { w: "nūdel", RI_IPA: "nuːdl", RI_Cyrl: "нӯдл", RI_Latn: "nudle", PI_IPA: "ˈnuːdlə", PI: "nudlă" },
      { w: "nosa", RI_IPA: "nɔz", RI_Cyrl: "ноз", RI_Latn: "nose", PI_IPA: "ˈnɔzə", PI: "nosă" },
      { w: "nū", RI_IPA: "nuː", RI_Cyrl: "нӯ", RI_Latn: "nu", PI_IPA: "nuː", PI: "nu" },
      { w: "ōstrīkārium", RI_IPA: "oːttriːˈkʲaːr", RI_Cyrl: "ѡ̄ттрі̄кя̄р", RI_Latn: "óstricàir", PI_IPA: "ɔːtriːˈkæːr", PI: "oûtricàir" },
      { w: "ōstrīki", RI_IPA: "ˈoːttriːtʃ", RI_Cyrl: "ѡ̄ттрі̄ч", RI_Latn: "óstrique", PI_IPA: "ˈɔːtriːtʃə", PI: "oûtrichă" },
      { w: "ōstrīkiska", RI_IPA: "ˈoːttriːtʃəkʲkʲ", RI_Cyrl: "ѡ̄ттрі̄чъкк", RI_Latn: "óstriquesque", PI_IPA: "ˈɔːtriːtʃəkə", PI: "oûtrichăca" },
      { w: "pinke", RI_IPA: "pĩtʃ", RI_Cyrl: "пінч", RI_Latn: "pinque", PI_IPA: "ˈpɛ̃tʃə", PI: "pinchă" },
      { w: "plekka", RI_IPA: "plɛkʲkʲ", RI_Cyrl: "плекк", RI_Latn: "plecque", PI_IPA: "ˈplɛkkə", PI: "pleccă" },
      { w: "rīs", RI_IPA: "riːʰ", RI_Cyrl: "рі̄’", RI_Latn: "ris", PI_IPA: "riːs", PI: "ris" },
      { w: "rōk", RI_IPA: "roːkʲ", RI_Cyrl: "рѡ̄к", RI_Latn: "róc", PI_IPA: "roːk", PI: "róc" },
      { w: "rost", RI_IPA: "rɔtt", RI_Cyrl: "ротт", RI_Latn: "rost", PI_IPA: "rɔt", PI: "rôt" },
      { w: "rūkāre", RI_IPA: "ruːˈkʲɑr", RI_Cyrl: "рӯкар", RI_Latn: "rucar", PI_IPA: "ruːˈkɑr", PI: "rucar" },
      { w: "sant", RI_IPA: "zɑ̃t", RI_Cyrl: "зант", RI_Latn: "sant", PI_IPA: "zɑ̃t", PI: "sant" },
      { w: "sap", RI_IPA: "zoː", RI_Cyrl: "зѡ̄", RI_Latn: "sau", PI_IPA: "zoː", PI: "sau" },
      { w: "sāt", RI_IPA: "zɑːt", RI_Cyrl: "за̄т", RI_Latn: "sat", PI_IPA: "zɑːt", PI: "sat" },
      { w: "scūm", RI_IPA: "ʰkʲuː", RI_Cyrl: "’кӯ", RI_Latn: "scuũ", PI_IPA: "skuː", PI: "scuu" },
      { w: "sēr", RI_IPA: "zeːr", RI_Cyrl: "зӣр", RI_Latn: "séir", PI_IPA: "zeːr", PI: "séir" },
      { w: "skella", RI_IPA: "ʰtʃœːl", RI_Cyrl: "’чө̄л", RI_Latn: "squeule", PI_IPA: "ˈstʃœːlə", PI: "scheulă" },
      { w: "skuldero", RI_IPA: "ˈʰkʲuːdər", RI_Cyrl: "’кӯдър", RI_Latn: "scuudere", PI_IPA: "ˈskuːdərə", PI: "scuudăra" },
      { w: "snelheid", RI_IPA: "ˈznœːɛjt", RI_Cyrl: "знө̄ејт", RI_Latn: "sneuheid", PI_IPA: "ˈznœːhəjd", PI: "sneuhăid" },
      { w: "snīthāre", RI_IPA: "zniːˈdɑr", RI_Cyrl: "зні̄дар", RI_Latn: "snidar", PI_IPA: "zniːˈdɑr", PI: "snidar" },
      { w: "sittāre", RI_IPA: "zitˈtɑr", RI_Cyrl: "зіттар", RI_Latn: "sittar", PI_IPA: "zətˈtɑr", PI: "sittar" },
      { w: "sivontig", RI_IPA: "ˈzivə̃təkʲ", RI_Cyrl: "зівънтък", RI_Latn: "siventeg", PI_IPA: "ˈzivə̃təx", PI: "sivăntag" },
      { w: "spīkere", RI_IPA: "ˈʰpiːtʃər", RI_Cyrl: "’пі̄чър", RI_Latn: "spiquere", PI_IPA: "ˈspiːtʃərə", PI: "spichăra" },
      { w: "splītāre", RI_IPA: "ʰpliːˈtɑr", RI_Cyrl: "’плі̄тар", RI_Latn: "splitar", PI_IPA: "spliːˈtɑr", PI: "splitar" },
      { w: "sprēkāre", RI_IPA: "ʰpreːˈkʲɑr", RI_Cyrl: "’прӣкар", RI_Latn: "spréicar", PI_IPA: "spreːˈkɑr", PI: "spréicar" },
      { w: "spīwāre", RI_IPA: "ʰpyːˈɑr", RI_Cyrl: "’пү̄ар", RI_Latn: "spiuar", PI_IPA: "spyːˈɑr", PI: "spiuar" },
      { w: "stapal", RI_IPA: "ʰtoːl", RI_Cyrl: "’тѡ̄л", RI_Latn: "staule", PI_IPA: "ˈstoːlə", PI: "staulă" },
      { w: "stāts", RI_IPA: "ʰtɑːts", RI_Cyrl: "’та̄тс", RI_Latn: "stats", PI_IPA: "stɑːts", PI: "stats" },
      { w: "stekāre", RI_IPA: "ʰtɛˈkʲɑr", RI_Cyrl: "’текар", RI_Latn: "stecar", PI_IPA: "stəˈkɑr", PI: "stecar" },
      { w: "stok", RI_IPA: "ʰtɔkʲ", RI_Cyrl: "’ток", RI_Latn: "stoc", PI_IPA: "stɔk", PI: "stoc" },
      { w: "strāla", RI_IPA: "ʰtrɑːl", RI_Cyrl: "’тра̄л", RI_Latn: "strale", PI_IPA: "ˈstrɑːlə", PI: "strală" },
      { w: "strīpa", RI_IPA: "ʰtriːp", RI_Cyrl: "’трі̄п", RI_Latn: "stripe", PI_IPA: "ˈstriːpə", PI: "stripă" },
      { w: "strōm", RI_IPA: "ʰtroː", RI_Cyrl: "’трѡ̄", RI_Latn: "stróũ", PI_IPA: "stroː", PI: "stróu" },
      { w: "sūgāre", RI_IPA: "zuːˈgʲɑr", RI_Cyrl: "зӯгар", RI_Latn: "sugar", PI_IPA: "zuːˈxɑr", PI: "sugar" },
      { w: "sunna", RI_IPA: "zỹn", RI_Cyrl: "зүнн", RI_Latn: "sunne", PI_IPA: "ˈzœ̃nə", PI: "sunnă" },
      { w: "swimmāre", RI_IPA: "zyːˈmɑr", RI_Cyrl: "зү̄мар", RI_Latn: "swiũmar", PI_IPA: "zwyːˈmɑr", PI: "swiumar" },
      { w: "thrājāre", RI_IPA: "drɑːˈʝɑr", RI_Cyrl: "дра̄жар", RI_Latn: "drayar", PI_IPA: "drɑːˈjɑr", PI: "drayar" },
      { w: "thunnī", RI_IPA: "ˈdỹniː", RI_Cyrl: "дүнні̄", RI_Latn: "dunni", PI_IPA: "ˈdœ̃niː", PI: "dunni" },
      { w: "tīt", RI_IPA: "tiːt", RI_Cyrl: "ті̄т", RI_Latn: "tit", PI_IPA: "tiːt", PI: "tit" },
      { w: "underarm", RI_IPA: "ˈỹdəroːr", RI_Cyrl: "үндърѡ̄р", RI_Latn: "undereũr", PI_IPA: "ˈœ̃dəroːr", PI: "undăreur" },
      { w: "vlissingen", RI_IPA: "ˈvlizzə̃n", RI_Cyrl: "вліззънн", RI_Latn: "vlissenne", PI_IPA: "ˈvlizzə̃nə", PI: "vlissănna" },
      { w: "watho", RI_IPA: "wɑd", RI_Cyrl: "уад", RI_Latn: "wade", PI_IPA: "ˈwɑdə", PI: "wadă" },
      { w: "wegga", RI_IPA: "wɛgʲgʲ", RI_Cyrl: "уегг", RI_Latn: "weggue", PI_IPA: "ˈwɛxxə", PI: "weggă" },
      { w: "wīd", RI_IPA: "wiːt", RI_Cyrl: "уі̄т", RI_Latn: "wid", PI_IPA: "wiːd", PI: "wid" },
      { w: "willāre", RI_IPA: "yːˈlɑr", RI_Cyrl: "ү̄лар", RI_Latn: "wiular", PI_IPA: "wyːˈlɑr", PI: "wiular" },
      { w: "wort", RI_IPA: "ɔrt", RI_Cyrl: "орт", RI_Latn: "wort", PI_IPA: "wɔrt", PI: "wort" },
      { w: "wurm", RI_IPA: "uːr", RI_Cyrl: "ӯр", RI_Latn: "wuũr", PI_IPA: "wuːr", PI: "wuur" },
      { w: "wurtala", RI_IPA: "ˈyrtəl", RI_Cyrl: "үртъл", RI_Latn: "wurtele", PI_IPA: "ˈwyrtələ", PI: "wurtăla" }
    ]
    
    olf_words.each do |word|
      xform = transform word[:w], "OLF"

      assert_equal word[:RI_IPA], xform[1].to_ipa
      assert_equal word[:RI_Cyrl], cyrillize(xform[1])
      assert_equal word[:RI_Latn], xform[1].join

      assert_equal word[:PI_IPA], xform[2].to_ipa
      assert_equal word[:PI], xform[2].join
    end
    
    fro_words = [
      { w: "race", RI_IPA: "ras", RI_Cyrl: "ряс", RI_Latn: "race", PI_IPA: "ˈræsə", PI: "rassă" }
    ]
    
    fro_words.each do |word|
      xform = transform word[:w], "FRO"

      assert_equal word[:RI_IPA], xform[1].to_ipa
      assert_equal word[:RI_Cyrl], cyrillize(xform[1])
      assert_equal word[:RI_Latn], xform[1].join

      assert_equal word[:PI_IPA], xform[2].to_ipa
      assert_equal word[:PI], xform[2].join
    end

    late_latin_words = [
      { w: "abominatio", RI_IPA: "ɑbɔminɑˈʒʒũː", RI_Cyrl: "абомінажжӯн", RI_Latn: "abominasçuon", PI_IPA: "əbəmənəˈʒʒũː", PI: "abominasçuon" },
      { w: "albanensem", RI_IPA: "ɑlbɑˈneʰ", RI_Cyrl: "албани’", RI_Latn: "albanés", PI_IPA: "əlbəˈnes", PI: "albanés" },
      { w: "allergīa>", RI_IPA: "ɑllɛrˈʝi", RI_Cyrl: "аллержі", RI_Latn: "allergie", PI_IPA: "əllərˈʝiə", PI: "allergiă" },
      { w: "aluminium", RI_IPA: "ɑlyˈmini", RI_Cyrl: "алүміні", RI_Latn: "aluminie", PI_IPA: "ələˈminjə", PI: "aluminiă" },
      { w: "america", RI_IPA: "ɑˈmɛrikʲ", RI_Cyrl: "амерік", RI_Latn: "amerique", PI_IPA: "əˈmɛrəkə", PI: "amerăca" },
      { w: "americanum>", RI_IPA: "ɑmɛriˈkʲɑ̃", RI_Cyrl: "амерікан", RI_Latn: "american", PI_IPA: "əmərəˈkɑ̃", PI: "american" },
      { w: "andorranum>", RI_IPA: "ɑ̃dɔrˈrɑ̃", RI_Cyrl: "андорран", RI_Latn: "andorran", PI_IPA: "ə̃dərˈrɑ̃", PI: "andorran" },
      { w: "anulāre", RI_IPA: "ɑnyˈlɑr", RI_Cyrl: "анүлар", RI_Latn: "anular", PI_IPA: "ənəˈlɑr", PI: "anular" },
      { w: "aquacultura>", RI_IPA: "ɑkwɑkʲylˈtyr", RI_Cyrl: "акуакүлтүр", RI_Latn: "aquaculture", PI_IPA: "əkwəkəlˈtyrə", PI: "acuacultură" },
      { w: "astrum", RI_IPA: "ɑttr", RI_Cyrl: "аттр", RI_Latn: "astre", PI_IPA: "ˈɑtrə", PI: "âtră" },
      { w: "augmentāre", RI_IPA: "ogʲmɛ̃ˈtɑr", RI_Cyrl: "ѡгментар", RI_Latn: "augmentar", PI_IPA: "əxmə̃ˈtɑr", PI: "augmentar" },
      { w: "basilicum", RI_IPA: "bɑˈzilikʲ", RI_Cyrl: "базілік", RI_Latn: "basilic", PI_IPA: "bəˈzilək", PI: "basilăc" },
      { w: "bottonem>", RI_IPA: "bɔtˈtũ", RI_Cyrl: "боттун", RI_Latn: "bottón", PI_IPA: "bətˈtɔ̃", PI: "bottón" },
      { w: "boxator", RI_IPA: "bɔksəˈluːr", RI_Cyrl: "боксълӯр", RI_Latn: "boxeluor", PI_IPA: "bəksəˈluːr", PI: "boxeluor" },
      { w: "boxatorium", RI_IPA: "bɔksəˈlœːr", RI_Cyrl: "боксълө̄р", RI_Latn: "boxeleur", PI_IPA: "bəksəˈlœːr", PI: "boxeleur" },
      { w: "caienna", RI_IPA: "kʲɑˈʝɛ̃n", RI_Cyrl: "каженн", RI_Latn: "cayenne", PI_IPA: "kəˈjɛ̃nə", PI: "cayennă" },
      { w: "canella", RI_IPA: "kʲɑˈnell", RI_Cyrl: "канилл", RI_Latn: "canélle", PI_IPA: "kəˈnellə", PI: "canéllă" },
      { w: "capitulum", RI_IPA: "kʲɑˈpityl", RI_Cyrl: "капітүл", RI_Latn: "capitul", PI_IPA: "kəˈpitəl", PI: "capităl" },
      { w: "cardamomum>", RI_IPA: "kʲɑrdɑˈmũ", RI_Cyrl: "кардамун", RI_Latn: "cardamóm", PI_IPA: "kərdəˈmɔ̃", PI: "cardamóm" },
      { w: "carvi", RI_IPA: "ˈkʲɑrvi", RI_Cyrl: "карві", RI_Latn: "carvi", PI_IPA: "ˈkɑrvə", PI: "carvă" },
      { w: "coriandrum", RI_IPA: "kʲɔriˈʝɑ̃dr", RI_Cyrl: "коріжандр", RI_Latn: "coriandre", PI_IPA: "kərəˈjɑ̃drə", PI: "coriandră" },
      { w: "corpus", RI_IPA: "ˈkʲorpyʰ", RI_Cyrl: "кѡрпү’", RI_Latn: "córpus", PI_IPA: "ˈkorpəs", PI: "córpăs" },
      { w: "curva", RI_IPA: "kʲyrv", RI_Cyrl: "күрв", RI_Latn: "curve", PI_IPA: "ˈkyrvə", PI: "curvă" },
      { w: "crystallum", RI_IPA: "kʲritˈtɑll", RI_Cyrl: "крітталл", RI_Latn: "cristall", PI_IPA: "krəˈtɑll", PI: "crîtall" },
      { w: "cylindrum", RI_IPA: "çiˈlĩdr", RI_Cyrl: "шіліндр", RI_Latn: "cilindre", PI_IPA: "çəˈlɛ̃drə", PI: "cilindră" },
      { w: "diatribas>", RI_IPA: "diʝɑˈtrib", RI_Cyrl: "діжатріб", RI_Latn: "diatribes", PI_IPA: "dəjəˈtribəs", PI: "diatribăs" },
      { w: "discum", RI_IPA: "dikʲkʲ", RI_Cyrl: "дікк", RI_Latn: "disc", PI_IPA: "dik", PI: "dîc" },
      { w: "distingu>", RI_IPA: "ditˈtĩkʲ", RI_Cyrl: "діттінк", RI_Latn: "disting", PI_IPA: "dəˈtɛ̃x", PI: "dîting" },
      { w: "emphasis", RI_IPA: "ˈɛ̃vɑʰ", RI_Cyrl: "енва’", RI_Latn: "emfas", PI_IPA: "ˈɛ̃vəs", PI: "emfăs" },
      { w: "entropia>", RI_IPA: "ɛ̃trɔˈpi", RI_Cyrl: "ентропі", RI_Latn: "entropie", PI_IPA: "ə̃trəˈpiə", PI: "entropiă" },
      { w: "epictetum>", RI_IPA: "ɛpikʲˈtet", RI_Cyrl: "епіктит", RI_Latn: "epictét", PI_IPA: "əpəkˈtet", PI: "epictét" },
      { w: "existēre", RI_IPA: "ɛksicˈcçer", RI_Cyrl: "ексіттјир", RI_Latn: "existiér", PI_IPA: "əksəˈtir", PI: "exîtir" },
      { w: "existiée", RI_IPA: "ɛksicˈcçe", RI_Cyrl: "ексіттји", RI_Latn: "existiée", PI_IPA: "əksəˈtjeə", PI: "exîtiéa" },
      { w: "existiéũs!", RI_IPA: "ɛksicˈcçøːʰ", RI_Cyrl: "ексіттјө̄’", RI_Latn: "existiéũs", PI_IPA: "əksəˈtjøːs", PI: "exîtiéus" },
      { w: "explosionem", RI_IPA: "ɛksplɔˈʒʒũː", RI_Cyrl: "експложжӯн", RI_Latn: "explosçuon", PI_IPA: "əkspləˈʒʒũː", PI: "explosçuon" },
      { w: "familjāre", RI_IPA: "vɑmiˈʝɑr", RI_Cyrl: "ваміжар", RI_Latn: "famillar", PI_IPA: "vəməˈjɑr", PI: "famiyar" },
      { w: "fenugrecum>", RI_IPA: "vɛnyˈgʲrekʲ", RI_Cyrl: "венүгрик", RI_Latn: "fenugréc", PI_IPA: "vənəˈxrek", PI: "fenugréc" },
      { w: "forma", RI_IPA: "vorm", RI_Cyrl: "вѡрм", RI_Latn: "fórme", PI_IPA: "ˈvormə", PI: "fórmă" },
      { w: "furaducensis", RI_IPA: "vyrɑdyˈçeʰ", RI_Cyrl: "вүрадүши’", RI_Latn: "furaducés", PI_IPA: "vərədəˈçes", PI: "furaducés" },
      { w: "gasum", RI_IPA: "gʲɑʰ", RI_Cyrl: "га’", RI_Latn: "gas", PI_IPA: "xɑs", PI: "gas" },
      { w: "helice", RI_IPA: "ˈɛliç", RI_Cyrl: "еліш", RI_Latn: "helice", PI_IPA: "ˈhɛləçə", PI: "helăça" }, # sg based on pl
      { w: "indice", RI_IPA: "ˈĩdiç", RI_Cyrl: "індіш", RI_Latn: "indice", PI_IPA: "ˈɛ̃dəçə", PI: "indăça" }, # sg based on pl
      { w: "inflatio", RI_IPA: "ĩvlɑˈʒʒũː", RI_Cyrl: "інвлажжӯн", RI_Latn: "imflasçuon", PI_IPA: "ə̃vləˈʒʒũː", PI: "imflasçuon" },
      { w: "isolāre", RI_IPA: "izɔˈlɑr", RI_Cyrl: "ізолар", RI_Latn: "isolar", PI_IPA: "əzəˈlɑr", PI: "isolar" },
      { w: "jamaica", RI_IPA: "ʝɑˈmɑʝikʲ", RI_Cyrl: "жамажік", RI_Latn: "jamayque", PI_IPA: "ʝəˈmɑjəkə", PI: "jamayăca" },
      { w: "japon!", RI_IPA: "ʝɑˈpɔ̃", RI_Cyrl: "жапон", RI_Latn: "japon", PI_IPA: "ʝəˈpɔ̃", PI: "japon" },
      { w: "japonensis", RI_IPA: "ʝɑpɔˈneʰ", RI_Cyrl: "жапони’", RI_Latn: "japonés", PI_IPA: "ʝəpəˈnes", PI: "japonés" },
      { w: "jasminum>", RI_IPA: "ʝɑˈzmĩ", RI_Cyrl: "жазмін", RI_Latn: "jasmin", PI_IPA: "ʝəˈzmɛ̃", PI: "jasmin" },
      { w: "lachensem", RI_IPA: "lɑˈtʃeʰ", RI_Cyrl: "лачи’", RI_Latn: "laqués", PI_IPA: "ləˈtʃes", PI: "lachés" },
      { w: "lavanda", RI_IPA: "lɑˈvɑ̃d", RI_Cyrl: "лаванд", RI_Latn: "lavande", PI_IPA: "ləˈvɑ̃də", PI: "lavandă" },
      { w: "liquidum", RI_IPA: "ˈlikwit", RI_Cyrl: "лікуіт", RI_Latn: "liquid", PI_IPA: "ˈlikwəd", PI: "licuăd" },
      { w: "macis", RI_IPA: "ˈmɑçiʰ", RI_Cyrl: "маші’", RI_Latn: "macis", PI_IPA: "ˈmɑçəs", PI: "maçăs" },
      { w: "majorana>", RI_IPA: "mɑʝɔˈrɑn", RI_Cyrl: "мажоран’", RI_Latn: "majorane", PI_IPA: "məʝəˈrɑnə", PI: "majorană" },
      { w: "materia", RI_IPA: "mɑˈtɛri", RI_Cyrl: "матері", RI_Latn: "materie", PI_IPA: "məˈtɛrjə", PI: "materiă" },
      { w: "mechlinensem", RI_IPA: "mɛkʲliˈneʰ", RI_Cyrl: "мекліни’", RI_Latn: "meclinés", PI_IPA: "məkləˈnes", PI: "meclinés" },
      { w: "multiplicāre", RI_IPA: "myltipliˈkʲɑr", RI_Cyrl: "мүлтіплікар", RI_Latn: "multiplicar", PI_IPA: "məltəpləˈkɑr", PI: "multiplicar" },
      { w: "muscada>", RI_IPA: "mykʲˈkʲɑd", RI_Cyrl: "мүккад", RI_Latn: "muscade", PI_IPA: "məˈkɑdə", PI: "mûcadă" },
      { w: "njamum", RI_IPA: "ɲɑ̃", RI_Cyrl: "њан", RI_Latn: "nham", PI_IPA: "ɲɑ̃", PI: "nham" },
      { w: "objectum", RI_IPA: "ɔbˈʝekʲt", RI_Cyrl: "обжикт", RI_Latn: "objécte", PI_IPA: "əbˈʝektə", PI: "objéctă" },
      { w: "orchidea>", RI_IPA: "ɔrkʲiˈde", RI_Cyrl: "оркіди", RI_Latn: "orquidée", PI_IPA: "ərkəˈdeə", PI: "orquidéa" },
      { w: "origanum", RI_IPA: "ɔˈrigʲɑ̃", RI_Cyrl: "оріган", RI_Latn: "origan", PI_IPA: "əˈrixə̃", PI: "origăn" },
      { w: "ovarium", RI_IPA: "ɔˈvaːr", RI_Cyrl: "овя̄р", RI_Latn: "ovàir", PI_IPA: "əˈvæːr", PI: "ovàir" },
      { w: "paprika", RI_IPA: "ˈpɑprikʲ", RI_Cyrl: "папрік", RI_Latn: "paprique", PI_IPA: "ˈpɑprəkə", PI: "paprăca" },
      { w: "parallelum>", RI_IPA: "pɑrɑlˈlel", RI_Cyrl: "параллил", RI_Latn: "parallél", PI_IPA: "pərəlˈlel", PI: "parallél" },
      { w: "participāre", RI_IPA: "pɑrtiçiˈpɑr", RI_Cyrl: "партішіпар", RI_Latn: "participar", PI_IPA: "pərtəçəˈpɑr", PI: "participar" },
      { w: "patronum>", RI_IPA: "pɑˈtrũ", RI_Cyrl: "патрун", RI_Latn: "patrón", PI_IPA: "pəˈtrɔ̃", PI: "patrón" },
      { w: "pellicula", RI_IPA: "pɛlˈlikʲyl", RI_Cyrl: "пеллікүл", RI_Latn: "pellicule", PI_IPA: "pəlˈlikələ", PI: "pellicăla" },
      { w: "pensāre", RI_IPA: "pɛ̃ˈzɑr", RI_Cyrl: "пензар", RI_Latn: "pensar", PI_IPA: "pə̃ˈzɑr", PI: "pensar" },
      { w: "phellogenum", RI_IPA: "vɛlˈlɔʝɛ̃", RI_Cyrl: "велложен", RI_Latn: "fellogen", PI_IPA: "vəlˈlɔʝə̃", PI: "felloçăn" },
      { w: "philosophum", RI_IPA: "viˈlɔzɔf", RI_Cyrl: "вілозов", RI_Latn: "filosof", PI_IPA: "vəˈlɔzəf", PI: "filosăf" },
      { w: "pimentum", RI_IPA: "piˈmẽt", RI_Cyrl: "піминт", RI_Latn: "pimént", PI_IPA: "pəˈmẽt", PI: "pimént" },
      { w: "pistillum", RI_IPA: "pitˈtiː", RI_Cyrl: "пітті̄", RI_Latn: "pistill", PI_IPA: "pəˈtiː", PI: "pîty" },
      { w: "planum", RI_IPA: "plɑ̃", RI_Cyrl: "план", RI_Latn: "plan", PI_IPA: "plɑ̃", PI: "plan" },
      { w: "porcellana>", RI_IPA: "pɔrçɛlˈlɑn", RI_Cyrl: "поршеллан’", RI_Latn: "porcellane", PI_IPA: "pərçəlˈlɑnə", PI: "porcellană" },
      { w: "pulsum", RI_IPA: "pyls", RI_Cyrl: "пүлс", RI_Latn: "puls", PI_IPA: "pyls", PI: "puls" },
      { w: "pyramide", RI_IPA: "piˈrɑmid", RI_Cyrl: "пірамід", RI_Latn: "piramide", PI_IPA: "pəˈrɑmədə", PI: "piramăda" },
      { w: "rationalis", RI_IPA: "rɑʒʒɔˈnoː", RI_Cyrl: "ражжонѡ̄", RI_Latn: "rationau", PI_IPA: "rəʒʒəˈnoː", PI: "rationau" },
      { w: "rectangulum", RI_IPA: "rɛkʲˈtɑ̃gʲyl", RI_Cyrl: "ректангүл", RI_Latn: "rectangul", PI_IPA: "rəkˈtɑ̃xəl", PI: "rectangăl" },
      { w: "reproducēre", RI_IPA: "rɛprɔdyˈçjir", RI_Cyrl: "репродүшјір", RI_Latn: "reproduciér", PI_IPA: "rəprədəˈçir", PI: "reproducir" },
      { w: "respīrāre", RI_IPA: "rɛppiˈrɑr", RI_Cyrl: "реппірар", RI_Latn: "respirar", PI_IPA: "rəpəˈrɑr", PI: "rêpirar" },
      { w: "rudbeckia", RI_IPA: "rydˈbɛkʲkʲi", RI_Cyrl: "рүдбеккі", RI_Latn: "rudbecquie", PI_IPA: "rədˈbɛkkjə", PI: "rudbecquiă" },
      { w: "safranum>", RI_IPA: "zɑˈvrɑ̃", RI_Cyrl: "завран", RI_Latn: "safran", PI_IPA: "zəˈvrɑ̃", PI: "safran" },
      { w: "sassafras", RI_IPA: "zɑˈzɑvr", RI_Cyrl: "зазавр", RI_Latn: "sassafres", PI_IPA: "zəˈzɑvrəs", PI: "sassafrăs" },
      { w: "scandalum", RI_IPA: "ˈʰkʲɑ̃dɑl", RI_Cyrl: "’кандал", RI_Latn: "scandal", PI_IPA: "ˈskɑ̃dəl", PI: "scandăl" },
      { w: "solidum", RI_IPA: "ˈzɔlit", RI_Cyrl: "золіт", RI_Latn: "solid", PI_IPA: "ˈzɔləd", PI: "solăd" },
      { w: "sphera", RI_IPA: "zver", RI_Cyrl: "звир", RI_Latn: "sfére", PI_IPA: "ˈzverə", PI: "sféră" },
      { w: "spiralis>", RI_IPA: "ʰpiˈroː", RI_Cyrl: "’пірѡ̄", RI_Latn: "spirau", PI_IPA: "spəˈroː", PI: "spirau" },
      { w: "sumach", RI_IPA: "ˈzymɑkʲ", RI_Cyrl: "зүмак", RI_Latn: "sumac", PI_IPA: "ˈzymək", PI: "sumăc" },
      { w: "systema>", RI_IPA: "zitˈtem", RI_Cyrl: "зіттим", RI_Latn: "sistéme", PI_IPA: "zəˈtemə", PI: "sîtémă" },
      { w: "thymum", RI_IPA: "dĩ", RI_Cyrl: "дін", RI_Latn: "dim", PI_IPA: "dɛ̃", PI: "dim" },
      { w: "tractorem>", RI_IPA: "trɑkʲˈtuːr", RI_Cyrl: "трактӯр", RI_Latn: "tractuor", PI_IPA: "trəkˈtuːr", PI: "tractuor" },
      { w: "vanilla", RI_IPA: "vɑˈniʝ", RI_Cyrl: "ваніж", RI_Latn: "vanille", PI_IPA: "vəˈnijə", PI: "vaniyă" },
      { w: "zeta", RI_IPA: "ʒet", RI_Cyrl: "жит", RI_Latn: "zéte", PI_IPA: "ˈʒetə", PI: "zétă" },
      { w: "zuccarum", RI_IPA: "ˈʒykʲkʲɑr", RI_Cyrl: "жүккар", RI_Latn: "zuccar", PI_IPA: "ˈʒykkər", PI: "zuccăr" }
    ]
    
    late_latin_words.each do |word|
      xform = transform word[:w], "LL"

      assert_equal word[:RI_IPA], xform[1].to_ipa
      assert_equal word[:RI_Cyrl], cyrillize(xform[1])
      assert_equal word[:RI_Latn], xform[1].join

      assert_equal word[:PI_IPA], xform[2].to_ipa
      assert_equal word[:PI], xform[2].join
    end
  end

  def by_eye #test_by_eye
    %w{ad ad\ tunce alteram alterā\ mente anguillam aprīlem audīre audīs 
       bibēre būculum 
       caecum caldāriam cantāre causam cognoscēre collum coxam cunīculum 
       dehus dē\ post dīcēre dūcem 
       eccistum egō essēre et extinguō 
       facēre factum fīcātum fidem figlīnam foedum flōrem furnum
       galbīnum generem gentem glōria grandem
       habēre historiam hominem hymnum 
       jacēre jam jam\ dūdum illum imperium jocāre 
       laxum linguam locālem longum
       marītum marrītum mātrem montāneam mixtum muttum 
       oblītāre oculum ornāmentum ovum 
       partem pectum pedem paucum paulum pensāre perdiū por\ quid 
         passāre porticum potēre potis potit prophētam propium 
       quam quid quō\ modō 
       ruscinjōla 
       salsīciam sapēre scūppīre sequō sīc spissum stella 
       tempus toccāre tōtum tripālium tūtāre
       ūnam ūnum 
       verācum veritātem vetulum vidēre volēre}.each do |word| 
         p "#{word}: PI #{transform(word)[2].join} /#{transform(word)[2].to_ipa}/, RI #{cyrillize(transform(word)[1]) }, #{transform(word)[1].join} /#{transform(word)[1].to_ipa}/"
       end
  end
end