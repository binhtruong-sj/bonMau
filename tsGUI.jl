version = "0.62u"
using GameZero
using Sockets
using Random: randperm
using Printf

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
boDoiFlag = (aiTrait .& 0x1 ) .!= 0
mydefensiveFlag = defensiveFlag .&& ((aiTrait .& 0x2) .!= 0)
println(boDoiFlag,mydefensiveFlag)
#aiType = [3,3,3,3]
GUIname = Vector{Any}(undef,4)
boDoiPic = Vector{Any}(undef,4)
numberOfSocketPlayer = 0
playerRootName = ["Bbot","Bbot","Bbot","Bbot"]
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
serverSetup = false
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

module nwAPI
    using Sockets
    export nw_sendToMaster, nw_sendTextToMaster,nw_receiveFromMaster,nw_receiveFromPlayer,nw_receiveTextFromPlayer,
    nw_sentToPlayer, nw_getR, serverSetup, clientSetup, allwPrint
    allowPrint = 0
    okToPrint(a) = allowPrint&a != 0

    function serverSetup(serverIP,port)
    # return(listen(ip"192.168.0.53",11029))
        return(listen(serverIP,port))
    end

    function acceptClient(s)
        return(accept(s))
    end

    function clientSetup(serverURL,port)
        try
            ac = connect(serverURL,port)
            return ac
        catch
            @warn "Server is not available"
            return 0
        end
    end
    function allwPrint(a)
        allowPrint & a
    end
    function nw_sendToMaster(id,connection,arr)

    l = length(arr)
    if okToPrint(0x1)
        println(id,"  nwAPI Send to Master DATA=",(arr,l))
    end
        if l != 112
            s_arr = Vector{UInt8}(undef,8)

            s_arr[1] = l
            for (i,a) in enumerate(arr)
                s_arr[i+1] = a
            end
            if okToPrint(0x1)
            println("Data = ",s_arr)
            end
        else
            s_arr = Vector{UInt8}(undef,l)

            for (i,a) in enumerate(arr)
                s_arr[i] = a
            end
        end
        write(connection,s_arr)
    end

    function nw_sendTextToMaster(id,connection,txt)
        println(connection,txt)
    end

    function nw_receiveTextFromMaster(connection)
        return readline(connection)
    end


    function nw_receiveFromMaster(connection,bytecnt)
        if okToPrint(0x1)
            println(" nwAPI receive from Master")
        end
        arr = []
    while true
            arr = read(connection,bytecnt)
            if length(arr) != bytecnt
                println(length(arr),"!=",bytecnt)
                    exit()
            else
                break
            end
        end
        if okToPrint(0x1)
        println("nwAPI received ",arr," from master ")
        end
        return(arr)
    end

    function nw_receiveFromPlayer(id,connection,bytecnt)
        global msgPic
        arr = []
        if okToPrint(0x1)
        println(" nwAPI received from Player ", id )
        end

        while true
            arr = read(connection,bytecnt)
            if length(arr) != bytecnt
                println(length(arr),"!=",bytecnt)
                exit()
            else
                break
            end
        end
        if okToPrint(0x1)
        println("nwAPImaster received ",arr)
        end
    return(arr)
    end

    function nw_receiveTextFromPlayer(id,connection)
        return readline(connection)
    end

    function nw_sendTextToPlayer(id, connection, txt)
        if okToPrint(0x1)
        println("Sendint text=",txt," to ",id)
        end
        println(connection,txt)
    end

    function nw_sendToPlayer(id, connection, arr)
        l = length(arr)
        if okToPrint(0x1)
        println("nwAPISend to Player ",id,"  DATA=",(arr,l))
        end

        if l != 112
            s_arr = Vector{UInt8}(undef,8)
            s_arr[1] = l
            for (i,a) in enumerate(arr)
                s_arr[i+1] = a
            end
            if okToPrint(0x1)
            println("Data = ",s_arr)
            end
        else

            s_arr = Vector{UInt8}(undef,l)
            for (i,a) in enumerate(arr)
                s_arr[i] = a
            end
        end

        write(connection,s_arr)
    end
    function nw_getR(nw)
        n = []
        for i in 1:nw[1]
            push!(n,nw[i+1])
        end
        return n
    end
end

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
        for i = 1:lastindex(str)
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

    function findCard(hand,s)
        grank = "Tstcxpm"
        gcolor = "TVDX"
        tohand = []
        aStrToVal(s) = (UInt8(find1(s[1], grank)) << 2) | (UInt8(find1(s[2], gcolor) - 1) << 5)
    
        v = aStrToVal(s)
        for (i,c) in enumerate(hand)
            if card_equal(c, v)
               return c
            end
        end
        @assert true
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

    """
    autoShuffle:
        gradienDir - (20 or 40) +/- 4

        - is up/left
        + is down/right
    """
    function humanShuffle!(deck::Deck, ySize, gradienDir)
        """
            deckCut(dir, a)
            direction: 1,0 ->  hor+right
                    0,1 -> ver+down
                        30+/- or 40+/-
        """
        function deckCut(dir, a)
            cardGrid = 4
            r, c = size(a)
            for dr in dir
                if dr < 2
                    rangeH = dr == 0 ? r : c
                    rangeL = 1
                    dr = dr + 29
                else
                    if dr > 30
                        g = abs(dr - 40)
                        Grid = div(r, cardGrid)
                    else
                        g = abs(dr - 20)
                        Grid = div(c, cardGrid)
                    end
                    rangeL, rangeH = g * Grid + 1, (g + 1) * Grid
                end
                crl, crh = lowhi(rand(rangeL:rangeH), rand(rangeL:rangeH))
                if dr < 30
                    #Horizontally
                    cl, ch = crl, crh
                    rr = rand(2:r)
                    for col = cl:ch
                        save = a[:, col]
                        for n = 1:r
                            rr = nextWrap(rr, 1, r)
                            a[n, col] = save[rr]
                        end
                        #rr = nextWrap(rr,1,r)
                    end
                else
                    #rl,rh set the BACKGROUND
                    rl, rh = crl, crh
                    #rc set starting point to rotate
                    rc = rand(2:c)
                    for row = rl:rh
                        save = a[row, :]
                        for n = 1:c
                            rc = nextWrap(rc, 1, c)
                            a[row, n] = save[rc]
                        end
                        #rc = nextWrap(rc,1,c)
                    end
                end
            end
        end
        ###-------------------------------------------

        a = collect(1:112)
        b = reshape(a, ySize, :)

        deckCut(gradienDir, b)
        a = reshape(b, :, 1)
        deck.cards .= deck.cards[a]
        r = rand(1:100)
        if r < 10
            deck = rcut(deck)
        end
        deck
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
    play1Card,setNoRandom,setAITRAIT, setManagerMode, RemoveCards!, 
    AddCards!,printTable,getTable,updateDeadCard,readRFtable

    const gpCheckMatch2 = 2
    const gpCheckMatch1or2 = 1
    const plBot1 = 0
    const plSocket = 1
    currentAction = 0

    mvArray = []
    managerModeAsMaster = false 
    aiType = [4,4,4,4]
    all_assets_marks = zeros(UInt8,128)
    boDoiPlayers = zeros(UInt8,4)
    PlayedCardCnt = zeros(UInt8,32)
    activePlayer = 1
    allowPrint = 0
    okToPrint(a) = allowPrint&a != 0
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
    mydefensiveFlag = defensiveFlag .&& ((aiTrait .& 0x2) .!= 0)

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
        global mydefensiveFlag = defensiveFlag .&& ((aiTrait .& 0x2) .!= 0)

    end
    function setNoRandom(r)
        noRandom = r
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
        global all_assets_marks = zeros(UInt8,128)
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
    
        global playerSuitsCnt = zeros(UInt8,4)
        global PlayedCardCnt = zeros(UInt8,32)
    
        global drawCnt = 1
        global gsHcnt = 1
    
        global deadCards = [[],[],[],[]]
        global prevDeck = false
        global prevCard = 0x00
        global prevN1 = 0
        global probableCards = [[],[],[],[]]
        global noSingle = [false,false,false,false]
        global all_assets_marks = zeros(UInt8,128)
        global matchSingle = zeros(UInt8,4)
        global Tuong = zeros(UInt8,4)
        global notDoneInit = true
        nDead=[[],[],[],[]]
        highValue = zeros(UInt8,4)
        needAcard = false

        global mGameDeck = TuSacCards.ordered_deck()
    end


    function readRFCoins(RF)
        global coinsArr
        RFaline = readline(RF)
        println("Coins: ",RFaline)
        RFp = split(RFaline,",")
        a = []
        for i in 2:lastindex(RFp)
            push!(a,parse(Int,RFp[i]))
        end
        coinsArr[1] = [a[1],a[2]]
        coinsArr[2] = [a[3],a[4]]
        coinsArr[3] = [a[5],a[6]]
        coinsArr[4] = [a[7],a[8]]
        return coinsArr
    end
    
    function _ts(a)
            TuSacCards.Card(a[1])
    end

    function ts(a)
        st = ""
        if length(a) == 1
            st = _ts(a)
        else
            if length(a) > 1
                for b in a
                    st = string(st,_ts(b)," ")
                end
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


    function readServerTable(RF)
        global mGameDeck,playerHand,playerAsset,playerDiscard
        playerHand  = []
        playerAsset = []
        playerDiscard  = []

        push!(playerHand,TuSacCards.Deck(TuSacCards.removeCards!(mGameDeck,readline(RF))))
        push!(playerHand,TuSacCards.Deck(TuSacCards.removeCards!(mGameDeck,readline(RF))))
        push!(playerHand,TuSacCards.Deck(TuSacCards.removeCards!(mGameDeck,readline(RF))))
        push!(playerHand,TuSacCards.Deck(TuSacCards.removeCards!(mGameDeck,readline(RF))))
        push!(playerDiscard,TuSacCards.Deck(TuSacCards.removeCards!(mGameDeck,readline(RF))))
        push!(playerDiscard,TuSacCards.Deck(TuSacCards.removeCards!(mGameDeck,readline(RF))))
        push!(playerDiscard,TuSacCards.Deck(TuSacCards.removeCards!(mGameDeck,readline(RF))))
        push!(playerDiscard,TuSacCards.Deck(TuSacCards.removeCards!(mGameDeck,readline(RF))))
        push!(playerAsset,TuSacCards.Deck(TuSacCards.removeCards!(mGameDeck,readline(RF))))
        push!(playerAsset,TuSacCards.Deck(TuSacCards.removeCards!(mGameDeck,readline(RF))))
        push!(playerAsset,TuSacCards.Deck(TuSacCards.removeCards!(mGameDeck,readline(RF))))
        push!(playerAsset,TuSacCards.Deck(TuSacCards.removeCards!(mGameDeck,readline(RF))))
        dsk = TuSacCards.Deck(TuSacCards.removeCards!(mGameDeck,readline(RF)))
        mGameDeck = dsk
        getAllPlayerCards()
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
        return allPairs, single, chot1, miss1, missT, miss1Card, chotP, chot1Special, suitCnt, miss1_1,miss1_2,cTrsh
    end

    function autoHumanShuffle(n)
        for i in 1:n
            rl = rand(17:23)
            rh = rand(37:43)
            sh = rand(0:1) > 0 ? rl : rh
            TuSacCards.humanShuffle!(mGameDeck,14,sh)
        end
    end

    function doShuffle(mode)
        if mode == 0 
            TuSacCards.shuffle!(mGameDeck)
        else
            autoHumanShuffle(mode)
        end
    end
   
    nextPlayer(p) = p == 4 ? 1 : p + 1
    prevPlayer(p) = p == 1 ? 4 : p - 1
    
    function removeCards!(deck, n, cards)
        global mvArray
        if deck
            nc = pop!(mGameDeck, 1)
            nca = pop!(vGameDeck)
            return(nc,nca)
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

    function addCards!(discard, n, cards)
        global mvArray
        for c in cards
            updateCntPlayedCard(c)
            push!(mvArray,(0,n,c))
            if !discard 
                push!(vPlayerAsset[n], c)
            else
                push!(vPlayerDiscard[n], c)
            end
            if !discard 
                push!(playerAsset[n],ts(c))
            else
                push!(playerDiscard[n],ts(c))
            end
        end
    end

    """
    moveCard!( nf,nt, c)

    nf: 0 is from Deck, 1-4 from hand.
    nt: 1-4: assets, 5-8: discards
    c: a card in alphabet (if from deck ... not used)
    """
    function moveCard!( fromIndex,toIndex,crd)
        global playerHand,vPlayerHand,
        mGameDeck,vGameDeck,
        vPlayerAsset,playerAsset,
        vPlayerDiscard,playerDiscard

        if fromIndex == 0
            c = pop!(mGameDeck, 1)
            nc = pop!(vGameDeck)
        else
            acard = TuSacCards.removeACard!(playerHand[fromIndex],crd)
            for l = 1:lastindex(vPlayerHand[fromIndex])
                if acard.value == vPlayerHand[fromIndex][l]
                    splice!(vPlayerHand[fromIndex], l)
                    break
                end
            end
            nc = acard.value
            c = crd
        end
        if toIndex < 5
            push!(vPlayerAsset[toIndex], nc)
            push!(playerAsset[toIndex],c)
        else
            push!(vPlayerDiscard[toIndex-4], nc)
            push!(playerDiscard[toIndex-4],c)
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
  
    function setupHand()
        for i in 1:4
            allPairs = scanCards(vPlayerHand[i],false)
            for pss in allPairs 
                for ps in pss
                    if length(ps) == 4
                        removeCards!(false,i,ps)
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

    """
    chk2(playCard) check for pairs -- also check for P XX ? M

    """
    function chk2(playCard;win=false)
        global coDoiCards
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
                        return []  # SAKI -- return nothing
                    else
                        if p == 1
                            if length(coDoiCards) == 0
                                if okToPrint(0x8)
                                    println("chk2-codoi-",ap)
                                end
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
        global allPairs, singles, chot1s, miss1s, missTs, miss1sbar, chotPs, chot1Specials, suitCnt, miss1_1,miss1_2,cTrsh 
        global currentAction = gpCheckMatch2 

        allPairs, singles, chot1s, miss1s, missTs, miss1sbar, chotPs, chot1Specials, suitCnt, miss1_1,miss1_2,cTrsh =
        scanCards(vPlayerHand[player],false,true)

        card1 = chk1(pcard)
        card2 = chk2(pcard)
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
        return rc
    
    end
    function Match1or2Card(pcard,player)
        global allPairs, singles, chot1s, miss1s, missTs, miss1sbar, chotPs, chot1Specials, suitCnt, miss1_1,miss1_2,cTrsh 
        global currentAction = gpCheckMatch1or2 

        allPairs, singles, chot1s, miss1s, missTs, miss1sbar, chotPs, chot1Specials, suitCnt, miss1_1,miss1_2,cTrsh =
        scanCards(vPlayerHand[player],false,true)

        card1 = chk1(pcard)
        card2 = chk2(pcard)
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
        if okToPrint(0x8)
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
        if okToPrint(0x8)
        println("Who win ?  n,w,r", (n, w, r), (l1, l2, l3, l4),(r1,r2,r3,r4))
        end
        return n, w, r
    end

    
    function whoWinRnd(pcard,play3,t1Player,n1c,n2c,n3c,n4c)
        t2Player = nextPlayer(t1Player)
        t3Player = nextPlayer(t2Player)
        t4Player = nextPlayer(t3Player)
        nPlayer, winner, r = whoWinRound(
            pcard,
            !play3,
            t1Player,
            n1c,
            t2Player,
            n2c,
            t3Player,
            n3c,
            t4Player,
            n4c,
        )
        return nPlayer, winner, r
    end
    
    function endTurn()
        nPlayer, winner, r =  whoWin!(glIterationCnt, glNewCard,glNeedaPlayCard,t1Player,t2Player,t3Player,t4Player)

    end

end # end TuSacManager

module tsIntf
using ..TuSacManager
import ..TuSacManager

export to_removeCards!, to_addCards!,
to_whoWinRnd,to_printTable, to_updateDeadCard, to_getTable, to_play1Card, to_Match2Card,
to_Match1or2Card

function to_removeCards!(arrNo, n, cards)

end

end

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
GUILoc = zeros(Int,13,3)
GUILoc[1,1],GUILoc[1,2],GUILoc[1,3] = 6,18,21
GUILoc[2,1],GUILoc[2,2],GUILoc[2,3] = 20,2,2
GUILoc[3,1],GUILoc[3,2],GUILoc[3,3] = 6,2,21
GUILoc[4,1],GUILoc[4,2],GUILoc[4,3] = 1,2,2

GUILoc[5,1],GUILoc[5,2],GUILoc[5,3] = 7,13,21
GUILoc[6,1],GUILoc[6,2],GUILoc[6,3] = 16,8,6
GUILoc[7,1],GUILoc[7,2],GUILoc[7,3] = 7,4,21
GUILoc[8,1],GUILoc[8,2],GUILoc[8,3] = 3,8,6

GUILoc[9,1], GUILoc[9,2], GUILoc[9,3] = 17,16,5
GUILoc[10,1],GUILoc[10,2],GUILoc[10,3] = 16,1,5
GUILoc[11,1],GUILoc[11,2],GUILoc[11,3] = 3,1,5
GUILoc[12,1],GUILoc[12,2],GUILoc[12,3] = 2,16,5

GUILoc[13,1],GUILoc[13,2],GUILoc[13,3] = 9,8,10
gamew = 0
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
        server baobinh.tplinkdns.com 11029
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
                nwAPI.allwPrint(allowPrint)
                TuSacCards.allwPrint(allowPrint)
                TuSacManager.allwPrint(allowPrint)
            elseif lcCmp(keyword,"GUIadjust")
                arrayIndex = parse(Int,rl[2])
                x = parse(Int,rl[3])
                y = parse(Int,rl[4])
                GUILoc[arrayIndex,1] += x
                GUILoc[arrayIndex,2] += y
            elseif lcCmp(keyword,"aiTrait")
                    aiTrait = [parse(Int,rl[2]),parse(Int,rl[3]),parse(Int,rl[4]),parse(Int,rl[5])]
                    aiType = aiTrait .>> 2
                    

                    println("AITYPE=", (aiTrait,aiType))
                    TuSacManager.setAITRAIT(aiTrait)
                    playerName = setPlayerName(playerRootName,aiTrait)
                    boDoiFlag = (aiTrait .& 0x1 ) .!= 0
                    mydefensiveFlag = defensiveFlag .&& ((aiTrait .& 0x2) .!= 0)
                
            elseif lcCmp(keyword,"serverURL")
                serverURL = string(rl[2])
            elseif lcCmp(keyword,"serverIP")
                serverIP = getaddrinfo(string(rl[2]))
                serverPort = parse(Int,rl[3])
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
            elseif lcCmp(keyword,"GUI")
                    global GUI = rl[2] == "true"
            end
        end
    end
    if fontSize == 50 && !macOS
        fontSize = 24
    end
    if GUI
        noGUI_list[myPlayer] = false
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

moveArray = zeros(Int8,16,3)

if coldStart
    eRrestart = false
end
if macOS
    adx = 28
    if okToPrint(0x1)
    println("macOS")
    end
const macOSconst = 1
    gameW = gamew == 0 ? 900 : gamew
    HEIGHT = gameW
    WIDTH = div(gameW * 16, 9)
    realHEIGHT = HEIGHT * 2
    realWIDTH = WIDTH * 2
    cardXdim = 90
    cardYdim = 295
    zoomCardYdim = 400
    GENERIC = 0
else
    adx = 8
    gameW = gamew == 0 ? 820 : gamew

    if GENERIC == 1
        cardXdim = 24
        cardYdim = 80
        zoomCardYdim = 110
    elseif GENERIC == 2
        cardXdim = 42
        cardYdim = 140
        zoomCardYdim = 210
    elseif GENERIC == 3
        cardXdim = 49
        cardYdim = 170
        zoomCardYdim = 210
    elseif GENERIC == 4
        cardXdim = 64
        cardYdim = 210
        zoomCardYdim = 295
    else
        cardXdim = 90
        cardYdim = 295
        zoomCardYdim = 400
    end
    if okToPrint(0x1)
    println("NO macOS")
    end
    const macOSconst = 0
    HEIGHT = gameW
    WIDTH = div(gameW * 16, 9)
    realHEIGHT = div(HEIGHT, 1)
    realWIDTH = div(WIDTH, 1)

end
boDoi = 0
bp1BoDoiCnt = 0
zoomCardXdim = div(zoomCardYdim*cardXdim,cardYdim)
const tableXgrid = 20
const tableYgrid = 20
global FaceDown = wantFaceDown
const cardGrid = 4
const gameDeckMinimum = 9
eRrestart = 1
const eRcheck = 2

function gameOver(n)
    global eRrestart
    global gameEnd, baiThui
    global FaceDown = false
    if n == 0
     #   gameEnd = 0
    end
    GUI && print('\u0007')
    if 0 < n < 5
        global gameStart = false
        updateWinnerPic(n)
        if histFile
            println(HF,"#, Winner = ",playerName[n])
        end
    else
        GUI && sleep(.5)
        if gameEnd == 0
            push!(gameDeck,ts(glNewCard))
        end
        baiThui = true
    end
    gameEnd = n == 5 ?  prevWinner : n

    replayHistory(0)

end
isGameOver() = gameEnd > 0


function playerIsHuman(p)
    return ((p == myPlayer) && mode_human)
end
humanIsGUI() = mode_human & !noGUI()

function RESET1()
     global baiThui,oneTime
    if coldStart
        global currentPlayer = 1
    else
        global currentPlayer = gameEnd

    end
  
    global openAllCard = false
    global coinsArr = [[0,0],[0,0],[0,0],[0,0]]


    global emBaiTrigger = [[-1,0,0],[-1,0,0],[-1,0,0],[-1,0,0]]
    global capturedCPoints = [[0,0,0,0],[0,0,0,0],[0,0,0,0],[0,0,0,0]]
    global gameTrashCnt = gameTrashCntLatest = zeros(Int8,4)
    global oneTime = true
    global gameStart = false
    global gotClick = false
    global GUI_array=[]
    global GUI_ready=true
    global FaceDown = wantFaceDown
    global HISTORY = []
    global waitForHuman = false
    global handPic
    global baiThuiPic
    global pBseat = []
    global points = zeros(Int8,4)

    global playerSuitsCnt = zeros(UInt8,4)
    global PlayedCardCnt = zeros(UInt8,32)

    global drawCnt = 1
    global gsHcnt = 1

    global deadCards = [[],[],[],[]]
    global prevDeck = false
    global prevCard = 0x00
    global prevN1 = 0
    global probableCards = [[],[],[],[]]
    global noSingle = [false,false,false,false]
    global all_hands = []
    global all_discards = []
    global all_assets = []
    global all_assets_marks = zeros(UInt8,128)
    global gameDeckArray =[]
    global matchSingle = zeros(UInt8,4)
    global Tuong = zeros(UInt8,4)

end
const gpPlay1card = 1
const gpCheckMatch1or2 = 3
const gpCheckMatch2 = 2
const gpPopCards = 4

const gsHarrayNamehands = 1
const gsHarrayNamediscards = 2
const gsHarrayNameassets = 3
const gsHarrayNamegameDeck = 4

"""
table-grid, giving x,y return grid coordinate
"""
tableGridXY(gx, gy) = (gx - 1) * div(realWIDTH, tableXgrid),
(gy - 1) * div(realHEIGHT, tableYgrid)
reverseTableGridXY(x, y) = div(x, div(realWIDTH, tableXgrid)) + 1,
div(y, div(realHEIGHT, tableYgrid)) + 1


RESET1()


"""
setupActorgameDeck:
    Set up the Full Deck of Actor to use for the whole game, linked to TuSacCards.Card by
    Card.value
"""
function setupActorgameDeck()
    if noGUI()
        return
    end
    a = []
    b = []
    big = []
    mapToActor = Vector{UInt8}(undef, 256)
    ind = 1
    sc = 0
    for s in ['w', 'y', 'r', 'g']
        for r = 1:7
            for d = 0:3
                if macOS
                    mapr = r < 4 ? r : (r == 4 ? 7 : r - 1)

                    st = string(s, "-m",mapr, ".png")
                    big_st = string(s, "-", mapr, ".png")
                    afc = Actor("fc-m.png")
                else
                    if GENERIC == 1
                        local m = r < 4 ? r : (r == 4 ? 7 : r - 1)
                        mapr = m == 5 ? 6 : m == 6 ? 5 : m
                        st = string(s, mapr, "xs.png")
                        big_st = string(s, mapr, "s.png")
                        afc = Actor("fcxs.png")
                    elseif GENERIC == 2
                        local m = r < 4 ? r : (r == 4 ? 7 : r - 1)
                        mapr = m == 5 ? 6 : m == 6 ? 5 : m
                        st = string(s, mapr, "s.png")
                        big_st = string(s, m, ".png")
                        afc = Actor("fcs.png")
                    elseif GENERIC == 3
                        local m = r < 4 ? r : (r == 4 ? 7 : r - 1)
                        mapr = m == 5 ? 6 : m == 6 ? 5 : m
                        st = string(s, mapr, "s1.png")
                        big_st = string(s, m, ".png")
                        afc = Actor("fcs1.png")
                    elseif GENERIC == 4
                        local m = r < 4 ? r : (r == 4 ? 7 : r - 1)
                        mapr = m == 5 ? 6 : m == 6 ? 5 : m
                        st = string(s, m, ".png")
                        big_st = string(s, "-m", m, ".png")
                        afc = Actor("fc.png")
                    else
                        local m = r < 4 ? r : (r == 4 ? 7 : r - 1)
                        mapr = m == 5 ? 6 : m == 6 ? 5 : m
                        st = string(s, "-m", m, ".png")
                        big_st = string(s, "-", m, ".png")
                        afc = Actor("fc.png")
                    end
                end
                act = Actor(st)
                big_act = Actor(big_st)

                act.pos = 0, 0
                deckI = (sc << 5) | (r << 2) | d
                mapToActor[deckI] = ind
                push!(a, act)
                push!(b, afc)
                push!(big, big_act)
                ind = ind + 1
            end
        end
        sc = sc + 1
    end
    return a, b, big, mapToActor
end
function RESET3()
    global actors, fc_actors, big_actors, mapToActors , mask,
    all_hands,all_discards,all_assets,gameDeckArray,ActiveCard,tsActiveCard,BIGcard
    ActiveCard,tsActiveCard,BIGcard = 0,0,0
    all_hands = []
    all_discards = []
    all_assets = []
    gameDeckArray =[]
    actors = []
    fc_actors = []
    big_actors = []
    mapToActors =[]

    mask = zeros(UInt8, 112)
    if noGUI() == false
        actors, fc_actors, big_actors, mapToActors = setupActorgameDeck()
        if okToPrint(0x1)
        println("lengths=",(length(actors),length(fc_actors), length(big_actors),
        length(mapToActors)))
        end
    end

end
RESET3()
"""
setupDrawDeck:
x,y: starting location
dims: 0: Vertical
      1: Horizontal
      2: Square

      x0,y0 x1,y1 dimensions of box
      state - set to 0
      mx0,my0,mx1,my1 are place holder for state usage
      return array, x0,y0,x1,y1,state, mx0,mx1,my0,my1
"""
function setupDrawDeck(deck, gx, gy, xDim, faceDown = false,assets = false)
    global modified_cardXdim, modified_cardYdim
    if noGUI()
        return
    end
    x, y = tableGridXY(gx, gy)

    if length(deck) == 0
        l = 20
        if xDim > 20
            xDim = l
            modified_cardYdim = cardYdim
        else
            modified_cardYdim =
                faceDown ? div( (cardYdim*33),100 ) : div( (cardYdim*45),100)
        end
        yDim = div(l, xDim)
        if (xDim * yDim ) < l
            yDim += 1
        end
        modified_cardXdim = div(cardXdim * cardScale,100)
        x1 = x + modified_cardXdim * xDim
        y1 = y + modified_cardYdim * yDim
    else
        l = length(deck)
        if xDim > 20
            xDim = l
            modified_cardXdim =
                                faceDown ? div( (cardXdim*80),100 ) :
                                cardXdim
            modified_cardXdim = div(modified_cardXdim * cardScale,100)
            modified_cardYdim = div(cardYdim * cardScale,100)
        else
            modified_cardXdim =
                                faceDown ? div( (cardXdim*80),100 ) :
                                cardXdim
            modified_cardXdim = div(modified_cardXdim * cardScale,100)

            modified_cardYdim =
                faceDown ? div( (cardYdim*33),100 ) : div( (cardYdim*45),100)
            modified_cardYdim = div(modified_cardYdim * cardScale,100)

        end
        dx = 0
        for (i,card) in enumerate(deck)
            m = mapToActors[card.value]
            px = x + (modified_cardXdim * rem(i-1, xDim))
            py = y + (modified_cardYdim * div(i-1, xDim))
            if assets
                adxt = all_assets_marks[card.value] == 2 ? adx << 1 : adx
                dx = all_assets_marks[card.value] == 1 ? 0 : dx + adxt
            end
            if  rem(i-1, xDim) == 0
                dx = 0
            end
            actors[m].pos = px-dx, py
            fc_actors[m].pos = px, py
            if (py + cardYdim * 2) > realHEIGHT
                bpy = py + cardYdim - zoomCardYdim
            else
                bpy = py
            end
            big_actors[m].pos = px-dx, bpy
            if (faceDown)
                mask[m] = mask[m] | 0x1
            else
                mask[m] = mask[m] & 0xFFFFFFFE
            end
        end
        yDim = div(l, xDim)
        if xDim * yDim < l
            yDim += 1
        end
        x1 = x + modified_cardXdim * xDim
        y1 = y + modified_cardYdim * yDim
    end
    ra_state = []
    push!(ra_state, x, y, x1, y1, 0, 0, 0, 0, 0, xDim, l)
    return ra_state
end

function getRand1and0(low, high)
    rand_shuffle = []
    for i = 1:rand((low:high))
        for j in rand((0:1))
            push!(rand_shuffle, j)
        end
    end
    return rand_shuffle
end


#ar = TuSacCards.toValueArray(dd)
#println(ar)

rs = getRand1and0(13, 26)

function organizeHand(ahand::TuSacCards.Deck)
    function tusacSearch(acard::TuSacCards.Card, mode)
        cnt = 0
        if mode == 0  # 4 cards of same kind, same color
            pattern = 0x67
        elseif mode == 1 # 3 of Tst or xpm have to be same color
            pattern = 0x64
        elseif mode == 2 # 3 of Tst or xpm have to be same color
            pattern = 0x64
        end
    end
    TuSacCards.ssort(ahand)
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

function readRFDeck(RF,gameDeck)
    global playerSuitsCnt,deadCards,kpoints,points
    readRFtable(RF,gameDeck)
    gameDeck = TuSacCards.Deck(TuSacCards.removeCards!(gameDeck,readline(RF)))
    tstMoveArray = []
    local found = false
    while true
        global RFaline = readline(RF)
        RFp = split(RFaline,", ")
        if RFp[1] == "(\"M\""
            found = true
            astr = string(RFp[2],RFp[3],RFp[4])
            push!(tstMoveArray,astr)
        elseif RFp[1] == "D" || RFp[1] == "S"|| RFp[1] == "K"|| RFp[1] == "C"
                found = true
                a =[]
                if RFp[1] == "D"
                    for i in 3:lastindex(RFp)
                        push!(a,TuSacCards.cardStrToVal(RFp[i]))
                    end
                else
                    for i in 3:lastindex(RFp)
                        push!(a,parse(Int,RFp[i]))
                    end
                end
                p = parse(Int,RFp[2])

                if RFp[1] == "D"
                    global deadCards[p] = a
                elseif RFp[1] == "S"
                    global playerSuitsCnt = a
                elseif RFp[1] == "K"
                    global kpoints = a[1:4]
                    global  points = a[5:8]
                elseif RFp[1] == "C"
                    global coinsArr[1] = [a[1],a[2]]
                    global coinsArr[2] = [a[3],a[4]]
                    global coinsArr[3] = [a[5],a[6]]
                    global coinsArr[4] = [a[7],a[8]]
                    println("COIN:",coinsArr)
                end
        else
            if found
                break
            end
        end
    end

    a = [P0_hand,P1_hand,P2_hand,P3_hand,P0_assets,P1_assets,P2_assets,P3_assets,P0_discards,P1_discards,P2_discards,P3_discards,gameDeck]
    return a,tstMoveArray,RFaline
end
cond(R) = SubString(R,1,1) == "#" || R == "(\"M\"" || R == "#" || R == "D" || R == "S" || R == "K"
function readRFNsearch!(RF,index)
    global RFstates, RF, RFaline
    println(RFaline)
    RFstates = split(RFaline,", ")
    while true
        if cond(RFstates[1])
            while !eof(RF)
                RFaline = readline(RF)
                RFstates = split(RFaline,", ")
                if !cond(RFstates[1])
                    break
                end
            end
        elseif SubString(RFstates[1],1,1) != "#"
            println("CMP=",(RFstates[1],index))
            if RFstates[1] == index
                println("Found index ",RFaline)
                break
            end
            readline(RF)
            readline(RF);readline(RF);readline(RF);readline(RF);
            readline(RF);readline(RF);readline(RF);readline(RF);
            readline(RF);readline(RF);readline(RF);readline(RF);
            RFaline = readline(RF)
            RFstates = split(RFaline,", ")
        end
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
    if okToPrint(0x1)
        println("prev-winner,sel", (winner,playerSel,myPlayer,rPlayer))
    end
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
    global FaceDown = wantFaceDown
    setupDrawDeck(gameDeck, GUILoc[13,1], GUILoc[13,2], GUILoc[13,3], FaceDown)
    setupDrawDeck(playerD_hand, GUILoc[4,1], GUILoc[4,2], GUILoc[4,3],  FaceDown)
    setupDrawDeck(playerC_hand, GUILoc[3,1], GUILoc[3,2], GUILoc[3,3],  FaceDown)


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
    global FaceDown = wantFaceDown
    global pBseat = setupDrawDeck(playerB_hand, GUILoc[2,1], GUILoc[2,2], GUILoc[2,3],  FaceDown)
    global human_state = setupDrawDeck(playerA_hand, GUILoc[1,1], GUILoc[1,2], GUILoc[1,3], false)
    replayHistory(0)
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
            for b in a
                st = string(st,_ts(b)," ")
            end
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



"""
    c_scan(p,s)
        scan/c_analyzer all the chots. Return singles.
TBW
"""
function c_scan(p,s;win=false)
    if  okToPrint(0x8)
         println("c-scan",(p,s))
    end
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
TBW
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
    if okToPrint(0x8) && !silence
        print("cTrsh = ")
        ts_s(cTrsh)
    end
    chot1 = cTrsh
    if okToPrint(0x8) && silence == false
        print("allPairs= ")
        for ps in allPairs
            for p in ps
                print((length(p),ts(p[1])))
            end
        end
        print("single= ")
        for c in single
            print(" ", ts(c))
        end
        print(" --ChotP=")
        for c in chotP
            ts_s(c)
        end
        print(" --Chot1=")
        for c in chot1
            print(" ", ts(c))
        end
        print(" --Chot1Special=")
        for c in chot1Special
            print(" ", ts(c))
        end
        print("missT=")
        for tc in missT
            for c in tc
                print(" ", ts(c))
            end
            print("|")
        end
        print("miss1= ")
        for tc in miss1
            for c in tc
                print(" ", ts(c))
            end
            print("|")
        end
        println()
    end
   # println((allPairs, single, chot1, miss1, missT, miss1Card, chotP, chot1Special, suitCnt, miss1_1,miss1_2,cTrsh))
    return allPairs, single, chot1, miss1, missT, miss1Card, chotP, chot1Special, suitCnt, miss1_1,miss1_2,cTrsh
end

global rQ = Vector{Any}(undef,4)
global rReady = Vector{Bool}(undef,4)

function has_T(c)
    global Tuong
    return Tuong[c&0x3+1] != 0
end
function updateHandPic(np)
   cp = playerMaptoGUI(np)
    if cp == 1
        gx,gy = 7, 14
    elseif cp == 2
        gx,gy = 17,12
    elseif cp == 3
        gx,gy = 12, 6
    else
        gx,gy = 3,12
    end
    handPic.pos = tableGridXY(gx, gy)
end
function  updateErrorPic(cp)
    if cp == 0
        gx,gy = 20,20
    else
        gx,gy = 10,10
    end
    errorPic.pos = tableGridXY(gx, gy)
end
function  updateboDoiPic(np,on)
    cp = playerMaptoGUI(np)

    if on
        if cp == 1
            gx,gy = 7, 14
        elseif cp == 2
            gx,gy = 17,12
        elseif cp == 3
            gx,gy = 12, 6
        else
            gx,gy = 3,12
        end
    else
        gx,gy = 20,20
    end
    boDoiPic[cp].pos = tableGridXY(gx, gy)
end
function updateWinnerPic(np)

    if noGUI()
        return
    end
    cp = playerMaptoGUI(np)

    if np == 0
        gx,gy = 20,20
    elseif cp == 1
        gx,gy = 7, 14
    elseif cp == 2
        gx,gy = 17,12
    elseif cp == 3
        gx,gy = 12, 6
    else
        gx,gy = 3,12
    end
    winnerPic.pos = tableGridXY(gx, gy)
end

function updateBaiThuiPic(np)
    if noGUI()
        return
    end
    if np == 0
        gx,gy = 20,20
    else
        gx,gy = 10, 10
    end
    baiThuiPic.pos = tableGridXY(gx, gy)
end

function removeCards!(cond,isDeck, n, cards)
    global gameDeck,gameDeckArray
    if cond
        nc = pop!(gameDeck,1)
        push!(gameDeck,nc)
        return nc
    end
    TuSacManager.removeCards!(isDeck,n,cards)
    if haBai
        return
    end
    if isDeck 
        nc = pop!(gameDeck, 1)
        nca = pop!(gameDeckArray)
        return nc
    else
       # m = n == 0 ? 0 : playerMaptoGUI(n)
        m = n
    #  if length(cards) != 4 && length(cards) > 0
    #     trackPlayedCards(n,cards,false)
    #  end
        for c in cards
            if histFile
                index = 0
                for i in 1:16
                    if moveArray[i,1] == c
                        moveArray[i,2] = m
                        break
                    elseif moveArray[i,1] == 0
                        moveArray[i,1] = c
                        moveArray[i,2] = m
                        break
                    end
                end
            end
            if n == 0
                return
            end
            if okToPrint(0x1)
                println("REMOVE ",ts(c)," from ",n," map-> ",m," myPlayer=",myPlayer)
            end
            found = false
            for l = 1:length(all_hands[n])
                if c == all_hands[n][l]
                    found = true
                    splice!(all_hands[n], l)
                    break
                end
            end
            @assert found
            global FaceDown = !isGameOver()

            if m == 1
                pop!(playerA_hand,ts(c))
                global human_state = setupDrawDeck(playerA_hand, GUILoc[1,1], GUILoc[1,2], GUILoc[1,3], false)

            elseif m == 2
                pop!(playerB_hand,ts(c))
                setupDrawDeck(playerB_hand, GUILoc[2,1], GUILoc[2,2], GUILoc[2,3], FaceDown)

            elseif m == 3
                pop!(playerC_hand,ts(c))
                setupDrawDeck(playerC_hand, GUILoc[3,1], GUILoc[3,2], GUILoc[3,3],  FaceDown)

            elseif m == 4
                pop!(playerD_hand,ts(c))
                setupDrawDeck(playerD_hand, GUILoc[4,1], GUILoc[4,2], GUILoc[4,3], FaceDown)

            end

        end
    end
end

function addCards!(cond,discard, n, cards)
    global matchSingle
    if cond 
        return
    end
    if haBai
        return
    end
    TuSacManager.addCards!(discard,n,cards)
    if n < 5 && discard && length(cards) > 0
        matchSingle[n] = cards[1]
    end
    m  = n
    for c in cards
        if histFile
            for i in 1:16
                if moveArray[i,1] == c
                    moveArray[i,3] = (discard+1)*4 + m
                    break
                elseif moveArray[i,1] == 0
                    moveArray[i,1] = c
                    moveArray[i,3] = (discard+1)*4 + m
                    break
                end
            end
        end
        if okToPrint(0x1)
            println("ADD ",ts(c)," from ",n," map-> ",m," myPlayer=",myPlayer)
        end
        if !discard
            push!(all_assets[n], c)
        else
            push!(all_discards[n], c)
        end
        if !discard
            if m== 1
                push!(playerA_assets,ts(c))
                asset1 = setupDrawDeck(playerA_assets, GUILoc[5,1], GUILoc[5,2], GUILoc[5,3], false,true)

            elseif m == 2
                push!(playerB_assets,ts(c))
                asset2 = setupDrawDeck(playerB_assets, GUILoc[6,1], GUILoc[6,2],GUILoc[6,3], false,true)

            elseif m == 3
                push!(playerC_assets,ts(c))
                asset3 = setupDrawDeck(playerC_assets, GUILoc[7,1], GUILoc[7,2],GUILoc[7,3], false,true)

            elseif m == 4
                push!(playerD_assets,ts(c))
                asset4 = setupDrawDeck(playerD_assets, GUILoc[8,1], GUILoc[8,2],GUILoc[8,3],false,true)

            end
        else
            if m== 1
                push!(playerA_discards,ts(c))
                setupDrawDeck(playerA_discards, GUILoc[9,1], GUILoc[9,2],GUILoc[9,3],false)
            elseif m == 2
                push!(playerB_discards,ts(c))
                setupDrawDeck(playerB_discards, GUILoc[10,1], GUILoc[10,2],GUILoc[10,3], false)

            elseif m == 3
                push!(playerC_discards,ts(c))
                setupDrawDeck(playerC_discards, GUILoc[11,1], GUILoc[11,2],GUILoc[11,3],false)

            elseif m == 4
                push!(playerD_discards,ts(c))
                discard4 = setupDrawDeck(playerD_discards, GUILoc[12,1], GUILoc[12,2],GUILoc[12,3],false)

            end
        end
    end
end

"""
    replayHistory(index,a=[],sel=1,fileMode=0)

fileMode:0 no file
         1 open  write
         2       write, close
         3 open, write, close
         4       write
"""
function replayHistory(index,a=[],sel=1,fileMode=0,testP = 0, card=boDoiCard)
    global HISTORY,all_hands,all_assets,all_discards,gameDeckArray, coinsArr,
     glIterationCnt,glNeedaPlayCard,glPrevPlayer,tsActiveCard,ActiveCard,BIGcard,aiTrait,aiType
    global playerA_hand, playerA_discards, playerA_assets
    global playerB_hand, playerB_discards, playerB_assets
    global playerC_hand, playerC_discards, playerC_assets
    global playerD_hand, playerD_discards, playerD_assets
    global gameDeck,coldStart,boxes
    global playerSuitsCnt,deadCards,kpoints,points

    rnd(n) = n > 4 ? n-4 : n
    indexSel(s,n) = s == 1 ? n : s == 2 ? rnd(n+1) : s == 3 ? rnd(n+2) : rnd(n+3)
    if(index > 0)
        global glIterationCnt,glNeedaPlayCard,glPrevPlayer,tsActiveCard,ActiveCard,BIGcard = a[14]
        playerSuitsCnt,deadCards,kpoints,points = a[15]
        glIterationCnt = glIterationCnt << 2
    end
    if index != 0 && fileMode == 0
        playerA_hand = deepcopy(a[indexSel(sel,1)])
        playerB_hand = deepcopy(a[indexSel(sel,2)])
        playerC_hand = deepcopy(a[indexSel(sel,3)])
        playerD_hand = deepcopy(a[indexSel(sel,4)])

        playerA_assets = deepcopy(a[indexSel(sel,1) + 4])
        playerB_assets = deepcopy(a[indexSel(sel,2) + 4])
        playerC_assets = deepcopy(a[indexSel(sel,3) + 4])
        playerD_assets = deepcopy(a[indexSel(sel,4) + 4])

        playerA_discards = deepcopy(a[indexSel(sel,1) + 8])
        playerB_discards = deepcopy(a[indexSel(sel,2) + 8])
        playerC_discards = deepcopy(a[indexSel(sel,3) + 8])
        playerD_discards = deepcopy(a[indexSel(sel,4) + 8])

        gameDeck = deepcopy(a[13])
        if sel > 1
            s = 4 - (sel - 1)
            playerSuitsCnt = circshift(playerSuitsCnt,s)
            deadCards = circshift(deadCards,s)
            kpoints = circshift(kpoints,s)
            points = circshift(points,s)
            coinsArr = circshift(coinsArr,s)
            global aiTrait = circshift(aiTrait,s)
            global aiType = aiTrait .>> 2
            global boDoiFlag = (aiTrait .& 0x1 ) != 0
            global mydefensiveFlag = defensiveFlag .&& ((aiTrait .& 0x2) .!= 0)
        
            global playerName = setPlayerName(playerRootName,aiTrait)
            setGUIname(playerName)
        end
        if GUI
            for p in 1:4
                ccnt = 0
                for i in 1:coinsArr[p][1]
                        createCoin(1,p,ccnt)
                        ccnt += 1
                end 
                for i in 1:coinsArr[p][2]
                    createCoin(2,p,ccnt)
                    ccnt += 1
                end   
            end
        end
      #  GUI && updateHandPic(glPrevPlayer)
    end
    if fileMode > 0  && index != 0
        if fileMode&1 > 0
            global hfName = nextFileName(histFILENAME,chFilenameStr)
            global HF = open(hfName,"w")

            println(HF,"# (",testP-1)
            println(HF,"#")
            println(HF,"#")
            global histFILENAME = hfName

        end
        if fileMode > 0
            println(HF,(a[14])," ",ts(card))
            for i in 1:13
                println(HF,a[indexSel(sel,i)])
            end
            print(HF,"S, 1")
            for m in playerSuitsCnt
                print(HF,", ",m)
            end
            println(HF)
            for i in 1:4
                print(HF,"D, $i")
                for m in deadCards[i]
                    print(HF,", ",ts(m))
                end
                println(HF)
            end
            print(HF,"K, 1")
                for m in kpoints
                    print(HF,", ",m)
                end
                for m in points
                    print(HF,", ",m)
                end
                println(HF)
            print(HF,"C, 1")
            for p in 1:4
                for c in coinsArr[p]
                    print(HF,", ",c)
                end
            end
            println(HF)
        end
        if fileMode & 0x2 > 0
            close(HF)
        end
    end
    if fileMode != 0
        return
    end
    getData_all_hands()
    getData_all_discard_assets()
    if GUI
        global FaceDown = !isGameOver()

        a5 = setupDrawDeck(gameDeck, GUILoc[13,1], GUILoc[13,2], GUILoc[13,3], FaceDown)

        d1 = setupDrawDeck(playerA_discards, GUILoc[9,1], GUILoc[9,2], GUILoc[9,3], false)
        d2 = setupDrawDeck(playerB_discards, GUILoc[10,1], GUILoc[10,2], GUILoc[10,3], false)
        d3 = setupDrawDeck(playerC_discards, GUILoc[11,1], GUILoc[11,2],  GUILoc[11,3], false)
        d4 = setupDrawDeck(playerD_discards, GUILoc[12,1], GUILoc[12,2], GUILoc[12,3], false)

        d5 = setupDrawDeck(playerA_assets, GUILoc[5,1], GUILoc[5,2], GUILoc[5,3], false,true)
        d6 = setupDrawDeck(playerB_assets, GUILoc[6,1], GUILoc[6,2], GUILoc[6,3], false,true)
        d7 = setupDrawDeck(playerC_assets, GUILoc[7,1], GUILoc[7,2], GUILoc[7,3], false,true)
        d8 = setupDrawDeck(playerD_assets, GUILoc[8,1], GUILoc[8,2], GUILoc[8,3], false,true)

        global human_state = setupDrawDeck(playerA_hand, GUILoc[1,1], GUILoc[1,2], GUILoc[1,3], false)
                        a2 = setupDrawDeck(playerB_hand, GUILoc[2,1], GUILoc[2,2], GUILoc[2,3], FaceDown)
                        a3 = setupDrawDeck(playerC_hand, GUILoc[3,1], GUILoc[3,2], GUILoc[3,3], FaceDown)
                        a4 = setupDrawDeck(playerD_hand, GUILoc[4,1], GUILoc[4,2], GUILoc[4,3], FaceDown)
        if tusacState < tsGameLoop
            boxes =[]
            push!(boxes,human_state,d1,d2,d3,d4, d5,d6,d7,d8, a2,a3,a4,a5)
        end
    end
end

nextPlayer(p) = p == 4 ? 1 : p + 1
prevPlayer(p) = p == 1 ? 4 : p - 1

function whoWinRound(card, play4,  n1, r1, n2, r2, n3, r3, n4, r4)
    nP,nWin,nr = TuSacManager.whoWinRnd(card,play4,n1,r1,r2,r3,r4)
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
        thand = deepcopy(all_hands[n])
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
                        okToPrint(0x8) &&
                            println("match ",ts_s(r)," is SAKI, not accepted")
                        l = 0
                    end
                end
            end
            ll = length(ss) + length(cs) + length(m1s) + length(mts)

            if oll < ll
                okToPrint(0x8) &&
                    println("whowin, chking more Trsh:",
                    (length(ss) , length(cs) , length(m1s) , length(mts)),
                    (length(oss) , length(ocs) , length(om1s) , length(omts)))
                
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
    okToPrint(0x8) &&
      #  println("W-wr result ",(l1, w1, ts_s(r1,false) ),(l2, w2, ts_s(r2,false)),(l3, w3, ts_s(r3,false)),(l4, w4, ts_s(r4,false)))
        println("W-wr result ",(l1, w1, r1 ),(l2, w2,r2),(l3, w3,r3),(l4, w4,r4))
    
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
    return n, w, r
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

function toDeck(arr,brr,crr,d)
    r = Vector{UInt8}(undef,112+12)
    i = 1
    for mr in [arr,brr,crr]
        for m in mr
        for a in m
            r[i] = a
            i += 1
        end
    end
    end
    for a in d
        r[i] = a
        i += 1
    end

    for a in [arr,brr,crr]
        for m in a
        r[i] = length(m)
        i += 1
        end
    end

    return r
end
function popchk!(array)
    if length(array) > 0
        pop!(array)
    end
end


function trackPlayedCards(player,card,deck)
    global prevCard, prevN1, prevDeck
    if card_equal(card[1],prevCard) ||
        (length(card)> 1 &&
        ((inSuit(prevCard,card[1]) && inSuit(prevCard,card[2])) ||
          (is_c(prevCard) && is_c(card[1]) && is_c(card[2]))))
        n2 = nextPlayer(prevN1)
        if prevN1 == player
            popchk!(deadCards[n2])
        elseif n2 == player
            if(length(card) > 1) && card_equal(card[1],card[2])
                popchk!(deadCards[prevN1])
            end
        elseif prevN1 != 0
            popchk!(deadCards[prevN1])
            popchk!(deadCards[n2])
        end
    else
        c = card[1]
        if deck == false
            push!(playedCards[player],c)
            l = length(playedCards[player])
            if l > 1
                c0 = playedCards[player][l]
                c1 = playedCards[player][l-1]
                if inSuit(c0,c1) && !card_equal(c0,c1)
                    noSingle[player] = true
                end
            end
            if noSingle[player]
                sc = suitCards(c)
                for c in sc
                    push!(probableCards[player],c)
                end
            end
        end
        n1 = player
        push!(deadCards[n1],c)
        n2 = nextPlayer(n1)
        push!(deadCards[n2],c)

        prevCard = card
        prevN1 = player
        prevDeck = deck
    end
end

function whoWin!(cond,glIterationCnt, pcard,play3,t1Player,t2Player,t3Player,t4Player)
    global rReady, rQ
    if cond
        return 0,0,pcard
    end
    if  rReady[t1Player] &&
        rReady[t2Player] &&
        rReady[t3Player] &&
       (play3  ||
        rReady[t4Player]  )
        n1c = rQ[t1Player]
        n2c = rQ[t2Player]
        n3c = rQ[t3Player]
        if okToPrint(0x8)
            println(n1c)
            println(n2c)
            println(n3c)
        end
        if !play3
            n4c = rQ[t4Player]
            if okToPrint(0x8)
              println(n4c)
            end
        else
            n4c = []
        end
        rReady = [false,false,false,false]
   
    else
        glIterationCnt -= 1
        return
    end
    if okToPrint(0x8)
        println("AT whoWin ",((ts(n1c),ts(n2c),ts(n3c),ts(n4c)),glNewCard),(t1Player,t2Player,t3Player,t4Player),
        (PlayerList[t1Player],PlayerList[t2Player],
        PlayerList[t3Player],PlayerList[t4Player])
        )
    end
    if (PlayerList[myPlayer] != plSocket) && isServer()
        if PlayerList[t1Player] == plSocket
            n1c = nwAPI.nw_getR(nwAPI.nw_receiveFromPlayer(t1Player, nwPlayer[t1Player],8))
        end
        if PlayerList[t2Player] == plSocket
            n2c = nwAPI.nw_getR(nwAPI.nw_receiveFromPlayer(t2Player, nwPlayer[t2Player],8))
        end
        if PlayerList[t3Player] == plSocket
            n3c = nwAPI.nw_getR(nwAPI.nw_receiveFromPlayer(t3Player, nwPlayer[t3Player],8))
        end
        if PlayerList[t4Player] == plSocket
            if !play3
                n4c = nwAPI.nw_getR(nwAPI.nw_receiveFromPlayer(t4Player, nwPlayer[t4Player],8))
            end
        end

        nPlayer, winner, r = whoWinRound(
            pcard,
            !play3,
            t1Player,
            n1c,
            t2Player,
            n2c,
            t3Player,
            n3c,
            t4Player,
            n4c,
        )
        function nw_makeR2(a,b,r)
            s_ar = []
            push!(s_ar,a,b,length(r))
            for ar in r
                push!(s_ar,ar)
            end
            return s_ar
        end
        msg = nw_makeR2(nPlayer, winner, r )
        for i in 1:4
            if(PlayerList[i] == plSocket)
                nwAPI.nw_sendToPlayer(i,nwPlayer[i],msg)
            end
        end
    elseif PlayerList[myPlayer] == plSocket
            r =[]
            if t1Player == myPlayer
                r = n1c
                nwAPI.nw_sendToMaster(myPlayer, nwMaster,r)
            elseif t2Player == myPlayer
                r = n2c
                nwAPI.nw_sendToMaster(myPlayer, nwMaster,r)
            elseif t3Player == myPlayer
                r = n3c
                nwAPI.nw_sendToMaster(myPlayer, nwMaster,r)
            else
                if !play3
                    r = n4c
                    nwAPI.nw_sendToMaster(myPlayer, nwMaster,r)
                end
            end
            rmsg = nwAPI.nw_receiveFromMaster(nwMaster,8)
            nPlayer, winner, l= rmsg[2],rmsg[3],rmsg[4]
            r = []
            for i in 1:l
                push!(r,rmsg[i+4])
            end
            if okToPrint(0x8)
                println("received =" , (nPlayer, winner, l, r))
            end
            if winner&0xFF == 0xFE
                if okToPrint(0x8)
                    println("Game Over, player ", nPlayer, " win")
                end
                gameOver(nPlayer)
            end
    else
        nPlayer, winner, r = whoWinRound(
            pcard,
            !play3,
            t1Player,
            n1c,
            t2Player,
            n2c,
            t3Player,
            n3c,
            t4Player,
            n4c,
        )
    end
    return nPlayer, winner, r
end


function removeACard!(hand, s)
    grank = "Tstcxpm"
    gcolor = "TVDX"
    tohand = []

    aStrToVal(s) =
    (UInt8(find1(s[1], grank)) << 2) | (UInt8(find1(s[2], gcolor) - 1) << 5)
    v = aStrToVal(s)
    for (i,c) in enumerate(hand)
        if card_equal(c.value, v)
            pop!(hand,c)
            return c
            break
        end
    end
    return 0
end

"""
moveCard!( nf,nt, c)

nf: 0 is from Deck, 1-4 from hand.
nt: 1-4: assets, 5-8: discards
c: a card in alphabet (if from deck ... not used)
"""
function moveCard!( fromIndex,toIndex,crd)
    if fromIndex == 0
        card = gameDeckArray[end]
    else
        card = TuSacCards.findCard(all_hands[fromIndex],crd)
    end
    okToPrint(0x80) && println("REMOVE CARD:",(fromIndex,toIndex),ts(card))
    removeCards!(false,fromIndex==0,fromIndex,card)

    n = toIndex > 4 ? toIndex - 4 : toIndex
    okToPrint(0x80) && println("ADD CARD:",(fromIndex,toIndex),ts(card))
    addCards!(false,toIndex>4, n, card)
end


function gamePlay1Iteration()
    global glNewCard, ActiveCard
    global glNeedaPlayCard
    global glPrevPlayer
    global glIterationCnt,bbox1
    global t1Player,t2Player,t3Player,t4Player
    global n1c,n2c,n3c,n4c,coDoiPlayer, coDoiCards,GUI_busy

    function checkHumanResponse(player,cmd)
        global GUI_ready, GUI_array, humanIsGUI,rQ, rReady
        if playerIsHuman(player)
            if humanIsGUI()
                if GUI_ready
                    if cmd == glNeedaPlayCard && length(GUI_array) == 0
                        return false
                    end
                    rReady[player] = true
                    rQ[player]=GUI_array
                    if length(GUI_array)==0
                        println(remoteMaster,".")
                    else
                        println(remoteMaster,ts(GUI_array))
                    end
                    if okToPrint(0x80)
                        print("Human-p: ", player," PlayCard = ")
                         ts_s(rQ[player])
                    end
                else
                    GUI && sleep(.3)
                    return false
                end
            else
                cards = keyboardInput(player)
                ts_s(cards)
                rQ[player]=cards
                rReady[player] = true
                println("PlayCard = ", (cards))
                ts_s(cards)
            end
        end
        return true
    end

    function All_hand_updateActor(card,facedown)
        if noGUI()
            return
        end
        global lsx,lsy
        global prevActiveCard = ActiveCard
        global tsPrevActiveCard = tsActiveCard
        global tsActiveCard = card
        mmm = mapToActors[card]
        println("ActiveCard ",ts(tsActiveCard))
        ActiveCard = mmm
        lsx, lsy = actors[mmm].pos
        global FaceDown = !isGameOver()

        if facedown == FaceDown
            mask[mmm] = mask[mmm] & 0xFE
        else
            mask[mmm] = mask[mmm] | 0x1
        end
    end

    function getScaledData(fn)
        global scaleArray
        if isfile(fn)
            scaleArray = []
            lines = readlines(aiFilename)
            scaleArray = []
            for line in lines
                line = replace(line,"["=>"")
                grps  = split(line,"],")
                aArray =[]
                for grp in grps[1:5]
                    grp = replace(grp,"]" => "")
                    rl = split(grp,',')
                    gs = [parse(Int,rl[1]),parse(Int,rl[2]),
                    parse(Int,rl[3]),parse(Int,rl[4])]

                    outA = [gs[1],gs[2],gs[3],gs[4]]
                    push!(aArray,outA)
                end
                push!(scaleArray,aArray)
            end
        end
    end
    
    function checkMaster(action,gpPlayer)
        # socket is a remote player
        # for The master: if the currentPlayer (gpPlayer) is a socket, then we need its pcard. If not, our bot has the card. After getting the right card, we need to send to other computers/Players so they can update/override their bots result
       # println("in CheckMaster ",(action,gpPlayer))
        if(action == gpPlay1card)
            if rReady[gpPlayer] == true
                cards = rQ[gpPlayer]
            else
                return
            end
            if okToPrint(0x8)
                    println((ts(cards[1]),UInt8(cards[1])))
            end
            isMaster = (PlayerList[myPlayer] != plSocket)
            if isMaster
                if PlayerList[gpPlayer] == plSocket
                    msg = nwAPI.nw_receiveFromPlayer(gpPlayer, nwPlayer[gpPlayer], 8)
                    final_card = msg[2]
                else
                    final_card = cards
                end
                for p in 1:4
                    if PlayerList[p] == plSocket
                        if(gpPlayer != p)
                            nwAPI.nw_sendToPlayer(p,nwPlayer[p],final_card)
                        end
                    end
                end
            else
                if gpPlayer == myPlayer
                    final_card = cards
                    nwAPI.nw_sendToMaster(myPlayer, nwMaster,final_card)
                else
                    msg = nwAPI.nw_receiveFromMaster(nwMaster,8)
                    final_card =msg[2]
                end
            end
            rReady[gpPlayer] = true
            rQ[gpPlayer] = final_card
            return
        end
    end
    
    if(rem(glIterationCnt,4) ==0)
        okToPrint(0x80) && println("HERE-begin")
        global rdCmd = readline(remoteMaster)
        if rdCmd[1] == 'N'
            println(rdCmd)
            n = split(rdCmd,",")
            t =["","","",""]
            global playerRootName = n[2:5]
            setGUIname(setPlayerName(playerRootName,t))
            println(remoteMaster,"AckName")
            global rdCmd = readline(remoteMaster)
        end
        okToPrint(0x80) && println("Receive remote cmd = ",rdCmd)
        global rmCmd = split(rdCmd,",")
        rmPlay1Card = rmCmd[1] == "true"
        rmActivePlayer = parse(Int,rmCmd[2])
        
        glPrevPlayer = rmActivePlayer
        glNeedaPlayCard = rmPlay1Card
        updateHandPic(glPrevPlayer)
        global currentPlayer = nextPlayer(glPrevPlayer)
        global rmNewCard
        if glNeedaPlayCard
            rmNewCard = TuSacCards.findCard(all_hands[glPrevPlayer],rmCmd[3])
        else
            rmNewCard = gameDeckArray[end]
        end
        okToPrint(0x80) && println("rmNewCard ",ts(rmNewCard),rmCmd[3])
        glNeedaPlayCard = rmPlay1Card
        glPrevPlayer = rmActivePlayer

        glIterationCnt += 1
        l = glIterationCnt >> 2
        okToPrint(0x40) && println("I:",l," cP",cmpPoints(playerSuitsCnt, khui, kpoints),
        " eBL",emBaiLimit," eBT",emBaiTrigger,"\n\t\tcCPs",capturedCPoints,"\ttrshCnt:",
        gameTrashCntLatest,"\nwantFaceDown,faceDown,all",(wantFaceDown,FaceDown,openAllCard, gameEnd))


        if okToPrint(0x8)
            println(
                "^+++"," eBT=",emBaiTrigger[glPrevPlayer]," ++++++++++++++++++++++",
                ((glIterationCnt-1)>>2, glNeedaPlayCard, glPrevPlayer),
                " Bo-doi=",(boDoiPlayers),
                "+++++++++++++++++++++++++++",
            )
                printAllInfo()
        end
      #  okToPrint(0x80) && checksum()
        okToPrint(0x80) && TuSacManager.printTable()
        
        if length(aiFilename) > 0
            getScaledData(aiFilename)
        end
        if glNeedaPlayCard
            glNewCard = hgamePlay(
                all_hands,
                all_discards,
                all_assets,
                gameDeck,
                [];
                gpPlayer = glPrevPlayer,
                gpAction = gpPlay1card,
                rQ,
                rReady
            )
        end
    elseif(rem(glIterationCnt,4) ==1)
        global FaceDown = !isGameOver()
        glIterationCnt += 1
        global CardFromDeck = !glNeedaPlayCard
        if glNeedaPlayCard
            checkHumanResponse(glPrevPlayer,glNeedaPlayCard)
            checkMaster(gpPlay1card,glPrevPlayer)
            if rReady[glPrevPlayer]
                glNewCard = rQ[glPrevPlayer]

                if length(glNewCard) == 0
                    glNewCard = []
                else
                    glNewCard = glNewCard[1]
                end
                if okToPrint(0x8)
                    println(glNewCard)
                end
                rReady[glPrevPlayer] = false
            else
                glIterationCnt -= 1
                return
            end
            glNewCard = rmCmd[4] != "P" ? rmNewCard : glNewCard[1]
        else
            nc = removeCards!(true,true,0,0)
            # no need to call removeCard here -- gamedeck is array 0
            global gd = setupDrawDeck(gameDeck, GUILoc[13,1], GUILoc[13,2],  GUILoc[13,3],  FaceDown)
            glNewCard = nc[1].value
            global currentPlayer = nextPlayer(glPrevPlayer)
            if okToPrint(0x80)
                println("pick a card from Deck=", nc[1], " for player", nextPlayer(glPrevPlayer))
            end
           # trackPlayedCards(currentPlayer,glNewCard,true)
        end
        All_hand_updateActor(glNewCard, !FaceDown)

    elseif(rem(glIterationCnt,4) ==2)
        t1Player = nextPlayer(glPrevPlayer)
        glIterationCnt += 1
        hgamePlay(
            all_hands,
            all_discards,
            all_assets,
            gameDeck,
            glNewCard;
            gpPlayer = t1Player,
            gpAction = gpCheckMatch1or2,
            rQ,
            rReady
        )
        if glNeedaPlayCard
            cmd = gpCheckMatch2
        else
            cmd = gpCheckMatch1or2
        end
        t2Player = nextPlayer(t1Player)
        hgamePlay(
            all_hands,
            all_discards,
            all_assets,
            gameDeck,
            glNewCard;
            gpPlayer = t2Player,
            gpAction = cmd,
            rQ,
            rReady
        )
        t3Player = nextPlayer(t2Player)
        hgamePlay(
            all_hands,
            all_discards,
            all_assets,
            gameDeck,
            glNewCard;
            gpPlayer = t3Player,
            gpAction = gpCheckMatch2,
            rQ,
            rReady
        )
        t4Player = nextPlayer(t3Player)
        if !glNeedaPlayCard
            hgamePlay(
                all_hands,
                all_discards,
                all_assets,
                gameDeck,
                glNewCard;
                gpPlayer = t4Player,
                gpAction = gpCheckMatch2,
                rQ,
                rReady
            )
        end
    else
      
        glIterationCnt += 1
        aplayer = t1Player

        gotHumanInput = true
       
        for i in  1:4
            if !(glNeedaPlayCard && (i == 4 ))
                gotHumanInput = gotHumanInput && checkHumanResponse(aplayer,gpCheckMatch1or2)
              
            end
            aplayer = nextPlayer(aplayer)
        end
        if gotHumanInput == false
            glIterationCnt -= 1
            return
        end

        bbox1 = false

        moveStr = readline(remoteMaster)
        println(remoteMaster,"+")

        println("REMOTE MSG, Move array:",moveStr)
        mvArr = split(moveStr,",")
        for i in 2:lastindex(mvArr) -1
            f = split(mvArr[i]," ")
            moveCard!(parse(Int,f[1]),parse(Int,f[2]),f[3])
        end
        astr = split(mvArr[1]," ")
        nPlayer = parse(Int,astr[2])
        global currentPlayer = nPlayer
        if astr[1] == "gameOver" 
            gameOver(nPlayer)
            updateWinnerPic(nPlayer)
            global openAllCard = true
        elseif glNeedaPlayCard
            All_hand_updateActor(glNewCard[1],!FaceDown)
        end
        global FaceDown = !isGameOver()
        all_assets_marks[glNewCard] = 1

    end
end
 
restartedGameOnStop = false
deltaSum = 0
deltaSumP = 0
deltaSumN = 0

function pointsCalc(winner)
    global oneTime
    global pots, kpoints, GUIname, boDoiPlayers

    if winner < 5
        global match += 1
        allPairs, single, chot1, miss1, missT, miss1Card, chotP, chot1Special, suitCnt =
        scanCards(all_hands[winner],false,true)
        global gameWin[winner] += 1
        points[winner] += 3 + suitCnt + c_points(chotP,chot1Special)+ kpoints[winner]
        if khui[winner] == 2
            points[winner] *= 2
        end
        kpoints[winner] = points[winner]
    else
        kpoints = zeros(Int8,4)
    end
    astr = Vector{String}(undef,4)
    firstBDP = 0
    eB = [111,111,111,111]
    for p in 1:4
        if emBaiTrigger[p][1] >= 0
            if emBaiTrigger[p][2] > 0
                old = eB[emBaiTrigger[p][2]] 
                if emBaiTrigger[p][1] < old 
                    eB[emBaiTrigger[p][2]] = emBaiTrigger[p][1]
                end
            end
            if emBaiTrigger[p][3] > 0
                old = eB[emBaiTrigger[p][3]] 
                if emBaiTrigger[p][1] < old 
                    eB[emBaiTrigger[p][3]] = emBaiTrigger[p][1]
                end
            end
        end
    end
   
    for p in 1:4
        if eB[p] != 111
            astr[p] = string(playerName[p]," ",pots[p],"+",kpoints[p],", T",(gameTrashCnt[p],gameTrashCntLatest[p])," E",eB[p])
        else
            astr[p] = string(playerName[p]," ",pots[p],"+",kpoints[p],", T",(gameTrashCnt[p],gameTrashCntLatest[p]))
        end
        if okToPrint(2)
            println(astr[p], " bo-doi @ ",boDoiPlayers[p])
        end
        pots[p] += kpoints[p]
        if boDoiPlayers[p] != 0 && firstBDP == 0
            firstBDP = (boDoiPlayers[p] - 2)
        end
    end

    matchAve = sum(pots)/match
    println("MatchCnt=",match," Match ave = ",matchAve, " ",gameWin,(pots./gameWin))
    println("eBTl=",emBaiLimit," eBTrg=",emBaiTrigger," sEBT", eB,", cCp",capturedCPoints,", ai",aiType," Game Iteration=", glIterationCnt >> 2)
    if winner > 4
        setGUIname(astr)
        return
    end
    if histFile
        println(HF,"#, - - ",(astr))
    end
    global restartedGameOnStop
    if  (kpoints[winner] & 1 ) != 0
        println("Bad Error, final point is an even number")
        exit()
    end
    if stopOn == "defensive"
        if  (kpoints[winner] & 1 ) != 0
            if reduceFile
                l2 = ( glIterationCnt >> 2 )
                replayHistory(1,HISTORY[1],  1,0x1,l1)
                replayHistory(l2,HISTORY[l2],1,0x2)
               # restartGameAt(l1)
               readline()
            end

        elseif emBaiTrigger[player][1] >= 0 && oneTime &&
            emBaiTrigger[player][1] != glIterationCnt >> 2
            println("TRIGGERS = ",(emBaiTrigger)," Iteration = ",glIterationCnt >>2 )
            println("c-Points =",
            cmpPoints(playerSuitsCnt, khui,kpoints))
            global oneTime = false
            l1 = emBaiTrigger[player][1]
            l2 = ( glIterationCnt >> 2 )
            global boDoiCard = 0
            firstBDP

            if reduceFile
                replayHistory(1,HISTORY[1],  1,0x1,l1)
                replayHistory(l1,HISTORY[l1],1,0x4)
                if firstBDP > 0
                    replayHistory(firstBDP,HISTORY[l1],1,0x4)
                end
                replayHistory(l2,HISTORY[l2],1,0x2)
               # restartGameAt(l1)
            end
            if reduceFile || histFile
            println("echo \"# ($l1\" > .a; cat $hfName >> .a; mv .a gtt.txt",echoOption)
            println("cp $hfName  gtt.txt",echoOption)
          #  println((reduceFile,histFile))
            readline()
            end
        end
    elseif stopOn == "cases"
        m,mi = findmin(gameTrashCnt)
        case = (winner != mi && winner == 1 ) &&
               ( eB[winner] != 111)
               println("m,mi,case",(gameTrashCnt,gameTrashCntLatest),(m,mi,case,winner,eB))
        if case 
            l1 = eB[winner]
            l2 = l1 +1
            l3 = glIterationCnt >> 2
            if reduceFile
                replayHistory(1,HISTORY[1],  1,0x1,l1)
                replayHistory(l1,HISTORY[l1],1,0x4)
                replayHistory(l2,HISTORY[l2],1,0x4)
                replayHistory(l3,HISTORY[l3],1,0x2)
                println("echo \"# ($l1\" > .a; cat $hfName >> .a; mv .a gtt.txt",echoOption)
                println("cp $hfName  gtt.txt",echoOption)
            end
            readline()
        end

    elseif stopOn == "bodoi" && ((restartedGameOnStop)||
        (maximum(boDoiPlayers) > 0 &&
                maximum(boDoiPlayers)  != glIterationCnt>>2))
        max,maxi = findmax(boDoiPlayers)
        l1 = firstBDP
            global restartFlag = false
        println("winer = ", winner," BoDoi-Player = ", (maxi,max>>2,glIterationCnt>>2), "\n passed-card = ",ts(boDoiCard))
        if restartedGameOnStop
            restartedGameonStop = false
        end
        if  maximum(boDoiPlayers) > 0
            if turnOffBoDoi
                println("HUH, not sure")
                exit()
            end
            global pW = winner
            global pBD = maxi
            restartedGameonStop = true
            global boDoiPlayers = zeros(UInt8,4)
            global turnOffBoDoi = true
            if reduceFile
                l2 = ( glIterationCnt >> 2 )
                replayHistory(1,HISTORY[1],  1,0x1,l1)
                replayHistory(l1,HISTORY[l1],1,0x4)
                replayHistory(l2,HISTORY[l2],1,0x2)
                restartGameAt(l1)
            end
            l = l1 - 1
            println("echo \"# ($l\" > .a; cat $hfName >> .a; mv .a gtt.txt",echoOption)
            println("cp $hfName  gtt.txt",echoOption)

        else
            pv = pW == pBD ? 1 : 0
            cv = winner == pBD ? 1 : 0
            if pv == cv
                pv = cv = 0
            end
            global deltaSumP += pv
            global deltaSumN += cv
            global deltaSum += (pv - cv)
            println("Delta-Sum = ", deltaSum, ",(bD/no-bD) $deltaSumN / $deltaSumP")
            global turnOffBoDoi = false
            global allowPrint = stickyAllowPrint
            if bodoiInspect
                readline()
            end
        end
    end
    setGUIname(astr)
end

function setGUIname(nameStr)
    if GUI
        GUIname[1]  = TextActor(nameStr[1],"asapvar",font_size=fontSize,colorant="white")
        GUIname[1].pos = tableGridXY(10,GUILoc[1,2]-1)
        GUIname[2]  = TextActor(nameStr[2],"asapvar",font_size=fontSize,colorant="white")
        GUIname[2].pos = tableGridXY(16,1)
        GUIname[3]  = TextActor(nameStr[3],"asapvar",font_size=fontSize,colorant="white")
        GUIname[3].pos = tableGridXY(10,1)
        GUIname[4]  = TextActor(nameStr[4],"asapvar",font_size=fontSize,colorant="white")
        GUIname[4].pos = tableGridXY(1,1)
    end
end
function SNAPSHOT(testnum=0)
    global tstMoveArray
    currentStates =glIterationCnt>>2,glNeedaPlayCard,glPrevPlayer,tsActiveCard,ActiveCard,
    BIGcard,ts(tsActiveCard),aiTrait[1],aiTrait[2],aiTrait[3],aiTrait[4], 0
    cardsHist = playerSuitsCnt,deadCards,kpoints,points
    anE= []
    anE = deepcopy(
        [playerA_hand,
        playerB_hand,
        playerC_hand,
        playerD_hand,
        playerA_assets,
        playerB_assets,
        playerC_assets,
        playerD_assets,
        playerA_discards,
        playerB_discards,
        playerC_discards,
        playerD_discards,
        gameDeck,currentStates,cardsHist])
        push!(HISTORY,anE)
        if histFile
            for i in 1:16
                if moveArray[i,1] != 0
                    println(HF,("M",ts(moveArray[i,1]),moveArray[i,2],moveArray[i,3],0))
                    if !isTestFile
                        moveArray[i,1] = 0
                    end
                else
                    break
                end
            end
            if isTestFile
                for i in 1:16
                    if moveArray[i,1] != 0
                        astr = string(ts(moveArray[i,1]),moveArray[i,2],moveArray[i,3])
                        moveArray[i,1] = 0
                        if length(tstMoveArray)<i
                            println("Failed : test #",testnum)
                        else
                            if isTestFile && astr != tstMoveArray[i]
                                println("Failed : test #",testnum)
                                println((astr))
                                println(tstMoveArray[i])
                            end
                            if isTestFile && !trial
                            @assert astr == tstMoveArray[i]
                            end
                        end
                    else
                        break
                    end
                end
            end
            println(HF,currentStates)
            println(HF,playerA_hand)
            println(HF,playerB_hand)
            println(HF,playerC_hand)
            println(HF,playerD_hand)

            println(HF,playerA_assets)
            println(HF,playerB_assets)
            println(HF,playerC_assets)
            println(HF,playerD_assets)

            println(HF,playerA_discards)
            println(HF,playerB_discards)
            println(HF,playerC_discards)
            println(HF,playerD_discards)
            println(HF,gameDeck)
            println(HF,"S, 1, ",playerSuitsCnt[1],", ",playerSuitsCnt[2],", ",playerSuitsCnt[3],", ",playerSuitsCnt[4])
            for i in 1:4
                print(HF,"D, $i")
                for m in deadCards[i]
                    print(HF,", ",ts(m))
                end
                println(HF)
            end
            print(HF,"K, 1")
            for m in kpoints
                print(HF,", ",m)
            end
            for m in points
                print(HF,", ",m)
            end
            println(HF)
            print(HF,"C, 1")
            for p in 1:4
                for c in coinsArr[p]
                    print(HF,", ",c)
                end
            end
            println(HF)
            flush(HF)
        end
end

function playersSyncDeck!(deck::TuSacCards.Deck)
    global myPlayer

    isMaster = (PlayerList[myPlayer] != plSocket)
    if okToPrint(0x1)
        println("in SYNC DECK MY player", myPlayer)
        println(PlayerList)
    end
    if mode == m_server
            if okToPrint(0x1)
                println("MASTER",(PlayerList,myPlayer,shufflePlayer))
            end
           if shufflePlayer != myPlayer && PlayerList[shufflePlayer] == plSocket
                dArray = nwAPI.nw_receiveFromPlayer(shufflePlayer, nwPlayer[shufflePlayer],112)
                if okToPrint(0x1)
                    println("\nold Deck",deck)
                end
                deck = []
                deck = TuSacCards.newDeckUsingArray(dArray)
           else
                dArray = TuSacCards.toValueArray(deck)
                deck = []
                deck = TuSacCards.newDeckUsingArray(dArray)

           end
           if okToPrint(0x1)
                println("\nNew Deck=",deck)
           end
            for i in 1:4
                    if PlayerList[i] == plSocket
                        if i != shufflePlayer
                            a = nwAPI.nw_receiveFromPlayer(i, nwPlayer[i],112)
                        end
                        nwAPI.nw_sendToPlayer(i,nwPlayer[i],dArray)
                    end
            end
    elseif mode == m_client
        if okToPrint(0x1)
            println("PLAYER",(PlayerList,myPlayer))
        end
        if PlayerList[myPlayer] == plSocket
            dArray = TuSacCards.toValueArray(deck)
            nwAPI.nw_sendToMaster(myPlayer, nwMaster,dArray)
            dArray =[]
            dArray = nwAPI.nw_receiveFromMaster(nwMaster,112)
            deck = []
            deck = TuSacCards.newDeckUsingArray(dArray)
        end
    end
return(deck)
end
global nwPlayer = Vector{Any}(undef,4)


function clientSetup(serverURL,port)
    println((serverURL,port))
    try
        ac = connect(serverURL,port)
        return ac
    catch
        println("Failed to connect")
        exit()
        return 0
    end
end
function thinNetworkInit()
    global remoteMaster = clientSetup(serverURL,serverPort)
    global playerNum =readline(remoteMaster)
    global playerName = string("Player",playerNum)
    println(remoteMaster,playerName)
    global gameOn = true
end  

function networkInit()
    global GUIname, connectedPlayer,nameSynced, serverSetup, nwMaster, nwPlayer,mode
    addingPlayer = false
    if mode == m_server
        println("SERVER, expecting ", numberOfSocketPlayer - connectedPlayer, " players.")
        if serverSetup == false
            global myS = nwAPI.serverSetup(serverIP,serverPort)
            serverSetup = true
        else
            addingPlayer = true
        end
        newPlayer = 0
        while connectedPlayer < numberOfSocketPlayer
            global p = nwAPI.acceptClient(myS)
            while true
                global i = rand(2:4)
                if PlayerList[i] != plSocket
                    break
                end
            end
            PlayerList[i] = plSocket
            nwPlayer[i] = p
            nwAPI.nw_sendToPlayer(i,p,i)
            msg = nwAPI.nw_receiveTextFromPlayer(i,nwPlayer[i])
            print("Accepting Player ",i, " Name=",msg)
            playerRootName[i] = msg
            playerName[i] = msg
            newPlayer = i
            connectedPlayer += 1
            nameSynced = false
        end
        so = connectedPlayer
        updated = false

        for s in 1:4
            if !(addingPlayer && s != newPlayer)
                if PlayerList[s] == plSocket
                    nwAPI.nw_sendToPlayer(s,nwPlayer[s],numberOfSocketPlayer)
                    nwAPI.nw_sendTextToPlayer(s,nwPlayer[s],version)
                    pversion = nwAPI.nw_receiveTextFromPlayer(s,nwPlayer[s])
                    println("Player ",playerName[s]," has version ",pversion)
                    if version > pversion
                        print("Sending updates to Player ", playerName[s])
                        updated = true
                        rf = open("tsGUI.jl","r")
                        while !eof(rf)
                            aline = readline(rf)
                            nwAPI.nw_sendTextToPlayer(s,nwPlayer[s],aline)
                        end
                        nwAPI.nw_sendTextToPlayer(s,nwPlayer[s],"#=Binh-end=#")
                        close(rf)
                        println(" ... done")
                    elseif pversion > version
                        wf = open("tsGUI.jl","w")
                        print("Receiving updates from Player ",playerName[s])
                        while true
                            aline = nwAPI.nw_receiveTextFromPlayer(s,nwPlayer[s])
                            if aline == "#=Binh-end=#"
                                break
                            end
                            println(wf,aline)
                        end
                        close(wf)
                        println(" ... done")
                        exit()
                    end
                    if so == 1
                        break
                    else
                        so -= 1
                    end
                end
            end
        end
        if updated
            println("WHAT??")
            exit()
        end
    elseif mode == m_client
        println("CLIENT")
        global nwMaster = nwAPI.clientSetup(serverURL,serverPort)
        if nwMaster == 0
            mode = m_standalone
            return
        end
        msg = nwAPI.nw_receiveFromMaster(nwMaster,8)
        println(msg)
        global myPlayer = msg[2]
        PlayerList[myPlayer] = plSocket
        if GUI
            noGUI_list[myPlayer] = false
        end
        println("Accepted as Player number ",myPlayer)
        playerRootName[myPlayer] = NAME
        playerName[myPlayer] = NAME
        nwAPI.nw_sendTextToMaster(myPlayer,nwMaster,playerName[myPlayer])
        println("Player List:",playerName)
        msg = nwAPI.nw_receiveFromMaster(nwMaster,8)
        global numberOfSocketPlayer = msg[2]
        println("numberOfSocketPlayer", numberOfSocketPlayer)
        sversion = nwAPI.nw_receiveTextFromMaster(nwMaster)
        nwAPI.nw_sendTextToMaster(myPlayer,nwMaster,version)
        println("Server has version ",sversion)
        if sversion > version
            print("Receiving updates from Server ... ")
            wf = open("tsGUI.jl","w")
            while true
                aline = nwAPI.nw_receiveTextFromMaster(nwMaster)
                if aline == "#=Binh-end=#"
                    break
                end
                println(wf,aline)
            end
            close(wf)
            println(" done")
            exit()
        elseif sversion < version
            print("Sending updates to Server ")
            rf = open("tsGUI.jl","r")
            while !eof(rf)
                aline = readline(rf)
                nwAPI.nw_sendTextToMaster(myPlayer,nwMaster,aline)
            end
            nwAPI.nw_sendTextToMaster(myPlayer,nwMaster,"#=Binh-end=#")
            close(rf)
            println(" ... done")
            exit()
        end
    end
end

function glbNameSync(myPlayer)
    global playerName, GUIname
    if mode == m_server
        for s in 1:4
            if PlayerList[s] == plSocket
                playerName[s] = nwAPI.nw_receiveTextFromPlayer(s,nwPlayer[s])
                playerRootName[s] = playerName[s]
            end
        end
        for s in 1:4
            if PlayerList[s] == plSocket
                for i in 1:4
                    nwAPI.nw_sendTextToPlayer(s,nwPlayer[s],playerName[i])
                end
            end
        end
    elseif mode == m_client
        nwAPI.nw_sendTextToMaster(myPlayer,nwMaster,playerName[myPlayer])
        for i in 1:4
            name = nwAPI.nw_receiveTextFromMaster(nwMaster)
            playerName[i] = name
            playerRootName[i] = playerName[i]

        end
    end
    nameRound(n)  = n > 4 ? n - 4 : n

    if !noGUI()
        nn = []
        for i in 1:4
            nn[i] = playerName[nameRound(myPlayer-1+i)]
        end
        setGUIname(nn)
    end
end

function doCardDeal()
    global bbox,bbox1,gameDeck, GUI_busy
    bbox = false
    bbox1 = false
  if mode != m_standalone && !noGUI()
      if okToPrint(0x1)
      println("GUI SYNC")
      end
      anewDeck = deepcopy(playersSyncDeck!(gameDeck))
      pop!(gameDeck,length(gameDeck))
      push!(gameDeck,anewDeck)
  end
  if okToPrint(0x1)
  println("ORGANIZE")
  end
  GUI_busy = false
    gsStateMachine(gsOrganize)
end
function testCntPlayCard()
    testDeck = TuSacCards.ordered_reduce_deck()
    for c in testDeck
        print(ts(c.value),"=",getCntPlayedCard(c.value)," ")
    end
    println()
end
function acquireCntPlayedCard()
    global PlayedCardCnt = zeros(UInt8,32)
    for as in all_assets
        for c in as
            updateCntPlayedCard(c)
        end
    end
    for as in all_discards
        for c in as
            updateCntPlayedCard(c)
        end
    end
end
function createCoin(type,player,coinsCnt)
    if type == 1
        coinActor = macOS ?  Actor("coin_b.png") : Actor("coin.png")
    else
        coinActor = macOS ?  Actor("coin1d_b.png") : Actor("coin1d.png")
    end
        mi = playerMaptoGUI(player)
        coinActor.pos =  mi == 1 ? tableGridXY(10+coinsCnt*1,15) :
                            mi == 2 ? tableGridXY(17,10+coinsCnt*1) :
                            mi == 3 ? tableGridXY(10+coinsCnt*1,5) :
                            tableGridXY(5,10+coinsCnt*1)
        push!(coins,coinActor)
end
"""
gsStateMachine(gameActions)

gsStateMachine: control the flow/setup of the game

states  --

    Flow of the card game is as follow:

    1) build gamedeck by calling ordered_deck
    2) function to mix up the card (multiple version), it can be autoShuffle
    or human-directed-shuffle (to emulate how human does it, not too random)
    3) dealCards: pretty simple, just like how the game supposed to deal, 1st
    player get 6-cards.  All subsequence deals, 5 cards each.
    4) now it goes to gameloop by running gamePlay1Iteration, each iteration is always
    fall-through (no-blocking), so that mouse/graphic still works.
    5) A round of game take 4 iterations, allowing async events (waiting for player
    to complete move) to complete.
        5a) The first part of the round, is after figuring who win the round and become the
        next player (done on previous iteration).
        On this iteration, a player is either play a card, or picking a card from the deck.
        a call is made to gamePlay() to get current play to play the card if needed "glNeedaPlayCard"

        5b) after get the playcard (glNewCard), it is send to other players on a non-blocking call to
        gamePlay() with the gpCheckMatch2/glCheckMatch1or2 command.  In this case,
        if player1 pick a card from the deck, then the round involves 4-player(1,2,3,4). If not, it
        only involves 3 players (1,2,3). All players works ASYNC and provide the results on the array "rQ" with
        ready bits "rReady". The code will spin on the same iteration waiting for rReady bits.  Human player control
        the GUI will select the card the "click_card" and entering his choice.  It will
        be slow and async to the bots players.
        Once all the results come in, whoWin is call to figure out who win the
        round.  It checks for legal move and final winning here too.
        5c + 5d) not much -- must moving cards from one pile to the others base on the
        result of the round. Here is where the cards GUI got updated,
        The purpose of breaking the round into 4 is to allow non-blocking, making call to 4
        players and getting data back asyncronously.

    6) The iteration will continue until the gameDeck become too small (9) or somebody win.

"""
function gsStateMachine(gameActions)
    global tusacState, all_discards, all_assets,prevWinner,haBai,coins,saveI,wantFaceDown
    global gameDeck, ad, deckState,gameEnd,HISTORY,currentAction,mode_human
    global nwPlayer,nwMaster,playerName,coldStart, FaceDown,shuffled,moveArray
    global playerA_hand,playerB_hand,playerC_hand,playerD_hand,RFaline, ActiveCard,tsActiveCard
    global playerA_discards,playerB_discards,playerC_discards,playerD_discards
    global playerA_assets,playerB_assets,playerC_assets,playerD_assets,khapMatDau
    global kpoints,khui,myPlayer,loadPlayer,isTestFile,tstMoveArray,PlayedCardCnt, points
    prevIter = 0
    if tusacState == tsSinitial
# -------------------A
        global mode
        cardCnt = zeros(UInt8,32)

        if gameActions == gsSetupGame
            global numberOfSocketPlayer
            global mode
            haBai = false
            shuffled = false
            if coldStart
                if !noGUI()
                    setGUIname(playerName)
                end
                thinNetworkInit()
                gameDeck = TuSacCards.ordered_deck()
            end
            if noGUI() == false
                global FaceDown = wantFaceDown
                deckState = setupDrawDeck(gameDeck,GUILoc[13,1], GUILoc[13,2], 14 ,  FaceDown)
                if coldStart
                    if (GENERIC == 1)
                        global handPic = Actor("hand4.png")
                        global winnerPic = Actor("winner2.png")
                    elseif GENERIC == 2
                        global handPic = Actor("hand31.png")
                        global winnerPic = Actor("winner21.png")
                    elseif GENERIC == 3
                        global handPic = Actor("hand31.png")
                        global winnerPic = Actor("winner21.png")
                    elseif GENERIC == 4
                        global handPic = Actor("hand2.png")
                        global winnerPic = Actor("winner2.png")
                    else
                        global handPic = Actor("hand.jpeg")
                        global winnerPic = Actor("winner2.png")
                    end
                    global baiThuiPic = Actor("bomb.jpeg")
                    global errorPic = TextActor("?!?","asapvar",font_size=fontSize*4,colorant="white")
                    bodoiStr = "Bo-Doi"
                    boDoiPic[1]  = TextActor(bodoiStr,"asapvar",font_size=fontSize,color=[0,0,0,0])
                    boDoiPic[2]  = TextActor(bodoiStr,"asapvar",font_size=fontSize,color=[0,0,0,0])
                    boDoiPic[3]  = TextActor(bodoiStr,"asapvar",font_size=fontSize,color=[0,0,0,0])
                    boDoiPic[4]  = TextActor(bodoiStr,"asapvar",font_size=fontSize,color=[0,0,0,0])
                end
           #     updateHandPic(prevWinner)
                updateWinnerPic(0)
                updateErrorPic(0)
                updateBaiThuiPic(0)
                for i in 1:4
                    updateboDoiPic(i,false)
                end

                if shuffled == false
                    randomShuffle()
               end
            else
                randomShuffle()
                #autoHumanShuffle(rand(4:8))
            end

            if mode != m_standalone && noGUI()
                anewDeck = deepcopy(playersSyncDeck!(gameDeck))
                pop!(gameDeck,112)
                push!(gameDeck,anewDeck)
            end
          #  println("anew",anewDeck)
            tusacState = tsSdealCards
            if  isTestFile
                doCardDeal()
            end
        end

# -------------------A

    elseif tusacState == tsSdealCards
# -------------------A
        global cardsIndxArr = []
        global GUI_ready = false
    #    if gameActions == gsOrganize
            if okToPrint(0x1)
                println("Prev Game Winner =", gameEnd)
            end
            global restartFlag = true
            prevWinner = gameEnd
            global gameEnd = 0
            global FaceDown = wantFaceDown
            tusacDeal(prevWinner)
            if okToPrint(0x5)
                println("\nDealing is completed,prevWinner=",prevWinner)
            end
            TuSacManager.init()
            global FaceDown = true
            TuSacManager.readServerTable(remoteMaster)
            coinsArr = TuSacManager.readRFCoins(remoteMaster)
            println("coins=",coinsArr)
            TuSacManager.printTable()
            all = TuSacManager.getTable()
            pHand,pAsset,pDiscard,pGameDeck,vHand,vAsset,vDiscard,vGameDeck = all
            global playerA_hand = pHand[1]
            global playerB_hand = pHand[2]
            global playerC_hand = pHand[3]
            global playerD_hand = pHand[4]
            global playerA_discards=pDiscard[1]
            global playerB_discards=pDiscard[2]
            global playerC_discards=pDiscard[3]
            global playerD_discards=pDiscard[4]
            global playerA_assets= pAsset[1]
            global playerB_assets= pAsset[2]
            global playerC_assets= pAsset[3]
            global playerD_assets= pAsset[4]

            gameDeck = pGameDeck
            getData_all_hands()
            getData_all_discard_assets()
            printAllInfo()

            coins = []
            global gameStart = true
      
            coinsCnt = 0
            for p in 1:4
                for i in 1:2
                    c = coinsArr[p][i]
                    if c > 0
                        m = c
                        while m > 0
                            createCoin(i,p,coinsCnt)
                            coinsCnt += 1
                            m -= 1
                        end
                    end
                end
            end

            global gameDeckArray = TuSacCards.toValueArray(gameDeck)
            replayHistory(0)
         

        global gameEnd = 0
        if okToPrint(0x1)
            println("Starting game, e-",gameEnd)
        end
        global currentAction = gpPlay1card
        global glNeedaPlayCard = true

        if coldStart
            global glPrevPlayer = 1
        else
            global glPrevPlayer = prevWinner
            global shufflePlayer = prevWinner ==  1  ? 4 : prevWinner - 1
        end
        global glIterationCnt = 0
        SNAPSHOT()
        tusacState = tsGameLoop
    elseif tusacState == tsGameLoop
        if gameActions == gsRestart
            tusacState = tsSinitial
            RESET1()
            RESET2()
            RESET3()
            global boDoiPlayers = [0,0,0,0]
            global allowPrint = stickyAllowPrint
            points = zeros(Int8,4)
            kpoints = zeros(Int8,4)
            khui = [1,1,1,1]
            khapMatDau = zeros(4)
            coldStart = false
            global FaceDown = wantFaceDown
            ActiveCard = 0
            saveI = 0
            all_assets = []
            all_discards = []
            HISTORY = []
            restartGame()
        else
            if length(gameDeckArray) >= gameDeckMinimum
                global atest
                global tstMoveArray
                if  isGameOver() == false
                    if  isTestFile && rem(glIterationCnt,4) == 0
                        if length(testList) > 0
                            atest = popfirst!(testList)
                            println("=========TEST===> ",atest)
                            readRFNsearch!(RF,atest[1])
                            glIterationCnt = parse(Int,SubString(atest[1],2)) << 2
                            mode_human = atest[2]
                            gameDeck = TuSacCards.ordered_deck()
                            a,tstMoveArray,RFaline = readRFDeck(RF,gameDeck)
                            playerSel = parse(Int,RFstates[3])
                            glPrevPlayer = myPlayer
                            glNeedaPlayCard = RFstates[2] == "true"
                            if length(RFstates) > 7
                                for i in 1:4
                                    println(RFstates[i+7])
                                    global aiTrait[i] = parse(Int,RFstates[i+7])
                                end
                                global aiType  = aiTrait .>> 2
                                println("aiTrait = ", aiTrait)
                                global playerName = setPlayerName(playerRootName,aiTrait)
                                setGUIname(playerName)
                            end
                            replayHistory(-1,a,playerSel)
                            acquireCntPlayedCard()
                        else
                            if isTestFile
                                isTestFile = false
                                if !trial
                                    exit()
                                end
                            end
                        end
                    end
                    gamePlay1Iteration()
                    if rem(glIterationCnt,4) == 0
                        SNAPSHOT(atest)
                        moveArray = zeros(Int,16,3)
                        socketSYNC()
                    end
                else
                    GUI && sleep(.5)
                end
            else
                global match += 1
                openAllCard = true
                println("Bai Thui: DECK=",(gameDeckArray,gameDeck))
                updateBaiThuiPic(1)
                gameOver(5)
                pointsCalc(5)
                glIterationCnt += 50
            end
        end
    elseif tusacState == tsRestart

    end
end
"""
    socketSYNC()
        sync point for all socket players, ... global command can be
            inserted here.
TBW
"""
function socketSYNC()
    global nameSynced,mode_human,PlayerList,
    playerName,connectedPlayer,nwMaster, wantFaceDown

    if numberOfSocketPlayer == 0
        if haBai
            println("Ha-bai")
            gameOver(prevWinner)
        elseif nameSynced == false
            println("Doing name sync, new name = ", playerName[myPlayer])
            if length(playerName[myPlayer]) > 2 && SubString(playerName[myPlayer],1,3) == "Bot"
                mode_human = false
                PlayerList[myPlayer] = plBot1

            else
                mode_human = true
                PlayerList[myPlayer] = plHuman

            end
            nameSynced = true
        end
    else
        if (PlayerList[myPlayer] != plSocket) && isServer()
            msg = Vector{String}(undef,4)
            for p in 1:4
                if PlayerList[p] == plSocket
                    msg[p] = nwAPI.nw_receiveTextFromPlayer(p, nwPlayer[p])
                end
            end
            gmsg ="."
            for p in 1:4
                if PlayerList[p] == plSocket
                    if msg[p] !="."
                        gmsg = msg[p]
                    end
                end
            end
            println(gmsg)
            needFDsync = !wantFaceDown  && !faceDownSync
            smsg = haBai ? "H" : !nameSynced ? "N" : needFDsync ? "F" : gmsg

            for p in 1:4
                if PlayerList[p] == plSocket
                    println("S-sending ", smsg)
                    nwAPI.nw_sendTextToPlayer(p, nwPlayer[p],smsg)
                end
            end
            if smsg == "H"
                gameOver(prevWinner)
            elseif smsg == "F"
                wantFaceDown = false
            elseif smsg == "N"
                glbNameSync(myPlayer)
                if length(playerName[myPlayer]) > 2 &&  SubString(playerName[myPlayer],1,3)  == "Bot"
                    mode_human = false
                else
                    mode_human = true
                end
                for p in 1:4
                    if PlayerList[p] == plSocket
                        println((p,playerName[p]))
                        if length(playerName[p]) > 3 && SubString(playerName[p],1,4) == "QBot"
                            connectedPlayer -= 1
                            PlayerList[p] = plBot1
                        end
                    end
                end
                nameSynced = true
            end
        elseif PlayerList[myPlayer] == plSocket
            needFDsync = !wantFaceDown  && !faceDownSync
            smsg = haBai ? "H" : !nameSynced ? "N" : needFDsync ? "F" : "."

            println("c-sending ", smsg)
            nwAPI.nw_sendTextToMaster(myPlayer, nwMaster,smsg)
            myMsg = nwAPI.nw_receiveTextFromMaster(nwMaster)
            println("receiving ",myMsg)
            if myMsg == "H"
                gameOver(prevWinner)
            elseif smsg == "F"
                wantFaceDown = false
            elseif myMsg == "N"
                glbNameSync(myPlayer)
                if  length(playerName[myPlayer]) > 2 && SubString(playerName[myPlayer],1,3) == "Bot"
                    mode_human = false
                elseif length(playerName[myPlayer]) > 2 &&  SubString(playerName[myPlayer],1,3)  == "QBo"
                    exit()
                else
                    mode_human = true
                end
                nameSynced = true
            end
            println(myMsg)
        end
    end
end
function randomShuffle()
    TuSacCards.shuffle!(gameDeck)
end
#=
game start here
=#
function autoHumanShuffle(n)
    if okToPrint(0x1)
        println("\nAUTO-HUMAN-SHUFFLE")
    end
    for i in 1:n
        rl = rand(17:23)
        rh = rand(37:43)
        sh = rand(0:1) > 0 ? rl : rh
        TuSacCards.humanShuffle!(gameDeck,14,sh)
    end
end

gsStateMachine(gsSetupGame)

function RESET2()
    global BIGcard = 0
    global ActiveCard = 0
    global prevActiveCard = 0
    global cardSelect = false
    global playCard = 0
end
global lsx,lsy

RESET2()
if noGUI()
    gsStateMachine(gsOrganize)
end

function on_mouse_move(g, pos)
    global tusacState, gameDeck, ad, deckState
    """
    MouseOnBoxShuffle:

        for a given box, check to see if mouse x,y is on box. Plus,
        check to see if mouse direction is Horizontal or  Vertical. it
        is done by state machine a[6]:
            0: initial state, after draw the first time, init x0,y0, x1,y1 to -1 --> 1:
            1: check to see if within box, set x0,y0 --> 2:
            2: check if within box still. If it is, set x1,y1 --> 2:   If not,
            Now, calculate the direction, compare x1 vs x0, and y1 vs y0 -->
            x1 > x0 --> +x 3:
            x1 < x0 --> -x 4:
            similarly for 5: 6:
                abs(x1-x0) vs abs(y1-y0) determines 20+/- or 40+/- as (+x,-x,+y,-y)
                if along the x/y direction (+ or -), gradien_size is factor in
            20+/- or 40+/-: -> no change after this.  It will go back to 0: after someone check/restart
    """
    function mouseDirOnBox(x, y, Bs)
        if Bs[5] == 0
            Bs[5] = 1
        elseif Bs[5] == 1
            if (Bs[1] < x < Bs[3]) &&
               (Bs[2] < y < Bs[4])
                Bs[6], Bs[7] = x, y
                Bs[5] = 2
            end
        elseif Bs[5] == 2
            if (
                (Bs[1] < x < Bs[3]) &&
                (Bs[2] < y < Bs[4])
            ) == false
                Bs[8], Bs[9] = x, y
                deltaX = Bs[8] - Bs[6]
                deltaY = Bs[9] - Bs[7]
                calGradien(a, b, loc, gradien_size) =
                    div(gradien_size * (loc - a), b - a)
                if abs(deltaX) < abs(deltaY)
                    g = calGradien(
                        Bs[1],
                        Bs[3],
                        Bs[6],
                        cardGrid,
                    )
                    deltaX > 0 ? Bs[5] = 40 + g : Bs[5] = 40 - g
                else
                    g = calGradien(
                        Bs[2],
                        Bs[4],
                        Bs[7],
                        cardGrid,
                    )
                    deltaY > 0 ? Bs[5] = 20 + g : Bs[5] = 20 - g
                end
            end
        end
    end
    function withinBoxes(x, y, boxes)
      #  println("m,x=",(modified_cardXdim,cardXdim))
        for (i, b) in enumerate(boxes)
            if b[1] < x < b[3] && b[2] < y < b[4]
                rx = div((x - b[1]), modified_cardXdim) + 1
                ry = div((y - b[2]), modified_cardYdim)
                cardId = ry * b[10] + rx
                return i, cardId
            end
        end
        return 0, 0
    end
    ####################
    x = pos[1] << macOSconst
    y = pos[2] << macOSconst

    if showLocation
        println((x,y,reverseTableGridXY(x,y)))
    end
    if tusacState == tsSdealCards

        if myPlayer == shufflePlayer
            mouseDirOnBox(x, y, deckState)
        end
    elseif tusacState > tsSstartGame && tusacState <= tsGameLoop

        boxId, cardIndx = withinBoxes(x, y, boxes)
        if boxId > 0
            if isGameOver() == false && boxId > 9
                boxId = 0
            end
        end

        if boxId == 0
            v = 0
        elseif boxId == 1
            v = TuSacCards.getCards(playerA_hand, cardIndx)
        elseif boxId == 2
            v = TuSacCards.getCards(playerA_discards, cardIndx)
        elseif boxId == 3
            v = TuSacCards.getCards(playerB_discards, cardIndx)
        elseif boxId == 4
            v = TuSacCards.getCards(playerC_discards, cardIndx)
        elseif boxId == 5
            v = TuSacCards.getCards(playerD_discards, cardIndx)
        elseif boxId == 6
            v = TuSacCards.getCards(playerA_assets, cardIndx)
        elseif boxId == 7
            v = TuSacCards.getCards(playerB_assets, cardIndx)
        elseif boxId == 8
            v = TuSacCards.getCards(playerC_assets, cardIndx)
        elseif boxId == 9
            v = TuSacCards.getCards(playerD_assets, cardIndx)
        elseif boxId == 10
            v = TuSacCards.getCards(playerB_hand, cardIndx)
        elseif boxId == 11
            v = TuSacCards.getCards(playerC_hand, cardIndx)
        elseif boxId == 12
            v = TuSacCards.getCards(playerD_hand, cardIndx)
        else
            v = TuSacCards.getCards(gameDeck, cardIndx)
        end
        if v != 0
            m = mapToActors[v]
        else
            m = 0
        end

        global BIGcard = m
    elseif tusacState == tsRestart

    end
end

function mouseDownOnBox(x, y, boxState)
    loc = 0
    up = 0
    if (boxState[1] < x < boxState[3]) && ((boxState[2] < y < boxState[4]))
        dx = div((x - boxState[1]), modified_cardXdim)
        dy = div((y - boxState[2]), cardYdim)
        up = rem((y - boxState[2]), cardYdim)
        up = div(up, div(cardYdim, 2))
        loc = div((boxState[3] - boxState[1]), modified_cardXdim) * dy + dx + 1
    end
    return loc, up
end

actionStr(a) =
    a == gpPlay1card ? "gpPlay1card" :
    a == gpCheckMatch1or2 ? "gpCheckMatch1or2" :
    a == gpCheckMatch2 ? "gpCheckMatch2" : "gpPopCards"



function strToVal(hand, str)
    grank = "Tstcxpm"
    gcolor = "TVDX"
    function find1(c, str)
        for i = 1:length(str)
            if c == str[i]
                return i
            end
        end
        return 0
    end
aStrToVal(s) =
(UInt8(find1(s[1], grank)) << 2) | (UInt8(find1(s[2], gcolor) - 1) << 5)

    local r = []
    for s in str
        v = aStrToVal(s)
        for i = 1:length(hand)
            c = hand[i]
            found = false
            for ar in r
                if ar == c
                    found = true
                end
            end
            if !found && card_equal(c, v)
                push!(r, c)
                break
            end
        end
    end
    return r
end

function keyboardInput(gpPlayer)
    global GUI_array, GUI_ready
    local al = readline()
    if length(al) > 1
        local rl = split(al, ' ')
        local card = strToVal(all_hands[gpPlayer], rl)
    else
        card = []
    end
    return card
end

function humanInput()
    testDeck = TuSacCards.toValueArray(TuSacCards.ordered_deck())
    local al = readline()
    if length(al) > 1
        local rl = split(al, ' ')
        local card = strToVal(testDeck, rl)
    else
        card = []
    end
    return card
end

global rf1,rf2,rf3,rf4
function failCheckPoint(dArray,all_hands,all_assets,all_discards)
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

"""
chk2(playCard) check for pairs -- also check for P XX ? M

"""
function chk2(playCard;win=false)
    global coDoiCards
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
                    return []  # SAKI -- return nothing
                else
                    if p == 1
                        if length(coDoiCards) == 0
                            if okToPrint(0x8)
                                println("chk2-codoi-",ap)
                            end
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
        ar = union(deadCards[player],all_assets[player],
        all_discards[player],all_discards[prevPlayer(player)])
    else
        ar = union(deadCards[player],
        all_discards[player],all_discards[prevPlayer(player)])
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
        if okToPrint(4)
            println("---->",(ts(s),m))
        end
    end
    if okToPrint(4)
    println((ts(card),max))
    end
    return card
end
nDead=[[],[],[],[]]
highValue = zeros(UInt8,4)

function mapAI(ai,trashCnt)
    
    if trashCnt >= 5
        if ai == 5
            localAI = 1
        elseif ai == 6
            localAI = 2
        elseif ai == 7
            localAI = 3
        end
    else
        if ai == 5
            localAI = 3
        elseif ai == 6
            localAI = 4
        elseif ai == 7
            localAI = 4
        end
    end
    return localAI
end
function gpHandlePlay1Card(player)
    gl = glIterationCnt >> 2
    erc = TuSacManager.play1Card(player)

    trashCnt = length(singles)+length(missTs)+length(miss1s)+length(chot1s)
    pairsCnt = length(allPairs[1])+length(allPairs[2])+length(allPairs[3])
   

    ai = aiType[player]
    localAI = ai
   # localAI = mapAI(ai,trashCnt)
    println("Local AI = ",(ai,localAI))

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
        println("=====dfT=",emBaiTrigger[player]," player= $player=$gl ===========================================")
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
        println("$player==$gl=================================================")
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
    okToPrint(0x20) &&  println("player$player cardinfo:  ",(ts(card),tcard),(ts(maxc),max))

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
            okToPrint(0x20) && print("sap het rac, try to win  ",gameTrashCntLatest[player])

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
            okToPrint(0x20) && print("Player$player nhieu rac -- give up ",gameTrashCntLatest[player])
            return true
        end
        if r1+r2 == 0
            elevateDead[player] = 0
            return false
        elseif r1 != 0 && r2 != 0
            elevateDead[player] = r1
            okToPrint(0x20) && print(" Too many Triggers ",gameTrashCntLatest[player])
                return true
        end
        nDead[player] =[]
        elevateDead[player] = t = r1

      #  if true || getCardFromDeck
        if t > 0 && findDeadCard(t,pc,dc_target)  == false
            ci = cardInfo(pc,player)
            okToPrint(0x20) && println("ci = ",(ci[1],ci[2]),ts(ci[3]))
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
maxAssets() = max(length(all_assets[1]),length(all_assets[2]),length(all_assets[3]),length(all_assets[4]))


function gpHandleMatch2Card(pcard,player)
    erc = TuSacManager.Match2Card(pcard,player)

    card1 = chk1(pcard)
    card2 = chk2(pcard)
    ls = length(singles)
    lmt = length(missTs)
    lm1s = length(miss1s)
    lc1s = length(chot1s)
    gameTrashCntLatest[player] = ls + lmt + lm1s + lc1s
    if glIterationCnt < 10
        global gameTrashCnt,gameTrashCntLatest
        if gameTrashCnt[player] == 0
            gameTrashCnt[player] = ls + lmt + lm1s + lc1s
        end
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
    return rc

end
function gpHandleMatch1or2Card(pcard,player)
     erc = TuSacManager.Match1or2Card(pcard,player)

    card1 = chk1(pcard)
    card2 = chk2(pcard)
    ls = length(singles)
    lmt = length(missTs)
    lm1s = length(miss1s)
    lc1s = length(chot1s)
    gameTrashCntLatest[player] = ls + lmt + lm1s + lc1s

    if glIterationCnt < 10
        global gameTrashCnt,gameTrashCntLatest
        if gameTrashCnt[player] == 0
            gameTrashCnt[player] = ls + lmt + lm1s + lc1s
        end
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

    return rc
end

"""
hgamePlay:
    actions: 0 - inital cards dealt - before any play
             1 - play a single card, player choise
             2 - check for match single/double; return matched
             3 - check for match double only; return matched
             4 - play cards -- these cards
    game-manager will control the flow of the game, calling each
    player for actions/reponse and maintaining all card-decks

"""
function hgamePlay(
    all_hands,
    all_discards,
    all_assets,
    gameDeck,
    pcard;
    gpPlayer = 1,
    gpAction = 0,
    rQ,
    rReady
)

    global rQ, rReady, coDoiPlayer, coDoiCards, GUI_ready, GUI_array, GUI_busy,
    currentCards,currentAction, currentPlayCard, FaceDown,gameEnd,wantFaceDown
    if(gpPlayer==myPlayer)
        currentAction = gpAction
        if playerIsHuman(myPlayer)
            GUI_busy = false
            GUI_ready = false
            GUI_array = []
        end
    end
    global openAllCard = !FaceDown
    currentPlayCard = pcard
    global FaceDown = !isGameOver() && wantFaceDown
    if gpPlayer == 1
        global human_state = setupDrawDeck(playerA_hand, GUILoc[1,1], GUILoc[1,2], GUILoc[1,3],  false)
        discard1 = setupDrawDeck(playerA_discards,GUILoc[9,1], GUILoc[9,2], GUILoc[9,3],  false)
        asset1 = setupDrawDeck(playerA_assets, GUILoc[5,1], GUILoc[5,2], GUILoc[5,3], false,true)

    elseif gpPlayer == 2
        setupDrawDeck(playerB_hand, GUILoc[2,1], GUILoc[2,2], GUILoc[2,3], FaceDown)
        discard2 = setupDrawDeck(playerB_discards, GUILoc[10,1], GUILoc[10,2],GUILoc[10,3],  false)
        asset2 = setupDrawDeck(playerB_assets, GUILoc[6,1], GUILoc[6,2],GUILoc[6,3],  false,true)

    elseif gpPlayer == 3
        setupDrawDeck(playerC_hand, GUILoc[3,1], GUILoc[3,2], GUILoc[3,3], FaceDown)
        discard3 = setupDrawDeck(playerC_discards, GUILoc[11,1], GUILoc[11,2],GUILoc[11,3],  false)
        asset3 = setupDrawDeck(playerC_assets, GUILoc[7,1], GUILoc[7,2], GUILoc[7,3], false,true)
    else
        setupDrawDeck(playerD_hand, GUILoc[4,1], GUILoc[4,2], GUILoc[4,3], FaceDown)
        discard4 = setupDrawDeck(playerD_discards, GUILoc[12,1], GUILoc[12,2],GUILoc[12,3],  false)
        asset4 = setupDrawDeck(playerD_assets, GUILoc[8,1], GUILoc[8,2], GUILoc[8,3], false,true)

    end

    rReady[gpPlayer] = false
    rQ[gpPlayer] = []
    if okToPrint(0x8)
        print(
            "$glPrevPlayer==$glIterationCnt====================player",
            gpPlayer,
            " Action=",
            actionStr(gpAction))
            if gpAction != gpPlay1card
                println(" checkCard=",
                ts(pcard))
            end
    end
   global allPairs, singles, chot1s, miss1s, missTs, miss1sbar,chotPs,chot1Specials, suitCnt,miss1_1,miss1_2 = scanCards(all_hands[gpPlayer])
    if gpAction == gpPlay1card
        ll = length(singles) + length(chot1s) + length(miss1s) + length(missTs)
        if ll == 0 && glIterationCnt == 1
            println("over----")
            gameOver(gpPlayer)
            pointsCalc(gpPlayer)
        end
        a = glIterationCnt >> 2
        @assert !(ll == 0  && glIterationCnt > 1) "no more trash, ll=$ll iteration=$a"
        coDoiPlayer = 0
        coDoiCards = []
        global boDoi = 0
        global bp1BoDoiCnt = 0
        cards = gpHandlePlay1Card(gpPlayer)
        if okToPrint(0x1)
            println("--",(playerIsHuman(gpPlayer),humanIsGUI,GUI_ready,GUI_array))
        end
    rReady[gpPlayer] = false

        #--------------------------------------HERE
    elseif gpAction == gpCheckMatch1or2
        cards = gpHandleMatch1or2Card(pcard,gpPlayer)
    else
        cards = gpHandleMatch2Card(pcard,gpPlayer)
    end
    if okToPrint(0x8)
        if length(cards) == 3
            print("--------->>>>")
        end
        println("rc=",cards," --  ", ts(cards))
        println(ts(coDoiCards)," ",coDoiPlayer)
    end
    if length(coDoiCards) == 2 && coDoiPlayer == 0
         if( length(cards) != 2 || !card_equal(cards[1],cards[2]))
            if okToPrint(0x8)
                println("POSS BODOI ", (gpPlayer, ts(coDoiCards)),ts(cards))
            end
            coDoiPlayer = gpPlayer
        else
            coDoiCards = []
        end
    end
    if !playerIsHuman(gpPlayer)
        rQ[gpPlayer]=cards
        rReady[gpPlayer] = true
    end
    currentCards = cards
    return
end

function restoreDeck(deck,ar)
    deck = []
    for a in ar
        push!(deck,ts(a))
    end
end

function printHistory(n)
    ar = HISTORY[n]
        for i in 1:length(ar)-1
           println(ar[i])
        end
end


function adjustCnt(cnt,max,dir)
    if dir == 0
        cnt -= 1
        cnt = cnt < 1 ? 1 : cnt
    elseif dir == 1
        cnt -= 4
        cnt = cnt < 1 ? 1 : cnt
    elseif dir == 3
        cnt += 4
        cnt = cnt > max ? max : cnt
    else
        cnt += 1
        cnt = cnt > max ? max : cnt
    end
    return cnt
end

function restartGame()
    global gameDeck,prevWinner,currentPlayer,HF,histFILENAME
    global FaceDown = false
    global coldStart = false
    if histFile
        close(HF)
        global hfName = nextFileName(histFILENAME,chFilenameStr)
        HF = open(hfName,"w")
        println(HF,"#")
        println(HF,"#")
        println(HF,"#")
        histFILENAME = hfName
    end
    currentPlayer = prevWinner
        newDeck = (union(
            playerA_hand,
            playerA_assets,
            playerA_discards,

            playerB_hand,
            playerB_assets,
            playerB_discards,

            playerC_hand,
            playerC_assets,
            playerC_discards,

            playerD_hand,
            playerD_assets,
            playerD_discards,
            gameDeck))
            gameDeck =TuSacCards.Deck(newDeck)
            pop!(playerA_assets,length(playerA_assets))
            pop!(playerB_assets,length(playerB_assets))
            pop!(playerC_assets,length(playerC_assets))
            pop!(playerD_assets,length(playerD_assets))

            pop!(playerA_discards,length(playerA_discards))
            pop!(playerB_discards,length(playerB_discards))
            pop!(playerC_discards,length(playerC_discards))
            pop!(playerD_discards,length(playerD_discards))


        prevWinner = gameEnd > 4 ? prevWinner : gameEnd
        currentPlayer = prevWinner
        tusacState = tsSinitial
        gsStateMachine(gsSetupGame)
end
function isMoreTrash(cards,hand)
    okToPrint(0x10) && println("trashCnt")

    allPairs, singles, chot1s, miss1s, missTs, miss1sbar,chotPs,chot1Specials =
scanCards(hand, false)
    TrashCnt = length(chot1s)
    thand = deepcopy(hand)
    for e in cards
        filter!(x -> x != e, thand)
    end
    ps, ss, cs, m1s, mts, mbs,cp,cspec = scanCards(thand, true)
    l = length(cs)
    if TrashCnt < l
        if okToPrint(0x8)
        println("Illegal match -- creating more trash ",(TrashCnt,l))
        ts_s(chot1s)
        ts_s(cs)
        end
    end
    return TrashCnt < l
end
termCnt = 0

"""
    restartGameAt( loc)

restart the game at iteration-cnt
"""
function restartGameAt(loc)
    println()
    resize!(HISTORY,loc)
    l = length(HISTORY)
    replayHistory(loc,HISTORY[loc])
    acquireCntPlayedCard()
    #testCntPlayCard()
    checksum()
    println()
    global gameEnd = 0
    global baiThui = false
    global gameStart = true
    global points = zeros(Int8,4)
    global kpoints = zeros(Int8,4)
   # RESET1()

    if GUI
        updateWinnerPic(0)
        updateBaiThuiPic(0)
        for i in 1:4
            updateboDoiPic(i,false)
        end
    end
    global tusacState = tsGameLoop
end

function on_key_down(g)
    global tusacState, gameDeck, mode_human,Pre_haBai,haBai,shuffled,mode,bbox,bbox1,FaceDown,
    playerA_hand,
    playerB_hand,
    playerC_hand,
    playerD_hand,
    playerA_assets,
    playerB_assets,
    playerC_assets,
    playerD_assets,
    playerA_discards,
    playerB_discards,
    playerC_discards,
    playerD_discards,nameSynced,
    histFile,reloadFile,numberOfSocketPlayer, termCnt
        if g.keyboard.Q
            if mode == m_server
                println("Server can not quit! -- game will be terminated")
                if termCnt > 2
                    exit()
                end
                termCnt += 1
            elseif mode == m_client
                println("Quit... waiting to sync")
                playerName[myPlayer] = string("QBot-",myPlayer)
                nameSynced = false
            end
        elseif g.keyboard.A
            if mode_human == true
                playerName[myPlayer] = string("Bot-",NAME,aiTrait[myPlayer])
            else
                playerName[myPlayer] = NAME
            end
            println("Attempting to switch human-mode from ", mode_human, playerName[myPlayer])
            nameSynced = false
        end

        if tusacState == tsSdealCards && g.keyboard.enter
            doCardDeal()
            gsStateMachine(gsOrganize)
        elseif tusacState == tsSdealCards
            if g.keyboard.S
                shuffled = true
                autoHumanShuffle(4)
                setupDrawDeck(gameDeck, GUILoc[13,1], GUILoc[13,2], 14, FaceDown)
            elseif g.keyboard.T
                mode_human = !mode_human
                if mode_human == false
                    playerName[myPlayer] = string("Bot",myPlayer)
                    nameSynced = false
                end
                println("-switching human mode to ",mode_human)
            elseif g.keyboard.C
                if mode == m_standalone
                    println("Making connection to server at", serverURL)
                    mode = m_client
                    networkInit()
                    if mode == m_client
                        if histFile
                            close(HF)
                            histFile = false
                        end
                    end
                end
            elseif g.keyboard.M
                if mode == m_standalone || mode == m_server
                    println("Setting up to connect more Player")
                    mode = m_server
                    numberOfSocketPlayer += 1
                    networkInit()
                end
            elseif g.keyboard.B
                println("Bai no tung!, (random shuffle) ")
                randomShuffle()
                shuffled = true
                setupDrawDeck(gameDeck, GUILoc[13,1], GUILoc[13,2], 14, FaceDown)
            end
        elseif tusacState == tsHistory
            if  g.keyboard.M
                println("Exiting History mode @",HistCnt)
                restartGameAt(HistCnt)
            elseif g.keyboard.SPACE || g.keyboard.X
                println("Exiting History mode")
                l = length(HISTORY)
                replayHistory(l,HISTORY[l])
                tusacState = tsGameLoop
            else
                dir = g.keyboard.LEFT ? 0 : g.keyboard.UP ? 1 : g.keyboard.RIGHT ? 2 : 3
                global HistCnt = adjustCnt(HistCnt,length(HISTORY),dir)
                replayHistory(HistCnt,HISTORY[HistCnt])
                okToPrint(8) && printAllInfo()
                println("(",(HistCnt-1))
            end
    elseif tusacState == tsGameLoop
        if g.keyboard.R
            checkForRestart()

        elseif g.keyboard.X
            SNAPSHOT() #taking last SNAPSHOT
            HistCnt = length(HISTORY)
            tusacState = tsHistory
            println("Xet bai, coi lai bai,  History mode, size=",HistCnt)
        elseif g.keyboard.H
            println("Ha Bai!!!")
            Pre_haBai = true
        end
    end
end

function click_card(cardIndx, yPortion, hand)
    global prevYportion, cardsIndxArr
    if cardIndx in cardsIndxArr
        # moving these cards
        if yPortion != prevYportion
            cardsIndxArr = []
            setupDrawDeck(hand, GUILoc[1,1], GUILoc[1,2],GUILoc[1,3], false)
            println("RESET")
            cardSelect = false
            return []
        elseif yPortion > 0
            sort!(cardsIndxArr)
            TuSacCards.rearrange(hand, cardsIndxArr, cardIndx)
            setupDrawDeck(hand, GUILoc[1,1], GUILoc[1,2], GUILoc[1,3], false)
            cardSelect = false
            cardsIndxArr = []
        end
    else
        m = mapToActors[TuSacCards.getCards(hand, cardIndx)]
        x, y = actors[m].pos
        global deltaY = yPortion > 0 ? 50 : -50
        actors[m].pos = x, y + deltaY
        push!(cardsIndxArr, cardIndx)
        cardSelect = true
    end
    global prevYportion = yPortion
end

function badPlay1(cards,player, hand,action,botCards,matchC)
    global bp1BoDoiCnt
    allPairs, singles, chot1s, miss1s, missTs, miss1sbar,chotPs,chot1Specials =
    scanCards(hand, false)
    if action == gpPlay1card
        for ps in allPairs
            for p in ps
                if length(p) == 3
                    return card_equal(p[1],cards[1])
                end
            end
        end
        return (length(cards) != 1) || is_T(cards[1])
    end
    if length(cards) == 0
        for ps in allPairs[1]
            if card_equal(ps[1],matchC[1])
                for mb in miss1sbar
                    if card_equal(ps[1],mb) && !is_Tst(mb)
                        println("saki case,, mb =", ts(mb))
                        return false
                    end
                end
                if is_c(ps[1]) && length(chot1Specials)==2
                    return false
                end
                bp1BoDoiCnt += 1
                if bp1BoDoiCnt > 1
                    return false
                else
                    return true
                end
            end
        end
        for ps in allPairs[2]
            if card_equal(ps[1],matchC[1])
               return true
            end
        end
    else
        if okToPrint(0x80)
            println("badplay1",(cards,matchC))
        end
        for ps in allPairs[2]
           for c in cards
                if card_equal(c,ps[1])
                    if length(cards) == 3 &&
                        card_equal(cards[2],cards[3]) &&
                        card_equal(cards[2],cards[1])
                       # return false
                    else
                        return true
                    end
                end
           end
        end
        newHand = sort(cat(matchC,cards;dims=1))
        aps, ss, cs, m1s, mTs, m1sb,cPs,c1Specials = scanCards(newHand, true)
        if (length(ss)+length(cs)+length(m1s)+length(mTs)) > 0
            println(ts(newHand))
            println((aps, ss, cs, m1s, mTs, m1sb,cPs,c1Specials))
            println("LOUSY PLAY")
            return true
        end
        newHand = deepcopy(hand)
        for e in cards
            filter!(x -> x != e, newHand)
        end
        aps, ss, cs, m1s, mTs, m1sb,cPs,c1Specials = scanCards(newHand, false)
        r0 = (length(ss)+length(cs)+length(m1s)+length(mTs))
        r1 = (length(singles)+length(chot1s)+length(miss1s)+length(missTs))
        if okToPrint(0x10)
            print("Checking for more trash than previous: ")
            print((length(ss),length(cs),length(m1s),length(mTs)))
            println((length(singles),length(chot1s),length(miss1s),length(missTs)))
        end
        return r0 > r1
    end
    return false
end
function foundSaki(card,miss1sbar,csps)
    for m in miss1sbar
        if card_equal(card,m) && !is_Tst(m)
            return true
        end
    end
    if is_c(card) && length(csps) == 2
        return true
    end
    return false
end
function badPlay(cards,player, hand,action,botCards,matchC)
    if badPlay1(cards,player, hand,action,botCards,matchC)
        if okToPrint(0x80)
            println("badPlay1 reject")
        end
        return true
    end
    if length(matchC) > 0
        pcard = matchC[1]
    else
        pcard = matchC
    end
    if okToPrint(0x10)
    print("Chk GUI ,matchcard ",(ts(pcard)," -- ", cards, " == ", "action=",action))
    ts_s(hand)
    ts_s(cards)
    end
    allPairs, singles, chot1s, miss1s, missTs, miss1sbar,chotPs,chot1Specials =
    scanCards(hand, false)
    allfound = true
    for c in cards
        found = false
        for h in hand
            if c == h
                found = true
                break
            end
        end

        allfound = allfound && found
        if action != gpPlay1card
            for t in allPairs[2]
                if card_equal(pcard,t[1])
                    if length(cards) != 3 || !card_equal(cards[1],t[1]) || !card_equal(cards[2],t[1]) || !card_equal(cards[3],t[1])
                        return true
                    end
                end
            end
        end
    end
    if !allfound
        return true
    end

    if action == gpPlay1card
        return (length(cards) != 1) || is_T(cards[1])
    else
        all_in_pairs = true
        all_in_suit = true
        if length(cards) > 0
            if card_equal(pcard,cards[1])
                if length(cards) == 1
                    return(is_T(pcard))
                end
                for c in cards
                    all_in_pairs = all_in_pairs && card_equal(pcard,c)
                end
                all_in_pairs = all_in_pairs && !(length(cards)==2 && is_T(pcard))
                if !all_in_pairs
                    if okToPrint(0x8)
                    println(cards," not pairs")
                    end
                    return true
                end
                if (length(cards) == 2) # check for SAKI
                    ps, ss, cs, m1s, mts, mbs = scanCards(hand, true)
                    for m in mbs
                        if card_equal(m,cards[1]) && !is_Tst(m)
                            if okToPrint(0x8)
                            println("match ",ts_s(cards)," is SAKI, not accepted")
                            end
                            return true
                        end
                    end
                end
                if length(cards) > 1
                    if !is_c(pcard)
                        all_in_suit= card_equal(pcard, missPiece(cards[1],cards[2]))
                    else
                        all_in_suit = all_chots(cards,pcard)
                    end
                    if okToPrint(0x8)  && !all_in_suit
                        println(cards," is not in suit")
                    end
                else
                    if okToPrint(0x8)
                    println(cards, " not pairs or in-suit")
                    end
                    return true
                end
            end
        end
        moreTrash = false
        if okToPrint(0x8)
        ts_s(hand)
        end

        if is_c(pcard) || length(cards) == 0
            # check for bo doi
            if length(cards) == 0
                for ps in allPairs
                    for p in ps
                        if card_equal(p[1],pcard)
                            if length(p) == 3
                                    return true
                               # end
                            end
                            if length(p) == 2
                                if !foundSaki(pcard,miss1sbar,chot1Specials) && !isMoreTrash(cards,hand)
                                    if okToPrint(0x8)
                                        println(("BO DOI",boDoi))
                                    end
                                    global boDoi += 1
                                    if boDoi > 1
                                        boDoi = 0
                                        return false
                                    else
                                        return true
                                    end
                                end
                            end
                        end
                    end
                end
                if okToPrint(0x8)
                println("bot-cards=",botCards)
                end
                if hints > 0 && length(botCards) > 0
                    if (action == gpCheckMatch2 && length(botCards) > 1 && card_equal(botCards[1],botCards[2]))||
                       (action == gpCheckMatch1or2)
                        global boDoi += 1
                        if boDoi > 1
                            boDoi = 0
                            return false
                        else
                            return true
                        end
                    end
                end
            elseif length(cards) < 3
                moreTrash = isMoreTrash(cards,hand)
            end
        end
        if okToPrint(0x8)
        println("p,s,t",(all_in_pairs ,all_in_suit,moreTrash))
        end
        return !( all_in_pairs || all_in_suit) || moreTrash
    end
end

function checkForRestart()
    if isGameOver()
        if numberOfSocketPlayer > 0
            if isServer()
                so = numberOfSocketPlayer
                for p in 2:4
                    if PlayerList[p] == plSocket
                        nwAPI.nw_sendTextToPlayer(p,nwPlayer[p],"restart")
                        if so == 1
                            break
                        else
                            so -= 1
                        end
                    end
                end
                gsStateMachine(gsRestart)
            else
                msg = nwAPI.nw_receiveTextFromMaster(nwMaster)
                if msg == "restart"
                    gsStateMachine(gsRestart)
                end
            end
        else
            println(remoteMaster,"Restart")
            gsStateMachine(gsRestart)

        end
    end
end

"""
    on_mouse_down(g, pos)

"""
function on_mouse_down(g, pos)
    global cardsIndxArr
    global cardSelect
    global playCard = []
    global tusacState, Pre_haBai, haBai
    global GUI_busy, bbox, bbox1


        x = pos[1] << macOSconst
        y = pos[2] << macOSconst
    println("guiready,busy ", (GUI_ready,GUI_busy))
        if tusacState == tsSdealCards
            doCardDeal()

        elseif tusacState == tsGameLoop
            if !isGameOver() && playerIsHuman(myPlayer)
                if Pre_haBai && glNeedaPlayCard
                    haBai = true
                    Pre_haBai = false
                    println("glIterationCnt= ", rem(glIterationCnt,4))
                    GUI_ready = true
                    GUI_array = currentCards
                else
                    if GUI_ready == false && !GUI_busy
                        cindx, yPortion = mouseDownOnBox(x, y, human_state)
                        if cindx != 0
                            click_card(cindx, yPortion, playerA_hand)
			                if length(cardsIndxArr) > 0
			    	            bbox = false
			                end
                        end

                        if currentAction == gpPlay1card
                            if bbox == false
                                cindx, yPortion = mouseDownOnBox(x, y, pBseat)
                                if cindx != 0 && length(cardsIndxArr) > 0
                                    bbox = true
                                else
                                    cindx = 0
                                end
                            end
                        else
                            if bbox1 == false
                                bc = ActiveCard
                                bx,by = big_actors[bc].pos
                                hotseat = [bx,by,bx+zoomCardXdim,by+zoomCardYdim]
                                cindx, yPortion = mouseDownOnBox(x, y, hotseat)
                                if cindx != 0
                                    bbox1 = true
                                end
                            end
                        end
                        if cindx != 0
                            GUI_busy = true
                            global GUI_array, GUI_ready
                            println("here",(cindx,(cardsIndxArr)))
                            GUI_array = []
                            for ci in cardsIndxArr
                                ac= TuSacCards.getCards(playerA_hand, ci)
                                push!(GUI_array,ac)
                            end
                            setupDrawDeck(playerA_hand, GUILoc[1,1], GUILoc[1,2],GUILoc[1,3], false)
                            cardsIndxArr = []
                            if ( length(GUI_array) > 0 || length(currentPlayCard) > 0 ) &&
                                badPlay(GUI_array,myPlayer,all_hands[myPlayer],
                                currentAction,currentCards,currentPlayCard)
                                if okToPrint(0x8)
                                    println("badPlay reject")
                                end
                                updateErrorPic(1)
                                GUI_ready = false
                                GUI_busy = false
                                bbox = false
                                bbox1 = false
                            else
                                updateErrorPic(0)
                                GUI_ready = true
                            end
                        end
                end
            end
        end
    elseif tusacState == tsRestart
            anewDeck = []
            global boxes = []
    end
end
if noGUI()
    while(true)
        gsStateMachine(gsGameLoop)
        checkForRestart()
    end
end
function update(g)
    global waitForHuman,FaceDown
    global ad, deckState, gameDeck, tusacState
    global tusacState
    FaceDown = !isGameOver()

    if tusacState == tsSdealCards

        if (deckState[5] > 10)
            shuffled = true
            TuSacCards.humanShuffle!(gameDeck, 14, deckState[5])
            deckState = setupDrawDeck(gameDeck, GUILoc[13,1], GUILoc[13,2], 14, FaceDown)
        end
        if noGUI()
            gsStateMachine(gsOrganize)
        end
    elseif tusacState == tsSstartGame
        gsStateMachine(gsStartGame)
    elseif (tusacState == tsSdealCards)

    elseif tusacState == tsGameLoop

      #  updateHandPic(currentPlayer)
        gsStateMachine(gsGameLoop)
    elseif tusacState == tsRestart

    end
end

function drawAhand(hand)
    global openAllCard
    sI = 0
    for c in hand
        i = mapToActors[c]
        if ((cardSelect == false)) && (i == BIGcard)
            sI = i
        elseif (openAllCard == true) || ((mask[i] & 0x1) == 0)
            draw(actors[i])
        else
            draw(fc_actors[i])
        end
    end
    return sI
end

function draw(g)
    global BIGcard, ActiveCard, openAllCard
    global cardSelect, FaceDown
    global drawCnt,lsx,lsy
    if noGUI()
        return
    end
   draw(Rect(0, 0, realWIDTH, realHEIGHT), colorant"grey", fill=true)

    saveI = 0
    drawCnt += 1
    if drawCnt > 4
        drawCnt = 0
    end
    if !((tusacState == tsGameLoop)||(tusacState == tsHistory))
        for i = 1:112
            global saveI
            if ((cardSelect == false)) && (i == BIGcard)
                saveI = i
            elseif (openAllCard == true) || ((mask[i] & 0x1) == 0)
                draw(actors[i])
            else
                draw(fc_actors[i])
            end
        end
    elseif (tusacState == tsGameLoop)||(tusacState == tsHistory)
        if(tusacState == tsHistory)
            GUI && sleep(.2)
        end
        saveI = saveI + drawAhand(TuSacCards.toValueArray(gameDeck))
        for i in 1:4
            saveI = saveI + drawAhand(all_hands[i])
            saveI = saveI + drawAhand(all_assets[i])
            saveI = saveI + drawAhand(all_discards[i])
        end
        if saveI != 0
            draw(big_actors[saveI])
        end

        if ActiveCard != 0
            global csx,csy = big_actors[ActiveCard].pos
            if drawCnt >0
                draw(big_actors[ActiveCard])
            end
        end
        draw(handPic)
        draw(winnerPic)
        draw(errorPic)
        draw(baiThuiPic)

        if length(coins) > 0
            for c in coins
                draw(c)
            end
        end
        for i in 1:4
            draw(boDoiPic[i])
            draw(GUIname[i])
        end
    end
end
