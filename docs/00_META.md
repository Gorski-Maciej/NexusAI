# 📜 Strona tytułowa dokumentacji NexusAI

> **NexusAI to nie aplikacja — to wirtualny księgowy.**

---

## Identyfikacja projektu

| Pole | Wartość |
|---|---|
| **Nazwa** | NexusAI |
| **Slug** | `nexus-ai` |
| **Wersja** | **2.3.1-dev** — „Enterprise Documentation" |
| **Data wydania** | 2026-07-05 |
| **Status deweloperski** | Beta (klasa 4) — patrz `pyproject.toml` classifiers |
| **Język** | Python ≥3.13 (free-threaded, `cp313t`) + Rust ≥1.78 |
| **Architektura** | Modularny Monolit z komunikacją przez NATS JetStream; CQRS + Event Sourcing |
| **Licencja** | Proprietary — wszystkie prawa zastrzeżone © 2026 NexusAI Team |

---

## Misja (one-liner)

> NexusAI przejmuje 90% rutynowej pracy księgowej (od pobrania faktury po jej zaksięgowanie), zostawiając przedsiębiorcy 3 minuty dziennie na decyzje w Centrum Decyzji. Wszystko lokalnie — żadne dane finansowe nie opuszczają komputera użytkownika.

---

## Propozycja wartości (PWE)

### 🔴 Problem (P)

| Wyzwanie | Konsekwencja |
|---|---|
| Ręczne księgowanie jest czasochłonne | Przedsiębiorca poświęca **8 h tygodniowo** na księgowość |
| Błędy kosztują pieniądze | Korekty JPK, odsetki, kary US — średnio **5 000 PLN/rok** na firmę |
| Dane wyciekają do chmury SaaS | Brak zgodności z RODO; zależność od dostawcy |
| Wdrożenie KSeF wymaga cyfryzacji | Ręczne wpisywanie niemożliwe w skali 2026 |

### 🟢 Wartość (W)

| Cecha | Korzyść |
|---|---|
| **Autonomia (AUTO_POST)** | Rada Agentów AI księguje 95% faktur bez pytania |
| **Prywatność (offline-first)** | Wszystkie modele AI + dane lokalne |
| **Zgodność polska z pudełka** | KSeF, NIP, Biała Lista MF, NBP, GUS/BIR |
| **Zgodność księgowa** | UoR, IFRS, GAAP, KSeF, JPK |
| **Niska bariera** | 6 GB RAM, bez GPU, działa na 5-letnim laptopie |
| **Kody źródłowe komponentów** | Litestar, Granian, llama.cpp, TigerBeetle, NATS — audytowalne |

### 🟦 Efekt (E)

| Metryka | Wartość docelowa |
|---|---|
| Czas tygodniowy na księgowość | 8 h → **1 h** |
| Oszczędność roczna | **do 20 000 PLN/rok** |
| Czas od wystawienia faktury do zaksięgowania | dni → **sekundy** |
| Zgodność z KSeF | **100%** generowanych faktur w FA_VAT(2) |
| Decyzje poprawne bez ingerencji | **>95%** (mierzone `FactsAggregator`) |

---

## Zespół

| Rola | Odpowiedzialność | Kontakt |
|---|---|---|
| **Technical Lead** | Architektura, code review, stack technologiczny | tech-lead@nexus-ai.pl |
| **Architect (DDD/AI)** | Model domeny, projekt agentów, ADR-y | arch@nexus-ai.pl |
| **Senior Engineer (Rust/PyO3)** | `nexus-crypto`, Nuitka, mypyc | rust@nexus-ai.pl |
| **Senior Engineer (OCR/AI)** | Pipeline OCR, modele GGUF | ocr@nexus-ai.pl |
| **Senior Engineer (TigerBeetle/NATS)** | Księga główna, event bus | ledger@nexus-ai.pl |
| **Księgowy konsultant** | Zgodność z UoR/IFRS, KSeF, JPK | accounting@nexus-ai.pl |
| **Doradca podatkowy** | Optimizacje CIT/PIT, scenariusze podatkowe | tax@nexus-ai.pl |
| **UX/UI Designer** | Material Design 3, Flet | ux@nexus-ai.pl |
| **DevOps / SRE** | CI/CD, security, monitorowanie | devops@nexus-ai.pl |
| **Security Officer** | Threat model, OWASP, RODO | security@nexus-ai.pl |
| **Maintainerzy open-source** | Reviews i merges (community) | maintainers@nexus-ai.pl |

---

## Licencja (proprietary)

```
NexusAI — Wirtualny Księgowy
Copyright © 2026 NexusAI Team. Wszelkie prawa zastrzeżone.

Niniejsza licencja Proprietary zabrania:
- Redystrybucji kodu źródłowego lub binarnego bez pisemnej zgody
- Modyfikacji i tworzenia dzieł pochodnych
- Inżynierii wstecznej (reverse engineering)
- Użytku komercyjnego bez aktywnej licencji
- Użytku w systemach krytycznych (medical, aviation, nuclear)

Zezwala na:
- Użytkowanie przez licencjonowane podmioty zgodnie z umową
- Audyt i testy bezpieczeństwa w ramach umowy SLA

Pełna treść: patrz LICENSE.txt w katalogu głównym repozytorium.
```

---

## Zgodność (compliance matrix)

| Standard | Wymóg | Status w NexusAI |
|---|---|---|
| **UoR** (Ustawa o rachunkowości, Dz.U. 1994 nr 121) | Art. 4, 6, 7, 13, 20, 22, 24, 28 | ✅ Pełny |
| **Ordynacja podatkowa** | Art. 86 § 1 (faktury), 70 § 1 (deklaracje) | ✅ Pełny |
| **KSeF** | FA_VAT(2) — XSD MF | ✅ Pełny |
| **JPK_V7** | Miesięczny + kwartalny | ✅ Pełny |
| **IFRS/MSSF** | 15, 16, IAS 2, 12, 16, 21 | ✅ |
| **RODO/GDPR** | Art. 5, 17, 25, 32 | ✅ Pełny |
| **OWASP Top 10 (2021)** | A01–A10 | ✅ Pokrycie 10/10 |
| **NIST SSDF** | PW.4, PS.1, RV.1 | ✅ |
| **SLSA** | Poziom 3 | ✅ |
| **OpenSSF Scorecard** | ≥ 7/10 | ✅ |

Szczegóły: [`docs/COMPLIANCE.md`](COMPLIANCE.md), [`docs/SECURITY.md`](SECURITY.md).

---

## Mapa dokumentacji

Pełna struktura dokumentacji z 21 sekcjami (0–20) — patrz [`docs/INDEX.md`](INDEX.md).

Nawigacja w 6 modułach iteracyjnych:

```
M1 Fundament    → README, 00_META, INTRODUCTION, QUICKSTART, PROJECT_STRUCTURE
M2 Architektura → ARCHITECTURE, DATABASE, MODULES, RUST_MODULE, MODELS_MANIFEST
M3 API          → API
M4 Operacje     → INSTALLATION, TESTING, DEPLOYMENT, TROUBLESHOOTING
M5 Bezpieczeństwo → SECURITY, COMPLIANCE
M6 Ludzie/proces→ CONTRIBUTING, USER_GUIDE, GLOSSARY, FAQ, BIBLIOGRAPHY, RELATED, CHANGELOG
```

---

## Kontakt i wsparcie

- 🐛 **Błędy**: [GitHub Issues](https://github.com/Gorski-Maciej/NexusAI/issues) — etykieta `bug`
- 💡 **Pomysły**: GitHub Issues — etykieta `enhancement`
- 🔒 **Bezpieczeństwo**: security@nexus-ai.pl (PGP key dostępna) — NIE zgłaszaj publicznie
- 📚 **Wiki**: [github.com/Gorski-Maciej/NexusAI/wiki](https://github.com/Gorski-Maciej/NexusAI/wiki)
- 💼 **Licencja komercyjna**: sales@nexus-ai.pl

---

## 🔗 Zobacz również

- [README.md (strona główna)](../README.md)
- [Spis treści](INDEX.md)
- [Wprowadzenie](INTRODUCTION.md) — pełna wersja PWE + persony
- [Changelog](CHANGELOG.md) — historia wersji

---

> **Data aktualizacji:** 2026-07-05 · **Autor:** NexusAI Team · **Wersja:** 2.3.0
> **Status dokumentu:** Stabilny · **Ostatnia weryfikacja:** 2026-07-05 · **Weryfikator:** Technical Lead
