version = "0.62u"
using Sockets
using Random: randperm
using Printf
using Distributed
macOS = false
myPlayer = 1
haBai = false
Pre_haBai = false
const plHuman = 0
const plBot1 = 1
const plBot2 = 2
const plBot3 = 3
const plSocket = 5
const m_client = 0
const m_server = 1
const m_standalone = 2
boxes = []
noRandom = false
const bRANDOM = 1
const bProbability = 2
const bMax = 3
const bAI = 4

function setPlayerName(root,trait)
    n = ["","","",""]
    for i in 1:4
        n[i] = string(root[i],trait[i])
    end
    return n
end
cFlag = true
gameTrashCnt = gameTrashCntLatest = zeros(Int8,4)
gameEnd = 1

coinsCnt = 0
coinsArr = [[0,0],[0,0],[0,0],[0,0]]
wantFaceDown = true
openAllCard = !wantFaceDown

match = 0
emBaiLimit = zeros(Int8,4)
gameWin = [0,0,0,0]
elevateDead = 0
defensiveFlag = [true,true,true,true]
boDoiFlag =  [true,true,true,true]
boDoiFlag = 
boDoiCard = 0
oneTime = true
emBaiTrigger = [[-1,0,0],[-1,0,0],[-1,0,0],[-1,0,0]]
capturedCPoints = [[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]
reduceFile = false
bodoiInspect = false
upgradeAllowPrint = 0
allowPrint = stickyAllowPrint = 0
turnOffBoDoi = false
aiFilename = ""
gameStart = false
faceDownSync = false
cardScale = 80
noGUI_list = [true,true,true,true]
PlayerList =[plBot1,plBot1,plBot1,plBot1]
aiTrait = [19,19,19,19]
aiType = aiTrait .>>2
boDoiFlag = (aiTrait .& 1 ) .!= 0
mydefensiveFlag = (defensiveFlag .& ((aiTrait .& 2) .!= 0))
println(boDoiFlag,mydefensiveFlag)
#aiType = [3,3,3,3]
GUIname = Vector{Any}(undef,4)
boDoiPic = Vector{Any}(undef,4)
numberOfSocketPlayer = 0
playerRootName = ["","","",""] # for bookeeping
playerName = setPlayerName(playerRootName,aiTrait)
shuffled = false
coDoiPlayer = 0
coDoiCards = []
coins = []
gameCmd = '.'
chFilenameStr = "123456789abcdefghijklmpqrstuvxyz"
GUI_busy = false
baiThui = false
points = zeros(Int8,4)
matchSingle = zeros(UInt8,4)
stopOn = ""
playerSuitsCnt = zeros(UInt8,4)
kpoints = zeros(Int8,4)
khui = [1,1,1,1]
khapMatDau = zeros(Int8,4)
pots = zeros(Int,4)
histFile = false
reloadFile = false
connectedPlayer = 0
nameSynced = true
trial = false
atest = []
tstMoveArray = []
all_assets_marks = zeros(UInt8,128)
boDoiPlayers = zeros(UInt8,4)
PlayedCardCnt = zeros(UInt8,32)
echoOption = ""
playerMaptoGUI(m) = rem(m-1+4-myPlayer+1,4)+1
GUIMaptoPlayer(m) = rem(m-1+myPlayer-1,4)+1
noGUI() = noGUI_list[myPlayer]
deadCards = [[],[],[],[]]
probableCards = [[],[],[],[]]
prevDeck = false
prevCard = 0x10
prevN1 = 0
noSingle = [false,false,false,false]
okToPrint(a) = allowPrint&a != 0

cmpPoints(playerSuitsCnt, khui,kpoints) = playerSuitsCnt.*khui+kpoints.*khui
a =cmpPoints(2,1,3)
emBaiLimit = [a,a,a,a]
println("Default Em-bai limit = ",emBaiLimit)


module TuSacCards
    using Random: randperm
    import Random: shuffle!

    import Base
    allowPrint = 0
    # Suits/Colors
    export T, V, D, X # aliases White, Yellow, Red, Green

    # Card, and Suit
    export Card, Suit

    # Card properties
    export suit, rank, high_value, low_value, color

    # Lists of all ranks / suits
    export ranks, suits, duplicate

    # Deck & deck-related methods
    export Deck, shuffle!, ssort, full_deck, reduce_deck, ordered_deck
    export ordered_deck_chot, humanShuffle!, dealCards, full_deck_chot, 
           ordered_reduce_deck, toCardArray
    export getCards, rearrange, sort!, rcut, moveCards!,cardStrToVal
    export test_deck, toValueArray, newDeckUsingArray,allwPrint
    #####
    ##### Types
    #####
    okToPrint(a) = allowPrint&a != 0

    function allwPrint(a)
        allowPrint = a
    end
    """
        In TuSac, cards has 4 suit of color: White,Yellow,Red,Green

    Encode a suit as a 2-bit value (low bits of a `UInt8`):
    - 0 = T rang (White)
    - 1 = X anh (Greed)
    - 2 = V ang (Yellow)
    - 3 = D o (Red)

    Suits have global constant bindings: `T`, `V`, `D`, `X`.
    """
    struct Suit
        i::UInt8
        Suit(s::Integer) =
            0 ≤ s ≤ 3 ? new(s) : throw(ArgumentError("invalid suit number: $s"))
    end


    """
        char

    Return the unicode characters:
    """
    const T = Suit(0)
    const V = Suit(1)
    const D = Suit(2)
    const X = Suit(3)

    char(s::Suit) = Char("TVDX"[s.i+1])
    Base.string(s::Suit) = string(char(s))
    Base.show(io::IO, s::Suit) = print(io, char(s))


    """
    Encode a playing card as a 3 bits number [4:2]
    The next 2 bits bit[6:5] encodes the suit/color. The
    bottom 2 bits bit[1:0] indicates cnt of card of same.

    -----: not used (0x0 value)
    Tuong: 1
    si   : 2
    tuong: 3
    xe   : 5
    phao : 6
    ma   : 7
    chot : 4
    The upper 1 bits bit[2] encode 'groups' as [Tuong-si-tuong],  or
    [xe-phao-ma, chot]

    bit[1:0] count the 4 cards for each card
    bit[6:5] encodes the colors
    """

    struct Card
        value::UInt8
        function Card(r::Integer, s::Integer)
            (0 <= r <= 31 && ((r & 0x1c) != 0)) ||
                throw(ArgumentError("invalid card : $r"))
            return new(UInt8((s << 5) | r))
        end
        function Card(i::Integer)
            return new(UInt8(i))
        end
        #=
        function Card(v::Vector{Any})
            Card[Card(e) for e in v]
        end
        =#
    end

    Card(r::Integer, s::Suit) = Card(r, s.i)

    """
        suit(::Card)
    The suit (color) of a card  bit[6:5]
    """
    suit(c::Card) = Suit((0x60 & c.value) >>> 5)

    """
        rank(::Card)

    The rank of a card
    """
    rank(c::Card) = UInt8((c.value & 0x1f))
    getvalue(c::Card) = UInt8(c.value)
    const T = Suit(0)
    const V = Suit(1)
    const D = Suit(2)
    const X = Suit(3)

    # Allow constructing cards with, e.g., `3♡`
    Base.:*(r::Integer, s::Suit) = Card(r, s)

    function Base.show(io::IO, c::Card)
        r = rank(c)
        rd = r >> 2
        print(io, "jTstcxpm"[rd+1])
        print(io, suit(c))
    end

    function rank_string(r::UInt8)
        rr = r >> 2
        @assert rr > 0

        return ("Tstcxpm"[rr])
    end

    Base.string(card::Card) = rank_string(rank(card)) * string(suit(card))

    """
        high_value(::Card)
        high_value(::Rank)

    The high rank value. For example:
    - `Rank(1)` -> 14 (use [`low_value`](@ref) for the low Ace value.)
    - `Rank(5)` -> 5
    """
    high_value(c::Card) = rank(c) # no meaning in Tusax

    """
        low_value(::Card)
        low_value(::Rank)

    The low rank value. For example:
    - `Rank(1)` -> 1 (use [`high_value`](@ref) for the high Ace value.)
    - `Rank(5)` -> 5
    """
    low_value(c::Card) = rank(c)

    """
        color(::Card)

    A `Symbol` (`:red`, or `:black`) indicating
    the color of the suit or card.
    """
    function color(s::Suit)
        if s == 'D'
            return :red
        elseif s == 'T'
            return :white
        elseif s == 'V'
            return :yellow
        else
            return :green
        end
    end
    color(card::Card) = color(suit(card))

    #####
    ##### Full deck/suit/rank methods
    #####

    """
        ranks

    A Tuple of ranks `1:7`.
    """
    ranks() = 1:7

    """
    For each card, there are duplicate of 4
    """
    duplicate() = 0:3

    """
        suits

    A Tuple of all suits
    """
    suits() = (T, V, D, X)

    """
        full_deck

    A vector of a cards
    containing a full deck
    """
    full_deck() = Card[
        Card((r << 2 | d), s) for s in suits() for d in duplicate() for r in ranks()
    ]

    reduce_deck() = Card[
        Card((r << 2 ), s) for s in suits() for r in ranks()
    ]

    full_deck_chot() =  Card[
        Card((d|4<<2), s) for s in suits() for d in duplicate()]

    function test_deck()
        boid = []
        for i = 1:5
            a = Actor("p1.png")
            a.pos = (100, 100)
            push!(boid, a)
        end
    end

    #### Deck

    """
        Deck

    Deck of cards (backed by a `Vector{Card}`)
    """
    struct Deck{C<:Vector}
        cards::C
    end

    Deck(arr) = Card[Card(a) for a in arr ]

    newDeckUsingArray(arr) = Card[Card(a) for a in arr ]

    is_c(v) = ((v & 0x1C) == 0x10)

    function ssort(deck::Deck)
        ar = []
        for c in deck
            push!(ar, c.value)
        end
        sort!(ar)
        cr = []
        for (i,a) in enumerate(ar)
            if is_c(a)
                push!(cr,a)
            end
        end
        filter!(!is_c,ar)
        for ce in cr
            push!(ar,ce)
        end
        idx = []
        for a in ar
            for (i, card) in enumerate(deck)
                if a == card.value
                    push!(idx, i)
                    break
                end
            end
        end
        deck.cards .= deck.cards[idx]
        deck
    end
    function ssort(deck::Vector{Card})
        ar = []
        for c in deck
            push!(ar, c.value)
        end
        sort!(ar)
        cr = []

        for (i,a) in enumerate(ar)
            if is_c(a)
                push!(cr,a)
            end
        end
        filter!(!is_c,ar)
        for ce in cr
            push!(ar,ce)
        end
        idx = []
        for a in ar
            for (i, card) in enumerate(deck)
                if a == card.value
                    push!(idx, i)
                    break
                end
            end
        end
        deck .= deck[idx]
        deck
    end

    function rcut(deck::Deck)
        r = rand(30:90)
        idx = union(collect(r:112), collect(1:r-1))
        deck.cards .= deck.cards[idx]
        deck
    end

    function rearrange(hand::Deck, arr, dst)
        a = collect(1:length(hand))
        c = 0
        for i in arr
            if (i != dst)
                splice!(a, i - c)
                c += 1
            end
        end
        sort!(arr)
        for (i, n) in enumerate(a)
            if n == dst
                splice!(a, i, arr)
                break
            end
        end

        hand.cards .= hand.cards[a]
        hand
    end
    function getCards(deck::Deck, id)
        if id > length(deck)
            return 0
        end
        if id == 0
            ra = []
            for c in deck
                push!(ra, c.value)
            end
        else
            ra = 0
            for (i, c) in enumerate(deck)
                if i == id
                    ra = c.value
                    break
                end
            end
        end
        return ra
    end




    Base.length(deck::Deck) = length(deck.cards)
    Base.iterate(deck::Deck, state = 1) = Base.iterate(deck.cards, state)
    Base.sort!(deck::Deck) = sort!(deck.cards)

    function Base.show(io::IO, deck::Deck)
        for (i, card) in enumerate(deck)
            Base.show(io, card)
                print(io, " ")
        end
    end

    """
        pop!(deck::Deck, n::Int = 1)
        pop!(deck::Deck, card::Card)
    Remove `n` cards from the `deck`.
    or
    Remove `card` from the `deck`.
    """
    Base.pop!(deck::Deck, n::Integer = 1) =
        collect(ntuple(i -> pop!(deck.cards), n))
    function Base.pop!(deck::Deck, card::Card)
        L0 = length(deck)
        filter!(x -> x ≠ card, deck.cards)
        L0 == length(deck) + 1 || error("Could not pop $(card) from deck.")
        return card
    end

    """
    push!
    push!(deck::Deck, cards::Vector{Card})
    #add `cards` to Deck
    """
    function Base.push!(deck::Deck, ncard)
        push!(deck.cards, ncard)
    end
    function Base.push!(deck::Deck, ncards::Vector{Card})
        for card in ncards
            push!(deck.cards, card)
        end
    end

    """
        moveCards!(toDeck::Deck, fDeck::Deck, cards::Deck)
            move cards from fDeck to toDeck
    """
    function moveCards!(toDeck::Deck, fDeck::Deck, cards::Deck)
        L0 = length(fDeck)
        for card in cards
            filter!(x -> x ≠ card, fDeck.cards)
            push!(toDeck.cards, card)
        end
        L0 == length(deck) + length(cards) ||
            error("Could not pop $(card) from deck.")
    end
    card_equal(a, b) = ((a & 0xFC) == (b & 0xFC))
    function find1(c, str)
        for i = 1:length(str)
            if c == str[i]
                return i
            end
        end
        return 0
    end
    function cardStrToVal(s)
        grank = "Tstcxpm"
        gcolor = "TVDX"
        (UInt8(find1(s[1], grank)) << 2) | (UInt8(find1(s[2], gcolor) - 1) << 5)
    end
    function cardStrToVal(s,deck)
        grank = "Tstcxpm"
        gcolor = "TVDX"
        card = (UInt8(find1(s[1], grank)) << 2) | (UInt8(find1(s[2], gcolor) - 1) << 5)
        for c in deck
            if card_equal(c,card)
                return c
                break
            end
        end
        return 0
    end

    function cardStrToVal(s,deck,ignore)
        grank = "Tstcxpm"
        gcolor = "TVDX"
        card = (UInt8(find1(s[1], grank)) << 2) | (UInt8(find1(s[2], gcolor) - 1) << 5)
        for c in deck
            if card_equal(c,card)
                found = false
                for i in ignore
                    if i == c
                        found = true
                        break
                    end
                end 
                if !found
                    return c
                end                       
            end
        end
        return 0
    end
    function removeCards!(hand::Deck, aline::String)
        grank = "Tstcxpm"
        gcolor = "TVDX"
        tohand = []

        aStrToVal(s) =
        (UInt8(find1(s[1], grank)) << 2) | (UInt8(find1(s[2], gcolor) - 1) << 5)
        str = split(aline, ' ')
        for s in str
            if length(s) ==0
                break
            end
            v = aStrToVal(s)
            for (i,c) in enumerate(hand)
                if card_equal(c.value, v)
                    push!(tohand, c)
                    pop!(hand,c)
                    break
                end
            end

        end
        return tohand
    end

    """
        ordered_deck
    An ordered `Deck` of cards.
    """
    ordered_deck() = Deck(full_deck())
    ordered_deck_chot() = Deck(full_deck_chot())
    ordered_reduce_deck() = Deck(reduce_deck())
    """
        shuffle!

    Shuffle the deck! `shuffle!` uses
    `Random.randperm` to shuffle the deck.
    """
    function shuffle!(deck::Deck)
        if okToPrint(0x1)
        println("\nSHUFFLE -- random")
        end
        deck.cards .= deck.cards[randperm(length(deck.cards))]
        deck
    end

    lowhi(r1, r2) = r1 > r2 ? (r2, r1) : (r1, r2)
    nextWrap(n::Int, d::Int, max::Int) = ((n + d) > max) ? 1 : (n + d)

    """
    """
    function toValueArray(deck::Deck)
        l = length(deck)
        a = Vector{UInt8}(undef,l)
        i = 1
        for card in deck
            a[i] = card.value
            i += 1
        end
        return a
    end
    """
    """
    function toValueArray(deck::Vector{Card})
        l = length(deck)
        a = Vector{UInt8}(undef,l)
        i = 1
        for card in deck
            a[i] = card.value
            i += 1
        end
        return a
    end
    """
    """
    function toValueArray(deck::Vector{Any})
        l = length(deck)
        a = Vector{UInt8}(undef,l)
        i = 1
        for card in deck
            a[i] = card.value
            i += 1
        end
        return a
    end

    function toCardArray(a::Vector{Any})
        d = Card[]
        for c in a
            push!(d,c)
        end
        return d
    end


end # module

"""
 Game Manager
"""
module TuSacManager
    using Random: randperm
    import Random: shuffle!
    using ..TuSacCards
    import ..TuSacCards
    export init,autoHumanShuffle,doShuffle,restoreCards,dealCards, 
    play1Card,setNoRandom,setAITRAIT, setManagerMode, removeCards!, 
    addCards!,printTable,getTable,updateDeadCard,print_mvArray,reset_mvArray,
    coDoiCards,coDoiPlayer

    const gpCheckMatch2 = 2
    const gpCheckMatch1or2 = 1
    const plBot1 = 0
    const plSocket = 1
    const gameDeckMinimum = 9
    currentAction = 0

    mvArray = []
    managerModeAsMaster = false 
    aiType = [4,4,4,4]
    all_assets_marks = zeros(UInt8,128)
    boDoiPlayers = zeros(UInt8,4)
    PlayedCardCnt = zeros(UInt8,32)
    activePlayer = 1
    allowPrint = 0x1
    okToPrint(a) = (allowPrint&a) != 0
    khapMatDau = zeros(4)
    matchSingle = zeros(UInt8,4)
    noRandom = false
    defensiveFlag = [true,true,true,true]
    boDoiFlag =  [true,true,true,true]

    emBaiTrigger = [[-1,0,0],[-1,0,0],[-1,0,0],[-1,0,0]]
    capturedCPoints = [[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]
    gameTrashCnt = gameTrashCntLatest = zeros(Int8,4)
    oneTime = true
    gameStart = false
    pBseat = []
    points = zeros(Int8,4)
    aiTrait = [19,19,19,19]
    aiType = aiTrait .>>2
    boDoiFlag = (aiTrait .& 0x1 ) .!= 0
    mydefensiveFlag = defensiveFlag .& ((aiTrait .& 0x2) .!= 0)

    playerSuitsCnt = zeros(UInt8,4)
    PlayedCardCnt = zeros(UInt8,32)

    drawCnt = 1
    gsHcnt = 1

    deadCards = [[],[],[],[]]
    prevDeck = false
    prevCard = 0x00
    prevN1 = 0
    probableCards = [[],[],[],[]]
    noSingle = [false,false,false,false]
    all_assets_marks = zeros(UInt8,128)
    matchSingle = zeros(UInt8,4)
    Tuong = zeros(UInt8,4)
    vPlayerHand = []
    vPlayerAsset = []
    vPlayerDiscard = []
    playerHand = [[],[],[],[]]
    playerAsset = [[],[],[],[]]
    playerDiscard = [[],[],[],[]]
    mGameDeck = []
    vGameDeck = []
    coinsArr = []
    khui = [1,1,1,1]
    kpoints = zeros(Int8,4)
    nDead=[[],[],[],[]]
    boDoiFlag = (aiTrait .& 0x1 ) .!= 0
    notDoneInit = true

    highValue = zeros(UInt8,4)

    coDoiPlayer = 0
    coDoiCards = []

    rQ = Vector{Any}(undef,4)
    rReady = Vector{Bool}(undef,4)

    function setPlayerList(player,t) 
        global PlayerList[player] = t
    end
    
    function setManagerMode(m)
        global managerModeAsMaster = m
    end

    function allwPrint(a)
        allowPrint = a
    end
    function setAITRAIT(a)
        global aiTrait = a
        global aiType = aiTrait .>>2
        global boDoiFlag = (aiTrait .& 0x1 ) .!= 0
        global mydefensiveFlag = defensiveFlag .& ((aiTrait .& 0x2) .!= 0)

    end
    function setNoRandom(r)
        noRandom = r
    end
    function baiThui()
        return length(vGameDeck) < gameDeckMinimum
    end
    chksum(s,v) = s &0x8000_0000_0000_0000 == 0 ? xor(s,v) << 1 : xor((xor(s,v) << 1),0x1)
    function checksum()
        local checksum::UInt64
        local a::UInt64
        checksum = 0
        for (i,ah) in enumerate(vPlayerHand)
            for a in ah
            checksum = chksum(checksum,a)
            end
        end
        for (i,ah) in enumerate(vPlayerDiscard)
            for a in ah
                checksum = chksum(checksum,a)
            end
        end
        for (i,ah) in enumerate(vPlayerAsset)
            for a in ah
                checksum = chksum(checksum,a)
            end
        end
        println("checksum = 0x",string(checksum,base=16))
        return checksum
    end

    function init(coldStart=true) 
        global mGameDeck
        global mvArray
        global boDoiPlayers = zeros(UInt8,4)
        global PlayedCardCnt = zeros(UInt8,32)
        global deadCards = [[],[],[],[]]
        global probableCards = [[],[],[],[]]
        global mvArray = []
        global kpoints,points
        global coinsArr = [[0,0],[0,0],[0,0],[0,0]]
        global kpoints = zeros(Int8,4)
        global points = zeros(Int8,4)
        global khapMatDau = zeros(4)
        global matchSingle = zeros(UInt8,4)
        boDoiFlag = (aiTrait .& 0x1 ) .!= 0
        global playerHand = [[],[],[],[]]
        global playerAsset = [[],[],[],[]]
        global playerDiscard = [[],[],[],[]]
        global emBaiTrigger = [[-1,0,0],[-1,0,0],[-1,0,0],[-1,0,0]]
        global capturedCPoints = [[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]
        global gameTrashCnt = gameTrashCntLatest = zeros(Int8,4)
        global oneTime = true
        global gameStart = false
        global gotClick = false
        global GUI_array=[]
        global GUI_ready=true
        global HISTORY = []
        global points = zeros(Int8,4)
        global khui = [1,1,1,1]
        global kpoints = zeros(Int8,4)
        global playerSuitsCnt = zeros(UInt8,4)
        global PlayedCardCnt = zeros(UInt8,32)
    
        global drawCnt = 1
        global gsHcnt = 1
    
        global prevDeck = false
        global prevCard = 0x00
        global prevN1 = 0
        global noSingle = [false,false,false,false]
        global all_assets_marks = zeros(UInt8,128)
        global matchSingle = zeros(UInt8,4)
        global Tuong = zeros(UInt8,4)
        global notDoneInit = true
        nDead=[[],[],[],[]]
        highValue = zeros(UInt8,4)
        needAcard = false
        global illPairs = []
        global illSuits = []
        global pair3s = []
        global mGameDeck = TuSacCards.ordered_deck()
    end


    function _ts(a)
            TuSacCards.Card(a[1])
    end

    function ts(a)
        st = ""
        if length(a) == 1
            st = _ts(a)
        elseif length(a) > 1
            for b in a
                    st = string(st,_ts(b)," ")
            end
        end 
        return st
    end

    """
    tss(g)
    to print out arr of arr of cards, like this [[],[],[]]
    """
    function tss(g,s1=" ",s2=", ")
        st = ""
        for (i,a) in enumerate(g)
            for (j,b) in enumerate(a)
                if j == length(a)
                    st = string(st,_ts(b))
                else
                    st = string(st,_ts(b),s1)
                end
            end
            if i != length(g)
                st = string(st,s2)
            end
        end
        return st
    end

    function ts_s(rt, sp = "", n = true)
        for rq in rt
            print(" ",ts(rq))
            if length(rq) > 1
                for r in rq[2:end]
                    print("+",ts(r))
                end
            end
        end
        print(sp)
        if n
            println()
        end
        return
    end

    function ts_ss(rts, n = true)
        for rt in rts
            for r in rt
                print(ts(r), " ")
            end
            print(",")
        end
        if n
            println()
        end
        return
    end


    const T = 0
    const V = 1 << 5
    const X = 2 << 5
    const D = 3 << 5

    is_T(v) = (v & 0x1C) == 0x4
    to_T(v) = v&0xf3 | 0x4

    is_s(v) = (v & 0x1C) == 0x8
    to_s(v) = v&0xf3 | 0x8

    is_t(v) = (v & 0x1C) == 0xc
    to_t(v) = v&0xf3 | 0xc

    is_Tst(v) = (0xd > (v & 0x1C) > 3)


    """
        c(v) is a chot
    """
    fourCs = [0x10,0x30,0x50,0x70]
    is_c(v) = ((v & 0x1C) == 0x10)

    is_colorT(v) = ((v & 0x60) == 0x00)
    is_colorV(v) = ((v & 0x60) == 0x20)
    is_colorX(v) = ((v & 0x60) == 0x40)
    is_colorD(v) = ((v & 0x60) == 0x60)

    to_colorT(v) = ((v & 0x1c) | T)
    to_colorV(v) = ((v & 0x1c) | V)
    to_colorX(v) = ((v & 0x1c) | X)
    to_colorD(v) = ((v & 0x1c) | D)
    """
        x(v) is a xe
    """

    is_x(v) = ((v & 0x1C) == 0x14)
    to_x(v) = v&0xf3 | 0x4

    """
        p(v) is a phao
    """
    is_p(v) = (v & 0x1C) == 0x18
    to_p(v) = v&0xf3 | 0x8

    """
        m(v) is a ma
    """
    is_m(v) = (v & 0x1C) == 0x1c
    to_m(v) = v&0xf3 | 0xc


    is_xpm(v) = 0x1d > (v & 0x1C) > 0x13

    function suitCards(v)
        if is_Tst(v)
            return [is_s(v) ? to_t(v) : to_s(v)]
        elseif is_xpm(v)
            if is_x(v)
                return [to_p(v),to_m(v)]
            elseif is_p(v)
                return [to_x(v),to_m(v)]
            else
                return [to_x(v),to_p(v)]
            end
        else
            if is_colorT(v)
                return [to_colorV(v),to_colorD(v),to_colorX(v)]
            elseif is_colorV(v)
                return [to_colorT(v),to_colorD(v),to_colorX(v)]
            elseif is_colorD(v)
                return [to_colorT(v),to_colorV(v),to_colorX(v)]
            else
                return [to_colorT(v),to_colorV(v),to_colorD(v)]
            end
        end
    end
    

    """
        inSuit(a,b): check if a,b is in the same sequence cards (Tst) or (xpm)
    """
    inSuit(a, b) = (a & 0xc != 0) && (b & 0xc != 0) && (a & 0xF0 == b & 0xF0)

    """
        inStrictSuit(a,b): check if a,b is in the same sequence cards (Tst)
        or (xpm) or chot, but remove equal cards
    """
    inAllStrictSuit(a,b) = !card_equal(a,b) && ((inSuit(a,b)) || (is_c(a) && is_c(b)))
  
    """
    inTSuit(a)
        a is either si or tuong
    """
    inTSuit(a) = (a&0x1c == 0x08) || (a&0x1c == 0x0C)
    function suit(r,matchc)
        if length(r) != 2
            return false
        end
        rt = card_equal(missPiece(r[1],r[2]), matchc)
   
        return rt
    end

    """
    card_equal(a,b): a,b are the same card (same color, and same kind)
    """
    card_equal(a, b) = a&0xFC == b&0xFC

    isPair(r) = length(r) == 2 ? card_equal(r[1],r[2]) : false
    isTripple(r) = length(r) == 3 ? card_equal(r[1],r[2]) : false

    function has_T(c)
        global Tuong
        return Tuong[c&0x3+1] != 0
    end

    """
        missPiece(s1,s2): creat the missing card for group of 3,
    """
    missPiece(s1, s2) = (s2 > s1) ? (((((s2 & 0xc) - (s1 & 0xc)) == 4 ) ?
                                    ( ((s1 & 0xc) == 4) ? 0xc : 4 ) : 8) |
                                    (s1 & 0xF3)) :
                                    (((((s1 & 0xc) - (s2 & 0xc)) == 4 ) ?
                                    ( ((s2 & 0xc) == 4) ? 0xc : 4 ) : 8) |
                                        (s2 & 0xF3))

                                        
    function printTable()
    # checksum()
        
        println("====Manager======Hands")
        for (i,ah) in enumerate(vPlayerHand)
            print(i,": ");ts_s(ah)
        end
        println("==========Discards")
        for (i,ah) in enumerate(vPlayerDiscard)
            print(i,": ");ts_s(ah)
        end
        println("===========Assets")
        for (i,ah) in enumerate(vPlayerAsset)
            print(i,": ");ts_s(ah)
        end
        println("gameDeck")
        println(mGameDeck)
        println()
    end

    function illegalScan(i)
        global kpoints,khui,coinsArr,coinsCnt,points,illPairs,illSuits,pair3s
            coinsCnt = 0
            allPairs, single, chot1, miss1, missT, 
            miss1Card, chotP, chot1Special, suitCnt, 
            miss1_1,miss1_2,cTrsh,suits =
            scanCards(vPlayerHand[i],false)

            illegal = []
            for app in allPairs
                for p in app
                    found = false
                    if length(p) == 2
                        for m in miss1Card
                            if card_equal(p[1],m)
                                found = true
                                break
                            end
                        end
                    end
                    if found == false
                        push!(illegal,p[1])
                    end
                end
            end
            pair3 = []
            for p in allPairs[2]
                push!(pair3,p[1])
            end
      
        return illegal,suits,pair3
    end


    function initialScan(all_hands)
        global kpoints,khui,coinsArr,coinsCnt,points,illPairs,illSuits,pair3s
        illPairs = []
        illSuits = []
        pair3s = []

        for i in 1:4
            coinsCnt = 0
            allPairs, single, chot1, miss1, missT, 
            miss1Card, chotP, chot1Special, suitCnt, 
            miss1_1,miss1_2,cTrsh,suits =
            scanCards(all_hands[i],false)

                for pss in allPairs
                    for ps in pss
                        if length(ps) == 4
                            removeCards!(false,i,ps)
                            addCards!(false,i,ps)
                            all_assets_marks[ps[1]] = 1
                            kpoints[i] += 8
                            khui[i] = 2
                            coinsArr[i][1] += 1
                            coinsCnt += 1
                        elseif length(ps) == 3
                            kpoints[i] += 3
                            if is_T(ps[1])
                                points[i] -= 3
                            end
                            coinsArr[i][2] += 1
                            coinsCnt += 1
                        end
                    end
                end
        end
    end

    function TableToString()
        # checksum()
        astr = ""
            for (i,ah) in enumerate(vPlayerHand)
                astr = astr * ts(ah) * "\n"
            end
            for (i,ah) in enumerate(vPlayerDiscard)
                astr = astr * ts(ah) * "\n"
            end
            for (i,ah) in enumerate(vPlayerAsset)
                astr = astr * ts(ah) * "\n"
            end
            astr = astr * ts(vGameDeck)
            return astr
    end

    function printTable(WF,player)
        # checksum()
            for i in player:4
                ah = vPlayerHand[i]
                println(WF,ts(ah))
            end
            if player > 1
                for i in 1:player-1
                    ah = vPlayerHand[i]
                    println(WF,ts(ah))
                end
            end

            for i in player:4
                ah = vPlayerDiscard[i]
                println(WF,ts(ah))
            end
            if player > 1
                for i in 1:player-1
                    ah = vPlayerDiscard[i]
                    println(WF,ts(ah))
                end
            end

            for i in player:4
                ah = vPlayerAsset[i]
                println(WF,ts(ah))
            end
            if player > 1
                for i in 1:player-1
                    ah = vPlayerAsset[i]
                    println(WF,ts(ah))
                end
            end

            println(WF,ts(vGameDeck))
         
    end

    function printCoins(WF,player)
        for i in player:4
            for c in coinsArr[i]
                print(WF,",",c)
            end
        end
        if player > 1
            for i in 1:player-1
                for c in coinsArr[i]
                    print(WF,",",c)
                end
            end
        end
        println(WF)
        illPair,illSuit,pair3 = illegalScan(player)
        println(WF,ts(illPair))
        println(WF,ts(illSuit))
        println(WF,ts(pair3))
    end


    function printCoins(player)
        for i in player:4
            for c in coinsArr[i]
                print(", ",c)
            end
        end
        if player > 1
            for i in 1:player-1
                for c in coinsArr[i]
                    print(", ",c)
                end
            end
        end
        println()
    end
   
    function updateDeadCard(player,card)
        push!(deadCards[player],card)
    end

    """
    c_scan(p,s)
        scan/c_analyzer all the chots. Return singles.
    """
    function c_scan(p,s;win=false)
   
        if length(s) > 2
            return []
        elseif length(s) == 2
            if length(p[2])>0 && win
                return[]
            else
                if length(p[1])>1
                    return []
                elseif length(p[1])==1
                    return [p[1][1][1]]
                else
                    return s
                end
            end
        else
            if length(p[2])>1 && win
                return[]
            elseif length(p[2])==1 && win
                return s
            else
                if length(p[1]) > 2
                    return []
                else
                    return s
                end
            end
        end
    end

    """
    c_analyzer(p,s,ci)
        return array, if length of 0, then perfect match
    not check for pairs match --- this function got call first before
        the regular pairs check
    """
    function c_analyzer(ap,as,ci)
        p = deepcopy(ap)
        s = deepcopy(as)
        #println("c_analyzer= ",(p,s,ci))
        match_s = false
        new_s = []
        new_p = []
        for c in s
            if card_equal(c,ci)
                match_s = true
            else
                push!(new_s,c)
            end
        end
        if match_s
            new_p = deepcopy(p)
            added_p =[ci,ci]
            push!(new_p[1],added_p)
            ct = c_scan(new_p,new_s, win = true)
        else
            match_p = false
            newPair = []
            new_p = [[],[],[]]
            for aps in p
                for ap in aps
                    if card_equal(ap[1],ci)
                        newPair = ap
                        push!(newPair,ci)
                        match_p = true
                    else
                        l = length(ap) - 1
                        push!(new_p[l],ap)
                    end
                end
            end
            if match_p
                l = length(newPair) - 1
                push!(new_p[l],newPair)
            else
                push!(new_s,ci)
            end
            ct = c_scan(new_p,new_s, win = true)
        end
        return ct
    end

    """
        c_match(p,s,n)
            return match for a chot. Taking in account of all chots, not just the
                singles.
    """
    function c_match(p,s,n,cmd;win=false)
        global coDoiCards
        if okToPrint(0x8)
            println("c-match ",(p,s,n,length(s)))
        end
        rt = []
        nrt = []
        if length(s) > 1
            for es in s
                if card_equal(es,n)
                        rt = [es]
                else
                    push!(nrt,es)
                end
            end
            if length(rt) != 0
                if length(p[1]) == 2
                    rt = [nrt[1],p[1][1][1],p[1][2][1]]
                elseif length(s) == 3
                    if length(p[1]) > 0
                        if length(nrt) > 1
                            pop!(nrt)
                        end
                        push!(nrt,p[1][1][1])
                        rt = nrt
                    else
                        rt = []
                    end
                end
            else
                rt = s
            end
        elseif length(s)==1
            if card_equal(s[1],n)
                rt = s
            else
            # now we have 2 uniq chots
                if length(p[2])>0 && win# at least 1 3-pair
                    rt =  [p[2][1][1],s[1]] # use 1 of the 3-pair
                else
                    if length(p[1])>1 # at least 2 2-pair and 1-single
                        if !(card_equal(n,p[1][1][1]) ||
                            card_equal(n,p[1][2][1]) )
                            rt =  [p[1][1][1],p[1][2][1]]
                        else
                            rt = []
                        end
                    elseif length(p[1])==1 && !card_equal(n,p[1][1][1])
                        rt =  [p[1][1][1],s[1]]
                    else
                        rt =  []
                    end
                end
            end
        end
        if length(rt) != 0
            for ap in p[2]
                if card_equal(ap[1],n)
                    rt = ap
                    break
                end
            end
            for ap in p[1]
                if card_equal(ap[1],n)
                    if length(rt)==3
                        rt = ap
                    elseif length(rt) == 1 && cmd == gpCheckMatch2
                        rt = ap
                    end
                    break
                end
            end
        else
            for aps in p
                for ap in aps
                    if card_equal(ap[1],n)
                        if length(ap) == 2
                            coDoiCards = ap
                        end
                        rt = ap
                        break
                    end
                end
            end
        end

        if okToPrint(0x8)
            println("c-match-result = ", rt); ts_s(rt)
        end

        return rt
    end

    """
    scanCards() scan for single and missing seq
                put cards in piles of (pairs, single1, miss1, missT, miss1bar, chot1)
                NOTE: some card can be in both group (pairs, single) for easy of matching purpose
                since it got rescan on every move, the duplication does not affecting correctness
    """
    function scanCards(inHand, silence = false, psc = false)
        # scan for pairs and remove them
        global allPairs, single, chot1, miss1, missT, miss1Card, chotP, chot1Special, suitCnt ,miss1_1,miss1_2,cTrsh
        ahand = deepcopy(inHand)
        pairs = []
        allPairs = [[], [], []]
        pairOf = 0
        rhand = []
        chot1 = []
        chot1Special = []
        chotP = [[],[],[]]
        all_chots =[]
        miss1 = []
        miss1_1 = []
        miss1_2 = []
        missT = []
        miss1Card = []
        single = []
        cTrsh = []
        suits = []

        global Tuong = zeros(UInt8,4)

        
        suitCnt = 0
        if length(ahand) == 0
            return allPairs, single, chot1, miss1, missT, miss1Card, chotP, chot1Special, suitCnt ,miss1_1,miss1_2,cTrsh
        end
        prevAcard = ahand[1]
        if is_c(prevAcard)
            push!(all_chots,prevAcard)
        elseif is_T(prevAcard)
            suitCnt += 1
        end
        for i = 2:length(ahand)
            acard = ahand[i]
            if is_T(acard)
                suitCnt += 1
            end
            if card_equal(acard, prevAcard)
                push!(pairs, prevAcard)
                pairOf += 1
                @assert pairOf < 4
            else
                if pairOf > 0
                    if is_T(prevAcard)

                        if pairOf == 1 # Tuong pair of 2 is not really a pair
                            push!(rhand, prevAcard) # put 1 back for rescan
                        else
                            push!(pairs, prevAcard)
                            push!(allPairs[pairOf], pairs)
                        end
                    else
                        push!(pairs, prevAcard)
                        push!(allPairs[pairOf], pairs)
                        if is_c(pairs[1])
                            push!(chotP[pairOf],pairs)
                        end
                    end
                    pairs = []
                    pairOf = 0
                else
                    push!(rhand, prevAcard)
                end
            end
            prevAcard = acard
        end
        if pairOf > 0

            push!(pairs, prevAcard)
            push!(allPairs[pairOf], pairs)
            if is_c(pairs[1])
                push!(chotP[pairOf],pairs)
            end
        else
            push!(rhand, prevAcard)
        end
        #rhand is the non-pair cards remaining after scan for pairs

        ahand = rhand
        if length(ahand) > 0
            acard = ahand[1]
            prevAcard = acard
            prev2card = acard
            prev3card = acard
            seqCnt = 0

            for i = 2:length(ahand)
                acard = ahand[i]
                if inSuit(prevAcard, acard)
                    prev3card = prev2card
                    prev2card = prevAcard
                    seqCnt += 1
                else
                    if seqCnt == 2
                        if !is_Tst(prevAcard)
                            suitCnt += 1
                        end
                        push!(suits,prevAcard)

                    elseif seqCnt == 1
                        ar = []
                        mc = missPiece(prev2card, prevAcard)
                        push!(miss1Card, mc)
                        push!(ar, prev2card, prevAcard)
                        if is_T(mc)
                            push!(missT, ar)
                        else
                            push!(miss1, ar)
                            if is_T(prev2card)
                                Tuong[prev2card&3+1] = 1
                                push!(miss1_1,prevAcard)
                            else
                                push!(miss1_2,ar)
                            end
                        end
                    elseif seqCnt == 0
                        # a single
                        if !is_T(prevAcard) # Tuong
                            if is_c(prevAcard)
                                push!(chot1Special, prevAcard)
                            else
                                push!(single, prevAcard)
                            end
                        end
                    end
                    seqCnt = 0
                end
                prevAcard = acard
            end
            if seqCnt == 2
                if !is_Tst(prevAcard)
                    suitCnt += 1
                end
                push!(suits,prevAcard)
            elseif seqCnt == 1
                ar = []
                mc = missPiece(prev2card, prevAcard)
                push!(miss1Card, mc)
                push!(ar, prev2card, prevAcard)
                if is_T(mc)
                    push!(missT, ar)
                else

                    push!(miss1, ar)
                    if is_T(prev2card)
                        Tuong[prev2card&3+1] = 1
                        push!(miss1_1,prevAcard)
                    else
                        push!(miss1_2,ar)
                    end
                end
            elseif seqCnt == 0
                # a single
                if !is_T(prevAcard) # Tuong
                    if is_c(prevAcard)
                        push!(chot1Special, prevAcard)
                    else
                        push!(single, prevAcard)
                    end
                end
            end
        end
        if length(allPairs[1]) >= 3
            for (i,p) in enumerate(allPairs[1])
                if is_x(p[1]) && (length(allPairs[1]) - i ) > 2
                    if inSuit(p[1],allPairs[1][i+1][1]) && inSuit(p[1],allPairs[1][i+2][1])
                        suitCnt += 2
                    end
                end
            end
        end

        cTrsh = c_scan(chotP,chot1Special)
        chot1 = cTrsh
        return allPairs, single, chot1, miss1, missT, miss1Card, chotP, chot1Special, suitCnt, miss1_1,miss1_2,cTrsh,suits
    end


    function doShuffle(mode)
            TuSacCards.shuffle!(mGameDeck)
    end
   
    nextPlayer(p) = p == 4 ? 1 : p + 1
    prevPlayer(p) = p == 1 ? 4 : p - 1
    
    function getDeckCard()
        return vGameDeck[end]
    end
    function print_mvArray(gameOver)
        print("Move Array: ")
        print(gameOver ? "gameOver," : "cont,")
        for ar in TuSacManager.mvArray
            print(ar[1]," ",ar[2]," ",ts(ar[3]),",")
        end
        println()
    end
    """
     mapping a player number (realp) to a new number relative to the player 
        P   no   R
        1   n    n
        2   2    1
        2   3    2
        2   4    3
        2   1    4

        3   3    1
        3   4    2
        3   1    3
        3   2    4

        4   4    1
        4   1    2
        4   2    3
        4   3    4
    """
    function mappingPlayer(player,relativeP)
        if relativeP == 0
            return 0
        end
        #discard vs asset 
        m = relativeP > 4 ? relativeP-4 : relativeP
       
        r = m - (player-1)
        r = r > 0 ? r : r+4
        r = relativeP > 4 ? r+4 : r

        return r
    end

    function string_TArray(gameOver,p,np)
        global mvArray
        tArray = []
        for i in 1:lastindex(mvArray)
            if mvArray[i][1] == 1
                for j in i + 1 : lastindex(mvArray)
                    if mvArray[j][1] == 0
                        if mvArray[i][3] == mvArray[j][3]
                            entry = mvArray[i][2],mvArray[j][2],mvArray[j][3]
                            push!(tArray,entry)
                            break
                        end
                    end
                end
            end
        end
        np = mappingPlayer(p,np)
        astr = gameOver ? string("gameOver $np,") : string("cont $np,")
      
        for ar in tArray
            astr = astr*string(mappingPlayer(p,ar[1])," ",mappingPlayer(p,ar[2])," ",ts(ar[3]),",")
        end
        return astr
    end

    function reset_mvArray()
        global mvArray = []
        global coDoiCards = []
        global coDoiPlayer = 0
    end

    function removeCards!(isDeck, n, cards)
        global mvArray
        println("remove-",(isDeck, n, cards))

        if isDeck
            nc = pop!(mGameDeck, 1)
            nca = pop!(vGameDeck)
            push!(mvArray,(1,0,nca))

            return nca
        else
            for c in cards
                push!(mvArray,(1,n,c))
                found = false
                for l = 1:length(vPlayerHand[n])
                    if c == vPlayerHand[n][l]
                        found = true
                        splice!(vPlayerHand[n], l)
                        break
                    end
                end
                pop!(playerHand[n],ts(c))
            end
            return []
        end
    end
    
    function addCards!(discardCard, n, cards)
        global mvArray
        m = n
        if discardCard 
            m += 4
        end
        println("add-",(m, cards))
        for c in cards
            updateCntPlayedCard(c)
            push!(mvArray,(0,m,c))
            if discardCard == false
                push!(vPlayerAsset[n], c)
            else
                push!(vPlayerDiscard[n], c)
            end
            if discardCard == false
                push!(playerAsset[n],ts(c))
            else
                push!(playerDiscard[n],ts(c))
            end
        end
    end

    function getAllPlayerCards()
        global playerHand,playerAsset,playerDiscard,mGameDeck,
        vPlayerHand,vPlayerAsset,vPlayerDiscard,vGameDeck

        vPlayerHand = []
        vPlayerAsset = []
        vPlayerDiscard = []

        for i in 1:4
            push!(vPlayerHand, TuSacCards.toValueArray(playerHand[i]))
            push!(vPlayerAsset,TuSacCards.toValueArray(playerAsset[i]))
            push!(vPlayerDiscard,TuSacCards.toValueArray(playerDiscard[i]))
        end
        vGameDeck = TuSacCards.toValueArray(mGameDeck)
    end

    function restoreCards(allCardsArray,playerIndex)
        global playerHand,playerAsset,playerDiscard,mGameDeck,
        vPlayerHand,vPlayerAsset,vPlayerDiscard,vGameDeck,kpoints,points,coinsArr

            playerA_hand, playerA_discards, playerA_assets,
            playerB_hand, playerB_discards, playerB_assets,
            playerC_hand, playerC_discards, playerC_assets,
            playerD_hand, playerD_discards, playerD_assets,
            mGameDeck,kpoints,points,coinsArr = deepcopy(allCardsArray)
            global activePlayer = playerIndex
            playerHand = []
            playerDiscard = []
            playerAsset = []
            push!(playerHand,playerA_hand)
            push!(playerHand,playerB_hand)
            push!(playerHand,playerC_hand)
            push!(playerHand,playerD_hand)

            push!(playerDiscard,playerA_discards)
            push!(playerDiscard,playerB_discards)
            push!(playerDiscard,playerC_discards)
            push!(playerDiscard,playerD_discards)

            push!(playerAsset,playerA_assets)
            push!(playerAsset,playerB_assets)
            push!(playerAsset,playerC_assets)
            push!(playerAsset,playerD_assets)

        getAllPlayerCards()
        global notDoneInit = false

    end

    function dealCards(firstPlayer)
        global mGameDeck
        global playerHand, playerAsset, playerDiscard
        P0_hand = TuSacCards.Deck(pop!(mGameDeck, 6))
        P1_hand = TuSacCards.Deck(pop!(mGameDeck, 5))
        P2_hand = TuSacCards.Deck(pop!(mGameDeck, 5))
        P3_hand = TuSacCards.Deck(pop!(mGameDeck, 5))
        for i = 2:4
            push!(P0_hand, pop!(mGameDeck, 5))
            push!(P1_hand, pop!(mGameDeck, 5))
            push!(P2_hand, pop!(mGameDeck, 5))
            push!(P3_hand, pop!(mGameDeck, 5))
        end
        playerA_hand = P0_hand
        playerB_hand = P1_hand
        playerC_hand = P2_hand
        playerD_hand = P3_hand
    
        global playerA_discards = TuSacCards.Deck(pop!(mGameDeck, 1))
        global playerB_discards = TuSacCards.Deck(pop!(mGameDeck, 1))
        global playerC_discards = TuSacCards.Deck(pop!(mGameDeck, 1))
        global playerD_discards = TuSacCards.Deck(pop!(mGameDeck, 1))
    
        global playerA_assets = TuSacCards.Deck(pop!(mGameDeck, 1))
        global playerB_assets = TuSacCards.Deck(pop!(mGameDeck, 1))
        global playerC_assets = TuSacCards.Deck(pop!(mGameDeck, 1))
        global playerD_assets = TuSacCards.Deck(pop!(mGameDeck, 1))
    
        push!(mGameDeck,pop!(playerD_assets,1))
        push!(mGameDeck,pop!(playerC_assets,1))
        push!(mGameDeck,pop!(playerB_assets,1))
        push!(mGameDeck,pop!(playerA_assets,1))
    
        push!(mGameDeck,pop!(playerD_discards,1))
        push!(mGameDeck,pop!(playerC_discards,1))
        push!(mGameDeck,pop!(playerB_discards,1))
        push!(mGameDeck,pop!(playerA_discards,1))
        playerHand  = []
        playerAsset = [[],[],[],[]]
        playerDiscard  = [[],[],[],[]]
        TuSacCards.ssort(playerA_hand)
        TuSacCards.ssort(playerB_hand)
        TuSacCards.ssort(playerC_hand)
        TuSacCards.ssort(playerD_hand)
        firstPlayer = 5 - firstPlayer
        for i in 1:4
            pl = ((firstPlayer + i) % 4 ) 
            if pl == 1
                push!(playerHand,playerA_hand)
            elseif pl == 2
                push!(playerHand,playerB_hand)
            elseif pl == 3
                push!(playerHand,playerC_hand)
            else
                push!(playerHand,playerD_hand)
            end
        end
        getAllPlayerCards()

    end
    gameReady = false
    function resetReady() 
        global gameReady = false
    end
    function setReady()
        global gameReady = true
    end

    function setupHand()
        for i in 1:4
            allPairs = scanCards(vPlayerHand[i],false)
            for pss in allPairs 
                for ps in pss
                    if length(ps) == 4
                        removeCards!(true,i,ps)
                        addCards!(false,i,ps)
                        all_assets_marks[ps[1]] = 1
                        kpoints[i] += 8
                        khui[i] = 2
                    elseif length(ps) == 3
                        kpoints[i] += 3
                        if is_T(ps[1])
                            points[i] -= 3
                        end
                    end
                end
            end
        end
    end

    function getTable()
        global playerHand,playerAsset,playerDiscard,vPlayerHand,vPlayerAsset,vPlayerDiscard

        a = playerHand,playerAsset,playerDiscard,mGameDeck,vPlayerHand,vPlayerAsset,vPlayerDiscard,vGameDeck
        return deepcopy(a)
    end

    function updateCntPlayedCard(card)
        global PlayedCardCnt
        c = card >> 2
        PlayedCardCnt[c] += 1
    end
    
    function getCntPlayedCard(card)
        global PlayedCardCnt
        c = card >> 2
        return PlayedCardCnt[c]
    end
    
    function cardHasPair(card)
        cArr = suitCards(card)
        for c in cArr
            for p in allPairs[1]
                if card_equal(c,p[1])
                    return true
                end
            end
        end
        return false
    end
    
    function cardHasTripple(card)
        cArr = suitCards(card)
        for c in cArr
            for p in allPairs[2]
                if card_equal(c,p[1])
                    return true
                end
            end
        end
        return false
    end


    """
    chk1(playCard)
    """
    function chk1(playCard)
        if is_c(playCard)
                r  = c_match(chotPs,chot1Specials,playCard,currentAction)
        if length(r) > 0
            return r
        end
        end
        function chk1Print()
            for s in singles
                print(" (s)",(ts(s)))
                @assert !is_c(s)
                if card_equal(s, playCard)
                    print("@")
                    return
                end
            end

            for mt in missTs
                m = missPiece(mt[1], mt[2])
                print(" (mT)", ts(m))
                if card_equal(m, playCard)
                    print("@")
                    return
                elseif card_equal(mt[1], playCard) && !is_T(playCard)
                    print("@")
                    return
                elseif card_equal(mt[2], playCard) && !is_T(playCard)
                    print("@")
                    return
                end
            end

            for m1 in miss1s
                m = missPiece(m1[1], m1[2])
                print(" (m1)", (length(miss1s),ts(playCard),ts(m)))
                if card_equal(m, playCard)
                    print("@")
                    return
                elseif card_equal(m1[1], playCard) && !is_T(playCard)
                    print("@")
                    return
                elseif card_equal(m1[2], playCard) && !is_T(playCard)
                    print("@")
                    return
                end
            end
        end
        if okToPrint(0x8)
            chk1Print()
        end

        for s in singles
            if card_equal(s, playCard)
                return s
            end
        end

        for mt in missTs
            m = missPiece(mt[1], mt[2])
            if card_equal(m, playCard)
                return mt
            elseif card_equal(mt[1], playCard) && !is_T(playCard)
                return mt[1]
            elseif card_equal(mt[2], playCard) && !is_T(playCard)
                return mt[2]
            end
        end

        for m1 in miss1s
            m = missPiece(m1[1], m1[2])
            if card_equal(m, playCard)
                return m1
            elseif card_equal(m1[1], playCard) && !is_T(playCard)
                return m1[1]
            elseif card_equal(m1[2], playCard) && !is_T(playCard)
                return m1[2]
            end
        end
        return []
    end
    foundSaki = false
    """
    chk2(playCard) check for pairs -- also check for P XX ? M

    """
    function chk2(playCard;win=false)
        global coDoiCards
        global foundSaki = false
        function chk2Print()
            found = false
            if !is_c(playCard)
                for m1 in miss1s # CAAE XX PM ? X
                    if card_equal(playCard, missPiece(m1[1], m1[2])) &&
                        !is_T(m1[1]) &&
                        !is_T(m1[2])
                        if okToPrint(0x8)
                            println("Found Saki -- allow bo doi")
                        end
                        found = true
                        break
                    end
                end
            end
            for p = 1:2
                print(" (pair)",(p+1))
                for ap in allPairs[p]
                    print(ts(ap[1]))
                    if is_T(playCard)
                        if p == 2 && card_equal(ap[1], playCard)
                            print("@")
                            return
                        end
                    elseif !is_c(playCard) && card_equal(ap[1], playCard)
                        if (p == 1) && found
                            print(" SAKI ")
                            print("@")
                            return
                        else
                            print("@")
                            if p == 1
                                if length(coDoiCards) == 0
                                    if okToPrint(0x8)
                                        println("FOUND CODOI", ( length(coDoiCards), ts(ap) ))
                                    end
                                end
                            end
                            return
                        end
                    end
                end
            end
            println()
        end
        if okToPrint(0x8)
            chk2Print()
        end
        inSuitArr = []
        found = false
        if !is_c(playCard)
            for m1 in miss1s # CAAE XX PM ? X
                if card_equal(playCard, missPiece(m1[1], m1[2])) &&
                !is_T(m1[1]) &&
                !is_T(m1[2])
                    found = true
                    break
                end
            end
        end
        for p = 1:2
            for ap in allPairs[p]
                if is_T(playCard)
                    if p == 2 && card_equal(ap[1], playCard)
                        return ap # TTTT
                    end
                elseif !is_c(playCard) && card_equal(ap[1], playCard)
                    if (p == 1) && found
                        foundSaki = true
                        return []  # SAKI -- return nothing
                    else
                        if p == 1
                            if length(coDoiCards) == 0
                                push!(coDoiCards,ap[1],ap[2])
                            end
                        end
                        return ap
                    end
                elseif inSuit(ap[1], playCard) && p == 1 # CASE X PP ? M
                    if length(inSuitArr) == 0
                        push!(inSuitArr, ap[1]) # put in array to check
                    end
                end
            end
        end
        if length(inSuitArr) > 0
            for s in singles
                if inSuit(s, playCard)
                    push!(inSuitArr, s)
                    return inSuitArr
                end
            end
        end
        return []
    end

    function findDeadCard(player,chkcard,mode=0)
        if mode == dc_target
            ar = union(deadCards[player],vPlayerAsset[player],
            vPlayerDiscard[player],vPlayerDiscard[prevPlayer(player)])
        else
            ar = union(deadCards[player],
            vPlayerDiscard[player],vPlayerDiscard[prevPlayer(player)])
        end
        for c in ar
            if card_equal(c,chkcard)
                return true
            end
        end
        return false
    end

    const dc_next =1
    const dc_target = 0
    function findWorstCard(Singles,player; findDead = false)
        singles = copy(Singles)
        max = -1.0
        card = []
        while length(singles) > 0
            if noRandom
                s = pop!(singles)
            else
                s = splice!(singles,rand(1:length(singles)))
            end
            okToPrint(4) && println("card = ",ts(s))
            cnt = getCntPlayedCard(s)
            cArr = suitCards(s)
            if okToPrint(4)
                print(" suitcards=") ; ts_s(cArr)
            end
            scnt = 0
            for c in cArr
            scnt += getCntPlayedCard(c)
            end
            if is_c(s)
                m = cnt/4 + scnt/6
            else
                m = cnt/4 + scnt/4
            end
            n1 = nextPlayer(player)
            if findDead && findDeadCard(n1,s,dc_next)
                m = 100
            end
            if m > max
                max = m
                card = s
            end
            okToPrint(4) &&
                println("---->",(ts(s),m))
        end
        okToPrint(4) && println((ts(card),max))
        return card
    end
    function play1Card(player)
        
        allPairs, singles, chot1s, miss1s, missTs, miss1sbar, chotPs, chot1Specials, suitCnt, miss1_1,miss1_2,cTrsh =
        scanCards(vPlayerHand[player],false,true)

        trashCnt = length(singles)+length(missTs)+length(miss1s)+length(chot1s)
        pairsCnt = length(allPairs[1])+length(allPairs[2])+length(allPairs[3])

        ai = aiType[player]
        localAI = ai

        # localAI = mapAI(ai,trashCnt)

        saveSingles = copy(singles)
        if okToPrint(4)
            print("save-singles= ")
            ts_s(saveSingles)
        end

        if length(chot1s) == 1 && length(chotPs) < 2
            push!(singles, chot1s[1])
        else
            if okToPrint(4)
                println("khapMatDau=",khapMatDau[player])
            end
            if khapMatDau[player] < 2 && (length(allPairs[2]) > 0 || length(allPairs[3]) > 0 )
                found = false
                for m1 in miss1s
                    ap = missPiece(m1[1],m1[2])
                    for ps in allPairs[2:3]
                        for p in ps
                            if card_equal(ap,p[1])
                                khapMatDau[player] = 1
                                found = true
                                if okToPrint(4)
                                    println("khap-mat-",(ts(m1[1]),ts(m1[2]),ts(p[1])))
                                end
                                if !is_T(m1[1])
                                    push!(singles,m1[1])
                                end
                                if !is_T(m1[2])
                                    push!(singles,m1[2])
                                end
                                break
                            end
                        end
                    end
                end
                if found == false
                    khapMatDau[player] = 2
                end
            else
                khapMatDau[player] = 2
            end
            if okToPrint(4)
                println("khapMatDau=",khapMatDau[player])
            end
            for m1 in miss1sbar
                for p in allPairs[1]
                    if card_equal(m1,p[1]) && !is_T(m1)
                        pushfirst!(miss1_1,p[1])
                        break
                    end
                end
            end
            if length(singles) == 0
                for mt in missTs
                    for m in mt
                        push!(singles, m)
                    end
                end
            end
            if length(singles) == 0
                if length(miss1s) > 0
                    for m1 in miss1s
                            if !is_T(m1[1]) && !is_T(m1[2])
                                if okToPrint(4)
                                    println((ts(m1[1]),ts(m1[2])))
                                end
                                push!(singles,m1[1],m1[2])
                                for p in allPairs[1]
                                    if card_equal(missPiece(m1[1],m1[2]),p[1])
                                        okToPrint(4) && println("--found Saki------>",(length(p),ts(p[1])))
                                        push!(singles,p[1],p[2])

                                    end
                                end
                            else
                                if !is_T(m1[1])
                                    push!(singles,m1[1])
                                else
                                    push!(singles,m1[2])
                                end
                            end
                    end
                end
                if length(chot1s) > 0
                    for m in chot1s
                        push!(singles,m)
                    end
                end
            end
        end
        c_need = []
        if length(chot1s) > 0
            for c in fourCs
                crt = c_analyzer(chotPs,chot1Specials,c)
                if length(crt) == 0
                push!(c_need,c)
                end
            end
        end


        if okToPrint(4)
            print("---Player:",player)
            print("  ---aiType:",localAI)
            print("  ---suitCnt:",playerSuitsCnt)
            print(" --- TrashCnt:",trashCnt)
            print(" -- Pairs Cnt:",pairsCnt)
            print(" -- Singles:")
            ts_s(singles)
            print(" -- SaveSingles:")
            ts_s(saveSingles)
            println("matched single=",ts(matchSingle)," max_assets =", maxAssets())

            print("missing-one-1 -- ")
            ts_ss(miss1_1)
            print("missing-one-2 -- ")
            ts_ss(miss1_2)
            print("missing T ")
            ts_ss(missTs)
            print("Chot1=")
            ts_s(chot1s)
            print("cho1Specials=")
            ts_s(chot1Specials)
            print("chotPs=")
            ts_ss(chotPs)
            print(" -- c-need=")
            ts_s(c_need)
            n1 = nextPlayer(player)
            print("Dead:")
            ts_s(deadCards[n1])
            print("Probable:")
            ts_s(probableCards[n1])
            println("     ----------- ")
            for n1 in 1:4
                print("Dead$n1:")
                ts_s(deadCards[n1])
                print("Probable$n1:")
                ts_s(probableCards[n1])
            end
        end

        if length(singles) > 0
            if localAI == 1
                card = singles[rand(1:length(singles))]
            elseif localAI == 2
                pickArray = []
                for s in singles
                    cnt = getCntPlayedCard(s)
                    if cnt == 3
                        return s
                    end
                    if is_c(s)
                        rcnt = 10 - cnt
                    elseif is_Tst(s)
                        rcnt = 8 - cnt
                    else
                        rcnt = 6 - cnt
                    end
                    for i in 1:rcnt
                    push!(pickArray,s)
                    end
                end
                card = pickArray[rand(1:length(pickArray))]
            elseif localAI == 3
                    if okToPrint(4)
                        println("In BMAX, player",player, " singles cnt =",length(singles))
                    end
                    card = findWorstCard(singles,player)
            elseif localAI == 4
                    l = min(length(scaleArray)-1,trashCnt)
                    okToPrint(4) && println("Index to Scale Array = ",l)
                    scaleData = scaleArray[l]

                    if length(saveSingles) > 1# && trashCnt < 4
                        blockCard = matchSingle[player]
                        matchSingle[player] = 0
                    else
                        blockCard = 0
                    end
                    max = [[-1000,10],[-1000,10]]
                    if length(chotPs[1]) != 0 || length(chot1s) > 1
                        # MORE THAN 1 CHOT, SO TREAT THEM AS 2 (XP, OR PM)
                        processList!(max,chot1s,player,scaleData[2],0,scaleData[4])
                    end
                    processList!(max,miss1_1,player,scaleData[1],0,scaleData[4])
                    processList!(max,miss1_2,player,scaleData[2],0,scaleData[4])
                    processList!(max,missTs,player,scaleData[3],0,scaleData[4])

                    processList!(max,saveSingles,player,scaleData[4],blockCard,scaleData[4])
                    if length(chotPs[1]) == 0 && length(chot1s) == 1
                        processList!(max,chot1s,player,scaleData[5],0,scaleData[4])
                    end
                    okToPrint(4) && println("Max-Array = ", (max[1][1],ts(max[1][2]) ),(max[2][1],ts(max[2][2])))
                    card = max[1][2]
            else
                    println("SHOULD NOT BE HERE",aiType)
                    exit()
                    max = [[-1000,10],[-1000,10]]
                    processM1Card(max,miss1_1,player)
                    processM2Card(max,miss1_2,player)
                    processM2Card(max,missTs,player)
                    processSCard(max,saveSingles,player)
                    processCCard(max,chot1s,player)
                    okToPrint(4) && println("Max-Array = ", (max[1][1],ts(max[1][2]) ),(max[2][1],ts(max[2][2])))
                    card = max[1][2]
            end
        else
            card =[] # rare case, no trash in the very start
        end
        global coDoiPlayer = 0
        global coDoiCards = []
        okToPrint(0x8) && println("P=",player," Play1card=",ts(card))
        return card
    end
            
    # miss1_1,miss1_2,missT,singles,chot1
    # index by trashs count
    scaleArray = [
    [[1,1,21,-6],[2,1,21,-8],[8,1,21,-2],[8,1,21,1],[2,1,12,0]],
    [[1,1,21,-6],[8,1,21,-8],[8,1,21,-2],[8,1,21,1],[2,1,12,0]],
    [[1,1,21,-6],[8,1,21,-8],[8,1,21,0],[8,1,21,11],[2,1,12,0]],
    [[1,1,21,-6],[8,1,21,-8],[8,1,21,0],[8,1,21,11],[2,1,12,0]],
    [[1,1,4,0],[8,1,4,0],[8,1,4,0],    [8,1,21,16],[4,1,21,17]],
    [[1,1,4,-6],[8,1,1,-8],[10,1,4,0],[32,1,32,16],[24,1,21,17]],
    [[1,1,4,-6],[8,1,1,-8],[10,1,4,4],[32,1,32,16],[24,1,21,17]],
    [[1,1,4,-6],[8,1,1,-8],[10,1,4,4],[32,1,32,16],[24,1,21,17]],
    [[1,1,4,-6],[8,1,1,-8],[10,1,4,4],[32,1,32,16],[24,1,21,17]],
    [[1,1,4,-6],[8,1,1,-8],[10,1,4,4],[32,1,32,16],[24,1,20,17]],
    ]
    function CardinList(card,list)
        for c in list
            if card_equal(c,card)
                return true
            end
        end
        return false
    end
    function CntCardinList(card,list)
        cnt = 0
        for c in list
            if card_equal(c,card) && c!=card
                cnt += 1
            end
        end
        return cnt
    end
    elevateDead= [0,0,0,0]
    """
        getCardCnt(c,player)

        get count for a card: card that has been played/discard or in own hand
    """
    function cntCard(c,player,own=false)

        cnt = getCntPlayedCard(c)
        #print(cnt," ")
        cnt += CntCardinList(c,all_hands[player])

        #print(cnt," ")

        cArr = suitCards(c)
        scnt = 0
        for sc in cArr
            if !is_T(sc) && !card_equal(sc,c)
                scnt += getCntPlayedCard(sc)
                scnt += CntCardinList(sc,all_hands[player])
            end
        end
        #println(scnt)
        mult = length(cArr)
        fcnt = scnt + cnt * mult
        if is_Tst(c)
            fcnt = fcnt / 12
        elseif is_xpm(c)
            fcnt = fcnt / 16
        else
            fcnt = fcnt / 24
        end
        return fcnt
    end

    """
        cardInfo(card,player)

    return a score on a card, and a potential card, higher score means card been 'known'.
    maximum for a xpm is 16, a x count other x by 2, and p,m by 1
    """
    function  cardInfo(card,player)
        tcard = cntCard(card,player)
        pTrsh = playerTrash(player)
        #println("player:$player, Trash:",(player,ts(pTrsh)))
        max = maxc = 0
        for c in pTrsh
            if  !is_T(c) && !card_equal(c,card)
                global cnt = cntCard(c,player,true)
                if cnt > max
                    max = cnt
                    maxc = c
                end
            end
        end
        return cnt,max,maxc
    end
    function processList!(max,list,player,sc,blockCard,sc1)
        finalList = []
        for l in list
            push!(finalList,l)
        end   
        if noRandom == false
            finalList = finalList[randperm(length(finalList))]
        end
        rcnt = 0
        for cs in finalList
            scale = sc
            if length(cs) > 1
                mc = missPiece(cs[1],cs[2])
                dead = getCntPlayedCard(mc) > 2
                if dead
                    scale = sc1
                end
            end
            for c in cs
                rcnt += 1
                cnt = getCntPlayedCard(c)
                cArr = suitCards(c)
                scnt = 0
                found = false
                for sc in cArr
                    a = getCntPlayedCard(sc)
                    if a == 4
                        a = 12
                    end
                    scnt += a
                    if card_equal(blockCard,sc)
                        (okToPrint(4)) && println("FOUND blockCard = ",ts(blockCard))
                        found = true
                    end
                end
                if found
                    scnt = -1
                end
    
                score = cnt*scale[1] + scnt*scale[2] + scale[4]
                if c == highValue[player]
                    score += score + 500
                    highValue[player] = 0
                end
                score_addon = 0
                for p2 in allPairs[1]
                    if card_equal(p2[1],c)
                        score_addon -= 4*(scale[1])
                        break
                    end
                end
    
                okToPrint(4) && print("score=$score addon-->",score_addon)
    
                if cardHasPair(c)
                    score_addon += is_Tst(c)&& !has_T(c) ? 0 : -3*scale[2]
                elseif cardHasTripple(c)
                    score_addon += abs(scale[4])
                    if is_c(c)
                        score_addon = score_addon >> 2
                    end
                end
                okToPrint(4) && print("-->",score_addon)
                if emBaiTrigger[player][1] >= 0
                    n2 = emBaiTrigger[player][2]
                    df =  findDeadCard(n2,c,dc_target)
                else
                    df = false
                end
                 n1 = nextPlayer(player)
                if CardinList(c,nDead[player])|| findDeadCard(n1,c,dc_next) || df
                    score_addon += elevateDead[player] > 0 ? scale[3]<<6 : scale[3]
                end
    
                okToPrint(4) && println("-->",score_addon)
    
                if score_addon != 0
                    score += score_addon
                else
                    score += is_Tst(c)&&!has_T(c) ? 1 : 0
                end
    
                if score >= max[1][1]# || ((score == max[1]) && (rand((0:rcnt)) == 0 ))
                    max[2][1] = max[1][1]
                    max[2][2] = max[1][2]
    
                    max[1][1] = score
                    max[1][2] = c
                else
                    if score >= max[2][1]
                        max[2][1] = score
                        max[2][2] = c
                    end
                end
                (okToPrint(4)) && println("max=",(max[1][1],ts(max[1][2])),"Card(",ts(c),") , score = $score ,cnt = $cnt, suitcnt = $scnt",scale)
            end
        end
    end
    
    #=
        For every card, we need to evaluate from 2 perspectives:
            1) out-going, minimize the probability of being taken by others
            2) keepng cards that has higher probability of being received

            for every entry, calculate the probability of get rid of it and not be used
                the oppposite is the probability of getting a card to complete a suit

    =#
    function processSCard(max,list,player)

    end

    function processM1Card(max,list,player)

    end

    function processM2Card(max,list,player)

    end

    function processCCard(max,list,player)

    end

    function randomSampling(c,list)

    end

    function list(s1,s2,p1,p2,p3)
        r =[]
        for l in s1
            push!(r,l)
        end
        for l in s2
            push!(r,l)
        end
    
        for ls in p1
            for l in ls
                push!(r,l)
            end
        end
        for ls in p2
            for l in ls
                push!(r,l)
            end
        end
        for ls in p3
            for l in ls
                push!(r,l)
            end
        end
        return r
    end
    
    function playerTrash(player)
        list = union(singles,chot1s)
        for l in union(miss1s,missTs)
            union!(list, l)
        end
        return list
    end
    
    function deadCardsExist(player,mode=dc_target,list = false)
        cnt = 0
        trashCnt = length(singles)+length(missTs)+length(miss1s)+length(chot1s)
        lst = []
        pTrsh = playerTrash(player)
    
        for a in pTrsh
                if !is_T(a) &&findDeadCard(player,a,mode)
                    push!(lst,a)
                    cnt += 1
                end
        end
    
        if list
            return cnt,lst
        else
            return cnt
        end
    end
    
    function beDefensive(player)
        global capturedCPoints
        tps =cmpPoints(playerSuitsCnt, khui,kpoints)
        max,t = findmax(tps)
        if max >= emBaiLimit[player]
            tps[t] = 0
            max2,t2 = findmax(tps)
            delta = max - max2
            if delta*4 > max
                t2 = 0
            end
            if player == t
                t = t2
                t2 = 0
            elseif player == t2
                t2 = 0
            end
            if emBaiTrigger[player][1] >= 0 && t > 0
                oldTps = capturedCPoints[player]
                deltaTps = tps .- oldTps    
                deltaTps[t] = 0
                maxTps,tTps = findmax(deltaTps)
                if deltaTps[tTps] > 2
                    t2 = tTps
                end
            end
         
            return t,t2
        end
        return 0,0
    end
    
    """
        defensive(pc,player,rc)
    
    true if not want to take and play anycard.
        it would take and play if it thinks the play card has higher score (been seen)
    """
    function em_Bai(pc,player,rc)
        global oneTime,elevateDead,nDead
            global highValue
            highValue[player] = 0
            rcisPair = isPair(rc)
    
            if isTripple(rc) ||
                ( cFlag && length(rc) == 2 && !card_equal(rc[1],rc[2]) && gameTrashCntLatest[player] < 4 ) ||
                (gameTrashCntLatest[player] < 3)
                return false
            end
    
            r1,r2 = beDefensive(player)
    
    
            it = glIterationCnt >> 2
    
            global emBaiTrigger
            if emBaiTrigger[player][1] < 0
                if r1 > 0
                    emBaiTrigger[player] = [it, r1,r2]
                    capturedCPoints[player] = cmpPoints(playerSuitsCnt, khui,kpoints)
                end
            else
                if r1 >0 && r1 != emBaiTrigger[player][2]
                     emBaiTrigger[player][2] = r1
                end
                if r2 >0 && r2 != emBaiTrigger[player][3]
                    emBaiTrigger[player][3] = r2
                end
            end
            it = it >> 2
            if emBaiTrigger[player][1] >= 0 && (gameTrashCntLatest[player]+it) > 5
                return true
            end
            if r1+r2 == 0
                elevateDead[player] = 0
                return false
            elseif r1 != 0 && r2 != 0
                elevateDead[player] = r1
                    return true
            end
            nDead[player] =[]
            elevateDead[player] = t = r1
    
          #  if true || getCardFromDeck
            if t > 0 && findDeadCard(t,pc,dc_target)  == false
                ci = cardInfo(pc,player)
            else
                ci = [1.0,0.0]
            end
          #  println("MARK",findDeadCard(t,pc,dc_target),(currentPlayer,prevPlayer(player),t,CardFromDeck,rcisPair,prevPlayer(t)))
            if prevPlayer(player) == t  && rcisPair ||
                (rcisPair && (player != prevPlayer(t) && (currentPlayer == prevPlayer(t)))) ||
                (CardFromDeck && (((currentPlayer == t) && rcisPair) || (CardFromDeck && currentPlayer == prevPlayer(t) &&(ci[1] <= ci[2] ))))
                if okToPrint(0x20)
                    println("*********************************")
                    println("*        EARLY                  *")
                    println("*********************************")
                end
                return false
            end
            if r2 == 0
                n1 = nextPlayer(player)
            else
                n1 = r2
            end
            cnt,la = deadCardsExist(n1,dc_next,true)
    
            n2 = t
            cnt1,lb = deadCardsExist(n2,dc_target,true)
            okToPrint(0x20) && println("DDD($player)=",(ts(rc)),(r1,r2),(cmpPoints(playerSuitsCnt, khui,kpoints),emBaiLimit),emBaiTrigger,(cnt,cnt1),(ts(la),ts(lb)))
    
            cnt += cnt1
            if cnt == 0  && r1 != player && r2 != player
                if okToPrint(0x20)
                println("*********************************")
                println("*          PASSED               *")
                println("*********************************")
                end
                rr = true
            else
                for c in la
                    push!(nDead[player],c)
                end
                for c in lb
                    push!(nDead[player],c)
                end
                rr = false
                for c in nDead[player]
                    for r in rc
                        if card_equal(r,c)
                            if okToPrint(0x20)
                            println("*********************************")
                            println("*          PASSED               *")
                            println("*********************************")
                            end
                            rr = true
                            break
                        end
                    end
                end
            end
            if rr  && ci[1] <= ci[2] && player != prevPlayer(t) # only trade card if it next to trget
                if okToPrint(0x20)
                println("*********************************")
                println("* ",ci[1], "  <=  ",ci[2]," ",ts(ci[3]))
                println("*********************************")
                end
                highValue[player] = ci[3]
                rr = false
            end
            return rr
    end
    
    """
        passOnMatchLastTrash(pcard,cards)
    
    0: not pass
    2: pass
    1: may-be, if not defensive, the true
    """
    function passOnMatchLastTrash(pcard,cards,flag)
        if length(cards) == 0
            return 2,false,false
        end
        ls = length(singles)
        lmt = length(missTs)
        lm1s = length(miss1s)
        lc1s = length(chot1s)
    
        if (ls+lmt+lm1s == 0 && lc1s <= 2 ) ||
            (lc1s == 0 && ls+lmt+lm1s == 1)
    
            if card_equal(pcard,cards[1]) == false
                return 0,true,true
            else
                if length(cards) == 1
                    if ls > 0
                        return 0,true,true
                    else
                        if lc1s > 0
                            if lc1s ==1
                                return 0,true,true
                            else
                                n = flag ? 2 : 0
                                return n,false,true
                            end
                        else
                            #lmt or lm1s
                            #after this no trash
                            n = flag ? 1 : 0
                            return n,false,true
                        end
                    end
                else
                    n = flag ? 1 : 0
                    return n,false,true
                end
            end
        else
            return 0,false,false
        end
    end
    maxAssets() = max(length(playerAsset[1]),length(playerAsset[2]),length(playerAsset[3]),length(playerAsset[4]))
    
    
    function Match2Card(pcard,player)
        global allPairs, singles, chot1s, miss1s, missTs, miss1sbar, chotPs, chot1Specials, suitCnt, miss1_1,miss1_2,cTrsh,
        coDoiCards,coDoiPlayer
        global currentAction = gpCheckMatch2 

        allPairs, singles, chot1s, miss1s, missTs, miss1sbar, chotPs, chot1Specials, suitCnt, miss1_1,miss1_2,cTrsh =
        scanCards(vPlayerHand[player],false,true)

        card1 = chk1(pcard)
        card2 = chk2(pcard)
        if coDoiPlayer == 0 && (length(coDoiCards) > 0 )
            println("CoDoi -- ",(player,ts(coDoiCards)))
            coDoiPlayer = player
        end
        ls = length(singles)
        lmt = length(missTs)
        lm1s = length(miss1s)
        lc1s = length(chot1s)
        gameTrashCntLatest[player] = ls + lmt + lm1s + lc1s
            global gameTrashCnt,gameTrashCntLatest
            if gameTrashCnt[player] == 0
                gameTrashCnt[player] = ls + lmt + lm1s + lc1s
            end
        if length(card1) == 0
            rc = card2
        elseif length(card2) == 0 || !card_equal(card2[1],card2[2])
                rc = card1
        else
            rc = card2
        end
        if okToPrint(0x8)
            println("Played(1)-",ts(card1)," Played(2)-",ts(card2))
        end
       
        pass,win,lastTrsh = passOnMatchLastTrash(pcard,rc,boDoiFlag[player])
        if win
            okToPrint(1) && println("P=",player," Match2=",ts(rc),".")
            return rc
        elseif pass > 2
            rc = []
        else
            if !mydefensiveFlag[player] && pass >0
                rc = []
            end
            if length(rc) > 0 && mydefensiveFlag[player] &&em_Bai(pcard,player,rc)
                okToPrint(0x20) && println(", Em-bai rc=",ts(rc))
                rc = []
            end
    
        end
        if lastTrsh && length(rc) == 0
            boDoiPlayers[player] = glIterationCnt >> 2
        end
        #=
        if length(rc) > 0
            global coDoiCards = []
        end
        =#
        if highValue[player] != 0
            for c in rc
                if card_equal(c,highValue[player])
                    if length(rc) == 1
                        rc = []
                    end
                    highValue[player] = 0
                    break
                end
            end
        end
        okToPrint(1) && println("P=",player," Match2=",ts(rc))
        return rc
    
    end
    function Match1or2Card(pcard,player)

        global allPairs, singles, chot1s, miss1s, missTs, miss1sbar, chotPs, chot1Specials, suitCnt, miss1_1,miss1_2,cTrsh,coDoiCards,coDoiPlayer

        global currentAction = gpCheckMatch1or2 

        println("In Match1or2Card ",(ts(pcard),player))
        allPairs, singles, chot1s, miss1s, missTs, miss1sbar, chotPs, chot1Specials, suitCnt, miss1_1,miss1_2,cTrsh =
        scanCards(vPlayerHand[player],false,true)

        card1 = chk1(pcard)
        card2 = chk2(pcard)
        if coDoiPlayer == 0 && (length(coDoiCards) > 0 )
            println("CoDoi -- ",(player,ts(coDoiCards)))
            coDoiPlayer = player
        end
        ls = length(singles)
        lmt = length(missTs)
        lm1s = length(miss1s)
        lc1s = length(chot1s)
        gameTrashCntLatest[player] = ls + lmt + lm1s + lc1s
    
            global gameTrashCnt,gameTrashCntLatest
            if gameTrashCnt[player] == 0
                gameTrashCnt[player] = ls + lmt + lm1s + lc1s
            end
            if length(card2) == 3
            rc = card2
        elseif length(card1) >0
            rc = card1
        else
            rc = card2
        end
    
        if okToPrint(0x8)
            println("Played(1)-",ts(card1)," Played(2)-",ts(card2))
        end
        pass,win,lastTrsh = passOnMatchLastTrash(pcard,rc,boDoiFlag[player])
        if win
            okToPrint(1) && println("P=",player," Match2+1=",ts(rc),".")
            return rc
        elseif pass > 2
            rc = []
        else
            if !mydefensiveFlag[player] && pass >0
                rc = []
            end
            if length(rc) > 0 &&mydefensiveFlag[player] && em_Bai(pcard,player,rc)
                okToPrint(0x20) && println(", Em-bai rc=",ts(rc))
                rc = []
            end
    
        end
        if lastTrsh && length(rc) == 0
            boDoiPlayers[player] = glIterationCnt >> 2
        end
        if highValue[player] != 0
            for c in rc
                if card_equal(c,highValue[player])
                    if length(rc) == 1
                        rc = []
                    end
                    highValue[player] = 0
                    break
                end
            end
        end
        okToPrint(1) && println("P=",player," Match2-1=",ts(rc))
        return rc
    end

    function whoWinRound(card, play4,  n1, r1, n2, r2, n3, r3, n4, r4)
        okToPrint(0x20) && println(" pc=",ts(card),(n1,ts(r1)),(n2,ts(r2)),(n3,ts(r3)),(n4,ts(r4)))
        function getl!(card, n, r)
            if okToPrint(0x8)
                println("Getl ------ n=",n)
            end
            l = length(r)
            if (l > 1) && !card_equal(r[1], r[2]) # not pairs
                l = 1
            end
            if length(r) > 0
                newHand = sort(cat(card,r;dims = 1))
                aps, ss, cs, m1s, mTs, m1sb,cPs,c1Specials = scanCards(newHand, true)
                if (length(ss)+length(cs)+length(m1s)+length(mTs)) > 0
                    if okToPrint(0x8)
                        println("whoWin(getl)",(length(ss),length(cs),length(m1s),length(mTs)))
                    end
                    return 0, false, []
                end
            end
            thand = deepcopy(vPlayerHand[n])
            moreTrash = false
            ops,oss,ocs,om1s,omts,ombs =  scanCards(thand, true)
            oll = length(oss) + length(ocs) + length(om1s) + length(omts)

            win = false
            if l > 0 || is_T(card)# only check winner that has matched cards
                if length(r) == 3 && is_T(card) && is_T(r[1]) && is_T(r[2]) && is_T(r[3])
                    l = 4
                end
                for e in r
                    filter!(x -> x != e, thand)
                end
                ps, ss, cs, m1s, mts, mbs = scanCards(thand, false)
                if (l == 2) && card_equal(r[1],r[2]) # check for SAKI
                    for m in mbs
                        if card_equal(m,r[1]) && !is_Tst(m)
                            if okToPrint(0x8)
                            println("match ",ts_s(r)," is SAKI, not accepted")
                            end
                            l = 0
                        end
                    end
                end
                ll = length(ss) + length(cs) + length(m1s) + length(mts)

                if oll < ll
                    if okToPrint(0x8)
                        println("whowin, chking more Trsh:",
                        (length(ss) , length(cs) , length(m1s) , length(mts)),
                        (length(oss) , length(ocs) , length(om1s) , length(omts)))
                    end
                    l = 0
                    r = []
                end
                if ll == 0

                    l = 4
                    win = true
                end
            end
            return l, win,r
        end

        l1, w1, r1 = getl!(card, n1, r1)
        l2, w2, r2 = getl!(card, n2, r2)
        l3, w3, r3 = getl!(card, n3, r3)
        l4, w4, r4 = getl!(card, n4, r4)
        if okToPrint(0x1)
        #  println("W-wr result ",(l1, w1, ts_s(r1,false) ),(l2, w2, ts_s(r2,false)),(l3, w3, ts_s(r3,false)),(l4, w4, ts_s(r4,false)))
            println("W-wr result ",(l1, w1, r1 ),(l2, w2,r2),(l3, w3,r3),(l4, w4,r4))
        end
        if is_T(card)
            l1 = l1 != 4 ? 0 : 4
            l2 = l2 != 4 ? 0 : 4
            l3 = l3 != 4 ? 0 : 4
            l4 = l4 != 4 ? 0 : 4
        end

        if !play4 && (l2 == 1)
                l2 = 0
        end
        if w1
            w2 = false
            w3 = false
            w4 = false
            l2 = 0
            l3 = 0
            l4 = 0
        elseif w2
            w3 = false
            w4 = false
            l1 = 0
            l3 = 0
            l4 = 0
        elseif w3
            w4 = false
            l1 = 0
            l2 = 0
            l4 = 0
        elseif w4
            l1 = 0
            l2 = 0
            l3 = 0
        end

        if l1 == 4
            w = 0
        elseif l2 == 4
            w = 1
        elseif l3 == 4
            w = 2
        elseif l4 == 4
            w = 3
        else
            if l1 > 1
                w = 0
            elseif l2 > 1
                w = 1
            elseif l3 > 1
                w = 2
            elseif l4 > 1
                w = 3
            else
                if play4 && (l2 > 0) && (l1 == 0)
                    w = 1
                else
                    w = 0
                end
            end
        end
        r = w == 0 ? r1 : w == 1 ? r2 : w == 2 ? r3 : r4
        n = rem((n1 - 1 + w), 4) + 1
        if w1 || w2 || w3 || w4   # game over
            w = 0xFE
        end
        if okToPrint(0x1)
        println("Who win ? p4, n,w,r", (play4, n, w, ts(r)), (l1, l2, l3, l4),(ts(r1),ts(r2),ts(r3),ts(r4)))
        end
        return n, w, r
    end

    
    function whoWinRnd(pcard,play3,t1Player,nc)
        t2Player = nextPlayer(t1Player)
        t3Player = nextPlayer(t2Player)
        t4Player = nextPlayer(t3Player)
        if play3 
            nPlayer, winner, r = whoWinRound(
                pcard,
                !play3,
                t2Player,
                nc[2],
                t3Player,
                nc[3],
                t4Player,
                nc[4],
                t2Player,
                nc[2],
            )
        else
            nPlayer, winner, r = whoWinRound(
                pcard,
                !play3,
                t1Player,
                nc[1],
                t2Player,
                nc[2],
                t3Player,
                nc[3],
                t4Player,
                nc[4]
            )
        end
        if is_T(pcard) && winner == 0 && length(r)==0
            winner = t1Player
        end
        return nPlayer, winner, r
    end
    
    function endTurn()
        nPlayer, winner, r =  whoWin!(glIterationCnt, glNewCard,glNeedaPlayCard,t1Player,t2Player,t3Player,t4Player)
    end


    function c_points(p,s)
        points = 0
        if length(p[1]) == 4
            points = 4
        elseif length(p[1]) == 3
            points = 2
            if length(s) > 0
                points = 3
            end
        elseif length(p[1]) == 2
            if length(s) == 2
                points = 2
            end
        elseif length(s) > 2
            points = length(s) - 2
        end
        return points
    end
    
    function pointsCalc(winner)
        global pots, kpoints, points, khui
        if winner < 5
            allPairs, single, chot1, miss1, missT, miss1Card, chotP, chot1Special, suitCnt =
            scanCards(vPlayerHand[winner],false,true)
            points[winner] += 3 + suitCnt + c_points(chotP,chot1Special)+ kpoints[winner]
            if khui[winner] == 2
                points[winner] *= 2
            end
            kpoints[winner] = points[winner]
        else
            kpoints = zeros(Int8,4)
        end
    end

    function pointsUpdate(nP,nr,activeCard)
        if length(nr)== 2 || (is_T(activeCard) && length(nr) == 0)
            points[nP] += 1
        elseif length(nr) == 3 
            if card_equal(nr[1],nr[2])
                kpoints[nP] += 3
                if is_T(nr[1])
                    points[nP] += 3
                end
                khui[nP] = 2
            else
                points[nP] += 2
            end
        end
    end

end # end TuSacManager


coldStart = true
shufflePlayer = 1
isServer() = mode == m_server
n = PROGRAM_FILE
n = chop(n,tail=3)
fn = string(n,".cfg")
println("File=",fn)
mode_human = false
mode = m_standalone
serverURL = "baobinh.tpdlinkdns.com"
serverPort = 11029
serverIP = ip"192.168.0.35"
GAMEW =900
GENERIC = 3
histFile = false
reloadFile = false
RFindex = ""
hints = 0
GUI = true
RF = 0
NAME= "PLayer?"
fontSize = 50
showLocation = false
testFile = ""
isTestFile = false
if okToPrint(0x1)
println((PlayerList, mode,mode_human,serverURL,serverIP,serverPort, gamew,macOS,numberOfSocketPlayer,myPlayer))
end

function correctFileName(name)
    name1 = string(name,".txt")
    tname = [string("tests/",name),string("tests/",name1),name,name1,]
    for n in tname
        isfile(n) && return true,n
    end
    return false,""
end
lcCmp(a,b) = lowercase(a) == lowercase(b)
function config(fn)
    global PlayerList,noGUI_list, mode,NAME,playerName,GUI,fontSize,histFILENAME,testFile,bodoiInspect,emBaiLimit,boDoiFlag,mydefensiveFlag,
    mode_human,serverURL,serverIP,serverPort, hints,allowPrint,wantFaceDown,showLocation,echoOption,reduceFile,noRandom,
    gamew,macOS,numberOfSocketPlayer,myPlayer,GENERIC,HF,histFile,RF,reloadFile,upgradeAllowPrint,stickyAllowPrint,
    RFindex,isTestFile,RFstates,RFaline,testList, trial, aiType,aiTrait, playerName,aiFilename,stopOn,defensiveFlag
    global GUILoc

    if !isfile(fn)
        println(fn," does not exist, please configure one. Similar to this\n
        name Binh
        mode standalone
        GUI true
        human true
        server baobinh.tpdlinkdns.com 11029
        client 192.168.0.53
        GAMEW 900
        macOS true")
    else
        cfg_str = readlines(fn)
        for line in cfg_str
            rl = split(line,' ')
            keyword = rl[1]
            if lcCmp(keyword,"name")
                NAME = rl[2]
                playerRootName[myPlayer] = NAME
                playerName[myPlayer] = string(playerRootName[myPlayer],aiTrait[myPlayer])
            elseif lcCmp(keyword,"upgradeAllowprint")
                upgradeAllowPrint = parse(Int,rl[2])
            elseif lcCmp(keyword,"aiTune")
                aiFilename = rl[2]
            elseif lcCmp(keyword,"defensiveFlag")
                defensiveFlag = rl[2] == "true"
            elseif lcCmp(keyword,"stopOn")
                stopOn = rl[2]
                println(stopOn)
            elseif lcCmp(keyword,"BoDoiInspect")
                bodoiInspect = rl[2] == "true"
            elseif lcCmp(keyword,"noRandom")
                noRandom = rl[2] == "true"
                TuSacManager.setNoRandom(noRandom)
            elseif lcCmp(keyword,"emBai")
                emBaiLimit += [parse(Int,rl[2]),parse(Int,rl[3]),parse(Int,rl[4]),parse(Int,rl[5])]
                println("Modified Em-bai limit = ",emBaiLimit)
            elseif lcCmp(keyword,"echoOption")
                for i in 2:length(rl)
                    echoOption = string(echoOption," ",rl[i])
                end
                println(echoOption)
            elseif lcCmp(keyword,"mode")
                mode = rl[2] == "client" ? m_client : rl[2] == "server" ? m_server : m_standalone
            elseif lcCmp(keyword,"human")
                mode_human = rl[2] == "true"
            elseif lcCmp(keyword,"cFlag")
                    mode_human = rl[2] == "true"
            elseif lcCmp(keyword,"trial")
                    trial = rl[2] == "true"
            elseif lcCmp(keyword,"showLocation")
                showLocation = true
            elseif lcCmp(keyword,"allowPrint")
                stickyAllowPrint = allowPrint = parse(Int,rl[2])
                TuSacCards.allwPrint(allowPrint)
                TuSacManager.allwPrint(allowPrint)
            elseif lcCmp(keyword,"aiTrait")
                    aiTrait = [parse(Int,rl[2]),parse(Int,rl[3]),parse(Int,rl[4]),parse(Int,rl[5])]
                    aiType = aiTrait .>> 2
                    

                    println("AITYPE=", (aiTrait,aiType))
                    TuSacManager.setAITRAIT(aiTrait)
                    playerName = setPlayerName(playerRootName,aiTrait)
                    boDoiFlag = (aiTrait .& 0x1 ) .!= 0
                    mydefensiveFlag = defensiveFlag .& ((aiTrait .& 0x2) .!= 0)
                
            elseif lcCmp(keyword,"serverURL")
                serverURL = string(rl[2])
                length(rl) > 2 && (serverPort = parse(Int,rl[3]))
            elseif lcCmp(keyword,"serverIP")
                serverIP = getaddrinfo(string(rl[2]))
                length(rl) > 2 && (serverPort = parse(Int,rl[3]))

            elseif lcCmp(keyword,"server")
                serverURL = string(rl[2])
                length(rl) > 2 && (serverPort = parse(Int,rl[3]))
            elseif lcCmp(keyword,"myIP")
                serverIP = getaddrinfo(string(rl[2]))
                length(rl) > 2 && (serverPort = parse(Int,rl[3]))

            elseif lcCmp(keyword,"gamew")
                gamew = parse(Int,rl[2])
            elseif lcCmp(keyword,"generic")
                GENERIC = parse(Int,rl[2])
            elseif lcCmp(keyword,"hints")
                hints = parse(Int,rl[2])
                if okToPrint(0x1)
                println("hints = ",hints)
                end
            elseif lcCmp(keyword,"fontSize")
                fontSize = parse(Int,rl[2])
            elseif lcCmp(keyword,"wantFacedown")
                wantFaceDown = rl[2] == "true"
            elseif lcCmp(keyword,"numberOfSocketPlayer")
                numberOfSocketPlayer = parse(Int,rl[2])
            elseif lcCmp(keyword,"cardscale")
                cardScale = parse(Int,rl[2])
            elseif lcCmp(keyword,"myPlayer")
                myPlayer = parse(Int,rl[2])
                if okToPrint(0x1)
                println(rl[2]," = ",myPlayer)
                end
            elseif lcCmp(keyword,"macOS")
                macOS = rl[2] == "true"

            elseif lcCmp(keyword,"reduceFile")
                reduceFile = true
            elseif lcCmp(keyword,"histFile")
                histFile = true
                histFILENAME = rl[2]
                global hfName = nextFileName(histFILENAME,chFilenameStr)

            elseif lcCmp(keyword,"reloadFile")
                reloadFile = true
                iname = rl[2]
                while true
                    done,name = correctFileName(iname)
                    if done
                        RF = open(name,"r")
                        break
                    else
                        println(iname," not exist! Please enter new name:")
                        iname = readline()
                    end
                end
                RFindex = rl[3]
                println(RFindex)
            elseif lcCmp(keyword,"testFile")
                iname = rl[2]
                while true
                    done,name = correctFileName(iname)
                    if done
                        RF = open(name,"r")
                        break
                    else
                        println(iname," not exist! Please enter new name:")
                        iname = readline()
                    end
                end
                testList = []
                trialFound = false
                while true
                    RFaline = readline(RF)
                    RFstates = split(RFaline," ")
                    if RFstates[1] != "#"
                        break
                    end
                    if !trialFound && length(RFstates) > 1 && RFstates[2][1] == '('
                        if trial
                            push!(testList,(RFstates[2],true))
                            trialFound = true
                        else
                            push!(testList,(RFstates[2],RFstates[3]=="true"))
                        end
                    end
                end
                sort!(testList)
                println("TestList=",testList)
                isTestFile = true
            end
        end
    end
    if fontSize == 50 && !macOS
        fontSize = 24
    end
 
    if mode == m_standalone && mode_human
        PlayerList[myPlayer] = plHuman
    end
    if length(stopOn) == 0 && !GUI && histFile
            println("Are you sure to save to histFile, ctrl-c to cancel")
            readline()
    end
    if reduceFile
        histFile = false
    end
    if histFile
        HF = open(hfName,"w")
        println(HF,"#")
        println(HF,"#")
        println(HF,"#")
        histFILENAME = hfName
    end
    return (PlayerList, mode,mode_human,serverURL,serverIP,serverPort, gamew,macOS,numberOfSocketPlayer,myPlayer)
end
saveNameLoc = 0
function nextFileName(fn,filenameStr)
    global saveNameLoc
    n = findfirst('#',fn)
    if n === nothing
        n = saveNameLoc
        achar = fn[n]
        cl = findfirst(achar,filenameStr)
        if cl == length(filenameStr)
            cl = 1
        else
            cl += 1
        end
        rfilename = string(fn[1:n-1],filenameStr[cl],fn[n+1:end])
    else
        saveNameLoc = n
        found = false
        for i in filenameStr
            global nfn = string(fn[1:n-1],i,fn[n+1:end])
            if isfile(nfn) == false
                found = true
                break
            end

        end
        if found
            rfilename = nfn
        else
            rfilename = string(fn[1:n-1],1,fn[n+1:end])
        end
    end

    return rfilename
end

prevWinner = 1


(PlayerList, mode,mode_human,serverURL,serverIP,
serverPort, gamew,macOS,
numberOfSocketPlayer,myPlayer) = config(fn)

if isfile(".tusacrc")
    (PlayerList, mode,mode_human,serverURL,serverIP,
serverPort, gamew,macOS,
numberOfSocketPlayer,myPlayer) =config(".tusacrc")
elseif isfile("../.tusacrc")
    (PlayerList, mode,mode_human,serverURL,serverIP,
serverPort, gamew,macOS,
numberOfSocketPlayer,myPlayer) =config("../.tusacrc")
end

function playerIsHuman(p)
    return ((p == myPlayer) && mode_human)
end

#ar = TuSacCards.toValueArray(dd)
#println(ar)
const gsOrganize = 1
const gsSetupGame = 2
const gsStartGame = 3
const gsGameLoop = 4
const gsRestart = 5

const tsSinitial = 0
const tsSdealCards = 1
const tsSstartGame = 2
const tsGameLoop = 3
const tsRestart = 6
const tsTest = 4
const tsHistory = 5

tusacState = tsSinitial

"""
    _ts(a)

print out 1 card
"""
function _ts(a)
        TuSacCards.Card(a[1])
end

"""
    ts(a)

to print out card of 1 element or an array
"""
function ts(a)
    st = ""
    if length(a) == 1
        st = _ts(a)
    else
        if length(a) > 1
            for i in 1: lastindex(a)-1
                st = string(st,_ts(a[i])," ")
            end
            st = string(st,_ts(a[end]))
        end
    end
    return st
end


function ts_s(rt, sp = "", n = true)
    for rq in rt
        print(" ",ts(rq))
        if length(rq) > 1
            for r in rq[2:end]
                print("+",ts(r))
            end
        end
    end
    print(sp)
    if n
        println()
    end
    return
end

"""
    tss(g)

to print out arr of arr of cards, like this [[],[],[]]
"""
function tss(g,s1=" ",s2=", ")
    st = ""
    for (i,a) in enumerate(g)
        for (j,b) in enumerate(a)
            if j == length(a)
                st = string(st,_ts(b))
            else
                st = string(st,_ts(b),s1)
            end
        end
        if i != length(g)
            st = string(st,s2)
        end
    end
    return st
end

const T = 0
const V = 1 << 5
const X = 2 << 5
const D = 3 << 5

is_T(v) = (v & 0x1C) == 0x4
to_T(v) = v&0xf3 | 0x4

is_s(v) = (v & 0x1C) == 0x8
to_s(v) = v&0xf3 | 0x8

is_t(v) = (v & 0x1C) == 0xc
to_t(v) = v&0xf3 | 0xc

is_Tst(v) = (0xd > (v & 0x1C) > 3)


"""
    c(v) is a chot
"""
fourCs = [0x10,0x30,0x50,0x70]
is_c(v) = ((v & 0x1C) == 0x10)

is_colorT(v) = ((v & 0x60) == 0x00)
is_colorV(v) = ((v & 0x60) == 0x20)
is_colorX(v) = ((v & 0x60) == 0x40)
is_colorD(v) = ((v & 0x60) == 0x60)

to_colorT(v) = ((v & 0x1c) | T)
to_colorV(v) = ((v & 0x1c) | V)
to_colorX(v) = ((v & 0x1c) | X)
to_colorD(v) = ((v & 0x1c) | D)
"""
    x(v) is a xe
"""

is_x(v) = ((v & 0x1C) == 0x14)
to_x(v) = v&0xf3 | 0x4

"""
    p(v) is a phao
"""
is_p(v) = (v & 0x1C) == 0x18
to_p(v) = v&0xf3 | 0x8

"""
    m(v) is a ma
"""
is_m(v) = (v & 0x1C) == 0x1c
to_m(v) = v&0xf3 | 0xc


is_xpm(v) = 0x1d > (v & 0x1C) > 0x13
function suitCards(v)
    if is_Tst(v)
        return [is_s(v) ? to_t(v) : to_s(v)]
    elseif is_xpm(v)
        if is_x(v)
            return [to_p(v),to_m(v)]
        elseif is_p(v)
            return [to_x(v),to_m(v)]
        else
            return [to_x(v),to_p(v)]
        end
    else
        if is_colorT(v)
            return [to_colorV(v),to_colorD(v),to_colorX(v)]
        elseif is_colorV(v)
            return [to_colorT(v),to_colorD(v),to_colorX(v)]
        elseif is_colorD(v)
            return [to_colorT(v),to_colorV(v),to_colorX(v)]
        else
            return [to_colorT(v),to_colorV(v),to_colorD(v)]
        end
    end
end

"""
    inSuit(a,b): check if a,b is in the same sequence cards (Tst) or (xpm)
"""
inSuit(a, b) = (a & 0xc != 0) && (b & 0xc != 0) && (a & 0xF0 == b & 0xF0)

"""
    inStrictSuit(a,b): check if a,b is in the same sequence cards (Tst)
    or (xpm) or chot, but remove equal cards
"""
inAllStrictSuit(a,b) = !card_equal(a,b) && ((inSuit(a,b)) || (is_c(a) && is_c(b)))
"""
    inTSuit(a)
     a is either si or tuong

"""
inTSuit(a) = (a&0x1c == 0x08) || (a&0x1c == 0x0C)
function suit(r,matchc)
    if length(r) != 2
        return false
    end
    rt = card_equal(missPiece(r[1],r[2]), matchc)
    if okToPrint(0x8)
        print("co-doi, chkSuit",rt);ts_s(r);ts_s(matchc)
    end
    return rt
end

"""
    miss(s1,s2): creat the missing card for group of 3,

"""
missPiece(s1, s2) = (s2 > s1) ? (((((s2 & 0xc) - (s1 & 0xc)) == 4 ) ?
                                ( ((s1 & 0xc) == 4) ? 0xc : 4 ) : 8) |
                                (s1 & 0xF3)) :
                                (((((s1 & 0xc) - (s2 & 0xc)) == 4 ) ?
                                ( ((s2 & 0xc) == 4) ? 0xc : 4 ) : 8) |
                                    (s2 & 0xF3))

"""
    all_chots(cards,pc)
all is Chots
"""
function all_chots(cards,pc)
    for c in cards
        if card_equal(pc,c)
            return false
        end
    end
    if length(cards) == 1
        return false
    else
        if card_equal(cards[1],cards[2])
            return false
        end
        if length(cards)==3
            return !card_equal(cards[3],cards[2])
        end
    end
    return true
end
"""
    card_equal(a,b): a,b are the same card (same color, and same kind)
"""
card_equal(a, b) = a&0xFC == b&0xFC

isPair(r) = length(r) == 2 ? card_equal(r[1],r[2]) : false
isTripple(r) = length(r) == 3 ? card_equal(r[1],r[2]) : false

global currenAction

"""
     mapping a player number (realp) to a new number relative to the player 
        P   no   R
        1   n    n
        2   2    1
        2   3    2
        2   4    3
        2   1    4

        3   3    1
        3   4    2
        3   1    3
        3   2    4

        4   4    1
        4   1    2
        4   2    3
        4   3    4
    """
function mappingPlayer(player,relativeP)
    if relativeP == 0
        return 0
    end
    #discard vs asset 
    m = relativeP > 4 ? relativeP-4 : relativeP
   
    r = m - (player-1)
    r = r > 0 ? r : r+4
    r = relativeP > 4 ? r+4 : r

    return r
end

function printAllInfo()
    checksum()
    println("====AllInfo======Hands")
    for (i,ah) in enumerate(all_hands)
        print(i,": ");ts_s(ah)
    end
    println("==========Discards")
    for (i,ah) in enumerate(all_discards)
        print(i,": ");ts_s(ah)
    end
    println("===========Assets")
    for (i,ah) in enumerate(all_assets)
        print(i,": ");ts_s(ah)
    end
    println("gameDeck")
    println(gameDeck)
    println()
end


function printAllInfoToFile(WF)
    for (i,ah) in enumerate(all_hands)
        println(WF,i,": ",ts(ah))
    end
    for (i,ah) in enumerate(all_discards)
        println(WF,i,": ",ts(ah))
    end
    for (i,ah) in enumerate(all_assets)
        println(WF,i,": ",ts(ah))
    end
    println(WF,gameDeck)
end
chksum(s,v) = s &0x8000_0000_0000_0000 == 0 ? xor(s,v) << 1 : xor((xor(s,v) << 1),0x1)
function checksum()
    local checksum::UInt64
    local a::UInt64
    checksum = 0
    for (i,ah) in enumerate(all_hands)
        for a in ah
           checksum = chksum(checksum,a)
        end
    end
    for (i,ah) in enumerate(all_discards)
        for a in ah
            checksum = chksum(checksum,a)
        end
    end
    for (i,ah) in enumerate(all_assets)
        for a in ah
            checksum = chksum(checksum,a)
        end
    end
    println("checksum = 0x",string(checksum,base=16))
    return checksum
end

function c_points(p,s)
    points = 0
    if length(p[1]) == 4
        points = 4
    elseif length(p[1]) == 3
        points = 2
        if length(s) > 0
            points = 3
        end
    elseif length(p[1]) == 2
        if length(s) == 2
            points = 2
        end
    elseif length(s) > 2
        points = length(s) - 2
    end
    return points
end


function getData_all_discard_assets()
    global all_discards,all_assets,gameDeckArray

    all_discards = []
    all_assets = []
    adjustPlayer = myPlayer
    gameDeckArray = TuSacCards.toValueArray(gameDeck)

    if adjustPlayer == 1

    push!(
        all_discards,
        TuSacCards.toValueArray(playerA_discards),
        TuSacCards.toValueArray(playerB_discards),
        TuSacCards.toValueArray(playerC_discards),
        TuSacCards.toValueArray(playerD_discards),
    )
    push!(
        all_assets,
        TuSacCards.toValueArray(playerA_assets),
        TuSacCards.toValueArray(playerB_assets),
        TuSacCards.toValueArray(playerC_assets),
        TuSacCards.toValueArray(playerD_assets),
    )
    elseif adjustPlayer == 4
        push!(
            all_discards,
            TuSacCards.toValueArray(playerB_discards),
            TuSacCards.toValueArray(playerC_discards),
            TuSacCards.toValueArray(playerD_discards),
            TuSacCards.toValueArray(playerA_discards),
        )

        push!(
            all_assets,
            TuSacCards.toValueArray(playerB_assets),
            TuSacCards.toValueArray(playerC_assets),
            TuSacCards.toValueArray(playerD_assets),
            TuSacCards.toValueArray(playerA_assets),
        )
    elseif adjustPlayer == 3
        push!(
            all_discards,
            TuSacCards.toValueArray(playerC_discards),
            TuSacCards.toValueArray(playerD_discards),
            TuSacCards.toValueArray(playerA_discards),
            TuSacCards.toValueArray(playerB_discards),
        )

        push!(
            all_assets,
            TuSacCards.toValueArray(playerC_assets),
            TuSacCards.toValueArray(playerD_assets),
            TuSacCards.toValueArray(playerA_assets),
            TuSacCards.toValueArray(playerB_assets),
        )
    elseif adjustPlayer == 2
        push!(
            all_discards,
            TuSacCards.toValueArray(playerD_discards),
            TuSacCards.toValueArray(playerA_discards),
            TuSacCards.toValueArray(playerB_discards),
            TuSacCards.toValueArray(playerC_discards),
        )

        push!(
            all_assets,
            TuSacCards.toValueArray(playerD_assets),
            TuSacCards.toValueArray(playerA_assets),
            TuSacCards.toValueArray(playerB_assets),
            TuSacCards.toValueArray(playerC_assets),
        )

    end
end
function getData_all_hands()
    adjustPlayer = myPlayer
    if length(all_hands) > 0
        pop!(all_hands)
        pop!(all_hands)
        pop!(all_hands)
        pop!(all_hands)
    end
    if adjustPlayer == 1
        push!(
            all_hands,
            TuSacCards.toValueArray(playerA_hand),
            TuSacCards.toValueArray(playerB_hand),
            TuSacCards.toValueArray(playerC_hand),
            TuSacCards.toValueArray(playerD_hand),
        )

    elseif adjustPlayer == 4
        push!(
            all_hands,
            TuSacCards.toValueArray(playerB_hand),
            TuSacCards.toValueArray(playerC_hand),
            TuSacCards.toValueArray(playerD_hand),
            TuSacCards.toValueArray(playerA_hand),
        )

    elseif adjustPlayer == 3
        push!(
            all_hands,
            TuSacCards.toValueArray(playerC_hand),
            TuSacCards.toValueArray(playerD_hand),
            TuSacCards.toValueArray(playerA_hand),
            TuSacCards.toValueArray(playerB_hand),
        )

    elseif adjustPlayer == 2
        push!(
            all_hands,
            TuSacCards.toValueArray(playerD_hand),
            TuSacCards.toValueArray(playerA_hand),
            TuSacCards.toValueArray(playerB_hand),
            TuSacCards.toValueArray(playerC_hand),
        )

    end
end

function tusacDeal(winner)
    global playerA_hand,playerB_hand,playerC_hand,playerD_hand,moveArray
    global playerA_discards,playerB_discards,playerC_discards,playerD_discards
    global playerA_assets,playerB_assets,playerC_assets,playerD_assets,gameDeck
    global RFstates,glPrevPlayer,glNeedaPlayCard,RFaline,tstMoveArray

    P0_hand = TuSacCards.Deck(pop!(gameDeck, 6))
    P1_hand = TuSacCards.Deck(pop!(gameDeck, 5))
    P2_hand = TuSacCards.Deck(pop!(gameDeck, 5))
    P3_hand = TuSacCards.Deck(pop!(gameDeck, 5))
    for i = 2:4
        push!(P0_hand, pop!(gameDeck, 5))
        push!(P1_hand, pop!(gameDeck, 5))
        push!(P2_hand, pop!(gameDeck, 5))
        push!(P3_hand, pop!(gameDeck, 5))
    end
    rPlayer = 5 + myPlayer - winner
    playerSel = rPlayer > 4 ? rPlayer - 4 : rPlayer
   
    if playerSel == 1
        playerA_hand = P0_hand
        playerB_hand = P1_hand
        playerC_hand = P2_hand
        playerD_hand = P3_hand
    elseif playerSel == 2
        playerA_hand = P1_hand
        playerB_hand = P2_hand
        playerC_hand = P3_hand
        playerD_hand = P0_hand
    elseif playerSel == 3
        playerA_hand = P2_hand
        playerB_hand = P3_hand
        playerC_hand = P0_hand
        playerD_hand = P1_hand
    else
        playerA_hand = P3_hand
        playerB_hand = P0_hand
        playerC_hand = P1_hand
        playerD_hand = P2_hand
    end
    FaceDown = wantFaceDown
    global playerA_discards = TuSacCards.Deck(pop!(gameDeck, 1))
    global playerB_discards = TuSacCards.Deck(pop!(gameDeck, 1))
    global playerC_discards = TuSacCards.Deck(pop!(gameDeck, 1))
    global playerD_discards = TuSacCards.Deck(pop!(gameDeck, 1))

    global playerA_assets = TuSacCards.Deck(pop!(gameDeck, 1))
    global playerB_assets = TuSacCards.Deck(pop!(gameDeck, 1))
    global playerC_assets = TuSacCards.Deck(pop!(gameDeck, 1))
    global playerD_assets = TuSacCards.Deck(pop!(gameDeck, 1))

    push!(gameDeck,pop!(playerD_assets,1))
    push!(gameDeck,pop!(playerC_assets,1))
    push!(gameDeck,pop!(playerB_assets,1))
    push!(gameDeck,pop!(playerA_assets,1))

    push!(gameDeck,pop!(playerD_discards,1))
    push!(gameDeck,pop!(playerC_discards,1))
    push!(gameDeck,pop!(playerB_discards,1))
    push!(gameDeck,pop!(playerA_discards,1))
    FaceDown = wantFaceDown
end

function readRDtable(RF,gameDeck)
    P0_hand = TuSacCards.Deck(TuSacCards.removeCards!(gameDeck,readline(RF)))
    P1_hand = TuSacCards.Deck(TuSacCards.removeCards!(gameDeck,readline(RF)))
    P2_hand = TuSacCards.Deck(TuSacCards.removeCards!(gameDeck,readline(RF)))
    P3_hand = TuSacCards.Deck(TuSacCards.removeCards!(gameDeck,readline(RF)))
    TuSacCards.ssort(P0_hand)
    TuSacCards.ssort(P1_hand)
    TuSacCards.ssort(P2_hand)
    TuSacCards.ssort(P3_hand)
    P0_assets = TuSacCards.Deck(TuSacCards.removeCards!(gameDeck,readline(RF)))
    P1_assets = TuSacCards.Deck(TuSacCards.removeCards!(gameDeck,readline(RF)))
    P2_assets = TuSacCards.Deck(TuSacCards.removeCards!(gameDeck,readline(RF)))
    P3_assets = TuSacCards.Deck(TuSacCards.removeCards!(gameDeck,readline(RF)))

    P0_discards = TuSacCards.Deck(TuSacCards.removeCards!(gameDeck,readline(RF)))
    P1_discards = TuSacCards.Deck(TuSacCards.removeCards!(gameDeck,readline(RF)))
    P2_discards = TuSacCards.Deck(TuSacCards.removeCards!(gameDeck,readline(RF)))
    P3_discards = TuSacCards.Deck(TuSacCards.removeCards!(gameDeck,readline(RF)))
end

function readRFCoins(RF)
    RFaline = readline(RF)
    RFp = split(RFaline,", ")
    for i in 3:length(RFp)
        push!(a,parse(Int,RFp[i]))
    end
    coinsArr[1] = [a[1],a[2]]
    coinsArr[2] = [a[3],a[4]]
    coinsArr[3] = [a[5],a[6]]
    coinsArr[4] = [a[7],a[8]]
    return coinsArr
end

function writeHF(HF,hands,discards,assets,deck)
    for a in hands
        println(HF,a)
    end
    for a in discards
        println(HF,a)
    end
    for a in assets
        println(HF,a)
    end
    println(HF,deck)
end
const error = 1
const good = 0
atPlayer = 1
playaCard = true
prevWinner = 1

function processClientCmd(line,HF,player)
    global mvArray, atPlayer, playaCard, playersReply
    l1 = line[1]
    achar = line[2]

    if l1== 'C'
        if achar == 'T'
            TuSacManager.printTable(HF)
        elseif achar == 'C'
            print(HF,"C, 1")
            for p in 1:4
                for c in coinsArr[p]
                    print(HF,", ",c)
                end
            end
            println(HF)
        end
    elseif l1 == 'R' 
        println("getting reply from player",player," ",line)
        playersReply[player] = line
    else
        return error
    end
    return good
end

nextPlayer(p) = p == 4 ? 1 : p + 1
prevPlayer(p) = p == 1 ? 4 : p - 1
saveStr = ""
writeCnt = [0,0,0,0]

function checkWrite(i,str)
    global writeData,writeCnt
    saveStr = ""
    while writeData[i] != "" || writeCnt[i] > 0
        astr = string("Wait for WritData $i to be empty, WriteData= ",writeData[i]," ready =",
        TuSacManager.gameReady," writeCnt=",writeCnt[i])
        filterprintln(i,astr,saveStr)
    end
   okToPrint(0x80) && println("APL: send $i \"$str\"")
    writeData[i] = str
    writeCnt[i] += 1
end

killPlayer = [false,false,false,false]
saveStrCnt = [0,0,0,0]
saveStrC = "|/-\\"
function filterprintln(player,str,saveStr)
    global saveStr,saveStrCnt
    if str != saveStr 
        saveStrCnt[player] = 0
        saveStr = str
        println(str)
    else
        if saveStrCnt[player] > 3*60
            killPlayer[player] = true
            saveStrCnt[player] = 0
        end
        saveStrCnt[player] += 1
        i = (saveStrCnt[player] % 4)+1
        print('\b')
        print(saveStrC[i])
        sleep(1)
    end
    return str
end


function sendToSocket(player,astr)
    global writeData,writeCnt   
    checkWrite(player,astr)
end

function sendToSocket(player,activePlayer,playaCard,activeCard, aiCMD,wsCMD)
    global writeData,writeCnt
    astr = string(playaCard,",",activePlayer,",",ts(activeCard),",",wsCMD,",",ts(aiCMD),",")
    checkWrite(player,astr)
end

function waitForSocket(player)
    global writeData, readData,writeCnt,vHand
    while(length(readData[player]) == 0)
        okToPrint(0x80) && filterprintln(player,"waiting for read data $player",saveStr)
    end
    if readData[player] == "+" || readData[player] == "="
        okToPrint(0x80) && println("APL: $player read \"+\"")
        readData[player] = ""
        writeCnt[player] -= 1
    else
        okToPrint(0x80) && println("$player ERROR in getting ack, getting ",readData[player])
        exit()
    end
    return 
end

function strToCards(hand, astr) 
    fs = split(astr," ")
    ignore = []
    for f in fs
        if f != ""
            fv = TuSacCards.cardStrToVal(f,hand,ignore)
            push!(ignore,fv)
        end
    end
    return ignore
end
function waitForSocket(player,aiCMD,wsCMD)
    global writeData, readData,writeCnt, vHand
    
    while(length(readData[player]) == 0)
        okToPrint(0x80) && filterprintln(player,"waiting for read data $player",saveStr)
    end
    line = readData[player]
    readData[player] = ""
    writeCnt[player] -= 1

    okToPrint(0x80) && println("APL: $player read $line")
    if line == "="
        line = string(ts(aiCMD))
    end
    if line == "." 
        cards = []
    else
        cards = strToCards(TuSacManager.vPlayerHand[player],line)
    end
    
    return cards
end

function serverSetup(serverIP,port)
     println("Server-setup ",(serverIP,port))
    nw = 0
    try
        nw = listen(serverIP,port)
        return nw
    catch
        @warn "Port is busy"
    end
end
    

function acceptClient(s)
    return(accept(s))
end
server = serverSetup(serverIP,serverPort)

const PTsocket = 1
const PTai = 0
playersType = [PTai,PTai,PTai,PTai]
playersTypeLive = [PTai,PTai,PTai,PTai]
playersTypeDelay = [PTai,PTai,PTai,PTai]
playersInGame = [PTai,PTai,PTai,PTai]
playersPayout = [[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]
i = 0

gameDeck = TuSacCards.ordered_deck()
all_hands = []
all_discards = []
all_assets = []
gameDeckArray =[]
socketCMD = ["","","",""]
playersReply = ["","","",""]

prevWinner = 1
gameOn = true    

wsPlay1Card = "P"
wsMatch1or2Card = "M"
wsMatch2Card = "M"
wsWhoWin = 4
wsCardUpdate = 5
gameOver = false
writeData = ["","","",""]
readData = ["","","",""]
promptData = ""
loopCnt = [0,0,0,0]
promptCnt = 0
name = ["","","",""]
tusacDeal(prevWinner)
global playersSocket = Vector{Any}(undef,4)
promptData = ""

if isfile("tsGUI.jl")
    rf = open("tsGUI.jl","r")
    myversion = readline(rf)
    close(rf)
else
    myverstion = "version = \"0.000\""
end

function checkNupdate(id,myversion,nw)
    rmversion = readline(nw)
    println((rmversion,myversion))
    if length(rmversion) > 10 && rmversion[1:10] == "version = " 
        println("rm,my=",(rmversion,myversion))
        if rmversion < myversion
            println(nw,myversion)
            rf = open("tsGUI.jl","r")
            while !eof(rf)
                aline = readline(rf)
                println(nw,aline)
            end
            println(nw,"#=Binh-end=#")
            close(rf)
        end
        println("Completed updated player ",id)
        close(nw)
        return ""
    else
        return rmversion
    end
end

function prompt()
    global promptData,promptCnt,savePT,gameOver
    if (playersType == [0,0,0,0] && promptData == "C") || 
        ( gameOver &&  promptData == "G")
        promptData = ""
    end
    savePT = playersType 
    if promptData != "A" && promptData != "P" && promptData != "C" && promptData != "G"
        flush(stdout)
        print("Hit ENTER to continue, \"A/P/C/G\" for auto-skip :")
        promptData = readline()
        promptCnt = 0
    else
        promptCnt += 1
        if promptCnt > 10 && promptData == "A"
            promptData = ""
        end
    end
end

timeout = 10
pots = [0,0,0,0]
tempP = [0,0,0,0]

function doMain()
    while true
        global gameOver,pHand,pAsset,pDiscard,pGameDeck,vHand,vAsset,vDiscard,vGameDeck,socketCMD,
        atPlayer, playaCard, prevWinner, playersType, playersTypeLive, playersInGame
        gameReady = false
        TuSacManager.init()
        TuSacManager.doShuffle(10)
        TuSacManager.dealCards(prevWinner)
        all = TuSacManager.getTable()
        pHand,pAsset,pDiscard,pGameDeck,vHand,vAsset,vDiscard,vGameDeck = all

        global playerA_hand = pHand[1]
        global playerB_hand = pHand[2]
        global playerC_hand = pHand[3]
        global playerD_hand = pHand[4]
        global gameDeck = pGameDeck
        getData_all_hands()
        getData_all_discard_assets()
        TuSacManager.initialScan(all_hands)
        for i in 1:4
            p,s,p3 =TuSacManager.illegalScan(i)
            println("$i PAIRS,SUITS,Pair3-------------------")
            e = p
            println(ts(e))
            e = s
            println(ts(e))
            e = p3
            println(ts(e))
        end
        printAllInfo()
        TuSacManager.setReady()

        atPlayer = prevWinner
        playaCard = true
        gameOver = false
        nPlayer = [0,0,0,0]
        prompt()
        playersInGame = deepcopy(playersType)

        while !gameOver
            global gameOver, playersReply
            if playersType == [0,0,0,0]
                sleep(5)
            end
            playersType = deepcopy(playersTypeLive)
            pcards = []
            cmd = []
            println("ActivePlayer = ",atPlayer)
            TuSacManager.reset_mvArray()
            playersReply = ["","","",""]
            rcCard = playaCard ? TuSacManager.play1Card(atPlayer) : TuSacManager.getDeckCard()
            if playaCard && playersType[atPlayer] == PTsocket
                okToPrint(0x80) && println("SENDTOSOCK",(atPlayer,playaCard,ts(rcCard)))

                sendToSocket(atPlayer, mappingPlayer(atPlayer,atPlayer), playaCard, rcCard, rcCard, wsPlay1Card)
                Cards = waitForSocket(atPlayer, rcCard, wsPlay1Card)
                rcCard = Cards[1]
            end
            activeCard = rcCard
            nPlayer[1] = atPlayer
            for i in 2:4
                nPlayer[i] = nextPlayer(nPlayer[i-1])
            end
            okToPrint(0x4) && println("players=",(nPlayer),(playersType))
            push!(pcards,playaCard ? activeCard : TuSacManager.Match1or2Card(activeCard,nPlayer[1]))
            push!(cmd,"M")
            push!(pcards,TuSacManager.Match1or2Card(activeCard,nPlayer[2]))
            push!(cmd,"M")

            for i in 3:4
               push!(pcards, TuSacManager.Match2Card(activeCard,nPlayer[i]))
               push!(cmd,"m")
            end
            beginI = playaCard ? 2 : 1
            for i in beginI:4
                p = nPlayer[i]
                if playersType[p] == PTsocket 
                    okToPrint(0x80) && println("SENDTOSOCK",(atPlayer,playaCard,ts(activeCard),pcards[i],cmd[i]))
                    sendToSocket(p,mappingPlayer(p,atPlayer),playaCard,activeCard,pcards[i], cmd[i])
                end
            end
            for i in beginI:4
                p = nPlayer[i]
                if playersType[p] == PTsocket 
                    pcards[i] = waitForSocket(p,pcards[i], cmd[i])
                end
            end
            gWinner,nWin,nr = TuSacManager.whoWinRnd(activeCard,playaCard,nPlayer[1],pcards)

            if playaCard 
                TuSacManager.removeCards!(false,nPlayer[1] ,activeCard)
            else
                TuSacManager.removeCards!(true,0,0)
            end
              
            noWin =  (nWin == 0) && (length(nr) == 0)
            if noWin # nobody win
                TuSacManager.addCards!(true,nPlayer[1],activeCard)
                atPlayer = nPlayer[2]
                playaCard = false
            else
                TuSacManager.removeCards!(false,gWinner,nr)
                TuSacManager.addCards!(false,gWinner,activeCard)
                TuSacManager.addCards!(false,gWinner,nr)
                TuSacManager.pointsUpdate(gWinner,nr,activeCard)
              
                atPlayer = gWinner
                playaCard = true
            end
            if TuSacManager.coDoiPlayer > 0 && ((TuSacManager.coDoiPlayer != gWinner ) || noWin)
                okToPrint(0x80) && print("Bo-doi! ",(gWinner,TuSacManager.coDoiPlayer))
                okToPrint(0x80) && println(ts(TuSacManager.coDoiCards))
                TuSacManager.removeCards!(false,TuSacManager.coDoiPlayer,TuSacManager.coDoiCards)
                TuSacManager.addCards!(false,TuSacManager.coDoiPlayer,TuSacManager.coDoiCards)
            end
            gameOver = nWin == 0xFE
          
            if gameOver 
                prevWinner = gWinner
                TuSacManager.pointsCalc(gWinner)
                for n in 1:4
                    pots[n] += TuSacManager.kpoints[n]
                end
                println("Points =", TuSacManager.kpoints[gWinner], " Pots=",pots[gWinner])
                global tempP = TuSacManager.kpoints
                global sendName = [true,true,true,true]
                for i in 1:4
                    if (gWinner != i) && (playersInGame[i] == PTsocket) && (playersInGame[gWinner] == PTsocket)
                        playersPayout[gWinner][i] += TuSacManager.kpoints[gWinner] 
                    end
                end
                for i in 1:4
                    if i != gWinner
                        for j in 1:4
                            if (j != i) && (playersInGame[i] == PTsocket) && (playersInGame[j] == PTsocket)
                                playersPayout[i][j] += TuSacManager.kpoints[i]
                            end
                        end
                    end
                end
            end
            if TuSacManager.baiThui()
                gameOver = true
                gWinner = 5
                TuSacManager.pointsCalc(gWinner)
            end
  
            if gameOver
                TuSacManager.resetReady()
            end
            okToPrint(0x80) && println(TuSacManager.string_TArray(gameOver,1,gWinner))
            for i in 1:4
                if playersType[i] == PTsocket
                    astr = TuSacManager.string_TArray(gameOver,i,gWinner)
                    sendToSocket(i,astr)
                end
                if playersTypeDelay[i] > PTai
                    playersTypeDelay[i] -= 1
                end
            end
            for i in 1:4
                (playersType[i] == PTsocket) && waitForSocket(i)
            end
            println(playersType,playersTypeLive,pots," TimeOut:",timeout)
            TuSacManager.printTable()

            prompt()

        end
    end
end
timeOutArray = [36*60*60,5*60,5*60,5*60]
sendName = [false,false,false,false]
playerName = ["Robo","Robo","Robo","Robo"]

function doNW()
    while true
        global i
        global readyToRead,writeData,readData,playersType,playersTypeLive,
        playersTypeDelay,playerName,sendName
        i = 0
        sum = playersType[1] + playersType[2] + playersType[3] + playersType[4] 
     
        for j in 1:4
            if playersTypeLive[j] + playersTypeDelay[j] == PTai
                i = j
                break
            end
        end
        global timeout = sum > 0 ? timeOutArray[sum] : 20

        if i != 0
            conn = accept(server)
            okToPrint(0x80) && println("Accepted: ",i," writeData=",writeData[i]," readData=",readData[i], " writeCnt=",writeCnt[i])
            playerName[i] = checkNupdate(i,myversion,conn)   
            if playerName[i] == ""
                println(" just update remote ... restarting connection ")
                continue
            end
            println(conn,i)
            global playerRootName[i] = playerName[i]

            sendName = [true,true,true,true]
            clientId = i
            readData[i] = ""
            writeData[i] = " "

            playersSocket[i] = conn
            playersTypeLive[i] = PTsocket
            playersPayout[i] = [0,0,0,0]
            pots[i] = 0
            kpoints[i] = 0
            loopCnt[i] = 0
            writeCnt[i] = 1
            while playersType[i] != PTsocket
                sleep(.4)
            end
            @spawn networkLoop(clientId,conn)
        else
            sleep(3)
        end
        
    end
end

function cleanup(myID)
    global readData[myID] = "="
    global writeData[myID] = ""
    global playerName[myID] = string("Robo ")
    global sendName = [true,true,true,true]
    global playersTypeLive[myID] = PTai
    global playersTypeDelay[myID] = PTsocket + PTsocket
    global playersType[myID] = PTai
    global promptData = promptData == "C" ? promptData = "" : promptData
    println("Player $myID disconnected")
    return
end
function networkLoop(myId,myConn)
    saveStr = ""
    saveStr1 = ["","","",""]
    while true
    
        global loopCnt
        gameOver = false
        writeData[myId] = " "
        while TuSacManager.gameReady == false
            sleep(.5)
        end
        try
            TuSacManager.printTable(myConn,myId)
            TuSacManager.printCoins(myConn,myId)
        catch
            return
        end
        writeData[myId] = ""
        writeCnt[myId] = 0
        while !gameOver
            global writeData, readData, readyToRead, playersTypeLive,playersType,
                loopCnt,sendName,playerName,timeout
        
            while length(writeData[myId]) == 0 
                sleep(1)
            end
            condi =  (writeData[myId][1] == 't' || writeData[myId][1] == 'f')
            if sendName[myId] == true && condi
                pName = ["","","",""]
                for i in 1:4
                    payout = playersPayout[myId][i] - playersPayout[i][myId]
                    pName[i] = string(playerName[i],i," A",aiTrait[i]," P",pots[i],"+",tempP[i]," \$",payout)
                end
                astr = ""
                for i in myId:4
                    astr = string(astr,pName[i],",")
                end
                if myId > 1
                    for i in 1:myId-1
                        astr = string(astr,pName[i],",")
                    end
                end
                println("Name,",astr)
                println(myConn,"Name,",astr)
                sendName[myId] = false
                line = readline(myConn)
                if line != "AckName"
                    cleanup(myId)
                    return
                end
            end
            ftimeout = condi ? timeout : 60

            line = writeData[myId]
            writeData[myId] = ""
            gameOver = line[1] == 'g'
            t = Timer(_ -> close(myConn), ftimeout)

            try
                println(myConn,line)
            catch 
                cleanup(myId)
                return
            finally
                close(t)
            end
            okToPrint(0x80) && println("NWL: send to $myId ",line)
            t = Timer(_ -> close(myConn), ftimeout)

            try
                line =  readline(myConn)
                okToPrint(0x80) && println("NWL: receive $myId\"$line\" ")

                if line == ""
                    cleanup(myId)
                    return
                else
                    !gameOver && (readData[myId] = line)
                end

            catch e
                cleanup(myId)
                return
            finally
                close(t)
            end
        end
        line = readline(myConn)
        okToPrint(0x80) && println(myId," ",line)
        readData[myId] = "+"
    end
end
@spawn doMain()

 doNW()








