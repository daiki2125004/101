"""Definitions for cards used in the 101 card game."""

from __future__ import annotations

from dataclasses import dataclass

SUITS = ["♠", "♥", "♦", "♣"]
RANKS = [
    "A",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "10",
    "J",
    "Q",
    "K",
]


@dataclass(frozen=True)
class Card:
    """Represents a single playing card."""

    suit: str
    rank: str

    def __str__(self) -> str:  # pragma: no cover - trivial string conversion
        return f"{self.rank}{self.suit}"

    @property
    def value(self) -> int:
        """Return the default value for the card.

        Numbered cards count as their rank. Face cards count as 10 and aces count as 11 by
        default. Handling the ace being counted as 1 is the responsibility of the hand logic
        which knows the current totals.
        """

        if self.rank in {"J", "Q", "K"}:
            return 10
        if self.rank == "A":
            return 11
        return int(self.rank)


def create_standard_deck() -> list[Card]:
    """Create a standard 52 card deck."""

    return [Card(suit=suit, rank=rank) for suit in SUITS for rank in RANKS]
