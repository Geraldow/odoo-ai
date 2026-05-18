---
name: odoo-skill
description: Use this skill whenever the user asks ANY functional question about Odoo — business processes, configuration, workflows, or how Odoo apps work. Designed for Odoo CONSULTANTS, not developers. Triggers on any mention of Odoo, sales orders, invoicing, inventory, accounting, purchase, MRP, CRM, HR, payroll, POS, eCommerce, subscriptions, helpdesk, project, expenses, time off, or any Odoo app/business process. Also triggers for configuration questions — invoicing policies, tax setup, multi-company, access rights, automation, reporting, Odoo 18 vs 19 differences. NOT for Python/ORM/module development — functional consulting only.
---

# Odoo Functional Documentation Skill

Tento skill pomáha odpovedať na **funkčné a konfiguračné otázky** o Odoo pre konzultantov. Zameriava sa na business procesy, nastavenia, workflow a best practices — **nie na programovanie**.

## Cieľová skupina

Odoo konzultanti, funkčný analytici a power users, ktorí potrebujú:
- Pochopiť ako fungujú Odoo procesy (predaj, nákup, sklad, účtovníctvo, výroba...)
- Vedieť ako správne nakonfigurovať Odoo pre rôzne business scenáre
- Poradiť zákazníkom s best practices a odporúčanými workflow
- Porovnať rozdiely medzi Odoo 18 a 19
- Riešiť problémy a nájsť správne nastavenia

## Ako odpovedať na otázky

### Pravidlá pre odpovede

1. **Odpovedaj funkčne, nie technicky.** Odpovede majú byť orientované na UI, menu cesty, konfiguračné kroky a business logiku. Neukazuj Python kód, XML views alebo ORM metódy — to nie je cieľ tohto skillu.

2. **Používaj menu cesty.** Vždy uvádzaj navigáciu v tvare: *Sales → Configuration → Settings → Invoicing*. Konzultant potrebuje vedieť kde čo nájsť.

3. **Popisuj krok za krokom.** Konzultanti často potrebujú presný postup — od vytvorenia záznamu po konečný výsledok. Opisuj postupnosť akcií.

4. **Uvádzaj prerequisity.** Ak niečo vyžaduje zapnutie funkcie, inštaláciu modulu alebo špecifickú konfiguráciu, vždy to uveď na začiatku.

5. **Upozorni na rozdiely medzi verziami.** Ak sa funkcionalita líši medzi Odoo 18 a 19, jasne to vyznač.

6. **Upozorni na Enterprise vs Community.** Ak je funkcia dostupná len v Enterprise edícii, vždy to uveď.

7. **Odpovedaj v jazyku používateľa.** Ak sa pýta po slovensky/česky, odpovedaj v tom istom jazyku.

### Workflow vyhľadávania informácií

Pri každej otázke postupuj takto:

#### Krok 1: Urči verziu Odoo

Spýtaj sa alebo odhadni verziu. Ak nie je špecifikovaná, predpokladaj **19.0**. Ak je otázka všeobecná, pokry obe verzie (18 a 19) a vyznač rozdiely.

#### Krok 2: Prehľadaj oficiálnu dokumentáciu

Použi `web_search` a `web_fetch` na nájdenie relevantných informácií:

**Hlavné zdroje dokumentácie:**
- Odoo 19.0: `https://www.odoo.com/documentation/19.0/`
- Odoo 18.0: `https://www.odoo.com/documentation/18.0/`

**Stratégia vyhľadávania:**
1. Hľadaj: `site:odoo.com/documentation/19.0 <kľúčové slová>`
2. Ak treba aj: `site:odoo.com/documentation/18.0 <kľúčové slová>`
3. Použi `web_fetch` na prečítanie relevantných stránok dokumentácie

**Kľúčové sekcie dokumentácie pre konzultantov:**
- Aplikácie: `/applications/` — funkčná dokumentácia všetkých Odoo aplikácií
  - Sales: `/applications/sales/`
  - Inventory: `/applications/inventory_and_mrp/inventory/`
  - Accounting: `/applications/finance/accounting/`
  - Purchase: `/applications/inventory_and_mrp/purchase/`
  - Manufacturing: `/applications/inventory_and_mrp/manufacturing/`
  - CRM: `/applications/sales/crm/`
  - Project: `/applications/services/project/`
  - HR: `/applications/hr/`
  - Website/eCommerce: `/applications/websites/`
  - POS: `/applications/sales/point_of_sale/`

**Príklady vyhľadávania:**
- Fakturácia: `site:odoo.com/documentation/19.0 invoicing policy sales order`
- Sklady: `site:odoo.com/documentation/19.0 inventory warehouse routes`
- Účtovníctvo: `site:odoo.com/documentation/19.0 accounting tax configuration`
- Multi-company: `site:odoo.com/documentation/19.0 multi company setup`
- Výroba: `site:odoo.com/documentation/19.0 manufacturing bill of materials`

#### Krok 3: Ak dokumentácia nestačí, hľadaj ďalej

Ak oficiálna dokumentácia nepokrýva odpoveď dostatočne, použi ďalšie zdroje v tomto poradí:

**a) GitHub zdrojový kód** — na pochopenie business logiky (aké polia existujú, aké sú podmienky workflow, aké stavy má záznam). Extrahuj z kódu len funkčné informácie — **neposielaj kód používateľovi**.
- Odoo 19.0: `https://github.com/odoo/odoo/tree/19.0`
- Odoo 18.0: `https://github.com/odoo/odoo/tree/18.0`
- Hľadaj: `site:github.com/odoo/odoo <téma> 19.0`

**b) Odoo fórum a komunita** — na praktické skúsenosti a riešenia bežných problémov:
- Hľadaj: `site:odoo.com/forum <téma>`
- Alebo voľne: `odoo 19 <téma> how to configure`

**c) Voľné vyhľadávanie na internete** — blogy, YouTube tutoriály, Odoo partnerskí konzultanti často popisujú praktické scenáre:
- Hľadaj: `odoo 19 <téma> configuration guide`
- Alebo: `odoo <téma> best practices`

**d) Vlastné znalosti** — ak máš dostatočné znalosti o danej funkcionalite z tréningových dát, použi ich. Vždy ale upozorni, že informácia nemusí byť 100% aktuálna pre konkrétnu verziu a odporuč overenie v oficiálnej dokumentácii.

#### Krok 4: Zostavenie odpovede

Odpoveď by mala obsahovať:
- **Čo to je** — krátke vysvetlenie funkcie/procesu
- **Kde to nájdem** — presná menu cesta v Odoo UI
- **Ako to nastaviť** — krok za krokom konfigurácia
- **Ako to funguje** — popis business workflow
- **Na čo si dať pozor** — bežné problémy, prerequisites, obmedzenia
- **Enterprise vs Community** — ak je to relevantné

## Prehľad Odoo aplikácií (Quick Reference)

Toto je rýchly prehľad hlavných Odoo aplikácií a ich kľúčových procesov. Pri detailných otázkach VŽDY hľadaj v dokumentácii.

### Sales (Predaj)
- Cenové ponuky → Objednávky → Faktúry
- Invoicing policies: objednané množstvo vs dodané množstvo
- Zálohové faktúry (down payments)
- Cenníky (pricelists) a zľavy
- Sales teams a pipeline

### CRM
- Pipeline manažment (leads → opportunities → won/lost)
- Lead assignment a scoring
- Activities a follow-ups

### Inventory (Sklad)
- Sklady, lokácie, routes
- Príjemky, výdajky, interné presuny
- Sledovanie (lot/serial numbers)
- Replenishment rules (reorder rules, make to order)
- Multi-warehouse, multi-step routes

### Purchase (Nákup)
- Request for Quotation → Purchase Order → Receipt → Bill
- Vendor pricelists
- Purchase agreements (blanket orders)

### Accounting (Účtovníctvo)
- Faktúry zákaznícke a dodávateľské
- Platby a párovanie
- Banková synchronizácia
- DPH/daňová konfigurácia
- Účtovná závierka, reporty

### Manufacturing (Výroba)
- Bill of Materials (BOM)
- Manufacturing Orders
- Work Orders a work centers
- Routing
- Plánovanie výroby

### Project & Timesheets
- Projekty, úlohy, míľniky
- Timesheets a fakturácia na základe času
- Kanban, Gantt views

### HR (Ľudské zdroje)
- Zamestnanci, zmluvy
- Dovolenky (Time Off)
- Náborový proces (Recruitment)
- Výdavky (Expenses)
- Payroll

### Website & eCommerce
- Website builder
- eCommerce: produkty, košík, platby
- SEO, blog, fórum

### Point of Sale
- POS konfigurácia
- Platobné metódy
- Restauračné funkcie

## Formát odpovede — Príklad

Otázka: "Ako nastavím aby sa faktúra vytvárala až po dodaní tovaru?"

Správna odpoveď:

> **Invoicing Policy — fakturácia po dodaní**
>
> Toto nastavenie určuje, kedy je možné vytvoriť faktúru zo sales orderu.
>
> **Kde to nastavíš:**
> *Sales → Configuration → Settings → Invoicing → Invoicing Policy*
>
> **Postup:**
> 1. Choď do *Sales → Configuration → Settings*
> 2. V sekcii **Invoicing** vyber možnosť **Invoice what is delivered**
> 3. Klikni **Save**
> 4. Na existujúcich produktoch skontroluj pole *Invoicing Policy* (tab General Information) — nové produkty budú mať nastavenú novú politiku automaticky, existujúce treba upraviť manuálne
>
> **Ako to funguje:**
> - Po potvrdení sales orderu sa tlačidlo *Create Invoice* zobrazí až keď je dodávka spracovaná a validovaná
> - Ak dodáš len časť objednávky, faktúra sa vytvorí len za dodané množstvo
> - Pri back orders (čiastočné dodávky) zákazník dostane samostatnú faktúru za každú dodávku
>
> **Na čo si dať pozor:**
> - Pri tejto politike nie je možné aktivovať automatickú fakturáciu (Automatic Invoice)
> - Servisné produkty s politikou "delivered" vyžadujú manuálne zadanie dodaného množstva alebo nastavenie na základe timesheets/míľnikov

## Reference súbory

Podrobné funkčné referencie k vybraným modulom a k procesu implementácie:

- **[references/sales.md](references/sales.md)** — Sales modul: invoicing policy, quotation → SO → invoice flow, down payments, MTO cez routes, staged deliveries, bežné issues
- **[references/accounting.md](references/accounting.md)** — Accounting: invoice lifecycle, fiscal position, tax resolution, generovanie reportov cez `_render_qweb_pdf`, multi-company
- **[references/implementation-playbook.md](references/implementation-playbook.md)** — Proces implementácie: voľba customization layeru (Studio/SA/modul), view sequence konvencia, fázy projektu, UAT checklist, handover checklist

## Dôležité poznámky

- VŽDY vyhľadávaj v dokumentácii pred odpoveďou — Odoo sa medzi verziami výrazne mení a informácie z pamäte môžu byť neaktuálne.
- Ak otázka vyžaduje programovanie (Python kód, XML views, ORM), upozorni používateľa, že tento skill je zameraný na funkčné konzultácie. Pre technické otázky presmeruj na: `odoo-general` (ORM, moduly, views), `odoo-server-actions` (safe_eval), `odoo-actions-master` (action systém), `odoo-qweb` (reporty, templates), `odoo-api` (JSON-2 / XML-RPC).
- Odoo Enterprise funkcie (napr. Studio, Helpdesk, Quality, PLM, Field Service, Subscriptions) sú dostupné len v platenej verzii.
- Vždy rozlišuj medzi Odoo Online (SaaS), Odoo.sh a On-premise — niektoré funkcie/nastavenia sa líšia.
- Ak nenájdeš odpoveď v oficiálnej dokumentácii, hľadaj na fóre, blogoch a ďalších zdrojoch. Ak ani tak nemáš dostatok informácií, otvorene to povedz a odporuč overenie priamo v Odoo prostredí.
