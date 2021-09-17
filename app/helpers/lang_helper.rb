module LangHelper

  def lang_code_to_lang_name(code)
    t "lang.#{code}"
    #case code
    #when 'af'
    #when 'en'
    #  t 'lang.en'
    #when 'ja'
    #  t 'lang.ja'
  end

  def lang_number_to_lang_name(number)
    lang_code_to_lang_name(Lang.convert_number_to_code(number))
    #case number
    #when 21
    #  t('lang.en')
    #when 44
    #  t('lang.ja')
    #else
    #  "#{number} / not found"
    #end
  end

  def lang_form_array
    lang_array = []
    1.upto(109) do |num|
      array = [lang_number_to_lang_name(num), num]
      lang_array << array
    end
    lang_array
  end

  def lang_form_and_auto_configure
    lang_array = lang_form_array
    lang_array.unshift(["#{t 'lang.language_setting'}: #{t 'lang.auto-configure'}", nil])
    lang_array
  end



  # javascripts/answer.js.erb, models/Langと数字と言語の対応を揃える。
  def speech_btn(lang_number)
    case lang_number
    when 21
      'speech-btn-en'
    when 44
      'speech-btn-ja'
    when 14
      'speech-btn-ch'
    when 15
      'speech-btn-tw'
    when 50
      'speech-btn-kr'
    when 25
      'speech-btn-fr'
    when 88
      'speech-btn-es'
    when 77
      'speech-btn-ru'
    when 29
      'speech-btn-de'
    when 43
      'speech-btn-it'
    when 97
      'speech-btn-th'
    when 41
      'speech-btn-id'
    else
      'speech-btn-en'
    end
  end




end
