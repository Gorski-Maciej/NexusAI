# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI — ScPackageFusion: Strategia Fuzji Pakietów OPA dla SC
# ═══════════════════════════════════════════════════════════════════════════════
#
# Optymalizacja #1 z 38_SPOLKA_CYWILNA_STRATEGIC_IMPROVEMENTS.md
#
# Ten dokument opisuje strategię fuzji pakietów OPA w celu redukcji czasu
# ewaluacji dla spółki cywilnej. NIE jest to automatyczna refaktoryzacja —
# fuzja powinna być poprzedzona profilowaniem (`opa eval --explain full`).
# ═══════════════════════════════════════════════════════════════════════════════

# ── Prerequisites ─────────────────────────────────────────────────────────────
#
# Przed fuzją:
# 1. Uruchom `opa eval --explain full --data policies/tax --input sample.json`
# 2. Zidentyfikuj pakiety z największym narzutem (profile >10ms)
# 3. Sprawdź które pakiety są zawsze nieaktywne dla Twojego profilu spółki
# 4. Fuzjuj tylko jeśli profilowanie pokazuje mierzalny zysk

# ── Fusion Strategy ───────────────────────────────────────────────────────────
#
# POZIOMA (Horizontal Fusion) — pakiety wzajemnie wykluczające się:
#
#   Fuzja A: sc.accounting.pkpir + sc.accounting.full
#   Powód: Spółka używa ALBO PKPiR ALBO pełnej księgowości — nigdy obu.
#   Zysk: 1 pakiet z warunkowym routingiem zamiast 2.
#   Implementacja:
#     package sc.accounting
#     decide := { accounting_method: "PKPIR", ... } { not full_accounting }
#     else := { accounting_method: "FULL", ... } { full_accounting }
#
#   Fuzja B: sc.vat.gtu + sc.vat.tax_point
#   Powód: GTU i tax point są zawsze ewaluowane sekwencyjnie po substantive.
#   Zysk: 2 → 1 pakiet, eliminacja przejścia między pakietami.
#   Implementacja: Połącz w sc.vat.details z wewnętrznym routingiem.
#
# PIONOWA (Vertical Fusion) — pakiety w pipeline:
#
#   Fuzja C: sc.risk + sc.routing + sc.compliance
#   Powód: Te 3 pakiety zawsze wykonują się sekwencyjnie jako gate.
#   Zysk: 3 → 1 pakiet z zachowaną kolejnością else chain.
#   Implementacja: Zachowaj kolejność P0-P39 w jednym pliku.
#
#   Fuzja D: sc.pit.partners + sc.pit.forms + sc.pit.kup
#   Powód: PIT jest zawsze ewaluowany per partner w sekwencji.
#   Zysk: 3 → 1 pakiet sc.pit.core per partner.
#   Implementacja: Zagnieżdżony else chain iterujący po partners[].

# ── DO NOT FUSE — Pakiety, których NIE należy łączyć ─────────────────────────
#
# ⛔ sc.vat.substantive + sc.pit.partners
#   Powód: SEPARACJA DOMEN — VAT (spółka) i PIT (wspólnicy) MUSZĄ być
#   niezależne. To jest NAJWAŻNIEJSZA granica architektoniczna systemu.
#   Naruszenie tej separacji grozi regresjami przy zmianach prawa.
#
# ⛔ sc.partnership.liability + cokolwiek innego
#   Powód: Odpowiedzialność solidarna (Art. 864 KC) jest cross-cutting concern.
#   Musi być ewaluowana NIEZALEŻNIE od reguł podatkowych i NIGDY nie może
#   być pominięta przez optymalizację first-match-wins.

# ── Implementation Checklist ──────────────────────────────────────────────────
#
# Dla każdej fuzji:
# □ 1. Profilowanie (opa eval --explain full) — potwierdź narzut
# □ 2. Utwórz skondensowany plik .rego
# □ 3. Przenieś reguły z zachowaniem kolejności else chain
# □ 4. Zaktualizuj _metadata.rego (nowe rule_id)
# □ 5. Uruchom testy (make test)
# □ 6. Porównaj wyniki przed/po fuzji (identyczne werdykty?)
# □ 7. Aktualizuj bundle.sh (nowa lista pakietów)
# □ 8. Deploy staging → test integracyjny → production

# ── Expected Gains ────────────────────────────────────────────────────────────
#
# Pozioma: Redukcja 4 pakietów (A+B) → 2 pakiety (oszczędność ~5-10ms)
# Pionowa: Redukcja 6 pakietów (C+D) → 2 pakiety (oszczędność ~8-15ms)
# Łącznie: 33 → ~25 pakietów (oszczędność ~25% czasu ewaluacji)
# UWAGA: To są SZACUNKI. Rzeczywiste zyski zależą od profilowania.
