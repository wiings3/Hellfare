extends RefCounted
class_name Names
## Names for new applicants: a first name from MALE or FEMALE (even odds) and a family name.
## A name is chosen once, when the person is made, and saved with them; changing these lists
## only changes who turns up next.

const MALE := [
	"Edric", "Tobin", "Lukas", "Rurik", "Alric", "Hale", "Perrin", "Otto", "Torren", "Bastian", "Merrin", "Aldous",
	"Ambrose", "Anselm", "Ansel", "Arnulf", "Aric", "Ashby", "Audric", "Baldric", "Barnabas", "Bartram", "Bede", "Benedek",
	"Berold", "Bertil", "Bjorn", "Boris", "Bram", "Brandt", "Brennan", "Brom", "Caddock", "Cael", "Cassian", "Cedric",
	"Conrad", "Corwin", "Cuthbert", "Dagmar", "Dain", "Dallan", "Darius", "Declan", "Desmond", "Dietrich", "Dorian", "Drogo",
	"Duncan", "Eadric", "Eamon", "Egil", "Einar", "Elias", "Emeric", "Emrys", "Enoch", "Erland", "Ewald", "Fabian",
	"Falk", "Faramond", "Fergus", "Florian", "Folke", "Fulk", "Gareth", "Gaspard", "Gawain", "Gerolt", "Gideon", "Gilbert",
	"Godric", "Gorm", "Gregor", "Griffin", "Gunnar", "Gustav", "Hadrian", "Hagen", "Halvard", "Harald", "Hector", "Henrik",
	"Herrick", "Hilmar", "Holger", "Hugo", "Idris", "Igor", "Ingram", "Isidore", "Ivo", "Jareth", "Jasper", "Jonas",
	"Jorund", "Josef", "Jurgen", "Kaspar", "Kellan", "Kenric", "Konrad", "Lambert", "Leif", "Leofric", "Leopold", "Lorcan",
	"Lothar", "Magnus", "Malcolm", "Manfred", "Marek", "Matthias", "Milo", "Mordecai", "Morten", "Nestor", "Niall", "Nikolai",
	"Njal", "Norbert", "Odo", "Olaf", "Oleg", "Orrin", "Osric", "Oswin", "Pavel", "Piers", "Quentin", "Radek",
	"Ragnar", "Ralf", "Randolf", "Reinhold", "Reynard", "Roderic", "Roland", "Rolf", "Rowan", "Rufus", "Sabin", "Sefton",
	"Sigurd", "Silas", "Simeon", "Soren", "Stellan", "Stefan", "Sven", "Tancred", "Teodor", "Thaddeus", "Theobald", "Thorne",
	"Tiberius", "Tomas", "Ulric", "Urien", "Valdemar", "Valen", "Vasil", "Viktor", "Vitus", "Walden", "Walther", "Warrick",
	"Wendel", "Wilhelm", "Wolfram", "Wulfric", "Yorick", "Yuri", "Zoltan", "Absalom", "Alaric", "Anders", "Anton", "Armin",
	"Arvid", "Augustin", "Axel", "Benedikt", "Caspian", "Cormac", "Crispin", "Dmitri", "Edmund", "Elric", "Erasmus", "Evander",
	"Ferdinand", "Gethin", "Gotthard", "Hamish", "Lennart", "Lucan", "Mathis", "Oskar",
]

const FEMALE := [
	"Nessa", "Cora", "Yara", "Fenna", "Daria", "Bryn", "Vera", "Anja", "Celia", "Adela", "Agatha", "Agnes",
	"Aldith", "Alis", "Alys", "Amalie", "Annika", "Ansa", "Ardith", "Astrid", "Aveline", "Beatrix", "Benedikta", "Bertha",
	"Birgit", "Blanche", "Brigid", "Brunhild", "Cassia", "Catrin", "Cecily", "Clemence", "Constance", "Dagny", "Dorota", "Edda",
	"Edith", "Eira", "Elfrida", "Elin", "Elisabet", "Elke", "Elodie", "Elsbeth", "Embla", "Emmeline", "Erika", "Ermengard",
	"Esme", "Estrid", "Ethelind", "Eudora", "Eva", "Freya", "Frida", "Gisela", "Greta", "Gudrun", "Gunhild", "Gwen",
	"Gwendolyn", "Hadewych", "Hanne", "Hedda", "Hedwig", "Helga", "Helene", "Hilda", "Hildegard", "Honora", "Ida", "Ilse",
	"Imogen", "Ingrid", "Irmgard", "Isolde", "Ivana", "Jadwiga", "Johanna", "Jutta", "Karin", "Katla", "Katrin", "Kerstin",
	"Klara", "Ksenia", "Laila", "Lene", "Liesel", "Linnea", "Liv", "Lotte", "Lucia", "Ludmila", "Lys", "Mabel",
	"Magda", "Maren", "Margit", "Marit", "Marta", "Mathilde", "Maud", "Mercia", "Milena", "Mirela", "Moira", "Morwenna",
	"Nadia", "Nell", "Nerys", "Odile", "Olwen", "Orla", "Ottilie", "Petra", "Philippa", "Ragna", "Ragnhild", "Rhosyn",
	"Rosalind", "Rowena", "Runa", "Sabine", "Saga", "Selma", "Senna", "Sigrid", "Signy", "Silke", "Solveig", "Sonja",
	"Svea", "Sybil", "Tamsin", "Tess", "Thea", "Thora", "Tilde", "Tova", "Ulla", "Ulrike", "Una", "Ursula",
	"Valka", "Vesna", "Vigdis", "Wilma", "Winifred", "Wren", "Ysolde", "Zdenka", "Zora", "Alba", "Alma", "Aud",
	"Branka", "Carys", "Della", "Dunja", "Edeline", "Elva", "Ffion", "Gaia", "Hesper", "Ilka", "Isa", "Jorunn",
	"Kaja", "Leda", "Lena", "Liora", "Mila", "Nadja", "Oda", "Perpetua", "Rozalia", "Saskia", "Tyra", "Vala",
	"Wanda", "Yrsa", "Briar", "Gerda", "Rhiannon", "Sunniva", "Ottilia", "Aelis", "Brenna", "Cressida", "Dagrun", "Elowen",
	"Halla", "Inga", "Jessamy", "Kirsten", "Morgana", "Rosamund", "Sigrun", "Oriel",
]

const LAST := [
	"Blackstone", "Moor", "Fell", "Ash", "Holt", "Voss", "Wick", "Vale", "Fallow", "Dunn", "Marsh", "Rook",
	"Ashby", "Ashcombe", "Ashford", "Aldmoor", "Amberly", "Anvil", "Ardwell", "Arkwright", "Barrow", "Beck", "Bell", "Birch",
	"Blackburn", "Blackwood", "Blight", "Bone", "Bracken", "Bramble", "Brand", "Brennick", "Briar", "Brimley", "Brook", "Burrow",
	"Byrne", "Cairn", "Calder", "Carrow", "Chalk", "Cinder", "Clay", "Coldwell", "Cole", "Corbet", "Crane", "Croft",
	"Crowe", "Cullen", "Dagger", "Dale", "Darke", "Deepwell", "Dorn", "Drake", "Dray", "Dusk", "Eastwick", "Elder",
	"Embers", "Falke", "Farrow", "Fenwick", "Finch", "Flint", "Forge", "Fox", "Frost", "Fulbright", "Gale", "Garrow",
	"Gaunt", "Glass", "Gloom", "Goodfellow", "Gorse", "Graves", "Greaves", "Grey", "Grimm", "Grove", "Hackett", "Halloran",
	"Hammer", "Harrow", "Hawke", "Hayward", "Heath", "Hedge", "Helm", "Hester", "Hobb", "Holloway", "Horne", "Ironside",
	"Ivey", "Kettle", "Keyes", "Kiln", "Knell", "Knox", "Lark", "Lathe", "Leach", "Lindqvist", "Lock", "Locke",
	"Lowe", "Mallory", "Mander", "Marlow", "Mayne", "Merrow", "Mill", "Mire", "Morrow", "Mott", "Nail", "Nettle",
	"North", "Oakes", "Orme", "Pale", "Pike", "Pitt", "Plume", "Poole", "Quarry", "Quill", "Rain", "Raven",
	"Reed", "Reeve", "Ridley", "Roan", "Rooke", "Rowe", "Rush", "Rust", "Sallow", "Salt", "Scrope", "Sedge",
	"Shale", "Sharpe", "Shaw", "Silt", "Slade", "Smoke", "Soot", "Sorrel", "Stark", "Steel", "Stone", "Storm",
	"Strand", "Strom", "Swale", "Swift", "Tallow", "Tanner", "Tarn", "Thatch", "Thorn", "Thorpe", "Tide", "Till",
	"Tolle", "Tower", "Trask", "Tull", "Underhill", "Vetch", "Warden", "Warren", "Weld", "Whitlock", "Wilde", "Winter",
	"Wolfe", "Wren", "Yarrow", "Yew", "Adler", "Albrecht", "Baumann", "Becker", "Brandauer", "Dressler", "Eberhardt", "Falkner",
	"Fischer", "Gerber", "Haller", "Hartmann", "Hessler", "Holzer", "Kessler", "Kohler", "Lang", "Lehmann", "Messner", "Nagel",
	"Ostrow", "Pfeiffer", "Reiter", "Roth", "Sauer", "Schaller", "Seidel", "Stahl", "Steiner", "Strauss", "Vogel", "Wagner",
	"Weber", "Winkler", "Zeller", "Novak", "Kral", "Dvorak", "Horak", "Marek", "Sokol", "Vesely", "Zeman", "Kowal",
	"Mazur", "Wilk", "Corran", "Dunmore", "Galloway", "Kincaid", "MacRae", "Ogilvy", "Rennick", "Strachan", "Tavish", "Brannock",
	"Ashgrove", "Bleakley", "Blackthorn", "Bonewright", "Briarwood", "Coalbrook", "Cragg", "Crossley", "Darrow", "Duskwood", "Emberly", "Fairweather",
	"Fenn", "Gallow", "Graywater", "Hallow", "Hollins", "Ironwood", "Larkspur", "Marchbank", "Mosswood", "Nightingale", "Oakheart", "Pennick",
	"Ravenscroft", "Redgrave", "Rookwood", "Saltmarsh", "Shadwell", "Stonebridge", "Thornbury", "Wexley", "Whitmore", "Wolfsbane", "Wychwood", "Ainsley",
	"Bracewell", "Cobb", "Deverell", "Eskdale", "Grimsby", "Hargrove", "Kettering", "Merriweather", "Penhallow", "Quarrell", "Rathbone", "Tolliver",
	"Undercroft", "Wakefield", "Ashwin", "Cardew", "Haldane", "Prentice", "Stroud", "Tregarth", "Wolcott", "Ashdown", "Brightwater", "Coldharbour",
	"Cresswell", "Dunwich", "Gilchrist", "Ingle", "Kestrel", "Lockhart", "Norwood", "Pembrook", "Radley", "Selwyn", "Trevelyan", "Wainwright",
	"Wetherby", "Yardley", "Abernath", "Carver", "Dunstan", "Everard", "Fletcher", "Jessop", "Kemble", "Lisle", "Morcant", "Oswald",
	"Pryce", "Quaile", "Rourke", "Stannard", "Thackeray", "Varden", "Wyndham", "Bramwell", "Chadwick", "Draycott", "Fosse", "Gorringe",
	"Hatherley", "Inchley", "Jolliffe", "Kirkby", "Ludlow", "Mortimer", "Nettleton", "Overton", "Pargeter", "Ramsden", "Tennant", "Upton",
	"Venn", "Woolley",
]

static func pick(rng: RandomNumberGenerator) -> String:
	var firsts: Array = MALE if rng.randf() < 0.5 else FEMALE
	return str(firsts[rng.randi_range(0, firsts.size() - 1)]) + " " + str(LAST[rng.randi_range(0, LAST.size() - 1)])

## Guild names for the prologue's suggestion ("The Ashen Lanterns", "Cinder Oath").
const GUILD_FIRST := ["Ashen", "Ember", "Cinder", "Iron", "Last", "Soot", "Red", "Hollow", "Lantern", "Brimstone",
	"Pale", "Sable", "Crimson", "Smoke", "Gallows", "Candle", "Ironbound", "Lost", "Sworn"]
const GUILD_SECOND := ["Lanterns", "Oath", "Company", "Wardens", "Hand", "Brotherhood", "Covenant", "Watch", "Delvers", "Torches",
	"Guild", "Banner", "Vigil", "Pact", "Descent", "Keepers", "Kindred", "Coin"]

static func guild(rng: RandomNumberGenerator) -> String:
	var a: String = GUILD_FIRST[rng.randi_range(0, GUILD_FIRST.size() - 1)]
	var b: String = GUILD_SECOND[rng.randi_range(0, GUILD_SECOND.size() - 1)]
	return ("The %s %s" % [a, b]) if rng.randf() < 0.6 else "%s %s" % [a, b]
