# EVEMon Certificates Enhanced

[🇵🇱 Polski](README-PL.md) | [🇬🇧 English](README-EN.md)

**EVEMon Certificates Enhanced** rebuilds selected default EVEMon certificates so they answer practical questions quickly: can the pilot use T1, is T2 unlocked, how deep is the specialization, and are the support skills merely started or genuinely strong?

The project focuses on **weapons, missile core, turret support, drones and tank**. It does not replace EVEMon Pilot Progression; it complements it with higher resolution where default EVEMon certificates are too compressed.

## Most important: installation order

1. Download and install EVEMon from the maintained **mgoeppner/evemon** repository: https://github.com/mgoeppner/evemon/releases
2. **Start EVEMon at least once.**
3. In the datafile/SDE update screen or popup, **install all offered datafile updates**.
4. Close EVEMon completely.
5. Download the newest package from this repository's **Releases** page.
6. Optional preview:
   ```powershell
   Set-ExecutionPolicy -Scope Process Bypass
   .\Install-EVEMon-Certificates-Enhanced.ps1 -Preview
   ```
7. Install:
   ```powershell
   .\Install-EVEMon-Certificates-Enhanced.ps1
   ```
8. Start EVEMon and open **Certificate Browser**.

> An EVEMon datafile update may restore upstream certificate definitions. After such an update, run the Certificates Enhanced installer again.

## Compatible EVEMon

The project is prepared and tested for **EVEMon 5.0.1** from https://github.com/mgoeppner/evemon. Update the upstream datafiles first; apply this enhancement only afterwards.

## The three related projects

- **EvE Modular Skillplans** — https://github.com/Blizbor/EvE-Modular-Skillplans — practical skill plans and training paths.
- **EVEMon Pilot Progression** — https://github.com/Blizbor/EVEMon-Pilot-Progression — broad pilot-competence map inside EVEMon.
- **EVEMon Certificates Enhanced** — https://github.com/Blizbor/EVEMon-Certificates-Enhanced — deeper weapon, drone and tank certificates.

## Downloading the package

Open **Releases** and download `EVEMon-Certificates-Enhanced.zip`. The repository includes a `package/` directory and a workflow that builds this archive automatically.

## Documentation

- [Quick start](docs/EN/Quick-Start.md)
- [What changes](docs/EN/What-Changes.md)
- [Weapons](docs/EN/Weapons.md)
- [Drones](docs/EN/Drones.md)
- [Tank](docs/EN/Tank.md)
- [Using it with EVEMon Pilot Progression](docs/EN/With-EVEMon-Pilot-Progression.md)
- [Project relationship](docs/EN/Project-Relationship.md)
- [Contributor guide](docs/EN/Contributor-Guide.md)
- [FAQ](docs/EN/FAQ.md)

## Contact

Installation problems, renamed/missing skills, grading suggestions and certificate proposals belong in the **Issue tracker**: https://github.com/Blizbor/EVEMon-Certificates-Enhanced/issues

<p align="center">
  <img src="https://images.evetech.net/characters/91331899/portrait?size=256" width="144" alt="Gazzine TunakTun portrait">
</p>
<p align="center"><strong>Author: Gazzine TunakTun</strong></p>

_EVE Online and related marks are property of CCP hf. This is a player-made project and is not affiliated with CCP._
