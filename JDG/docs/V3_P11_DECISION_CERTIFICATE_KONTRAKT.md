# KONTRAKT V3-P11 — DECISION CERTIFICATE (V2/F4)

> Seria V3 (GLM 5.2) · Część P11 · Status: WDROŻONY_100 · Data: 2026-09-03
> Dokument wiążący dla P12, P36, P41, P43, P44, P38, P39, P10, P03, P01/P05.
> Pełny raport: `raporty_glm52_v3/RAPORT_V3_P11_DECISION_CERTIFICATE.txt`.

## 1. Schemat certyfikatu i warstwa ludzka
K1. Certificate Schema v1 (I01): certyfikat JSON = NADZBIÓR pól werdyktu (P03);
    pola top-level: `certificate_id` (DC-YYYY-MM-DD-NNNNNNNN), `transaction_date`,
    `certainty_class`, `decision` (rule_id, matched, legal_basis, legal_basis_refs,
    bundle_version, rule_version, invariant_violations), `seal`, `generated_at`,
    `legal_quote`, `human_explanation`. Wiąże P41 (UI/API), P44, P03.
K2. PDF = odwzorowanie 1:1 JSON (zero informacji w PDF, których nie ma w JSON);
    sekcje PDF: nagłówek → decyzja → klasa pewności → podstawa prawna z cytatem
    przepisu w wersji z dnia transakcji (P01/P05) → progi/wartości → wersje
    (reguła/bundle/threshold) → pieczęć/QR → stopka. Wiąże P41, P01, P05.
K3. Trust UI (I08): wyjaśnienie warstwowe (krótko → szczegółowo → pełny dowód);
    status weryfikacji zielony/żółty/czerwony; „pokaż dowód"; konsekwencje klasy
    pewności jawne (AUTO_POST wyłącznie przy CERTAIN i pełnym dowodzie).
    Wiąże P41, P03, P09.

## 2. Warstwa kryptograficzna
K4. Merkle Daily Tree (I02): hash per werdykt → drzewo dzienne → root miesięczny →
    PUBLICZNY rejestr rootów (transparencja). Zastępuje Merkle-LITE
    (payload_hash == merkle_root) w decision_certificate.py. Wiąże P43, P38, P44.
K5. HSM Key Ceremony (I07): podpis = prawdziwy klucz HSM/KMS (ECDSA/RSA), NIE
    placeholder `HSM-ECDSA-<hash>`; seal niesie `kid` + `key_version` + algorytm;
    rotacja kwartalna bez łamania weryfikowalności starych certyfikatów; klucze
    offline DR; audyt ceremonii 4-eyes. Wiąże P43 (security/DR), P38, P07.
K6. Long-Term Validation (I11): seal z timestamp + algorytm + kid; retencja WORM
    50 lat audytowych (art. 74 uor, art. 86 § 1 i 3 Ordynacji podatkowej);
    weryfikacja starych certyfikatów przez dekady bez sieci. Wiąże P43, P44.
K7. Batch Signing (I10): podpis batchowy (root grupy dziennej) z budżetem latencji
    SLO; metryki czasu podpisu do obserwowalności (P37); zero degeneracji SLO.
    Wiąże P02 (SLO/latency), P37.

## 3. Cykl życia i korekty
K8. Correction Chain (I04): korekta decyzji = NOWY podpisany certyfikat z polem
    `supersedes=<original_id>`; łańcuch wersji oryginał→korekta1→korekta2; oryginał
    w WORM nietykalny (append-only). Wiąże P36, P07, P44.
K9. Revocation Manifest (I05): podpisany manifest unieważnień (CRL decyzyjny)
    rozpowszechniany z certyfikatami; unieważnienie wymaga uprawnień + 4-eyes;
    weryfikacja offline sprawdza certyfikat przeciw manifestowi. Wiąże P36, P07.
K10. KAS Export Bundle (I06): paczka dla organu = certyfikaty + merkle root +
     snapshoty przepisów (P01/P05) + manifest z hashami i podpisem całości;
     weryfikowalna offline w całości. Wiąże P44 (dowód dla organów), P01/P05.

## 4. Weryfikacja offline i testy
K11. Offline Verifier CLI (I03): samodzielny weryfikator bez sieci (podpis → merkle
     root → legal refs hash → kompletność kontraktu); weryfikacja KONTENSU
     (recompute), nie kształtu; test dekady (certyfikat sprzed lat weryfikuje się
     dziś). Wiąże P44, P41.
K12. Tamper Test Suite (I09): mutacja dowolnej grupy pól certyfikatu →
     weryfikacja offline MUSI zawieść (verified=False); asercje negatywne jako
     bramka CI (P39); spójne z mutation testing (P04/P10). Wiąże P39, P44.
K13. Certificate Golden Link (I12): każda decyzja golden setu (P10) ma certyfikat
     z `golden_verdict_id` + `verdict_hash`; spójność oracle↔certyfikat weryfikowana
     w CI (zero cichych rozjazdów). Wiąże P10, P44, P03.

## 5. Wiązania międzyczęściowe
- P11 otrzymuje z: P03 (kontrakt werdyktu, klasy pewności), P01/P05 (legal refs,
  temporalność, cytat przepisu z dnia transakcji), P10 (golden oracle).
- P11 przekazuje do: P41 (UI/API — schemat certyfikatu, status weryfikacji),
  P43 (WORM/DR — Merkle/HSM/retention 50 lat), P44 (certyfikacja finalna — eksport
  KAS, tamper tests), P36 (procesy — korekty/unieważnienia), P38 (deploy — klucze,
  batch signing), P39 (bramki CI — tamper + golden link), P37 (metryki LTV/podpisu).

## 6. Reguły fail-closed
- Weryfikacja offline NIGDY nie kończy się „OK" przy podpisie-placeholder
  (`HSM-ECDSA-<hash>`), braku kid/algorytmu, rozjeździe merkle lub mutacji pola.
- Certyfikat z klasą NEEDS_ADVICE nigdy nie upoważnia do AUTO_POST.
- Brak certyfikatu dla werdyktu golden = BLOCKER spójności (K13).
