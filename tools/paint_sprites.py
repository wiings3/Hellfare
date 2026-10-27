"""Paint the crawl sprites (side-on pixel art, 24x28, drawn at 3x on the crawl screen).

Each sprite is a hand-authored grid: one character per pixel, mapped through a palette. Heroes
face right; monsters face left. Run from the project root:

    python3 tools/paint_sprites.py [sheet.png]     # writes assets/ui/crawl/<name>.png
"""
import sys
from PIL import Image

OUT = "assets/ui/crawl/%s.png"

BASE = {
    ".": None, "o": "#160d0c",
}

SPRITES = {}

# --- Heroes (facing right) ------------------------------------------------------------
SPRITES["knight"] = ({
    "S": "#d6dde6", "s": "#9aa4b4", "d": "#5c6576", "R": "#b0352c", "r": "#6e1c1a", "G": "#e7b85a", "g": "#9c7432",
    "W": "#eef3f8", "w": "#9fb0c4", "B": "#7a5638", "b": "#45301f", "e": "#160d0c",
}, [
    ".o......................",
    ".oWo....................",
    "..oWo...................",
    "...oWo..................",
    "....oWo..oooooo.........",
    ".....oWooSSSSSso........",
    "......oWoSSsssdo..R.....",
    ".......oGSoeeeedoRR.....",
    "......oGgGsssssdoR......",
    ".......oBosSssddo.......",
    "......oBBo.oooo.oooooo..",
    ".....oSBsoRRRRo.oSSSSSo.",
    ".....osssoRRrRRooSGGGsdo",
    "......osoRRRrRRooSGRGsdo",
    "......oooRRrRRRooSGRGsdo",
    ".......osRRRRRrooSGGGsdo",
    ".......oBBBGBBBooSsGssdo",
    ".......osRRRRRrooSssssdo",
    ".......osRRrRRroodsssddo",
    ".......osRRRrRro.oddddo.",
    "........oRRRRro...oddo..",
    "........osssoss.o..oo...",
    "........osdoosdo........",
    "........osdo.osdo.......",
    "........osdo..osdo......",
    ".......obbbo..obbbo.....",
    ".......obbbbo.obbbbo....",
    ".......oooooo.oooooo....",
])

SPRITES["rogue"] = ({
    "H": "#4e5a3a", "h": "#2e3622", "C": "#5a4632", "c": "#352719", "K": "#c9946c", "k": "#8a5c40",
    "E": "#f3d27a", "L": "#7a5638", "l": "#45301f", "W": "#e6edf5", "w": "#8f9fb2", "e": "#0b0707", "M": "#9a2f28",
}, [
    "........................",
    "..........oooo..........",
    ".........oHHHHo.........",
    "........oHHHHhho........",
    ".......oHHHhheeho.......",
    ".......oHHheeEeho.......",
    ".......oHhheeeko........",
    "......oHHhhhkKko........",
    "......oHHhhoKKo.........",
    ".....oHHHhhooo..........",
    ".....oHHhhCCCCoo........",
    "....oHHhhCCCcCLLo.......",
    "....oHhhCCMCCcLKKoo.....",
    "...oHHhhCCCMCcoKKKWWo...",
    "...oHhhoCCCCcLoowWWWWo..",
    "...oHhhoLLLLLLo.ooooo...",
    "...oHhhoCCcCCco.........",
    "...oHhhoCCCcCco.........",
    "..oHHhhoCCCCcco.........",
    "..oHhhh.oCCcCco.........",
    "..oHhho.oclllco.........",
    "..oooo..olloolo.........",
    "........ollo.olo........",
    "........olo...olo.......",
    ".......ollo...ollo......",
    ".......occco..occco.....",
    ".......ococco.ocococ....",
    ".......oooooo.oooooo....",
])

# --- Monsters (facing left) -----------------------------------------------------------
SPRITES["rat"] = ({
    "F": "#8d7a6a", "f": "#5e4e42", "x": "#3a2e27", "P": "#d49a8e", "p": "#9a6458", "E": "#e04030", "T": "#b88878",
}, [
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "...oo...oo..............",
    "..oPPo.oPPo.............",
    "..oPpoooPpo.ooooo.......",
    "..ooFFFFFFoFFFFFFoo.....",
    ".oFFEoFFFFFFFFFFFffo....",
    "oPFFFFFFFFFFFFFFFFffo...",
    "oPpoFFFFFFFFFFFFFFfffo..",
    ".oo.oFFfFFFFFFFFFfffxo..",
    "....ofFffFFfFFFfffffxo..",
    ".....oxfffffffffffxxo.oo",
    "......oxxooxxxxooxxo.oTo",
    "......oPpo.oPo.oPpooTo..",
    "......oPpo.oPo.oPpTTo...",
    ".....oPPo.oPPo.oPPoo....",
    ".....oooo.oooo.oooo.....",
])

SPRITES["spider"] = ({
    "A": "#4a3a5a", "a": "#2a1f36", "x": "#170f20", "E": "#e8402e", "e": "#ff9a50", "M": "#7a2a32", "L": "#38294a",
}, [
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "........................",
    "...........oooooo.......",
    ".........ooAAAAAAoo.....",
    "........oAAAaAAAaAAo....",
    ".......oAAMAAAMAAAAAo...",
    "......oAAAAAMMAAAaAAAo..",
    "......oAAaAAAAAAAAaAAo..",
    "..ooo.oAAAAaAAAAAAAAAo..",
    ".oAAAooxAAAAAAAaAAAAxo..",
    "oAEeAAAoxxAAAAAAAAAxxo..",
    "oAAEAAAAooxxxxxxxxxxo...",
    ".oAaAAoLoLoLoooLoLoLo...",
    "..oooooLoLoLo.oLoLoLo...",
    "...oL.oLooLooo.oLooLo...",
    "..oLo.oL.oLo...oL.oLo...",
    ".oLo.oLo.oL.....oL.oL...",
    ".oL..oL..oLo....oLo.oLo.",
    "oLo..oL...oL.....oL..oL.",
    "oL...oo...oo.....oo..oo.",
    "oo......................",
    "........................",
])

SPRITES["bone_knight"] = ({
    "B": "#ddd2bc", "b": "#a99c84", "x": "#6e6454", "R": "#7c5a3e", "r": "#4c3624", "E": "#ff7a2a", "e": "#ffd27a",
    "W": "#c6ccd4", "w": "#7e8796", "K": "#3c2c2a",
}, [
    ".....................oo.",
    "....................oWo.",
    "...................oWwo.",
    "..................oWwo..",
    "....oooooo.......oWwo...",
    "...oKKKKKKo.....oWwo....",
    "..oKxKKKKxKo...oWwo.....",
    "..oKBEoBEBKo..oWwo......",
    "..oKBBoBBBKo.oWwo.......",
    "...oBoBoBbo..oGo........",
    "....obbbbo..oxGxo.......",
    "...ooKxxKoooxbbo........",
    "..oRRRbRRRRRbbo.........",
    ".oRRrRBbRRrRRo..........",
    ".oRrRRBbRRRrRo..........",
    "oRRRRoBbBoRRRRo.........",
    "oRrRRoxbboRRrRo.........",
    "oRRRo.oBbo.oRRo.........",
    ".oRo..oBbo..oRo.........",
    ".obo.oRRRRo..obo........",
    ".oBo.oRrRRo..oBo........",
    "..o..oRRRro...o.........",
    "....oBoo.oBo............",
    "....oBbo.oBbo...........",
    "....oBbo..oBo...........",
    "...oRRro..oRRo..........",
    "..oRRRro..oRRRo.........",
    "..oooooo..ooooo.........",
])
SPRITES["bone_knight"][0]["G"] = "#a07a3a"

# Ser Aldren, the Lantern's Blade: the knight's shape in polished, gilded plate and wine red.
SPRITES["aldren"] = (dict(SPRITES["knight"][0], **{
    "S": "#f1ead2", "s": "#c2b48a", "d": "#7c6a44", "R": "#8a1e2e", "r": "#4e101a", "G": "#ffd56a", "g": "#b8862e",
    "W": "#fff8e8", "w": "#d6c48e",
}), SPRITES["knight"][1])
# Aldren as Death's First Blade: the same man in black plate, with embers where his eyes were.
SPRITES["first_blade"] = (dict(SPRITES["knight"][0], **{
    "S": "#5a5462", "s": "#3a3442", "d": "#221e2a", "R": "#c8481c", "r": "#6e2010", "G": "#ff9a3a", "g": "#a8401a",
    "W": "#d8dce6", "w": "#6a7080", "e": "#ff6a2a",
}), SPRITES["knight"][1])

SPRITES["fiend"] = ({
    "F": "#7a2418", "f": "#4a1610", "x": "#2a0c08", "H": "#d8c4a8", "h": "#8a7660", "E": "#ffd25a", "C": "#ff7a22", "c": "#c84012",
}, [
    "........................",
    "........................",
    "........................",
    "........................",
    "....oo......oo..........",
    "....oHo....oHo..........",
    ".....oHo..oHho..........",
    ".....ohHooHho...........",
    "......ooFFFoo...........",
    ".....oFFFFFFfo..........",
    ".....oFEoFFEfo..........",
    ".....ofFFFFFfo..........",
    "......oFfCfFo...........",
    "..oo...offfo...ooo......",
    ".oFFo.oFFFFFo.oFFFo.....",
    ".oFfFoFFCFFFFoFfFfo.....",
    "..ofFFFCcFFFFFFFfo......",
    "...ooFFFFCFFcFFfo.......",
    ".....oFFFFcCFFfo........",
    ".....ofFFFFFFffo....oo..",
    "......ofFFFFFfo....oCo..",
    "......oFfooFffo...oCo...",
    ".....oFfo..ofFo..oco....",
    ".....oFo....oFo.ofo.....",
    "....oFfo....oFfoofo.....",
    "...offo.....offfo.......",
    "...ooo......oooo........",
    "........................",
])


def paint(name):
    pal, rows = SPRITES[name]
    full = dict(BASE)
    full.update(pal)
    h = len(rows)
    w = max(len(r) for r in rows)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for y, row in enumerate(rows):
        assert len(row) == w, "%s row %d is %d wide" % (name, y, len(row))
        for x, ch in enumerate(row):
            c = full.get(ch)
            if c is None:
                if ch != ".":
                    raise KeyError("%s: unknown %r at %d,%d" % (name, ch, x, y))
                continue
            c = c.lstrip("#")
            img.putpixel((x, y), (int(c[0:2], 16), int(c[2:4], 16), int(c[4:6], 16), 255))
    return img


if __name__ == "__main__":
    names = list(SPRITES)
    imgs = {n: paint(n) for n in names}
    for n, im in imgs.items():
        im.save(OUT % n)
    if len(sys.argv) > 1:
        k = 6
        sheet = Image.new("RGBA", (len(names) * 26 * k, 30 * k), (60, 34, 26, 255))
        for i, n in enumerate(names):
            im = imgs[n].resize((imgs[n].width * k, imgs[n].height * k), Image.NEAREST)
            sheet.alpha_composite(im, (i * 26 * k + k, k))
        sheet.save(sys.argv[1])
    print("painted %d sprites" % len(names))
