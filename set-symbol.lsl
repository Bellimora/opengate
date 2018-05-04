string shortlistsymbols = "♈♉♊♋♌♍♎♏♐♑♒♓☼☽☾☿♀♁♂♃♄♅♆  ";
list map = [1,2,3,0,4,5,6];

#define SYMBOL_TEXTURE "b378d2ed-94d7-a7da-4863-7819fb6e8009"

#define ERR_NOT_FOUND -1

vector Symbol2Offsets(string glyph) {
    if (llStringLength(glyph) > 1) return <0, 0, ERR_NOT_FOUND>;
    
    integer gnum = llSubStringIndex(shortlistsymbols, glyph);
    if (gnum == -1) return <0, 0, ERR_NOT_FOUND>;
    
    float h = -.5 + .1 + ((float)(gnum%5)) * .2;
    float v = -.5 + .1 + ((float)(gnum/5)) * .2; 
    
    return <h, -v, 0.0>;
}

list SymbolSettings(string glyph, integer face) {
    return [PRIM_TEXTURE, face, SYMBOL_TEXTURE, <0.2, 0.2, 0>, 
        Symbol2Offsets(glyph)];
}

default
{
    state_entry()
    {
        llSetLinkPrimitiveParamsFast(LINK_THIS, SymbolSettings("♋", 0)+[0.0]+
            SymbolSettings("♊", 1) + [0.0] + SymbolSettings(" ", 2)+ [0.0]);
    }

    touch_start(integer total_number)
    {
        llSay(0, "Touched.");
    }
}
