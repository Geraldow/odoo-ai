# Odoo Implementation Playbook

Procesné usmernenie pre konzultantov pri scopingu a exekúcii Odoo implementácie.
Zamerané na rozhodnutia na úrovni projektu, nie na code patterns (tie žijú v
odoo-general, odoo-server-actions a odoo-actions-master).

---

## Vrstvy customizácie — vyberte najnižšiu, ktorá funguje

| Potreba | Nástroj | Prečo |
|---|---|---|
| Pridať pole / tlačidlo / jednoduchá zmena view | **Studio** | Žiadny modul, žiadny kód, prežije SaaS |
| Podmienený update poľa, odoslanie notifikácie, domain-driven flow | **Automated Action** (base.automation) | Hooknuté do ORM eventov, kompatibilné so Studiom |
| Manuálna jednorazová logika na požiadanie | **Server Action** so safe_eval | Sedí na tlačidle vo forme |
| Komplexná biznis logika, nové modely, externé integrácie | **Vlastný modul** (Odoo.sh / on-prem) | Vyžadované, keď potrebujete importy, nové triedy alebo heavy compute |

Pravidlo: posuňte sa o úroveň vyššie iba vtedy, keď vás aktuálna blokuje. Na Odoo
Online SaaS nie sú vlastné moduly opciou — všetko musí sedieť do
Studio + Automated Actions + Server Actions.

---

## Konvencia sequence pohľadov

| Zdroj | Typická sequence |
|---|---|
| Core Odoo views | 0 – 99 |
| Addon-module inherited views | 100 – 159 |
| Studio-generated views | 160+ |
| Vaše dedičnosti, ktoré musia vyhrať nad Studiom | 200+ |

Vyššia sequence sa aplikuje neskôr a vyhráva. Ak Studio pole zmizne po
tom, čo zdedíte view, bumpnite vašu sequence na 200+.

---

## Typické implementačné fázy

1. **Discovery**
   - Workshop: namapujte každý biznis proces na Odoo apps.
   - Identifikujte medzery (vlastné polia, reporty, workflow, integrácie).
   - Zdokumentujte verziu (18 vs 19), edition (Community vs Enterprise), hosting (Online vs .sh vs on-prem) — tieto obmedzujú každé neskoršie rozhodnutie.
2. **Design**
   - Plán migrácie dát (zdroje, mapping, dedup stratégia).
   - Inventár customizácie: Studio položky, automated actions, vlastné moduly.
   - Access model: companies, groups, record rules.
3. **Build**
   - Najprv nakonfigurujte core apps end-to-end, až potom pridávajte customizácie.
   - Customizujte naposledy — ľahšie je dropnúť Studio pole než ho prebudovať.
4. **Data load**
   - Najprv načítajte referenčné dáta (produkty, partneri, CoA) pred transakčnými (SO, faktúry, sklad).
   - Validujte počet riadkov AJ vzorkované riadky (exit kódy klamú).
5. **UAT**
   - Testujte golden path AJ edge cases, na ktorých zákazníkovi záleží.
   - Zaznamenajte testovanie access rights per role, nie iba "admin funguje".
6. **Go-live**
   - Zmrazte customizácie 1 týždeň pred cutover.
   - Oddeľte historické dáta na čistej hranici (napr. iba otvorené faktúry, zaplatené zostanú v legacy).
   - Pripravte rollback plán pre prvých 48 hodín.

---

## Testovacia stratégia

### Minimálny checklist pred go-live

- [ ] Vytvoriť SO → confirm → deliver → invoice → register payment (end-to-end)
- [ ] Purchase: RFQ → PO → receive goods → bill → pay
- [ ] Financial: post manuálny journal entry → spustiť Balance Sheet / P&L
- [ ] Access: prihlásiť sa ako každá rola (sales user, warehouse user, accountant, manager) a overiť viditeľnosť
- [ ] Vlastné polia sa správne renderujú vo všetkých dotknutých views (form, list, kanban, search)
- [ ] Server actions sa spúšťajú bez chýb aspoň pre jeden záznam
- [ ] Automated actions sa triggerujú na zamýšľanom triggeri a nie na nesúvisiacich záznamoch
- [ ] Reporty sa generujú (PDF aj obrazovka) pre reálny záznam
- [ ] Emaily sa odosielajú z test prostredia (šablóna + mail server)

### Validácia dát

Nikdy neverte len počtu riadkov. Vzorkujte a pozerajte:
- Akýkoľvek riadok s unikátnym prirodzeným kľúčom (order number, PO number, customer code).
- Akýkoľvek riadok s menou alebo množstvom — overte aritmetiku na import totals.
- Preklady: ak multi-language, otvorte niekoľko záznamov v non-default jazyku.

---

## Handover checklist

Zdokumentujte toto; odovzdajte internému adminovi zákazníka alebo ďalšiemu konzultantovi.

- **Vlastné polia** — model, technický názov, typ, kde sa zobrazuje, účel
- **Automated / server actions** — trigger, model, čo robí, autor, owner
- **Scheduled actions (ir.cron)** — interval, owner kódu, failure kontakt
- **Access model** — groups, ktoré groups vidia/editujú ktoré záznamy, kde žijú pravidlá
- **Integrácie** — externý systém, auth metóda, endpointy, lokalita credentials, error channels
- **Skripty migrácie dát** — ako znovu spustiť, kde žijú zdroje, čo robiť pri zlyhaní
- **Go-live runbook** — rollback postup, kontakty, známe issues

Ak je zákazník na SaaS, zdokumentujte aj ako regenerovať API keys,
kto má admin prístup a kde žije Odoo billing kontakt.
