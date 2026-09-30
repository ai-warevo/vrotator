vrotator/
├── README.md
├── LICENSE
├── .gitignore
├── pyproject.toml
│
├── src/
│   └── vrotator/
│       ├── __init__.py
│       ├── main.py
│       ├── core/
│       │   ├── __init__.py
│       │   ├── capture.py
│       │   ├── pixel.py
│       │   └── input.py
│       └── utils/
│           ├── __init__.py
│           └── logger.py
│
├── tests/
│   ├── __init__.py
│   ├── test_capture.py
│   ├── test_pixel.py
│   └── test_input.py
│
└── addons/
    └── vrotator-wotlk/
        ├── vrotator-wotlk.toc
        ├── core/
        │   ├── main.lua
        │   ├── scanner.lua
        │   └── signal.lua
        └── rotations/
            ├── deathknight_blood.lua
            ├── deathknight_frost.lua
            ├── deathknight_unholy.lua
            │
            ├── druid_balance.lua
            ├── druid_feral_cat.lua
            ├── druid_feral_bear.lua
            ├── druid_restoration.lua
            │
            ├── hunter_bm.lua
            ├── hunter_mm.lua
            ├── hunter_surv.lua
            │
            ├── mage_arcane.lua
            ├── mage_fire.lua
            ├── mage_frost.lua
            │
            ├── paladin_holy.lua
            ├── paladin_prot.lua
            ├── paladin_ret.lua
            │
            ├── priest_disc.lua
            ├── priest_holy.lua
            ├── priest_shadow.lua
            │
            ├── rogue_assass.lua
            ├── rogue_combat.lua
            ├── rogue_sub.lua
            │
            ├── shaman_elem.lua
            ├── shaman_enh.lua
            ├── shaman_resto.lua
            │
            ├── warlock_affli.lua
            ├── warlock_demo.lua
            ├── warlock_destro.lua
            │
            ├── warrior_arms.lua
            ├── warrior_fury.lua
            └── warrior_prot.lua
