import json, pathlib, sys
sys.stdout.reconfigure(encoding='utf-8')
arb = json.loads(pathlib.Path('lib/l10n/app_en.arb').read_text(encoding='utf-8'))
keys = {k: v for k,v in arb.items() if not k.startswith('@')}
checks = [
    'newChat','chatHistory','aiPlantConsultant','newChatTooltip','plantSwapMarket',
    'listYourPlant','whatAreYouOffering','titleLabel','descriptionLabel','cityLabel',
    'beFirstToShare','allFilter','cuttingsFilter','seedsFilter','wholePlantsFilter',
    'plantWiki','wikiFilterAll','wikiFilterPetFriendly','wikiFilterLowLight',
    'wikiFilterBeginner','waterLabel','cancel','thisCannotBeUndone','completedLabel',
    'noInfo','myCollection','thisCannotBeUndone','listYourPlant','beFirstShareArea',
    'swapMarket','newChatTooltip','aiConsultant','plantSwapMarket','cuttingsChip',
    'description','listedBy','message','markCompleted','deleteListing','cutLabel',
    'noPlantsMatch','plantWiki','wikiFilter','waterTab','sunLabel','feedLabel',
    'addToCollection','searchByNameOrType','findNextGreenCompanion','wikiFilterAll',
    'cuttingChip','seedsChip','wholePlantChip','postListing',
]
for k in checks:
    val = keys.get(k, 'MISSING')
    if val != 'MISSING':
        print(f'FOUND {k}: {val[:60]}')
    else:
        print(f'MISSING {k}')
