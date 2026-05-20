import json, sys, pathlib
sys.stdout.reconfigure(encoding='utf-8')

# Step 1: Add 8 keys + metadata to app_en.arb
en_path = pathlib.Path('lib/l10n/app_en.arb')
arb = json.loads(en_path.read_text(encoding='utf-8'))

new_entries = {
    'addGrowthPhotosForTimelapse': 'Add more growth photos to create a time lapse \u2014 you need at least 2',
    'growthTimelapse': 'Growth Time-lapse',
    'tapPhotosToViewJourney': "Tap photos to view your plant's journey",
    'moveToMemorialGarden': 'Move to Memorial Garden',
    'leaveNoteAboutPlant': 'Would you like to leave a note about {plantName}?',
    '@leaveNoteAboutPlant': {'placeholders': {'plantName': {'type': 'String'}}},
    'memorialNoteHint': 'Memorial note...',
    'farewellToPlant': 'A farewell to {plantName} \U0001f54a\ufe0f',
    '@farewellToPlant': {'placeholders': {'plantName': {'type': 'String'}}},
    'thankYouForDaysOfCare': 'Thank you for {days} days of care',
    '@thankYouForDaysOfCare': {'placeholders': {'days': {'type': 'int'}}},
}
arb.update(new_entries)
en_path.write_text(json.dumps(arb, ensure_ascii=False, indent=2), encoding='utf-8')
print('app_en.arb updated with 8 keys')

# Step 2: Propagate translations to 14 non-English ARB files
translations = {
    'addGrowthPhotosForTimelapse': {
        'es': 'Agrega m\xe1s fotos de crecimiento para crear un time-lapse \u2014 necesitas al menos 2',
        'fr': 'Ajoutez plus de photos de croissance pour cr\xe9er un time-lapse \u2014 vous en avez besoin d\u2019au moins 2',
        'de': 'F\xfcge mehr Wachstumsfotos hinzu, um einen Zeitraffer zu erstellen \u2014 du ben\xf6tigst mindestens 2',
        'pt': 'Adicione mais fotos de crescimento para criar um time-lapse \u2014 voc\xea precisa de pelo menos 2',
        'ar': '\u0623\u0636\u0641 \u0627\u0644\u0645\u0632\u064a\u062f \u0645\u0646 \u0635\u0648\u0631 \u0627\u0644\u0646\u0645\u0648 \u0644\u0625\u0646\u0634\u0627\u0621 \u0641\u064a\u0644\u0645 \u0632\u0645\u0646\u064a \u2014 \u062a\u062d\u062a\u0627\u062c \u0625\u0644\u0649 \u0635\u0648\u0631\u062a\u064a\u0646 \u0639\u0644\u0649 \u0627\u0644\u0623\u0642\u0644',
        'fa': '\u0639\u06a9\u0633\u200c\u0647\u0627\u06cc \u0631\u0634\u062f \u0628\u06cc\u0634\u062a\u0631\u06cc \u0628\u0631\u0627\u06cc \u0627\u06cc\u062c\u0627\u062f \u062a\u0627\u06cc\u0645\u200c\u0644\u067e \u0627\u0636\u0627\u0641\u0647 \u06a9\u0646\u06cc\u062f \u2014 \u062d\u062f\u0627\u0642\u0644 \u0628\u0647 \u06f2 \u0639\u06a9\u0633 \u0646\u06cc\u0627\u0632 \u062f\u0627\u0631\u06cc\u062f',
        'ja': '\u30bf\u30a4\u30e0\u30e9\u30d7\u30b9\u3092\u4f5c\u6210\u3059\u308b\u306b\u306f\u6210\u9577\u5199\u771f\u3092\u8ffd\u52a0\u3057\u3066\u304f\u3060\u3055\u3044 \u2014 \u5c11\u306a\u304f\u3068\u30822\u679a\u5fc5\u8981\u3067\u3059',
        'ko': '\ud0c0\uc784\ub7a9\uc2a4\ub97c \ub9cc\ub4e4\ub824\uba74 \uc131\uc7a5 \uc0ac\uc9c4\uc744 \ub354 \ucd94\uac00\ud558\uc138\uc694 \u2014 \ucd5c\uc18c 2\uc7a5 \ud544\uc694',
        'it': 'Aggiungi pi\xf9 foto di crescita per creare un time-lapse \u2014 ne servono almeno 2',
        'nl': 'Voeg meer groeifotos toe om een time-lapse te maken \u2014 je hebt er minstens 2 nodig',
        'tr': 'Zaman atlamal\u0131 video olu\u015fturmak i\xe7in daha fazla b\xfcy\xfcme foto\u011fraf\u0131 ekleyin \u2014 en az 2 taneye ihtiyac\u0131n\u0131z var',
        'pl': 'Dodaj wi\u0119cej zdj\u0119\u0107 wzrostu, aby stworzy\u0107 poklatkowy \u2014 potrzebujesz co najmniej 2',
        'sv': 'L\xe4gg till fler tillv\xe4xtfoton f\xf6r att skapa en tidsf\xf6rloppsvideo \u2014 du beh\xf6ver minst 2',
        'hi': '\u091f\u093e\u0907\u092e-\u0932\u0948\u092a\u094d\u0938 \u092c\u0928\u093e\u0928\u0947 \u0915\u0947 \u0932\u093f\u090f \u0914\u0930 \u092c\u0922\u093c\u0924\u0947 \u0939\u0941\u090f \u092b\u093c\u094b\u091f\u094b \u091c\u094b\u0921\u093c\u0947\u0902 \u2014 \u0906\u092a\u0915\u094b \u0915\u092e \u0938\u0947 \u0915\u092e 2 \u091a\u093e\u0939\u093f\u090f',
    },
    'growthTimelapse': {
        'es': 'Time-lapse de crecimiento', 'fr': 'Time-lapse de croissance', 'de': 'Wachstums-Zeitraffer',
        'pt': 'Time-lapse de crescimento', 'ar': '\u0627\u0644\u0641\u064a\u0644\u0645 \u0627\u0644\u0632\u0645\u0646\u064a \u0644\u0644\u0646\u0645\u0648', 'fa': '\u062a\u0627\u06cc\u0645\u200c\u0644\u067e \u0631\u0634\u062f',
        'ja': '\u6210\u9577\u30bf\u30a4\u30e0\u30e9\u30d7\u30b9', 'ko': '\uc131\uc7a5 \ud0c0\uc784\ub7a9\uc2a4', 'it': 'Time-lapse di crescita',
        'nl': 'Groeitijdsverloop', 'tr': 'B\xfcy\xfcme Zaman Atlamal\u0131', 'pl': 'Poklatkowy wzrostu',
        'sv': 'Tillv\xe4xt-tidsf\xf6rlopp', 'hi': '\u0935\u093f\u0915\u093e\u0938 \u091f\u093e\u0907\u092e-\u0932\u0948\u092a\u094d\u0938',
    },
    'tapPhotosToViewJourney': {
        'es': 'Toca las fotos para ver el viaje de tu planta',
        'fr': 'Appuyez sur les photos pour voir le parcours de votre plante',
        'de': 'Tippe auf die Fotos, um die Reise deiner Pflanze zu sehen',
        'pt': 'Toque nas fotos para ver a jornada da sua planta',
        'ar': '\u0627\u0646\u0642\u0631 \u0639\u0644\u0649 \u0627\u0644\u0635\u0648\u0631 \u0644\u0645\u0634\u0627\u0647\u062f\u0629 \u0631\u062d\u0644\u0629 \u0646\u0628\u0627\u062a\u0643',
        'fa': '\u0628\u0631\u0627\u06cc \u0645\u0634\u0627\u0647\u062f\u0647 \u0633\u0641\u0631 \u06af\u06cc\u0627\u0647 \u062e\u0648\u062f \u0631\u0648\u06cc \u0639\u06a9\u0633\u200c\u0647\u0627 \u0636\u0631\u0628\u0647 \u0628\u0632\u0646\u06cc\u062f',
        'ja': '\u5199\u771f\u3092\u30bf\u30c3\u30d7\u3057\u3066\u690d\u7269\u306e\u6210\u9577\u306e\u65c5\u3092\u8868\u793a',
        'ko': '\uc0ac\uc9c4\uc744 \ud0ed\ud558\uc5ec \uc2dd\ubb3c\uc758 \uc5ec\uc815\uc744 \ubcf4\uc138\uc694',
        'it': 'Tocca le foto per vedere il viaggio della tua pianta',
        'nl': 'Tik op fotos om de reis van je plant te bekijken',
        'tr': 'Bitkinin yolculu\u011funu g\xf6rmek i\xe7in foto\u011fraflara dokunun',
        'pl': 'Dotkni\u0119cie zdj\u0119\u0107, aby zobaczy\u0107 podr\xf3\u017c swojej ro\u015bliny',
        'sv': 'Tryck p\xe5 foton f\xf6r att se din plants resa',
        'hi': '\u0905\u092a\u0928\u0947 \u092a\u094c\u0927\u0947 \u0915\u0940 \u092f\u093e\u0924\u094d\u0930\u093e \u0926\u0947\u0916\u0928\u0947 \u0915\u0947 \u0932\u093f\u090f \u092b\u093c\u094b\u091f\u094b \u092a\u0930 \u091f\u0948\u092a \u0915\u0930\u0947\u0902',
    },
    'moveToMemorialGarden': {
        'es': 'Mover al Jard\xedn Memorial', 'fr': 'D\xe9placer vers le Jardin Comm\xe9moratif',
        'de': 'In den Gedenkgarten verschieben', 'pt': 'Mover para o Jardim Memorial',
        'ar': '\u0627\u0646\u0642\u0644 \u0625\u0644\u0649 \u062d\u062f\u064a\u0642\u0629 \u0627\u0644\u0630\u0643\u0631\u0649', 'fa': '\u0627\u0646\u062a\u0642\u0627\u0644 \u0628\u0647 \u0628\u0627\u063a \u06cc\u0627\u062f\u0628\u0648\u062f',
        'ja': '\u30e1\u30e2\u30ea\u30a2\u30eb\u30ac\u30fc\u30c7\u30f3\u306b\u79fb\u52d5', 'ko': '\ucd94\ubaa8 \uc815\uc6d0\uc73c\ub85c \uc774\ub3d9',
        'it': 'Sposta nel Giardino della Memoria', 'nl': 'Verplaatsen naar Herdenkingstuin',
        'tr': 'An\u0131 Bah\xe7esine Ta\u015f\u0131', 'pl': 'Przenie\u015b do Ogrodu Pami\u0119ci',
        'sv': 'Flytta till Minnestr\xe4dg\xe5rden', 'hi': '\u0938\u094d\u092e\u093e\u0930\u0915 \u0909\u0926\u094d\u092f\u093e\u0928 \u092e\u0947\u0902 \u0932\u0947 \u091c\u093e\u090f\u0901',
    },
    'leaveNoteAboutPlant': {
        'es': '\u00bfTe gustar\xeda dejar una nota sobre {plantName}?',
        'fr': 'Souhaitez-vous laisser une note \xe0 propos de {plantName}\u00a0?',
        'de': 'M\xf6chtest du eine Notiz \xfcber {plantName} hinterlassen?',
        'pt': 'Gostaria de deixar uma nota sobre {plantName}?',
        'ar': '\u0647\u0644 \u062a\u0631\u063a\u0628 \u0641\u064a \u062a\u0631\u0643 \u0645\u0644\u0627\u062d\u0638\u0629 \u062d\u0648\u0644 {plantName}\u061f',
        'fa': '\u0622\u06cc\u0627 \u0645\u06cc\u200c\u062e\u0648\u0627\u0647\u06cc\u062f \u06cc\u0627\u062f\u062f\u0627\u0634\u062a\u06cc \u062f\u0631\u0628\u0627\u0631\u0647 {plantName} \u0628\u06af\u0630\u0627\u0631\u06cc\u062f\u061f',
        'ja': '{plantName}\u306b\u95a2\u3059\u308b\u30e1\u30e2\u3092\u6b8b\u3057\u307e\u3059\u304b\uff1f',
        'ko': '{plantName}\uc5d0 \ub300\ud55c \uba54\ubaa8\ub97c \ub0a8\uae30\uc2dc\uaca0\uc5b4\uc694?',
        'it': 'Vuoi lasciare una nota su {plantName}?', 'nl': 'Wil je een notitie achterlaten over {plantName}?',
        'tr': '{plantName} hakk\u0131nda bir not b\u0131rakmak ister misiniz?',
        'pl': 'Czy chcesz zostawi\u0107 notatk\u0119 o {plantName}?',
        'sv': 'Vill du l\xe4mna en anteckning om {plantName}?',
        'hi': '\u0915\u094d\u092f\u093e \u0906\u092a {plantName} \u0915\u0947 \u092c\u093e\u0930\u0947 \u092e\u0947\u0902 \u090f\u0915 \u0928\u094b\u091f \u091b\u094b\u0921\u093c\u0928\u093e \u091a\u093e\u0939\u0947\u0902\u0917\u0947?',
    },
    'memorialNoteHint': {
        'es': 'Nota conmemorativa...', 'fr': 'Note comm\xe9morative...', 'de': 'Gedenknotiz...',
        'pt': 'Nota memorial...', 'ar': '\u0645\u0644\u0627\u062d\u0638\u0629 \u062a\u0630\u0643\u0627\u0631\u064a\u0629...',
        'fa': '\u06cc\u0627\u062f\u062f\u0627\u0634\u062a \u06cc\u0627\u062f\u0628\u0648\u062f...', 'ja': '\u8ffd\u608a\u30e1\u30e2...',
        'ko': '\ucd94\ubaa8 \ub178\ud2b8...', 'it': 'Nota commemorativa...', 'nl': 'Herdenkingsnotitie...',
        'tr': 'An\u0131 notu...', 'pl': 'Notatka pami\u0105tkowa...', 'sv': 'Minnesanteckning...',
        'hi': '\u0938\u094d\u092e\u093e\u0930\u0915 \u0928\u094b\u091f...',
    },
    'farewellToPlant': {
        'es': 'Una despedida a {plantName} \U0001f54a\ufe0f',
        'fr': 'Un adieu \xe0 {plantName} \U0001f54a\ufe0f',
        'de': 'Ein Abschied von {plantName} \U0001f54a\ufe0f',
        'pt': 'Uma despedida para {plantName} \U0001f54a\ufe0f',
        'ar': '\u0648\u062f\u0627\u0639\u064b\u0627 \u0644\u0640 {plantName} \U0001f54a\ufe0f',
        'fa': '\u062e\u062f\u0627\u062d\u0627\u0641\u0638\u06cc \u0628\u0627 {plantName} \U0001f54a\ufe0f',
        'ja': '{plantName}\u3078\u306e\u5225\u308c \U0001f54a\ufe0f',
        'ko': '{plantName}\uc5d0\uac8c \uc774\ubcc4\uc744 \U0001f54a\ufe0f',
        'it': 'Un addio a {plantName} \U0001f54a\ufe0f',
        'nl': 'Een afscheid van {plantName} \U0001f54a\ufe0f',
        'tr': "{plantName}'e veda \U0001f54a\ufe0f",
        'pl': 'Po\u017cegnanie z {plantName} \U0001f54a\ufe0f',
        'sv': 'Ett farv\xe4l till {plantName} \U0001f54a\ufe0f',
        'hi': '{plantName} \u0915\u094b \u0935\u093f\u0926\u093e\u0908 \U0001f54a\ufe0f',
    },
    'thankYouForDaysOfCare': {
        'es': 'Gracias por {days} d\xedas de cuidado',
        'fr': 'Merci pour {days} jours de soins',
        'de': 'Danke f\xfcr {days} Tage F\xfcrsorge',
        'pt': 'Obrigado por {days} dias de cuidado',
        'ar': '\u0634\u0643\u0631\u064b\u0627 \u0644\u0643 \u0639\u0644\u0649 {days} \u064a\u0648\u0645\u064b\u0627 \u0645\u0646 \u0627\u0644\u0631\u0639\u0627\u064a\u0629',
        'fa': '\u0628\u0627 \u062a\u0634\u06a9\u0631 \u0627\u0632 {days} \u0631\u0648\u0632 \u0645\u0631\u0627\u0642\u0628\u062a',
        'ja': '{days}\u65e5\u9593\u306e\u30b1\u30a2\u3092\u3042\u308a\u304c\u3068\u3046',
        'ko': '{days}\uc77c\uac04\uc758 \ub3cc\ubd09 \uac10\uc0ac\ud569\ub2c8\ub2e4',
        'it': 'Grazie per {days} giorni di cura',
        'nl': 'Dank je voor {days} dagen zorg',
        'tr': '{days} g\xfcnl\xfck bak\u0131m i\xe7in te\u015fekk\xfcrler',
        'pl': 'Dzi\u0119kuj\u0119 za {days} dni opieki',
        'sv': 'Tack f\xf6r {days} dagars omsorg',
        'hi': '{days} \u0926\u093f\u0928\u094b\u0902 \u0915\u0940 \u0926\u0947\u0916\u092d\u093e\u0932 \u0915\u0947 \u0932\u093f\u090f \u0927\u0928\u094d\u092f\u0935\u093e\u0926',
    },
}

for p in pathlib.Path('lib/l10n').glob('app_*.arb'):
    if p.name == 'app_en.arb':
        continue
    lang = p.stem.replace('app_', '')
    data = json.loads(p.read_text(encoding='utf-8'))
    for key, lang_map in translations.items():
        if lang in lang_map:
            data[key] = lang_map[lang]
    p.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f'{p.name}: updated')

print('Done.')
