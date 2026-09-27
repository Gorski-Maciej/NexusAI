#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
=======================================================================
 SILNIK SYMULACYJNY PROJEKTU:
 "Komparator większości (>) liczb dwubitowych z minimalizacją
  Quine'a–McCluskeya, analizą hazardów i analizą tolerancji poziomów"
 Autor pracy: Maciej Górski, nr albumu 4256
=======================================================================

Konwencje:
  - kod mintermu = 8*A1 + 4*A0 + 2*B1 + B0   (A1 = MSB)
  - terminy QM jako krotka (WZORZEC, MASKA):
      WZORZEC - bity zmiennych stałych, MASKA - bit=1 => zmienna obecna
  - kanał analogowy: poziom(x) = k*x + d*(1-x)  (x in {0,1}), obcięty do [0,1]
  - próg decyzyjny odbiornika: 0,5

Zawartość:
  1. Specyfikacja G = (A > B) i tablica kanoniczna.
  2. Symulator statyczny + time-wheel (1 ns, opóźnienia bramek, skew wejść).
  3. Detekcja hazardów static-0/1 i dynamicznych.
  4. Quine-McCluskey: prime implicants, pokrycie, weryfikacja ekspansją.
  5. Silnik analogowy: skan d, skan k, Monte Carlo, granice analityczne.
  6. Analiza opóźnień (ostatnia zmiana wyjścia, średnia po próbkach).
  7. Testy 4.1-4.7, raport TXT, fragmenty LaTeX, eksporty CSV.

Uruchomienie: python3 symulacja.py [--montecarlo N] [--sigma S] [--seed S]
"""
from __future__ import annotations

import argparse
import math
import os
import random
from dataclasses import dataclass, field
from itertools import product
from typing import Callable, Dict, List, Sequence, Tuple

# ======================================================================
# 0. SPECYFIKACJA
# ======================================================================

NAZWY = ("A1", "A0", "B1", "B0")
KLUCZE = ("a1", "a0", "b1", "b0")

def spec_G(a1: int, a0: int, b1: int, b0: int) -> int:
    """G = 1 <=> A > B, gdzie A = 2*A1 + A0, B = 2*B1 + B0."""
    return 1 if (2 * a1 + a0) > (2 * b1 + b0) else 0

def mintermy_spec() -> List[int]:
    """Mintermy G w kodowaniu 8*A1+4*A0+2*B1+B0."""
    return sorted(8*a1 + 4*a0 + 2*b1 + b0
                  for a1, a0, b1, b0 in product((0, 1), repeat=4)
                  if spec_G(a1, a0, b1, b0))

def bity(kod: int) -> Tuple[int, int, int, int]:
    """Kod -> (A1, A0, B1, B0)."""
    return ((kod >> 3) & 1, (kod >> 2) & 1, (kod >> 1) & 1, kod & 1)

def kod_z_bitow(a1: int, a0: int, b1: int, b0: int) -> int:
    return 8*a1 + 4*a0 + 2*b1 + b0

def wejscia_z_kodu(kod: int) -> Dict[str, int]:
    return dict(zip(KLUCZE, bity(kod)))

# ======================================================================
# 1. SYMULATOR LOGICZNY
# ======================================================================

@dataclass
class Gate:
    nazwa: str
    f: Callable[..., int]
    tp: int                                   # opóźnienie propagacji [ns]
    we: List["Wezel"] = field(default_factory=list)
    stan: int = 0

class WezelWejsciowy:
    def __init__(self, nazwa: str):
        self.nazwa = nazwa
        self.tp = 0
        self.we: List[Wezel] = []
        self.stan: int = 0

Wezel = object  # Gate albo WezelWejsciowy

def _wierzcholki(Y) -> List:
    """Porządek topologiczny od wejść do wyjścia."""
    seen: set = set()
    order: List = []

    def dfs(v):
        if id(v) in seen:
            return
        seen.add(id(v))
        for p in v.we:
            dfs(p)
        order.append(v)

    dfs(Y)
    return order

def symuluj_statycznie(uklad: Dict, we: Dict[str, int]) -> int:
    """Stan ustalony wyjścia Y."""
    for v in _wierzcholki(uklad["Y"]):
        if isinstance(v, WezelWejsciowy):
            v.stan = we[v.nazwa]
        else:
            v.stan = v.f(*[p.stan for p in v.we])
    return uklad["Y"].stan

def symuluj_z_skewem(uklad: Dict, we0: Dict[str, int], we1: Dict[str, int],
                     skew: int = 0, horyzont: int = 40) -> List[Tuple[int, int]]:
    """Time-wheel: zmiana wejść od t=0; kolejne zmieniane bity wchodzą
    co `skew` ns; bramka o opóźnieniu tp patrzy na poprzedników z (t-tp).
    Zwraca [(t, Y(t))] dla t = 0..horyzont."""
    top = _wierzcholki(uklad["Y"])
    zmienione = [k for k in KLUCZE if we0[k] != we1[k]]

    def t_wejscia(nazwa: str, t: int) -> int:
        if nazwa not in zmienione:
            return we0[nazwa]
        idx = zmienione.index(nazwa)
        return we1[nazwa] if t >= idx * skew else we0[nazwa]

    def stan_ustalony(v, s: Dict[str, int]) -> int:
        if isinstance(v, WezelWejsciowy):
            return s[v.nazwa]
        return v.f(*[stan_ustalony(p, s) for p in v.we])

    hist: Dict[int, Dict[int, int]] = {
        id(v): {-10**6: stan_ustalony(v, we0)} for v in top
    }
    out: List[Tuple[int, int]] = []
    for t in range(0, horyzont + 1):
        for v in top:
            h = hist[id(v)]
            if isinstance(v, WezelWejsciowy):
                h[t] = t_wejscia(v.nazwa, t)
            else:
                vals = []
                for p in v.we:
                    hp = hist[id(p)]
                    tt = t - v.tp
                    if tt in hp:
                        vals.append(hp[tt])
                    else:
                        wczesniej = [kk for kk in hp if kk <= tt]
                        vals.append(hp[max(wczesniej)])
                h[t] = v.f(*vals)
        out.append((t, hist[id(uklad["Y"])][t]))
    return out

def detekcja_hazardu(przebieg: Sequence[Tuple[int, int]],
                     y_start: int, y_stop: int) -> List[str]:
    """Klasyfikacja glitchy: static-1, static-0, dynamiczny."""
    ys = [y for _, y in przebieg]
    opisy: List[str] = []
    if y_start == 1 and y_stop == 1 and 0 in ys:
        opisy.append("static-1")
    if y_start == 0 and y_stop == 0 and 1 in ys:
        opisy.append("static-0")
    zmiany = sum(1 for i in range(1, len(ys)) if ys[i] != ys[i - 1])
    oczekiwane = 1 if y_start != y_stop else 0
    if zmiany > max(oczekiwane, 1):
        opisy.append("dynamiczny")
    return opisy

# ---------------------------------------------------------------------
# Funkcje przełączające bramek
# ---------------------------------------------------------------------

def f_NOT(x): return 1 - x
def f_AND2(x, y): return x & y
def f_AND3(x, y, z): return x & y & z
def f_AND4(w, x, y, z): return w & x & y & z
def f_OR2(x, y): return x | y
def f_OR3(x, y, z): return x | y | z
def f_OR6(w, x, y, z, u, v): return w | x | y | z | u | v
def f_NAND2(x, y): return 1 - (x & y)
def f_NAND3(x, y, z): return 1 - (x & y & z)
def f_XNOR2(x, y): return 1 - (x ^ y)

# ---------------------------------------------------------------------
# Warianty konstrukcyjne funkcji G = A > B
# ---------------------------------------------------------------------

def zbuduj_sop() -> Dict:
    """Wariant S — SOP z QM:  G = A1·B1' + A0·B1'·B0' + A1·A0·B0'
    (pokrycie minimalne: 3 implikanty pierwsze, wszystkie essential)."""
    inp = {k: WezelWejsciowy(k) for k in KLUCZE}
    inv_b1 = Gate("inv_b1", f_NOT, 2); inv_b1.we = [inp["b1"]]
    inv_b0 = Gate("inv_b0", f_NOT, 2); inv_b0.we = [inp["b0"]]
    p1 = Gate("P1", f_AND2, 5); p1.we = [inp["a1"], inv_b1]
    p2 = Gate("P2", f_AND3, 5); p2.we = [inp["a0"], inv_b1, inv_b0]
    p3 = Gate("P3", f_AND3, 5); p3.we = [inp["a1"], inp["a0"], inv_b0]
    Y = Gate("Y", f_OR3, 6);    Y.we = [p1, p2, p3]
    return {"Y": Y, "nazwa": "SOP z QM (2xNOT+2xAND3+AND2+OR3)"}

def zbuduj_nand() -> Dict:
    """Wariant N — ta sama funkcja w technologii NAND-NAND (6 bramek NAND)."""
    inp = {k: WezelWejsciowy(k) for k in KLUCZE}
    ni_b1 = Gate("ni_b1", f_NAND2, 2); ni_b1.we = [inp["b1"], inp["b1"]]
    ni_b0 = Gate("ni_b0", f_NAND2, 2); ni_b0.we = [inp["b0"], inp["b0"]]
    p1 = Gate("P1", f_NAND2, 4); p1.we = [inp["a1"], ni_b1]
    p2 = Gate("P2", f_NAND3, 4); p2.we = [inp["a0"], ni_b1, ni_b0]
    p3 = Gate("P3", f_NAND3, 4); p3.we = [inp["a1"], inp["a0"], ni_b0]
    Y = Gate("Y", f_NAND3, 4);   Y.we = [p1, p2, p3]
    return {"Y": Y, "nazwa": "NAND-NAND (2xNAND2inv+3xNAND+NAND3)"}

def zbuduj_kanoniczny() -> Dict:
    """Wariant C — SOP kanoniczny: 6 mintermów 4-zmiennych + OR6 + 4 NOT."""
    inp = {k: WezelWejsciowy(k) for k in KLUCZE}
    inv = {k: Gate("inv_" + k, f_NOT, 2) for k in KLUCZE}
    for k in inv:
        inv[k].we = [inp[k]]
    mint: List[Gate] = []
    for i, m in enumerate(mintermy_spec()):
        a1, a0, b1, b0 = bity(m)
        g = Gate(f"m{i}", f_AND4, 5)
        g.we = [inp["a1"] if a1 else inv["a1"],
                inp["a0"] if a0 else inv["a0"],
                inp["b1"] if b1 else inv["b1"],
                inp["b0"] if b0 else inv["b0"]]
        mint.append(g)
    Y = Gate("Y", f_OR6, 7)
    Y.we = list(mint)
    return {"Y": Y, "nazwa": "SOP kanoniczny (4xNOT+6xAND4+OR6)"}

def zbuduj_kaskada() -> Dict:
    """Wariant T — kaskada klasyczna:  G = A1·B1' + E1·A0·B0',
    gdzie E1 = XNOR(A1,B1) (zgodność bitów starszych)."""
    inp = {k: WezelWejsciowy(k) for k in KLUCZE}
    inv_b1 = Gate("inv_b1", f_NOT, 2); inv_b1.we = [inp["b1"]]
    inv_b0 = Gate("inv_b0", f_NOT, 2); inv_b0.we = [inp["b0"]]
    E1 = Gate("E1", f_XNOR2, 8); E1.we = [inp["a1"], inp["b1"]]
    p1 = Gate("P1", f_AND2, 5);  p1.we = [inp["a1"], inv_b1]
    p2 = Gate("P2", f_AND3, 5);  p2.we = [E1, inp["a0"], inv_b0]
    Y = Gate("Y", f_OR2, 6);     Y.we = [p1, p2]
    return {"Y": Y, "nazwa": "Kaskada (2xNOT+XNOR+AND2+AND3+OR2)"}

WARIANTY: Dict[str, Callable[[], Dict]] = {
    "S": zbuduj_sop,
    "N": zbuduj_nand,
    "C": zbuduj_kanoniczny,
    "T": zbuduj_kaskada,
}

def tabela_prawdy_sym(uklad: Dict) -> List[Tuple[int, int, int]]:
    """[(kod, Y_symulacji, Y_spec)] dla 16 kombinacji."""
    wyn = []
    for kod in range(16):
        y = symuluj_statycznie(uklad, wejscia_z_kodu(kod))
        wyn.append((kod, y, spec_G(*bity(kod))))
    return wyn

# ======================================================================
# 2. SILNIK ANALOGOWY
# ======================================================================

PROG = 0.5  # próg decyzyjny odbiornika

def a_not(a: float) -> float: return 1.0 - a
def a_and2(a: float, b: float) -> float: return a * b
def a_and3(a: float, b: float, c: float) -> float: return a * b * c
def a_or2(a: float, b: float) -> float: return 1.0 - (1.0 - a) * (1.0 - b)
def a_or3(a: float, b: float, c: float) -> float:
    return 1.0 - (1.0 - a) * (1.0 - b) * (1.0 - c)
def a_xnor(a: float, b: float) -> float: return 1.0 - abs(a - b)

def kanal(x: int, k: float, d: float) -> float:
    """Kanał: poziom(1) = k, poziom(0) = d; obcięcie do [0,1]."""
    return min(1.0, max(0.0, k * x + d * (1.0 - x)))

def analog_G_sop(a1, a0, b1, b0) -> float:
    """Wariant S: A1·B1' + A0·B1'·B0' + A1·A0·B0'."""
    return a_or3(
        a_and2(a1, a_not(b1)),
        a_and3(a0, a_not(b1), a_not(b0)),
        a_and3(a1, a0, a_not(b0)),
    )

def analog_G_nand(a1, a0, b1, b0) -> float:
    """Wariant N: NAND-NAND (ta sama funkcja co S)."""
    def nand2(u, v): return a_not(u * v)
    def nand3(u, v, w): return a_not(u * v * w)
    i1 = nand2(b1, b1)
    i0 = nand2(b0, b0)
    p1 = nand2(a1, i1)
    p2 = nand3(a0, i1, i0)
    p3 = nand3(a1, a0, i0)
    return nand3(p1, p2, p3)

def analog_G_kanoniczny(a1, a0, b1, b0) -> float:
    """Wariant C: OR6 z 6 mintermów."""
    out = 1.0
    for m in mintermy_spec():
        mb1, mb0_, mb2, mb3 = bity(m)
        mi = ((a1 if mb1 else a_not(a1)) * (a0 if mb0_ else a_not(a0)) *
              (b1 if mb2 else a_not(b1)) * (b0 if mb3 else a_not(b0)))
        out *= (1.0 - mi)
    return 1.0 - out

def analog_G_kaskada(a1, a0, b1, b0) -> float:
    """Wariant T: A1·B1' + E1·A0·B0', E1 = XNOR(A1,B1)."""
    E1 = a_xnor(a1, b1)
    return a_or2(
        a_and2(a1, a_not(b1)),
        a_and3(E1, a0, a_not(b0)),
    )

ANALOGI: Dict[str, Callable[..., float]] = {
    "S": analog_G_sop,
    "N": analog_G_nand,
    "C": analog_G_kanoniczny,
    "T": analog_G_kaskada,
}

EPS = 1e-9  # tolerancja na błędy zmiennoprzecinkowe przy porównaniu z progiem

def skan_tolerancji(fn: Callable[..., float], krok: float = 0.002,
                    d_max: float = 1.0) -> float:
    """Maksymalne d (k=1), przy którym wszystkie 16 kombinacji decyzji
    jest poprawnych względem progu 0,5 (z tolerancją EPS)."""
    d, najlepsze = 0.0, 0.0
    while d <= d_max + 1e-12:
        ok = True
        for kod in range(16):
            a1, a0, b1, b0 = bity(kod)
            y = fn(kanal(a1, 1.0, d), kanal(a0, 1.0, d),
                   kanal(b1, 1.0, d), kanal(b0, 1.0, d))
            ocz = spec_G(a1, a0, b1, b0)
            if (ocz == 1 and y < PROG - EPS) or (ocz == 0 and y > PROG + EPS):
                ok = False
                break
        if not ok:
            break
        najlepsze = d
        d += krok
    return najlepsze

def pierwszy_fail_d(fn: Callable[..., float], d: float):
    """Zwraca (kod, Y, ocz) pierwszego stanu failing przy zadanych d
    albo None, gdy wszystkie stany poprawne."""
    for kod in range(16):
        a1, a0, b1, b0 = bity(kod)
        y = fn(kanal(a1, 1.0, d), kanal(a0, 1.0, d),
               kanal(b1, 1.0, d), kanal(b0, 1.0, d))
        ocz = spec_G(a1, a0, b1, b0)
        if (ocz == 1 and y < PROG - EPS) or (ocz == 0 and y > PROG + EPS):
            return kod, y, ocz
    return None

def skan_wzmocnienia(fn: Callable[..., float], krok: float = 0.002) -> float:
    """Minimalne k (d=0), przy którym układ jeszcze działa poprawnie.
    Skan w dół aż do pierwszego błędu; zwraca ostatnie zdane k."""
    k, najlepsze = 1.0, 0.0
    while k >= krok - 1e-12:
        ok = True
        for kod in range(16):
            a1, a0, b1, b0 = bity(kod)
            y = fn(k * a1, k * a0, k * b1, k * b0)
            ocz = spec_G(a1, a0, b1, b0)
            if (ocz == 1 and y < PROG - EPS) or (ocz == 0 and y > PROG + EPS):
                ok = False
                break
        if not ok:
            break
        najlepsze = k
        k -= krok
    return najlepsze

def pierwszy_fail_k(fn: Callable[..., float], k: float):
    """Pierwszy stan failing przy wzmocnieniu k (d=0) albo None."""
    for kod in range(16):
        a1, a0, b1, b0 = bity(kod)
        y = fn(k * a1, k * a0, k * b1, k * b0)
        ocz = spec_G(a1, a0, b1, b0)
        if (ocz == 1 and y < PROG - EPS) or (ocz == 0 and y > PROG + EPS):
            return kod, y, ocz
    return None

def monte_carlo(fn: Callable[..., float], probek: int, sigma: float,
                seed: int) -> Tuple[int, float, float]:
    """Losowy szum poziomów N(0, sigma) niezależnie na każdym kanale."""
    rng = random.Random(seed)
    bledy, worst1, worst0 = 0, 1.0, 0.0
    for _ in range(probek):
        kod = rng.randrange(16)
        a1, a0, b1, b0 = bity(kod)
        syg = [min(1.0, max(0.0, (1.0 if v else 0.0) + rng.gauss(0.0, sigma)))
               for v in (a1, a0, b1, b0)]
        y = fn(*syg)
        ocz = spec_G(a1, a0, b1, b0)
        if ocz == 1:
            worst1 = min(worst1, y)
            if y < PROG:
                bledy += 1
        else:
            worst0 = max(worst0, y)
            if y > PROG:
                bledy += 1
    return bledy, worst1, worst0

def granica_analityczna() -> Dict[str, float]:
    """Granice dla wariantu S przy k=1 (poziom(0) = d, poziom(1) = 1):
      - stan G=1 krytyczny: m9 (A=10,B=01): tylko P1 = A1·B1' = 1·(1-d)
        jest aktywne (b0=1 zeruje P2 i P3), więc Y(m9) = 1-d.
        Warunek Y >= 0,5  =>  d <= 0,5. Analogicznie m13, m14.
      - stan G=0: największy przeciek przy małych d występuje w stanach
        z jednym zerem na wejściu (np. m2: Y ~ d(1-d) <= 0,25 < 0,5) —
        nie wiąże.
    Wniosek: d_max(S) = 0,5 (wynik skanu potwierdza z dokładnością kroku)."""
    return {
        "d_max_S": 0.5,           # z Y(m9) = 1-d >= 0,5
        "d_przeciek_max": 0.25,   # maksimum paraboli d·(1-d) — nie wiąże
    }

# ======================================================================
# 3. QUINE-McCLUSKEY  (konwencja: (WZORZEC, MASKA))
# ======================================================================

def qm_prime_implicants(mintermy: Sequence[int]
                        ) -> List[Tuple[int, int, frozenset]]:
    """Lista (wzorzec, maska, pokrycie) — implikanty pierwsze."""
    grupy: Dict[int, List[Tuple[int, int, frozenset]]] = {}
    for m in mintermy:
        grupy.setdefault(bin(m).count("1"), []).append(
            (m, 0b1111, frozenset([m])))
    primes: List[Tuple[int, int, frozenset]] = []
    aktualny = [it for g in sorted(grupy) for it in grupy[g]]
    while aktualny:
        nastepny: List[Tuple[int, int, frozenset]] = []
        scalone: set = set()
        for i in range(len(aktualny)):
            for j in range(i + 1, len(aktualny)):
                w1, msk1, c1 = aktualny[i]
                w2, msk2, c2 = aktualny[j]
                if msk1 != msk2:
                    continue
                r = w1 ^ w2
                if r and (r & (r - 1)) == 0:
                    scalone.update((id(aktualny[i]), id(aktualny[j])))
                    nastepny.append((w1 & ~r, msk1 & ~r, c1 | c2))
        for it in aktualny:
            if id(it) not in scalone:
                primes.append(it)
        uniq, seen = [], set()
        for it in nastepny:
            if (it[0], it[1]) not in seen:
                seen.add((it[0], it[1]))
                uniq.append(it)
        aktualny = uniq
    return primes

def pi_tekst(wzorzec: int, maska: int) -> str:
    czlony = []
    for i, nazwa in enumerate(NAZWY):
        bit = 1 << (3 - i)
        if maska & bit:
            czlony.append(nazwa if wzorzec & bit else nazwa + "'")
    return "·".join(czlony) if czlony else "1"

def ekspanduj(wzorzec: int, maska: int) -> set:
    """Pełna ekspansja kostki — zbiór kodów pokrywanych przez termin."""
    wolne = [i for i in range(4) if not (maska >> (3 - i)) & 1]
    out: set = set()
    for kombinacja in product((0, 1), repeat=len(wolne)):
        kod = wzorzec
        for poz, v in zip(wolne, kombinacja):
            if v:
                kod |= 1 << (3 - poz)
        out.add(kod)
    return out

def qm_pokrycie(mintermy: Sequence[int], primes) -> List[Tuple[int, int]]:
    """Pokrycie: implikanty essential + zachłanne dobieranie reszty."""
    ess: List[Tuple[int, int, frozenset]] = []
    pokryte: set = set()
    for m in mintermy:
        pokr = [p for p in primes if m in p[2]]
        if len(pokr) == 1 and pokr[0] not in ess:
            ess.append(pokr[0])
            pokryte |= pokr[0][2]
    pozostale = set(mintermy) - pokryte
    kand = [p for p in primes if p not in ess]
    while pozostale:
        best = max(kand, key=lambda p: (len(p[2] & pozostale), -len(p[2])))
        ess.append(best)
        pokryte |= best[2]
        pozostale -= best[2]
        kand.remove(best)
    return [(p[0], p[1]) for p in ess]

def weryfikuj_pokrycie(mintermy: Sequence[int], cover) -> bool:
    """Pokrycie = dokładnie zbiór mintermów (ekspansja pełnych kostek)."""
    zbior = set(mintermy)
    pokryte: set = set()
    for wzorzec, maska in cover:
        pokryte |= ekspanduj(wzorzec, maska)
    return pokryte == zbior

# ======================================================================
# 4. ANALIZA OPÓŹNIEŃ
# ======================================================================

def sredni_czas_przejscia(builder: Callable[[], Dict], probek: int = 64,
                          seed: int = 42) -> float:
    """Średni czas (ns) ostatniej zmiany Y przy losowych przejściach,
    skew=1 ns. Uwzględnia tylko przejścia zmieniające Y."""
    rng = random.Random(seed)
    u = builder()
    czasy: List[int] = []
    for _ in range(probek):
        ka, kb = rng.randrange(16), rng.randrange(16)
        if ka == kb:
            continue
        we0, we1 = wejscia_z_kodu(ka), wejscia_z_kodu(kb)
        y0 = symuluj_statycznie(u, we0)
        y1 = spec_G(*bity(kb))
        if y0 == y1:
            continue
        ys = [y for _, y in symuluj_z_skewem(u, we0, we1, skew=1)]
        zmiany = [t for t in range(1, len(ys)) if ys[t] != ys[t - 1]]
        if zmiany:
            czasy.append(zmiany[-1])
    return sum(czasy) / len(czasy) if czasy else 0.0

def liczba_bramek_i_glebokosc(builder: Callable[[], Dict]) -> Tuple[int, int]:
    """(liczba bramek, głębokość logiczna) z realnej struktury."""
    u = builder()
    n = sum(1 for v in _wierzcholki(u["Y"])
            if not isinstance(v, WezelWejsciowy))

    def glebokosc(v, memo: Dict[int, int]) -> int:
        if id(v) in memo:
            return memo[id(v)]
        if isinstance(v, WezelWejsciowy):
            memo[id(v)] = 0
            return 0
        wynik = 1 + max(glebokosc(p, memo) for p in v.we)
        memo[id(v)] = wynik
        return wynik

    return n, glebokosc(u["Y"], {})

# ======================================================================
# 5. TESTY WERYFIKACYJNE
# ======================================================================

def test_tablic_prawdy() -> List[str]:
    L = []
    for klucz, builder in WARIANTY.items():
        u = builder()
        t = tabela_prawdy_sym(u)
        zgod = sum(1 for _, ys, sp in t if ys == sp)
        L.append(f"[{'PASS' if zgod == 16 else 'FAIL'}] wariant {klucz} "
                 f"({u['nazwa']}): {zgod}/16")
        for kod, ys, sp in t:
            if ys != sp:
                a1, a0, b1, b0 = bity(kod)
                L.append(f"      niezgodn.: kod={kod:04b} "
                         f"(A={2*a1+a0}, B={2*b1+b0}) sym={ys} spec={sp}")
    return L

def test_qm() -> List[str]:
    L = []
    m = mintermy_spec()
    L.append(f"mintermy G: {m}  ({len(m)} sztuk)")
    primes = qm_prime_implicants(m)
    L.append(f"implikanty pierwsze ({len(primes)}):")
    for wz, mk, cov in primes:
        ok = ekspanduj(wz, mk) <= set(m)
        L.append(f"    {pi_tekst(wz, mk):20s} pokrywa {sorted(cov)}"
                 f"  {'OK' if ok else 'NIEVALID'}")
    cover = qm_pokrycie(m, primes)
    L.append("pokrycie minimalne:")
    for wz, mk in cover:
        L.append(f"    {pi_tekst(wz, mk)}")
    L.append("Y_QM = " + " + ".join(pi_tekst(w, mk) for w, mk in cover))
    L.append("weryfikacja pokrycia (ekspansja 100%): "
             f"{'PASS' if weryfikuj_pokrycie(m, cover) else 'FAIL'}")
    return L

def test_hazardow() -> Tuple[List[str], Dict]:
    L, dane = [], {}
    for klucz, builder in WARIANTY.items():
        u = builder()
        stat1 = stat0 = dyn = 0
        naj_skew = 0
        przyklady: List[Tuple[str, int, List[str]]] = []
        for ka in range(16):
            we0 = wejscia_z_kodu(ka)
            y0 = symuluj_statycznie(u, we0)
            for kb in range(16):
                if kb == ka:
                    continue
                we1 = wejscia_z_kodu(kb)
                y1 = spec_G(*bity(kb))
                for skew in (0, 1, 2, 3):
                    prze = symuluj_z_skewem(u, we0, we1, skew=skew)
                    hz = detekcja_hazardu(prze, y0, y1)
                    if hz:
                        stat1 += "static-1" in hz
                        stat0 += "static-0" in hz
                        dyn += "dynamiczny" in hz
                        naj_skew = max(naj_skew, skew)
                        if len(przyklady) < 3:
                            przyklady.append((f"{ka:04b}->{kb:04b}",
                                              skew, hz))
                        break
        dane[klucz] = (stat1, stat0, dyn, naj_skew, przyklady)
        L.append(f"wariant {klucz}: static-1={stat1}, static-0={stat0}, "
                 f"dynamiczne={dyn}, najgorszy skew={naj_skew} ns")
    return L, dane

def test_tolerancji() -> Tuple[List[str], Dict[str, float]]:
    L, wyn = [], {}
    for nazwa, fn in ANALOGI.items():
        d = skan_tolerancji(fn)
        wyn[nazwa] = d
        fail = pierwszy_fail_d(fn, d + 0.002)
        info = (f" (pierwszy fail: m{fail[0]:02d}, Y={fail[1]:.4f})"
                if fail else "")
        L.append(f"wariant {nazwa}: d_max = {d:.3f}{info}")
    g = granica_analityczna()
    wyn["analityczna"] = g["d_max_S"]
    L.append(f"analitycznie (S): Y(m9) = 1-d => d <= {g['d_max_S']:.1f} "
             f"[stan krytyczny A=10, B=01]")
    L.append(f"stan G=0: Y <= {g['d_przeciek_max']:.2f} < 0,5 — niewiążąca")
    return L, wyn

def test_wzmocnienia() -> List[str]:
    L = []
    for nazwa, fn in ANALOGI.items():
        k = skan_wzmocnienia(fn)
        fail = pierwszy_fail_k(fn, k - 0.002)
        info = (f" (pierwszy fail: m{fail[0]:02d}, Y={fail[1]:.4f})"
                if fail else "")
        L.append(f"wariant {nazwa}: k_min = {k:.3f}{info}")
    return L

def test_monte_carlo(probek: int, sigma: float, seed: int) -> List[str]:
    L = []
    for nazwa, fn in ANALOGI.items():
        bledy, w1, w0 = monte_carlo(fn, probek, sigma, seed)
        L.append(f"wariant {nazwa}: bledy={bledy}/{probek}, "
                 f"worst Y|G=1: {w1:.4f}, worst Y|G=0: {w0:.4f}")
    return L

def test_opoznien() -> List[str]:
    L = []
    for klucz, builder in WARIANTY.items():
        n, gl = liczba_bramek_i_glebokosc(builder)
        t = sredni_czas_przejscia(builder)
        L.append(f"wariant {klucz}: bramki={n}, glebokosc={gl}, "
                 f"sredni czas przejscia={t:.1f} ns")
    return L

# ======================================================================
# 6. RAPORT + EKSPORTY
# ======================================================================

def raport_pelny(probek: int, sigma: float, seed: int) -> str:
    L = []
    L.append("=" * 76)
    L.append(" RAPORT SYMULACJI — komparator większości (A > B), 2 bity")
    L.append(" Autor pracy: Maciej Górski, nr albumu 4256")
    L.append("=" * 76)
    sekcje = (
        ("4.1 TABLICE PRAWDY (16 kombinacji, warianty S/N/C/T)",
         test_tablic_prawdy()),
        ("4.2 QUINE-McCLUSKEY", test_qm()),
        ("4.3 HAZARDY (240 przejsc x skew 0-3 ns)", test_hazardow()[0]),
        ("4.4 TOLERANCJA POZIOMOW (skan d, k=1)", test_tolerancji()[0]),
        ("4.5 WZMOCNIENIE W DOL (skan k, d=0)", test_wzmocnienia()),
        (f"4.6 MONTE CARLO (n={probek}, sigma={sigma}, seed={seed})",
         test_monte_carlo(probek, sigma, seed)),
        ("4.7 OPÓŹNIENIA I ZŁOŻONOŚĆ", test_opoznien()),
    )
    for naglowek, tresc in sekcje:
        L.append("")
        L.append(f"--- {naglowek} ---")
        L.extend("  " + x for x in tresc)
    L.append("")
    L.append("=" * 76)
    L.append(" KONIEC RAPORTU")
    return "\n".join(L)

def lx_tablica_prawdy() -> str:
    """Wiersze tablicy prawdy: bity, A, B, dec, G_spec, G_sym (wariant S)."""
    u = zbuduj_sop()
    wiersze = []
    for kod in range(16):
        a1, a0, b1, b0 = bity(kod)
        y = symuluj_statycznie(u, wejscia_z_kodu(kod))
        sp = spec_G(a1, a0, b1, b0)
        ok = r"\cmark" if y == sp else r"\xmark"
        wiersze.append(f"{a1} & {a0} & {b1} & {b0} & {2*a1+a0} & {2*b1+b0} & "
                       f"{sp} & {y} & {ok} \\\\")
    return "\n".join(wiersze)

def lx_mapa() -> str:
    """Mapa Karnaugha: wiersze A1A0, kolumny B1B0 (kod Graya)."""
    m = set(mintermy_spec())
    wiersze = []
    for ra1, ra0 in ((0, 0), (0, 1), (1, 1), (1, 0)):
        komorki = []
        for kb1, kb0 in ((0, 0), (0, 1), (1, 1), (1, 0)):
            kod = kod_z_bitow(ra1, ra0, kb1, kb0)
            komorki.append("1" if kod in m else "0")
        wiersze.append(f"{ra1}{ra0} & " + " & ".join(komorki) + " \\\\")
    return "\n".join(wiersze)

def lx_hazard() -> Tuple[str, Dict]:
    _, dane = test_hazardow()
    wiersze = []
    for klucz in ("S", "N", "C", "T"):
        stat1, stat0, dyn, skew, _ = dane[klucz]
        wiersze.append(f"{klucz} & {stat1} & {stat0} & {dyn} & {skew} \\\\")
    return "\n".join(wiersze), dane

def lx_porownanie() -> str:
    """Tabela porównawcza z REALNYCH struktur (licznik bramek/głębokość)."""
    wiersze = []
    for klucz in ("C", "S", "N", "T"):
        builder = WARIANTY[klucz]
        u = builder()
        n, gl = liczba_bramek_i_glebokosc(builder)
        t = sredni_czas_przejscia(builder)
        wiersze.append(f"{klucz} & {u['nazwa']} & {n} & {gl} & "
                       f"{t:.1f} \\\\")
    return "\n".join(wiersze)

def lx_przejscia() -> str:
    """Tabela przykładowych przejść (wariant S, skew=1 ns)."""
    scenariusze = [
        ("$3 \\to 2$", 0b0011, 0b0010),
        ("$1 \\to 2$", 0b0001, 0b0010),
        ("$2 \\to 3$", 0b0010, 0b0011),
        ("$0 \\to 3$", 0b0000, 0b0011),
    ]
    u = zbuduj_sop()
    wiersze = []
    for nazwa, ka, kb in scenariusze:
        we0, we1 = wejscia_z_kodu(ka), wejscia_z_kodu(kb)
        y0 = symuluj_statycznie(u, we0)
        y1 = spec_G(*bity(kb))
        prze = symuluj_z_skewem(u, we0, we1, skew=1)
        hz = detekcja_hazardu(prze, y0, y1)
        ys = [y for _, y in prze]
        zmiany = [t for t in range(1, len(ys)) if ys[t] != ys[t - 1]]
        nb = sum(1 for k in KLUCZE if we0[k] != we1[k])
        hz_txt = ", ".join(hz) if hz else "brak"
        wiersze.append(f"{nazwa} & {nb} & {y0}$\\to${y1} & "
                       f"{zmiany[-1] if zmiany else '--'} & {hz_txt} \\\\")
    return "\n".join(wiersze)

def eksport_csv_yod() -> str:
    """CSV: Y(d) dla stanów krytycznych wariantu S:
    m9 (A=10,B=01, G=1, Y=1-d) oraz m2 (A=00,B=10, G=0, przeciek)."""
    linie = ["d;Y_m9_G1;Y_m2_G0"]
    for i in range(0, 61):
        d = i * 0.01
        y1 = analog_G_sop(*[kanal(v, 1.0, d) for v in (1, 0, 0, 1)])
        y0 = analog_G_sop(*[kanal(v, 1.0, d) for v in (0, 0, 1, 0)])
        linie.append(f"{d:.2f};{y1:.4f};{y0:.4f}")
    return "\n".join(linie)

def eksport_csv_przebieg() -> str:
    """CSV: Y(t) dla przejścia B: 3 -> 2 przy A=1 (skew=2 ns), wariant S."""
    u = zbuduj_sop()
    we0 = dict(zip(KLUCZE, (0, 1, 1, 1)))   # A=1, B=3
    we1 = dict(zip(KLUCZE, (0, 1, 1, 0)))   # A=1, B=2
    prze = symuluj_z_skewem(u, we0, we1, skew=2)
    return "t;Y\n" + "\n".join(f"{t};{y}" for t, y in prze)

# ======================================================================
# 7. MAIN
# ======================================================================

def main() -> int:
    p = argparse.ArgumentParser(description="Symulator komparatora większości")
    p.add_argument("--montecarlo", type=int, default=20000)
    p.add_argument("--sigma", type=float, default=0.02)
    p.add_argument("--seed", type=int, default=4256)
    args = p.parse_args()

    raport = raport_pelny(args.montecarlo, args.sigma, args.seed)
    print(raport)

    here = os.path.dirname(os.path.abspath(__file__))
    wyniki = os.path.abspath(os.path.join(here, "..", "wyniki"))
    os.makedirs(wyniki, exist_ok=True)
    pliki = {
        "raport_symulacji.txt": raport + "\n",
        "tablica_prawdy.tex": lx_tablica_prawdy() + "\n",
        "mapa_karnaugh.tex": lx_mapa() + "\n",
        "tabela_hazardow.tex": lx_hazard()[0] + "\n",
        "tabela_porownanie.tex": lx_porownanie() + "\n",
        "tabela_przejscia.tex": lx_przejscia() + "\n",
        "y_od_d.csv": eksport_csv_yod() + "\n",
        "przebieg_B3toB2.csv": eksport_csv_przebieg() + "\n",
    }
    for nazwa, tresc in pliki.items():
        with open(os.path.join(wyniki, nazwa), "w", encoding="utf-8") as f:
            f.write(tresc)
    print(f"(info) fragmenty LaTeX i CSV zapisane w: {wyniki}")

    ok = True
    for klucz, builder in WARIANTY.items():
        t = tabela_prawdy_sym(builder())
        if any(ys != sp for _, ys, sp in t):
            ok = False
    m = mintermy_spec()
    cover = qm_pokrycie(m, qm_prime_implicants(m))
    if not weryfikuj_pokrycie(m, cover):
        ok = False
    print("WALIDACJA KOŃCOWA:",
          "PASS — 4 warianty zgodne ze specyfikacją, pokrycie QM 100%"
          if ok else "FAIL — wykryto niezgodności!")
    return 0 if ok else 1

if __name__ == "__main__":
    raise SystemExit(main())
