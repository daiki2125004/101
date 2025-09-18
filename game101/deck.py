"""Deck implementation for the 101 card game."""

from __future__ import annotations

import random
from typing import Iterable, Iterator

from .card import Card, create_standard_deck


class Deck:
    """Represents a shuffled deck of cards."""

    def __init__(self, cards: Iterable[Card] | None = None) -> None:
        self._cards: list[Card] = list(cards if cards is not None else create_standard_deck())
        self.shuffle()

    def shuffle(self) -> None:
        random.shuffle(self._cards)

    def draw(self) -> Card:
        if not self._cards:
            raise RuntimeError("The deck is empty. No more cards can be drawn.")
        return self._cards.pop()

    def __len__(self) -> int:
        return len(self._cards)

    def __iter__(self) -> Iterator[Card]:
        return iter(self._cards)
