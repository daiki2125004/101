"""Command line interface for the 101 card game."""

from __future__ import annotations

from game101.game import Game101

PROMPT = "(h)it, (s)tand, or (q)uit? "


def print_hand(prefix: str, hand) -> None:
    cards = " ".join(str(card) for card in hand.cards)
    print(f"{prefix}: {cards} => {hand.best_total}")


def play_round() -> None:
    game = Game101()
    game.deal_initial_cards()

    print("=== 101 Card Game ===")
    print("目標は合計値を101にできるだけ近づけつつ、101を超えないようにカードを引くことです。\n")

    while True:
        print_hand("あなた", game.human.hand)
        # Hide all but first card for suspense
        computer_first = str(game.computer.hand.cards[0])
        print(f"コンピューター: {computer_first} ?? => ?")

        if game.human.hand.is_bust:
            print("101を超えてしまいました…")
            break

        choice = input(PROMPT).strip().lower()
        if choice in {"q", "quit"}:
            raise SystemExit(0)
        if choice in {"h", "hit", ""}:
            game.human_hit()
            print()
            continue
        if choice in {"s", "stand"}:
            break
        print("無効な入力です。h/s/q のいずれかを選択してください。\n")

    print("\n--- 結果 ---")
    game.computer_turn()
    print_hand("あなた", game.human.hand)
    print_hand("コンピューター", game.computer.hand)

    winner = game.winner()
    if winner is None:
        print("引き分けです！")
    elif winner == game.human.name:
        print("おめでとうございます、あなたの勝ちです！")
    else:
        print("コンピューターの勝ちです。次こそは！")


if __name__ == "__main__":
    try:
        while True:
            play_round()
            again = input("もう一度遊びますか？ (y/n): ").strip().lower()
            if again not in {"y", "yes", ""}:
                break
            print()
    except (KeyboardInterrupt, EOFError):
        print("\nゲームを終了します。ありがとうございました！")
