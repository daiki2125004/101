"""Game logic for the 101 card game."""

from __future__ import annotations

from dataclasses import dataclass

from .deck import Deck
from .hand import Hand, MAX_TOTAL


@dataclass
class Player:
    """Simple player representation."""

    name: str
    hand: Hand
    is_computer: bool = False

    def wants_card(self) -> bool:
        """Determine whether the player should draw another card."""

        if not self.is_computer:
            raise RuntimeError("wants_card should not be called for human players.")
        # Very simple computer strategy: draw while under 85, otherwise stand.
        return self.hand.best_total < 85


class Game101:
    """Encapsulates a single round of the 101 card game."""

    def __init__(self, human_name: str = "You") -> None:
        self.deck = Deck()
        self.human = Player(name=human_name, hand=Hand())
        self.computer = Player(name="Computer", hand=Hand(), is_computer=True)

    def deal_initial_cards(self) -> None:
        for _ in range(2):
            self.human.hand.add_card(self.deck.draw())
            self.computer.hand.add_card(self.deck.draw())

    def human_hit(self) -> None:
        self.human.hand.add_card(self.deck.draw())

    def computer_turn(self) -> None:
        while not self.computer.hand.is_bust and self.computer.wants_card():
            self.computer.hand.add_card(self.deck.draw())

    def winner(self) -> str | None:
        """Return the name of the winner or ``None`` for a draw."""

        human_total = self.human.hand.best_total
        computer_total = self.computer.hand.best_total
        human_bust = human_total > MAX_TOTAL
        computer_bust = computer_total > MAX_TOTAL

        if human_bust and computer_bust:
            return None
        if human_bust:
            return self.computer.name
        if computer_bust:
            return self.human.name
        if human_total > computer_total:
            return self.human.name
        if computer_total > human_total:
            return self.computer.name
        return None
