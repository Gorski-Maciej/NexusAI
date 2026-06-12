from __future__ import annotations

from enum import Enum

__NAMESPACE__ = "http://crd.gov.pl/xml/schematy/dziedzinowe/mf/2022/01/05/eD/DefinicjeTypy/"


class TkodKraju(Enum):
    """
    Słownik kodów krajów.

    :cvar AF: AFGANISTAN
    :cvar AX: ALAND ISLANDS
    :cvar AL: ALBANIA
    :cvar DZ: ALGIERIA
    :cvar AD: ANDORA
    :cvar AO: ANGOLA
    :cvar AI: ANGUILLA
    :cvar AQ: ANTARKTYDA
    :cvar AG: ANTIGUA I BARBUDA
    :cvar AN: ANTYLE HOLENDERSKIE
    :cvar SA: ARABIA SAUDYJSKA
    :cvar AR: ARGENTYNA
    :cvar AM: ARMENIA
    :cvar AW: ARUBA
    :cvar AU: AUSTRALIA
    :cvar AT: AUSTRIA
    :cvar AZ: AZERBEJDŻAN
    :cvar BS: BAHAMY
    :cvar BH: BAHRAJN
    :cvar BD: BANGLADESZ
    :cvar BB: BARBADOS
    :cvar BE: BELGIA
    :cvar BZ: BELIZE
    :cvar BJ: BENIN
    :cvar BM: BERMUDY
    :cvar BT: BHUTAN
    :cvar BY: BIAŁORUŚ
    :cvar BO: BOLIWIA
    :cvar BQ: BONAIRE, SINT EUSTATIUS I SABA
    :cvar BA: BOŚNIA I HERCEGOWINA
    :cvar BW: BOTSWANA
    :cvar BR: BRAZYLIA
    :cvar BN: BRUNEI DARUSSALAM
    :cvar IO: BRYTYJSKIE TERYTORIUM OCEANU INDYJSKIEGO
    :cvar BG: BUŁGARIA
    :cvar BF: BURKINA FASO
    :cvar BI: BURUNDI
    :cvar XC: CEUTA
    :cvar CL: CHILE
    :cvar CN: CHINY
    :cvar HR: CHORWACJA
    :cvar CW: CURAÇAO
    :cvar CY: CYPR
    :cvar TD: CZAD
    :cvar ME: CZARNOGÓRA
    :cvar DK: DANIA
    :cvar DM: DOMINIKA
    :cvar DO: DOMINIKANA
    :cvar DJ: DŻIBUTI
    :cvar EG: EGIPT
    :cvar EC: EKWADOR
    :cvar ER: ERYTREA
    :cvar EE: ESTONIA
    :cvar ET: ETIOPIA
    :cvar FK: FALKLANDY
    :cvar FJ: FIDŻI REPUBLIKA
    :cvar PH: FILIPINY
    :cvar FI: FINLANDIA
    :cvar FR: FRANCJA
    :cvar TF: FRANCUSKIE TERYTORIUM POŁUDNIOWE
    :cvar GA: GABON
    :cvar GM: GAMBIA
    :cvar GH: GHANA
    :cvar GI: GIBRALTAR
    :cvar GR: GRECJA
    :cvar GD: GRENADA
    :cvar GL: GRENLANDIA
    :cvar GE: GRUZJA
    :cvar GU: GUAM
    :cvar GG: GUERNSEY
    :cvar GY: GUJANA
    :cvar GF: GUJANA FRANCUSKA
    :cvar GP: GWADELUPA
    :cvar GT: GWATEMALA
    :cvar GN: GWINEA
    :cvar GQ: GWINEA RÓWNIKOWA
    :cvar GW: GWINEA-BISSAU
    :cvar HT: HAITI
    :cvar ES: HISZPANIA
    :cvar HN: HONDURAS
    :cvar HK: HONGKONG
    :cvar IN: INDIE
    :cvar ID: INDONEZJA
    :cvar IQ: IRAK
    :cvar IR: IRAN
    :cvar IE: IRLANDIA
    :cvar IS: ISLANDIA
    :cvar IL: IZRAEL
    :cvar JM: JAMAJKA
    :cvar JP: JAPONIA
    :cvar YE: JEMEN
    :cvar JE: JERSEY
    :cvar JO: JORDANIA
    :cvar KY: KAJMANY
    :cvar KH: KAMBODŻA
    :cvar CM: KAMERUN
    :cvar CA: KANADA
    :cvar QA: KATAR
    :cvar KZ: KAZACHSTAN
    :cvar KE: KENIA
    :cvar KG: KIRGISTAN
    :cvar KI: KIRIBATI
    :cvar CO: KOLUMBIA
    :cvar KM: KOMORY
    :cvar CG: KONGO
    :cvar CD: KONGO, REPUBLIKA DEMOKRATYCZNA
    :cvar KP: KOREAŃSKA REPUBLIKA LUDOWO-DEMOKRATYCZNA
    :cvar XK: KOSOWO
    :cvar CR: KOSTARYKA
    :cvar CU: KUBA
    :cvar KW: KUWEJT
    :cvar LA: LAOS
    :cvar LS: LESOTHO
    :cvar LB: LIBAN
    :cvar LR: LIBERIA
    :cvar LY: LIBIA
    :cvar LI: LIECHTENSTEIN
    :cvar LT: LITWA
    :cvar LV: ŁOTWA
    :cvar LU: LUKSEMBURG
    :cvar MK: MACEDONIA
    :cvar MG: MADAGASKAR
    :cvar YT: MAJOTTA
    :cvar MO: MAKAU
    :cvar MW: MALAWI
    :cvar MV: MALEDIWY
    :cvar MY: MALEZJA
    :cvar ML: MALI
    :cvar MT: MALTA
    :cvar MP: MARIANY PÓŁNOCNE
    :cvar MA: MAROKO
    :cvar MQ: MARTYNIKA
    :cvar MR: MAURETANIA
    :cvar MU: MAURITIUS
    :cvar MX: MEKSYK
    :cvar XL: MELILLA
    :cvar FM: MIKRONEZJA
    :cvar UM: MINOR
    :cvar MD: MOŁDOWA
    :cvar MC: MONAKO
    :cvar MN: MONGOLIA
    :cvar MS: MONTSERRAT
    :cvar MZ: MOZAMBIK
    :cvar MM: MYANMAR (BURMA)
    :cvar NA: NAMIBIA
    :cvar NR: NAURU
    :cvar NP: NEPAL
    :cvar NL: NIDERLANDY (HOLANDIA)
    :cvar DE: NIEMCY
    :cvar NE: NIGER
    :cvar NG: NIGERIA
    :cvar NI: NIKARAGUA
    :cvar NU: NIUE
    :cvar NF: NORFOLK
    :cvar NO: NORWEGIA
    :cvar NC: NOWA KALEDONIA
    :cvar NZ: NOWA ZELANDIA
    :cvar PS: OKUPOWANE TERYTORIUM PALESTYNY
    :cvar OM: OMAN
    :cvar PK: PAKISTAN
    :cvar PW: PALAU
    :cvar PA: PANAMA
    :cvar PG: PAPUA NOWA GWINEA
    :cvar PY: PARAGWAJ
    :cvar PE: PERU
    :cvar PN: PITCAIRN
    :cvar PF: POLINEZJA FRANCUSKA
    :cvar PL: POLSKA
    :cvar GS: POŁUDNIOWA GEORGIA I POŁUD.WYSPY SANDWICH
    :cvar PT: PORTUGALIA
    :cvar PR: PORTORYKO
    :cvar CF: REP.ŚRODKOWOAFRYKAŃSKA
    :cvar CZ: REPUBLIKA CZESKA
    :cvar KR: REPUBLIKA KOREI
    :cvar ZA: REPUBLIKA POŁUDNIOWEJ AFRYKI
    :cvar RE: REUNION
    :cvar RU: ROSJA
    :cvar RO: RUMUNIA
    :cvar RW: RWANDA
    :cvar EH: SAHARA ZACHODNIA
    :cvar BL: SAINT BARTHELEMY
    :cvar KN: SAINT KITTS I NEVIS
    :cvar LC: SAINT LUCIA
    :cvar MF: SAINT MARTIN
    :cvar VC: SAINT VINCENT I GRENADYNY
    :cvar SV: SALWADOR
    :cvar WS: SAMOA
    :cvar AS: SAMOA AMERYKAŃSKIE
    :cvar SM: SAN MARINO
    :cvar SN: SENEGAL
    :cvar RS: SERBIA
    :cvar SC: SESZELE
    :cvar SL: SIERRA LEONE
    :cvar SG: SINGAPUR
    :cvar SK: SŁOWACJA
    :cvar SI: SŁOWENIA
    :cvar SO: SOMALIA
    :cvar LK: SRI LANKA
    :cvar PM: SAINT PIERRE I MIQUELON
    :cvar US: STANY ZJEDNOCZONE AMERYKI
    :cvar SZ: SUAZI
    :cvar SD: SUDAN
    :cvar SS: SUDAN POŁUDNIOWY
    :cvar SR: SURINAM
    :cvar SJ: SVALBARD I JAN MAYEN
    :cvar SH: ŚWIĘTA HELENA
    :cvar SY: SYRIA
    :cvar CH: SZWAJCARIA
    :cvar SE: SZWECJA
    :cvar TJ: TADŻYKISTAN
    :cvar TH: TAJLANDIA
    :cvar TW: TAJWAN
    :cvar TZ: TANZANIA
    :cvar TG: TOGO
    :cvar TK: TOKELAU
    :cvar TO: TONGA
    :cvar TT: TRYNIDAD I TOBAGO
    :cvar TN: TUNEZJA
    :cvar TR: TURCJA
    :cvar TM: TURKMENISTAN
    :cvar TV: TUVALU
    :cvar UG: UGANDA
    :cvar UA: UKRAINA
    :cvar UY: URUGWAJ
    :cvar UZ: UZBEKISTAN
    :cvar VU: VANUATU
    :cvar WF: WALLIS I FUTUNA
    :cvar VA: WATYKAN
    :cvar HU: WĘGRY
    :cvar VE: WENEZUELA
    :cvar GB: WIELKA BRYTANIA
    :cvar VN: WIETNAM
    :cvar IT: WŁOCHY
    :cvar TL: WSCHODNI TIMOR
    :cvar CI: WYBRZEŻE KOŚCI SŁONIOWEJ
    :cvar BV: WYSPA BOUVETA
    :cvar CX: WYSPA BOŻEGO NARODZENIA
    :cvar IM: WYSPA MAN
    :cvar SX: WYSPA SINT MAARTEN (CZĘŚĆ HOLENDERSKA WYSPY)
    :cvar CK: WYSPY COOKA
    :cvar VI: WYSPY DZIEWICZE-USA
    :cvar VG: WYSPY DZIEWICZE-W.B.
    :cvar HM: WYSPY HEARD I MCDONALD
    :cvar CC: WYSPY KOKOSOWE (KEELINGA)
    :cvar MH: WYSPY MARSHALLA
    :cvar FO: WYSPY OWCZE
    :cvar SB: WYSPY SALOMONA
    :cvar ST: WYSPY ŚWIĘTEGO TOMASZA I KSIĄŻĘCA
    :cvar TC: WYSPY TURKS I CAICOS
    :cvar ZM: ZAMBIA
    :cvar CV: ZIELONY PRZYLĄDEK
    :cvar ZW: ZIMBABWE
    :cvar AE: ZJEDNOCZONE EMIRATY ARABSKIE
    :cvar XI: ZJEDNOCZONE KRÓLESTWO (IRLANDIA PÓŁNOCNA)
    """

    AF = "AF"
    AX = "AX"
    AL = "AL"
    DZ = "DZ"
    AD = "AD"
    AO = "AO"
    AI = "AI"
    AQ = "AQ"
    AG = "AG"
    AN = "AN"
    SA = "SA"
    AR = "AR"
    AM = "AM"
    AW = "AW"
    AU = "AU"
    AT = "AT"
    AZ = "AZ"
    BS = "BS"
    BH = "BH"
    BD = "BD"
    BB = "BB"
    BE = "BE"
    BZ = "BZ"
    BJ = "BJ"
    BM = "BM"
    BT = "BT"
    BY = "BY"
    BO = "BO"
    BQ = "BQ"
    BA = "BA"
    BW = "BW"
    BR = "BR"
    BN = "BN"
    IO = "IO"
    BG = "BG"
    BF = "BF"
    BI = "BI"
    XC = "XC"
    CL = "CL"
    CN = "CN"
    HR = "HR"
    CW = "CW"
    CY = "CY"
    TD = "TD"
    ME = "ME"
    DK = "DK"
    DM = "DM"
    DO = "DO"
    DJ = "DJ"
    EG = "EG"
    EC = "EC"
    ER = "ER"
    EE = "EE"
    ET = "ET"
    FK = "FK"
    FJ = "FJ"
    PH = "PH"
    FI = "FI"
    FR = "FR"
    TF = "TF"
    GA = "GA"
    GM = "GM"
    GH = "GH"
    GI = "GI"
    GR = "GR"
    GD = "GD"
    GL = "GL"
    GE = "GE"
    GU = "GU"
    GG = "GG"
    GY = "GY"
    GF = "GF"
    GP = "GP"
    GT = "GT"
    GN = "GN"
    GQ = "GQ"
    GW = "GW"
    HT = "HT"
    ES = "ES"
    HN = "HN"
    HK = "HK"
    IN = "IN"
    ID = "ID"
    IQ = "IQ"
    IR = "IR"
    IE = "IE"
    IS = "IS"
    IL = "IL"
    JM = "JM"
    JP = "JP"
    YE = "YE"
    JE = "JE"
    JO = "JO"
    KY = "KY"
    KH = "KH"
    CM = "CM"
    CA = "CA"
    QA = "QA"
    KZ = "KZ"
    KE = "KE"
    KG = "KG"
    KI = "KI"
    CO = "CO"
    KM = "KM"
    CG = "CG"
    CD = "CD"
    KP = "KP"
    XK = "XK"
    CR = "CR"
    CU = "CU"
    KW = "KW"
    LA = "LA"
    LS = "LS"
    LB = "LB"
    LR = "LR"
    LY = "LY"
    LI = "LI"
    LT = "LT"
    LV = "LV"
    LU = "LU"
    MK = "MK"
    MG = "MG"
    YT = "YT"
    MO = "MO"
    MW = "MW"
    MV = "MV"
    MY = "MY"
    ML = "ML"
    MT = "MT"
    MP = "MP"
    MA = "MA"
    MQ = "MQ"
    MR = "MR"
    MU = "MU"
    MX = "MX"
    XL = "XL"
    FM = "FM"
    UM = "UM"
    MD = "MD"
    MC = "MC"
    MN = "MN"
    MS = "MS"
    MZ = "MZ"
    MM = "MM"
    NA = "NA"
    NR = "NR"
    NP = "NP"
    NL = "NL"
    DE = "DE"
    NE = "NE"
    NG = "NG"
    NI = "NI"
    NU = "NU"
    NF = "NF"
    NO = "NO"
    NC = "NC"
    NZ = "NZ"
    PS = "PS"
    OM = "OM"
    PK = "PK"
    PW = "PW"
    PA = "PA"
    PG = "PG"
    PY = "PY"
    PE = "PE"
    PN = "PN"
    PF = "PF"
    PL = "PL"
    GS = "GS"
    PT = "PT"
    PR = "PR"
    CF = "CF"
    CZ = "CZ"
    KR = "KR"
    ZA = "ZA"
    RE = "RE"
    RU = "RU"
    RO = "RO"
    RW = "RW"
    EH = "EH"
    BL = "BL"
    KN = "KN"
    LC = "LC"
    MF = "MF"
    VC = "VC"
    SV = "SV"
    WS = "WS"
    AS = "AS"
    SM = "SM"
    SN = "SN"
    RS = "RS"
    SC = "SC"
    SL = "SL"
    SG = "SG"
    SK = "SK"
    SI = "SI"
    SO = "SO"
    LK = "LK"
    PM = "PM"
    US = "US"
    SZ = "SZ"
    SD = "SD"
    SS = "SS"
    SR = "SR"
    SJ = "SJ"
    SH = "SH"
    SY = "SY"
    CH = "CH"
    SE = "SE"
    TJ = "TJ"
    TH = "TH"
    TW = "TW"
    TZ = "TZ"
    TG = "TG"
    TK = "TK"
    TO = "TO"
    TT = "TT"
    TN = "TN"
    TR = "TR"
    TM = "TM"
    TV = "TV"
    UG = "UG"
    UA = "UA"
    UY = "UY"
    UZ = "UZ"
    VU = "VU"
    WF = "WF"
    VA = "VA"
    HU = "HU"
    VE = "VE"
    GB = "GB"
    VN = "VN"
    IT = "IT"
    TL = "TL"
    CI = "CI"
    BV = "BV"
    CX = "CX"
    IM = "IM"
    SX = "SX"
    CK = "CK"
    VI = "VI"
    VG = "VG"
    HM = "HM"
    CC = "CC"
    MH = "MH"
    FO = "FO"
    SB = "SB"
    ST = "ST"
    TC = "TC"
    ZM = "ZM"
    CV = "CV"
    ZW = "ZW"
    AE = "AE"
    XI = "XI"
