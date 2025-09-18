"""Hand logic used by players in the 101 card game."""

from __future__ import annotations

from typing import Iterable

from .card import Card

MAX_TOTAL = 101


class Hand:
    """Represents the set of cards held by a player."""

    def __init__(self, cards: Iterable[Card] | None = None) -> None:
        self.cards: list[Card] = list(cards or [])

    def add_card(self, card: Card) -> None:
        self.cards.append(card)

    def totals(self) -> list[int]:
        """Return all possible totals respecting flexible ace values."""

        total = 0
        aces = 0
        for card in self.cards:
            if card.rank == "A":
                aces += 1
            total += card.value

        totals = [total]
        # Each ace can reduce the total by 10 if needed (11 -> 1)
        for _ in range(aces):
            total -= 10
            totals.append(total)
        return sorted({t for t in totals if t <= MAX_TOTAL} or {min(totals)})

    @property
    def best_total(self) -> int:
        totals = self.totals()
        # If we have at least one total <= MAX_TOTAL pick highest, otherwise pick minimum bust
        valid_totals = [t for t in totals if t <= MAX_TOTAL]
        return max(valid_totals) if valid_totals else min(totals)

    @property
    def is_bust(self) -> bool:
        return all(total > MAX_TOTAL for total in self.totals())

    def __str__(self) -> str:  # pragma: no cover - trivial formatting
        cards = " ".join(str(card) for card in self.cards)
        return f"[{cards}] => {self.best_total}"
