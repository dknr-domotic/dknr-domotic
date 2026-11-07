# Conception de dknr-domotic

Document de référence sur l'architecture et les conventions de dknr-domotic (état à la version 1.1, novembre 2026). À lire avant toute modification, et à tenir à jour quand une convention change.


## Rôle

dknr-domotic est le tableau de bord et le cerveau des projets DKNR : il lit les entités publiées sur MQTT par les sources (dknr-zigbee, dknr-zwave, dknr-rfxcom, dknr-teleinfo, dknr-nuki, dknr-daikin, dknr-zendure, dknr-apsystems), les range par pièce, les historise dans InfluxDB et les pilote par des scènes. Il est lui-même la source `dknr` (modes et capteurs internes de la maison).


## Dépôt

* Node-RED en mode projet : `flows.json`, `flows_cred.json` (chiffré avec `DKNR_SECRET`), `package.json` (version de l'application), `data/settings.js` (`httpAdminRoot: "/admin"`, tableau de bord sur `/dashboard`).
* `Dockerfile` (image `nodered/node-red`) et `docker-entrypoint.sh` : le conteneur reclone le dépôt au démarrage. `docker-compose.yaml` : InfluxDB 2 + dknr-domotic.
* Branche principale `master` (l'ancienne branche `reborn`, refonte au format DKNR, a été fusionnée en 1.0).
* Workflows : `release.yaml` (manuel, version en entrée : branche `x.y`, tag `vx.y`, images amd64/arm64 sur Docker Hub `jcpd/dknr-domotic` et `ghcr.io`), `release_dev.yaml` (image `dev` chaque matin), `update_docker_readme.yml`, `clean_repository.yml`, `dependabot.yml` (actions, npm, image Docker).
* Pas de tests automatisés dans le dépôt. Les modifications ont été validées avec un simulateur Node-RED maison (exécution des nœuds function, link call, délais et MQTT en boucle), non versionné : à recréer si besoin.


## Organisation du flow

Onglets : `common` (logique partagée), `home`, `energy`, `calendar`, `room`, `scene`, `entity`, `config`, `auth`.

* Les traitements partagés sont des groupes `common - ...` appelés par **link call** (`await node.linkcall('common - ...', msg)`) : `common - entity - merge`, `common - entity - set`, `common - entity - get`, `common - scene`, `common - influxdb`, `common - energy`, `common - weather`, `common - dknr - ...`, `common - mqtt - publish`, `common - ui - ...` (hmi, notice, enable, group, tab, control, latency), `common - user - ...`, `common - register - page`, `common - register - dictionary`.
* Chaque page s'enregistre (`describe.page`) et enregistre ses textes (`dictionary`, français et anglais).
* Tableau de bord FlowFuse Dashboard 2. Nommage des widgets : `ui - page - <page>`, `ui - group|dialog - <page> - <nom>`.
* Classes CSS du projet préfixées `dknr-` (ex : `dknr-row-icon`, `dknr-center`).
* Graphiques personnalisés en `ui-template` SVG (historique d'une entité, énergie, puissance, batterie) : dessin en pixels avec `ResizeObserver` (le tableau de bord perd le `viewBox`), et **hauteur fixe** sur le nœud `ui-template` (sinon il ne fait qu'une ligne).


## Contexte global

Données persistées (export / import sélectif depuis la page Configuration : auth, mqtt, room, parent, entity, block, calendar, energy, scene) :

| Clé | Contenu |
|---|---|
| `entity` | entités par identifiant `source/parent/id` |
| `discovery` | dernière discovery reçue par entité |
| `source`, `parent` | sources et appareils déclarés |
| `room` | `base` (pièces : id, nom, `outdoor` 1/0), `confort` (plages par pièce), `workday` (jours `d0`..`d6` à 1/0 par pièce), `location`, `map`, `camera` |
| `scene` | scènes par entité cible |
| `energy` | entités choisies pour l'énergie (puissances, batterie, compteurs, `preferred_tariff`...) |
| `calendar`, `user`, `auth`, `mqtt`, `block` | calendrier, utilisateurs, authentification, configuration MQTT, entités bloquées |

Données de fonctionnement : `describe` (templates, éléments, routines par élément, unités textuelles, enums de la source dknr, pages), `dictionary`, `form` (formulaires par interface), `stop`, `boot`, `sourceboot` (heure de démarrage annoncée par chaque source).

Les templates sont dans `describe.template` (nœud mémoire `c7b7c464c8142df7`) : `entity`, `discovery`, `source`, `parent`, `room`, `scene`, `trigger`, `routine`, `hmi`. **Toujours copier les objets imbriqués** (ex : `options`) au lieu de les partager avec le template.


## Format DKNR (MQTT)

Topic racine `dknr` par défaut :

* `dknr/discovery/<source>` (titre, version, git, icône), `dknr/discovery/<source>/<parent>` (nom), `dknr/discovery/<source>/<parent>/<entité>` : `{ name, group, type: binary|number|enum|text, unit, value, options }`.
* `dknr/get/<source>/<parent>/<entité>` : valeur. `dknr/set/<source>/<parent>/<entité>` : commande.

Conventions communes à tous les dépôts dknr :

* **Binaires** : `1` / `0` (unité `b`). L'unité `rb` inverse l'affichage (binaire dont `0` est l'état actif).
* **Enums** : la valeur publiée est la **clé** de l'option, jamais le libellé. Les libellés (`options`) sont traduits par la source selon la langue choisie dans sa configuration MQTT.
* **Ouvertures** (porte, fenêtre, baie) : `1` = ouvert, sauf unité `rb`. C'est aussi la convention des routines de scène.
* **Actions de télécommande** (transitoires) : enum avec la liste des actions ; publiées à chaque appui, même identique, mais jamais rejouées depuis un message MQTT retenu.
* Une source ne republie une valeur que si elle change (sauf événements de télécommande).


## Entités

* Discovery (`common - entity - merge`, nœuds `6facde51e61886e6` et `2d19ef3f5683869c`) :
  * une discovery d'entité crée l'entité si elle n'existe pas (nouvelle entité **cachée**, `hidden: 1`) ;
  * l'unité vient du type pour `binary` (`b`), `enum`, `text` ;
  * les `options` sont **reconstruites depuis la discovery** à chaque message (liste convertie en `{ valeur: valeur }`, valeur non objet ignorée) ;
  * une discovery de source (`dknr/discovery/<source>`) note son démarrage dans `sourceboot`.
* Valeurs (`common - entity - get`) : normalisation, `msg.repeat` si la valeur n'a pas changé, historisation InfluxDB (bucket `domotic`, measurement = élément, champ = identifiant), déclenchement des scènes.
* Commandes (`common - entity - set`) : publication sur `dknr/set`. Les entités de la source `dknr` passent aussi par MQTT (get / set) comme une source externe.
* Page Entités : sélecteur de source (plusieurs milliers d'entités), puis nom, pièce, élément, groupe, unité, visibilité.
* Éléments : switch, plug, power, current, frequency, voltage, energy, light, remote, door, window, lock, shutter, slider, waterboiler, alert, sound, motion, temperature, humidity, illuminance, pressure, fan, direction, time, battery, mode, text, location, color, tariff. Unités textuelles : `''`, `chex`, `enum`, `text`, `time`.


## Source interne dknr

* Commandes `dknr/command/<x>` (modes) : `nycthemer`, `light`, `shutter`, `waterboiler`, `sound`, avec `auto`, `high`, `low`, `manual`. D'autres entités dknr donnent l'état général : `automate`, mode thermique `temperature` (heating, cooling, thawing, off), humidité, lever / coucher du soleil, puissance de la maison...
* Capteurs `dknr/sensor/<x>` calculés chaque minute et au changement d'une commande (`29c782ee02094a7a`) : en `auto`, calcul selon le jour / la nuit, la saison, etc. ; en `high` / `low`, valeur forcée ; en `manual`, le capteur vaut `manual` (light, sound, shutter, waterboiler), ce qui arrête les scènes de l'élément. Le mode jour / nuit garde sa dernière valeur en manuel.
* Capteurs publiés seulement s'ils changent.


## Scènes

Une scène pilote une **entité cible** (clé de `scene`) à partir d'entités **déclencheurs** (`scene[cible].trigger[uid]` : `inputhigh`, `inputlow`, `outputhigh`, `outputlow` parmi `none`, `high`, `low`, `toggle`). Champs de la scène : voir `describe.template.scene` (`on`, `off`, routines activées, durée, seuils, `timer`, `today`, `pending`, paramètres `temperature_*`). Routines proposées par élément de la cible : `describe.scenes`.

### Chaîne (groupe `common - scene`)

`routine - loop` → files d'attente → `trigger` → `target` → `automate` → `enabled` → `manual` → `level` → `thermostat` → `nocturnal` → `diurnal` → `confort` → `eco` → `illuminance` → `darkness` → `motion` → `retention` → `aperture` → `humidity` → `nightlight` → `tariff` → `power` → `value` → `daily` → `duration` → `rsp` → limite par cible → `data` → `common - entity - set`.

Chaque routine lit `msg.rsp`, se court-circuite (« skip by response / exclusion »), écrit son résultat dans `msg.summary` et dans son statut. Le résumé des échecs est gardé par scène et affiché en tableau dans le détail de la scène (page Scènes, « Débogage ») : c'est le premier outil de diagnostic.

### Règles établies

* **loop** : un message par scène utilisant le déclencheur. Les valeurs répétées numériques ne déclenchent pas, les répétitions binaires et textuelles oui (rétention de mouvement, double appui de télécommande). Pendant 60 s après le démarrage annoncé d'une source, ses valeurs répétées ne déclenchent pas. Quand un mode `dknr/command/<x>` change, les scènes déclenchées par `dknr/sensor/<x>` sont rejouées 3 s plus tard. Une cible changée à la main sans être son propre déclencheur ne fait que démarrer / arrêter le minuteur de durée.
* **Files** : volets 30 s (attente de la position finale), cible = déclencheur par cible, autres 5 / s. La limite finale garde la dernière commande **par cible** (aucune cible n'est perdue).
* **trigger** relit la scène et la cible après les files (pas de décision sur des valeurs périmées) et calcule une fois les heures de confort de la pièce (`msg.confort`, plages et jours travaillés, plage à cheval sur minuit acceptée).
* **level** compare valeurs et seuils sans tenir compte du type (`1` = `'1'`), heures en `hhmm`, comparaison textuelle si non numérique, seuils inversés acceptés, entre les deux seuils : rien (hystérésis).
* **manual** arrête si `dknr/sensor/<élément>` vaut `manual`.
* **aperture** : arrête si une ouverture déclencheur est ouverte (convention `1` = ouvert, `rb` inversé) ; l'ordre bloqué est gardé dans `scene.pending` et rejoué quand la dernière ouverture se ferme ; il est effacé dès qu'un ordre passe.
* **motion** déclenche l'état haut sur mouvement ; **retention** ne relance le minuteur que si la cible est déjà haute.
* **tariff** : `energy.preferred_tariff` (binaire) doit être favorable.
* **power** : arrêt si la puissance reste sous le seuil bas 10 s (sur une copie du message).
* **daily** : une fois par jour, marquée seulement quand la commande part réellement (`rsp`) ; remise à zéro chaque matin à 8h et depuis la page Configuration.
* **duration** : minuteur à l'allumage (par scène ou à la main), extinction par le cron à expiration, minuteur arrêté à l'extinction.
* **thermostat** : sondes intérieures (pièces non extérieures, `outdoor` 1 ou `true`) et extérieures, consigne confort / éco / hors gel, durée de chauffe calculée par cycle, arrêt fenêtre ouverte, froid sur énergie solaire ; il n'écrit que ses champs `temperature_*` dans la scène ; réévalué chaque minute par le cron.
* **cron** (chaque minute) : minuteurs expirés (la cible sert de déclencheur avec la valeur `off`) et thermostats.
* Les routines liées à l'heure (nocturnal, diurnal, confort, eco, nightlight) ne se réévaluent que sur un déclencheur : ajouter `dknr/sensor/nycthemer` comme déclencheur pour suivre le jour / la nuit.


## Pages

* **Accueil** : plan (pièces, températures, humidité), météo OpenWeatherMap, calendrier.
* **Pièces** : plan, entités par usage avec pilotage et historique (InfluxDB), caméras, heures de confort, jours travaillés.
* **Energie** : carte des flux (réseau, solaire, batterie, maison, lumières = somme des puissances visibles des parents ayant une lumière ou un spot visible), graphiques puissance / énergie / batterie aux couleurs fixes, résumé.
* **Scènes** : édition, déclencheurs (formulaire adapté à l'unité : liste pour les enums avec options, texte sinon), minuteurs, événements, détail et débogage.
* **Entités**, **Calendrier**, **Configuration** (MQTT, utilisateurs, pièces, export / import sélectif, remise à zéro du quotidien), **Authentification** (utilisateurs avec niveau et langue).


## Pistes et points ouverts

* Délestage des thermostats quand la puissance dépasse l'abonnement (`temperature_duration_offloading` déjà prévu, non utilisé).
* Champs présents mais pas encore utilisés : Telegram des utilisateurs, topic Home Assistant de la configuration MQTT.
* Ordre en attente des volets sans expiration (à revoir si un cas gênant apparaît).
* Projet lié en conception : dknr-alexa (voir son `docs/CONCEPTION.md`).
