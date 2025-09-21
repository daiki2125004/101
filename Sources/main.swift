import Foundation

enum Suit: String, CaseIterable {
    case hearts = "♥"
    case diamonds = "♦"
    case clubs = "♣"
    case spades = "♠"

    static var standard: [Suit] {
        return [.hearts, .diamonds, .clubs, .spades]
    }
}

enum Rank: CaseIterable {
    case two, three, four, five, six, seven, eight, nine, ten
    case jack, queen, king, ace
    case joker

    var displayName: String {
        switch self {
        case .two: return "2"
        case .three: return "3"
        case .four: return "4"
        case .five: return "5"
        case .six: return "6"
        case .seven: return "7"
        case .eight: return "8"
        case .nine: return "9"
        case .ten: return "10"
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        case .ace: return "A"
        case .joker: return "JOKER"
        }
    }

    var defaultValue: Int {
        switch self {
        case .two: return 2
        case .three: return 3
        case .four: return 4
        case .five: return 5
        case .six: return 6
        case .seven: return 7
        case .eight: return 0
        case .nine: return 0
        case .ten: return 10
        case .jack: return 10
        case .queen: return 20
        case .king: return 30
        case .ace: return 11
        case .joker: return 50
        }
    }
}

struct Card: CustomStringConvertible {
    let rank: Rank
    let suit: Suit?

    init(rank: Rank, suit: Suit?) {
        self.rank = rank
        self.suit = suit
    }

    var description: String {
        if rank == .joker {
            return "JOKER"
        }
        guard let suit = suit else {
            return rank.displayName
        }
        return "\(rank.displayName)\(suit.rawValue)"
    }
}

struct Deck {
    private var cards: [Card] = []

    init() {
        reset()
    }

    mutating func reset() {
        cards.removeAll()
        for suit in Suit.standard {
            cards.append(Card(rank: .ace, suit: suit))
            cards.append(Card(rank: .king, suit: suit))
            cards.append(Card(rank: .queen, suit: suit))
            cards.append(Card(rank: .jack, suit: suit))
            cards.append(Card(rank: .ten, suit: suit))
            cards.append(Card(rank: .nine, suit: suit))
            cards.append(Card(rank: .eight, suit: suit))
            cards.append(Card(rank: .seven, suit: suit))
            cards.append(Card(rank: .six, suit: suit))
            cards.append(Card(rank: .five, suit: suit))
            cards.append(Card(rank: .four, suit: suit))
            cards.append(Card(rank: .three, suit: suit))
            cards.append(Card(rank: .two, suit: suit))
        }
        cards.append(Card(rank: .joker, suit: nil))
        cards.append(Card(rank: .joker, suit: nil))
        cards.shuffle()
    }

    func canDraw(using discard: [Card]) -> Bool {
        return !cards.isEmpty || !discard.isEmpty
    }

    mutating func draw(from discard: inout [Card]) -> Card? {
        if cards.isEmpty {
            reshuffle(from: &discard)
        }
        return cards.popLast()
    }

    mutating func reshuffle(from discard: inout [Card]) {
        guard !discard.isEmpty else { return }
        cards = discard.shuffled()
        discard.removeAll()
    }
}

enum PlayerType {
    case human
    case cpu
}

struct Player {
    let id: Int
    let name: String
    let type: PlayerType
    var hand: [Card] = []
    var score: Int = 0
}

enum CardDecisionMode {
    case value(Int)
    case skip
    case reverse
    case jokerSpecial
}

struct CardDecision {
    let mode: CardDecisionMode
    let description: String
}

func possibleDecisions(for card: Card, total: Int) -> [CardDecision] {
    switch card.rank {
    case .ace:
        return [
            CardDecision(mode: .value(1), description: "+1"),
            CardDecision(mode: .value(11), description: "+11")
        ]
    case .ten:
        return [
            CardDecision(mode: .value(-10), description: "-10"),
            CardDecision(mode: .value(10), description: "+10")
        ]
    case .eight:
        return [CardDecision(mode: .skip, description: "合計値は変化しません")]
    case .nine:
        return [CardDecision(mode: .reverse, description: "合計値は変化せず、順番が反転します")]
    case .joker:
        if total == 100 {
            return [CardDecision(mode: .jokerSpecial, description: "一人勝ち")]
        } else {
            return [CardDecision(mode: .value(50), description: "+50")]
        }
    default:
        return [CardDecision(mode: .value(card.rank.defaultValue), description: "+\(card.rank.defaultValue)")]
    }
}

func nextIndex(from current: Int, direction: Int, playerCount: Int) -> Int {
    var index = current + direction
    while index < 0 {
        index += playerCount
    }
    index %= playerCount
    return index
}

func readInt(prompt: String, range: ClosedRange<Int>) -> Int {
    while true {
        print(prompt, terminator: " ")
        if let line = readLine(), let value = Int(line.trimmingCharacters(in: .whitespacesAndNewlines)), range.contains(value) {
            return value
        }
        print("入力が正しくありません。もう一度入力してください。")
    }
}

func chooseDecision(from decisions: [CardDecision]) -> CardDecision {
    if decisions.count == 1 {
        return decisions[0]
    }
    for (idx, decision) in decisions.enumerated() {
        print("  \(idx + 1): \(decision.description)")
    }
    let choice = readInt(prompt: "選択肢を入力してください (1-\(decisions.count)):", range: 1...decisions.count)
    return decisions[choice - 1]
}

func cpuSelectAction(for player: Player, total: Int, deck: inout Deck, discard: inout [Card]) -> (card: Card, decision: CardDecision, handIndex: Int?) {
    var bestScore = Int.min
    var bestCardIndex: Int?
    var bestDecision: CardDecision?

    func score(for decision: CardDecision, card: Card) -> Int {
        switch decision.mode {
        case .jokerSpecial:
            return 10_000
        case .skip:
            return 500
        case .reverse:
            return 400
        case .value(let delta):
            let result = total + delta
            if result > 101 {
                return -1000 - (result - 101)
            } else if result == 101 {
                return 150
            } else {
                return 300 + result
            }
        }
    }

    for (idx, card) in player.hand.enumerated() {
        let decisions = possibleDecisions(for: card, total: total)
        for decision in decisions {
            let s = score(for: decision, card: card)
            if s > bestScore {
                bestScore = s
                bestCardIndex = idx
                bestDecision = decision
            }
        }
    }

    if let index = bestCardIndex, let decision = bestDecision, bestScore > -1000 {
        return (player.hand[index], decision, index)
    }

    if let drawn = deck.draw(from: &discard) {
        let decisions = possibleDecisions(for: drawn, total: total)
        let decision = decisions.max(by: { score(for: $0, card: drawn) < score(for: $1, card: drawn) }) ?? decisions[0]
        return (drawn, decision, nil)
    }

    if let index = bestCardIndex, let decision = bestDecision {
        return (player.hand[index], decision, index)
    }

    let fallbackCard = player.hand[0]
    let fallbackDecision = possibleDecisions(for: fallbackCard, total: total)[0]
    return (fallbackCard, fallbackDecision, 0)
}

func describeDecision(_ decision: CardDecision, for card: Card) -> String {
    switch decision.mode {
    case .value(let delta):
        let sign = delta >= 0 ? "+" : ""
        return "\(card) (合計値に\(sign)\(delta))"
    case .skip:
        return "\(card) (合計値は変わりません)"
    case .reverse:
        return "\(card) (順番が反転します)"
    case .jokerSpecial:
        return "\(card) (一人勝ち)"
    }
}

func flowContribution(for card: Card, direction: inout Int) -> Int {
    switch card.rank {
    case .ace:
        return 11
    case .ten:
        return 10
    case .eight:
        return 0
    case .nine:
        direction *= -1
        return 0
    case .joker:
        return 50
    default:
        return card.rank.defaultValue
    }
}

func playRound(players: inout [Player]) {
    var deck = Deck()
    var discard: [Card] = []

    for index in players.indices {
        players[index].hand.removeAll()
    }

    for _ in 0..<2 {
        for index in players.indices {
            if let card = deck.draw(from: &discard) {
                players[index].hand.append(card)
            }
        }
    }

    var currentIndex = Int.random(in: 0..<players.count)
    var direction = 1
    var total = 0
    var flowCount = 0
    var previousPlayerIndex = nextIndex(from: currentIndex, direction: -direction, playerCount: players.count)

    print("\n--- 新しいラウンドを開始します ---")
    print("開始プレイヤー: \(players[currentIndex].name)")

    roundLoop: while true {
        var player = players[currentIndex]
        print("\n現在の合計値: \(total)")
        print("順番: \(direction == 1 ? "時計回り" : "反時計回り")")
        print("\(player.name)の番です。スコア: \(player.score)")

        let card: Card
        let decision: CardDecision
        var playedFromHand = false

        switch player.type {
        case .human:
            print("手札:")
            for (idx, card) in player.hand.enumerated() {
                let decisions = possibleDecisions(for: card, total: total)
                let descriptions = decisions.map { $0.description }.joined(separator: ", ")
                print("  \(idx + 1): \(card) [選択肢: \(descriptions)]")
            }
            let canDraw = deck.canDraw(using: discard)
            let promptSuffix = canDraw ? "1/2" : "1"
            print("行動を選んでください: 1) 手札から出す")
            if canDraw {
                print("                       2) 山札から引いてそのまま出す")
            }
            let actionChoice = readInt(prompt: "選択 (\(promptSuffix)):", range: 1...(canDraw ? 2 : 1))
            if actionChoice == 1 {
                let cardIndex = readInt(prompt: "出すカードを選択してください (1-\(player.hand.count)):", range: 1...player.hand.count) - 1
                card = player.hand.remove(at: cardIndex)
                let decisions = possibleDecisions(for: card, total: total)
                decision = chooseDecision(from: decisions)
                playedFromHand = true
            } else {
                if let drawn = deck.draw(from: &discard) {
                    print("山札から \(drawn) を引きました。")
                    card = drawn
                    let decisions = possibleDecisions(for: card, total: total)
                    decision = chooseDecision(from: decisions)
                } else {
                    print("山札からカードを引けませんでした。代わりに手札から出してください。")
                    let cardIndex = readInt(prompt: "出すカードを選択してください (1-\(player.hand.count)):", range: 1...player.hand.count) - 1
                    card = player.hand.remove(at: cardIndex)
                    let decisions = possibleDecisions(for: card, total: total)
                    decision = chooseDecision(from: decisions)
                    playedFromHand = true
                }
            }
        case .cpu:
            let action = cpuSelectAction(for: player, total: total, deck: &deck, discard: &discard)
            card = action.card
            decision = action.decision
            if let index = action.handIndex {
                player.hand.remove(at: index)
                playedFromHand = true
                print("\(player.name) は \(describeDecision(decision, for: card)) を出しました。")
            } else {
                print("\(player.name) は山札からカードを引き \(describeDecision(decision, for: card)) を出しました。")
            }
        }

        players[currentIndex] = player

        var roundEnded = false
        var loserIndex: Int?
        var winnerIndex: Int?

        switch decision.mode {
        case .skip:
            print("\(card) により合計値は変わりません。")
            discard.append(card)
        case .reverse:
            direction *= -1
            print("\(card) により順番が反転しました。")
            discard.append(card)
        case .jokerSpecial:
            print("\(card) により \(players[currentIndex].name) の一人勝ち！")
            discard.append(card)
            winnerIndex = currentIndex
            loserIndex = previousPlayerIndex
            roundEnded = true
        case .value(let delta):
            let newTotal = total + delta
            print("\(card) により合計値は \(total) -> \(newTotal) になりました。")
            total = newTotal
            discard.append(card)
            if total == 101 {
                flowCount += 1
                print("合計値が101になったため場が流れます。現在の流れ回数: \(flowCount)")
                if let flowCard = deck.draw(from: &discard) {
                    var flowDirection = direction
                    let contribution = flowContribution(for: flowCard, direction: &flowDirection)
                    direction = flowDirection
                    total = contribution
                    print("流れ札として \(flowCard) がめくられ、合計値は \(total) から再開します。")
                    discard.append(flowCard)
                } else {
                    total = 0
                    print("流れ札を引けなかったため合計値は0から再開します。")
                }
            } else if total > 101 {
                print("合計値が101を超えたため \(players[currentIndex].name) の負けです。")
                loserIndex = currentIndex
                roundEnded = true
            }
        }

        if roundEnded {
            let penalty = flowCount + 1
            if let winner = winnerIndex {
                players[winner].score += penalty
                if let loser = loserIndex {
                    players[loser].score -= penalty
                    print("\(players[winner].name) が +\(penalty) ポイント、\(players[loser].name) が -\(penalty) ポイント。")
                } else {
                    print("\(players[winner].name) が +\(penalty) ポイント。")
                }
            } else if let loser = loserIndex {
                players[loser].score -= penalty
                print("\(players[loser].name) が -\(penalty) ポイント。")
            }
            break roundLoop
        }

        if playedFromHand {
            if let drawCard = deck.draw(from: &discard) {
                players[currentIndex].hand.append(drawCard)
            }
        }

        previousPlayerIndex = currentIndex
        currentIndex = nextIndex(from: currentIndex, direction: direction, playerCount: players.count)
    }

    print("\nラウンド終了時のスコア:")
    for player in players {
        print("  \(player.name): \(player.score)")
    }
}

func startGame() {
    print("ようこそ！トランプゲーム『101』を開始します。")
    let cpuCount = readInt(prompt: "参加させるCPUの人数を入力してください (0-3):", range: 0...3)
    var players: [Player] = []
    players.append(Player(id: 0, name: "あなた", type: .human))
    for i in 0..<cpuCount {
        players.append(Player(id: i + 1, name: "CPU\(i + 1)", type: .cpu))
    }
    if players.count < 2 {
        print("CPUが参加しない場合でも、最低1人のCPUを追加します。")
        players.append(Player(id: players.count, name: "CPU1", type: .cpu))
    }

    while !players.contains(where: { $0.score <= -5 }) {
        playRound(players: &players)
    }

    print("\nゲーム終了！最終結果:")
    for player in players {
        print("  \(player.name): \(player.score)")
    }
    if let loser = players.min(by: { $0.score < $1.score }) {
        print("最終的に負けたのは \(loser.name) です。")
    }
}

startGame()
