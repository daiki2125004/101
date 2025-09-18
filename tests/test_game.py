"""Basic tests for the 101 card game logic."""

from __future__ import annotations

import random

from game101.card import Card
from game101.deck import Deck
from game101.game import Game101
from game101.hand import Hand


def test_deck_has_52_unique_cards() -> None:
    deck = Deck()
    assert len(deck) == 52
    assert len({str(card) for card in deck}) == 52


def test_hand_totals_handle_aces() -> None:
    hand = Hand([Card("♠", "A"), Card("♦", "9"), Card("♥", "A")])
    assert hand.totals() == [11, 21, 31]
    assert hand.best_total == 31


def test_game_winner_detection() -> None:
    random.seed(0)
    game = Game101()
    game.deal_initial_cards()
    # Force deterministic hands
    game.human.hand = Hand([Card("♠", "K"), Card("♣", "Q"), Card("♦", "9")])  # 29
    game.computer.hand = Hand([Card("♥", "10"), Card("♦", "8"), Card("♣", "7")])  # 25
    assert game.winner() == game.human.name
