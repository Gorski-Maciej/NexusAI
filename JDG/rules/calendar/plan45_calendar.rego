# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.calendar hyper-granularity (Doc 45: R1368-R1402)
# Atom rules: per-tax deadlines, alerts, weekend/holiday shifts, annual forecast
# Rules: 35 atom — each with differentiated trigger conditions
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.calendar.hyper
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.calendar.hyper.no_match","package":"jdg.calendar.hyper","priority":99999}

# ══ R1368-R1372: VAT Deadlines ══
decide := {"matched":true,"rule_id":"jdg.calendar.hyper.vat_monthly_25th","package":"jdg.calendar.hyper","priority":1368,"_routing":"WARNING","_routing_reason":"VAT: miesięczny do 25.","_legal_basis":"Art. 103 ust. 1 VAT","_warnings":["VAT miesięczny — złóż JPK_V7 i zapłać do 25. dnia następnego miesiąca"]} {
    object.get(input.jdg_entrepreneur, "vat_filing_frequency", "") == "MONTHLY"
}
else := {"matched":true,"rule_id":"jdg.calendar.hyper.vat_quarterly_25th","package":"jdg.calendar.hyper","priority":1369,"_routing":"WARNING","_routing_reason":"VAT: kwartalny do 25.","_legal_basis":"Art. 103 ust. 2 VAT","_warnings":["VAT kwartalny — złóż JPK_V7 i zapłać do 25. dnia po kwartale"]} {
    object.get(input.jdg_entrepreneur, "vat_filing_frequency", "") == "QUARTERLY"
}
else := {"matched":true,"rule_id":"jdg.calendar.hyper.vat_weekend_shift","package":"jdg.calendar.hyper","priority":1370,"_routing":"","_routing_reason":"VAT: przesunięcie terminu na dzień roboczy","_legal_basis":"Art. 12 § 5 OP","_warnings":["Termin VAT w weekend/święto — przesunięty na następny dzień roboczy"]} {
    object.get(input.jdg_entrepreneur, "vat_deadline_on_weekend", false) == true
}
else := {"matched":true,"rule_id":"jdg.calendar.hyper.vat_arrears_interest","package":"jdg.calendar.hyper","priority":1371,"_routing":"WARNING","_routing_reason":"VAT: zaległość + odsetki","_legal_basis":"Art. 56 OP","_warnings":["VAT niezapłacony w terminie — odsetki za zwłokę od dnia następującego po terminie"]} {
    object.get(input.jdg_entrepreneur, "vat_payment_overdue", false) == true
}
else := {"matched":true,"rule_id":"jdg.calendar.hyper.vat_annual_correction_deadline","package":"jdg.calendar.hyper","priority":1372,"_routing":"WARNING","_routing_reason":"VAT: korekta roczna","_legal_basis":"Art. 86 ust. 7a VAT","_warnings":["Korekta roczna VAT (współczynnik) — złóż do 25. stycznia następnego roku"]} {
    object.get(input.jdg_entrepreneur, "vat_annual_correction_due", false) == true
}

# ══ R1373-R1377: PIT Deadlines ══
else := {"matched":true,"rule_id":"jdg.calendar.hyper.pit_advance_20th","package":"jdg.calendar.hyper","priority":1373,"_routing":"WARNING","_routing_reason":"PIT: zaliczka do 20.","_legal_basis":"Art. 44 ust. 6 PIT","_warnings":["Zaliczka miesięczna PIT — zapłać do 20. dnia następnego miesiąca"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") != "LUMP_SUM"
    object.get(input.jdg_entrepreneur, "monthly_advance_due", false) == true
}
else := {"matched":true,"rule_id":"jdg.calendar.hyper.pit_lump_sum_20th","package":"jdg.calendar.hyper","priority":1374,"_routing":"WARNING","_routing_reason":"Ryczałt: do 20.","_legal_basis":"Art. 21 ust. 1 u.z.p.d.","_warnings":["Ryczałt — zapłać miesięcznie do 20. dnia (lub kwartalnie do 20. po kwartale)"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") == "LUMP_SUM"
    object.get(input.jdg_entrepreneur, "monthly_advance_due", false) == true
}
else := {"matched":true,"rule_id":"jdg.calendar.hyper.pit_annual_return_30april","package":"jdg.calendar.hyper","priority":1375,"_routing":"WARNING","_routing_reason":"PIT: zeznanie roczne do 30.04","_legal_basis":"Art. 45 ust. 1 PIT","_warnings":["Zeznanie roczne PIT-36/PIT-36L/PIT-28 — złóż do 30 kwietnia!"]} {
    object.get(input.jdg_entrepreneur, "annual_return_due", false) == true
}
else := {"matched":true,"rule_id":"jdg.calendar.hyper.pit_shift_weekend","package":"jdg.calendar.hyper","priority":1376,"_routing":"","_routing_reason":"PIT: przesunięcie weekendowe","_legal_basis":"Art. 12 § 5 OP","_warnings":["Termin PIT w weekend/święto — przesunięty na następny dzień roboczy"]} {
    object.get(input.jdg_entrepreneur, "pit_deadline_on_weekend", false) == true
}
else := {"matched":true,"rule_id":"jdg.calendar.hyper.pit_arrears_interest","package":"jdg.calendar.hyper","priority":1377,"_routing":"WARNING","_routing_reason":"PIT: zaległość + odsetki","_legal_basis":"Art. 56 OP","_warnings":["PIT niezapłacony w terminie — odsetki za zwłokę"]} {
    object.get(input.jdg_entrepreneur, "pit_payment_overdue", false) == true
}

# ══ R1378-R1382: ZUS Deadlines ══
else := {"matched":true,"rule_id":"jdg.calendar.hyper.zus_no_employees_10th","package":"jdg.calendar.hyper","priority":1378,"_routing":"WARNING","_routing_reason":"ZUS: JDG bez prac. do 10.","_legal_basis":"Art. 47 ust. 1 pkt 1 SUS","_warnings":["ZUS — JDG bez pracowników: złóż DRA i zapłać do 10. dnia miesiąca"]} {
    object.get(input.jdg_entrepreneur, "employee_count", 0) == 0
    object.get(input.jdg_entrepreneur, "zus_contributions_due", false) == true
}
else := {"matched":true,"rule_id":"jdg.calendar.hyper.zus_employees_15th","package":"jdg.calendar.hyper","priority":1379,"_routing":"WARNING","_routing_reason":"ZUS: z prac. do 15.","_legal_basis":"Art. 47 ust. 1 pkt 2 SUS","_warnings":["ZUS — JDG z pracownikami (do 5): złóż DRA i zapłać do 15. dnia miesiąca"]} {
    object.get(input.jdg_entrepreneur, "employee_count", 0) > 0
    object.get(input.jdg_entrepreneur, "employee_count", 0) <= 5
    object.get(input.jdg_entrepreneur, "zus_contributions_due", false) == true
}
else := {"matched":true,"rule_id":"jdg.calendar.hyper.zus_units_15th","package":"jdg.calendar.hyper","priority":1380,"_routing":"WARNING","_routing_reason":"ZUS: wszyscy płatnicy do 15. (v7.0 FIX K47-1)","_legal_basis":"Art. 47 ust. 1 pkt 2 SUS","_warnings":["ZUS — termin płatności: 15. dnia miesiąca (v7.0 FIX K47-1: popr. z 20. na 15.)"]} {
    object.get(input.jdg_entrepreneur, "employee_count", 0) > 5
    object.get(input.jdg_entrepreneur, "zus_contributions_due", false) == true
}
else := {"matched":true,"rule_id":"jdg.calendar.hyper.zus_weekend_shift","package":"jdg.calendar.hyper","priority":1381,"_routing":"","_routing_reason":"ZUS: przesunięcie weekendowe","_legal_basis":"Art. 12 § 5 OP","_warnings":["Termin ZUS w weekend/święto — przesunięty na następny dzień roboczy"]} {
    object.get(input.jdg_entrepreneur, "zus_deadline_on_weekend", false) == true
}
else := {"matched":true,"rule_id":"jdg.calendar.hyper.zus_arrears","package":"jdg.calendar.hyper","priority":1382,"_routing":"WARNING","_routing_reason":"ZUS: zaległość","_legal_basis":"Art. 24 SUS","_warnings":["ZUS niezapłacony w terminie — odsetki za zwłokę + możliwość egzekucji"]} {
    object.get(input.jdg_entrepreneur, "zus_payment_overdue", false) == true
}

# ══ R1383-R1387: PCC Deadlines ══
else := {"matched":true,"rule_id":"jdg.calendar.hyper.pcc3_deadline_14days","package":"jdg.calendar.hyper","priority":1383,"_routing":"WARNING","_routing_reason":"PCC-3: 14 dni od czynności","_legal_basis":"Art. 10 ust. 1 PCC","_warnings":["PCC-3 — złóż w ciągu 14 dni od zawarcia umowy cywilnoprawnej"]} {
    object.get(input.jdg_entrepreneur, "pcc_obligation", false) == true
}
else := {"matched":true,"rule_id":"jdg.calendar.hyper.pcc_payment_14days","package":"jdg.calendar.hyper","priority":1384,"_routing":"WARNING","_routing_reason":"PCC: zapłata 14 dni","_legal_basis":"Art. 10 ust. 1 PCC","_warnings":["PCC — zapłać podatek w ciągu 14 dni od powstania obowiązku"]} {
    object.get(input.jdg_entrepreneur, "pcc_obligation", false) == true
}
else := {"matched":true,"rule_id":"jdg.calendar.hyper.pcc_weekend_shift","package":"jdg.calendar.hyper","priority":1385,"_routing":"","_routing_reason":"PCC: przesunięcie weekendowe","_legal_basis":"Art. 12 § 5 OP","_warnings":["Termin PCC w weekend/święto — przesunięty na następny dzień roboczy"]} {
    object.get(input.jdg_entrepreneur, "pcc_deadline_on_weekend", false) == true
}
else := {"matched":true,"rule_id":"jdg.calendar.hyper.pcc_arrears","package":"jdg.calendar.hyper","priority":1386,"_routing":"WARNING","_routing_reason":"PCC: zaległość","_legal_basis":"Art. 56 OP","_warnings":["PCC niezapłacony w terminie — odsetki za zwłokę"]} {
    object.get(input.jdg_entrepreneur, "pcc_payment_overdue", false) == true
}
else := {"matched":true,"rule_id":"jdg.calendar.hyper.pcc_exemptions_check","package":"jdg.calendar.hyper","priority":1387,"_routing":"","_routing_reason":"PCC: sprawdź zwolnienia","_legal_basis":"Art. 9 PCC","_warnings":["Sprawdź czy przysługuje zwolnienie z PCC (np. grupa 0 dla rodziny, VAT-owcy)"]} {
    object.get(input.jdg_entrepreneur, "pcc_exemption_possible", false) == true
}

# ══ R1388-R1392: Alerts ══
else := {"matched":true,"rule_id":"jdg.calendar.hyper.alert_7_days_before","package":"jdg.calendar.hyper","priority":1388,"_routing":"WARNING","_routing_reason":"Alert: 7 dni przed terminem","_legal_basis":"Art. 12 OP","_warnings":["Termin płatności za 7 dni — przygotuj środki"]} {
    object.get(input.jdg_entrepreneur, "days_to_next_deadline", 999) <= 7
    object.get(input.jdg_entrepreneur, "days_to_next_deadline", 999) >= 4
}
else := {"matched":true,"rule_id":"jdg.calendar.hyper.alert_3_days_before","package":"jdg.calendar.hyper","priority":1389,"_routing":"WARNING","_routing_reason":"Alert: 3 dni przed terminem","_legal_basis":"Art. 12 OP","_warnings":["Termin płatności za 3 dni — upewnij się, że masz środki na koncie!"]} {
    object.get(input.jdg_entrepreneur, "days_to_next_deadline", 999) <= 3
    object.get(input.jdg_entrepreneur, "days_to_next_deadline", 999) >= 2
}
else := {"matched":true,"rule_id":"jdg.calendar.hyper.alert_1_day_before","package":"jdg.calendar.hyper","priority":1390,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Alert: 1 dzień przed terminem","_legal_basis":"Art. 12 OP","_warnings":["Termin płatności JUTRO — zapłać natychmiast!"]} {
    object.get(input.jdg_entrepreneur, "days_to_next_deadline", 999) <= 1
    object.get(input.jdg_entrepreneur, "days_to_next_deadline", 999) > 0
}
else := {"matched":true,"rule_id":"jdg.calendar.hyper.alert_on_deadline_day","package":"jdg.calendar.hyper","priority":1391,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Alert: DZIŚ termin","_legal_basis":"Art. 12 OP","_warnings":["DZIŚ mija termin płatności — jeśli nie zapłaciłeś, zrób to TERAZ!"]} {
    object.get(input.jdg_entrepreneur, "days_to_next_deadline", 999) == 0
}
else := {"matched":true,"rule_id":"jdg.calendar.hyper.alert_overdue","package":"jdg.calendar.hyper","priority":1392,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Alert: PO terminie","_legal_basis":"Art. 56 OP","_warnings":["Termin minął! Naliczane są odsetki za zwłokę — zapłać natychmiast!"]} {
    object.get(input.jdg_entrepreneur, "days_to_next_deadline", 999) < 0
}

# ══ R1393-R1397: Annual Forecast ══
else := {"matched":true,"rule_id":"jdg.calendar.hyper.forecast_annual_tax","package":"jdg.calendar.hyper","priority":1393,"_routing":"","_routing_reason":"Prognoza roczna podatków","_legal_basis":"—","_warnings":["Prognoza roczna: suma PIT + VAT + ZUS + PCC na podstawie danych historycznych"]} {
    object.get(input.jdg_entrepreneur, "forecast_enabled", false) == true
}
else := {"matched":true,"rule_id":"jdg.calendar.hyper.forecast_history_trend","package":"jdg.calendar.hyper","priority":1394,"_routing":"","_routing_reason":"Prognoza: trend historyczny","_legal_basis":"—","_warnings":["Trend płatności: rosnący/malejący/stały na podstawie ostatnich 12 miesięcy"]} {
    object.get(input.jdg_entrepreneur, "forecast_enabled", false) == true
    object.get(input.jdg_entrepreneur, "history_available", false) == true
}
else := {"matched":true,"rule_id":"jdg.calendar.hyper.forecast_cash_flow_warning","package":"jdg.calendar.hyper","priority":1395,"_routing":"WARNING","_routing_reason":"Prognoza: ostrzeżenie cash-flow","_legal_basis":"—","_warnings":["Prognoza — możliwy niedobór środków w miesiącu z dużymi płatnościami"]} {
    object.get(input.jdg_entrepreneur, "cash_flow_warning", false) == true
}
else := {"matched":true,"rule_id":"jdg.calendar.hyper.forecast_optimization","package":"jdg.calendar.hyper","priority":1396,"_routing":"","_routing_reason":"Optymalizacja: przejście na kwartalne","_legal_basis":"Art. 103 ust. 2 VAT","_warnings":["Możesz przejść na kwartalne rozliczenia VAT — mniej terminów, lepsze cash-flow"]} {
    object.get(input.jdg_entrepreneur, "quarterly_vat_recommended", false) == true
}
else := {"matched":true,"rule_id":"jdg.calendar.hyper.forecast_next_quarter","package":"jdg.calendar.hyper","priority":1397,"_routing":"","_routing_reason":"Prognoza: następny kwartał","_legal_basis":"—","_warnings":["Prognoza na następny kwartał — nadchodzące terminy i szacowane kwoty"]} {
    object.get(input.jdg_entrepreneur, "forecast_enabled", false) == true
    object.get(input.jdg_entrepreneur, "next_quarter_forecast", false) == true
}

# ══ R1398-R1402: Weekend/Holiday Shifts ══
else := {"matched":true,"rule_id":"jdg.calendar.hyper.weekend_shift_saturday","package":"jdg.calendar.hyper","priority":1398,"_routing":"","_routing_reason":"Przesunięcie: sobota → poniedziałek","_legal_basis":"Art. 12 § 5 OP","_warnings":["Termin przypada w sobotę — przesunięty na poniedziałek"]} {
    object.get(input.document, "deadline_day_of_week", "") == "SATURDAY"
}
else := {"matched":true,"rule_id":"jdg.calendar.hyper.weekend_shift_sunday","package":"jdg.calendar.hyper","priority":1399,"_routing":"","_routing_reason":"Przesunięcie: niedziela → poniedziałek","_legal_basis":"Art. 12 § 5 OP","_warnings":["Termin przypada w niedzielę — przesunięty na poniedziałek"]} {
    object.get(input.document, "deadline_day_of_week", "") == "SUNDAY"
}
else := {"matched":true,"rule_id":"jdg.calendar.hyper.holiday_shift","package":"jdg.calendar.hyper","priority":1400,"_routing":"","_routing_reason":"Przesunięcie: święto państwowe","_legal_basis":"Art. 12 § 5 OP","_warnings":["Termin przypada w święto — przesunięty na następny dzień roboczy"]} {
    object.get(input.document, "deadline_is_holiday", false) == true
}
else := {"matched":true,"rule_id":"jdg.calendar.hyper.easter_shift","package":"jdg.calendar.hyper","priority":1401,"_routing":"","_routing_reason":"Przesunięcie: Wielkanoc","_legal_basis":"Art. 12 § 5 OP","_warnings":["Termin w Poniedziałek Wielkanocny — przesunięty na wtorek"]} {
    object.get(input.document, "deadline_is_easter_monday", false) == true
}
else := {"matched":true,"rule_id":"jdg.calendar.hyper.christmas_shift","package":"jdg.calendar.hyper","priority":1402,"_routing":"","_routing_reason":"Przesunięcie: Boże Narodzenie","_legal_basis":"Art. 12 § 5 OP","_warnings":["Termin w dniach 25-26 grudnia — przesunięty na 27 grudnia (lub następny dzień roboczy)"]} {
    object.get(input.document, "deadline_is_christmas", false) == true
}
